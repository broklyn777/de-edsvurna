class_name Gambits
extends RefCounted
## Makronas villkor som man förtjänar, som gambits i Final Fantasy XII (docs/plan/gambits.md, data/gambits.json).
##
## Ett villkor ger ett omdöme, inte en förmåga: handlingarna kan man alltid välja för hand, men hjälten gör dem bara själv
## när profilen äger villkoret (Profile.gambits). Platserna per hjälte växer med nivån. Ren logik utan noder, så att
## botarna kan använda samma regler (playable) som striden.


static func all(data: Dictionary) -> Dictionary:
	return data.get("gambits", {}).get("gambits", {})


## Villkoren en ny profil börjar med (rarity "start").
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


## Gambits som en rad behöver: villkoret och, för en kedja, "Pröva nästa rad".
static func needs(data: Dictionary, line: Dictionary) -> Array:
	var out := []
	var c := for_cond(data, String(line.get("cond", "")))
	if c != "":
		out.append(c)
	if line.get("action", "") == "test_next":
		var chain := for_cond(data, "test_next")
		if chain != "" and not out.has(chain):
			out.append(chain)
	return out


static func line_owned(data: Dictionary, line: Dictionary, owned: Array) -> bool:
	for id in needs(data, line):
		if not owned.has(id):
			return false
	return true


## Den första gambit raden saknar, eller "".
static func missing(data: Dictionary, line: Dictionary, owned: Array) -> String:
	for id in needs(data, line):
		if not owned.has(id):
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


## Vad en ny följeslagare lär ut när hen ansluter (data/gambits.json "teach"), eller "".
static func teach_for(data: Dictionary, hero_id: String) -> String:
	return String(data.get("gambits", {}).get("teach", {}).get(hero_id, ""))


## Droppen efter en vunnen strid: högst ett villkor (vårt val). kinds = de besegrade fiendernas typer.
## Hemmet går först (ett slag per villkor, boss > elit > vanlig), sedan en liten chans till ett vanligt villkor var som helst.
static func roll_battle(data: Dictionary, owned: Array, kinds: Array, rng: RandomNumberGenerator) -> String:
	var g := all(data)
	var d: Dictionary = data.get("gambits", {}).get("drops", {})
	var order := []
	for id in g:
		if owned.has(id):
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
			if not owned.has(id) and g[id].get("rarity", "") == "common":
				pool.append(id)
		if not pool.is_empty():
			return pool[rng.randi() % pool.size()]
	return ""


static func _rank(entry: Dictionary) -> int:
	return {"common": 0, "chest": 0, "elite": 1, "boss": 2}.get(entry.get("rarity", "common"), 0)


## Droppen ur en skattkista på ett djup: ett kistvillkor från det djupet, annars ibland ett vanligt.
static func roll_chest(data: Dictionary, owned: Array, depth: int, rng: RandomNumberGenerator) -> String:
	var g := all(data)
	var d: Dictionary = data.get("gambits", {}).get("drops", {})
	var chest := []
	var common := []
	for id in g:
		if owned.has(id):
			continue
		if g[id].has("chest") and depth >= int(g[id].chest.get("depth", 1)):
			chest.append(id)
		elif g[id].get("rarity", "") == "common":
			common.append(id)
	chest.sort()
	if not chest.is_empty() and rng.randf() < float(d.get("chest_home", 0.5)):
		return chest[rng.randi() % chest.size()]
	if not common.is_empty() and rng.randf() < float(d.get("chest_any", 0.1)):
		return common[rng.randi() % common.size()]
	return ""


static func name_of(data: Dictionary, id: String) -> String:
	return String(all(data).get(id, {}).get("name", id))


static func clue(data: Dictionary, id: String) -> String:
	return String(all(data).get(id, {}).get("clue", ""))


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
