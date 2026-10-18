extends SceneTree
## Varje perk för sig: hur ofta startmakrona klarar hela kryptan med kärnan + perken (utan artefakter).
##   godot --headless --path . --script res://tests/perk_report.gd

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 100


func _init() -> void:
	var data := GameData.load_all()
	for oath_id in data.oaths:
		print("%s: bara kärnan %d/%d" % [data.traits[oath_id].name, _rate(data, [oath_id]), RUNS])
		for p in data.oaths[oath_id].perks:
			print("  + %-18s %3d/%d  (%d silver)" % [data.traits[p.id].name, _rate(data, [oath_id, p.id]), RUNS, p.cost])
	quit()


func _rate(data: Dictionary, traits: Array) -> int:
	var cleared := 0
	for seed_value in range(1, RUNS + 1):
		var state := RunState.new()
		state.fill_charges(data)
		var ok := true
		for floor in RunState.FLOORS:
			var r := Bot.run_fight(data, seed_value, Bot.Skill.MACRO, floor, state.party, {"paladin": traits}, state.charges)
			if r.outcome != "victory":
				ok = false
				break
			state.store_charges(r.sim)
		if ok:
			cleared += 1
	return cleared
