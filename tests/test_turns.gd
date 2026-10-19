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


func test_timeline_rotates_actor_to_bottom() -> void:
	var sim := _sim()
	var first_cycle := [sim.current.id] + sim.order
	sim.act("attack")
	assert_eq(sim.order[-1], "eira", "den som agerat läggs längst ned")
	var seen := {}
	var guard := 0
	while seen.size() < 8 and guard < 50:
		guard += 1
		seen[sim.current.id] = true
		sim.auto = true
		sim.ai_act()
	assert_eq(seen.size(), 8, "alla får en tur innan någon får två")
	assert_eq(sim.upcoming(3).size(), 3)
	assert_eq(first_cycle.size(), 8)


func test_dead_leave_timeline_and_revived_rejoin_at_bottom() -> void:
	var sim := CombatSim.create(_data, "crypt_3", 3)
	sim.begin()
	var skel := sim.unit("skeleton_warrior_1")
	sim._kill(skel)
	assert_true(not sim.order.has(skel.id))
	sim._revive(skel, 0.5)
	assert_eq(sim.order[-1], skel.id)


func test_hero_waits_for_player() -> void:
	var sim := _sim()
	assert_true(sim.needs_input(), "Eira börjar och väntar på spelaren")
	var turn := sim.turn_no
	assert_eq(sim.act("attack", "grave_priest_1"), "")
	assert_true(sim.turn_no > turn)
	assert_true(sim.unit("grave_priest_1").hp < sim.unit("grave_priest_1").max_hp)


func test_abilities_spend_charges() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	var full: int = eira.charges.hunters_mark
	assert_eq(sim.act("ability", "skeleton_warrior_1", "hunters_mark"), "")
	assert_eq(eira.charges.hunters_mark, full - 1)
	eira.charges.hunters_mark = 0
	_until_hero(sim, "eira")
	assert_eq(sim.can_act(eira, "ability", "hunters_mark"), "charges")
	assert_eq(sim.can_act(eira, "ability", "healing_light"), "none", "Eira har inte Alvas förmåga")


func test_charges_carry_between_fights() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 1, [], {}, {"eira": {"hunters_mark": 2, "arrow_rain": 0}})
	assert_eq(sim.unit("eira").charges.hunters_mark, 2)
	assert_eq(sim.unit("alva").charges.healing_light, int(_data.abilities.healing_light.charges))


func test_defend_reduces_damage_until_next_turn() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	var normal := eira.damage_taken()
	sim.act("defend")
	assert_near(eira.damage_taken(), normal * 0.65)
	_until_hero(sim, "eira")
	assert_near(eira.damage_taken(), normal)


func test_provoke_redirects_enemy_intents_and_restricts_targets() -> void:
	var sim := _sim()
	sim.act("provoke")
	for e in sim.enemies:
		if e.alive and sim.ability(e.intent.ability).target == "enemy":
			assert_eq(e.intent.targets, ["eira"])
	var warden := sim.unit("skeleton_warrior_1")
	sim._add_aura(warden, warden, "provoke")
	_until_hero(sim, "paladin")
	assert_eq(sim.valid_targets(sim.current, "attack"), ["skeleton_warrior_1"], "en provocerande fiende måste anfallas")


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
	paladin.crit_chance = -1.0  # ingen krit, inte ens med fartfördel
	sim._deal_damage(paladin, sim.unit("skeleton_archer_1"), 100.0, "physical", "strike", true, true)
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


func test_auto_party_usually_beats_first_floor() -> void:
	var wins := 0
	for seed_value in range(1, 21):
		if Bot.run_fight(_data, seed_value, Bot.Skill.MACRO).outcome == "victory":
			wins += 1
	assert_true(wins >= 10, "sällskapet med startmakron ska vinna minst hälften (vann %d/20)" % wins)


func test_turn_limit_stops_endless_follow_ups() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	for i in CombatSim.TURN_LIMIT:
		assert_true(sim._within_limit(eira, "attack"))
	assert_true(not sim._within_limit(eira, "attack"), "sjätte attacken samma tur stoppas")
	assert_true(sim._within_limit(eira, "spell"), "besvärjelser räknas för sig")


func test_lich_crown_turns_follow_ups_into_holy_spells() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	eira.traits = CombatSim.expand_traits(_data, ["eira_followup", "lich_crown"])
	sim._add_aura(eira, sim.unit("skeleton_warrior_1"), "marked")
	sim.drain_events()
	sim.act("attack", "skeleton_warrior_1")
	var follow: Dictionary = sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.ability == "eira_followup")[0]
	assert_eq(follow.school, "holy")
	assert_eq(follow.kind, "spell")


func test_run_offers_trophies_from_defeated_monsters() -> void:
	var state := RunState.new()
	state.depth = 10  # så djupt att troféchansen är 100 %
	var rng := RandomNumberGenerator.new()
	var offer := state.trophy_offer(_data, rng)
	assert_eq(offer.size(), 3)
	assert_true(offer.has("bone_finger") and offer.has("rosary"))
	state.take_trophy("rosary")
	state.equip("alva", "rosary")
	state.equip("eira", "rosary")
	assert_eq(state.wearer("rosary"), "eira", "en trofé bärs av en hjälte i taget")
	assert_true(state.hero_traits(_data).eira.has("rosary"))


func test_lich_raises_dead_skeleton() -> void:
	var sim := CombatSim.create(_data, "crypt_3", 3)
	sim.begin()
	var skel := sim.unit("skeleton_warrior_1")
	sim._kill(skel)
	var lich := sim.unit("bone_lich_1")
	sim._choose_intent(lich)
	assert_eq(lich.intent.ability, "raise_dead")
	sim._perform(lich, "raise_dead", "intent", "")
	assert_true(skel.alive, "skelettet ska vara väckt")
