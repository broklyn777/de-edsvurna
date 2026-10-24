extends "res://tests/test_case.gd"
## 0.14: Realm Depth, våningarnas skalning, Resistant och fiendernas egenskaper.

var _data := GameData.load_all()


func _sim(encounter := "crypt_1", depth := 1) -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 7, [], {}, {}, {}, depth)
	sim.begin()
	sim.drain_events()
	return sim


## En direkt attack (power 1) utan krit från src mot tgt, med samma slumpfrö varje gång.
func _hit(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, kind := "attack") -> float:
	sim.rng.seed = 3
	var before := tgt.hp
	sim._deal_damage(src, tgt, 1.0, "physical", src.attack_ability, false, true, kind, true)
	return before - tgt.hp


func test_depth_scales_enemy_stats_but_not_speed() -> void:
	var d: Dictionary = _data.enemies.skeleton_warrior.stats
	var deep := _sim("crypt_1", 3).unit("skeleton_warrior_1")
	assert_near(CombatSim.depth_mult(3), 1.06)
	assert_eq(deep.max_hp, CombatSim.snap_stat(d.health * CombatSim.depth_mult(3)), "Health")
	assert_eq(deep.attack, CombatSim.snap_stat(d.attack * CombatSim.depth_mult(3)), "Attack")
	assert_eq(deep.defense, CombatSim.snap_stat(d.defense * CombatSim.depth_mult(3)), "Defense")
	assert_eq(deep.speed, float(d.speed), "Speed skalar inte")
	assert_eq(deep.base_stats.attack, deep.attack, "startvärdet följer med (golvet 20 %)")
	var shallow := _sim("crypt_1", 1).unit("skeleton_warrior_1")
	assert_eq(shallow.max_hp, float(d.health), "djup 1 är oskalat")
	assert_eq(_sim("crypt_1", 3).unit("brokk").max_hp, float(_data.heroes.brokk.stats.health), "hjältarna skalar inte")


func test_later_floors_are_stronger() -> void:
	assert_true(float(_data.encounters.crypt_2.stat_mult) > 1.0)
	# elit-balans: bossmötet är svagare än våning 2:s möte (bossen avgör körningen); bara starkare än våning 1.
	assert_true(float(_data.encounters.crypt_3.stat_mult) > float(_data.encounters.crypt_1.stat_mult))
	var warden := _sim("crypt_2").unit("grave_warden_1")
	assert_eq(warden.max_hp, CombatSim.snap_stat(_data.enemies.grave_warden.stats.health * float(_data.encounters.crypt_2.stat_mult)))


