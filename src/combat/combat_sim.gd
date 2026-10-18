class_name CombatSim
extends RefCounted
## Ren stridslogik utan noder. Driv den med advance(dt), läs enheternas tillstånd
## och töm händelserna med drain_events() för att spela upp effekter.
##
## Händelser (Dictionary med "type"):
##   cast_start {unit, ability, targets, duration, by_player}
##   cast_end {unit, ability, result: success|interrupted|cancelled|dead, by?}
##   ability_used {unit, ability, targets, by_player}
##   projectile {source, target, ability, travel}
##   swing {unit, target}
##   damage {source, target, amount, crit, school, ability}
##   heal {source, target, amount, effective, crit, ability}
##   aura_applied {unit, aura, refreshed} / aura_removed {unit, aura}
##   death {unit}
##   queued {unit, ability} / error {unit, ability, reason}
##   announce {text}
##   outcome {result: victory|defeat}
##   trait {unit, trait} – en egenskap slog till (händelser den orsakar bär fältet "trait")
##   release {unit, trait, charge, amount, ability} – en förmåga förbrukade laddningar

const STEP := 0.05
const BASE_GCD := 1.5
const MIN_GCD := 1.0
## En förmåga vars cooldown har högst så här mycket kvar köas i stället för att nekas.
const QUEUE_WINDOW := 0.5
const HEAL_THREAT := 0.5
const MELEE_CRIT := 2.0
const SPELL_CRIT := 1.5
## Hur många egenskaper som kan sätta igång varandra i en kedja.
const MAX_TRAIT_CHAIN := 4

var data: Dictionary
var units: Array[CombatUnit] = []
var heroes: Array[CombatUnit] = []
var boss: CombatUnit
var time := 0.0
var outcome := ""
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var threat := {}

var _by_id := {}
var _accum := 0.0
var _pending: Array[Dictionary] = []
var _timers: Array[Dictionary] = []
var _phases: Array = []
var _trait_ctx := ""
var _trait_depth := 0
## Medan en förmåga förbrukar laddningar: {unit, ability, mult} för skadebonusen.
var _release_bonus := {}


static func create(game_data: Dictionary, encounter_id: String, seed_value := 1) -> CombatSim:
	var sim := CombatSim.new()
	sim.data = game_data
	sim.rng.seed = seed_value
	var enc: Dictionary = game_data.encounters[encounter_id]
	for hero_id in enc.party:
		var hero := CombatUnit.from_data(hero_id, game_data.heroes[hero_id], 0)
		sim._add(hero)
		sim.heroes.append(hero)
		sim.threat[hero.id] = 0.0
	var boss_data: Dictionary = game_data.bosses[enc.boss]
	sim.boss = CombatUnit.from_data(enc.boss, boss_data, 1)
	sim._add(sim.boss)
	for t in boss_data.get("timers", []):
		sim._timers.append({"ability": t.ability, "every": float(t.every), "left": float(t.first)})
	sim._phases = boss_data.get("phases", []).duplicate(true)
	for hero in sim.heroes:
		if hero.role == "tank":
			sim.threat[hero.id] = 1.0
			break
	return sim


# --- Publikt API ------------------------------------------------------------

static func is_heal(ab: Dictionary) -> bool:
	return ab.get("effects", []).any(func(e: Dictionary) -> bool: return e.type == "heal")


## Summan av genomsnittlig healing som just nu laddas mot enheten (för raidramarnas prognos).
func incoming_heal(unit_id: String) -> float:
	var total := 0.0
	for h in heroes:
		if h.alive and h.is_casting() and h.cast.targets.has(unit_id):
			for e in ability(h.cast.ability).get("effects", []):
				if e.type == "heal":
					total += (e.min + e.max) / 2.0
	return total


