class_name CombatSim
extends RefCounted
## Turordningsstrid utan noder. Varje runda agerar alla levande en gång, snabbast först.
##
## Flöde: create() → begin() → så länge outcome == "":
##   needs_input() → spelaren väljer act(action, target) för hjälten som har turen
##   annars        → ai_act() låter AI:n agera (fiender, och hjältar när auto är på)
## Töm händelserna med drain_events() och spela upp dem.
##
## Händelser (Dictionary med "type"):
##   round_start {round, order}
##   turn_start {unit}
##   action {unit, action, ability, targets}
##   damage {source, target, amount, crit, school, kind, ability, direct}
##   heal {source, target, amount, effective, overheal, crit, ability}
##   revive {unit}
##   limit {unit, kind} – en egenskap stoppades av gränsen per tur
##
## Skada har en typ ("kind": attack, spell, indirect) skild från skolan (physical, holy, fire,
## shadow). Ett följdanfall från en egenskap är en attack om inget annat sägs.
##   aura_applied {unit, aura, refreshed} / aura_removed {unit, aura}
##   death {unit}
##   trait {unit, trait} – en egenskap slog till (händelser den orsakar bär fältet "trait")
##   release {unit, trait, charge, amount, ability} – en förmåga förbrukade laddningar
##   outcome {result: victory|defeat}

const CRIT_MULT := 1.5
## Säkerhetsgräns för hur djupt egenskaper kan sätta igång varandra.
const MAX_TRAIT_CHAIN := 10
## Som i Siralim: per figur och pågående tur får egenskaper utlösa högst så många attacker,
## besvärjelser och mottagna helningar, plus en övergripande gräns.
const TURN_LIMIT := 5
const TURN_PROC_LIMIT := 60
const ACTIONS := ["attack", "signature", "defend", "provoke"]
## Platser på slagfältet (sim-enheter, se UnitModel.to_world). Bara utseende.
const HERO_SLOTS := [Vector2(-95, 10), Vector2(-150, -75), Vector2(-165, 95), Vector2(-230, 15),
		Vector2(-240, -110), Vector2(-250, 130)]
const ENEMY_SLOTS := [Vector2(105, 5), Vector2(160, -80), Vector2(170, 90), Vector2(235, 0),
		Vector2(245, -120), Vector2(250, 125)]

var data: Dictionary
var units: Array[CombatUnit] = []
var heroes: Array[CombatUnit] = []
var enemies: Array[CombatUnit] = []
var round := 0
var turn_no := 0
## Vilka som har tur kvar den här rundan, i ordning.
var order: Array[String] = []
var current: CombatUnit
var outcome := ""
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
## När sant spelar AI:n även hjältarna.
var auto := false

var _by_id := {}
var _trait_ctx := ""
var _trait_depth := 0
## Medan en förmåga förbrukar laddningar: {unit, ability, mult} för skadebonusen.
var _release_bonus := {}
## unit_id -> {attack, spell, heal} under den pågående turen.
var _turn_counts := {}
var _turn_procs := 0
## Vad varje egenskap har gjort i striden (för kvittot): trait_id -> {unit, procs, damage, heal}.
var trait_stats := {}


## party: hjältar som ersätter mötets förvalda; traits: hero_id -> [trait_id, …] som ersätter
## hjältens förvalda egenskaper.
static func create(game_data: Dictionary, encounter_id: String, seed_value := 1,
		party: Array = [], traits := {}) -> CombatSim:
	var sim := CombatSim.new()
	sim.data = game_data
	sim.rng.seed = seed_value
	var enc: Dictionary = game_data.encounters[encounter_id]
	var hero_ids: Array = party if not party.is_empty() else enc.party
	for i in hero_ids.size():
		var hero := CombatUnit.from_data(hero_ids[i], game_data.heroes[hero_ids[i]], 0)
		hero.position = HERO_SLOTS[i]
		if traits.has(hero.id):
			hero.traits = traits[hero.id].duplicate()
		hero.traits = expand_traits(game_data, hero.traits)
		sim._add(hero)
		sim.heroes.append(hero)
	var counts := {}
	for i in enc.enemies.size():
		var kind: String = enc.enemies[i]
		counts[kind] = counts.get(kind, 0) + 1
		var e := CombatUnit.from_data("%s_%d" % [kind, counts[kind]], game_data.enemies[kind], 1)
		e.kind = kind
		e.position = ENEMY_SLOTS[i]
		e.traits = expand_traits(game_data, e.traits)
		sim._add(e)
		sim.enemies.append(e)
	return sim


