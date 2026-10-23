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
	if OS.get_environment("BALANS") == "sallskap":
		_party_sizes(data)
		quit()
		return
	if OS.get_environment("BALANS") == "forsta":
		_first_descent(data)
		quit()
		return
	if OS.get_environment("BALANS") == "trofeplats":
		_trophy_slot(data)
		quit()
		return
	if OS.get_environment("BALANS") == "grotta":
		_grotto(data)
		quit()
		return
	if OS.get_environment("BALANS") == "elitdiag":
		_elite_diag(data)
		quit()
		return
	if OS.get_environment("BALANS") == "elitskala":
		_elite_scale(data)
		quit()
		return
	if OS.get_environment("BALANS") == "elitsvar":
		_elite_answers(data)
		quit()
		return
	if OS.get_environment("BALANS") == "elitnotning":
		_elite_attrition(data)
		quit()
		return
	if OS.get_environment("BALANS") == "loften":
		_vows(data)
		quit()
		return
	if OS.get_environment("BALANS") == "elitgrupper":
		_elite_groups(data)
		quit()
		return
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


## Sällskapets storlek (0.23): Paladinen + 1, 2 och 3 följeslagare på väntad nivå, och en ny profil (nivå 1, två
## hjältar som växer). Sist varje ny följeslagare i stället för Eira i ett sällskap om fyra.
const PARTIES := [["paladin", "imma"], ["paladin", "imma", "brokk"], ["paladin", "imma", "brokk", "alva"],
		["paladin", "brokk", "alva", "eira"]]


func _party_sizes(data: Dictionary) -> void:
	var realms: Array = data.realms.keys()
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	var lv := HeroStats.expected_level(1)
	print("=== Sällskapets storlek, djup 1, väntad nivå %d (fienderna ×%s) ===" % [lv, str(CombatSim.PARTY_SCALE)])
	for realm_id in realms if OS.get_environment("NIVA_BARA_NYA") != "1" else []:
		for party in PARTIES:
			_party_line(data, realm_id, party, lv, ", ".join(party.slice(1).map(func(id: String) -> String: return data.heroes[id].short)))
		_party_line(data, realm_id, ["paladin", "imma"], 1, "ny profil, befriar fångar", ["imma"])
	if OS.get_environment("NIVA_NYA") == "0":
		return
	# NIVA_BARA_NYA=1 hoppar över storlekarna; NIVA_HJALTE=<id> mäter bara den (0.29.4: båda Realms).
	var only := OS.get_environment("NIVA_HJALTE")
	for realm_id in realms:
		print("=== De nya följeslagarna i stället för Eira (%s, väntad nivå) ===" % realm_id)
		for id in ["eira", "imma", "ronja", "lirien", "tove", "hulda", "ragnhild", "sefir"]:
			if only == "" or only == id:
				_party_line(data, realm_id, ["paladin", "brokk", "alva", id], lv, data.heroes[id].short)


## Första nedstigningen (0.23.3): små sällskap med en ny profils makron (MACRO) mot fyra hjältar med startmakrona,
## på väntad nivå och för en ny profil på nivå 1 (med och utan befriade fångar). BALANS=forsta.
func _first_descent(data: Dictionary) -> void:
	var lv := HeroStats.expected_level(1)
	var fresh := Bot.new_profile_macros(data)
	print("=== Första nedstigningen, djup 1 (fienderna ×%s, högst sällskapet + %d) ===" % [str(CombatSim.PARTY_SCALE),
			CombatSim.EXTRA_ENEMIES])
	for realm_id in ["crypt", "chapel"]:
		_first_line(data, realm_id, "4 hjältar, startmakron, nivå %d" % lv, ["paladin", "brokk", "alva", "eira"], lv, {})
		_first_line(data, realm_id, "Paladinen + Imma, nivå %d" % lv, ["paladin", "imma"], lv, {"bot_macros": fresh})
		_first_line(data, realm_id, "+ Imma + Brokk, nivå %d" % lv, ["paladin", "imma", "brokk"], lv, {"bot_macros": fresh})
		_first_line(data, realm_id, "ny profil nivå 1, befriar fångar", ["paladin", "imma"], 1,
				{"bot_macros": fresh, "recruited": ["imma"]})
		_first_line(data, realm_id, "ny profil nivå 1, ingen befrias", ["paladin", "imma"], 1,
				{"bot_macros": fresh, "recruited": data.heroes.keys()})
		# 0.24: profilens första nedstigning (svagare fiender, ingen fånge) och den andra (Alva i ett fånge-rum).
		_first_line(data, realm_id, "första nedstigningen (trappa %s)" % str(RunState.FIRST_DESCENT_RAMP), ["paladin", "imma"], 1,
				{"bot_macros": fresh, "recruited": data.heroes.keys(), "first_descent": true})
		# 0.25: paladinen går ned ensam och Imma smiter efter direkt efter den första striden.
		_first_line(data, realm_id, "0.25: ensam, Imma efter strid 1", ["paladin"], 1,
				{"bot_macros": fresh, "recruited": data.heroes.keys(), "first_descent": true, "joins": "imma"})
		_first_line(data, realm_id, "andra, nivå 3, en fånge", ["paladin", "imma"], 3,
				{"bot_macros": fresh, "recruited": ["imma"]})


