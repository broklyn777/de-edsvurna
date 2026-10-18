extends "res://tests/test_case.gd"

const Bot := preload("res://tests/combat_bot.gd")

var _data := GameData.load_all()


func _sim(seed_value := 42) -> CombatSim:
	var sim := CombatSim.create(_data, "crypt_1", seed_value)
	sim.begin()
	return sim


## Låter AI:n spela tills det är hjältens tur.
func _until_hero(sim: CombatSim, hero_id: String) -> void:
	var guard := 0
	while sim.outcome == "" and (sim.current == null or sim.current.id != hero_id) and guard < 100:
		guard += 1
		sim.auto = true
		sim.ai_act()
	sim.auto = false


func test_fastest_acts_first() -> void:
	var sim := _sim()
	assert_eq(sim.current.id, "eira", "Eira är snabbast (14)")
	assert_eq(sim.order[0], "skeleton_archer_1", "bågskytten (13) kommer sedan")


func test_round_gives_everyone_one_turn() -> void:
	var sim := _sim()
	var seen := {}
	var guard := 0
	while sim.round == 1 and guard < 50:
		guard += 1
		seen[sim.current.id] = seen.get(sim.current.id, 0) + 1
		sim.auto = true
		sim.ai_act()
	assert_eq(seen.size(), 8)
	assert_true(seen.values().all(func(n: int) -> bool: return n == 1), "en tur var per runda")


func test_hero_waits_for_player() -> void:
	var sim := _sim()
	assert_true(sim.needs_input(), "Eira börjar och väntar på spelaren")
	var turn := sim.turn_no
	assert_eq(sim.act("attack", "grave_priest_1"), "")
	assert_true(sim.turn_no > turn)
	assert_true(sim.unit("grave_priest_1").hp < sim.unit("grave_priest_1").max_hp)


func test_signature_cooldown_counts_own_turns() -> void:
	var sim := _sim()
	sim.act("signature", "skeleton_warrior_1")  # Märk byte, nedkylning 2
	_until_hero(sim, "eira")
	assert_eq(sim.can_act(sim.current, "signature"), "cooldown")
	sim.act("attack")
	_until_hero(sim, "eira")
	assert_eq(sim.can_act(sim.current, "signature"), "cooldown")
	sim.act("attack")
	_until_hero(sim, "eira")
	assert_eq(sim.can_act(sim.current, "signature"), "")


func test_defend_halves_damage_until_next_turn() -> void:
	var sim := _sim()
	var brokk := sim.unit("brokk")
	var normal := brokk.damage_taken()
	_until_hero(sim, "brokk")
	sim.act("defend")
	assert_near(brokk.damage_taken(), normal * 0.5)
	_until_hero(sim, "brokk")
	assert_near(brokk.damage_taken(), normal)


func test_challenge_redirects_enemy_intents() -> void:
	var sim := _sim()
	_until_hero(sim, "brokk")
	sim.act("signature")
	for e in sim.enemies:
		if e.alive and sim.ability(e.intent.ability).target == "enemy":
			assert_eq(e.intent.targets, ["brokk"])


func test_vengeance_strikes_back_when_ally_hit() -> void:
	var sim := _sim()
	var archer := sim.unit("skeleton_archer_1")
	sim.drain_events()
	sim._deal_damage(archer, sim.unit("alva"), 50.0, "physical", "bone_arrow", false, true)
	var back := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.ability == "oath_vengeance")
	assert_eq(back.size(), 1)
	assert_eq(back[0].target, archer.id)
	sim._deal_damage(archer, sim.unit("eira"), 50.0, "physical", "bone_arrow", false, true)
	assert_eq(sim.drain_events().filter(func(e: Dictionary) -> bool: return e.ability == "oath_vengeance").size(), 0,
			"bara en gång per tur")


func test_bulwark_and_blessing_empower_next_attack() -> void:
	var sim := _sim()
	var paladin := sim.unit("paladin")
	sim._add_aura(sim.unit("brokk"), sim.unit("brokk"), "defend")
	assert_true(paladin.auras.has("inspired"), "Stenhård ger hela sällskapet Styrka")
	paladin.crit_chance = 0.0
	sim._deal_damage(paladin, sim.unit("skeleton_warrior_1"), 100.0, "physical", "strike", true, true)
	var hit: Dictionary = sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.source == "paladin")[0]
	assert_near(hit.amount, 130.0)
	assert_true(not paladin.auras.has("inspired"), "Styrka förbrukas")


func test_eira_follows_up_on_marked() -> void:
	var sim := _sim()
	sim._add_aura(sim.unit("eira"), sim.unit("skeleton_warrior_1"), "marked")
	sim.drain_events()
	sim.act("attack", "skeleton_warrior_1")
	var follow := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.ability == "eira_followup")
	assert_eq(follow.size(), 1)


func test_auto_party_beats_crypt() -> void:
	var wins := 0
	for seed_value in range(1, 21):
		if Bot.run_fight(_data, seed_value, Bot.Skill.AUTO).outcome == "victory":
			wins += 1
	assert_true(wins >= 10, "auto-sällskapet ska vinna minst hälften (vann %d/20)" % wins)
