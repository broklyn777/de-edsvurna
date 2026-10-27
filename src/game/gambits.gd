class_name Gambits
extends RefCounted
## Makronas villkor som man förtjänar, som gambits i Final Fantasy XII (docs/plan/gambits.md, data/gambits.json).
##
## Ett villkor ger ett omdöme, inte en förmåga: handlingarna kan man alltid välja för hand, men hjälten gör dem bara själv
## när profilen äger villkoret (Profile.gambits). Platserna per hjälte växer med nivån. Ren logik utan noder, så att
## botarna kan använda samma regler (playable) som striden.


static func all(data: Dictionary) -> Dictionary:
	return data.get("gambits", {}).get("gambits", {})


## Alla klossar som går att förtjäna, med gränserna utbredda ("g_hp_below@50"): id -> post med name, rarity, homes,
## clue, rows (och value för en gräns). Gambits 2 (docs/plan/gambits.md "Klossar").
static func blocks(data: Dictionary) -> Dictionary:
	var out := {}
	var g := all(data)
	for id in g:
		if g[id].has("thresholds"):
			for t in g[id].thresholds:
				out["%s@%s" % [id, t]] = entry(data, "%s@%s" % [id, t])
		else:
			out[id] = entry(data, id)
	return out


## En kloss: posten i gambits.json, eller för en gräns ("g_hp_below@50") familjens post med gränsens egna fält.
## En gräns som inte står i listan (t.ex. 35 ur ett gammalt makro) får familjens fält.
static func entry(data: Dictionary, id: String) -> Dictionary:
	var g := all(data)
	var base := id.get_slice("@", 0)
	if not g.has(base):
		return {}
	var e: Dictionary = g[base].duplicate(true)
	e.id = id
	e.base = base
	if id.contains("@"):
		var v := id.get_slice("@", 1)
		e.value = int(v)
		var over: Dictionary = g[base].get("thresholds", {}).get(v, {"homes": []})
		for k in over:
			e[k] = over[k]
		e.homes = over.get("homes", [])
		if e.get("rarity", "common") in ["elite", "boss"] and e.has("sharp_rows"):
			e.rows = e.sharp_rows
		e.name = String(e.name).replace("{v}", v)
	e.erase("thresholds")
	e.erase("sharp_rows")
	return e


## Klossarna en ny profil börjar med (rarity "start"): bara Lägst liv, introts första rad.
static func starters(data: Dictionary) -> Array:
	var out := []
	var g := all(data)
	for id in g:
		if g[id].get("rarity", "") == "start":
			out.append(id)
	return out


## Villkoret (gambit-id) som äger en makrovillkorskod, eller "" om det är fritt.
static func for_cond(data: Dictionary, cond: String) -> String:
	var g := all(data)
	for id in g:
		if (g[id].get("conds", []) as Array).has(cond):
			return id
	return ""


## Klossen för ett villkor med sitt värde: gränsen är en egen kloss ("g_hp_below@50"), andra värden (status, egenskap,
## förmåga) är fria när man äger villkoret.
static func cond_block(data: Dictionary, cond: String, value: Variant) -> String:
	var id := for_cond(data, cond)
	if id != "" and all(data)[id].has("thresholds"):
		return "%s@%d" % [id, int(value)]
	return id


## Klossen för ett subjekt eller mål, eller "" om det är fritt (Denna hjälte, Någon allierad, Någon fiende, Den som matchade).
static func subject_block(data: Dictionary, subject: String) -> String:
	if (data.get("gambits", {}).get("free_subjects", []) as Array).has(subject):
		return ""
	var g := all(data)
	for id in g:
		if (g[id].get("subjects", []) as Array).has(subject):
			return id
	return ""


static func target_block(data: Dictionary, target: String) -> String:
	if (data.get("gambits", {}).get("free_targets", []) as Array).has(target):
		return ""
	var g := all(data)
	for id in g:
		if (g[id].get("targets", []) as Array).has(target):
			return id
	return ""


