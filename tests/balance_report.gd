extends SceneTree
## Balansrapport (0.18): hela körningar på rumskartan, där botarna väljer väg (enkelt: undviker elit
## och portal; girigt: tar elit, portal och skatt först), i båda Realms på djup 1 och 3.
## MACRO kör startmakrona, TUNED de förbättrade makrona i combat_bot.gd. Raderna visar andelen klarade
## körningar, snittet strider per körning och hur ofta Realm Questen blev klar.
##   godot --headless --path . --script res://tests/balance_report.gd
## Mål på djup 1: startmakrona omkring 40 %, TUNED omkring 65 % (som hela kryptan i 0.17).
## Sist nivåerna (0.19): nivå 1, väntad nivå, väntad+2 och träning på djup 1 före djup 2 (BALANS=nivaer för bara dem).
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


## Nivåer (0.19): hela körningar där hjältarna har nivåer och växer av erfarenheten (inget tak), och
## fienderna har djupets och våningens nivå (HeroStats.enemy_level). "v1" = andelen vunna strider på första
## våningen. Sist: att gå tillbaka lönar sig – träna på djup 1 från nivå 1 tills sällskapet vunnit X strider,
## och kör sedan djup 2. NIVA_START, NIVA_STEG, NIVA_XP och NIVA_KURVA prövar andra värden; NIVA_DJUP=1
## bara djup 1, NIVA_REALM en Realm, NIVA_TRANING=0 hoppar över träningen.
func _levels(data: Dictionary) -> void:
	if OS.get_environment("NIVA_START") != "":
		HeroStats.FLOOR_START = float(OS.get_environment("NIVA_START"))
	if OS.get_environment("NIVA_STEG") != "":
		HeroStats.FLOOR_STEP = float(OS.get_environment("NIVA_STEG"))
	if OS.get_environment("NIVA_XP") != "":
		HeroStats.XP_BASE = int(OS.get_environment("NIVA_XP"))
	if OS.get_environment("NIVA_KURVA") != "":
		var k := OS.get_environment("NIVA_KURVA").split(",")
		HeroStats.XP_NEED_SQ = int(k[0])
		HeroStats.XP_NEED_LIN = int(k[1])
		HeroStats.XP_NEED_FLAT = int(k[2])
	var realms: Array = data.realms.keys()
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	var depths: Array = DEPTHS if OS.get_environment("NIVA_DJUP") == "" else [int(OS.get_environment("NIVA_DJUP"))]
	print("fiendernas nivå: start %.2f, steg %.2f per våning, erfarenhet ×%d × djup², till nästa nivå %s …" % [
			HeroStats.FLOOR_START, HeroStats.FLOOR_STEP, HeroStats.XP_BASE,
			", ".join(range(1, 9).map(func(l: int) -> String: return str(HeroStats.xp_to_next(l))))])
	for depth in depths:
		var expected := HeroStats.expected_level(depth)
		print("=== Nivåer, djup %d (fiender nivå %.1f / %.1f / %.1f, väntad nivå %d) ===" % [depth,
				HeroStats.enemy_level(depth, 0), HeroStats.enemy_level(depth, 1), HeroStats.enemy_level(depth, 2), expected])
		var cases := [["nivå 1", 1], ["väntad %d" % expected, expected], ["väntad+2 %d" % (expected + 2), expected + 2]]
		for realm_id in realms:
			for c in cases:
				var opts := {"levels": Bot.party_levels(data, c[1]), "grow": true}
				for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
					_level_line(data, "%s, %s: %s" % [data.realms[realm_id].short, c[0], _skill_name(skill)], skill,
							depth, realm_id, opts)
	if OS.get_environment("NIVA_TRANING") == "0":
		return
	print("=== Gå tillbaka: träna på djup 1 från nivå 1 tills X vunna strider, sedan djup 2 (väntad nivå %d) ===" %
			HeroStats.expected_level(2))
	for realm_id in realms:
		for wins in [0, 20, 50, 100]:
			for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
				_training_line(data, "%s, %d strider på djup 1: %s" % [data.realms[realm_id].short, wins, _skill_name(skill)],
						skill, realm_id, wins)


func _skill_name(skill: int) -> String:
	return "MACRO" if skill == Bot.Skill.MACRO else "TUNED"


func _level_line(data: Dictionary, label: String, skill: int, depth: int, realm_id: String, opts: Dictionary) -> void:
	var cleared := 0
	var f0 := 0
	var f0_won := 0
	var end_level := 0.0
	for seed_value in range(1, RUNS + 1):
		var r := Bot.run_expedition(data, seed_value, skill, {}, {}, depth, realm_id, opts.duplicate(true), "simple")
		cleared += 1 if r.cleared else 0
		f0 += r.f0_fights
		f0_won += r.f0_won
		end_level += HeroStats.party_level(r.levels)
	print("  %-40s klarade %3d %%  v1 %3d %%  slutnivå %4.1f" % [label, roundi(100.0 * cleared / RUNS),
			roundi(100.0 * f0_won / maxi(f0, 1)), end_level / RUNS])


## Träning: körningar på djup 1 (med samma makron) tills sällskapet vunnit `wins` strider, sedan en
## körning på djup 2 med nivåerna det fått. Förlorade körningar ger erfarenhet för striderna som vanns.
func _training_line(data: Dictionary, label: String, skill: int, realm_id: String, wins: int) -> void:
	var cleared := 0
	var start_level := 0.0
	var runs := 0
	for seed_value in range(1, RUNS + 1):
		var levels := Bot.party_levels(data, 1)
		var won := 0
		var n := 0
		while won < wins and n < 60:
			var r := Bot.run_expedition(data, seed_value * 1000 + n, skill, {}, {}, 1, realm_id,
					{"levels": levels, "grow": true}, "simple")
			levels = r.levels
			won += r.fights - (0 if r.cleared else 1)
			n += 1
		runs += n
		start_level += HeroStats.party_level(levels)
		var d2 := Bot.run_expedition(data, seed_value, skill, {}, {}, 2, realm_id, {"levels": levels, "grow": true}, "simple")
		cleared += 1 if d2.cleared else 0
	print("  %-40s nivå %4.1f efter %4.1f körningar  djup 2 klarade %3d %%" % [label, start_level / RUNS,
			float(runs) / RUNS, roundi(100.0 * cleared / RUNS)])


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
