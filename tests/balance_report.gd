extends SceneTree
## Balansrapport (0.14) på djup 1 och 3 (Realm Depth).
## Per våning: vinstandel, turer och överlevande för BASIC (bara Anfall), MACRO (startmakrona) och
## TUNED (de förbättrade makrona i combat_bot.gd, som svarar på fiendernas egenskaper).
## Hela kryptan: alla tre våningarna i följd med Charges som räcker hela vägen, med TUNED plus en
## artefakt, en Eds bästa perks, och allt (fyra artefakter och alla perks). Sist varje Ed med bara
## kärnan och med alla perks (MACRO).
##   godot --headless --path . --script res://tests/balance_report.gd
## Mål på djup 1: BASIC förlorar varje strid, MACRO ~40 %, TUNED ~60 %, TUNED med en artefakt eller
## en Eds bästa perks 75–85 %, ingenting 100 %. Djup 3 märkbart svårare.

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
## De två perks per Ed som hjälper mest (280–360 silver).
const BEST_PERKS := {
	"oath_vengeance": ["vengeance_hand_of_light", "vengeance_reckoning"],
	"oath_dawn": ["dawn_greater_healing", "dawn_guiding_light"],
	"oath_ward": ["ward_in_formation", "ward_war_machine"],
}


func _init() -> void:
	var data := GameData.load_all()
	for depth in DEPTHS:
		print("=== Djup %d (fiender ×%.2f) ===" % [depth, CombatSim.depth_mult(depth)])
		for floor in RunState.FLOORS:
			var enc: Dictionary = data.encounters[floor]
			print("%s (våning ×%.2f)" % [enc.name, float(enc.get("stat_mult", 1.0))])
			for skill in [Bot.Skill.BASIC, Bot.Skill.MACRO, Bot.Skill.TUNED]:
				var wins := 0
				var turns := 0
				var alive := 0
				for seed_value in range(1, RUNS + 1):
					var r := Bot.run_fight(data, seed_value, skill, floor, [], {}, {}, {}, depth)
					turns += r.turns
					if r.outcome == "victory":
						wins += 1
						alive += r.alive
				print("  %-6s vinster %3d/%d  snitt %4.1f turer  överlevande vid seger %.1f" % [
					Bot.Skill.keys()[skill], wins, RUNS, float(turns) / RUNS, float(alive) / maxf(wins, 1)])
		print("Hela kryptan (Charges räcker alla tre våningarna)")
		_line(data, "MACRO", Bot.Skill.MACRO, {}, {}, depth)
		_line(data, "TUNED", Bot.Skill.TUNED, {}, {}, depth)
		_line(data, "TUNED + en artefakt", Bot.Skill.TUNED, {}, ONE_ARTIFACT, depth)
		for oath_id in BEST_PERKS:
			_line(data, "TUNED + %s, bästa perks" % data.traits[oath_id].name, Bot.Skill.TUNED,
					{"paladin": [oath_id] + BEST_PERKS[oath_id]}, {}, depth)
		var all_perks: Array = ["oath_dawn"] + data.oaths.oath_dawn.perks.map(func(p: Dictionary) -> String: return p.id)
		_line(data, "TUNED + fyra artefakter + Gryningens alla perks", Bot.Skill.TUNED,
				{"paladin": all_perks}, ARTIFACTS, depth)
	print("Ederna på djup 1 (MACRO, hela kryptan, utan artefakter)")
	for oath_id in data.oaths:
		var perks: Array = data.oaths[oath_id].perks.map(func(p: Dictionary) -> String: return p.id)
		var core := _rate(data, Bot.Skill.MACRO, {"paladin": [oath_id]}, {}, 1)
		var full := _rate(data, Bot.Skill.MACRO, {"paladin": [oath_id] + perks}, {}, 1)
		print("  %-18s bara kärnan %3d/%d  alla perks %3d/%d" % [data.traits[oath_id].name, core, RUNS, full, RUNS])
	quit()


func _line(data: Dictionary, label: String, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int) -> void:
	print("  %-48s klarade kryptan %3d/%d" % [label, _rate(data, skill, traits, artifacts, depth), RUNS])


func _rate(data: Dictionary, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int) -> int:
	var cleared := 0
	for seed_value in range(1, RUNS + 1):
		if Bot.run_crypt(data, seed_value, skill, traits, artifacts, depth):
			cleared += 1
	return cleared