func test_profile_unlocks_depth_after_clearing() -> void:
	var p := Profile.new()
	assert_eq(p.max_depth(), 1)
	p.choose_depth(3)
	assert_eq(p.depth, 1, "djup 2 är låst innan djup 1 är klarat")
	p.clear_depth(1)
	p.choose_depth(3)
	assert_eq(p.depth, 2, "bara ett djup längre än det djupaste klarade")
	p.clear_depth(1)
	assert_eq(p.best_depth, 1, "ett grundare djup sänker inte rekordet")
	var path := "user://test_progress_depth.cfg"
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.best_depth, 1)
	assert_eq(q.depth, 2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_silver_and_trophy_chance_grow_with_depth() -> void:
	assert_eq(Profile.reward(2, 1), Profile.FLOOR_REWARD[2])
	assert_eq(Profile.reward(2, 3), roundi(Profile.FLOOR_REWARD[2] * 1.5))
	assert_near(RunState.trophy_chance(1), RunState.TROPHY_CHANCE)
	assert_true(RunState.trophy_chance(3) > RunState.trophy_chance(1))
	assert_near(RunState.trophy_chance(10), 1.0)
	var s := RunState.new()
	var rng := RandomNumberGenerator.new()
	for seed_value in 20:
		rng.seed = seed_value
		assert_true(not s.trophy_offer(_data, rng).is_empty(), "minst en trofé efter en seger")
	s.depth = 10
	assert_eq(s.trophy_offer(_data, rng).size(), RunState.OFFER_SIZE, "djupt nog: alla platser")


func test_boss_is_resistant_to_debuffs() -> void:
	# 0.22, som originalet: bara statusar med en Resistant-version påverkas; Märkt och Brinner verkar fullt.
	var sim := _sim("crypt_3")
	var lich := sim.unit("bone_lich_1")
	assert_true(lich.resistant)
	sim._add_aura(sim.unit("eira"), lich, "marked")
	assert_near(lich.auras.marked.damage_taken_mult, 1.2, 0.001, "Märkt verkar fullt")
	sim._add_aura(sim.unit("alva"), lich, "burning")
	assert_near(lich.auras.burning.dot, sim.unit("alva").intelligence * 0.3, 1e-9, "Brinner verkar fullt")
	sim = _sim("crypt_3")
	lich = sim.unit("bone_lich_1")
	lich.hp = 100.0
	sim._add_aura(sim.unit("eira"), lich, "bleeding")
	sim.drain_events()
	sim._tick_turn_start(lich)
	var bled := 0.0
	for e in sim.drain_events():
		if e.type == "damage" and e.ability == "bleeding":
			bled = e.amount
	assert_eq(bled, 10.0, "Blöder: resistent tar 10 % av livet i stället för 30 %")


func test_every_enemy_has_a_trait() -> void:
	for kind in _data.enemies:
		var list: Array = _data.enemies[kind].get("traits", [])
		assert_true(not list.is_empty(), "%s har en egenskap" % kind)
		for trait_id in list:
			assert_true(_data.traits[trait_id].get("text", "") != "", "%s har en text" % trait_id)


func test_bone_armor_reduces_attacks_not_spells() -> void:
	var sim := _sim()
	var w := sim.unit("skeleton_warrior_1")
	var paladin := sim.unit("paladin")
	var armored := _hit(sim, paladin, w)
	var armored_spell := _hit(sim, paladin, w, "spell")
	w.traits.erase("bone_armor")
	w.hp = w.max_hp
	assert_near(armored, roundf(_hit(sim, paladin, w) * 0.7), 1.0, "attacker −30 %")
	assert_eq(armored_spell, _hit(sim, paladin, w, "spell"), "besvärjelser biter fullt")


func test_grave_pact_grows_per_fallen_ally() -> void:
	var sim := _sim()
	var priest := sim.unit("grave_priest_1")
	var brokk := sim.unit("brokk")
	var base := _hit(sim, priest, brokk)
	brokk.hp = brokk.max_hp
	sim._kill(sim.unit("skeleton_warrior_1"))
	sim._kill(sim.unit("skeleton_warrior_2"))
	var after := _hit(sim, priest, brokk)
	var pct: float = _data.traits.grave_pact.modify.damage_mult_per_dead_ally
	assert_near(after, roundf(base * (1.0 + 2.0 * pct)), 2.0, "två fallna allierade")


func test_warden_thorns_only_while_provoking() -> void:
	var sim := _sim("crypt_2")
	var warden := sim.unit("grave_warden_1")
	var paladin := sim.unit("paladin")
	var hp := paladin.hp
	_hit(sim, paladin, warden)
	assert_eq(paladin.hp, hp, "inga törnen utan Provocera")
	sim._add_aura(warden, warden, "provoke")
	var dealt := _hit(sim, paladin, warden)
	assert_true(paladin.hp < hp, "törnen när Gravväktaren provocerar")
	assert_true(hp - paladin.hp <= ceilf(dealt * 0.4), "högst 40 % tillbaka")
	hp = paladin.hp
	_hit(sim, paladin, warden, "spell")
	assert_eq(paladin.hp, hp, "besvärjelser slipper törnen")


func test_ember_skeleton_sets_burning_from_intelligence() -> void:
	var sim := _sim("crypt_2")
	var ember := sim.unit("ember_skeleton_1")
	var brokk := sim.unit("brokk")
	_hit(sim, ember, brokk)
	assert_true(brokk.auras.has("burning"))
	assert_near(brokk.auras.burning.dot, ember.intelligence * 0.3, 1e-9)


func test_lich_wrath_triggers_once_below_half() -> void:
	var sim := _sim("crypt_3")
	var lich := sim.unit("bone_lich_1")
	var paladin := sim.unit("paladin")
	_hit(sim, paladin, lich)
	assert_true(not lich.auras.has("lich_wrath"), "inte över 50 %")
	lich.hp = lich.max_hp * 0.52
	sim.drain_events()
	_hit(sim, paladin, lich)
	assert_true(lich.auras.has("lich_wrath"), "vredgas under 50 %")
	var storms := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "action" and e.ability == "bone_storm")
	assert_eq(storms.size(), 1, "Benstorm direkt")
	_hit(sim, paladin, lich)
	var again := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type == "trait" and e.trait == "lich_undying_wrath")
	assert_eq(again.size(), 0, "bara en gång per strid")
