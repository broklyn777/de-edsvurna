class_name MacroRunner
extends RefCounted
## Makron som i Siralim Ultimate: ren logik utan noder.
##
## Ett makro är {name, lines}. En rad är:
##   {subject, cond, value, action, ability, target, enabled}
## enabled (gambits, valfritt, sant om det saknas): en avstängd rad står kvar men hoppas över.
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
		"deaths_at_least", "revives_at_least", "is_alive", "highest_speed", "lowest_hp", "lowest_defense",
		"highest_defense", "highest_attack", "own_turn",
		"has_charges", "has_artifact", "lacks_artifact", "is_immune", "not_immune", "is_silenced",
		"has_buff", "has_debuff", "lacks_buff", "lacks_debuff", "is_charging", "charge_left_at_most",
		"is_channeling", "is_charge_target", "omen_is", "next_ability_echoes", "free_ability_unused", "intends_heal",
		"weak_to", "next_in_turn"]


## Väljer vad hjälten gör. Returnerar:
##   {ok: true, action, ability, target, line (1-baserad), text, skipped: [text], notes: [text]}
##   {ok: false, text, skipped: [text], notes: [text]}  – inget passade
## skipped: rader som stämde men inte gick att utföra. notes (bara med explain, makro-UX förslag 1): varför varje
## rad ovanför den valda inte valdes, också rader vars villkor inte stämde ("Rad 1 stämde inte: … (lägst: Brokk 64 %)").
## När inget passade står raden som var närmast att stämma först.
static func decide(sim: CombatSim, u: CombatUnit, macro: Dictionary, explain := false) -> Dictionary:
	var lines: Array = macro.get("lines", [])
	var skipped: Array[String] = []
	var notes: Array[Dictionary] = []  # {text, near}
	var i := 0
	while i < mini(lines.size(), MAX_LINES):
		# En kedja: rader med "Pröva nästa rad" följda av en rad med en riktig handling.
		var bound: CombatUnit = null
		var matched := true
		var why: Array[String] = []
		var j := i
		while j < lines.size():
			var line: Dictionary = lines[j]
			# Gambits: en avstängd rad (enabled = false) står kvar i listan men prövas inte; i en kedja bryter den kedjan.
			if not line.get("enabled", true):
				matched = false
				if explain:
					notes.append({"text": "Rad %d är avstängd." % (j + 1), "near": 2000.0})
				break
			var hit := match_line(sim, u, line, bound)
			if hit == null:
				matched = false
				if explain:
					notes.append(why_not(sim, u, line, j + 1, bound))
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
				plan.notes = _note_texts(notes, false)
				plan.text = "%s %s – rad %d matchade: %s." % [u.name, _describe_plan(sim, plan),
						j + 1, " och ".join(why)]
				# 0.30.25: en kedja håller fast vid figuren som den första raden valde (VAL, se match_line).
				if j > i and bound != null and lines[i].subject in ["any_ally", "any_enemy"]:
					plan.text += " Kedjan prövade bara %s, som rad %d valde." % [bound.name, i + 1]
				return plan
			skipped.append("Rad %d hoppades över: %s." % [j + 1, plan.reason])
			if explain:
				notes.append({"text": skipped[-1], "near": 0.0})
		elif not matched:
			# VAL: misslyckas en rad i en kedja hoppar vi till raden efter kedjan.
			while j < lines.size() and lines[j].action == "test_next":
				j += 1
		i = j + 1
	return {"ok": false, "skipped": skipped, "notes": _note_texts(notes, true),
			"text": "%s: inget makro passade." % u.name}


static func _note_texts(notes: Array[Dictionary], nearest_first: bool) -> Array[String]:
	var sorted: Array = notes.duplicate()
	if nearest_first:
		# Stabil sortering: lika nära behåller radordningen.
		var idx := range(sorted.size())
		idx.sort_custom(func(a: int, b: int) -> bool:
			return sorted[a].near < sorted[b].near or (sorted[a].near == sorted[b].near and a < b))
		sorted = idx.map(func(i: int) -> Dictionary: return notes[i])
	var out: Array[String] = []
	for n in sorted:
		out.append(n.text)
	return out