# --- Publikt API ------------------------------------------------------------

## Lägger till dolda delar ("parts") av egenskaper, t.ex. en kronas nackdel.
static func expand_traits(game_data: Dictionary, list: Array) -> Array:
	var out := []
	for trait_id in list:
		out.append(trait_id)
		for part in game_data.traits[trait_id].get("parts", []):
			out.append(part)
	return out

func begin() -> void:
	_start_round()


func ability(ability_id: String) -> Dictionary:
	return data.abilities[ability_id]


func unit(unit_id: String) -> CombatUnit:
	return _by_id.get(unit_id)


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func needs_input() -> bool:
	return outcome == "" and current != null and current.team == 0 and not auto


## Förmågan bakom en handling ("attack", "signature", "defend") för en enhet.
func action_ability(u: CombatUnit, action: String) -> String:
	match action:
		"attack":
			return u.attack_ability
		"signature":
			return u.signature
		"provoke":
			return "provoke"
	return "defend"


## Tom sträng om handlingen går att göra, annars en orsak.
func can_act(u: CombatUnit, action: String) -> String:
	if u == null or not u.alive:
		return "dead"
	var ability_id := action_ability(u, action)
	if ability_id == "":
		return "none"
	if u.cooldown_left(ability_id) > 0.0:
		return "cooldown"
	return ""


## Vilka mål spelaren kan välja för handlingen (tom lista = inget mål behövs).
func valid_targets(u: CombatUnit, action: String) -> Array[String]:
	var out: Array[String] = []
	match ability(action_ability(u, action)).get("target", "self"):
		"enemy":
			for x in _taunting_enemies(u):
				out.append(x.id)
		"ally":
			for x in _allies(u):
				out.append(x.id)
	return out


## Förvalt mål om spelaren inte pekar ut något.
func default_target(u: CombatUnit, action: String) -> String:
	var ab := ability(action_ability(u, action))
	if not ab.get("target", "") in ["enemy", "ally"]:
		return ""
	var picked := _pick_targets(u, ab)
	return picked[0] if not picked.is_empty() else ""


## Hjälten som har turen gör en handling. Returnerar "" eller en orsak till att det inte gick.
func act(action: String, target_id := "") -> String:
	if outcome != "" or current == null:
		return "over"
	var reason := can_act(current, action)
	if reason != "":
		return reason
	_perform(current, action_ability(current, action), action, target_id)
	_end_turn()
	return ""


## AI:n agerar för den som har turen.
func ai_act() -> void:
	if outcome != "" or current == null:
		return
	var choice := _hero_choice(current) if current.team == 0 else _enemy_choice(current)
	_perform(current, choice.ability, choice.action, choice.get("target", ""))
	_end_turn()


## Laddningar som förmågan förbrukar när den används: {charge, value, max}, eller tom.
func charge_info(u: CombatUnit, ability_id: String) -> Dictionary:
	for trait_id in u.traits:
		var t: Dictionary = data.traits[trait_id]
		var release: Dictionary = t.get("release", {})
		if release.is_empty() or not _release_matches(u, release, ability_id):
			continue
		var cap := 0.0
		for effect in t.get("effects", []):
			if effect.type == "charge":
				cap = _charge_cap(u, effect)
		return {"charge": release.charge, "value": u.charges.get(release.charge, 0.0), "max": cap}
	return {}


