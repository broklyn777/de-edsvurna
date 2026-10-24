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
## KORNINGAR=n ändrar antalet körningar eller strider per rad (förval 100; fler ger mindre brus).
var RUNS := 100
## BALANS=grotta: GROTTA_DJUP=n kör grottan på djup n med väntad nivå (förval 1).
var grotto_depth := 1
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
	if OS.get_environment("KORNINGAR") != "":
		RUNS = int(OS.get_environment("KORNINGAR"))
	var data := GameData.load_all()
	# strid-langd: prov av fiendehelning som mattas, tidigare utmattning i stora strider och Antecknats tak.
	if OS.get_environment("HEAL_FADE") != "":
		CombatSim.heal_fade = float(OS.get_environment("HEAL_FADE"))
	if OS.get_environment("HEAL_FADE_MIN") != "":
		CombatSim.heal_fade_min = float(OS.get_environment("HEAL_FADE_MIN"))
	if OS.get_environment("BIG_EXH") != "":
		CombatSim.big_fight_exhaustion = int(OS.get_environment("BIG_EXH"))
	if OS.get_environment("BIG_EXH_STEP") != "":
		CombatSim.big_fight_step = float(OS.get_environment("BIG_EXH_STEP"))
	if OS.get_environment("NOTED_MAX") != "":
		data.traits.noted.modify.repeat_max = float(OS.get_environment("NOTED_MAX"))
	if OS.get_environment("BIG_HP") != "":
		CombatSim.big_fight_hp = float(OS.get_environment("BIG_HP"))
	if OS.get_environment("BIG_POW") != "":
		CombatSim.big_fight_power = float(OS.get_environment("BIG_POW"))
	# MOTE_MULT=crypt_g2:1.17 prövar ett mötes stat_mult.
	if OS.get_environment("MOTE_MULT") != "":
		var mm := OS.get_environment("MOTE_MULT").split(":")
		data.encounters[mm[0]].stat_mult = float(mm[1])
	if OS.get_environment("BEARER_DEF") != "":
		data.enemies.coffin_bearer.rules[0]["if"].self_hp_below = float(OS.get_environment("BEARER_DEF"))
	# NIVAER=k2|k3|kurva|k2seg: prototyp av andra nivåtakter (HeroStats.set_variant, docs/plan/nivaer-och-charges.md).
	if OS.get_environment("NIVAER") != "":
		HeroStats.set_variant(OS.get_environment("NIVAER"))
		print("Nivåvariant: %s" % HeroStats.variant)
	# DJUPSTEG=0.03: fiendernas stats per djup för mätningen (spelets värde är CombatSim.DEPTH_STEP).
	if OS.get_environment("DJUPSTEG") != "":
		CombatSim.depth_step = float(OS.get_environment("DJUPSTEG"))
		print("Djupsteg: +%.1f %% per djup" % (CombatSim.depth_step * 100.0))
	# PROVOKE_CD=n: Provocera går att använda högst var n:te egna tur (nedkylning n − 1). NO_PROVOKE=1 i combat_bot.gd.
	if not OS.get_environment("PROVOKE_CD") in ["", "0"]:
		data.abilities.provoke.cooldown = float(int(OS.get_environment("PROVOKE_CD")) - 1)
		print("Provocera: högst var %s:e tur" % OS.get_environment("PROVOKE_CD"))
	# BALANS=nivaer kör bara nivåavsnittet (0.19), som går snabbare och värmer mindre.
	if OS.get_environment("BALANS") == "sallskap":
		_party_sizes(data)
		quit()
		return
	if OS.get_environment("BALANS") == "forsta":
		_first_descent(data)
		quit()
		return
	if OS.get_environment("BALANS") == "sigill":
		_seals(data)
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
	if OS.get_environment("BALANS") == "fem":
		_five_by_type(data)
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
	if OS.get_environment("BALANS") == "levande":
		_living(data)
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
	if OS.get_environment("BALANS") == "vaktare":
		_guardians(data)
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


