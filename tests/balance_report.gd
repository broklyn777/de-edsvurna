extends SceneTree
## Balansrapport per våning: vinstandel, rundor och överlevande för varje spelarnivå.
##   godot --headless --path . --script res://tests/balance_report.gd

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 100


func _init() -> void:
	var data := GameData.load_all()
	for floor in RunState.FLOORS:
		print(data.encounters[floor].name)
		for skill in [Bot.Skill.BASIC, Bot.Skill.AUTO, Bot.Skill.GOOD]:
			var wins := 0
			var rounds := 0
			var alive := 0
			for seed_value in range(1, RUNS + 1):
				var r := Bot.run_fight(data, seed_value, skill, floor)
				rounds += r.rounds
				if r.outcome == "victory":
					wins += 1
					alive += r.alive
			print("  %-6s vinster %3d/%d  snitt %4.1f rundor  överlevande vid seger %.1f" % [
				Bot.Skill.keys()[skill], wins, RUNS, float(rounds) / RUNS, float(alive) / maxf(wins, 1)])
	quit()
