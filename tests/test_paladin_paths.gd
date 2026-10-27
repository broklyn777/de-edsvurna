extends "res://tests/test_case.gd"
## Paladinens inriktningar (docs/plan/paladin-inriktningar.md): Sköldbäraren och Ljusbäraren, Glöd, Befäl, Edens sköld,
## Gryningens hand, valet och bytet hos Gorm, gamla profiler och makrovillkoren.


func _data(path_id := "") -> Dictionary:
	var d := GameData.load_all()
	Paths.apply(d, path_id)
	return d


func _sim(d: Dictionary, traits := {}) -> CombatSim:
	var sim := CombatSim.create(d, "crypt_1", 3, ["paladin", "brokk", "alva", "eira"], traits)
	return sim


func _pal(sim: CombatSim) -> CombatUnit:
	return sim.unit("paladin")


func test_apply_sets_and_removes_the_path() -> void:
	var d := _data("shield")
	assert_eq(d.heroes.paladin.path, "shield")
	assert_true(d.heroes.paladin.abilities.has("pal_intervene"), "Sköldbäraren kan kasta sig emellan")
	assert_true(d.heroes.paladin.path_traits.has("path_shield_core"))
	assert_true(float(d.heroes.paladin.stats.defense) > 5.0, "mer Defense")
	Paths.apply(d, "light")
	assert_true(not d.heroes.paladin.abilities.has("holy_shield"), "Ljusbäraren har fyra förmågor, utan Helig sköld")
	assert_true(d.heroes.paladin.abilities.has("pal_foresight"))
	Paths.apply(d, "")
	assert_eq(d.heroes.paladin.abilities, ["holy_smite", "holy_shield"], "utan väg är paladinen som förut")
	assert_true(not d.heroes.paladin.has("path_traits") and not d.heroes.paladin.has("path"))


func test_choose_and_change_path() -> void:
	var d := _data()
	var p := Profile.new()
	p.silver = 60
	var rows: Variant = p.choose_path(d, "shield")
	assert_true(rows != null and (rows as Array).size() == 3, "eden ger tre startrader")
	assert_eq(p.silver, 60, "det första valet är gratis")
	assert_true(Gambits.has(p.gambits, "g_glow"), "eden lär ut Glöd minst …")
	assert_true(p.found_rows.any(func(r: Dictionary) -> bool: return r.line.cond == "glow_at_least"), "som en funnen rad")
	assert_eq(p.choose_path(d, "shield"), null, "samma väg är inget byte")
	assert_true(p.choose_path(d, "light") != null)
	assert_eq(p.silver, 60, "det första bytet är gratis")
	assert_eq(p.path_changes, 1)
	assert_true(p.choose_path(d, "shield") != null)
	assert_eq(p.silver, 10, "sedan kostar ett byte %d silver" % Paths.BYTE_COST)
	assert_eq(p.choose_path(d, "light"), null, "för lite silver")
	assert_eq(p.path, "shield")


func test_old_profiles_keep_everything() -> void:
	var p := Profile.new()
	assert_eq(p.path, "", "en profil utan väg är som förut tills den väljer")
	assert_true(not p.path_offered)


func test_command_costs_three_glow_and_gives_an_extra_action() -> void:
	var d := _data("shield")
	var sim := _sim(d)
	var pal := _pal(sim)
	sim.current = pal
	assert_eq(sim.can_act(pal, "ability", "pal_command"), "glow", "Befäl kostar 3 Glöd")
	pal.stacks[CombatSim.GLOW] = 4.0
	assert_eq(sim.can_act(pal, "ability", "pal_command"), "")
	sim.order.erase("eira")
	sim.order.push_back("eira")
	var before := sim.order.size()
	assert_eq(sim.act("ability", "eira", "pal_command"), "")
	assert_eq(pal.stacks.get(CombatSim.GLOW), 1.0, "tre förbrukade")
	assert_eq(sim.current.id, "eira", "Eira agerar direkt")
	assert_true(sim.order.has("eira"), "och behåller sin vanliga plats på tidslinjen")
	assert_true(sim.order.size() >= before - 1)
	assert_true(not sim.command_targets(pal).has(sim.unit("eira")), "inte samma allierad två gånger på en runda")
	assert_true(not sim.command_targets(pal).has(pal), "aldrig paladinen själv")


