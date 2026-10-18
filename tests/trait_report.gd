extends SceneTree
## Kör alla kombinationer av hjältarnas egenskapsval och visar vilka som är starkast och svagast.
##   godot --headless --path . --script res://tests/trait_report.gd

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 12


func _init() -> void:
	var data := GameData.load_all()
	var party: Array = data.encounters.bone_lich.party
	var combos: Array[Dictionary] = [{}]
	for hero_id in party:
		var next: Array[Dictionary] = []
		for combo in combos:
			for trait_id in data.heroes[hero_id].trait_options:
				var c := combo.duplicate()
				c[hero_id] = trait_id
				next.append(c)
		combos = next

	var rows: Array[Dictionary] = []
	var per_trait := {}
	for combo in combos:
		var wins := 0
		var win_time := 0.0
		for seed_value in range(1, RUNS + 1):
			var r := Bot.run_fight(data, seed_value, Bot.Skill.SLOPPY, 400.0, combo)
			if r.outcome == "victory":
				wins += 1
				win_time += r.time
		var rate := float(wins) / RUNS
		rows.append({"combo": combo, "rate": rate, "time": win_time / maxf(wins, 1)})
		for trait_id in combo.values():
			per_trait[trait_id] = per_trait.get(trait_id, []) + [rate]

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.rate > b.rate or (a.rate == b.rate and a.time < b.time))
	print("SLOPPY-spelare, %d strider per kombination, %d kombinationer\n" % [RUNS, rows.size()])
	print("Starkast:")
	for row in rows.slice(0, 6):
		print("  %3.0f%%  %5.1fs  %s" % [row.rate * 100.0, row.time, _names(data, row.combo)])
	print("Svagast:")
	for row in rows.slice(rows.size() - 6):
		print("  %3.0f%%  %5.1fs  %s" % [row.rate * 100.0, row.time, _names(data, row.combo)])
	print("\nPer egenskap (snitt av alla kombinationer den ingår i):")
	for hero_id in party:
		for trait_id in data.heroes[hero_id].trait_options:
			var rates: Array = per_trait[trait_id]
			var avg: float = rates.reduce(func(acc: float, x: float) -> float: return acc + x, 0.0) / rates.size()
			print("  %-8s %-14s %3.0f%%" % [hero_id, data.traits[trait_id].name, avg * 100.0])
	quit()


func _names(data: Dictionary, combo: Dictionary) -> String:
	return ", ".join(combo.values().map(func(t: String) -> String: return data.traits[t].name))