func _first_line(data: Dictionary, realm_id: String, label: String, party: Array, lv: int, extra: Dictionary) -> void:
	var line := "  %-8s %-34s" % [data.realms[realm_id].short, label]
	for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
		var cleared := 0
		var f0 := 0
		var f0_won := 0
		var end0 := 0
		var end0_won := 0
		for seed_value in range(1, RUNS + 1):
			var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party}
			opts.merge(extra.duplicate(true))
			var r := Bot.run_expedition(data, seed_value, skill, {}, {}, 1, realm_id, opts, "simple")
			cleared += 1 if r.cleared else 0
			f0 += r.f0_fights
			f0_won += r.f0_won
			# Våning 1:s slutstrid: nådd om körningen klarades, föll senare eller föll just där.
			var lost: String = r.get("lost_at", "")
			if r.cleared or lost == "f0_end" or (lost != "" and not lost.begins_with("f0_")):
				end0 += 1
				end0_won += 0 if lost == "f0_end" else 1
		line += "  %s %3d %% (v1 %3d %%, v1-slut %3d %%)" % [_skill_name(skill), roundi(100.0 * cleared / RUNS),
				roundi(100.0 * f0_won / maxi(f0, 1)), roundi(100.0 * end0_won / maxi(end0, 1))]
	print(line)


func _party_line(data: Dictionary, realm_id: String, party: Array, lv: int, label: String, recruited := []) -> void:
	var line := "  %-10s %-30s" % [data.realms[realm_id].short, label]
	for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
		var cleared := 0
		var f0 := 0
		var f0_won := 0
		var size := 0
		for seed_value in range(1, RUNS + 1):
			var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party}
			if not recruited.is_empty():
				opts.recruited = recruited
			var r := Bot.run_expedition(data, seed_value, skill, {}, {}, 1, realm_id, opts, "simple")
			cleared += 1 if r.cleared else 0
			f0 += r.f0_fights
			f0_won += r.f0_won
			size += r.levels.size()
		line += "  %s %3d %% (v1 %d %%)" % [_skill_name(skill), roundi(100.0 * cleared / RUNS), roundi(100.0 * f0_won / maxi(f0, 1))]
		if not recruited.is_empty():
			line += " sällskap %.1f" % (float(size) / RUNS)
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


## 0.28 (BALANS=elitgrupper): varje elitgrupp för sig, en strid med fulla Charges och motdragen på, fyra hjältar på
## väntad nivå för djupet och elitpoolens våning. NIVA_REALM begränsar till en Realm.
func _elite_groups(data: Dictionary) -> void:
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	print("=== Elitgrupper (0.28), 4 hjältar, en strid, motdrag på, %d strider per rad ===" % RUNS)
	var party := ["paladin", "brokk", "alva", "eira"]
	for realm_id in realms:
		var pools: Array = data.realms[realm_id].get("elite_pools", [])
		for floor_i in pools.size():
			for enc_id in pools[floor_i]:
				var line := "  %-24s v%d" % [data.encounters[enc_id].name, floor_i + 1]
				for depth in [1, 3]:
					var lv := roundi(HeroStats.enemy_level(depth, floor_i))
					for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
						var won := 0
						var hp_left := 0.0
						var fallen := 0
						for seed_value in range(1, RUNS + 1):
							var opts := {"levels": Bot.party_levels(data, lv, party), "floor": floor_i, "counter": true}
							var r := Bot.run_fight(data, seed_value, skill, enc_id, party, {}, {}, {}, depth, opts)
							won += 1 if r.outcome == "victory" else 0
							var sim: CombatSim = r.sim
							var hp := 0.0
							var max_hp := 0.0
							for h in sim.heroes:
								hp += h.hp if h.alive else 0.0
								max_hp += h.max_hp
							hp_left += hp / max_hp
							fallen += party.size() - int(r.alive)
						# Vinst, liv kvar i sällskapet och stupade per strid: en grupp som alltid vinns kan ändå vara dyr.
						line += "  d%d %s %3d %% liv %2d %% stup %.1f" % [depth, _skill_name(skill), roundi(100.0 * won / RUNS),
								roundi(100.0 * hp_left / RUNS), float(fallen) / RUNS]
				print(line)


