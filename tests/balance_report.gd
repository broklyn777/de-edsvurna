extends SceneTree
## Balansrapport per våning: vinstandel, turer och överlevande för varje spelarnivå.
## BASIC anfaller bara, MACRO kör startmakrona, TUNED de förbättrade makrona i combat_bot.gd.
## "Hela körningen" spelar alla tre våningarna i följd, med Charges som räcker hela vägen.
##   godot --headless --path . --script res://tests/balance_report.gd

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 100


func _init() -> void:
	var data := GameData.load_all()
	for floor in RunState.FLOORS:
		print(data.encounters[floor].name)
		for skill in [Bot.Skill.BASIC, Bot.Skill.MACRO, Bot.Skill.TUNED]:
			var wins := 0
			var turns := 0
			var alive := 0
			var no_match := 0
			for seed_value in range(1, RUNS + 1):
				var r := Bot.run_fight(data, seed_value, skill, floor)
				turns += r.turns
				no_match += r.no_match
				if r.outcome == "victory":
					wins += 1
					alive += r.alive
			print("  %-6s vinster %3d/%d  snitt %4.1f turer  överlevande vid seger %.1f  inget passade %d" % [
				Bot.Skill.keys()[skill], wins, RUNS, float(turns) / RUNS, float(alive) / maxf(wins, 1), no_match])
	print("Hela körningen (Charges räcker alla tre våningarna)")
	for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
		var cleared := 0
		for seed_value in range(1, RUNS + 1):
			var state := RunState.new()
			state.fill_charges(data)
			var ok := true
			for floor in RunState.FLOORS:
				var r := Bot.run_fight(data, seed_value, skill, floor, state.party, {}, state.charges)
				if r.outcome != "victory":
					ok = false
					break
				state.store_charges(r.sim)
			if ok:
				cleared += 1
		print("  %-6s klarade kryptan %3d/%d" % [Bot.Skill.keys()[skill], cleared, RUNS])
	quit()