## Laddningar som förmågan förbrukar när den används: {charge, value, max}, eller tom.
func charge_info(u: CombatUnit, ability_id: String) -> Dictionary:
	for trait_id in u.traits:
		var t: Dictionary = data.traits[trait_id]
		var release: Dictionary = t.get("release", {})
		if release.get("ability", "") != ability_id:
			continue
		var cap := 0.0
		for effect in t.get("effects", []):
			if effect.type == "charge":
				cap = _charge_cap(u, effect)
		return {"charge": release.charge, "value": u.charges.get(release.charge, 0.0), "max": cap}
	return {}


func ability(ability_id: String) -> Dictionary:
	return data.abilities[ability_id]


func unit(unit_id: String) -> CombatUnit:
	return _by_id.get(unit_id)


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func advance(dt: float) -> void:
	_accum += dt
	while _accum >= STEP and outcome == "":
		_accum -= STEP
		_tick(STEP)


func threat_target() -> CombatUnit:
	var best: CombatUnit = null
	var best_threat := -1.0
	for h in heroes:
		if h.alive and threat[h.id] > best_threat:
			best = h
			best_threat = threat[h.id]
	return best


## Spelaren trycker på en förmåga. Returnerar "used", "queued" eller en felorsak.
## Spelarens order går alltid före hjältens egen AI.
func player_use(ability_id: String, target_id := "") -> String:
	if outcome != "":
		return "over"
	var ab := ability(ability_id)
	var u := unit(ab.owner)
	var on_gcd: bool = ab.get("gcd", true)
	var reason := _can_use(u, ability_id)
	if reason == "cooldown" and on_gcd and u.cooldown_left(ability_id) <= QUEUE_WINDOW:
		reason = ""
	if reason != "":
		_emit({"type": "error", "unit": u.id, "ability": ability_id, "reason": reason})
		return reason
	var command := {"ability": ability_id, "target": target_id}
	if not on_gcd:
		_start(u, ability_id, _command_targets(u, command), true)
		return "used"
	if u.is_casting() and not u.cast.by_player:
		_cancel_cast(u)
	if u.gcd > 0.0 and u.gcd_from_ai:
		u.gcd = 0.0
	if u.is_casting() or u.gcd > 0.0 or u.cooldown_left(ability_id) > 0.0:
		u.queued = command
		_emit({"type": "queued", "unit": u.id, "ability": ability_id})
		return "queued"
	_start(u, ability_id, _command_targets(u, command), true)
	return "used"


# --- Simuleringssteg --------------------------------------------------------

func _tick(dt: float) -> void:
	time += dt
	for u in units:
		if u.alive:
			_tick_timers(u, dt)
	_tick_pending(dt)
	for u in units:
		if u.alive:
			_tick_cast(u, dt)
	for u in units:
		if u.alive:
			_tick_swing(u, dt)
	_tick_boss_ai(dt)
	for h in heroes:
		if h.alive:
			_tick_hero_ai(h)
	_check_phases()
	_check_outcome()


func _tick_timers(u: CombatUnit, dt: float) -> void:
	u.gcd = maxf(0.0, u.gcd - dt)
	for key in u.cooldowns.keys():
		u.cooldowns[key] = maxf(0.0, u.cooldowns[key] - dt)
	if u.max_mana > 0.0:
		u.mana = minf(u.max_mana, u.mana + u.mana_regen * dt)
	for aura_id in u.auras.keys():
		var a: Dictionary = u.auras[aura_id]
		if a.hot > 0.0 or a.dot > 0.0:
			a.tick -= dt
			if a.tick <= 0.0:
				a.tick += 1.0
				var source := unit(a.source)
				if a.hot > 0.0:
					_heal(source if source else u, u, a.hot, aura_id, false)
				else:
					_deal_damage(source if source else u, u, a.dot, a.school, aura_id, false, false)
				if not u.alive:
					return
		if a.duration > 0.0:
			a.remaining -= dt
			if a.remaining <= 0.0:
				u.auras.erase(aura_id)
				_emit({"type": "aura_removed", "unit": u.id, "aura": aura_id})


func _tick_pending(dt: float) -> void:
	for p in _pending.duplicate():
		p.left -= dt
		if p.left <= 0.0:
			_pending.erase(p)
			_apply_effects(unit(p.source), p.ability, p.targets)


