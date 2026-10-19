extends SceneTree
## Balansrapport (0.17) på djup 1 och 3 (Realm Depth).
## Per våning: vinstandel, turer och överlevande för BASIC (bara Anfall), MACRO (startmakrona) och
## TUNED (de förbättrade makrona i combat_bot.gd, som svarar på fiendernas egenskaper).
## Hela kryptan: alla tre våningarna i följd med Charges som räcker hela vägen, med TUNED plus en
## artefakt, och för varje Ed de bästa perkarna inom perk-poängen (sökta bland alla kombinationer som
## får plats): bara nivå 1, med perk-nivåer, och med nivåer och en lånad perk (anointment). Sist allt
## (fyra artefakter och det bästa perk-bygget) och varje Eds kärna med startmakrona. På djup 3 prövas
## perkarna tillsammans med en artefakt, eftersom inget bygge utan artefakt vinner där. Sist samma
## byggen i Det fördärvade kapellet (0.16), som ska vara ungefär lika svårt som kryptan. Därefter
## elitfiender och instabilitet 0 och 2 (0.17) och varje våningsregel för sig. Alla rader utom "utan
## elitfiender" har elitvarianter som i spelet.
##   godot --headless --path . --script res://tests/balance_report.gd
## Mål på djup 1: BASIC förlorar, MACRO ~40 %, TUNED ~65 %, ingenting 100 % utom kanske allt.
## Kärnorna inom ±10 procentenheter. Djup 3: ett bra bygge (artefakt + bästa perks) 30–60 %.

const Bot := preload("res://tests/combat_bot.gd")
const RUNS := 100
## Körningar per kombination när de bästa perkarna söks.
const SEARCH_RUNS := 20

## Sökresultat per djup och kombination (str(lista) -> vinster).
var _search_cache := {}
## Det bästa perk-bygget i kryptan per djup (prövas också i kapellet).
var _best_by_depth := {}
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
		print("--- Kryptan ---")
		_floor_table(data, RunState.FLOORS, depth)
		# Perk-poängen för den som spelar på djupet: djupet innan är klarat.
		var profile := Profile.new()
		profile.best_depth = depth - 1
		var points := profile.perk_points()
		_search_cache.clear()
		print("Hela kryptan (Charges räcker alla tre våningarna, %d perk-poäng)" % points)
		_line(data, "MACRO", Bot.Skill.MACRO, {}, {}, depth)
		_line(data, "TUNED", Bot.Skill.TUNED, {}, {}, depth)
		_line(data, "TUNED + en artefakt", Bot.Skill.TUNED, {}, ONE_ARTIFACT, depth)
		# På djup 1 prövas perkarna för sig; på djupare med en artefakt (utan den vinner inget bygge).
		var base_art: Dictionary = {} if depth == 1 else ONE_ARTIFACT
		var prefix := "TUNED + " if depth == 1 else "TUNED + en artefakt + "
		var best_rate := -1
		var best_traits := []
		for oath_id in data.oaths:
			for mode in ["flat", "ranks", "anoint"]:
				var list := _best_perks(data, oath_id, points, depth, mode, base_art)
				var tag: String = {"flat": "", "ranks": " [nivåer]", "anoint": " [nivåer + lån]"}[mode]
				var rate := _line(data, "%s%s%s" % [prefix, _names(data, list), tag], Bot.Skill.TUNED,
						{"paladin": list}, base_art, depth)
				if rate > best_rate:
					best_rate = rate
					best_traits = list
		if depth == 1:
			_line(data, "TUNED + en artefakt + " + _names(data, best_traits), Bot.Skill.TUNED,
					{"paladin": best_traits}, ONE_ARTIFACT, depth)
		_line(data, "TUNED + fyra artefakter + " + _names(data, best_traits), Bot.Skill.TUNED,
				{"paladin": best_traits}, ARTIFACTS, depth)
		_best_by_depth[depth] = best_traits
	# Det fördärvade kapellet: samma byggen (de bästa perkarna från kryptan) i den andra Realmen.
	var chapel: Array = data.realms.chapel.floors
	for depth in DEPTHS:
		print("=== Det fördärvade kapellet, djup %d ===" % depth)
		_floor_table(data, chapel, depth)
		var best: Array = _best_by_depth[depth]
		print("Hela kapellet")
		_line(data, "MACRO", Bot.Skill.MACRO, {}, {}, depth, chapel)
		_line(data, "TUNED", Bot.Skill.TUNED, {}, {}, depth, chapel)
		_line(data, "TUNED + en artefakt", Bot.Skill.TUNED, {}, ONE_ARTIFACT, depth, chapel)
		_line(data, "TUNED + en artefakt + " + _names(data, best), Bot.Skill.TUNED, {"paladin": best},
				ONE_ARTIFACT, depth, chapel)
		_line(data, "TUNED + fyra artefakter + " + _names(data, best), Bot.Skill.TUNED, {"paladin": best},
				ARTIFACTS, depth, chapel)
	# Instabilitet (0.17): våningsregler och elitfiender, djup 1, båda Realms.
	var best1: Array = _best_by_depth[1]
	for realm_id in data.realms:
		var floors: Array = data.realms[realm_id].floors
		print("=== %s, djup 1: elitfiender och instabilitet ===" % data.realms[realm_id].name)
		for level in [-2, 0, 2]:
			var tag: String = {-2: "utan elitfiender", 0: "instabilitet 0", 2: "instabilitet 2"}[level]
			_line(data, "%s: MACRO" % tag, Bot.Skill.MACRO, {}, {}, 1, floors, level)
			_line(data, "%s: TUNED" % tag, Bot.Skill.TUNED, {}, {}, 1, floors, level)
			if level >= 0:
				_line(data, "%s: TUNED + en artefakt + %s" % [tag, _names(data, best1)], Bot.Skill.TUNED,
						{"paladin": best1}, ONE_ARTIFACT, 1, floors, level)
	print("Varje våningsregel för sig (kryptan, djup 1, TUNED, utan elitfiender)")
	for rule_id in data.floor_rules:
		var cleared := 0
		for seed_value in range(1, RUNS + 1):
			if Bot.run_crypt(data, seed_value, Bot.Skill.TUNED, {}, {}, 1, RunState.FLOORS,
					{"rules": [rule_id], "elite_chance": 0.0}):
				cleared += 1
		print("  %-20s %3d/%d  (silver +%d %%)" % [data.floor_rules[rule_id].name, cleared, RUNS,
				roundi(float(data.floor_rules[rule_id].silver) * 100.0)])
	print("Edernas kärnor på djup 1 (MACRO, hela kryptan, utan artefakter och perks)")
	for oath_id in data.oaths:
		print("  %-18s %3d/%d" % [data.traits[oath_id].name, _rate(data, Bot.Skill.MACRO, {"paladin": [oath_id]}, {}, 1, RUNS), RUNS])
	quit()


