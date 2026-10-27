extends SceneTree
## Gambits (docs/plan/gambits.md): hur snabbt kommer villkoren? En ny profil spelar en karriär av nedstigningar med
## botarna (MACRO, en ny profils makron och villkor, som växer med dropparna), och skriptet räknar vunna strider tills
## profilen har hittat sina första 3, 6 och 10 villkor (startvillkoren och det följeslagarna lär ut räknas inte).
##   godot --headless --path . --script res://tests/gambit_drops.gd
## KARRIARER=n (förval 40). Varje karriär: kryptan djup 1 ×2 (den första som profilens första nedstigning), kapellet,
## kryptan, kapellet på djup 1, sedan djup 2 ×4 och kryptan djup 3.

const Bot := preload("res://tests/combat_bot.gd")
const PLAN := [["crypt", 1], ["crypt", 1], ["chapel", 1], ["crypt", 1], ["chapel", 1], ["crypt", 2], ["chapel", 2],
		["crypt", 2], ["chapel", 2], ["crypt", 3]]
const MARKS := [3, 6, 10]


func _init() -> void:
	var data := GameData.load_all()
	var careers := 40
	if OS.get_environment("KARRIARER") != "":
		careers = int(OS.get_environment("KARRIARER"))
	var reached := {3: [], 6: [], 10: []}
	var descent_reached := {3: [], 6: [], 10: []}
	var per_descent := []  # funna villkor efter varje nedstigning, summa över karriärerna
	per_descent.resize(PLAN.size())
	per_descent.fill(0)
	var owned_after := []  # ägda klossar efter varje nedstigning (Gambits 2), summa
	owned_after.resize(PLAN.size())
	owned_after.fill(0)
	var wins_after := []
	wins_after.resize(PLAN.size())
	wins_after.fill(0)
	var first_ids := {}
	for c in range(1, careers + 1):
		var gp := {"owned": Gambits.starters(data), "log": [], "wins": 0}
		var levels := Bot.party_levels(data, 1, ["paladin"])
		var party := ["paladin"]
		var recruited := ["imma"]
		var marks_done := {}
		for d in PLAN.size():
			var realm: String = PLAN[d][0]
			var depth: int = PLAN[d][1]
			var opts := {"levels": levels, "grow": true, "party": party.duplicate(), "gambit_progress": gp,
					"bot_macros": _macros(data, party + ["imma", "alva", "brokk", "eira"]), "recruited": recruited.duplicate()}
			if d == 0:
				opts.first_descent = true
				opts.joins = "imma"
				opts.recruited = data.heroes.keys()
			var r := Bot.run_expedition(data, c * 101 + d, Bot.Skill.MACRO, {}, {}, depth, realm, opts, "simple")
			levels = r.get("levels", levels)
			party = levels.keys()
			for id in party:
				if id != "paladin" and not recruited.has(id):
					recruited.append(id)
			var found := _found(gp)
			per_descent[d] += found.size()
			owned_after[d] += gp.owned.size()
			wins_after[d] += int(gp.wins)
			for m in MARKS:
				if not marks_done.has(m) and found.size() >= m:
					marks_done[m] = true
					reached[m].append(int(found[m - 1].wins))
					descent_reached[m].append(d + 1)
		for e in gp.log:
			first_ids[e.id] = int(first_ids.get(e.id, 0)) + 1
	print("=== Gambits 2: funna rader under en ny profils karriär (%d karriärer, MACRO) ===" % careers)
	for m in MARKS:
		var a: Array = reached[m]
		a.sort()
		if a.is_empty():
			print("  %2d rader: nås inte" % m)
			continue
		print("  %2d rader: %d av %d karriärer, median %d vunna strider (25–75 %%: %d–%d), median nedstigning %d" % [m, a.size(),
				careers, a[a.size() / 2], a[a.size() / 4], a[(a.size() * 3) / 4], _median(descent_reached[m])])
	for d in PLAN.size():
		print("  efter nedstigning %2d (%s djup %d): %.1f rader funna, %.1f klossar ägda (av %d), %.1f vunna strider" % [d + 1,
				PLAN[d][0], PLAN[d][1], float(per_descent[d]) / careers, float(owned_after[d]) / careers, Gambits.blocks(data).size(),
				float(wins_after[d]) / careers])
	var ids := first_ids.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return first_ids[a] > first_ids[b])
	print("  hittade (karriärer): " + ", ".join(ids.map(func(id: String) -> String: return "%s %d" % [id, first_ids[id]])))
	quit()


## Villkor som profilen har hittat (droppar och kistor, inte start eller följeslagare), i ordning.
static func _found(gp: Dictionary) -> Array:
	return gp.log


static func _median(a: Array) -> int:
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2] if not b.is_empty() else 0


## En ny profils makron med makroförslagen för sällskapet (som balance_report.sim_macros).
static func _macros(data: Dictionary, party: Array) -> Dictionary:
	var out := Bot.new_profile_macros(data)
	for hero_id in party:
		var hint: Dictionary = data.heroes.get(hero_id, {}).get("macro_hint", {})
		if hint.is_empty() or not out.has(hero_id):
			continue
		out[hero_id].lines.insert(0, hint.line.duplicate(true))
	return out