## Ordningen framöver: den som har turen, resten av rundan och sedan nästa runda (för tidslinjen).
## Returnerar [{id, next_round}].
func upcoming(count: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if current and current.alive:
		out.append({"id": current.id, "next_round": false})
	for id in order:
		if unit(id).alive:
			out.append({"id": id, "next_round": false})
	for id in _round_order():
		out.append({"id": id, "next_round": true})
	return out.slice(0, count)


# --- Rundor och turer -------------------------------------------------------

func _round_order() -> Array[String]:
	var alive: Array[CombatUnit] = []
	for u in units:
		if u.alive:
			alive.append(u)
	alive.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool:
		return a.speed > b.speed or (a.speed == b.speed and a.team < b.team))
	var out: Array[String] = []
	for u in alive:
		out.append(u.id)
	return out


func _start_round() -> void:
	round += 1
	order = _round_order()
	_emit({"type": "round_start", "round": round, "order": order.duplicate()})
	for e in enemies:
		if e.alive:
			_choose_intent(e)
	_next_turn()


func _next_turn() -> void:
	current = null
	while outcome == "":
		if order.is_empty():
			_start_round()
			return
		var u := unit(order.pop_front())
		if not u.alive:
			continue
		current = u
		turn_no += 1
		_turn_counts.clear()
		_turn_procs = 0
		_emit({"type": "turn_start", "unit": u.id})
		_tick_turn_start(u)
		_check_outcome()
		if u.alive:
			return
		current = null


## I början av den egna turen: nedkylningar räknas ned och auror verkar och åldras.
func _tick_turn_start(u: CombatUnit) -> void:
	for key in u.cooldowns.keys():
		u.cooldowns[key] = maxf(0.0, u.cooldowns[key] - 1.0)
	for aura_id in u.auras.keys():
		var a: Dictionary = u.auras[aura_id]
		var source := unit(a.source)
		if a.hot > 0.0:
			_heal(source if source else u, u, a.hot, aura_id, false)
		if a.dot > 0.0:
			_deal_damage(source if source else u, u, a.dot, a.school, aura_id, false, false, "indirect")
		if not u.alive:
			return
		if a.duration > 0.0:
			a.remaining -= 1.0
			if a.remaining <= 0.0:
				u.auras.erase(aura_id)
				_emit({"type": "aura_removed", "unit": u.id, "aura": aura_id})


func _end_turn() -> void:
	_check_outcome()
	if outcome == "":
		_next_turn()


func _check_outcome() -> void:
	if outcome != "":
		return
	if enemies.all(func(e: CombatUnit) -> bool: return not e.alive):
		outcome = "victory"
	elif heroes.all(func(h: CombatUnit) -> bool: return not h.alive):
		outcome = "defeat"
	if outcome != "":
		current = null
		_emit({"type": "outcome", "result": outcome})


# --- AI ---------------------------------------------------------------------

## Fienden bestämmer sin handling i början av rundan, så att spelaren kan se den.
func _choose_intent(e: CombatUnit) -> void:
	for rule in e.rules:
		var ability_id: String = rule.ability
		if e.cooldown_left(ability_id) > 0.0 or not _rule_matches(e, rule):
			continue
		e.intent = {"ability": ability_id, "targets": _pick_targets(e, ability(ability_id))}
		return
	e.intent = {"ability": e.attack_ability, "targets": _pick_targets(e, ability(e.attack_ability))}


func _enemy_choice(e: CombatUnit) -> Dictionary:
	if e.intent.is_empty() or e.cooldown_left(e.intent.ability) > 0.0:
		_choose_intent(e)
	var target := ""
	for id in e.intent.targets:
		if unit(id).alive:
			target = id
			break
	return {"action": "intent", "ability": e.intent.ability, "target": target}