## 0.27 grottan (BALANS=grotta): vinst, strider per körning (alla och klarade) och steg, för startmakrona (MACRO) och
## TUNED, i kryptan och kapellet på väntad nivå, och den första nedstigningen (ensam, Imma efter strid 1).
func _grotto(data: Dictionary) -> void:
	var fresh := Bot.new_profile_macros(data)
	print("=== Grottan (0.27), djup 1, %d körningar per rad ===" % RUNS)
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	for realm_id in realms:
		_grotto_line(data, realm_id, "4 hjältar, startmakron, nivå 3", ["paladin", "brokk", "alva", "eira"], 3, {})
		_grotto_line(data, realm_id, "Paladinen + Imma, nivå 3", ["paladin", "imma"], 3, {"bot_macros": fresh})
		_grotto_line(data, realm_id, "första: ensam, Imma efter strid 1", ["paladin"], 1,
				{"bot_macros": fresh, "recruited": data.heroes.keys(), "first_descent": true, "joins": "imma"})


func _grotto_line(data: Dictionary, realm_id: String, label: String, party: Array, lv: int, extra: Dictionary,
		traits := {}, artifacts := {}) -> void:
	var line := "  %-8s %-34s" % [data.realms[realm_id].short, label]
	for run in [[Bot.Skill.MACRO, "simple"], [Bot.Skill.TUNED, "simple"], [Bot.Skill.MACRO, "careful"],
			[Bot.Skill.MACRO, "direct"]]:
		var skill: Bot.Skill = run[0]
		var policy: String = run[1]
		var cleared := 0
		var fights := 0
		var fights_cleared := 0
		var steps := 0
		var lost := {}
		var xp := 0
		for seed_value in range(1, RUNS + 1):
			var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party}
			opts.merge(extra.duplicate(true))
			var r := Bot.run_expedition(data, seed_value, skill, traits, artifacts, 1, realm_id, opts, policy)
			cleared += 1 if r.cleared else 0
			if r.has("lost_at"):
				lost[r.lost_at] = int(lost.get(r.lost_at, 0)) + 1
			fights += int(r.fights)
			steps += int(r.rooms)
			xp += int(r.get("xp", 0))
			if r.cleared:
				fights_cleared += int(r.fights)
		line += "  %s%s %3d %% (strider %.1f, klarade %.1f, steg %d, erf %d)" % [_skill_name(skill),
				{"careful": "-försiktig", "direct": "-direkt"}.get(policy, ""), roundi(100.0 * cleared / RUNS),
				float(fights) / RUNS, float(fights_cleared) / maxi(cleared, 1), roundi(float(steps) / RUNS), xp / RUNS]
		# GROTTA_FORLUST=1: var körningarna förloras (våning och rumstyp, f1_end = bossen).
		if OS.get_environment("GROTTA_FORLUST") != "":
			var keys := lost.keys()
			keys.sort()
			line += " [" + ", ".join(keys.map(func(k: String) -> String: return "%s %d" % [k, lost[k]])) + "]"
	print(line)


## Troféplatsen (BALANS=trofeplats): hela körningar på djup 1 utan troféer, med en buren trofé och en artefakt på nivå 6
## (Forge.TROPHY_LEVEL, tom plats, ingen förmåga), och med en andra trofé i artefakten. Skillnaden mellan de två sista
## raderna är den andra trofén. Troféerna är rimliga val per hjälte ur båda Realms (TROFE_PAR ändrar dem:
## "hjälte:buren:artefakt;…").
const TROPHY_PAIRS := {"paladin": ["rosary", "bone_finger"], "brokk": ["rattler_bone", "warden_helm"],
		"alva": ["prayer_beads", "deacon_stole"], "eira": ["bow_sinew", "quick_shot"], "imma": ["mold_jaw", "scatter_shot"]}
const TROPHY_ART_TYPES := {"paladin": "sword", "brokk": "shield", "alva": "staff", "eira": "sword", "imma": "boots"}


