class_name MacroRunner
extends RefCounted
## Makron som i Siralim Ultimate: ren logik utan noder.
##
## Ett makro är {name, lines}. En rad är:
##   {subject, cond, value, action, ability, target}
## Raderna prövas uppifrån och ned. Den första rad som matchar och går att utföra utförs, och turen
## tar slut. Se docs/plan/0.11-makron.md för vilka regler som är bekräftade i originalet och vilka
## som är våra val (märkta VAL nedan).

const MAX_LINES := 20

const SUBJECTS := ["self", "any_ally", "any_enemy", "ally_1", "ally_2", "ally_3", "ally_4", "all_allies",
		"enemy_1", "enemy_2", "enemy_3", "enemy_4", "enemy_5", "enemy_6", "all_enemies"]
const ACTIONS := ["attack", "ability", "defend", "provoke", "skip", "test_next"]
const TARGETS := ["that", "random_enemy", "random_ally", "self", "enemy_1", "enemy_2", "enemy_3",
		"enemy_4", "enemy_5", "enemy_6", "ally_1", "ally_2", "ally_3", "ally_4"]
## Villkor. Värdet ("value") är procent, ett id (status/egenskap/förmåga) eller ett antal.
const CONDITIONS := ["hp_below", "hp_above", "has_status", "lacks_status", "top_of_timeline",
		"not_top_of_timeline", "bottom_of_timeline", "not_bottom_of_timeline", "has_trait", "lacks_trait",
		"deaths_at_least", "revives_at_least", "is_alive", "highest_speed", "lowest_hp", "own_turn",
		"has_charges"]


## Väljer vad hjälten gör. Returnerar:
##   {ok: true, action, ability, target, line (1-baserad), text, skipped: [text]}
##   {ok: false, text, skipped: [text]}  – inget passade
static func decide(sim: CombatSim, u: CombatUnit, macro: Dictionary) -> Dictionary:
	var lines: Array = macro.get("lines", [])
	var skipped: Array[String] = []
	var i := 0
	while i < mini(lines.size(), MAX_LINES):
		# En kedja: rader med "Pröva nästa rad" följda av en rad med en riktig handling.
		var bound: CombatUnit = null
		var matched := true
		var why: Array[String] = []
		var j := i
		while j < lines.size():
			var line: Dictionary = lines[j]
			var hit := match_line(sim, u, line, bound)
			if hit == null:
				matched = false
				break
			bound = hit
			why.append(describe_condition(sim, line))
			if line.action != "test_next":
				break
			j += 1
		if matched and j < lines.size():
			var line: Dictionary = lines[j]
			var plan := _plan_action(sim, u, line, bound)
			if plan.ok:
				plan.line = j + 1
				plan.skipped = skipped
				plan.text = "%s %s – rad %d matchade: %s." % [u.name, _describe_plan(sim, plan),
						j + 1, " och ".join(why)]
				return plan
			skipped.append("Rad %d hoppades över: %s." % [j + 1, plan.reason])
		elif not matched:
			# VAL: misslyckas en rad i en kedja hoppar vi till raden efter kedjan.
			while j < lines.size() and lines[j].action == "test_next":
				j += 1
		i = j + 1
	return {"ok": false, "skipped": skipped, "text": "%s: inget makro passade." % u.name}


## Prövar en rad. Returnerar figuren som matchade ("that creature"), eller null.
## VAL: med "någon …" och flera träffar blir det den första i platsordning. Efter "Pröva nästa rad"
## prövas en "någon/alla"-rad på samma sida bara mot figuren som matchade raden innan.
static func match_line(sim: CombatSim, u: CombatUnit, line: Dictionary, bound: CombatUnit = null) -> CombatUnit:
	var subject: String = line.subject
	var group := subject_units(sim, u, subject)
	if bound != null and subject in ["any_ally", "any_enemy", "all_allies", "all_enemies"] and group.has(bound):
		group = [bound]
	if subject.begins_with("all_"):
		var alive := group.filter(func(x: CombatUnit) -> bool: return x.alive)
		if alive.is_empty():
			return null
		for x in alive:
			if not test_condition(sim, u, x, line, group):
				return null
		return alive[0]
	for x in group:
		if test_condition(sim, u, x, line, group):
			return x
	return null


static func subject_units(sim: CombatSim, u: CombatUnit, subject: String) -> Array:
	var allies: Array = sim.heroes if u.team == 0 else sim.enemies
	var foes: Array = sim.enemies if u.team == 0 else sim.heroes
	match subject:
		"self":
			return [u]
		"any_ally", "all_allies":
			return allies.duplicate()
		"any_enemy", "all_enemies":
			return foes.duplicate()
	var n := int(subject.get_slice("_", 1)) - 1
	var side: Array = allies if subject.begins_with("ally_") else foes
	return [side[n]] if n >= 0 and n < side.size() else []


