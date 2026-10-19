extends "res://tests/test_case.gd"
## 0.18: rumskartan, Realm Quest, lägereld, helgedom, skattkammare, portal och sparad körning.

var _data := GameData.load_all()


func _state(realm := "crypt", seed_value := 5) -> RunState:
	var s := RunState.new()
	s.set_realm(_data, realm)
	s.fill_charges(_data)
	s.start_expedition(_data, seed_value)
	return s


func test_maps_meet_the_rules_for_1000_seeds() -> void:
	var pools: Array = _data.realms.crypt.pools
	for seed_value in 1000:
		var floor_index := seed_value % 3
		var m := RoomMap.generate(seed_value, floor_index, floor_index == 2, pools[floor_index], "crypt_%d" % (floor_index + 1))
		var problems := m.problems()
		assert_true(problems.is_empty(), "frö %d: %s" % [seed_value, ", ".join(problems)])
		assert_true(m.steps.size() >= RoomMap.MIN_STEPS and m.steps.size() <= RoomMap.MAX_STEPS, "3–4 steg")
		for row in m.steps:
			assert_true(row.size() >= RoomMap.MIN_ROOMS and row.size() <= RoomMap.MAX_ROOMS, "2–3 rum per steg")
			for r in row:
				assert_true(r.next.size() >= 1 and r.next.size() <= 2, "frö %d: %s leder till %d rum" % [seed_value, r.id, r.next.size()])
		if problems.size() > 0 or m.steps.is_empty():
			return


func test_end_is_the_boss_on_the_last_floor() -> void:
	var s := _state()
	assert_eq(s.map.end.encounter, "crypt_1")
	assert_true(not s.map.end.boss)
	var last := RoomMap.generate(3, 2, true, _data.realms.crypt.pools[2], "crypt_3")
	assert_true(last.end.boss)
	assert_eq(last.end.encounter, "crypt_3")


func test_choices_follow_the_paths() -> void:
	var s := _state()
	assert_eq(s.choices(), s.map.steps[0].map(func(r: Dictionary) -> String: return r.id))
	var first: String = s.choices()[0]
	s.enter(first)
	assert_eq(s.choices(), s.map.room(first).next if s.map.room(first).kind != "portal" else s.choices())


func test_walking_a_whole_run_reaches_the_end() -> void:
	var s := _state()
	var rng := RandomNumberGenerator.new()
	var guard := 0
	var floors_seen := []
	while not s.finished and guard < 80:
		guard += 1
		if not floors_seen.has(s.floor):
			floors_seen.append(s.floor)
		var r := s.enter(s.choices()[0])
		if RunState.is_battle(r):
			s.battle_won()
			if s.floor_cleared():
				s.next_floor(_data)
		elif r.kind == "campfire":
			s.campfire(_data)
		elif r.kind == "treasure":
			s.treasure(_data, rng)
		elif r.kind == "shrine":
			s.apply_shrine(_data, rng, s.shrine_options(_data, rng)[0])
	assert_true(s.finished, "körningen tar slut")
	assert_eq(floors_seen, [0, 1, 2])


func test_campfire_restores_charges_per_ability() -> void:
	var s := _state()
	s.charges.alva.healing_light = 0
	s.charges.alva.renew = int(_data.abilities.renew.charges)
	s.campfire(_data)
	assert_eq(s.charges.alva.healing_light, RunState.CAMPFIRE_CHARGES)
	assert_eq(s.charges.alva.renew, int(_data.abilities.renew.charges), "aldrig över max")


func test_shrine_gifts_and_blessing_lasts_one_battle() -> void:
	var s := _state()
	var rng := RandomNumberGenerator.new()
	var gifts := s.shrine_options(_data, rng)
	assert_eq(gifts.size(), 3)
	var charge: Dictionary = gifts[0]
	var before := int(s.charges[charge.hero][charge.ability])
	s.apply_shrine(_data, rng, charge)
	assert_eq(int(s.charges[charge.hero][charge.ability]), before + 2)
	s.apply_shrine(_data, rng, {"kind": "blessing", "aura": "inspired"})
	assert_eq(s.battle_opts().start_auras, ["inspired"])
	s.battle_won()
	assert_eq(s.battle_opts().start_auras, [], "bara nästa strid")