func _trophy_slot(data: Dictionary) -> void:
	var pairs := TROPHY_PAIRS.duplicate(true)
	if OS.get_environment("TROFE_PAR") != "":
		for part in OS.get_environment("TROFE_PAR").split(";"):
			var bits := part.split(":")
			pairs[bits[0]] = [bits[1], bits[2]]
	var fresh := Bot.new_profile_macros(data)
	print("=== Troféplatsen, grottan djup 1, %d körningar per rad (artefakt nivå %d) ===" % [RUNS, Forge.TROPHY_LEVEL])
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	for realm_id in realms:
		for setup in [[["paladin", "brokk", "alva", "eira"], {}, "4 hjältar"], [["paladin", "imma"], {"bot_macros": fresh}, "P+I"]]:
			var party: Array = setup[0]
			var one := {}
			var two := {}
			var arts := {}
			for h in party:
				var own: Array = data.heroes[h].get("traits", []).duplicate()
				one[h] = own + [pairs[h][0]]
				arts[h] = Forge.normalize({"type": TROPHY_ART_TYPES[h], "ability": "", "level": Forge.TROPHY_LEVEL})
			var arts2 := arts.duplicate(true)
			for h in party:
				arts2[h].trophy = pairs[h][1]
			_grotto_line(data, realm_id, "%s, inga troféer" % setup[2], party, 3, setup[1])
			_grotto_line(data, realm_id, "%s, 1 trofé + artefakt 6" % setup[2], party, 3, setup[1], one, arts)
			_grotto_line(data, realm_id, "%s, 2 troféer + artefakt 6" % setup[2], party, 3, setup[1], one, arts2)


## Elitgrupperna under nötning (BALANS=elitnotning): grottkörningar spelas och läget sparas när boten kliver på en
## elitruta (Charges, nivåer, sällskap; livet är fullt i varje strid, som i Siralim). Varje elitgrupp i våningens pool
## spelas sedan från de sparade lägena. Rad: vinst, stupade per strid och Charges som gick åt. NIVA_REALM, ELIT_DJUP
## (t.ex. "1") och ELIT_N (lägen per grupp) begränsar.
func _elite_attrition(data: Dictionary) -> void:
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	var depths := [1, 3]
	if OS.get_environment("ELIT_DJUP") != "":
		depths = [int(OS.get_environment("ELIT_DJUP"))]
	var n := int(OS.get_environment("ELIT_N")) if OS.get_environment("ELIT_N") != "" else RUNS
	var fresh := Bot.new_profile_macros(data)
	# ELIT_SALLSKAP="paladin,imma;paladin,imma,brokk" mäter de sällskapen i stället för fyra hjältar (och hoppar över
	# första nedstigningen).
	var parties := [["paladin", "brokk", "alva", "eira"]]
	if OS.get_environment("ELIT_SALLSKAP") != "":
		parties = Array(OS.get_environment("ELIT_SALLSKAP").split(";")).map(func(p: String) -> Array: return Array(p.split(",")))
	print("=== Elitgrupper under nötning, upp till %d lägen per grupp ===" % n)
	for realm_id in realms:
		for depth in depths:
			var lv: int = 5 * (depth - 1) + 3
			for party in parties:
				var label := "4 hjältar" if party.size() == 4 and parties.size() == 1 else "+".join(party)
				for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
					var snaps := _collect_snaps(data, realm_id, depth, skill, party, lv, {}, n)
					_print_attrition(data, realm_id, depth, skill, snaps, n, label)
			if depth == 1 and OS.get_environment("ELIT_SALLSKAP") == "":
				var snaps := _collect_snaps(data, realm_id, 1, Bot.Skill.MACRO, ["paladin"], 1,
						{"bot_macros": fresh, "recruited": data.heroes.keys(), "first_descent": true, "joins": "imma"}, n, true)
				_print_attrition(data, realm_id, 1, Bot.Skill.MACRO, snaps, n, "första nedstigningen", {"bot_macros": fresh})
				_print_attrition(data, realm_id, 1, Bot.Skill.TUNED, snaps, n, "första nedstigningen")


