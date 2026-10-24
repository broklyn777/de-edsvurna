extends "res://tests/test_case.gd"
## Bryt två av tre sigill (questen "seals"): placeringen, att två brutna öppnar målet, att det kvarlämnade sigillets
## fördel når slutstriden och att allt sparas.


func _run(data: Dictionary, seed_value: int, realm := "crypt") -> RunState:
	RunState.dev_quest = "seals"
	var s := RunState.new()
	s.set_realm(data, realm)
	s.fill_charges(data)
	s.start_expedition(data, seed_value)
	RunState.dev_quest = ""
	return s


## Står på sigillet med besegrad vakt och bryter det (som efter en vunnen strid).
func _break(s: RunState, cell: int) -> bool:
	s.pos = cell
	s.map.cells[cell].beaten = true
	return s.break_seal()


func test_three_seals_follow_the_placement_rules() -> void:
	var data := GameData.load_all()
	for realm in ["crypt", "chapel"]:
		for seed_value in range(1, 25):
			var s := _run(data, seed_value, realm)
			assert_eq(s.quest.type, "seals")
			assert_eq(s.map.problems(s.quest), [] as Array[String], "%s frö %d" % [realm, seed_value])
			var seals := s.seals()
			assert_eq(seals.size(), 3)
			var kinds := {}
			for x in seals:
				kinds[x.seal] = true
				assert_true(s.map.cell(x.cell).has("encounter"), "varje sigill har en vakt")
				assert_true(not s.map.cell(x.cell).get("elite", false), "vakterna är lika starka, ingen elit")
			assert_eq(kinds.size(), 3, "tre olika fördelar")
			assert_eq(s.quest_hints.size(), 3, "ett rykte per sigill")


func test_first_descent_never_rolls_seals() -> void:
	var data := GameData.load_all()
	for seed_value in range(1, 60):
		var s := RunState.new()
		s.set_realm(data, "crypt")
		s.first_descent = true
		s.fill_charges(data)
		s.start_expedition(data, seed_value)
		assert_true(s.quest.type != "seals", "frö %d" % seed_value)
	var seen := false
	for seed_value in range(1, 60):
		var t := RunState.new()
		t.set_realm(data, "crypt")
		t.fill_charges(data)
		t.start_expedition(data, seed_value)
		assert_true(t.quest.type != "seals", "aldrig på den första våningen (frö %d)" % seed_value)
		t.quest.done = true
		t.next_floor(data)
		seen = seen or t.quest.type == "seals"
	assert_true(seen, "sigillen rullas på den sista våningen")


func test_breaking_two_opens_the_exit_and_the_third_holds() -> void:
	var data := GameData.load_all()
	var s := _run(data, 4)
	var seals := s.seals()
	assert_true(s.goal_locked())
	assert_eq(RunState.quest_text(s.quest), "Bryt två av tre sigill (0/2)")
	assert_true(not (_break(s, seals[0].cell)))
	assert_true(s.goal_locked(), "ett brutet sigill räcker inte")
	assert_eq(RunState.quest_text(s.quest), "Bryt två av tre sigill (1/2)")
	assert_true(_break(s, seals[1].cell), "det andra brutna klarar questen")
	assert_true(not (s.goal_locked()))
	assert_true(s.map.cell(seals[2].cell).get("held", false))
	assert_true(s.revealed.has(seals[2].cell) or s.visited.has(seals[2].cell), "det som håller syns på kartan")
	assert_eq(s.boss_seals, [RunState.SEAL_TRAITS[seals[2].seal]])
	assert_true(not _break(s, seals[2].cell), "det tredje går inte att bryta")
	assert_true(not (s.map.cell(seals[2].cell).get("broken", false)))
	assert_eq(s.boss_seals.size(), 1)
	assert_eq(s.active_hints(), [], "ryktena försvinner när questen är klar")


func test_a_seal_is_not_broken_while_its_guard_stands() -> void:
	var data := GameData.load_all()
	var s := _run(data, 6)
	s.pos = s.seals()[0].cell
	assert_true(not (s.break_seal()))
	assert_eq(int(s.quest.progress), 0)


