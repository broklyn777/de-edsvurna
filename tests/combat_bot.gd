extends RefCounted
## Simulerade spelare för balanstester i turordningsstriden.
##   BASIC – anfaller alltid det förvalda målet
##   AUTO  – hjältarnas egna regler (samma som Auto-knappen)
##   GOOD  – som AUTO, men slår ut helaren först och följer upp mot märkta mål

enum Skill { BASIC, AUTO, GOOD }


static func run_fight(data: Dictionary, seed_value: int, skill: Skill, encounter := "crypt_1",
		party: Array = [], traits := {}) -> Dictionary:
	var sim := CombatSim.create(data, encounter, seed_value, party, traits)
	sim.begin()
	var guard := 0
	while sim.outcome == "" and guard < 500:
		guard += 1
		if not sim.needs_input():
			sim.ai_act()
			continue
		match skill:
			Skill.BASIC:
				sim.act("attack")
			Skill.AUTO:
				sim.auto = true
				sim.ai_act()
				sim.auto = false
			Skill.GOOD:
				_good(sim)
		sim.drain_events()
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	return {"outcome": sim.outcome, "rounds": sim.round, "alive": alive}


static func _good(sim: CombatSim) -> void:
	var h := sim.current
	var focus := _focus_target(sim)
	if h.role == "healer" and sim.can_act(h, "signature") == "":
		for a in sim.heroes:
			if a.alive and a.hp_pct() < 0.6:
				sim.act("signature", a.id)
				return
	if h.role == "tank" and sim.can_act(h, "signature") == "":
		sim.act("signature")
		return
	if h.role in ["dps", "leader"] and sim.can_act(h, "signature") == "":
		sim.act("signature", focus)
		return
	sim.act("attack", focus)


## Helaren först, sedan märkta mål, sedan den svagaste.
static func _focus_target(sim: CombatSim) -> String:
	var best: CombatUnit = null
	for e in sim.enemies:
		if not e.alive:
			continue
		if e.rules.any(func(r: Dictionary) -> bool: return r.ability == "grave_mend"):
			return e.id
		if best == null or e.auras.has("marked") and not best.auras.has("marked") or e.hp < best.hp:
			best = e
	return best.id if best else ""