func _collect_snaps(data: Dictionary, realm_id: String, depth: int, skill: Bot.Skill, party: Array, lv: int,
		extra: Dictionary, n: int, first := false) -> Array:
	var snaps := []
	var seed_value := 1
	# Första nedstigningen: bara våning 1 med Imma (ensam går boten förbi eliten), så fler körningar behövs.
	while seed_value <= n * (8 if first else 3) and (_first_snaps(snaps).size() if first else _snaps_per_floor(snaps)) < n:
		var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party.duplicate(),
				"elite_snaps": snaps}
		opts.merge(extra.duplicate(true))
		opts.elite_snaps = snaps
		Bot.run_expedition(data, seed_value, skill, {}, {}, depth, realm_id, opts, "simple")
		seed_value += 1
	return _first_snaps(snaps) if first else snaps


func _first_snaps(snaps: Array) -> Array:
	return snaps.filter(func(s: Dictionary) -> bool: return s.party.size() >= 2 and int(s.floor) == 0)


## Det minsta antalet sparade lägen på någon våning (båda våningarna ska ha minst n).
func _snaps_per_floor(snaps: Array) -> int:
	var c := [0, 0]
	for s in snaps:
		c[int(s.floor)] += 1
	return mini(c[0], c[1])


## Spelar en elitgrupp från sparade lägen. Ger {won, fallen, spent, n} (stupade och Charges per strid).
static func attrition_fight(data: Dictionary, enc_id: String, snaps: Array, skill: Bot.Skill, depth: int, n: int,
		traits := {}, extra := {}) -> Dictionary:
	var won := 0
	var fallen := 0
	var spent := 0
	var count := mini(n, snaps.size())
	for i in count:
		var s: Dictionary = snaps[i]
		var opts: Dictionary = s.opts.duplicate(true)
		opts.levels = s.levels
		opts.merge(extra, true)
		var charges: Dictionary = s.charges.duplicate(true)
		var r := Bot.run_fight(data, 1000 + i, skill, enc_id, s.party, traits, charges, {}, depth, opts)
		won += 1 if r.outcome == "victory" else 0
		fallen += s.party.size() - int(r.alive)
		var sim: CombatSim = r.sim
		for h in sim.heroes:
			for a in h.charges:
				spent += int(s.charges.get(h.id, {}).get(a, 0)) - int(h.charges[a])
	return {"won": 100.0 * won / maxi(count, 1), "fallen": float(fallen) / maxi(count, 1),
			"spent": float(spent) / maxi(count, 1), "n": count}


func _print_attrition(data: Dictionary, realm_id: String, depth: int, skill: Bot.Skill, snaps: Array, n: int,
		label: String, extra := {}) -> void:
	var pools: Array = data.realms[realm_id].get("elite_pools", [])
	var share := [0.0, 0.0]
	var cnt := [0, 0]
	for s in snaps:
		cnt[int(s.floor)] += 1
		share[int(s.floor)] += Bot.charges_share_of(data, s.charges)
	print("  %s djup %d %s %s (lägen v1 %d, v2 %d; Charges kvar v1 %d %%, v2 %d %%)" % [data.realms[realm_id].short, depth,
			_skill_name(skill), label, cnt[0], cnt[1], roundi(100.0 * share[0] / maxi(cnt[0], 1)),
			roundi(100.0 * share[1] / maxi(cnt[1], 1))])
	for floor_i in pools.size():
		var fs := snaps.filter(func(s: Dictionary) -> bool: return int(s.floor) == floor_i)
		if fs.is_empty():
			continue
		for enc_id in pools[floor_i]:
			var r := attrition_fight(data, enc_id, fs, skill, depth, n, {}, extra)
			print("    %-24s v%d  vinst %3d %%  stup %.2f  Charges %.1f" % [data.encounters[enc_id].name, floor_i + 1,
					roundi(r.won), r.fallen, r.spent])


## Svaren på elitgrupperna (BALANS=elitsvar), djup 1 under nötning: utan svar och med varje kandidat (en trofé på en
## hjälte, ["trofé", hjälte, egenskap], eller en makrorad före varje hjältes första Anfall-rad som anfaller fienden med
## en viss egenskap, ["fokus", egenskap]).
const ELITE_ANSWERS := {
	"crypt_e1": [["trofé", "eira", "mold_jaw"], ["trofé", "alva", "caller_lantern"]],
	"crypt_e2": [["trofé", "alva", "caller_lantern"]],
	"crypt_e3": [["trofé", "paladin", "mist_veil"], ["trofé", "alva", "caller_lantern"]],
	"crypt_e4": [["trofé", "eira", "scribe_quill"], ["fokus", "rattle"]],
	"crypt_e5": [["trofé", "brokk", "bell_rope"]],
	"crypt_e6": [["fokus", "flock_bite"]],
	"chapel_e1": [["trofé", "brokk", "wisp_flame"], ["trofé", "paladin", "lantern_light"], ["fokus", "mirror_ward"]],
	"chapel_e2": [["trofé", "paladin", "torn_banner"]],
	"chapel_e3": [["trofé", "brokk", "mirror_shield"]],
	"chapel_e4": [["trofé", "paladin", "lance_tip"], ["trofé", "eira", "mold_jaw"], ["fokus", "fasting"]],
	"chapel_e5": [["trofé", "paladin", "torn_banner"], ["fokus", "cultist_ward"], ["fokus", "witch_malice"]],
	"chapel_e6": [["fokus", "clouded_blessing"]],
}