func test_edens_shield_takes_a_share_and_counts_his_defense() -> void:
	var d := _data("shield")
	var sim := _sim(d)
	var pal := _pal(sim)
	var brokk := sim.unit("brokk")
	var foe: CombatUnit = sim.enemies[0]
	var hp_before := pal.hp
	sim._deal_damage(foe, brokk, 40.0, "physical", "strike", false, true, "pure")
	var taken := hp_before - pal.hp
	assert_true(taken > 0.0, "paladinen tar en del av träffen mot Brokk")
	pal.hp = pal.max_hp
	sim._add_aura(pal, pal, "defend")
	hp_before = pal.hp
	sim._deal_damage(foe, brokk, 40.0, "physical", "strike", false, true, "pure")
	assert_true(hp_before - pal.hp < taken, "Försvara minskar andelen")
	assert_true(pal.stacks.get(CombatSim.GLOW, 0.0) >= 1.0, "en tagen träff åt någon ger Glöd")


func test_intervene_draws_attacks_without_defense_loss() -> void:
	var d := _data("shield")
	var sim := _sim(d)
	var pal := _pal(sim)
	sim.current = pal
	sim.order.assign(sim.units.filter(func(x: CombatUnit) -> bool: return x != pal).map(func(x: CombatUnit) -> String: return x.id))
	var def_before := pal.defense_now()
	assert_eq(sim.act("ability", "", "pal_intervene"), "")
	assert_true(pal.auras.has("pal_between"))
	assert_true(pal.defense_now() >= def_before, "ingen Defense går förlorad, till skillnad från Provocera")
	assert_eq(sim.valid_targets(sim.enemies[0], "attack"), ["paladin"], "fiendernas anfall går till honom")


func test_light_core_replaces_dawn_oath_heal() -> void:
	var d := _data("light")
	var with_light := CombatSim.expand_traits(d, ["oath_dawn"] + d.heroes.paladin.path_traits)
	assert_true(not with_light.has("oath_dawn_light"), "Gryningens hand ersätter kallets egen helning")
	assert_true(CombatSim.expand_traits(d, ["oath_dawn"]).has("oath_dawn_light"), "utan vägen finns den kvar")


func test_glow_conditions() -> void:
	var d := _data("light")
	var sim := _sim(d)
	var pal := _pal(sim)
	var line := {"subject": "self", "cond": "glow_at_least", "value": 3, "action": "ability", "ability": "holy_smite", "target": "that"}
	assert_true(not MacroRunner.test_condition(sim, pal, pal, line, [pal]))
	pal.stacks[CombatSim.GLOW] = 3.0
	assert_true(MacroRunner.test_condition(sim, pal, pal, line, [pal]))
	sim.current = pal
	var dec := MacroRunner.decide(sim, pal, {"lines": [line]})
	assert_true(dec.ok and sim.unit(dec.target).team == 1, "raden om hjälten själv slår förmågans förvalda mål")
	var foe: CombatUnit = sim.enemies[0]
	foe.intent = {"ability": foe.attack_ability, "targets": ["alva"]}
	var t := {"subject": "any_ally", "cond": "is_attack_target", "action": "ability", "ability": "pal_foresight", "target": "that"}
	assert_true(MacroRunner.test_condition(sim, pal, sim.unit("alva"), t, []), "Alva är målet för ett anfall")
	assert_true(not MacroRunner.test_condition(sim, pal, sim.unit("eira"), t, []))


func test_ash_trophy_has_its_own_stack() -> void:
	var d := _data()
	assert_eq(d.traits.ember_jaw.name, "Den slocknade askan")
	assert_eq(d.traits.ember_jaw.release.stack, "aska", "trofén delar inte paladinens Glöd")
	assert_true(not String(d.traits.ember_jaw.text).contains("Glöd"))
