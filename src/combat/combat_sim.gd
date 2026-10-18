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

const STEP := 0.05
const BASE_GCD := 1.5
const MIN_GCD := 1.0
## En förmåga vars cooldown har högst så här mycket kvar köas i stället för att nekas.
const QUEUE_WINDOW := 0.5
const HEAL_THREAT := 0.5
const MELEE_CRIT := 2.0
const SPELL_CRIT := 1.5

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
		events.append({"type": "error", "unit": u.id, "ability": ability_id, "reason": reason})
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
		events.append({"type": "queued", "unit": u.id, "ability": ability_id})
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
		if a.hot > 0.0:
			a.tick -= dt
			if a.tick <= 0.0:
				a.tick += 1.0
				var source := unit(a.source)
				_heal(source if source else u, u, a.hot, aura_id, false)
		if a.duration > 0.0:
			a.remaining -= dt
			if a.remaining <= 0.0:
				u.auras.erase(aura_id)
				events.append({"type": "aura_removed", "unit": u.id, "aura": aura_id})


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
	events.append({"type": "cast_end", "unit": u.id, "ability": c.ability, "result": "success"})
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
	events.append({"type": "swing", "unit": u.id, "target": target.id})
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
			events.append({"type": "error", "unit": h.id, "ability": command.ability, "reason": reason})
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
		events.append({"type": "announce", "text": phase.get("text", "")})


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
		events.append({"type": "outcome", "result": outcome})


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
		events.append({"type": "cast_start", "unit": u.id, "ability": ability_id,
				"targets": targets, "duration": cast_time, "by_player": by_player})
	else:
		events.append({"type": "ability_used", "unit": u.id, "ability": ability_id,
				"targets": targets, "by_player": by_player})
		_resolve(u, ability_id, targets)


func _cancel_cast(u: CombatUnit) -> void:
	var c := u.cast
	u.cast = {}
	u.mana += ability(c.ability).get("cost", 0.0)
	var cooldown: float = ability(c.ability).get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[c.ability] = 0.0
	events.append({"type": "cast_end", "unit": u.id, "ability": c.ability, "result": "cancelled"})


func _resolve(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var travel: float = ability(ability_id).get("travel", 0.0)
	if travel <= 0.0:
		_apply_effects(caster, ability_id, targets)
		return
	for target_id in targets:
		events.append({"type": "projectile", "source": caster.id, "target": target_id,
				"ability": ability_id, "travel": travel})
	_pending.append({"left": travel, "source": caster.id, "targets": targets, "ability": ability_id})


func _apply_effects(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var ab := ability(ability_id)
	var can_crit: bool = not ab.get("no_crit", false)
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
					_interrupt(caster, t)
	if caster.team == 0 and caster.alive:
		threat[caster.id] += ab.get("threat_bonus", 0.0)


func _deal_damage(src: CombatUnit, tgt: CombatUnit, base: float, school: String,
		ability_id: String, melee: bool, can_crit: bool) -> void:
	if not tgt.alive:
		return
	var crit := can_crit and rng.randf() < src.crit_chance
	var mult := (MELEE_CRIT if melee else SPELL_CRIT) if crit else 1.0
	var amount := roundf(base * mult * tgt.damage_taken())
	tgt.hp = maxf(0.0, tgt.hp - amount)
	events.append({"type": "damage", "source": src.id, "target": tgt.id, "amount": amount,
			"crit": crit, "school": school, "ability": ability_id})
	if src.team == 0 and src.alive:
		threat[src.id] += amount * src.threat_mult
	if tgt.hp <= 0.0:
		_kill(tgt)


func _heal(src: CombatUnit, tgt: CombatUnit, base: float, ability_id: String, can_crit: bool) -> void:
	if not tgt.alive:
		return
	var crit := can_crit and rng.randf() < src.crit_chance
	var amount := roundf(base * (SPELL_CRIT if crit else 1.0))
	var effective := minf(amount, tgt.max_hp - tgt.hp)
	tgt.hp += effective
	events.append({"type": "heal", "source": src.id, "target": tgt.id, "amount": amount,
			"effective": effective, "crit": crit, "ability": ability_id})
	if src.team == 0 and src.alive:
		threat[src.id] += effective * HEAL_THREAT


func _add_aura(src: CombatUnit, tgt: CombatUnit, aura_id: String) -> void:
	if not tgt.alive:
		return
	var d: Dictionary = data.auras[aura_id]
	var refreshed := tgt.auras.has(aura_id)
	var duration := float(d.get("duration", -1))
	tgt.auras[aura_id] = {"remaining": duration, "duration": duration,
			"haste": float(d.get("haste", 0.0)), "damage_taken_mult": float(d.get("damage_taken_mult", 1.0)),
			"hot": float(d.get("hot", 0.0)), "tick": 1.0, "source": src.id}
	events.append({"type": "aura_applied", "unit": tgt.id, "aura": aura_id, "refreshed": refreshed})


func _interrupt(src: CombatUnit, tgt: CombatUnit) -> void:
	if not tgt.is_casting() or not ability(tgt.cast.ability).get("interruptible", false):
		return
	var interrupted: String = tgt.cast.ability
	tgt.cast = {}
	events.append({"type": "cast_end", "unit": tgt.id, "ability": interrupted,
			"result": "interrupted", "by": src.id})


func _kill(u: CombatUnit) -> void:
	u.alive = false
	u.hp = 0.0
	if u.is_casting():
		var c := u.cast
		u.cast = {}
		events.append({"type": "cast_end", "unit": u.id, "ability": c.ability, "result": "dead"})
	u.auras.clear()
	u.queued = {}
	if threat.has(u.id):
		threat[u.id] = 0.0
	events.append({"type": "death", "unit": u.id})


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