## Edens bästa perks inom poängen för TUNED (alla kombinationer som får plats, SEARCH_RUNS var).
## mode: "flat" bara nivå 1, "ranks" med perk-nivåer, "anoint" med nivåer och en lånad perk från en
## annan Ed (kostar poäng ur samma pott).
func _best_perks(data: Dictionary, oath_id: String, points: int, depth: int, mode: String,
		artifacts: Dictionary) -> Array:
	var combos := _combos(data.oaths[oath_id].perks, 0, points, mode != "flat")
	if mode == "anoint":
		# Lånet är frivilligt: de egna kombinationerna är också med.
		var borrowed := combos.duplicate()
		for other in data.oaths:
			if other == oath_id:
				continue
			for p in data.oaths[other].perks:
				for c in _combos(data.oaths[oath_id].perks, 0, points - int(p.cost), true):
					borrowed.append(c + [p.id])
		combos = borrowed
	var best := [oath_id]
	var best_rate := -1
	for combo in combos:
		var list: Array = [oath_id] + combo
		var rate: int = _search_cache.get(str(list), -1)
		if rate < 0:
			rate = _rate(data, Bot.Skill.TUNED, {"paladin": list}, artifacts, depth, SEARCH_RUNS)
			_search_cache[str(list)] = rate
		if rate > best_rate:
			best_rate = rate
			best = list
	return best


## Alla kombinationer av perkarna från index i som kostar högst points (en post per nivå).
func _combos(perks: Array, i: int, points: int, ranks: bool) -> Array:
	if i >= perks.size() or points <= 0:
		return [[]] if points >= 0 else []
	var out := []
	var cost := int(perks[i].cost)
	var max_rank := int(perks[i].get("ranks", 1)) if ranks else 1
	for n in range(0, max_rank + 1):
		if n * cost > points:
			break
		var head := []
		for k in n:
			head.append(perks[i].id)
		for rest in _combos(perks, i + 1, points - n * cost, ranks):
			out.append(head + rest)
	return out


## Per våning: vinstandel, turer och överlevande för BASIC, MACRO och TUNED (fulla Charges).
func _floor_table(data: Dictionary, floors: Array, depth: int) -> void:
	for floor in floors:
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


func _names(data: Dictionary, list: Array) -> String:
	return ", ".join(list.map(func(id: String) -> String: return data.traits[id].name))


func _line(data: Dictionary, label: String, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int,
		floors: Array = RunState.FLOORS, level := -1) -> int:
	var rate := _rate(data, skill, traits, artifacts, depth, RUNS, floors, level)
	print("  %-72s %3d/%d" % [label, rate, RUNS])
	return rate


## Seeds efter de som söker perks, så att sökningen inte väljer på samma slump som den mäts med.
## level: −1 = som spelet i dag utan instabilitet, −2 = utan elitfiender, annars instabiliteten
## (reglerna slumpas per frö).
func _rate(data: Dictionary, skill: int, traits: Dictionary, artifacts: Dictionary, depth: int, runs: int,
		floors: Array = RunState.FLOORS, level := -1) -> int:
	var cleared := 0
	var first := 1 if runs == RUNS else 1000
	for seed_value in range(first, first + runs):
		var opts := {}
		if level == -2:
			opts = {"elite_chance": 0.0}
		elif level >= 0:
			opts = Bot.instability_opts(data, seed_value, level)
		if Bot.run_crypt(data, seed_value, skill, traits, artifacts, depth, floors, opts):
			cleared += 1
	return cleared
