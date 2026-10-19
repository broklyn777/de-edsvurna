extends "res://tests/test_case.gd"
## Siralims stats och skadeformler (docs/research/siralim.md §2 och §12).

var _data := GameData.load_all()


func _sim(encounter := "crypt_1") -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 7)
	sim.begin()
	sim.drain_events()
	return sim


func _hits(sim: CombatSim, source_id: String) -> Array:
	return sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "damage" and e.source == source_id)


func test_units_have_siralims_five_stats() -> void:
	var sim := _sim()
	var brokk := sim.unit("brokk")
	assert_eq(brokk.max_hp, float(_data.heroes.brokk.stats.health))
	assert_eq(brokk.attack, float(_data.heroes.brokk.stats.attack))
	assert_eq(brokk.intelligence, float(_data.heroes.brokk.stats.intelligence))
	assert_eq(brokk.defense, float(_data.heroes.brokk.stats.defense))
	assert_eq(brokk.speed, float(_data.heroes.brokk.stats.speed))
	for kind in _data.enemies:
		assert_true(_data.enemies[kind].stats.has("defense"), "%s har Defense" % kind)


func test_attack_formula() -> void:
	# (max(Attack − Defense, 0) + 1 % · Attack) × modifierare
	assert_near(CombatSim.attack_damage(100.0, 30.0), 71.0)
	assert_near(CombatSim.attack_damage(100.0, 30.0, 2.0), 142.0)
	assert_near(CombatSim.attack_damage(20.0, 50.0), 0.2, 0.001, "Defense över Attack lämnar bara 1 %")


func test_spell_formula_and_tiers() -> void:
	# max(Potency − Defense, 0) × modifierare; starkare nivåer ignorerar en del av Defense
	assert_near(CombatSim.spell_damage(100.0, 40.0), 60.0)
	assert_near(CombatSim.spell_damage(100.0, 40.0, 1.0, 0.2), 68.0)
	assert_near(CombatSim.spell_damage(30.0, 40.0), 0.0)
	assert_eq(CombatSim.SPELL_TIERS.massive, [1.3, 0.3])


func test_indirect_formula() -> void:
	# skada × modifierare − 20 % · Defense
	assert_near(CombatSim.indirect_damage(50.0, 45.0), 41.0)
	assert_near(CombatSim.indirect_damage(5.0, 45.0), 0.0)


func test_increases_add_and_reductions_multiply() -> void:
	assert_near(CombatSim.combine_mods([1.75, 1.75]), 2.5, 0.001, "+75 % och +75 % = +150 %")
	assert_near(CombatSim.combine_mods([0.6, 0.5]), 0.3, 0.001, "−40 % och −50 % = −70 %")
	assert_near(CombatSim.combine_mods([0.05]), 0.2, 0.001, "en minskning stannar vid 80 %")
	assert_near(CombatSim.combine_mods([1.5, 0.5]), 0.75)


func test_crit_and_dodge_from_speed_ratio() -> void:
	assert_near(CombatSim.crit_bonus(1.0), 0.75)
	assert_near(CombatSim.crit_bonus(3.0), 2.0, 0.001, "Siralim: +200 % vid 3× målets fart")
	assert_near(CombatSim.crit_bonus(27.0), 4.5, 0.001, "Siralim: ~+450 % vid 27×")
	assert_near(CombatSim.crit_bonus(0.5), 0.5, 0.001, "aldrig under +50 %")
	assert_near(CombatSim.crit_chance_for(0.1, 1.0), 0.1)
	assert_near(CombatSim.crit_chance_for(0.1, 2.0), 0.2)
	assert_near(CombatSim.crit_chance_for(0.1, 1000.0), 0.5, 0.001, "högst 50 %")
	assert_near(CombatSim.dodge_chance(1.0), 0.0, 0.001, "lika fart: inget undvikande")
	assert_near(CombatSim.dodge_chance(0.5), 0.0, 0.001, "ett långsammare mål undviker aldrig")
	assert_near(CombatSim.dodge_chance(2.0), 0.1)
	assert_near(CombatSim.dodge_chance(64.0), 0.3, 0.001, "högst 30 %")


func test_strike_uses_attack_minus_defense() -> void:
	var sim := _sim()
	var paladin := sim.unit("paladin")
	var warrior := sim.unit("skeleton_archer_1")  # utan Benrustning
	paladin.crit_chance = -1.0
	sim._deal_damage(paladin, warrior, 1.0, "physical", "strike", true, true, "attack", true)
	var hit: Dictionary = _hits(sim, "paladin")[0]
	var low := roundf(CombatSim.attack_damage(paladin.attack * 0.9, warrior.defense))
	var high := roundf(CombatSim.attack_damage(paladin.attack * 1.1, warrior.defense))
	assert_true(hit.amount >= low and hit.amount <= high, "%d inom %d–%d" % [hit.amount, low, high])


func test_spells_use_intelligence_and_never_crit() -> void:
	var sim := _sim()
	var alva := sim.unit("alva")
	var warrior := sim.unit("skeleton_warrior_1")
	alva.crit_chance = 1.0
	alva.attack = 1.0
	sim._deal_damage(alva, warrior, 1.0, "holy", "judgement", true, true, "spell", true)
	var hit: Dictionary = _hits(sim, "alva")[0]
	assert_true(not hit.crit, "spells blir inte kritiska")
	var tier: Array = CombatSim.SPELL_TIERS[_data.abilities.judgement.tier]
	var high := CombatSim.spell_damage(alva.intelligence * tier[0] * 1.1, warrior.defense, 1.0, tier[1])
	assert_true(hit.amount > 10.0 and hit.amount <= roundf(high), "skadan följer Int, inte Attack")


