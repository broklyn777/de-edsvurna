extends RefCounted
## Simulerade spelare för balanstester i turordningsstriden.
##   BASIC – anfaller alltid det förvalda målet
##   MACRO – hjältarna kör startmakrona i data/macros.json (det Auto gör från början)
##   TUNED – startmakrona med små förbättringar (TUNED_MACROS nedan): visar att makrobygget spelar roll

enum Skill { BASIC, MACRO, TUNED }

## Startmakrona förbättrade för att svara på fiendernas egenskaper (0.14): döda Gravprästen först
## (Gravpakt), besvärjelser mot Benrustning, Pilregn mot många, Krigsrop i första turen, och Brokk
## provocerar bara med mycket liv. I kapellet (0.16): Kultisterna först (biskopen är immun så länge de
## lever), Ljusets dom mot Gasten som undviker attacker. Med rumskartan (0.18) och Siralims Charges
## helar Alva snålare (Helande ljus under 35 %, Förnyelse under 60 %) så att Charges räcker hela körningen. Försök som sparade Charges förlorade oftare – att spendera är oftast rätt.
const TUNED_MACROS := {
	"paladin": {"name": "Paladinen+", "lines": [
		{"subject": "any_ally", "cond": "hp_below", "value": 35, "action": "ability", "ability": "holy_shield", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "cultist_ward", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "ability", "ability": "holy_smite", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"brokk": {"name": "Brokk+", "lines": [
		{"subject": "self", "cond": "own_turn", "value": 1, "action": "ability", "ability": "war_cry"},
		{"subject": "self", "cond": "hp_below", "value": 50, "action": "ability", "ability": "stone_wall"},
		{"subject": "self", "cond": "hp_above", "value": 50, "action": "test_next"},
		{"subject": "self", "cond": "lacks_status", "value": "provoke", "action": "provoke"},
		{"subject": "self", "cond": "hp_below", "value": 50, "action": "defend"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "cultist_ward", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"alva": {"name": "Syster Alva+", "lines": [
		{"subject": "any_ally", "cond": "hp_below", "value": 35, "action": "ability", "ability": "healing_light", "target": "that"},
		{"subject": "any_ally", "cond": "lacks_status", "value": "renew", "action": "test_next"},
		{"subject": "any_ally", "cond": "hp_below", "value": 60, "action": "ability", "ability": "renew", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "ability", "ability": "judgement", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "bone_armor", "action": "ability", "ability": "judgement", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "wraith_ethereal", "action": "ability", "ability": "judgement", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}]},
	"eira": {"name": "Jägaren Eira+", "lines": [
		{"subject": "enemy_3", "cond": "is_alive", "action": "ability", "ability": "arrow_rain"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "cultist_ward", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "has_trait", "value": "grave_pact", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "has_status", "value": "marked", "action": "attack", "target": "that"},
		{"subject": "any_enemy", "cond": "lowest_hp", "action": "ability", "ability": "hunters_mark", "target": "that"},
		{"subject": "any_enemy", "cond": "is_alive", "action": "attack", "target": "that"}]},
}


static func run_fight(data: Dictionary, seed_value: int, skill: Skill, encounter := "crypt_1",
		party: Array = [], traits := {}, charges := {}, artifacts := {}, depth := 1, opts := {}) -> Dictionary:
	var sim := CombatSim.create(data, encounter, seed_value, party, traits, charges, artifacts, depth, opts)
	sim.begin()
	var guard := 0
	var no_match := 0
	while sim.outcome == "" and guard < 500:
		guard += 1
		if not sim.needs_input():
			sim.ai_act()
			continue
		if skill == Skill.BASIC:
			sim.act("attack")
			continue
		var macros: Dictionary = data.macros if skill == Skill.MACRO else TUNED_MACROS
		var decision := MacroRunner.decide(sim, sim.current, macros.get(sim.current.id, {"lines": []}))
		if decision.ok:
			sim.act(decision.action, decision.target, decision.ability)
		else:
			no_match += 1
			if sim.act("defend") != "":
				sim.act("attack")  # Inga bönder: Försvara går inte
		sim.drain_events()
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	return {"outcome": sim.outcome, "turns": sim.turn_no, "alive": alive, "no_match": no_match, "sim": sim}


## En hel Realm (standard kryptan) i följd med Charges som räcker alla våningarna. Sant om sällskapet klarar den.
static func run_crypt(data: Dictionary, seed_value: int, skill: Skill, traits := {}, artifacts := {},
		depth := 1, floors: Array = RunState.FLOORS, opts := {}) -> bool:
	var state := RunState.new()
	state.fill_charges(data)
	for floor in floors:
		var r := run_fight(data, seed_value, skill, floor, state.party, traits, state.charges, artifacts, depth, opts)
		if r.outcome != "victory":
			return false
		state.store_charges(r.sim)
	return true


## Inställningar för en körning med instabilitet: reglerna slumpas med fröet (samma för alla
## våningar), som när spelaren väljer instabilitet vid Kryptporten.
static func instability_opts(data: Dictionary, seed_value: int, level: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + level
	var rolled := RunState.roll_rules(data, level, rng)
	return {"rules": rolled.visible + rolled.hidden, "instability": level}


## En hel körning på rumskartan (0.18): våning för våning väljer boten väg, går igenom rummen och
## spelar striderna med Charges som räcker hela körningen. policy: "simple" undviker elit och portal
## (slumpar bland resten), "greedy" tar elit, portal och skattkammare först. På helgedomen tas
## Charges om de erbjuds, annars välsignelsen. Returnerar {cleared, fights, quest_done, rooms}.
static func run_expedition(data: Dictionary, seed_value: int, skill: Skill, traits := {}, artifacts := {},
		depth := 1, realm := "crypt", opts := {}, policy := "simple") -> Dictionary:
	var state := RunState.new()
	state.set_realm(data, realm)
	state.depth = depth
	state.instability = int(opts.get("instability", 0))
	state.rules_visible = opts.get("rules", []).duplicate()
	state.fill_charges(data)
	state.start_expedition(data, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 13 + 5
	var fights := 0
	var rooms := 0
	# Nivåer (0.19): opts.levels = startnivåer per hjälte; med opts.grow växer de av erfarenheten upp till opts.cap.
	var levels: Dictionary = opts.get("levels", {}).duplicate(true)
	while not state.finished and rooms < 60:
		var options := state.choices()
		if options.is_empty():
			break
		var r := state.enter(_pick_room(state, options, policy, rng))
		rooms += 1
		if RunState.is_battle(r):
			var battle_opts := state.battle_opts()
			for key in opts:
				if not battle_opts.has(key) and not key in ["levels", "grow", "cap"]:
					battle_opts[key] = opts[key]
			if not levels.is_empty():
				battle_opts.levels = levels
			var result := run_fight(data, seed_value * 31 + fights, skill, state.encounter(), state.party, traits,
					state.charges, artifacts, depth, battle_opts)
			fights += 1
			if result.outcome != "victory":
				return {"cleared": false, "fights": fights, "quest_done": state.quest.get("done", false), "rooms": rooms,
						"lost_at": "f%d_%s" % [state.floor, r.kind]}
			state.store_charges(result.sim)
			if opts.get("grow", false):
				var xp := HeroStats.battle_xp(r.kind, depth, r.get("boss", false))
				for hero_id in levels:
					HeroStats.add_xp(levels[hero_id], xp, int(opts.get("cap", 99)))
			state.battle_won()
			if state.floor_cleared():
				state.next_floor(data)
		else:
			match r.kind:
				"campfire":
					state.campfire(data)
				"treasure":
					state.treasure(data, rng)
				"shrine":
					var gifts := state.shrine_options(data, rng)
					state.apply_shrine(data, rng, gifts[0] if gifts[0].kind == "charge" else gifts[1])
	return {"cleared": state.finished, "fights": fights, "quest_done": state.quest.get("done", false), "rooms": rooms,
			"levels": levels}


## Sällskapet på en viss nivå med de förvalda personligheterna (för balansrapporten).
static func party_levels(data: Dictionary, level: int, party: Array = ["paladin", "brokk", "alva", "eira"]) -> Dictionary:
	var out := {}
	for hero_id in party:
		out[hero_id] = {"level": level, "xp": 0, "personality": data.heroes[hero_id].get("personality", "")}
	return out


static func _pick_room(state: RunState, options: Array, policy: String, rng: RandomNumberGenerator) -> String:
	if options.size() == 1:
		return options[0]
	var kinds := {}
	for id in options:
		kinds[id] = state.map.room(id).kind
	var order: Array = ["elite", "portal", "treasure", "shrine", "battle", "campfire", "end"] if policy == "greedy" \
			else ["campfire", "shrine", "treasure", "battle", "end", "portal", "elite"]
	if policy == "simple":
		var safe := options.filter(func(id: String) -> bool: return not kinds[id] in ["elite", "portal"])
		if not safe.is_empty():
			return safe[rng.randi() % safe.size()]
	for kind in order:
		for id in options:
			if kinds[id] == kind:
				return id
	return options[0]