static func test_condition(sim: CombatSim, u: CombatUnit, x: CombatUnit, line: Dictionary, group: Array) -> bool:
	var v: Variant = line.get("value", 0)
	match line.cond:
		"is_alive":
			return x.alive
		"deaths_at_least":
			return x.deaths >= int(v)
		"revives_at_least":
			return x.revives >= int(v)
	if not x.alive:
		return false
	match line.cond:
		"hp_below":
			return x.hp_pct() * 100.0 < float(v)
		"hp_above":
			return x.hp_pct() * 100.0 > float(v)
		"has_status":
			return x.auras.has(v)
		"lacks_status":
			return not x.auras.has(v)
		"top_of_timeline":
			return _timeline_pos(sim, x) == 0
		"not_top_of_timeline":
			return _timeline_pos(sim, x) != 0
		"bottom_of_timeline":
			return _timeline_pos(sim, x) == _timeline_len(sim) - 1
		"not_bottom_of_timeline":
			return _timeline_pos(sim, x) != _timeline_len(sim) - 1
		"has_trait":
			return x.traits.has(v)
		"lacks_trait":
			return not x.traits.has(v)
		"highest_speed":
			return _extreme(group, x, func(a: CombatUnit) -> float: return a.speed, true)
		"lowest_hp":
			return _extreme(group, x, func(a: CombatUnit) -> float: return a.hp_pct(), false)
		"own_turn":
			return x.turns_taken == int(v)
		"has_charges":
			return x.charges.get(v, 0) > 0
	return false


## Tidslinjen räknas från den som har turen (0) och sedan kön. VAL: den som har turen räknas som
## överst, eftersom villkoret prövas under dess tur.
static func _timeline_pos(sim: CombatSim, x: CombatUnit) -> int:
	if sim.current == x:
		return 0
	var i := sim.order.find(x.id)
	return i + 1 if i >= 0 else -1


static func _timeline_len(sim: CombatSim) -> int:
	return sim.order.size() + (1 if sim.current else 0)


## Sant om x har det högsta (eller lägsta) värdet bland de levande i gruppen.
## VAL: jämförelsen görs inom radens grupp, inte bland alla figurer (Siralim 3 jämförde alla 12).
static func _extreme(group: Array, x: CombatUnit, value: Callable, highest: bool) -> bool:
	for other in group:
		if other == x or not other.alive:
			continue
		if (highest and value.call(other) > value.call(x)) or (not highest and value.call(other) < value.call(x)):
			return false
	return true


## Går handlingen att utföra? VAL: om inte räknas raden som omatchad och prövningen fortsätter.
static func _plan_action(sim: CombatSim, u: CombatUnit, line: Dictionary, that: CombatUnit) -> Dictionary:
	var action: String = line.action
	var ability_id: String = line.get("ability", "") if action == "ability" else ""
	var reason := sim.can_act(u, action, ability_id)
	if reason != "":
		return {"ok": false, "reason": _reason_text(sim, u, action, ability_id, reason)}
	var target_kind: String = sim.ability(sim.action_ability(u, action, ability_id)).get("target", "self")
	if not target_kind in ["enemy", "ally"]:
		return {"ok": true, "action": action, "ability": ability_id, "target": ""}
	var t := _resolve_target(sim, u, line.get("target", "that"), that)
	var want_enemy := target_kind == "enemy"
	if t == null or not t.alive or (t.team != u.team) != want_enemy:
		return {"ok": false, "reason": "%s har inget giltigt mål (%s)" % [_action_name(sim, action, ability_id),
				describe_target(sim, u, line.get("target", "that"))]}
	return {"ok": true, "action": action, "ability": ability_id, "target": t.id}


static func _resolve_target(sim: CombatSim, u: CombatUnit, target: String, that: CombatUnit) -> CombatUnit:
	var allies: Array = sim.heroes if u.team == 0 else sim.enemies
	var foes: Array = sim.enemies if u.team == 0 else sim.heroes
	match target:
		"that":
			return that
		"self":
			return u
		"random_enemy", "random_ally":
			var pool := (foes if target == "random_enemy" else allies).filter(func(x: CombatUnit) -> bool: return x.alive)
			return null if pool.is_empty() else pool[sim.rng.randi() % pool.size()]
	var n := int(target.get_slice("_", 1)) - 1
	var side: Array = allies if target.begins_with("ally_") else foes
	return side[n] if n >= 0 and n < side.size() else null


# --- Text (för editorn och förklaringsloggen) -------------------------------