func _hero_choice(h: CombatUnit) -> Dictionary:
	for rule in h.rules:
		var action: String = rule.action
		if can_act(h, action) != "" or not _rule_matches(h, rule):
			continue
		return {"action": action, "ability": action_ability(h, action)}
	return {"action": "attack", "ability": h.attack_ability}


func _rule_matches(u: CombatUnit, rule: Dictionary) -> bool:
	var condition: Dictionary = rule.get("if", {})
	if condition.has("ally_hp_below"):
		if not _allies(u).any(func(a: CombatUnit) -> bool: return a.hp_pct() < condition.ally_hp_below):
			return false
	if condition.has("self_hp_below") and u.hp_pct() >= condition.self_hp_below:
		return false
	if condition.has("enemies_at_least") and _enemies(u).size() < condition.enemies_at_least:
		return false
	if condition.get("dead_ally", false) and _pick_targets(u, {"target": "dead_ally"}).is_empty():
		return false
	return true


# --- Förmågor ---------------------------------------------------------------

func _perform(u: CombatUnit, ability_id: String, action: String, target_id: String) -> void:
	var ab := ability(ability_id)
	var targets := _targets_for(u, ab, target_id)
	var cooldown: float = ab.get("cooldown", 0.0)
	if cooldown > 0.0:
		u.cooldowns[ability_id] = cooldown + 1.0  # räknas ned i början av egna turer
	_emit({"type": "action", "unit": u.id, "action": action, "ability": ability_id, "targets": targets})
	_apply_effects(u, ability_id, targets)


func _targets_for(u: CombatUnit, ab: Dictionary, target_id: String) -> Array:
	if ab.get("target", "") == "dead_ally":
		return _pick_targets(u, ab)
	var chosen := unit(target_id) if target_id != "" else null
	var kind: String = ab.get("target", "self")
	if kind == "enemy" and chosen and not _taunting_enemies(u).has(chosen):
		chosen = null  # en provocerande fiende måste anfallas först
	if chosen and chosen.alive and ((kind == "enemy" and chosen.team != u.team) or (kind == "ally" and chosen.team == u.team)):
		return [chosen.id]
	return _pick_targets(u, ab)


func _apply_effects(caster: CombatUnit, ability_id: String, targets: Array) -> void:
	var ab := ability(ability_id)
	var can_crit: bool = not ab.get("no_crit", false)
	var releases := _take_releases(caster, ability_id)
	for effect in ab.get("effects", []):
		for target_id in targets:
			var t := unit(target_id)
			if t == null or (not t.alive and effect.type != "revive"):
				continue
			match effect.type:
				"damage":
					_deal_damage(caster, t, _roll_power(caster, effect), effect.get("school", ab.get("school", "physical")),
							ability_id, can_crit, true, ab.get("kind", "attack"))
				"heal":
					_heal(caster, t, _roll_power(caster, effect), ability_id, can_crit)
				"aura":
					_add_aura(caster, t, effect.aura, float(effect.get("duration", 0.0)))
				"revive":
					_revive(t, float(effect.get("pct", 0.5)))
	_release_bonus = {}
	for r in releases:
		_run_release(caster, r, targets)


func _roll_power(u: CombatUnit, effect: Dictionary) -> float:
	if effect.has("min"):
		return rng.randf_range(effect.min, effect.max)
	return rng.randf_range(u.attack_min, u.attack_max) * float(effect.get("power", 1.0))