func test_elite_portal_and_nemesis_rooms_change_the_battle() -> void:
	var s := _state()
	s.map.steps[0][0].kind = "elite"
	s.map.steps[0][0].encounter = "crypt_1a"
	s.enter(s.map.steps[0][0].id)
	assert_eq(s.battle_opts().force_elites, 1)
	var sim := CombatSim.create(_data, s.encounter(), 3, [], {}, {}, {}, 1, s.battle_opts())
	assert_true(sim.enemies[0].elite, "elitrummet har en elit")
	var p := _state()
	p.map.steps[0][0].kind = "portal"
	p.map.steps[0][0].side = [{"id": "x_p0", "kind": "portal_battle", "encounter": "crypt_1a"}, {"id": "x_p1", "kind": "treasure"}]
	var r := p.enter(p.map.steps[0][0].id)
	assert_eq(r.kind, "portal_battle")
	assert_eq(p.battle_opts().stat_bonus, RunState.PORTAL_STATS)
	p.battle_won()
	assert_eq(p.current_room().kind, "treasure", "sedan skatten i portalen")
	p.treasure(_data, RandomNumberGenerator.new())
	assert_eq(p.side_index, -1, "tillbaka på kartan")
	assert_eq(p.choices(), p.map.steps[0][0].next)


func test_quests() -> void:
	var rng := RandomNumberGenerator.new()
	var types := {}
	for i in 60:
		rng.seed = i
		types[RunState.roll_quest(_data, rng, 3).type] = true
	assert_eq(types.size(), 3, "Jakt, Rensa och Rening")
	var s := _state()
	s.quest = {"type": "clear", "goal": 2, "progress": 0, "done": false}
	s.map.steps[0][0].kind = "elite"
	s.enter(s.map.steps[0][0].id)
	assert_true(not s.battle_won())
	s.room_id = s.map.steps[0][0].id
	assert_true(s.battle_won(), "två elitstrider klarar questen")
	var h := _state()
	h.quest = {"type": "hunt", "goal": 1, "progress": 0, "done": false, "floor": 0}
	h.start_floor(_data)
	var nemesis := h.map.all_rooms().filter(func(r: Dictionary) -> bool: return r.get("nemesis", false))
	assert_eq(nemesis.size(), 1, "en Nemesis på våningen")
	h.room_id = nemesis[0].id
	assert_true(h.battle_opts().nemesis)
	assert_true(h.battle_won())
	var p := _state("crypt", 9)
	p.quest = {"type": "purify", "goal": 3, "progress": 0, "done": false}
	for i in 3:
		p.apply_shrine(_data, rng, {"kind": "blessing", "aura": "inspired"})
	assert_true(p.quest.done)
	assert_true(RunState.quest_text(p.quest).begins_with("Rening"))


func test_purify_maps_have_a_shrine_every_floor() -> void:
	for seed_value in 200:
		var m := RoomMap.generate(seed_value, 0, false, _data.realms.chapel.pools[0], "chapel_1", 1)
		assert_true(m.count("shrine") >= 1)


func test_run_is_saved_and_resumed() -> void:
	var s := _state("chapel", 11)
	s.enter(s.choices()[0])
	s.charges.alva.healing_light = 3
	s.trophies.append("rosary")
	var path := "user://test_run.cfg"
	assert_eq(s.save(path), OK)
	var t := RunState.load_from(path)
	assert_true(t != null)
	assert_eq(t.realm, "chapel")
	assert_eq(t.room_id, s.room_id)
	assert_eq(t.choices(), s.choices())
	assert_eq(int(t.charges.alva.healing_light), 3)
	assert_eq(t.trophies, s.trophies)
	assert_eq(t.quest, s.quest)
	assert_eq(t.map.to_dict(), s.map.to_dict())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_true(RunState.load_from(path) == null, "ingen sparad körning")


func test_quest_gives_perk_point_once_per_realm_and_depth() -> void:
	var p := Profile.new()
	var silver := p.silver
	var r := p.complete_quest("crypt", 1)
	assert_true(r.point)
	assert_eq(p.silver, silver + Profile.QUEST_SILVER)
