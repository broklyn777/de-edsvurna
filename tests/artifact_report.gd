extends SceneTree
## Provar varje artefakt på varje hjälte (förvalda klassegenskaper) och visar vinstandel för
## en SLOPPY-spelare och snittid för en GOOD-spelare, jämfört med utan artefakt.
##   godot --headless --path . --script res://tests/artifact_report.gd

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 12


func _init() -> void:
	var data := GameData.load_all()
	var party: Array = data.encounters.bone_lich.party
	var base := _measure(data, {})
	print("Utan artefakt:  SLOPPY %3.0f%%  GOOD %5.1fs\n" % [base.rate * 100.0, base.time])
	print("%-14s" % "" + "".join(party.map(func(h: String) -> String: return "%-18s" % h)))
	for trait_id in data.traits:
		if not data.traits[trait_id].get("artifact", false):
			continue
		var line := "%-14s" % data.traits[trait_id].name
		for hero_id in party:
			var m := _measure(data, {hero_id: trait_id})
			line += "%3.0f%%  %5.1fs      " % [m.rate * 100.0, m.time]
		print(line)
	quit()


func _measure(data: Dictionary, artifacts: Dictionary) -> Dictionary:
	var wins := 0
	var good_time := 0.0
	for seed_value in range(1, RUNS + 1):
		if Bot.run_fight(data, seed_value, Bot.Skill.SLOPPY, 400.0, {}, artifacts).outcome == "victory":
			wins += 1
		good_time += Bot.run_fight(data, seed_value, Bot.Skill.GOOD, 400.0, {}, artifacts).time
	return {"rate": float(wins) / RUNS, "time": good_time / RUNS}