func _tick_cast(u: CombatUnit, dt: float) -> void:
	if not u.is_casting():
		return
	u.cast.elapsed += dt
	if u.cast.elapsed < u.cast.duration:
		return
	var c := u.cast
	u.cast = {}
	_emit({"type": "cast_end", "unit": u.id, "ability": c.ability, "result": "success"})
	_resolve(u, c.ability, c.targets)


func _tick_swing(u: CombatUnit, dt: float) -> void:
	if u.swing.is_empty() or u.is_casting():
		return
	u.swing_timer -= dt * u.haste()
	if u.swing_timer > 0.0:
		return
	u.swing_timer += u.swing.interval
	var target := boss if u.team == 0 else threat_target()
	if target == null or not target.alive:
		return
	_emit({"type": "swing", "unit": u.id, "target": target.id})
	_deal_damage(u, target, rng.randf_range(u.swing.min, u.swing.max),
			u.swing.get("school", "physical"), "melee", true, true)


func _tick_boss_ai(dt: float) -> void:
	if not boss.alive:
		return
	for t in _timers:
		t.left -= dt
	if boss.is_casting():
		return
	for t in _timers:
		if t.left <= 0.0:
			t.left = t.every
			var targets := _pick_targets(boss, ability(t.ability).target)
			if not targets.is_empty():
				_start(boss, t.ability, targets, false)
			return


func _tick_hero_ai(h: CombatUnit) -> void:
	if h.is_casting() or h.gcd > 0.0:
		return
	if not h.queued.is_empty():
		var command := h.queued
		var reason := _can_use(h, command.ability)
		if reason == "cooldown":
			return
		h.queued = {}
		if reason == "":
			_start(h, command.ability, _command_targets(h, command), true)
		else:
			_emit({"type": "error", "unit": h.id, "ability": command.ability, "reason": reason})
		return
	for rule in h.rules:
		var ability_id: String = rule.ability
		if _can_use(h, ability_id) != "":
			continue
		var targets := _pick_targets(h, rule.get("target", ability(ability_id).target))
		if targets.is_empty() or not _rule_matches(rule, targets):
			continue
		_start(h, ability_id, targets, false)
		return


func _check_phases() -> void:
	if not boss.alive:
		return
	for phase in _phases:
		if phase.get("done", false) or boss.hp_pct() > phase.below:
			continue
		phase.done = true
		if phase.has("aura"):
			_add_aura(boss, boss, phase.aura)
		_emit({"type": "announce", "text": phase.get("text", "")})


func _check_outcome() -> void:
	if not boss.alive:
		outcome = "victory"
	elif heroes.all(func(h: CombatUnit) -> bool: return not h.alive):
		outcome = "defeat"
	if outcome != "":
		for u in units:
			u.cast = {}
			u.queued = {}
		_pending.clear()
		_emit({"type": "outcome", "result": outcome})


# --- Förmågor ---------------------------------------------------------------

func _can_use(u: CombatUnit, ability_id: String) -> String:
	if u == null or not u.alive:
		return "dead"
	var ab := ability(ability_id)
	if u.cooldown_left(ability_id) > 0.0:
		return "cooldown"
	if u.mana < ab.get("cost", 0.0):
		return "mana"
	if ab.get("requires_interruptible_cast", false) and not _has_interruptible_enemy(u):
		return "nothing_to_interrupt"
	return ""


func _start(u: CombatUnit, ability_id: String, targets: Array, by_player: bool) -> void:
	var ab := ability(ability_id)
	u.mana -= ab.get("cost", 0.0)
	var cooldown: float = ab.get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[ability_id] = cooldown
	if ab.get("gcd", true):
		u.gcd = maxf(MIN_GCD, BASE_GCD / u.haste())
		u.gcd_from_ai = not by_player
	var cast_time: float = ab.get("cast", 0.0) / u.haste()
	if cast_time > 0.0:
		u.cast = {"ability": ability_id, "targets": targets, "elapsed": 0.0,
				"duration": cast_time, "by_player": by_player}
		_emit({"type": "cast_start", "unit": u.id, "ability": ability_id,
				"targets": targets, "duration": cast_time, "by_player": by_player})
	else:
		_emit({"type": "ability_used", "unit": u.id, "ability": ability_id,
				"targets": targets, "by_player": by_player})
		_resolve(u, ability_id, targets)