func test_the_remaining_seal_reaches_the_end_fight() -> void:
	var data := GameData.load_all()
	var s := _run(data, 9)
	var seals := s.seals()
	_break(s, seals[0].cell)
	_break(s, seals[1].cell)
	var left: String = RunState.SEAL_TRAITS[seals[2].seal]
	# Vanliga strider får ingenting; slutstriden på den sista våningen får sigillets egenskap.
	s.pos = seals[2].cell
	assert_true(not (s.battle_opts().has("boss_traits")))
	s.floor = RunState.FLOORS_PER_RUN - 1
	s.start_floor(data)
	s.pos = s.map.goal
	var opts := s.battle_opts()
	assert_eq(opts.get("boss_traits", []), [left])
	var sim := CombatSim.create(data, s.encounter(), 3, Array(s.party), {}, {}, {}, s.depth, opts)
	var bearer: CombatUnit = null
	for e in sim.enemies:
		if e.traits.has(left):
			bearer = e
	assert_true(bearer != null, "bossen bär sigillets egenskap")
	if bearer != null and sim.enemies.any(func(e: CombatUnit) -> bool: return data.enemies[e.kind].get("boss", false)):
		assert_true(data.enemies[bearer.kind].get("boss", false), "bossen, inte följet")


func test_each_seal_does_what_it_says() -> void:
	var data := GameData.load_all()
	var enc: String = data.realms.crypt.floors[data.realms.crypt.floors.size() - 1]
	var party := ["paladin", "brokk", "alva", "eira"]
	# Murens sigill: Barriär för 20 % av livet när striden börjar.
	var sim := CombatSim.create(data, enc, 5, party, {}, {}, {}, 1, {"boss_traits": ["seal_ward"]})
	sim.begin()
	var boss := _bearer(sim, "seal_ward")
	assert_true(boss != null and boss.barrier > 0.0, "Barriär")
	if boss != null:
		assert_true(absf(boss.barrier - boss.max_hp * 0.2) < 1.5, "20 % av livet")
	# Vaksamhetens sigill: bossen står först på tidslinjen och är Smidig.
	sim = CombatSim.create(data, enc, 5, party, {}, {}, {}, 1, {"boss_traits": ["seal_haste"]})
	var first_id := ""
	sim.begin()
	boss = _bearer(sim, "seal_haste")
	assert_true(boss != null)
	if boss != null:
		first_id = sim.current.id if sim.current != null else ""
		assert_eq(first_id, boss.id, "bossen agerar först")
		assert_true(boss.auras.has("agile"), "Smidig")


func _bearer(sim: CombatSim, trait_id: String) -> CombatUnit:
	for e in sim.enemies:
		if e.traits.has(trait_id):
			return e
	return null


func test_seals_survive_save_and_load() -> void:
	var data := GameData.load_all()
	var s := _run(data, 11)
	var seals := s.seals()
	_break(s, seals[0].cell)
	var t := RunState.from_dict(s.to_dict())
	assert_eq(t.quest.type, "seals")
	assert_eq(int(t.quest.progress), 1)
	assert_true(t.map.cell(seals[0].cell).get("broken", false))
	assert_eq(t.seals().size(), 3)
	_break(t, seals[1].cell)
	var u := RunState.from_dict(t.to_dict())
	assert_eq(u.boss_seals, [RunState.SEAL_TRAITS[seals[2].seal]])
	assert_true(not (u.goal_locked()))
	var path := "user://test_seals_run.cfg"
	u.save(path)
	var v := RunState.load_from(path)
	RunState.delete_saved(path)
	assert_eq(v.boss_seals, u.boss_seals)
	assert_true(v.map.cell(seals[2].cell).get("held", false))


func test_guardians_get_the_milder_wall_and_haste_strikes_harder() -> void:
	var data := GameData.load_all()
	var s := _run(data, 2)
	s.boss_seals = [RunState.SEAL_TRAITS.ward]
	assert_eq(s.end_fight_seals({"boss": true}), ["seal_ward"])
	s.map.cells[s.map.goal] = {"kind": "end", "encounter": "crypt_g2", "boss": true, "guardian": true}
	assert_eq(s.end_fight_seals(s.map.cell(s.map.goal)), [RunState.GUARDIAN_WARD])
	var enc: String = data.realms.crypt.floors[data.realms.crypt.floors.size() - 1]
	var sim := CombatSim.create(data, enc, 5, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, 1, {"boss_traits": ["seal_haste"]})
	sim.begin()
	var boss := _bearer(sim, "seal_haste")
	assert_true(boss != null and boss.auras.has("seal_strike"), "första anfallet +50 %")