## Provfaktor per grupp (BALANS=elitsvar): statsen skalas så att gruppen inte vinns nästan alltid, annars syns inga svar.
## ELIT_PROBE=0 stänger av den.
const ELITE_PROBE := {"crypt_e1": 1.5, "crypt_e2": 1.5, "crypt_e3": 1.6, "crypt_e4": 1.5, "crypt_e5": 1.35, "crypt_e6": 1.25,
	"chapel_e1": 1.9, "chapel_e2": 1.0, "chapel_e3": 1.6, "chapel_e4": 1.25, "chapel_e5": 1.15, "chapel_e6": 1.3}


## ELIT_KAND="möte=hjälte:trofé,fokus:egenskap;möte=…" ersätter kandidaterna; ELIT_MOTEN begränsar till de mötena.
func _answer_list() -> Dictionary:
	if OS.get_environment("ELIT_KAND") == "":
		return ELITE_ANSWERS
	var out := {}
	for part in OS.get_environment("ELIT_KAND").split(";"):
		var kv := part.split("=")
		var list := []
		for c in kv[1].split(","):
			var x := c.split(":")
			if x[0] == "fokus":
				list.append(["fokus", x[1]])
			elif x[0] == "rad":
				list.append(["rad", x[1], x[2], x[3]] + ([x[4]] if x.size() > 4 else []))
			else:
				list.append(["trofé", x[0], x[1]])
		out[kv[0]] = list
	return out


func _elite_answers(data: Dictionary) -> void:
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	var n := int(OS.get_environment("ELIT_N")) if OS.get_environment("ELIT_N") != "" else RUNS
	var party := ["paladin", "brokk", "alva", "eira"]
	print("=== Elitgruppernas svar, djup 1 under nötning, upp till %d lägen per grupp ===" % n)
	for realm_id in realms:
		var pools: Array = data.realms[realm_id].get("elite_pools", [])
		for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
			var snaps := _collect_snaps(data, realm_id, 1, skill, party, 3, {}, n)
			print("  %s %s" % [data.realms[realm_id].short, _skill_name(skill)])
			for floor_i in pools.size():
				var fs := snaps.filter(func(s: Dictionary) -> bool: return int(s.floor) == floor_i)
				for enc_id in pools[floor_i]:
					var answers := _answer_list()
					if (OS.get_environment("ELIT_MOTEN") != "" and not enc_id in OS.get_environment("ELIT_MOTEN").split(",")) \
							or (OS.get_environment("ELIT_KAND") != "" and not answers.has(enc_id)):
						continue
					var probe := 1.0 if OS.get_environment("ELIT_PROBE") == "0" else float(ELITE_PROBE.get(enc_id, 1.0))
					var pfs := fs.map(func(x: Dictionary) -> Dictionary: return _probed(x, probe))
					var base := attrition_fight(data, enc_id, pfs, skill, 1, n)
					var line := "    %-22s utan %3d %% (%.2f)" % [data.encounters[enc_id].name, roundi(base.won), base.fallen]
					for ans in answers.get(enc_id, []):
						var traits := {}
						var extra := {}
						var label := ""
						if ans[0] == "trofé":
							traits[ans[1]] = data.heroes[ans[1]].get("traits", []) + [ans[2]]
							label = "%s:%s" % [ans[1], ans[2]]
						elif ans[0] == "rad":
							# ["rad", hjälte, egenskap, förmåga, (trofé)]: hjälten använder förmågan mot fienden med egenskapen.
							extra.hero_lines = {ans[1]: {"subject": "any_enemy", "cond": "has_trait", "value": ans[2],
									"action": "ability", "ability": ans[3], "target": "that"}}
							label = "%s:%s→%s" % [ans[1], ans[3], ans[2]]
							if ans.size() > 4:
								traits[ans[1]] = data.heroes[ans[1]].get("traits", []) + [ans[4]]
								label += "+" + ans[4]
						else:
							extra.focus_line = {"subject": "any_enemy", "cond": "has_trait", "value": ans[1], "action": "attack",
									"target": "that"}
							label = "fokus:%s" % ans[1]
						var r := attrition_fight(data, enc_id, pfs, skill, 1, n, traits, extra)
						line += "  %s %3d %% (%.2f)" % [label, roundi(r.won), r.fallen]
					print(line)


