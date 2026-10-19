extends SceneTree
## Balansrapport (0.18): hela körningar på rumskartan, där botarna väljer väg (enkelt: undviker elit
## och portal; girigt: tar elit, portal och skatt först), i båda Realms på djup 1 och 3.
## MACRO kör startmakrona, TUNED de förbättrade makrona i combat_bot.gd. Raderna visar andelen klarade
## körningar, snittet strider per körning och hur ofta Realm Questen blev klar.
##   godot --headless --path . --script res://tests/balance_report.gd
## Mål på djup 1: startmakrona omkring 40 %, TUNED omkring 65 % (som hela kryptan i 0.17).
## Sist nivåerna (0.19): från nivå 1 som växer, väntad nivå, taket och nivå 1 (BALANS=nivaer för bara dem).
## Den äldre rapporten med perk-sökning och varje våningsregel för sig finns i git (0.17).

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 100
const DEPTHS := [1, 3]
## Ett första smide: Brokks sköld med Helande ljus (160 silver).
const ONE_ARTIFACT := {"brokk": {"type": "shield", "ability": "healing_light"}}
## En artefakt per hjälte (640 silver).
const ARTIFACTS := {
	"paladin": {"type": "sword", "ability": "holy_smite"},
	"brokk": {"type": "shield", "ability": "healing_light"},
	"alva": {"type": "staff", "ability": "judgement"},
	"eira": {"type": "boots", "ability": "arrow_rain"},
}
## Det bästa perk-bygget i 0.17 inom poängen: 2 poäng på djup 1, 3 på djup 3 (Gryningens kall med
## lånad Krigsmaskin).
const BEST_PERKS := {1: ["oath_dawn", "ward_war_machine"], 3: ["oath_dawn", "dawn_anointment", "ward_war_machine"]}


func _init() -> void:
	var data := GameData.load_all()
	# BALANS=nivaer kör bara nivåavsnittet (0.19), som går snabbare och värmer mindre.
	if OS.get_environment("BALANS") != "nivaer":
		_runs_without_levels(data)
	_levels(data)
	quit()


## Nivåer (0.19): hela körningar där hjältarna har nivåer och fienderna möter dem (HeroStats).
## "från nivå 1" växer under körningen upp till taket, de andra står på en fast nivå.
func _levels(data: Dictionary) -> void:
	for depth in DEPTHS:
		var expected := HeroStats.expected_level(depth)
		var cap := HeroStats.level_cap(depth - 1)
		print("=== Nivåer, djup %d (väntad nivå %d, tak %d) ===" % [depth, expected, cap])
		var cases := [["väntad nivå %d" % expected, expected, false], ["taket %d" % cap, cap, false]]
		if depth == 1:
			cases.push_front(["från nivå 1, växer", 1, true])
			cases.append(["nivå 1", 1, false])
		for realm_id in data.realms:
			for c in cases:
				var opts := {"levels": Bot.party_levels(data, c[1]), "grow": c[2], "cap": cap}
				_line(data, "%s, %s: MACRO" % [data.realms[realm_id].short, c[0]], Bot.Skill.MACRO, {}, {}, depth,
						realm_id, opts, "simple")
				_line(data, "%s, %s: TUNED" % [data.realms[realm_id].short, c[0]], Bot.Skill.TUNED, {}, {}, depth,
						realm_id, opts, "simple")


func _runs_without_levels(data: Dictionary) -> void:
	for realm_id in data.realms:
		for depth in DEPTHS:
			print("=== %s, djup %d (fiender ×%.2f) ===" % [data.realms[realm_id].name, depth, CombatSim.depth_mult(depth)])
			var best: Array = BEST_PERKS[depth]
			_line(data, "MACRO, enkel väg", Bot.Skill.MACRO, {}, {}, depth, realm_id, {}, "simple")
			_line(data, "MACRO, girig väg", Bot.Skill.MACRO, {}, {}, depth, realm_id, {}, "greedy")
			_line(data, "TUNED, enkel väg", Bot.Skill.TUNED, {}, {}, depth, realm_id, {}, "simple")
			_line(data, "TUNED, girig väg", Bot.Skill.TUNED, {}, {}, depth, realm_id, {}, "greedy")
			_line(data, "TUNED + en artefakt", Bot.Skill.TUNED, {}, ONE_ARTIFACT, depth, realm_id, {}, "simple")
			_line(data, "TUNED + en artefakt + " + _names(data, best), Bot.Skill.TUNED, {"paladin": best},
					ONE_ARTIFACT, depth, realm_id, {}, "simple")
			_line(data, "TUNED + fyra artefakter + " + _names(data, best), Bot.Skill.TUNED, {"paladin": best},
					ARTIFACTS, depth, realm_id, {}, "simple")
	print("=== Instabilitet 2, djup 1 (reglerna slumpas per körning) ===")
	for realm_id in data.realms:
		_line(data, "%s: TUNED" % data.realms[realm_id].short, Bot.Skill.TUNED, {}, {}, 1, realm_id, {}, "simple", 2)
		_line(data, "%s: TUNED + en artefakt + %s" % [data.realms[realm_id].short, _names(data, BEST_PERKS[1])],
				Bot.Skill.TUNED, {"paladin": BEST_PERKS[1]}, ONE_ARTIFACT, 1, realm_id, {}, "simple", 2)
	print("=== Kallens kärnor, djup 1 (MACRO, kryptan, enkel väg) ===")
	for oath_id in data.oaths:
		_line(data, data.traits[oath_id].name, Bot.Skill.MACRO, {"paladin": [oath_id]}, {}, 1, "crypt", {}, "simple")


func _names(data: Dictionary, list: Array) -> String:
	return ", ".join(list.map(func(id: String) -> String: return data.traits[id].name))


## level: instabilitet (−1 = ingen; reglerna slumpas med fröet).
func _line(data: Dictionary, label: String, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int,
		realm_id: String, opts: Dictionary, policy: String, level := -1) -> void:
	var cleared := 0
	var fights := 0
	var quests := 0
	for seed_value in range(1, RUNS + 1):
		var o := opts.duplicate()
		if level >= 0:
			o = Bot.instability_opts(data, seed_value, level)
		var r := Bot.run_expedition(data, seed_value, skill, traits, artifacts, depth, realm_id, o, policy)
		cleared += 1 if r.cleared else 0
		fights += r.fights
		quests += 1 if r.quest_done else 0
	print("  %-62s klarade %3d/%d  strider %4.1f  quest %3d %%" % [label, cleared, RUNS, float(fights) / RUNS,
			roundi(100.0 * quests / RUNS)])