func _deal_damage(src: CombatUnit, tgt: CombatUnit, base: float, school: String,
		ability_id: String, can_crit: bool, direct := false, kind := "attack") -> void:
	if not tgt.alive:
		return
	var probe := {"source": src.id, "target": tgt.id, "ability": ability_id, "school": school,
			"direct": direct, "kind": kind, "from_trait": _trait_ctx != ""}
	_convert(src, probe)
	var mult := 1.0
	if direct:
		mult *= _consume_empower(src, probe)
	school = probe.school
	kind = probe.kind
	var crit: bool = can_crit and (rng.randf() < src.crit_chance or _modify(src, "modify_damage", probe, "force_crit", false))
	if crit:
		mult *= CRIT_MULT
	mult *= _modify(src, "modify_damage", probe, "damage_mult", 1.0)
	mult *= _modify(tgt, "modify_damage_taken", probe, "damage_taken_mult", 1.0)
	if _release_bonus.get("unit", "") == src.id and _release_bonus.ability == ability_id:
		mult *= _release_bonus.mult
	var amount := maxf(1.0, roundf(base * mult * tgt.damage_taken()))
	tgt.hp = maxf(0.0, tgt.hp - amount)
	_emit({"type": "damage", "source": src.id, "target": tgt.id, "amount": amount, "crit": crit,
			"school": school, "kind": kind, "ability": ability_id, "direct": direct})
	if tgt.hp <= 0.0:
		_kill(tgt)


## Auror som förstärker nästa direkta anfall (t.ex. Välsignelse) förbrukas här.
func _consume_empower(src: CombatUnit, probe: Dictionary) -> float:
	var mult := 1.0
	for aura_id in src.auras.keys():
		var d: Dictionary = data.auras[aura_id]
		if not d.has("next_attack_mult"):
			continue
		mult *= float(d.next_attack_mult)
		if d.has("school"):
			probe.school = d.school
		src.auras.erase(aura_id)
		_emit({"type": "aura_removed", "unit": src.id, "aura": aura_id})
	return mult


## Egenskaper som ändrar vad skadan räknas som ("convert_damage"), t.ex. följdanfall → Heliga besvärjelser.
func _convert(src: CombatUnit, probe: Dictionary) -> void:
	for trait_id in src.traits:
		var t: Dictionary = data.traits[trait_id]
		if t.trigger == "convert_damage" and _when(src, t.get("when", {}), probe):
			for key in t.convert:
				probe[key] = t.convert[key]


func _revive(u: CombatUnit, pct: float) -> void:
	if u.alive:
		return
	u.alive = true
	u.hp = roundf(u.max_hp * pct)
	u.charges.clear()
	_emit({"type": "revive", "unit": u.id})


func _heal(src: CombatUnit, tgt: CombatUnit, base: float, ability_id: String, can_crit: bool) -> void:
	if not tgt.alive:
		return
	var crit := can_crit and rng.randf() < src.crit_chance
	var mult: float = _modify(src, "modify_heal", {"source": src.id, "target": tgt.id, "ability": ability_id}, "heal_mult", 1.0)
	var amount := roundf(base * (CRIT_MULT if crit else 1.0) * mult)
	var effective := minf(amount, tgt.max_hp - tgt.hp)
	tgt.hp += effective
	_emit({"type": "heal", "source": src.id, "target": tgt.id, "amount": amount,
			"effective": effective, "overheal": amount - effective, "crit": crit, "ability": ability_id})


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
			"school": d.get("school", "physical"), "source": src.id}
	_emit({"type": "aura_applied", "unit": tgt.id, "aura": aura_id, "refreshed": refreshed})
	if d.get("taunt", false):
		for e in enemies:
			if e.alive and not e.intent.is_empty() and ability(e.intent.ability).get("target", "") == "enemy":
				e.intent.targets = [tgt.id]


func _kill(u: CombatUnit) -> void:
	if not u.alive:  # en egenskap kan ha dödat enheten mitt i en annan träff
		return
	u.alive = false
	u.hp = 0.0
	u.auras.clear()
	_emit({"type": "death", "unit": u.id})