## Skalning av elitgrupperna (BALANS=elitskala), djup 1 under nötning: vinst och stupade när elitstriden får
## ELIT_SKALA (t.ex. "1,1.2,1.4") gånger statsen. Underlag för mötenas stat_mult.
func _elite_scale(data: Dictionary) -> void:
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	var n := int(OS.get_environment("ELIT_N")) if OS.get_environment("ELIT_N") != "" else RUNS
	var factors := []
	for f in (OS.get_environment("ELIT_SKALA") if OS.get_environment("ELIT_SKALA") != "" else "1,1.2,1.4,1.6").split(","):
		factors.append(float(f))
	var fresh := Bot.new_profile_macros(data)
	print("=== Elitgrupper, skalning under nötning, djup 1, upp till %d lägen per grupp ===" % n)
	for realm_id in realms:
		var pools: Array = data.realms[realm_id].get("elite_pools", [])
		var sets := []
		if OS.get_environment("ELIT_SALLSKAP") != "":
			# Bara de sällskapen (ELIT_SALLSKAP="paladin,imma;…"), som i BALANS=elitnotning.
			for p in OS.get_environment("ELIT_SALLSKAP").split(";"):
				var party := Array(p.split(","))
				for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
					sets.append([skill, "+".join(party), _collect_snaps(data, realm_id, 1, skill, party, 3, {}, n), {}])
		else:
			for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
				sets.append([skill, "4 hjältar", _collect_snaps(data, realm_id, 1, skill, ["paladin", "brokk", "alva", "eira"], 3, {}, n), {}])
			var first := _collect_snaps(data, realm_id, 1, Bot.Skill.MACRO, ["paladin"], 1,
					{"bot_macros": fresh, "recruited": data.heroes.keys(), "first_descent": true, "joins": "imma"}, n, true)
			sets.append([Bot.Skill.MACRO, "första", first, {"bot_macros": fresh}])
			sets.append([Bot.Skill.TUNED, "första", first, {}])
		for set in sets:
			print("  %s %s %s" % [data.realms[realm_id].short, _skill_name(set[0]), set[1]])
			for floor_i in pools.size():
				var fs: Array = set[2].filter(func(s: Dictionary) -> bool: return int(s.floor) == floor_i)
				if fs.is_empty():
					continue
				for enc_id in pools[floor_i]:
					var line := "    %-22s" % data.encounters[enc_id].name
					for f in factors:
						var scaled := []
						for snap in fs:
							var c: Dictionary = snap.duplicate(true)
							c.opts.stat_bonus = float(c.opts.get("stat_bonus", 1.0)) * f
							scaled.append(c)
						var r := attrition_fight(data, enc_id, scaled, set[0], 1, n, {}, set[3])
						line += "  ×%.2f %3d %% (%.2f)" % [f, roundi(r.won), r.fallen]
					print(line)


