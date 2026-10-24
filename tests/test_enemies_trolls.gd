extends "res://tests/test_case.gd"
## 0.30.23: Trollfolket (docs/plan/troll.md): artregeln Trollhud, varje trolls egenskap och förmåga, och troféerna.

var _data := GameData.load_all()


func _sim(encounter: String) -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 3, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, 1, {"elite_chance": 0.0})
	sim.begin()
	sim.drain_events()
	return sim


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


func test_trolls_have_data_trophies_and_traits() -> void:
	for id in ["moss_troll", "porridge_troll", "grumpy_troll", "club_troll", "changeling_troll", "bridge_troll", "troll_mother",
			"mountain_king"]:
		var e: Dictionary = _data.enemies[id]
		assert_eq(e.family, "troll_kin", id)
		assert_true(_data.traits.has(e.trophy) and _data.traits[e.trophy].get("trophy", false), "%s har en trofé" % id)
		for t in e.traits:
			assert_true(_data.traits.has(t), "%s: %s" % [id, t])
		for r in e.rules:
			assert_true(_data.abilities.has(r.ability), "%s: egen förmåga %s" % [id, r.ability])
		assert_true(ResourceLoader.exists("res://assets/models/%s.glb" % e.visual.model), "%s: modellen finns" % id)


func test_an_ability_stops_troll_healing() -> void:
	var sim := _sim("troll_1a")
	var moss := _enemy(sim, "moss_troll")
	moss.hp = moss.max_hp * 0.5
	var before := moss.hp
	sim._heal(moss, moss, 10.0, "troll_moss")
	assert_true(moss.hp > before, "utan svedd hud läker trollet")
	var paladin := sim.unit("paladin")
	sim._deal_damage(paladin, moss, 1.0, "holy", paladin.abilities[0] if not paladin.abilities.is_empty() else "holy_smite", false, true, "spell", true)
	assert_true(moss.auras.has("troll_scorched"), "en förmåga sveder huden")
	before = moss.hp
	sim._heal(moss, moss, 10.0, "troll_moss")
	assert_eq(moss.hp, before, "svedd hud: ingen läkning")


func test_basic_attack_does_not_scorch() -> void:
	var sim := _sim("troll_1a")
	var moss := _enemy(sim, "moss_troll")
	var brokk := sim.unit("brokk")
	sim._deal_damage(brokk, moss, 1.0, "physical", brokk.attack_ability, false, true, "attack", true)
	assert_true(not moss.auras.has("troll_scorched"))


func test_porridge_grows_when_heroes_are_healed() -> void:
	var sim := _sim("troll_1b")
	var gudrun := _enemy(sim, "porridge_troll")
	var atk := gudrun.stat("attack")
	var alva := sim.unit("alva")
	alva.hp = alva.max_hp * 0.5
	sim._heal(alva, alva, 5.0, "healing_light")
	sim.drain_events()
	assert_true(gudrun.stat("attack") > atk, "Grytmodern blir mättare")


func test_envy_copies_a_hero_buff() -> void:
	var sim := _sim("troll_1c")
	var gunnar := _enemy(sim, "grumpy_troll")
	var buff := ""
	for id in _data.auras:
		if _data.auras[id].get("buff", false) and not _data.auras[id].get("cannot_dispel", false):
			buff = id
			break
	sim._add_aura(sim.unit("paladin"), sim.unit("brokk"), buff)
	assert_true(gunnar.auras.has(buff), "Avundsjätten fick samma buff (%s)" % buff)


func test_club_doubles_against_defending() -> void:
	var sim := _sim("troll_1c")
	var kalle := _enemy(sim, "club_troll")
	var brokk := sim.unit("brokk")
	var plain := sim.expected_damage(kalle, brokk, kalle.attack_ability) if sim.has_method("expected_damage") else 0.0
	sim._add_aura(brokk, brokk, "defend")
	var probe := {"source": kalle.id, "target": brokk.id, "kind": "attack", "direct": true}
	var mods := sim._modifiers(kalle, "modify_damage", probe)
	assert_true(mods.any(func(m: Dictionary) -> bool: return float(m.get("damage_mult", 1.0)) == 2.0), "Klubban mot den som Försvarar")


func test_brom_strikes_his_last_attacker_and_takes_a_charge() -> void:
	var sim := _sim("troll_e2")
	var brom := _enemy(sim, "bridge_troll")
	var eira := sim.unit("eira")
	sim._deal_damage(eira, brom, 1.0, "physical", eira.attack_ability, false, true, "attack", true)
	var targets := sim._pick_targets(brom, sim.ability("toll_strike"))
	assert_eq(targets, [eira.id], "Tullslaget går mot den som slog senast")
	var alva := sim.unit("alva")
	var total := 0
	for id in alva.charges:
		total += int(alva.charges[id])
	sim._drain_charge(alva)
	var after := 0
	for id in alva.charges:
		after += int(alva.charges[id])
	assert_eq(after, total - 1, "Brotull tar en Charge")


func test_lullaby_sleeps_only_those_who_cast() -> void:
	var sim := _sim("troll_e1")
	var mother := _enemy(sim, "troll_mother")
	var alva := sim.unit("alva")
	var brokk := sim.unit("brokk")
	alva.last_ability = "healing_light"
	brokk.last_ability = brokk.attack_ability
	sim._apply_effects(mother, "grey_lullaby", sim._pick_targets(mother, sim.ability("grey_lullaby")))
	assert_true(alva.auras.has("sleeping"), "den som kastade somnar")
	assert_true(not brokk.auras.has("sleeping"), "den som anföll är vaken")


func test_stone_heart_punishes_repeating_the_same_action() -> void:
	var sim := _sim("troll_3")
	var king := _enemy(sim, "mountain_king")
	var paladin := sim.unit("paladin")
	sim._note_team_action(paladin, "attack", paladin.attack_ability)
	sim._note_team_action(sim.unit("brokk"), "ability", "healing_light")
	var probe := {"source": paladin.id, "target": king.id, "kind": "attack"}
	assert_true(sim._modifiers(king, "modify_damage_taken", probe).is_empty(), "olika handlingar: full skada")
	sim._note_team_action(sim.unit("eira"), "ability", "volley")
	var mods := sim._modifiers(king, "modify_damage_taken", probe)
	assert_eq(mods.size(), 1, "samma sorts handling två gånger: Stenhjärta")
