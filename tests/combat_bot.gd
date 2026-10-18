extends RefCounted
## Simulerade spelare för balanstester.
##   NONE   – trycker aldrig på något (bara hjältarnas AI)
##   GOOD   – reagerar på mekanikerna som en van spelare
##   SLOPPY – som GOOD, men missar ungefär var tredje reaktion

enum Skill { NONE, GOOD, SLOPPY }

const DT := 1.0 / 30.0


## traits: hero_id -> trait_id, ersätter hjältens förvalda egenskap.
## artifacts: hero_id -> trait_id, läggs till som hjältens andra egenskap.
static func run_fight(data: Dictionary, seed_value: int, skill: Skill, max_time := 400.0,
		traits := {}, artifacts := {}) -> Dictionary:
	var sim := CombatSim.create(data, "bone_lich", seed_value)
	for hero_id in traits:
		sim.unit(hero_id).traits = [traits[hero_id]]
	for hero_id in artifacts:
		sim.unit(hero_id).traits.append(artifacts[hero_id])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7 + 3
	var reacted := {}
	while sim.outcome == "" and sim.time < max_time:
		sim.advance(DT)
		sim.drain_events()
		if skill != Skill.NONE:
			_act(sim, skill, rng, reacted)
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	return {"outcome": sim.outcome, "time": sim.time, "alive": alive, "boss_hp": sim.boss.hp_pct()}


static func _act(sim: CombatSim, skill: Skill, rng: RandomNumberGenerator, reacted: Dictionary) -> void:
	var boss := sim.boss
	var cast_key := "%s@%d" % [boss.cast.get("ability", ""), int(sim.time - boss.cast.get("elapsed", 0.0))]
	if boss.is_casting() and not reacted.has(cast_key) and boss.cast_progress() > 0.35:
		reacted[cast_key] = true
		var miss := skill == Skill.SLOPPY and rng.randf() < 0.33
		if not miss:
			match boss.cast.ability:
				"shadow_bolt_volley":
					sim.player_use("kick")
				"bone_crush":
					sim.player_use("shield_wall")
	if sim.time > 2.0 and sim.time < 2.2:
		sim.player_use("bloodlust")
	if sim.unit("mage").cooldown_left("pyroblast") == 0.0 and sim.unit("mage").queued.is_empty():
		sim.player_use("pyroblast")
	var priest := sim.unit("priest")
	if priest.alive and not (priest.is_casting() and priest.cast.by_player) and priest.queued.is_empty():
		for h in sim.heroes:
			if h.alive and h.hp_pct() < 0.45:
				sim.player_use("flash_heal", h.id)
				break