## Felsökning av en elitgrupp (BALANS=elitdiag ELIT_MOTE=<möte> ELIT_PROBE=<faktor>, valfritt ELIT_SVAR=hjälte:trofé):
## TUNED på djup 1 under nötning; skada per fiende och händelser per strid.
func _elite_diag(data: Dictionary) -> void:
	var enc_id := OS.get_environment("ELIT_MOTE")
	var probe := float(OS.get_environment("ELIT_PROBE")) if OS.get_environment("ELIT_PROBE") != "" else 1.0
	var n := int(OS.get_environment("ELIT_N")) if OS.get_environment("ELIT_N") != "" else 40
	var realm_id := "crypt" if enc_id.begins_with("crypt") else "chapel"
	var floor_i := 0 if enc_id.ends_with("_e1") else 1
	var snaps := _collect_snaps(data, realm_id, 1, Bot.Skill.TUNED, ["paladin", "brokk", "alva", "eira"], 3, {}, n)
	snaps = snaps.filter(func(s: Dictionary) -> bool: return int(s.floor) == floor_i)
	var traits := {}
	if OS.get_environment("ELIT_SVAR") != "":
		var p := OS.get_environment("ELIT_SVAR").split(":")
		traits[p[0]] = data.heroes[p[0]].get("traits", []) + [p[1]]
	var dmg := {}
	var counts := {}
	var won := 0
	var count := mini(n, snaps.size())
	for i in count:
		var s: Dictionary = snaps[i]
		var opts: Dictionary = s.opts.duplicate(true)
		opts.levels = s.levels
		opts.stat_bonus = float(opts.get("stat_bonus", 1.0)) * probe
		var log := []
		opts.event_log = log
		var r := Bot.run_fight(data, 1000 + i, Bot.Skill.TUNED, enc_id, s.party, traits, s.charges.duplicate(true), {}, 1, opts)
		won += 1 if r.outcome == "victory" else 0
		var sim: CombatSim = r.sim
		var hero_ids := sim.heroes.map(func(h: CombatUnit) -> String: return h.id)
		for e in log:
			var key: String = e.get("type", "")
			if key == "aura_applied":
				key += ":" + str(e.get("aura", ""))
			if key == "trait":
				key += ":" + str(e.get("trait", ""))
			if key == "status_skip" or key == "aura_removed":
				key += ":" + str(e.get("aura", "")) + ":" + str(e.get("reason", ""))
			if key == "action":
				key += ":" + str(e.get("unit", "")) + ":" + str(e.get("action", "")) + ":" + str(e.get("ability", ""))
			counts[key] = counts.get(key, 0) + 1
			if e.get("type", "") == "damage" and hero_ids.has(e.get("target", "")):
				var src := str(e.get("source", "?")) + ":" + str(e.get("ability", ""))
				dmg[src] = dmg.get(src, 0.0) + float(e.get("amount", 0))
	print("%s ×%.2f TUNED vinst %d %% (%d strider)" % [enc_id, probe, roundi(100.0 * won / maxi(count, 1)), count])
	var keys := dmg.keys()
	keys.sort_custom(func(a, b) -> bool: return dmg[a] > dmg[b])
	for k in keys:
		print("  skada %-40s %6.1f per strid" % [k, dmg[k] / count])
	var ck := counts.keys()
	ck.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	for k in ck.slice(0, 45):
		print("  %-60s %5.2f" % [k, float(counts[k]) / count])
	for k in ck.slice(45):
		if "sleep" in k or "status_skip" in k:
			print("  %-60s %5.2f" % [k, float(counts[k]) / count])


static func _probed(snap: Dictionary, f: float) -> Dictionary:
	var c: Dictionary = snap.duplicate(true)
	c.opts.stat_bonus = float(c.opts.get("stat_bonus", 1.0)) * f
	return c


## 0.30.17 Löften (BALANS=loften): vinst och hur ofta löftet hålls, för varje löfte mot inget löfte, i kryptan och kapellet
## på väntad nivå (4 hjältar och Paladinen + Imma, startmakron).
func _vows(data: Dictionary) -> void:
	var fresh := Bot.new_profile_macros(data)
	print("=== Löften (0.30.17), djup 1, %d körningar per rad: vinst · hållet · strider ===" % RUNS)
	var vows: Array = [""] + data.vows.keys().filter(func(k: String) -> bool: return not k.begins_with("_"))
	for realm_id in ["crypt", "chapel"]:
		for party in [["paladin", "brokk", "alva", "eira"], ["paladin", "imma"]]:
			var line := "  %-8s %-24s" % [data.realms[realm_id].short, "4 hjältar" if party.size() == 4 else "Paladinen + Imma"]
			for vow in vows:
				var cleared := 0
				var kept := 0
				var fights := 0
				for seed_value in range(1, RUNS + 1):
					var opts := {"levels": Bot.party_levels(data, 3, party), "grow": true, "party": party, "vow": vow}
					if party.size() == 2:
						opts.bot_macros = fresh
					var r := Bot.run_expedition(data, seed_value, Bot.Skill.MACRO, {}, {}, 1, realm_id, opts, "simple")
					cleared += 1 if r.cleared else 0
					kept += 1 if r.cleared and r.get("vow_kept", false) else 0
					fights += int(r.fights)
				var name: String = "inget" if vow == "" else String(data.vows[vow].name)
				line += "  %s %3d %% · %3d %% · %.1f" % [name, roundi(100.0 * cleared / RUNS), roundi(100.0 * kept / maxi(cleared, 1)),
						float(fights) / RUNS]
			print(line)