# --- Egenskaper (traits) ----------------------------------------------------
# En egenskap lyssnar på en händelsetyp ("trigger") och kör effekter när villkoren i "when"
# stämmer. "modify_*" körs i stället innan siffrorna räknas ut. Händelser som en egenskap
# orsakar bär fältet "trait" och kan sätta igång andra egenskaper, men aldrig samma igen.
# "once_per_turn" begränsar till en gång per tur (vems tur som helst); "internal_cooldown"
# räknas i rundor.

func _emit(e: Dictionary) -> void:
	if _trait_ctx != "":
		e.trait = _trait_ctx
	events.append(e)
	_count_stats(e)
	if _trait_depth >= MAX_TRAIT_CHAIN or outcome != "" or _turn_procs >= TURN_PROC_LIMIT:
		return
	for owner in units:
		if not owner.alive:
			continue
		for trait_id in owner.traits:
			var t: Dictionary = data.traits[trait_id]
			if t.trigger != e.type or e.get("trait", "") == trait_id or not _trait_ready(owner, trait_id, t):
				continue
			if not _when(owner, t.get("when", {}), e):
				continue
			if t.has("chance") and rng.randf() >= float(t.chance):
				continue
			var last: Dictionary = owner.trait_ready.get(trait_id, {})
			var count: int = last.count + 1 if last.get("turn", -1) == turn_no else 1
			owner.trait_ready[trait_id] = {"turn": turn_no, "count": count,
					"round": round + int(t.get("internal_cooldown", 0))}
			_turn_procs += 1
			_run_trait(owner, trait_id, t, e)


func _count_stats(e: Dictionary) -> void:
	var trait_id: String = e.get("trait", "")
	if trait_id == "":
		return
	var st: Dictionary = trait_stats.get(trait_id, {"unit": "", "procs": 0, "damage": 0.0, "heal": 0.0})
	match e.type:
		"trait", "release":
			st.procs += 1
			st.unit = e.unit
		"damage":
			st.damage += e.amount
		"heal":
			st.heal += e.effective
	trait_stats[trait_id] = st


## Siralims gräns: räknar egenskapsutlösta attacker/besvärjelser per figur och mottagna helningar.
## Sant om det får ske.
func _within_limit(u: CombatUnit, kind: String) -> bool:
	var counts: Dictionary = _turn_counts.get(u.id, {})
	var n: int = counts.get(kind, 0)
	if n >= TURN_LIMIT:
		_emit({"type": "limit", "unit": u.id, "kind": kind})
		return false
	counts[kind] = n + 1
	_turn_counts[u.id] = counts
	return true


func _trait_ready(owner: CombatUnit, trait_id: String, t: Dictionary) -> bool:
	var last: Dictionary = owner.trait_ready.get(trait_id, {})
	if last.is_empty():
		return true
	var per_turn := 1 if t.get("once_per_turn", false) else int(t.get("max_per_turn", 0))
	if per_turn > 0 and last.turn == turn_no and last.count >= per_turn:
		return false
	return round >= last.round


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


## self, allies, other_allies (alla utom förmågans mål), enemy, weakest_ally eller ett fält i
## händelsen (source, target, unit …).
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
		"weakest_ally":
			var best: CombatUnit = null
			for a in _allies(owner):
				if best == null or a.hp_pct() < best.hp_pct():
					best = a
			if best:
				out = [best]
		"enemy":
			var foes := _enemies(owner)
			if not foes.is_empty():
				out = [foes[0]]
		_:
			if unit(e.get(where, "")) != null:
				out = [unit(e[where])]
	return out


