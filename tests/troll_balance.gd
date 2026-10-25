extends SceneTree
## 0.30.23: Trollfolkets möten mot kapellets, en strid i taget med fulla Charges (fyra hjältar, startmakron och TUNED,
## nivå efter mötets tier som i grottan). TROLL_RUNS=n ändrar antalet.

const Bot := preload("res://tests/combat_bot.gd")


func _init() -> void:
	var data := GameData.load_all()
	if OS.get_environment("TROLL_MODE") == "djup":
		_depth_report(data)
		quit()
		return
	var runs := int(OS.get_environment("TROLL_RUNS")) if OS.get_environment("TROLL_RUNS") != "" else 100
	var party := ["paladin", "brokk", "alva", "eira"]
	var rows := [["troll_1a", 0], ["troll_1b", 0], ["troll_1c", 0], ["chapel_1a", 0], ["troll_2a", 1], ["troll_2b", 1],
			["chapel_2a", 1], ["troll_e1", 1], ["troll_e2", 1], ["chapel_e4", 1], ["troll_3", 2], ["chapel_3", 2]]
	print("=== Trollen mot kapellet, djup 1, %d strider per rad: vinst (turer, stående) ===" % runs)
	for row in rows:
		var enc: String = row[0]
		var tier: int = row[1]
		var line := "  %-10s %-26s" % [enc, data.encounters[enc].name]
		for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
			var won := 0
			var turns := 0
			var alive := 0
			for s in range(1, runs + 1):
				var lv := HeroStats.enemy_level(1, tier)
				var opts := {"levels": Bot.party_levels(data, roundi(lv), party), "floor": tier, "elite_chance": 0.0}
				if data.encounters[enc].get("elite_group", false):
					opts.force_elites = 1
				var r := Bot.run_fight(data, s, skill, enc, party, {}, {}, {}, 1, opts)
				won += 1 if r.outcome == "victory" else 0
				turns += int(r.turns)
				alive += int(r.alive)
			line += "  %s %3d %% (%d, %.1f)" % ["MACRO" if skill == Bot.Skill.MACRO else "TUNED", roundi(100.0 * won / runs),
					turns / runs, float(alive) / runs]
		print(line)
	quit()


## 0.30.25 (VD): Trollbergets djup 1 räknas som djup 1 + "depth_offset" för fienderna. TROLL_MODE=djup kör hela djup 1 i
## grottan (Charges för hela körningen) med sällskapet ett lag har när berget öppnas efter kapellet 1 (nivå 6–7: Paladinen,
## Imma, Alva 7, Lirien 6; den femte Brokk 6), fyra och fem i sällskapet. TROLL_OFFSET=a,b,… prövar andra förskjutningar,
## TROLL_RUNS körningar per rad (standard 60), TROLL_SKILL=tuned med botarnas bättre makron. Visar vinst per körning och segrar per sort (vanlig, elit, boss).
static func _depth_report(data: Dictionary) -> void:
	var runs := int(OS.get_environment("TROLL_RUNS")) if OS.get_environment("TROLL_RUNS") != "" else 60
	var offsets: Array = [int(data.realms.mountain.get("depth_offset", 0))]
	if OS.get_environment("TROLL_OFFSET") != "":
		offsets = Array(OS.get_environment("TROLL_OFFSET").split(",")).map(func(x: String) -> int: return int(x))
	var four := ["paladin", "imma", "alva", "lirien"]
	var five := four + ["brokk"]
	var lv := {"paladin": 7, "imma": 7, "alva": 7, "lirien": 6, "brokk": 6}
	# TROLL_MULT=x: alla Trollbergets möten (troll_*) med stat_mult × x, för att pröva en mildare Realm.
	if OS.get_environment("TROLL_MULT") != "":
		for enc_id in data.encounters:
			if String(enc_id).begins_with("troll"):
				data.encounters[enc_id].stat_mult = float(data.encounters[enc_id].get("stat_mult", 1.0)) * float(OS.get_environment("TROLL_MULT"))
	var skill := Bot.Skill.TUNED if OS.get_environment("TROLL_SKILL") == "tuned" else Bot.Skill.MACRO
	for off in offsets:
		data.realms.mountain.depth_offset = off
		print("=== Trollberget djup 1 som djup %d (fiendernivå %.1f–%.1f), %d körningar ===" % [1 + off,
				HeroStats.enemy_level(1 + off, 0), HeroStats.enemy_level(1 + off, 2), runs])
		for party in [four, five]:
			var levels := {}
			for id in party:
				levels[id] = {"level": lv[id], "xp": 0, "personality": data.heroes[id].get("personality", "")}
			var cleared := 0
			var kinds := {}
			for s in range(1, runs + 1):
				var r := Bot.run_expedition(data, s, skill, {}, {}, 1, "mountain",
						{"party": party, "levels": levels, "owned": 5, "slots": 5}, "simple")
				cleared += 1 if r.cleared else 0
				for k in r.by_kind:
					var a: Array = kinds.get(k, [0, 0])
					kinds[k] = [int(a[0]) + int(r.by_kind[k][0]), int(a[1]) + int(r.by_kind[k][1])]
			var line := "  %d hjältar: klarat %3d %%" % [party.size(), roundi(100.0 * cleared / runs)]
			for k in ["vanlig", "elit", "väktare", "boss"]:
				if kinds.has(k):
					line += "  %s %d/%d (%d %%)" % [k, kinds[k][1], kinds[k][0], roundi(100.0 * kinds[k][1] / maxi(kinds[k][0], 1))]
			print(line)