## Varför en rad inte stämde, kort och med det närmaste värdet när det finns ett (makro-UX förslag 1).
## Returnerar {text, near}: near är hur långt ifrån raden var (procentenheter liv), annars ett stort tal.
static func why_not(sim: CombatSim, u: CombatUnit, line: Dictionary, number: int, bound: CombatUnit = null) -> Dictionary:
	var subject: String = line.subject
	var group := subject_units(sim, u, subject)
	if bound != null and subject in ["any_ally", "any_enemy", "all_allies", "all_enemies"] and group.has(bound):
		group = [bound]
	var cond: String = line.cond
	var v: Variant = line.get("value", 0)
	var alive := group.filter(func(x: CombatUnit) -> bool: return x.alive)
	var hint := ""
	var near := 1000.0
	var hp_cond := cond in ["hp_below", "hp_above"]
	if group.is_empty():
		hint = "finns inte"
	elif alive.is_empty() and not cond in ["is_alive", "deaths_at_least", "revives_at_least"]:
		hint = "har stupat" if group.size() == 1 else "ingen lever"
	elif subject.begins_with("all_"):
		for x in alive:
			if not test_condition(sim, u, x, line, group):
				hint = "inte %s" % x.name
				if hp_cond:
					hint += " %d %%" % roundi(x.hp_pct() * 100.0)
					near = absf(x.hp_pct() * 100.0 - float(v))
				break
	elif hp_cond:
		# Den som var närmast: lägst liv för "liv <", högst för "liv >".
		var best: CombatUnit = null
		for x in alive:
			if best == null or (cond == "hp_below" and x.hp_pct() < best.hp_pct()) \
					or (cond == "hp_above" and x.hp_pct() > best.hp_pct()):
				best = x
		var pct := best.hp_pct() * 100.0
		near = absf(pct - float(v))
		if group.size() == 1:
			hint = "%s %d %%" % [best.name, roundi(pct)]
		else:
			hint = "%s: %s %d %%" % ["lägst" if cond == "hp_below" else "högst", best.name, roundi(pct)]
	elif group.size() == 1:
		hint = group[0].name
	# I en kedja prövas raden bara mot den som matchade raden innan.
	if bound != null and group.size() == 1 and group[0] == bound and not hint.begins_with(bound.name):
		hint = "prövat mot " + bound.name + ("" if hint == "" else ", " + hint)
	elif bound != null and hint == bound.name:
		hint = "prövat mot " + bound.name
	var text := "Rad %d stämde inte: %s" % [number, describe_condition(sim, line)]
	if hint != "":
		text += " (%s)" % hint
	return {"text": text + ".", "near": near}


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
		"has_buff":
			return x.has_kind("buff")
		"has_debuff":
			return x.has_kind("debuff")
		"lacks_buff":
			return not x.has_kind("buff")
		"lacks_debuff":
			return not x.has_kind("debuff")
		"top_of_timeline":
			return _timeline_pos(sim, x) == 0
		"not_top_of_timeline":
			return _timeline_pos(sim, x) != 0
		"bottom_of_timeline":
			return _timeline_pos(sim, x) == _timeline_len(sim) - 1
		"not_bottom_of_timeline":
			return _timeline_pos(sim, x) != _timeline_len(sim) - 1
		# Gambits 2 (idéfilen): står näst på tidslinjen, efter den som har turen.
		"next_in_turn":
			return _timeline_pos(sim, x) == 1
		# Gambits 2: förmågan (value) slår hårdare mot x just nu (förmågans bonus_vs, t.ex. Rättfärdigt slag mot Förblindad).
		"weak_to":
			return not CombatSim.bonus_vs_for(sim.data.abilities.get(v, {}), x.auras).is_empty()
		"has_trait":
			return x.traits.has(v)
		"lacks_trait":
			return not x.traits.has(v)
		"highest_speed":
			return _extreme(group, x, func(a: CombatUnit) -> float: return a.speed, true)
		"lowest_hp":
			# 0.29.5: lika andel liv (t.ex. alla på 100 %) avgörs av minst liv kvar i antal, inte av ordningen i listan.
			return _extreme(group, x, func(a: CombatUnit) -> float: return snappedf(a.hp_pct(), 0.0001) * 1e6 + a.hp, false)
		# Siralim 3 hade "has the lowest Defense"; Defense räknas med Försvara/Provocera just nu.
		"lowest_defense":
			return _extreme(group, x, func(a: CombatUnit) -> float: return a.defense_now(), false)
		"highest_defense":
			return _extreme(group, x, func(a: CombatUnit) -> float: return a.defense_now(), true)
		"highest_attack":
			return _extreme(group, x, func(a: CombatUnit) -> float: return a.attack, true)
		"own_turn":
			return x.turns_taken == int(v)
		"has_charges":
			return x.charges.get(v, 0) > 0
		"has_artifact":
			return x.artifact.get("type", "") == v
		"is_immune":
			return sim.is_immune(x)
		"not_immune":
			return not sim.is_immune(x)
		"is_silenced":
			return sim.is_silenced(x)
		# 0.31 Varslade attacker: fienden laddar, och slår om högst n av sina egna turer.
		"is_charging":
			return sim.is_charging(x)
		"charge_left_at_most":
			return sim.is_charging(x) and sim.charge_left(x) <= int(v)
		# Väktarsteg 2: håller en annan fiendes laddning vid liv (Midnatt), och är målet för en laddning (Dom).
		"is_channeling":
			return sim.is_channeling(x)
		"is_charge_target":
			return sim.is_charge_target(x)
		# Torun (Inte färdigt än): fiendens avsikt är en helning.
		"intends_heal":
			return sim.intends_heal(x)
		"lacks_artifact":
			return x.artifact.get("type", "") != v
		# 0.30.45 Djupets tecken: vilket tecken som gäller, Ekande valv och Tyst mässa.
		"omen_is":
			return sim.omen == String(v)
		"next_ability_echoes":
			return sim.next_ability_echoes(x)
		"free_ability_unused":
			return sim.free_ability_unused(x)
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
		# 0.30.25: kedjan håller fast vid den figur raden valde ("med den"), nästa rad söker inte efter någon annan.
		return head + (" → pröva nästa rad med den" if line.subject in ["any_ally", "any_enemy"] else " → pröva nästa rad")
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
		"has_buff":
			return "har en buff"
		"has_debuff":
			return "har en debuff"
		"lacks_buff":
			return "har ingen buff"
		"lacks_debuff":
			return "har ingen debuff"
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
			return "har stupat minst %d %s" % [int(value), "gång" if int(value) == 1 else "gånger"]
		"revives_at_least":
			return "har väckts minst %d %s" % [int(value), "gång" if int(value) == 1 else "gånger"]
		"is_alive":
			return "lever"
		"highest_speed":
			return "har högst Speed"
		"lowest_hp":
			return "har lägst liv (%)"
		"lowest_defense":
			return "har lägst Defense"
		"highest_defense":
			return "har högst Defense"
		"highest_attack":
			return "har högst Attack"
		"own_turn":
			return "är på sin tur %d" % int(value)
		"has_charges":
			return "har Charges kvar på %s" % data.abilities.get(value, {}).get("name", str(value))
		"has_artifact":
			return "bär %s" % data.get("artifacts", {}).get(value, {}).get("name", str(value)).to_lower()
		"lacks_artifact":
			return "bär inte %s" % data.get("artifacts", {}).get(value, {}).get("name", str(value)).to_lower()
		"is_immune":
			return "är immun mot skada"
		"not_immune":
			return "kan skadas"
		"is_silenced":
			return "är tystad"
		"is_charging":
			return "laddar en varslad attack"
		"charge_left_at_most":
			return "laddar, slår om högst %d %s" % [int(value), "tur" if int(value) == 1 else "turer"]
		"is_channeling":
			return "håller en laddning vid liv"
		"is_charge_target":
			return "är måltavla för en laddning"
		"omen_is":
			return "tecknet är %s" % data.get("floor_rules", {}).get(value, {}).get("name", str(value))
		"next_ability_echoes":
			return "nästa förmåga ekar (Ekande valv)"
		"free_ability_unused":
			return "laget har sin gratis förmåga kvar (Tyst mässa)"
		"intends_heal":
			return "tänker hela"
		"next_in_turn":
			return "står näst på tidslinjen"
		"weak_to":
			return "är svag mot %s" % data.abilities.get(value, {}).get("name", str(value))
	return cond


static func action_label(data: Dictionary, action: String, ability_id := "") -> String:
	match action:
		"attack":
			return "Anfall"
		"ability":
			# 0.30.45 (Trång passage): förmågor som träffar alla märks, så att makrot kan välja en som träffar ett mål.
			var ab: Dictionary = data.abilities.get(ability_id, {})
			return "Förmåga: " + String(ab.get("name", ability_id)) + (" (alla)" if CombatSim.is_multi_target(ab) else "")
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
		"silenced":
			return "%s är tystad" % u.name
		"sealed":
			return "%s är förseglad" % name
		"forbidden":
			return "ingen kan %s (Ingen gard)" % name.to_lower()
	return reason