func _run_trait_effect(owner: CombatUnit, trait_id: String, effect: Dictionary, tgt: CombatUnit, e := {}) -> void:
	var amount := 0.0
	if effect.has("pct_of_event"):
		amount = float(e.get(effect.get("event_field", "amount"), 0.0)) * float(effect.pct_of_event)
	elif effect.type in ["damage", "heal"]:
		amount = _roll_power(owner, effect)
	match effect.type:
		"damage":
			var kind: String = effect.get("kind", "attack")
			if kind != "indirect" and not _within_limit(owner, kind):
				return
			_deal_damage(owner, tgt, amount, effect.get("school", "physical"), trait_id,
					not effect.get("no_crit", false), false, kind)
		"heal":
			if not _within_limit(tgt, "heal"):
				return
			_heal(owner, tgt, amount, trait_id, false)
		"aura":
			_add_aura(owner, tgt, effect.aura, float(effect.get("duration", 0.0)))
		"charge":
			_add_charge(tgt, effect, e)


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
			"target_not_self":
				if e.get("target", "") == owner.id:
					return false
			"min_amount":
				if float(e.get("amount", 0.0)) < want:
					return false
			"min_effective":
				if float(e.get("effective", 0.0)) < want:
					return false
			"action_in":
				if not want.has(e.get("action", "")):
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


# --- Laddningar och förlösning ----------------------------------------------
# En egenskap kan ladda upp en resurs ("charge"-effekt) och förbruka den när hjälten använder
# en viss förmåga ("release").

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
		if not _release_matches(caster, release, ability_id) or amount <= 0.0:
			continue
		caster.charges[release.charge] = 0.0
		mult *= 1.0 + float(release.get("damage_mult_per", 0.0)) * amount
		out.append({"trait": trait_id, "release": release, "amount": amount})
	_release_bonus = {"unit": caster.id, "ability": ability_id, "mult": mult} if mult != 1.0 else {}
	return out


## En förlösning gäller en viss förmåga ("ability") eller bärarens signatur ("action": "signature").
func _release_matches(u: CombatUnit, release: Dictionary, ability_id: String) -> bool:
	if release.get("action", "") == "signature":
		return ability_id == u.signature
	return release.get("ability", "") == ability_id and ability_id != ""


func _run_release(caster: CombatUnit, r: Dictionary, ability_targets: Array) -> void:
	var outer := _trait_ctx
	_trait_ctx = r.trait
	_trait_depth += 1
	_emit({"type": "release", "unit": caster.id, "trait": r.trait, "charge": r.release.charge,
			"amount": r.amount})
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


# --- Hjälpfunktioner --------------------------------------------------------

func _add(u: CombatUnit) -> void:
	units.append(u)
	_by_id[u.id] = u


## Fiender som får anfallas med enkelmål: de som provocerar, annars alla.
func _taunting_enemies(u: CombatUnit) -> Array[CombatUnit]:
	var all := _enemies(u)
	var taunting: Array[CombatUnit] = []
	for x in all:
		if x.auras.keys().any(func(a: String) -> bool: return data.auras[a].get("taunt", false)):
			taunting.append(x)
	return taunting if not taunting.is_empty() else all


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


## Väljer mål efter förmågans "target" och "pick" (lowest, random, first). Hån (taunt) styr
## fiendernas enkelmål.
func _pick_targets(caster: CombatUnit, ab: Dictionary) -> Array:
	var kind: String = ab.get("target", "self")
	match kind:
		"self":
			return [caster.id]
		"dead_ally":
			for x in units:
				if not x.alive and x.team == caster.team:
					return [x.id]
			return []
		"all_enemies":
			return _enemies(caster).map(func(x: CombatUnit) -> String: return x.id)
		"all_allies":
			return _allies(caster).map(func(x: CombatUnit) -> String: return x.id)
	var pool := _enemies(caster) if kind == "enemy" else _allies(caster)
	if pool.is_empty():
		return []
	if kind == "enemy":
		for x in pool:
			if x.auras.keys().any(func(a: String) -> bool: return data.auras[a].get("taunt", false)):
				return [x.id]
	match ab.get("pick", "lowest"):
		"random":
			return [pool[rng.randi() % pool.size()].id]
		"first":
			return [pool[0].id]
	var best := pool[0]
	for x in pool:
		if x.hp_pct() < best.hp_pct():
			best = x
	return [best.id]
