extends "res://tests/test_case.gd"
## Löften per nedstigning (0.30.17, docs/plan/loften.md).

var _data := GameData.load_all()


func _state(vow: String) -> RunState:
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.party.assign(["paladin", "brokk", "alva"])
	s.fill_charges(_data)
	s.set_vow(_data, vow)
	return s


func test_every_vow_has_its_traits() -> void:
	for id in _data.vows:
		if id.begins_with("_"):
			continue
		var v: Dictionary = _data.vows[id]
		assert_true(v.has("name") and v.has("text"), "%s har namn och text" % id)
		for key in ["held", "humble"]:
			if v.has(key):
				assert_true(_data.traits.has(v[key]), "%s: %s finns i traits.json" % [id, v[key]])


func test_held_trait_goes_to_the_paladin() -> void:
	var s := _state("vow_no_fall")
	assert_true(s.hero_traits(_data).paladin.has("vow_no_fall_held"))
	assert_true(not s.hero_traits(_data).brokk.has("vow_no_fall_held"))


func test_a_fall_breaks_the_vow_and_the_humble_form_is_used_once() -> void:
	var s := _state("vow_no_fall")
	var sim := CombatSim.create(_data, "crypt_1", 3, s.party, s.hero_traits(_data))
	sim.unit("brokk").deaths = 1
	assert_eq(s.vow_after_battle(_data, sim), "broke")
	assert_true(not s.vow_kept(_data))
	assert_eq(s.vow_name(_data), "Den som föll reser sig")
	assert_eq(s.vow_trait(_data), "vow_no_fall_humble")
	var sim2 := CombatSim.create(_data, "crypt_1", 4, s.party, s.hero_traits(_data))
	sim2.trait_stats["vow_no_fall_humble"] = {"unit": "paladin", "procs": 1, "damage": 0.0, "heal": 0.0}
	s.vow_after_battle(_data, sim2)
	assert_eq(s.vow_trait(_data), "", "den ödmjuka formen gäller en gång per körning")


func test_no_heal_blocks_healing_abilities_but_not_attacks() -> void:
	var s := _state("vow_no_heal")
	var opts := {}
	s.apply_vow(_data, opts)
	var sim := CombatSim.create(_data, "crypt_1", 3, s.party, s.hero_traits(_data), {}, {}, 1, opts)
	var alva := sim.unit("alva")
	assert_eq(sim.can_act(alva, "ability", "healing_light"), "vowed")
	assert_eq(sim.can_act(alva, "ability", "judgement"), "")
	assert_eq(sim.can_act(alva, "attack"), "")
	assert_true(s.hero_traits(_data).paladin.has("vow_no_heal_held"))


func test_straight_breaks_on_the_third_common_group() -> void:
	var s := _state("vow_straight")
	assert_true(RunState.is_common_group({"kind": "battle"}))
	assert_true(not RunState.is_common_group({"kind": "battle", "elite": true}))
	assert_true(not RunState.is_common_group({"kind": "item"}))
	s.commons_fought = 2
	assert_true(s.vow_kept(_data))
	s.commons_fought += 1  # som RunState.fight() på en tredje vanlig grupp
	if s.commons_fought > s.vow_max_commons:
		s.vow_broken = true
	assert_true(not s.vow_kept(_data))
	assert_eq(s.vow_name(_data), "Omvägen")


func test_kept_vow_adds_silver() -> void:
	var s := _state("vow_no_heal")
	assert_near(s.silver_mult(_data), 1.0 + float(_data.vows.vow_no_heal.silver))
	s.vow_broken = true
	assert_near(s.silver_mult(_data), 1.0)


func test_vow_survives_save_and_load() -> void:
	var s := _state("vow_no_fall")
	s.vow_broken = true
	s.commons_fought = 1
	var t := RunState.from_dict(s.to_dict())
	assert_eq(t.vow, "vow_no_fall")
	assert_true(t.vow_broken)
	assert_eq(t.commons_fought, 1)
	assert_eq(t.vow_breaks_on, "death")