## Klossar som en rad behöver: villkoret (med gränsen), subjektet, målet och, för en kedja, "Pröva nästa rad".
## Handlingarna är fria.
static func needs(data: Dictionary, line: Dictionary) -> Array:
	var out := []
	var action := String(line.get("action", ""))
	var ids := [cond_block(data, String(line.get("cond", "")), line.get("value", 0)),
			subject_block(data, String(line.get("subject", "")))]
	if action in ["attack", "ability"]:
		ids.append(target_block(data, String(line.get("target", "that"))))
	if action == "test_next":
		ids.append(for_cond(data, "test_next"))
	for id in ids:
		if id != "" and not out.has(id):
			out.append(id)
	return out


## Sant om profilen äger klossen. Hela familjen ("g_hp_below", gamla profiler) äger alla dess gränser.
static func has(owned: Array, id: String) -> bool:
	return owned.has(id) or (id.contains("@") and owned.has(id.get_slice("@", 0)))


static func line_owned(data: Dictionary, line: Dictionary, owned: Array) -> bool:
	for id in needs(data, line):
		if not has(owned, id):
			return false
	return true


## Den första kloss raden saknar, eller "".
static func missing(data: Dictionary, line: Dictionary, owned: Array) -> String:
	for id in needs(data, line):
		if not has(owned, id):
			return id
	return ""


## Platser för en hjälte på en nivå (vårt val): start, +1 var every_levels nivå, högst max.
static func slots_for_level(data: Dictionary, level: int) -> int:
	var s: Dictionary = data.get("gambits", {}).get("slots", {"start": 3, "every_levels": 2, "max": 12})
	var n := int(s.start) + maxi(level - 1, 0) / maxi(int(s.every_levels), 1)
	return clampi(n, int(s.start), int(s.max))


## Nivån då nästa plats öppnas, eller 0 om alla är öppna.
static func next_slot_level(data: Dictionary, level: int) -> int:
	var s: Dictionary = data.get("gambits", {}).get("slots", {})
	var now := slots_for_level(data, level)
	if now >= int(s.get("max", 12)):
		return 0
	var lv := level + 1
	while slots_for_level(data, lv) == now:
		lv += 1
	return lv


## Varje rads läge: "ok" (körs), "off" (avstängd), "locked" (villkor profilen inte äger) eller "beyond" (under den sista
## platsen). En kedja (rader med "pröva nästa rad" och raden de leder till) är en enhet och tar en plats, och en enhet med
## ett oägt villkor tar ingen plats (vårt val: i FF XII kan ett villkor man inte äger inte stå i listan alls). En avstängd
## enhet tar sin plats, som i FF XII. owned = null betyder att allt är ägt.
static func line_states(data: Dictionary, lines: Array, owned: Variant, slots: int) -> Array:
	var out := []
	var used := 0
	var unit := []
	for i in lines.size():
		var l: Dictionary = lines[i]
		unit.append(l)
		if l.get("action", "") == "test_next" and i < lines.size() - 1:
			continue
		var state := "ok"
		for u in unit:
			if owned != null and not line_owned(data, u, owned):
				state = "locked"
		if state == "ok":
			used += 1
			if used > slots:
				state = "beyond"
			elif unit.any(func(u: Dictionary) -> bool: return not u.get("enabled", true)):
				state = "off"
		for u in unit:
			out.append(state)
		unit = []
	return out


## Platser som makrots ägda enheter tar (PLATSER n / m på gambitsidan).
static func used_slots(data: Dictionary, lines: Array, owned: Variant) -> int:
	var n := 0
	var states := line_states(data, lines, owned, 1000)
	for i in lines.size():
		if states[i] != "locked" and (i == lines.size() - 1 or lines[i].get("action", "") != "test_next"):
			n += 1
	return n


## Raderna som hjälten faktiskt kör (Run.macro_for, botarna): bara rader i läget "ok" (line_states).
static func playable(data: Dictionary, macro: Dictionary, owned: Variant, slots: int) -> Dictionary:
	var lines: Array = macro.get("lines", [])
	var states := line_states(data, lines, owned, slots)
	var out := []
	for i in lines.size():
		if states[i] == "ok":
			out.append(lines[i])
	return {"name": macro.get("name", ""), "lines": out}


## Vad en ny följeslagare utan makroförslag lär ut när hen ansluter (data/gambits.json "teach"), eller "".
static func teach_for(data: Dictionary, hero_id: String) -> String:
	return String(data.get("gambits", {}).get("teach", {}).get(hero_id, ""))


