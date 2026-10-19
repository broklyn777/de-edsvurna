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
	if OS.get_environment("BALANS") == "artefakter":
		_artifacts(data)
		quit()
		return
	if OS.get_environment("BALANS") != "nivaer":
		_runs_without_levels(data)
	_levels(data)
	if OS.get_environment("BALANS") != "nivaer":
		_artifacts(data)
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
		if OS.get_environment("NIVA_BARA_VANTAD") != "":
			cases = [cases[1]]
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


## Artefaktnivåer (0.20): en artefakt (Brokks sköld) och en per hjälte på nivå 1, 5 och 10 med material som
## passar rollen, på väntad nivå (som växer). Sist fynd och silver per körning på och under det djupaste djupet.
const ROLE_AMBER := {"paladin": ["amber_red", "amber_orange", "amber_green"], "brokk": ["amber_grey", "amber_teal", "amber_green"],
		"alva": ["amber_blue", "amber_rose", "amber_violet"], "eira": ["amber_red", "amber_yellow", "amber_bronze"]}
const ROLE_TRICKS := {"paladin": ["whetstone", "jagged_rock"], "brokk": ["armor_scrap", "slippery_stone"],
		"alva": ["arcane_sigil", "slate_inspired"], "eira": ["jagged_rock", "curio_vulnerable"]}
## En typisk Magisk sten (två egenskaper, medelkvalitet) per roll.
const ROLE_STONE := {"paladin": [["stat", "attack"], ["trick", "whetstone"]], "brokk": [["stat", "defense"], ["trick", "armor_scrap"]],
		"alva": [["stat", "intelligence"], ["trick", "arcane_sigil"]], "eira": [["stat", "speed"], ["trick", "jagged_rock"]]}


static func built_artifact(base: Dictionary, hero_id: String, level: int) -> Dictionary:
	var a := Forge.normalize(base)
	a.level = level
	for i in Forge.STAT_SLOT_LEVELS.size():
		a.stat_slots[i] = ROLE_AMBER[hero_id][i] if Forge.stat_slot_open(level, i) else ""
	for i in Forge.TRICK_SLOT_LEVELS.size():
		a.trick_slots[i] = ROLE_TRICKS[hero_id][i] if Forge.trick_slot_open(level, i) else ""
	if Forge.nether_open(level):
		var affixes := []
		for x in ROLE_STONE[hero_id]:
			affixes.append({"kind": "stat", "stat": x[1], "pct": 0.08, "q": 1.0} if x[0] == "stat"
					else {"kind": "trick", "trick": x[1], "q": 1.0})
		a.nether = {"id": "bot", "rarity": "magic", "number": 200, "affixes": affixes}
	return a


func _artifacts(data: Dictionary) -> void:
	var realms: Array = data.realms.keys()
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	var depths: Array = DEPTHS if OS.get_environment("NIVA_DJUP") == "" else [int(OS.get_environment("NIVA_DJUP"))]
	for depth in depths:
		var lv := HeroStats.expected_level(depth)
		print("=== Artefakter, djup %d, väntad nivå %d (växer) ===" % [depth, lv])
		for realm_id in realms:
			for level in [0, 1, 5, 10]:
				for all in ([false] if level == 0 else [false, true]):
					var arts := {}
					if level > 0:
						for hero_id in (ARTIFACTS if all else ONE_ARTIFACT):
							arts[hero_id] = built_artifact(ARTIFACTS[hero_id], hero_id, level)
					var label := "ingen artefakt" if level == 0 else ("%s nivå %d" % ["fyra artefakter" if all else "Brokks sköld", level])
					for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
						var cleared := 0
						for seed_value in range(1, RUNS + 1):
							var r := Bot.run_expedition(data, seed_value, skill, {}, arts, depth, realm_id,
									{"levels": Bot.party_levels(data, lv), "grow": true}, "simple")
							cleared += 1 if r.cleared else 0
						print("  %-50s klarade %3d %%" % ["%s, %s: %s" % [data.realms[realm_id].short, label, _skill_name(skill)],
								roundi(100.0 * cleared / RUNS)])
	print("=== Fynd och silver per körning (Kryptan, TUNED, väntad nivå) ===")
	for depth in depths:
		for frontier in [true, false]:
			var sum := {"amber": 0, "trick": 0, "nether": 0, "rare": 0}
			var silver := 0
			for seed_value in range(1, RUNS + 1):
				var r := Bot.run_expedition(data, seed_value, Bot.Skill.TUNED, {}, {}, depth, "crypt",
						{"levels": Bot.party_levels(data, HeroStats.expected_level(depth)), "grow": true, "finds": frontier}, "simple")
				for k in sum:
					sum[k] += r.finds[k]
				silver += r.silver
			print("  djup %d, %-22s bärnsten %4.1f  trick %4.2f  Nether Stones %4.2f (sällsynta %4.2f)  silver %4d" % [depth,
					"djupaste djupet" if frontier else "under det djupaste", float(sum.amber) / RUNS,
					float(sum.trick) / RUNS, float(sum.nether) / RUNS, float(sum.rare) / RUNS, silver / RUNS])
	var total := 0
	var line := "  silver till nivå:"
	for l in range(2, Forge.LEVEL_MAX + 1):
		total += Forge.LEVEL_COST[l - 1]
		line += " %d=%d" % [l, total]
	print(line)


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