func test_defend_and_provoke_change_defense() -> void:
	var sim := _sim()
	var brokk := sim.unit("brokk")
	sim._add_aura(brokk, brokk, "defend")
	assert_near(brokk.defense_now(), brokk.defense * 1.5, 0.001, "Försvara: +50 % Defense")
	assert_near(brokk.damage_taken(), 0.65, 0.001, "Försvara: −35 % skada")
	brokk.auras.clear()
	sim._add_aura(brokk, brokk, "provoke")
	assert_near(brokk.defense_now(), brokk.defense * 0.65, 0.001, "Provocera: −35 % Defense")
	assert_near(brokk.damage_taken(), 1.0, 0.001, "Provocera ger inte längre mer skada")


func test_defense_never_below_20_percent() -> void:
	var sim := _sim()
	var brokk := sim.unit("brokk")
	brokk.auras["test"] = {"defense_mult": 0.01, "damage_taken_mult": 1.0, "haste": 0.0}
	assert_near(brokk.defense_now(), brokk.defense * 0.2)


func test_indirect_damage_cannot_be_dodged_or_crit() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	var priest := sim.unit("grave_priest_1")
	eira.speed = 1000.0  # skulle undvika nästan allt
	for i in 20:
		sim._deal_damage(priest, eira, 30.0, "fire", "burning", true, false, "indirect")
	var events := sim.drain_events()
	assert_eq(events.filter(func(e: Dictionary) -> bool: return e.type == "dodge").size(), 0)
	var hits := events.filter(func(e: Dictionary) -> bool: return e.type == "damage" and e.target == "eira")
	assert_eq(hits.size(), 20)
	assert_eq(hits[0].amount, roundf(CombatSim.indirect_damage(30.0, eira.defense)))
	assert_true(hits.all(func(e: Dictionary) -> bool: return not e.crit))


func test_fast_target_dodges_attacks() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	eira.speed = 1000.0
	eira.max_hp = 100000.0
	eira.hp = eira.max_hp
	var dodged := 0
	for i in 40:
		sim._deal_damage(sim.unit("skeleton_warrior_1"), eira, 1.0, "physical", "bone_slash", true, true, "attack", true)
		dodged += sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "dodge").size()
	assert_true(dodged >= 4 and dodged <= 22, "omkring 30 %% undviks (fick %d/40)" % dodged)


func test_barrier_absorbs_before_health_and_triggers_nothing() -> void:
	var sim := _sim()
	var alva := sim.unit("alva")
	sim._add_barrier(alva, alva, 100.0)
	assert_true(alva.auras.has("barrier"))
	sim._add_barrier(alva, alva, 40.0)
	assert_eq(alva.barrier, 100.0, "den starkaste Barrier gäller, de staplas inte")
	sim.drain_events()
	sim._deal_damage(sim.unit("skeleton_archer_1"), alva, 60.0, "physical", "bone_arrow", false, true)
	var events := sim.drain_events()
	assert_eq(alva.hp, alva.max_hp, "Barrier tog allt")
	assert_eq(alva.barrier, 40.0)
	assert_eq(events.filter(func(e: Dictionary) -> bool: return e.get("ability", "") == "oath_vengeance").size(), 0,
			"en träff som Barrier tog sätter inte igång Domens kall")
	sim._deal_damage(sim.unit("skeleton_archer_1"), alva, 60.0, "physical", "bone_arrow", false, true)
	assert_eq(alva.hp, alva.max_hp - 20.0)
	assert_true(not alva.auras.has("barrier"), "Barrier försvinner när den är slut")


func test_heal_uses_intelligence() -> void:
	var sim := _sim()
	var alva := sim.unit("alva")
	var amount := sim._heal_amount(alva, _data.abilities.healing_light.effects[0])
	var power: float = _data.abilities.healing_light.effects[0].power
	assert_true(amount >= alva.intelligence * power * 0.9 and amount <= alva.intelligence * power * 1.1)


func test_macro_conditions_on_stats() -> void:
	var sim := _sim("crypt_2")
	var paladin := sim.unit("paladin")
	var line := {"subject": "any_enemy", "cond": "lowest_defense", "action": "attack", "target": "that"}
	assert_eq(MacroRunner.match_line(sim, paladin, line), sim.unit("skeleton_archer_1"), "bågskytten har lägst Defense")
	line.cond = "highest_defense"
	assert_eq(MacroRunner.match_line(sim, paladin, line), sim.unit("grave_warden_1"))
	line.subject = "any_ally"
	line.cond = "highest_attack"
	assert_eq(MacroRunner.match_line(sim, paladin, line), paladin)
	var warden := sim.unit("grave_warden_1")
	sim._add_aura(warden, warden, "provoke")
	line = {"subject": "any_enemy", "cond": "highest_defense", "action": "attack", "target": "that"}
	assert_near(warden.defense_now(), warden.defense * 0.65)
	assert_eq(MacroRunner.match_line(sim, paladin, line), warden, "Provocera sänker Defense, men väktaren har fortfarande högst")
	assert_eq(MacroRunner.condition_name(_data, "lowest_defense", 0), "har lägst Defense")