## Roterande väktare (BALANS=vaktare, mot-upprepning.md §1): en strid per bossplats (huvudbossen och väktarna) på djup
## 1–3 med fulla Charges och motdrag, fyra hjältar på väntad nivå. En väktare ska vara ungefär lika svår som huvudbossen
## på samma djup; hela körningarna mäts med BALANS=grotta. NIVA_REALM begränsar till en Realm.
func _guardians(data: Dictionary) -> void:
	var realms := ["crypt", "chapel", "grove", "mountain"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	print("=== Roterande väktare, 4 hjältar, en strid, motdrag på, %d strider per rad ===" % RUNS)
	var party := ["paladin", "brokk", "alva", "eira"]
	for realm_id in realms:
		var r: Dictionary = data.realms[realm_id]
		var slots: Array = [r.floors[r.floors.size() - 1]] + r.get("guardians", [])
		for enc_id in slots:
			var line := "  %-8s %-24s" % [r.short, data.encounters[enc_id].name]
			for depth in [1, 2, 3]:
				var lv := HeroStats.expected_level(depth)
				for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
					var won := 0
					var tl := []
					for seed_value in range(1, RUNS + 1):
						var opts := {"levels": Bot.party_levels(data, lv, party), "floor": 2, "counter": true}
						var res := Bot.run_fight(data, seed_value, skill, enc_id, party, {}, {}, {}, depth, opts)
						won += 1 if res.outcome == "victory" else 0
						tl.append(int(res.turns))
					line += "  d%d %s %3d %%" % [depth, _skill_name(skill), roundi(100.0 * won / RUNS)]
					if OS.get_environment("GROTTA_TURER") == "1":
						line += " t" + _turn_stats({"": tl}, [""]).strip_edges()
			var mark := "" if enc_id == slots[0] else "  (djup %s)" % ", ".join(range(1, 10).filter(func(d: int) -> bool:
				return RunState.guardian_for(data, realm_id, d) == enc_id).map(func(d: int) -> String: return str(d)))
			print(line + mark)


## Bryt två av tre sigill (BALANS=sigill): en strid per bossplats (huvudbossen och väktarna) med fulla Charges och
## motdrag, fyra hjältar på väntad nivå, utan sigill och med vart och ett av dem kvar (RunState.SEAL_TRAITS). Visar hur
## mycket varje fördel kostar; hela körningarna mäts med BALANS=grotta GROTTA_QUEST=1. NIVA_REALM, GROTTA_DJUP.
func _seals(data: Dictionary) -> void:
	var realms := ["crypt", "chapel"] if OS.get_environment("NIVA_REALM") == "" else [OS.get_environment("NIVA_REALM")]
	var depths := [1, 3] if OS.get_environment("GROTTA_DJUP") == "" else [int(OS.get_environment("GROTTA_DJUP"))]
	var variants := [["inga", []]]
	for k in RunState.SEAL_TRAITS:
		variants.append([k, [RunState.SEAL_TRAITS[k]]])
	print("=== Sigillen mot slutstriden, 4 hjältar, fulla Charges, motdrag, %d strider per rad ===" % RUNS)
	var party := ["paladin", "brokk", "alva", "eira"]
	for realm_id in realms:
		var r: Dictionary = data.realms[realm_id]
		var only := OS.get_environment("SIGILL_MOTE")  # SIGILL_MOTE=crypt_g2: bara det mötet
		for enc_id in [r.floors[r.floors.size() - 1]] + r.get("guardians", []):
			if only != "" and enc_id != only:
				continue
			var vs := variants.duplicate()
			if data.encounters[enc_id].get("guardian", false):
				vs += [["mur-väktare", [RunState.GUARDIAN_WARD]]]
			for depth in depths:
				var lv := HeroStats.expected_level(depth)
				var line := "  %-8s %-24s d%d" % [r.short, data.encounters[enc_id].name, depth]
				for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
					line += "  %s" % _skill_name(skill)
					for v in vs:
						var won := 0
						for seed_value in range(1, RUNS + 1):
							var opts := {"levels": Bot.party_levels(data, lv, party), "floor": 2, "counter": true}
							if not v[1].is_empty():
								opts.boss_traits = v[1]
							var res := Bot.run_fight(data, seed_value, skill, enc_id, party, {}, {}, {}, depth, opts)
							won += 1 if res.outcome == "victory" else 0
						line += " %s %3d %%" % [v[0], roundi(100.0 * won / RUNS)]
				print(line)


## 0.27 grottan (BALANS=grotta): vinst, strider per körning (alla och klarade) och steg, för startmakrona (MACRO) och
## TUNED, i kryptan och kapellet på väntad nivå, och den första nedstigningen (ensam, Imma efter strid 1).
func _grotto(data: Dictionary) -> void:
	var fresh := Bot.new_profile_macros(data)
	if OS.get_environment("GROTTA_DJUP") != "":
		grotto_depth = int(OS.get_environment("GROTTA_DJUP"))
	if OS.get_environment("GROTTA_TAK") != "":
		CombatSim.max_enemies = int(OS.get_environment("GROTTA_TAK"))  # prototyp: högst så många fiender (5 = lättare)
	print("=== Grottan (0.27), djup %d, %d körningar per rad, högst %d fiender ===" % [grotto_depth, RUNS, CombatSim.max_enemies])
	if OS.get_environment("GROTTA_FEM") == "1":
		_grotto_five(data)
		return
	if grotto_depth > 1 or OS.get_environment("GROTTA_FYRA") == "1":  # GROTTA_FYRA=1: bara fyra hjältar, också på djup 1
		var lv := HeroStats.expected_level(grotto_depth)
		for realm_id in (realms_for_grotto()):
			_grotto_line(data, realm_id, "4 hjältar, startmakron, nivå %d" % lv, ["paladin", "brokk", "alva", "eira"], lv, {})
		return
	var realms := ["crypt", "chapel"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	for realm_id in realms:
		_grotto_line(data, realm_id, "4 hjältar, startmakron, nivå 3", ["paladin", "brokk", "alva", "eira"], 3, {})
		_grotto_line(data, realm_id, "Paladinen + Imma, nivå 3", ["paladin", "imma"], 3, {"bot_macros": fresh})
		_grotto_line(data, realm_id, "första: ensam, Imma efter strid 1", ["paladin"], 1,
				{"bot_macros": fresh, "recruited": data.heroes.keys(), "first_descent": true, "joins": "imma"})


## Prototyp (sallskap-fem, GROTTA_FEM=1): Trollberget (NIVA_REALM ändrar) på GROTTA_DJUP med väntad nivå. Fyra hjältar som
## förut, fyra när profilen äger fem (fienderna som mot fem), och fem med var och en av lärjungarna som femte (GROTTA_FEMTE
## = id:n med komma). GROTTA_TAK=5: högst fem fiender.
const FIFTHS := ["imma", "solveig", "tove", "sefir", "lirien", "ragnhild", "hulda", "ronja"]


func _grotto_five(data: Dictionary) -> void:
	var lv := HeroStats.expected_level(grotto_depth)
	var realms := ["mountain"] if OS.get_environment("NIVA_REALM") == "" else [OS.get_environment("NIVA_REALM")]
	var four := ["paladin", "brokk", "alva", "eira"]
	var fifths: Array = FIFTHS if OS.get_environment("GROTTA_FEMTE") == "" else Array(OS.get_environment("GROTTA_FEMTE").split(","))
	for realm_id in realms:
		_grotto_line(data, realm_id, "4, förr (berget mot fyra)", four, lv, {"realm_party": 4})
		_grotto_line(data, realm_id, "4 hjältar (berget mot fem)", four, lv, {})
		for fifth in fifths:
			_grotto_line(data, realm_id, "5: + %s" % data.heroes[fifth].get("short", data.heroes[fifth].name), four + [fifth],
					lv, {"owned": 5, "slots": 5})


## Prototyp (sallskap-fem, BALANS=fem): Trollberget (NIVA_REALM) på GROTTA_DJUP per sorts strid, en strid med fulla
## Charges på väntad nivå för våningen: vanliga grupper (alla tre tiers), elitgrupper, väktarna och huvudbossen. Rader:
## fyra som förr (berget mot fyra), fyra mot fem och fem med var och en av FIFTHS (GROTTA_FEMTE). FEM_N strider per möte
## (förval 20). GROTTA_TAK=5: högst fem fiender.
func _five_by_type(data: Dictionary) -> void:
	if OS.get_environment("GROTTA_DJUP") != "":
		grotto_depth = int(OS.get_environment("GROTTA_DJUP"))
	if OS.get_environment("GROTTA_TAK") != "":
		CombatSim.max_enemies = int(OS.get_environment("GROTTA_TAK"))
	var n := int(OS.get_environment("FEM_N")) if OS.get_environment("FEM_N") != "" else 20
	var realm_id := "mountain" if OS.get_environment("NIVA_REALM") == "" else OS.get_environment("NIVA_REALM")
	var m: Dictionary = data.realms[realm_id]
	# [typ, möte, våning, motdrag]
	var fights := []
	for tier in m.pools.size():
		for enc_id in m.pools[tier]:
			fights.append(["vanlig", enc_id, mini(tier, 1), false])
	for f in m.elite_pools.size():
		for enc_id in m.elite_pools[f]:
			fights.append(["elit", enc_id, f, true])
	for enc_id in m.get("guardians", []):
		fights.append(["väktare", enc_id, 2, true])
	fights.append(["boss", m.floors[2], 2, true])
	print("=== Sällskap om fem: %s djup %d per sorts strid, %d strider per möte, högst %d fiender ===" % [m.short,
			grotto_depth, n, CombatSim.max_enemies])
	var four := ["paladin", "brokk", "alva", "eira"]
	var fifths: Array = FIFTHS if OS.get_environment("GROTTA_FEMTE") == "" else Array(OS.get_environment("GROTTA_FEMTE").split(","))
	var rows := [["4, förr (mot fyra)", four, 0], ["4 (mot fem)", four, 5]]
	for fifth in fifths:
		rows.append(["5: + %s" % data.heroes[fifth].get("short", data.heroes[fifth].name), four + [fifth], 5])
	for row in rows:
		var line := "  %-24s" % row[0]
		for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
			var won := {}
			var total := {}
			for fight in fights:
				var lv := roundi(HeroStats.enemy_level(grotto_depth, int(fight[2])))
				for seed_value in range(1, n + 1):
					var opts := {"levels": Bot.party_levels(data, lv, row[1]), "floor": fight[2], "counter": fight[3]}
					if int(row[2]) > 0:
						opts.full_party = int(row[2])
					if fight[0] == "elit":
						opts.force_elites = 1
					var r := Bot.run_fight(data, seed_value, skill, fight[1], row[1], {}, {}, {}, grotto_depth, opts)
					won[fight[0]] = int(won.get(fight[0], 0)) + (1 if r.outcome == "victory" else 0)
					total[fight[0]] = int(total.get(fight[0], 0)) + 1
			line += "  %s" % _skill_name(skill)
			for kind in ["vanlig", "elit", "väktare", "boss"]:
				line += " %s %3d %%" % [kind, roundi(100.0 * int(won.get(kind, 0)) / maxi(int(total.get(kind, 0)), 1))]
		print(line)


## strid-langd: "sort med/p90/max (n)" för nycklarna i {nyckel: [turer]}.
static func _turn_stats(turns: Dictionary, keys: Array) -> String:
	var bits := []
	for k in keys:
		if not turns.has(k) or (turns[k] as Array).is_empty():
			continue
		var a: Array = (turns[k] as Array).duplicate()
		a.sort()
		bits.append("%s %d/%d/%d (%d)" % [k, a[a.size() / 2], a[mini(a.size() - 1, int(a.size() * 0.9))], a[a.size() - 1], a.size()])
	return ", ".join(bits)


func realms_for_grotto() -> Array:
	return ["crypt", "chapel"] if OS.get_environment("NIVA_REALM") == "" else [OS.get_environment("NIVA_REALM")]


func _grotto_line(data: Dictionary, realm_id: String, label: String, party: Array, lv: int, extra: Dictionary,
		traits := {}, artifacts := {}) -> void:
	var line := "  %-8s %-34s" % [data.realms[realm_id].short, label]
	var runs := [[Bot.Skill.MACRO, "simple"], [Bot.Skill.TUNED, "simple"], [Bot.Skill.MACRO, "careful"],
			[Bot.Skill.MACRO, "direct"]]
	for run in runs.slice(0, 2) if OS.get_environment("GROTTA_KORT") == "1" else runs:  # GROTTA_KORT=1: MACRO och TUNED
		var skill: Bot.Skill = run[0]
		var policy: String = run[1]
		var cleared := 0
		var fights := 0
		var fights_cleared := 0
		var steps := 0
		var lost := {}
		var xp := 0
		var kinds := {}
		var by_quest := {}  # GROTTA_QUEST=1: våningar per quest-typ [nådda, klarade], och körningar med/utan sigill
		var seal_runs := [0, 0, 0, 0]
		var boss_left := {}
		var turns := {}  # GROTTA_TURER=1: turer per strid per sort och möte
		for seed_value in range(1, RUNS + 1):
			var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party}
			opts.merge(extra.duplicate(true))
			var r := Bot.run_expedition(data, seed_value, skill, traits, artifacts, grotto_depth, realm_id, opts, policy)
			cleared += 1 if r.cleared else 0
			if r.has("lost_at"):
				lost[r.lost_at] = int(lost.get(r.lost_at, 0)) + 1
			fights += int(r.fights)
			steps += int(r.rooms)
			xp += int(r.get("xp", 0))
			for k in r.get("by_kind", {}):
				var a: Array = kinds.get(k, [0, 0])
				kinds[k] = [int(a[0]) + int(r.by_kind[k][0]), int(a[1]) + int(r.by_kind[k][1])]
			for k in r.get("turns", {}):
				var tl: Array = turns.get(k, [])
				tl.append_array(r.turns[k])
				turns[k] = tl
			if r.cleared:
				fights_cleared += int(r.fights)
			var has_seal := false
			for fq in r.get("floor_quests", []):
				var key: String = "%s f%d" % [fq.type, int(fq.floor) + 1]
				var a: Array = by_quest.get(key, [0, 0])
				by_quest[key] = [int(a[0]) + 1, int(a[1]) + (1 if fq.passed else 0)]
				if fq.type == RunState.SEAL_QUEST:
					has_seal = true
					var lk: String = "lämnade " + String(fq.left)
					var b: Array = by_quest.get(lk, [0, 0])
					by_quest[lk] = [int(b[0]) + 1, int(b[1]) + (1 if fq.passed else 0)]
			var idx := 0 if has_seal else 2
			seal_runs[idx] += 1
			seal_runs[idx + 1] += 1 if r.cleared else 0
			# Bossens sista strid med kvarlämnade sigill: [nådda, vunna] per fördel.
			var reached_boss: bool = r.get("floor_quests", []).size() >= RunState.FLOORS_PER_RUN
			if reached_boss:
				var left_key := "+".join(r.get("seals_left", []).map(func(t: String) -> String: return t.trim_prefix("seal_"))) \
						if not r.get("seals_left", []).is_empty() else "inga"
				var c: Array = boss_left.get(left_key, [0, 0])
				boss_left[left_key] = [int(c[0]) + 1, int(c[1]) + (1 if r.cleared else 0)]
		if OS.get_environment("GROTTA_TURER") == "1" and line.contains("%"):
			line += "\n  %-8s %-34s" % ["", ""]
		line += "  %s%s %3d %% (strider %.1f, klarade %.1f, steg %d, erf %d)" % [_skill_name(skill),
				{"careful": "-försiktig", "direct": "-direkt"}.get(policy, ""), roundi(100.0 * cleared / RUNS),
				float(fights) / RUNS, float(fights_cleared) / maxi(cleared, 1), roundi(float(steps) / RUNS), xp / RUNS]
		# GROTTA_TYPER=1 (prototyp sallskap-fem): vinst per sorts strid i körningarna (vunna/utkämpade).
		if OS.get_environment("GROTTA_TYPER") == "1":
			var bits := []
			for k in ["vanlig", "elit", "väktare", "boss"]:
				if kinds.has(k):
					bits.append("%s %d/%d" % [k, int(kinds[k][1]), int(kinds[k][0])])
			line += " [" + ", ".join(bits) + "]"
		if OS.get_environment("GROTTA_QUEST") == "1":
			var keys := by_quest.keys()
			keys.sort()
			line += "\n      våningar: " + ", ".join(keys.map(func(k: String) -> String:
				return "%s %d/%d (%d %%)" % [k, by_quest[k][1], by_quest[k][0], roundi(100.0 * by_quest[k][1] / maxi(by_quest[k][0], 1))]))
			line += "\n      körningar med sigill %d/%d (%d %%), utan %d/%d (%d %%)" % [seal_runs[1], seal_runs[0],
					roundi(100.0 * seal_runs[1] / maxi(seal_runs[0], 1)), seal_runs[3], seal_runs[2], roundi(100.0 * seal_runs[3] / maxi(seal_runs[2], 1))]
			var bk := boss_left.keys()
			bk.sort()
			line += "\n      bossen (vunna/nådda) efter kvarlämnade sigill: " + ", ".join(bk.map(func(k: String) -> String:
				return "%s %d/%d" % [k, boss_left[k][1], boss_left[k][0]]))
		if OS.get_environment("GROTTA_TURER") == "1":
			line += "\n      turer (median / 90:e percentilen / max, antal): " + _turn_stats(turns, ["vanlig", "elit", "väktare", "boss"])
			var named := turns.keys().filter(func(k: String) -> bool: return k.contains(": "))
			named.sort()
			for k in named:
				line += "\n        %s" % _turn_stats(turns, [k])
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


## Den levande kartan (BALANS=levande, docs/plan/levande-karta.md): hela grottkörningar per steg av fördärvet (0–4) i varje
## Realm, fyra hjältar med startmakron på väntad nivå på djup 1 och 2 (MACRO och TUNED). Steg 4 i kryptan är den
## förvridna bossen. Sist bara bossmötet: Benfursten mot den svärtade Benfursten.
func _living(data: Dictionary) -> void:
	var party := ["paladin", "brokk", "alva", "eira"]
	if OS.get_environment("LEVANDE_STAT") != "":
		LivingMap.stat_per_step = float(OS.get_environment("LEVANDE_STAT"))
	var depths := [1, 2] if OS.get_environment("LEVANDE_DJUP") == "" else [int(OS.get_environment("LEVANDE_DJUP"))]
	print("Stats per steg: +%.1f %%" % (LivingMap.stat_per_step * 100.0))
	print("=== Den levande kartan, %d körningar per ruta: vinst per steg (MACRO / TUNED) ===" % RUNS)
	for depth in depths:
		var lv := HeroStats.expected_level(depth)
		for realm_id in data.realms:
			if OS.get_environment("LEVANDE_REALM") not in ["", realm_id]:
				continue
			var line := "  djup %d %-8s nivå %d" % [depth, data.realms[realm_id].short, lv]
			for g in range(1, LivingMap.GROWTH_MAX + 1):
				var won := [0, 0]
				for k in 2:
					var skill: Bot.Skill = [Bot.Skill.MACRO, Bot.Skill.TUNED][k]
					for seed_value in range(1, RUNS + 1):
						var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party, "growth": g}
						var r := Bot.run_expedition(data, seed_value, skill, {}, {}, depth, realm_id, opts, "simple")
						won[k] += 1 if r.cleared else 0
				line += "  steg %d %3d/%3d %%" % [g, roundi(100.0 * won[0] / RUNS), roundi(100.0 * won[1] / RUNS)]
			print(line)
	var boss_lv := HeroStats.expected_level(1) + 2  # sällskapet har vuxit under körningen när det når bossen
	print("  Bossmötet ensamt (nivå %d, fulla Charges, MACRO):" % boss_lv)
	for enc in ["crypt_3", "crypt_twisted"]:
		for g in [1, 4]:
			var won := 0
			for seed_value in range(1, RUNS + 1):
				var r := Bot.run_fight(data, seed_value, Bot.Skill.MACRO, enc, party, {}, {}, {}, 1,
						{"levels": Bot.party_levels(data, boss_lv, party), "floor": 2,
						"stat_bonus": LivingMap.stat_mult(g), "counter": true})
				won += 1 if r.outcome == "victory" else 0
			print("    %-14s steg %d: %3d %%" % [enc, g, roundi(100.0 * won / RUNS)])