static func describe_line(sim_or_data: Variant, line: Dictionary) -> String:
	var data: Dictionary = sim_or_data.data if sim_or_data is CombatSim else sim_or_data
	var head := "Om %s %s" % [subject_name(line.subject), condition_name(data, line.cond, line.get("value", 0))]
	if line.action == "test_next":
		return head + " → pröva nästa rad"
	var act := action_label(data, line.action, line.get("ability", ""))
	if line.action in ["attack", "ability"]:
		var ab: Dictionary = data.abilities.get(line.get("ability", ""), {}) if line.action == "ability" else {}
		if line.action == "attack" or ab.get("target", "") in ["enemy", "ally"]:
			act += " på " + target_name(line.get("target", "that"))
	return head + " → " + act


static func describe_condition(sim: CombatSim, line: Dictionary) -> String:
	return "%s %s" % [subject_name(line.subject), condition_name(sim.data, line.cond, line.get("value", 0))]


static func subject_name(subject: String) -> String:
	match subject:
		"self":
			return "denna hjälte"
		"any_ally":
			return "någon allierad"
		"any_enemy":
			return "någon fiende"
		"all_allies":
			return "alla allierade"
		"all_enemies":
			return "alla fiender"
	return ("allierad " if subject.begins_with("ally_") else "fiende ") + subject.get_slice("_", 1)


static func condition_name(data: Dictionary, cond: String, value: Variant) -> String:
	match cond:
		"hp_below":
			return "har liv < %d %%" % int(value)
		"hp_above":
			return "har liv > %d %%" % int(value)
		"has_status":
			return "har %s" % data.auras.get(value, {}).get("name", str(value))
		"lacks_status":
			return "har inte %s" % data.auras.get(value, {}).get("name", str(value))
		"top_of_timeline":
			return "är överst på tidslinjen"
		"not_top_of_timeline":
			return "är inte överst på tidslinjen"
		"bottom_of_timeline":
			return "är sist på tidslinjen"
		"not_bottom_of_timeline":
			return "är inte sist på tidslinjen"
		"has_trait":
			return "har egenskapen %s" % data.traits.get(value, {}).get("name", str(value))
		"lacks_trait":
			return "har inte egenskapen %s" % data.traits.get(value, {}).get("name", str(value))
		"deaths_at_least":
			return "har stupat minst %d gång(er)" % int(value)
		"revives_at_least":
			return "har väckts minst %d gång(er)" % int(value)
		"is_alive":
			return "lever"
		"highest_speed":
			return "har högst snabbhet"
		"lowest_hp":
			return "har lägst liv"
		"own_turn":
			return "är på sin tur %d" % int(value)
		"has_charges":
			return "har Charges kvar på %s" % data.abilities.get(value, {}).get("name", str(value))
	return cond


static func action_label(data: Dictionary, action: String, ability_id := "") -> String:
	match action:
		"attack":
			return "Anfall"
		"ability":
			return "Förmåga: " + data.abilities.get(ability_id, {}).get("name", ability_id)
		"defend":
			return "Försvara"
		"provoke":
			return "Provocera"
		"skip":
			return "Hoppa över tur"
	return "Pröva nästa rad"


static func target_name(target: String) -> String:
	match target:
		"that":
			return "den som matchade"
		"random_enemy":
			return "slumpvis fiende"
		"random_ally":
			return "slumpvis allierad"
		"self":
			return "sig själv"
	return ("allierad " if target.begins_with("ally_") else "fiende ") + target.get_slice("_", 1)


static func describe_target(sim: CombatSim, _u: CombatUnit, target: String) -> String:
	return target_name(target)


static func _action_name(sim: CombatSim, action: String, ability_id: String) -> String:
	return action_label(sim.data, action, ability_id).replace("Förmåga: ", "")


static func _describe_plan(sim: CombatSim, plan: Dictionary) -> String:
	var verb: String
	match plan.action:
		"attack":
			verb = "anföll"
		"ability":
			verb = "använde " + sim.ability(plan.ability).name
		"defend":
			return "försvarade sig"
		"provoke":
			return "provocerade"
		"skip":
			return "hoppade över turen"
	if plan.target != "":
		verb += (" " if plan.action == "attack" else " på ") + sim.unit(plan.target).name
	return verb


static func _reason_text(sim: CombatSim, u: CombatUnit, action: String, ability_id: String, reason: String) -> String:
	var name := _action_name(sim, action, ability_id)
	match reason:
		"charges":
			return "%s har inga Charges kvar" % name
		"cooldown":
			return "%s är inte redo" % name
		"none":
			return "%s har inte %s" % [u.name, name]
		"dead":
			return "%s har stupat" % u.name
	return reason
