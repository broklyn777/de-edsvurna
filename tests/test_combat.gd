extends "res://tests/test_case.gd"

const Bot := preload("res://tests/combat_bot.gd")

var _data := GameData.load_all()


func _sim() -> CombatSim:
	return CombatSim.create(_data, "bone_lich", 42)


func _advance_until(sim: CombatSim, condition: Callable, max_time := 60.0) -> bool:
	while sim.time < max_time:
		if condition.call():
			return true
		sim.advance(CombatSim.STEP)
	return false


func test_boss_targets_tank_first() -> void:
	var sim := _sim()
	assert_eq(sim.threat_target().id, "warrior")


func test_tank_keeps_threat_over_mage() -> void:
	var sim := _sim()
	sim.advance(20.0)
	assert_eq(sim.threat_target().id, "warrior")


func test_player_command_overrides_ai_cast() -> void:
	var sim := _sim()
	var mage := sim.unit("mage")
	_advance_until(sim, func() -> bool: return mage.is_casting() and mage.cast.ability == "frostbolt")
	assert_eq(sim.player_use("pyroblast"), "used")
	assert_eq(mage.cast.ability, "pyroblast")
	assert_true(mage.cast.by_player, "pyroblast ska vara spelarens cast")


func test_spell_queue_runs_after_player_cast() -> void:
	var sim := _sim()
	var priest := sim.unit("priest")
	assert_eq(sim.player_use("flash_heal"), "used")
	assert_eq(sim.player_use("flash_heal", "mage"), "queued")
	sim.advance(1.6)
	assert_true(priest.is_casting(), "köad Flash Heal ska ha startat")
	assert_eq(priest.cast.targets, ["mage"])


func test_kick_interrupts_volley() -> void:
	var sim := _sim()
	var boss := sim.boss
	assert_true(_advance_until(sim, func() -> bool: return boss.is_casting() and boss.cast.ability == "shadow_bolt_volley"))
	sim.drain_events()
	assert_eq(sim.player_use("kick"), "used")
	assert_true(not boss.is_casting(), "volley ska vara avbruten")
	var interrupted := sim.drain_events().any(func(e: Dictionary) -> bool:
		return e.type == "cast_end" and e.result == "interrupted")
	assert_true(interrupted, "cast_end/interrupted-händelse saknas")


func test_kick_without_cast_is_refused() -> void:
	var sim := _sim()
	assert_eq(sim.player_use("kick"), "nothing_to_interrupt")
	assert_eq(sim.unit("rogue").cooldown_left("kick"), 0.0)


func test_shield_wall_reduces_damage() -> void:
	var sim := _sim()
	var warrior := sim.unit("warrior")
	var normal := warrior.damage_taken()
	sim.player_use("shield_wall")
	assert_near(warrior.damage_taken(), normal * 0.35)


func test_bloodlust_hastes_party() -> void:
	var sim := _sim()
	sim.player_use("bloodlust")
	for h in sim.heroes:
		assert_near(h.haste(), 1.3)


func test_fight_without_input_is_lost() -> void:
	var wins := 0
	for seed_value in range(1, 11):
		if Bot.run_fight(_data, seed_value, Bot.Skill.NONE).outcome == "victory":
			wins += 1
	assert_true(wins <= 1, "utan spelare ska partyt nästan alltid förlora (vann %d/10)" % wins)


func test_good_player_wins() -> void:
	var wins := 0
	for seed_value in range(1, 11):
		if Bot.run_fight(_data, seed_value, Bot.Skill.GOOD).outcome == "victory":
			wins += 1
	assert_true(wins >= 9, "en bra spelare ska nästan alltid vinna (vann %d/10)" % wins)


func test_kick_exposes_boss() -> void:
	var sim := _sim()
	var boss := sim.boss
	assert_true(_advance_until(sim, func() -> bool: return boss.is_casting() and boss.cast.ability == "shadow_bolt_volley"))
	sim.drain_events()
	sim.player_use("kick")
	assert_true(boss.auras.has("exposed"), "Blottlägg ska ge bossen Blottad")
	var procced := sim.drain_events().any(func(e: Dictionary) -> bool:
		return e.type == "trait" and e.trait == "expose")
	assert_true(procced, "trait-händelse saknas")


func test_mage_always_crits_exposed_target() -> void:
	var sim := _sim()
	sim._add_aura(sim.unit("rogue"), sim.boss, "exposed", 99.0)
	sim.advance(12.0)
	var mage_hits := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.source == "mage")
	assert_true(mage_hits.size() >= 3, "Mage borde ha träffat flera gånger")
	assert_true(mage_hits.all(func(e: Dictionary) -> bool: return e.crit), "alla Mage-träffar ska vara kritiska")


func test_retaliation_only_under_shield_wall() -> void:
	var sim := _sim()
	sim.advance(6.0)
	var before := sim.drain_events().any(func(e: Dictionary) -> bool: return e.get("ability", "") == "retaliation")
	assert_true(not before, "Vedergällning ska inte slå till utan Shield Wall")
	sim.player_use("shield_wall")
	sim.advance(6.0)
	var after := sim.drain_events().any(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.ability == "retaliation" and e.target == "bone_lich")
	assert_true(after, "Vedergällning ska slå tillbaka mot bossen")


func test_crit_gives_priest_mana() -> void:
	var sim := _sim()
	var priest := sim.unit("priest")
	priest.mana = 1000.0
	priest.mana_regen = 0.0
	sim._deal_damage(sim.unit("rogue"), sim.boss, 10.0, "physical", "melee", true, false)
	assert_near(priest.mana, 1000.0)
	sim.unit("rogue").crit_chance = 1.0
	sim._deal_damage(sim.unit("rogue"), sim.boss, 10.0, "physical", "melee", true, true)
	assert_near(priest.mana, 1030.0)


func test_poison_ticks_damage_over_time() -> void:
	var sim := _sim()
	sim._add_aura(sim.unit("rogue"), sim.boss, "poison")
	sim.drain_events()
	sim.advance(3.0)
	var ticks := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.ability == "poison")
	assert_eq(ticks.size(), 3)


func test_mercy_boosts_heals_on_low_target() -> void:
	var sim := _sim()
	var priest := sim.unit("priest")
	var mage := sim.unit("mage")
	priest.traits = ["mercy"]
	priest.crit_chance = 0.0
	mage.hp = 100.0
	sim._heal(priest, mage, 200.0, "flash_heal", false)
	assert_near(mage.hp, 400.0)
	mage.hp = 600.0
	sim._heal(priest, mage, 200.0, "flash_heal", false)
	assert_near(mage.hp, 800.0)


func test_chosen_traits_replace_defaults() -> void:
	var r := Bot.run_fight(_data, 1, Bot.Skill.GOOD, 400.0, {"mage": "combustion", "rogue": "envenom"})
	assert_eq(r.outcome, "victory")


func test_adding_traits_does_not_change_game_data() -> void:
	var sim := _sim()
	sim.unit("mage").traits.append("fire_rune")
	assert_eq(_data.heroes.mage.traits, ["kindling"])