## Droppen efter en vunnen strid: högst en kloss (vårt val). kinds = de besegrade fiendernas typer.
## Hemmet går först (ett slag per kloss, boss > elit > vanlig), sedan en liten chans till en vanlig kloss var som helst.
static func roll_battle(data: Dictionary, owned: Array, kinds: Array, rng: RandomNumberGenerator) -> String:
	var g := blocks(data)
	var d: Dictionary = data.get("gambits", {}).get("drops", {})
	var order := []
	for id in g:
		if has(owned, id):
			continue
		var homes: Array = g[id].get("homes", [])
		if kinds.any(func(k: String) -> bool: return homes.has(k)):
			order.append(id)
	order.sort_custom(func(a: String, b: String) -> bool: return _rank(g[a]) > _rank(g[b]) or (_rank(g[a]) == _rank(g[b]) and a < b))
	for id in order:
		var chance := float(d.get("home_" + String(g[id].get("rarity", "common")), d.get("home_common", 0.4)))
		if rng.randf() < chance:
			return id
	if rng.randf() < float(d.get("anywhere", 0.0)):
		var pool := []
		for id in g:
			if not has(owned, id) and g[id].get("rarity", "") == "common":
				pool.append(id)
		pool.sort()
		if not pool.is_empty():
			return pool[rng.randi() % pool.size()]
	return ""


static func _rank(e: Dictionary) -> int:
	return {"common": 0, "chest": 0, "elite": 1, "boss": 2, "master": 3}.get(e.get("rarity", "common"), 0)


## Droppen ur en skattkista på ett djup: en kistkloss från djupet, annars ibland en vanlig.
static func roll_chest(data: Dictionary, owned: Array, depth: int, rng: RandomNumberGenerator) -> String:
	var g := blocks(data)
	var d: Dictionary = data.get("gambits", {}).get("drops", {})
	var chest := []
	var common := []
	for id in g:
		if has(owned, id):
			continue
		if g[id].has("chest") and depth >= int(g[id].chest.get("depth", 1)):
			chest.append(id)
		elif g[id].get("rarity", "") == "common":
			common.append(id)
	chest.sort()
	common.sort()
	if not chest.is_empty() and rng.randf() < float(d.get("chest_home", 0.5)):
		return chest[rng.randi() % chest.size()]
	if not common.is_empty() and rng.randf() < float(d.get("chest_any", 0.1)):
		return common[rng.randi() % common.size()]
	return ""


static func name_of(data: Dictionary, id: String) -> String:
	return String(entry(data, id).get("name", id))


static func clue(data: Dictionary, id: String) -> String:
	return String(entry(data, id).get("clue", ""))


## Alla rykten om klossen: det vanliga och ett per Realm där den också har hem (Gambits 3, "home_clues").
static func clues(data: Dictionary, id: String) -> Array:
	var e := entry(data, id)
	var out := [String(e.get("clue", ""))]
	for realm in e.get("home_clues", {}):
		if String(e.home_clues[realm]) != "":
			out.append(String(e.home_clues[realm]))
	return out.filter(func(c: String) -> bool: return c != "")


