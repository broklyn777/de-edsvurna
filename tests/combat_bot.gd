extends RefCounted
## Simulerade spelare för balanstester i turordningsstriden.
##   BASIC – anfaller alltid det förvalda målet
##   MACRO – hjältarna kör startmakrona i data/macros.json (det Auto gör från början)
##   TUNED – startmakrona med små förbättringar (TUNED_MACROS nedan): visar att makrobygget spelar roll

enum Skill { BASIC, MACRO, TUNED }

## Startmakrona förbättrade för att svara på fiendernas egenskaper (0.14): döda Gravprästen först
## (Gravpakt), besvärjelser mot Benrustning, Pilregn mot många, Krigsrop i första turen, och Brokk
## provocerar bara med mycket liv. I kapellet (0.16): Kultisterna först (biskopen är immun så länge de
## lever), Ljusets dom mot Gasten som undviker attacker. Försök som sparade Charges förlorade oftare – att spendera är oftast rätt.
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
		{"subject": "any_ally", "cond": "hp_below", "value": 50, "action": "ability", "ability": "healing_light", "target": "that"},
		{"subject": "any_ally", "cond": "lacks_status", "value": "renew", "action": "test_next"},
		{"subject": "any_ally", "cond": "hp_below", "value": 80, "action": "ability", "ability": "renew", "target": "that"},
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
