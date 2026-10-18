extends SceneTree
## Skriver ut en balansrapport: vinstandel, stridstid och överlevande per spelarnivå.
##   godot --headless --path . --script res://tests/balance_report.gd

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 40


func _init() -> void:
	var data := GameData.load_all()
	for skill in [Bot.Skill.NONE, Bot.Skill.SLOPPY, Bot.Skill.GOOD]:
		var wins := 0
		var win_time := 0.0
		var alive := 0
		var boss_left := 0.0
		for seed_value in range(1, RUNS + 1):
			var r := Bot.run_fight(data, seed_value, skill)
			if r.outcome == "victory":
				wins += 1
				win_time += r.time
				alive += r.alive
			else:
				boss_left += r.boss_hp
		var losses := RUNS - wins
		print("%-7s vinster %2d/%d  snittid %5.1fs  överlevande %.1f  boss kvar vid förlust %3.0f%%" % [
			Bot.Skill.keys()[skill], wins, RUNS,
			win_time / maxf(wins, 1), float(alive) / maxf(wins, 1),
			100.0 * boss_left / maxf(losses, 1)])
	quit()
