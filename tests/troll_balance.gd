extends SceneTree
## 0.30.23: Trollfolkets möten mot kapellets, en strid i taget med fulla Charges (fyra hjältar, startmakron och TUNED,
## nivå efter mötets tier som i grottan). TROLL_RUNS=n ändrar antalet.

const Bot := preload("res://tests/combat_bot.gd")


func _init() -> void:
	var data := GameData.load_all()
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