## Fyndet (Gambits 2): en färdig rad för klossen. Radmallarna prövas i ordning; den första som någon hjälte i sällskapet
## kan utföra blir raden, och fyndet väljer den hjälten (för en förmåga den som har den, för Anfall någon, för Försvara och
## Provocera den med högst Defense). En mall vars rad aldrig kan göra nytta hoppas över (row_problem).
## Returnerar {line, hero, block} eller {} om klossen saknas.
static func make_row(data: Dictionary, block_id: String, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	var e := entry(data, block_id)
	if e.is_empty() or party.is_empty():
		return {}
	var rows: Array = e.get("rows", [])
	for t in rows:
		var options := []  # [hero, ability]
		for hero_id in party:
			var h: Dictionary = data.heroes.get(hero_id, {})
			if t.action == "ability":
				for ab in h.get("abilities", []):
					if ability_fits(data, ab, String(t.ability)) and row_problem(data, _fill(data, e, t, ab, rng, hero_id)) == "":
						options.append([hero_id, ab])
						break
			elif data.heroes.has(hero_id) and row_problem(data, _fill(data, e, t, "", rng, hero_id)) == "":
				options.append([hero_id, ""])
		if options.is_empty():
			continue
		var pick: Array = options[rng.randi() % options.size()]
		if t.action in ["defend", "provoke"]:
			options.sort_custom(func(a: Array, b: Array) -> bool: return _base_def(data, a[0]) > _base_def(data, b[0]))
			pick = options[0]
		return {"line": _fill(data, e, t, pick[1], rng, pick[0]), "hero": pick[0], "block": block_id}
	return {}  # varje lista slutar med en mall utan förmåga (test_gambits), så det här händer inte


## Villkor som också matchar döda (test_condition prövar dem före "lever").
const DEAD_CONDS := ["deaths_at_least", "revives_at_least"]


## Kan raden någonsin göra nytta? "" om den kan, annars varför inte: handlingens mål måste gå ihop med subjektet och villkoret
## (ett anfall på en allierad, en sköld på någon som har stupat, en helning på en fiende går aldrig att utföra).
static func row_problem(data: Dictionary, line: Dictionary) -> String:
	var action := String(line.get("action", ""))
	if not action in ["attack", "ability"]:
		return ""
	var subject := String(line.get("subject", ""))
	var enemy_side := subject == "any_enemy" or subject == "all_enemies" or subject.begins_with("enemy_")
	var dead := DEAD_CONDS.has(String(line.get("cond", "")))
	var target := String(line.get("target", "that"))
	var want := "enemy"
	if action == "ability":
		want = String(data.abilities.get(line.get("ability", ""), {}).get("target", "self"))
		if not want in ["enemy", "ally", "dead_ally"]:
			return ""  # träffar alla eller hjälten själv: inget mål
	if want == "dead_ally":
		return "" if target == "that" and not enemy_side and dead else "återupplivar bara den som matchade bland de stupade"
	match target:
		"that":
			if dead:
				return "villkoret kan matcha en stupad, och handlingen kräver ett levande mål"
			if enemy_side != (want == "enemy"):
				return "den som matchade står på fel sida för handlingen"
		"self", "random_ally":
			if want == "enemy":
				return "handlingen kräver en fiende"
		"random_enemy":
			if want != "enemy":
				return "handlingen kräver en allierad"
		_:
			if target.begins_with("ally_") == (want == "enemy"):
				return "målet står på fel sida för handlingen"
	return ""


static func _base_def(data: Dictionary, hero_id: String) -> float:
	return float(data.heroes.get(hero_id, {}).get("stats", {}).get("defense", 0))


## Fyller i mallen. Utan förmåga (reservraden med Anfall) tas värdet ur hjältens första förmåga ("@ability") eller
## dess första status ("@aura", annars Förblindad).
static func _fill(data: Dictionary, e: Dictionary, t: Dictionary, ability: String, rng: RandomNumberGenerator,
		hero_id: String) -> Dictionary:
	var line := {"subject": t.subject, "cond": t.cond, "value": t.get("value", 0), "action": t.action,
			"ability": ability, "target": t.get("target", "that")}
	if e.has("value") and (all(data).get(e.base, {}).get("conds", []) as Array).has(line.cond):
		line.value = e.value
	var own: Array = data.heroes.get(hero_id, {}).get("abilities", [])
	match str(line.value):
		"@ability":
			line.value = ability if ability != "" else (own[0] if not own.is_empty() else "")
		"@aura":
			line.value = _first_aura(data, ability)
			for ab in own:
				if line.value == "":
					line.value = _first_aura(data, ab)
			if line.value == "":
				line.value = "blind"
		"@omen":
			var omens := RunState.omen_ids(data)
			omens.sort()
			line.value = omens[rng.randi() % omens.size()] if not omens.is_empty() else ""
	if ability != "" and not (data.abilities.get(ability, {}).get("target", "") in ["ally", "enemy", "dead_ally"]):
		line.erase("target")  # förmågor som träffar alla eller hjälten själv har inget mål
	return line


## Den första statusen förmågan ger (en debuff mot fiender, annars vilken som helst).
static func _first_aura(data: Dictionary, ability: String) -> String:
	for fx in data.abilities.get(ability, {}).get("effects", []):
		if fx.get("type", "") == "aura" and fx.has("aura"):
			return String(fx.aura)
	return ""


## Passar förmågan radmallens sort? Sorten är ett förmåge-id eller heal, protect, support, cleanse, damage, aoe, debuff,
## bonus, revive.
static func ability_fits(data: Dictionary, ability: String, kind: String) -> bool:
	if ability == kind:
		return true
	var ab: Dictionary = data.abilities.get(ability, {})
	var target := String(ab.get("target", "self"))
	var types: Array = ab.get("effects", []).map(func(fx: Dictionary) -> String: return String(fx.get("type", "")))
	var auras: Array = ab.get("effects", []).filter(func(fx: Dictionary) -> bool: return fx.has("aura")) \
			.map(func(fx: Dictionary) -> String: return String(fx.aura))
	var to_ally := target in ["ally", "all_allies"]
	var to_enemy := target in ["enemy", "all_enemies"]
	match kind:
		"heal":
			return to_ally and (types.has("heal") or auras.any(func(a: String) -> bool: return data.auras.get(a, {}).has("hot")))
		"protect":
			return target == "ally" and (types.has("barrier") or auras.any(func(a: String) -> bool:
					return data.auras.get(a, {}).has("damage_taken_mult")))
		"support":
			return to_ally and not types.has("heal")
		"cleanse":
			return to_ally and (types.has("purge") or types.has("dispel"))
		"damage":
			return target == "enemy" and types.has("damage")
		"aoe":
			return target == "all_enemies" and types.has("damage")
		"debuff":
			return to_enemy and auras.any(func(a: String) -> bool: return data.auras.get(a, {}).get("type", "") != "buff")
		"bonus":
			return to_enemy and ab.has("bonus_vs")
		"revive":
			return target == "dead_ally"
	return false


## Klossarna en följeslagare lär ut när hen ansluter: allt i hens startrader (Run.starter_lines) och makroförslaget,
## eller, utan förslag, raden för hens kloss i "teach". Raden som visas som fynd står i {row}.
static func recruit_gift(data: Dictionary, hero_id: String) -> Dictionary:
	var run_script: GDScript = load("res://scripts/game/run.gd")
	var lines: Array = run_script.starter_lines(data, hero_id, data.get("macros", {}).get(hero_id, {}).get("lines", []))
	var row := {}
	var hint: Dictionary = data.heroes.get(hero_id, {}).get("macro_hint", {})
	if not hint.is_empty():
		var l: Dictionary = {"target": "that", "ability": "", "value": 0}
		l.merge(hint.line, true)
		row = {"line": l, "hero": hero_id, "block": ""}
	elif teach_for(data, hero_id) != "":
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(hero_id)
		row = make_row(data, teach_for(data, hero_id), [hero_id], rng)
	var blocks_out := []
	for l in lines + ([row.line] if not row.is_empty() else []):
		for id in needs(data, l):
			if not blocks_out.has(id):
				blocks_out.append(id)
	return {"blocks": blocks_out, "row": row}


## Samma rad (villkor, värde, handling, förmåga, subjekt och mål), oavsett PÅ/AV.
static func same_line(a: Dictionary, b: Dictionary) -> bool:
	for k in ["subject", "cond", "action", "ability"]:
		if str(a.get(k, "")) != str(b.get(k, "")):
			return false
	var va: Variant = a.get("value", 0)
	var vb: Variant = b.get("value", 0)
	if typeof(va) in [TYPE_INT, TYPE_FLOAT] and typeof(vb) in [TYPE_INT, TYPE_FLOAT]:
		if not is_equal_approx(float(va), float(vb)):
			return false
	elif str(va) != str(vb):
		return false
	return a.get("action", "") in ["defend", "provoke", "skip", "test_next"] or str(a.get("target", "that")) == str(b.get("target", "that"))


## Gambits som en profils sparade makron använder (migrering: allt som redan står i makrona räknas som ägt).
static func used_in(data: Dictionary, macros: Dictionary) -> Array:
	var out := []
	for m in macros.values():
		for l in m.get("lines", []):
			for id in needs(data, l):
				if not out.has(id):
					out.append(id)
	return out


## Flest platser något sparat makro tar (migrering: gamla profiler får minst så många platser).
static func most_lines(macros: Dictionary, data := {}) -> int:
	var n := 0
	for m in macros.values():
		n = maxi(n, used_slots(data, m.get("lines", []), null))
	return n