func _cancel_cast(u: CombatUnit) -> void:
	var c := u.cast
	u.cast = {}
	u.mana += ability(c.ability).get("cost", 0.0)
	var cooldown: float = ability(c.ability).get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[c.ability] = 0.0
	_emit({"type": "cast_end", "unit": u.id, "ability": c.ability, "result": "cancelled"})


func _resolve(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var travel: float = ability(ability_id).get("travel", 0.0)
	if travel <= 0.0:
		_apply_effects(caster, ability_id, targets)
		return
	for target_id in targets:
		_emit({"type": "projectile", "source": caster.id, "target": target_id,
				"ability": ability_id, "travel": travel})
	_pending.append({"left": travel, "source": caster.id, "targets": targets, "ability": ability_id})


func _apply_effects(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var ab := ability(ability_id)
	var can_crit: bool = not ab.get("no_crit", false)
	var releases := _take_releases(caster, ability_id)
	var interrupted := false
	for effect in ab.get("effects", []):
		for target_id in targets:
			var t := unit(target_id)
			if t == null:
				continue
			match effect.type:
				"damage":
					_deal_damage(caster, t, _roll(effect), effect.get("school", "physical"),
							ability_id, ab.get("melee", false), can_crit)
				"heal":
					_heal(caster, t, _roll(effect), ability_id, can_crit)
				"aura":
					_add_aura(caster, t, effect.aura)
				"interrupt":
					interrupted = _interrupt(caster, t) or interrupted
	_release_bonus = {}
	for r in releases:
		if r.release.get("needs_interrupt", false) and not interrupted:
			caster.charges[r.release.charge] = r.amount  # misslyckat avbrott: laddningarna finns kvar
			continue
		_run_release(caster, r, targets)
	if caster.team == 0 and caster.alive:
		threat[caster.id] += ab.get("threat_bonus", 0.0)


func _deal_damage(src: CombatUnit, tgt: CombatUnit, base: float, school: String,
		ability_id: String, melee: bool, can_crit: bool) -> void:
	if not tgt.alive:
		return
	var probe := {"source": src.id, "target": tgt.id, "ability": ability_id, "school": school}
	var crit: bool = can_crit and (rng.randf() < src.crit_chance or _modify(src, "modify_damage", probe, "force_crit", false))
	var mult: float = (MELEE_CRIT if melee else SPELL_CRIT) if crit else 1.0
	mult *= _modify(src, "modify_damage", probe, "damage_mult", 1.0)
	if _release_bonus.get("unit", "") == src.id and _release_bonus.ability == ability_id:
		mult *= _release_bonus.mult
	mult *= _modify(tgt, "modify_damage_taken", probe, "damage_taken_mult", 1.0)
	var amount := roundf(base * mult * tgt.damage_taken())
	tgt.hp = maxf(0.0, tgt.hp - amount)
	_emit({"type": "damage", "source": src.id, "target": tgt.id, "amount": amount,
			"crit": crit, "school": school, "ability": ability_id})
	if src.team == 0 and src.alive:
		threat[src.id] += amount * src.threat_mult
	if tgt.hp <= 0.0:
		_kill(tgt)


func _heal(src: CombatUnit, tgt: CombatUnit, base: float, ability_id: String, can_crit: bool) -> void:
	if not tgt.alive:
		return
	var crit := can_crit and rng.randf() < src.crit_chance
	var mult: float = _modify(src, "modify_heal", {"source": src.id, "target": tgt.id, "ability": ability_id}, "heal_mult", 1.0)
	var amount := roundf(base * (SPELL_CRIT if crit else 1.0) * mult)
	var effective := minf(amount, tgt.max_hp - tgt.hp)
	tgt.hp += effective
	_emit({"type": "heal", "source": src.id, "target": tgt.id, "amount": amount,
			"effective": effective, "crit": crit, "ability": ability_id})
	if src.team == 0 and src.alive:
		threat[src.id] += effective * HEAL_THREAT


func _add_aura(src: CombatUnit, tgt: CombatUnit, aura_id: String, duration_override := 0.0) -> void:
	if not tgt.alive:
		return
	var d: Dictionary = data.auras[aura_id]
	var refreshed := tgt.auras.has(aura_id)
	var duration := duration_override if duration_override > 0.0 else float(d.get("duration", -1))
	if refreshed and tgt.auras[aura_id].remaining > duration:
		duration = tgt.auras[aura_id].remaining
	tgt.auras[aura_id] = {"remaining": duration, "duration": duration,
			"haste": float(d.get("haste", 0.0)), "damage_taken_mult": float(d.get("damage_taken_mult", 1.0)),
			"hot": float(d.get("hot", 0.0)), "dot": float(d.get("dot", 0.0)),
			"school": d.get("school", "physical"), "tick": 1.0, "source": src.id}
	_emit({"type": "aura_applied", "unit": tgt.id, "aura": aura_id, "refreshed": refreshed})


func _interrupt(src: CombatUnit, tgt: CombatUnit) -> bool:
	if not tgt.is_casting() or not ability(tgt.cast.ability).get("interruptible", false):
		return false
	var interrupted: String = tgt.cast.ability
	tgt.cast = {}
	_emit({"type": "cast_end", "unit": tgt.id, "ability": interrupted,
			"result": "interrupted", "by": src.id})
	return true


func _kill(u: CombatUnit) -> void:
	if not u.alive:  # en egenskap kan ha dödat enheten mitt i en annan träff
		return
	u.alive = false
	u.hp = 0.0
	if u.is_casting():
		var c := u.cast
		u.cast = {}
		_emit({"type": "cast_end", "unit": u.id, "ability": c.ability, "result": "dead"})
	u.auras.clear()
	u.queued = {}
	if threat.has(u.id):
		threat[u.id] = 0.0
	_emit({"type": "death", "unit": u.id})


# --- Egenskaper (traits) ----------------------------------------------------
# En egenskap lyssnar på en händelsetyp ("trigger") och kör effekter när villkoren i "when"
# stämmer. "modify_damage" körs i stället innan skadan räknas ut. Händelser som en egenskap
# orsakar bär fältet "trait" och kan sätta igång andra egenskaper, men aldrig samma igen.

func _emit(e: Dictionary) -> void:
	if _trait_ctx != "":
		e.trait = _trait_ctx
	events.append(e)
	if _trait_depth >= MAX_TRAIT_CHAIN or outcome != "":
		return
	for owner in heroes:
		if not owner.alive:
			continue
		for trait_id in owner.traits:
			var t: Dictionary = data.traits[trait_id]
			if t.trigger != e.type or e.get("trait", "") == trait_id:
				continue
			if time < owner.trait_ready.get(trait_id, 0.0) or not _when(owner, t.get("when", {}), e):
				continue
			if t.has("chance") and rng.randf() >= float(t.chance):
				continue
			owner.trait_ready[trait_id] = time + float(t.get("internal_cooldown", 0.0))
			_run_trait(owner, trait_id, t, e)


func _run_trait(owner: CombatUnit, trait_id: String, t: Dictionary, e: Dictionary) -> void:
	var outer := _trait_ctx
	_trait_ctx = trait_id
	_trait_depth += 1
	_emit({"type": "trait", "unit": owner.id, "trait": trait_id})
	for effect in t.get("effects", []):
		for tgt in _trait_targets(owner, effect.get("target", "self"), e, []):
			_run_trait_effect(owner, trait_id, effect, tgt, e)
	_trait_depth -= 1
	_trait_ctx = outer


## self, allies, enemy, other_allies (alla utom förmågans mål) eller ett fält i händelsen (source, target …).
func _trait_targets(owner: CombatUnit, where: String, e: Dictionary, ability_targets: Array) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	match where:
		"self":
			out = [owner]
		"allies":
			out = _allies(owner)
		"other_allies":
			for a in _allies(owner):
				if not ability_targets.has(a.id):
					out.append(a)
		"enemy":
			var enemies := _enemies(owner)
			if not enemies.is_empty():
				out = [enemies[0]]
		_:
			if unit(e.get(where, "")) != null:
				out = [unit(e[where])]
	return out


func _run_trait_effect(owner: CombatUnit, trait_id: String, effect: Dictionary, tgt: CombatUnit, e := {}) -> void:
	match effect.type:
		"damage":
			_deal_damage(owner, tgt, _roll(effect), effect.get("school", "physical"), trait_id,
					false, not effect.get("no_crit", false))
		"heal":
			_heal(owner, tgt, _roll(effect), trait_id, false)
		"aura":
			_add_aura(owner, tgt, effect.aura, float(effect.get("duration", 0.0)))
		"mana":
			tgt.mana = minf(tgt.max_mana, tgt.mana + float(effect.amount))
		"charge":
			_add_charge(tgt, effect, e)


# --- Laddningar och förlösning ----------------------------------------------
# En egenskap kan ladda upp en resurs ("charge"-effekt) och förbruka den när hjälten lyckas
# med en viss förmåga ("release"). Förbrukningen sker när förmågan verkar – en avbruten cast
# eller ett Kick utan något att avbryta behåller laddningarna.

func _charge_cap(u: CombatUnit, effect: Dictionary) -> float:
	if effect.has("max_pct_hp"):
		return roundf(u.max_hp * float(effect.max_pct_hp))
	return float(effect.get("max", 5))


func _add_charge(u: CombatUnit, effect: Dictionary, e: Dictionary) -> void:
	var charge: String = effect.charge
	var every := int(effect.get("every", 1))
	if every > 1:
		u.charge_progress[charge] = u.charge_progress.get(charge, 0) + 1
		if u.charge_progress[charge] < every:
			return
		u.charge_progress[charge] = 0
	var amount := float(e.get(effect.amount_from, 0.0)) if effect.has("amount_from") else float(effect.get("amount", 1))
	u.charges[charge] = minf(_charge_cap(u, effect), u.charges.get(charge, 0.0) + amount)


## Plockar ut laddningarna som förmågan förbrukar och sätter skadebonusen för den här förmågan.
func _take_releases(caster: CombatUnit, ability_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var mult := 1.0
	for trait_id in caster.traits:
		var release: Dictionary = data.traits[trait_id].get("release", {})
		var amount: float = caster.charges.get(release.get("charge", ""), 0.0)
		if release.get("ability", "") != ability_id or amount <= 0.0:
			continue
		caster.charges[release.charge] = 0.0
		mult *= 1.0 + float(release.get("damage_mult_per", 0.0)) * amount
		out.append({"trait": trait_id, "release": release, "amount": amount})
	_release_bonus = {"unit": caster.id, "ability": ability_id, "mult": mult} if mult != 1.0 else {}
	return out


func _run_release(caster: CombatUnit, r: Dictionary, ability_targets: Array) -> void:
	var outer := _trait_ctx
	_trait_ctx = r.trait
	_trait_depth += 1
	_emit({"type": "release", "unit": caster.id, "trait": r.trait, "charge": r.release.charge,
			"amount": r.amount, "ability": r.release.ability})
	for effect in r.release.get("effects", []):
		var scaled: Dictionary = effect.duplicate()
		if effect.get("per_charge", false):
			for key in ["min", "max", "duration"]:
				if scaled.has(key):
					scaled[key] = float(scaled[key]) * r.amount
		for tgt in _trait_targets(caster, effect.get("target", "self"), {}, ability_targets):
			_run_trait_effect(caster, r.trait, scaled, tgt)
	_trait_depth -= 1
	_trait_ctx = outer


## Villkor för en egenskap. Händelsefält jämförs med "self", "ally", "enemy" eller ett värde.
func _when(owner: CombatUnit, when: Dictionary, e: Dictionary) -> bool:
	for key in when:
		var want: Variant = when[key]
		match key:
			"self_has_aura":
				if not owner.auras.has(want):
					return false
			"self_hp_below":
				if owner.hp_pct() >= want:
					return false
			"target_hp_below":
				var t := unit(e.get("target", ""))
				if t == null or t.hp_pct() >= want:
					return false
			"target_has_aura":
				var t := unit(e.get("target", ""))
				if t == null or not t.auras.has(want):
					return false
			_:
				if not e.has(key):
					return false
				var got: Variant = e[key]
				if want is String and want == "self":
					if got != owner.id:
						return false
				elif want is String and want in ["ally", "enemy"]:
					var u := unit(got)
					if u == null or (u.team == owner.team) != (want == "ally"):
						return false
				elif typeof(got) != typeof(want) or got != want:
					return false
	return true


## Samlar ihop en egenskapsmodifierare: multiplicerar tal, eller sant om någon egenskap säger sant.
func _modify(owner: CombatUnit, trigger: String, probe: Dictionary, key: String, base: Variant) -> Variant:
	var result: Variant = base
	for trait_id in owner.traits:
		var t: Dictionary = data.traits[trait_id]
		if t.trigger != trigger or not t.get("modify", {}).has(key) or not _when(owner, t.get("when", {}), probe):
			continue
		if result is bool:
			result = result or t.modify[key]
		else:
			result *= float(t.modify[key])
	return result


# --- Hjälpfunktioner --------------------------------------------------------

func _add(u: CombatUnit) -> void:
	units.append(u)
	_by_id[u.id] = u


func _roll(effect: Dictionary) -> float:
	return rng.randf_range(effect.min, effect.max)


func _allies(u: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for x in units:
		if x.alive and x.team == u.team:
			out.append(x)
	return out


func _enemies(u: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for x in units:
		if x.alive and x.team != u.team:
			out.append(x)
	return out


func _pick_targets(caster: CombatUnit, selector: String) -> Array:
	match selector:
		"self":
			return [caster.id]
		"enemy":
			var enemies := _enemies(caster)
			return [] if enemies.is_empty() else [enemies[0].id]
		"enemy_all":
			return _enemies(caster).map(func(x: CombatUnit) -> String: return x.id)
		"ally_all":
			return _allies(caster).map(func(x: CombatUnit) -> String: return x.id)
		"threat_target":
			var t := threat_target()
			return [] if t == null else [t.id]
		"lowest_ally":
			var best: CombatUnit = null
			for a in _allies(caster):
				if best == null or a.hp_pct() < best.hp_pct():
					best = a
			return [] if best == null else [best.id]
		"tank":
			for a in _allies(caster):
				if a.role == "tank":
					return [a.id]
			return []
	push_error("Okänd målväljare: " + selector)
	return []


func _command_targets(u: CombatUnit, command: Dictionary) -> Array:
	var chosen := unit(command.target) if command.target != "" else null
	if chosen and chosen.alive:
		return [chosen.id]
	return _pick_targets(u, ability(command.ability).target)


func _rule_matches(rule: Dictionary, targets: Array) -> bool:
	var condition: Dictionary = rule.get("if", {})
	var first := unit(targets[0])
	if condition.has("target_hp_below") and first.hp_pct() >= condition.target_hp_below:
		return false
	if condition.has("target_missing_aura") and first.auras.has(condition.target_missing_aura):
		return false
	return true


func _has_interruptible_enemy(u: CombatUnit) -> bool:
	for e in _enemies(u):
		if e.is_casting() and ability(e.cast.ability).get("interruptible", false):
			return true
	return false
