extends SceneTree
## Balansrapport (0.14.1) på djup 1 och 3 (Realm Depth).
## Per våning: vinstandel, turer och överlevande för BASIC (bara Anfall), MACRO (startmakrona) och
## TUNED (de förbättrade makrona i combat_bot.gd, som svarar på fiendernas egenskaper).
## Hela kryptan: alla tre våningarna i följd med Charges som räcker hela vägen, med TUNED plus en
## artefakt, varje Eds bästa perks inom perk-poängen (sökta bland alla kombinationer som får plats),
## och allt (fyra artefakter och de bästa perkarna). Sist varje Eds kärna med startmakrona.
##   godot --headless --path . --script res://tests/balance_report.gd
## Mål på djup 1: BASIC förlorar, MACRO ~40 %, TUNED ~65 %, ingenting 100 % utom kanske allt.
## Kärnorna inom ±10 procentenheter. Djup 3: ett bra bygge (artefakt + bästa perks) 30–60 %.

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 100
## Körningar per kombination när de bästa perkarna söks.
const SEARCH_RUNS := 30
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
		# Perk-poängen för den som spelar på djupet: djupet innan är klarat.
		var profile := Profile.new()
		profile.best_depth = depth - 1
		var points := profile.perk_points()
		print("Hela kryptan (Charges räcker alla tre våningarna, %d perk-poäng)" % points)
		_line(data, "MACRO", Bot.Skill.MACRO, {}, {}, depth)
		_line(data, "TUNED", Bot.Skill.TUNED, {}, {}, depth)
		_line(data, "TUNED + en artefakt", Bot.Skill.TUNED, {}, ONE_ARTIFACT, depth)
		var best_rate := -1
		var best_traits := []
		for oath_id in data.oaths:
			var list := _best_perks(data, oath_id, points, depth)
			var rate := _line(data, "TUNED + " + _names(data, list), Bot.Skill.TUNED, {"paladin": list}, {}, depth)
			if rate > best_rate:
				best_rate = rate
				best_traits = list
		_line(data, "TUNED + en artefakt + " + _names(data, best_traits), Bot.Skill.TUNED,
				{"paladin": best_traits}, ONE_ARTIFACT, depth)
		_line(data, "TUNED + fyra artefakter + " + _names(data, best_traits), Bot.Skill.TUNED,
				{"paladin": best_traits}, ARTIFACTS, depth)
	print("Edernas kärnor på djup 1 (MACRO, hela kryptan, utan artefakter och perks)")
	for oath_id in data.oaths:
		print("  %-18s %3d/%d" % [data.traits[oath_id].name, _rate(data, Bot.Skill.MACRO, {"paladin": [oath_id]}, {}, 1, RUNS), RUNS])
	quit()


## Edens bästa perks inom poängen för TUNED (alla kombinationer som får plats, SEARCH_RUNS var).
func _best_perks(data: Dictionary, oath_id: String, points: int, depth: int) -> Array:
	var perks: Array = data.oaths[oath_id].perks
	var best := [oath_id]
	var best_rate := -1
	for mask in range(1, 1 << perks.size()):
		var list := [oath_id]
		var cost := 0
		for i in perks.size():
			if mask & (1 << i):
				list.append(perks[i].id)
				cost += int(perks[i].cost)
		if cost > points:
			continue
		var rate := _rate(data, Bot.Skill.TUNED, {"paladin": list}, {}, depth, SEARCH_RUNS)
		if rate > best_rate:
			best_rate = rate
			best = list
	return best


func _names(data: Dictionary, list: Array) -> String:
	return ", ".join(list.map(func(id: String) -> String: return data.traits[id].name))


func _line(data: Dictionary, label: String, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int) -> int:
	var rate := _rate(data, skill, traits, artifacts, depth, RUNS)
	print("  %-72s %3d/%d" % [label, rate, RUNS])
	return rate


## Seeds efter de som söker perks, så att sökningen inte väljer på samma slump som den mäts med.
func _rate(data: Dictionary, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int, runs: int) -> int:
	var cleared := 0
	var first := 1 if runs == RUNS else 1000
	for seed_value in range(first, first + runs):
		if Bot.run_crypt(data, seed_value, skill, traits, artifacts, depth):
			cleared += 1
	return cleared
