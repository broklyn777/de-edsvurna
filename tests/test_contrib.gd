extends "res://tests/test_case.gd"
## Hjältebladets bidrag: vad varje hjälte gjorde under nedstigningen (CombatSim.contrib → RunState.contrib) och den
## förra nedstigningen (Profile.last_contrib).

var _data := GameData.load_all()


func _fight(seed_value: int) -> CombatSim:
	var sim := CombatSim.create(_data, "crypt_1", seed_value, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, 1,
			{"elite_chance": 0.0})
	sim.begin()
	var guard := 0
	var dealt := {}
	var healed := {}
	while sim.outcome == "" and guard < 300:
		guard += 1
		if sim.needs_input():
			sim.act("attack", sim.default_target(sim.current, "attack"), "")
		else:
			sim.ai_act()
		for e in sim.drain_events():
			var src := sim.unit(String(e.get("source", "")))
			if e.type == "damage" and src != null and src.team == 0 and sim.unit(String(e.target)).team != 0:
				dealt[src.id] = float(dealt.get(src.id, 0.0)) + float(e.amount)
			if e.type == "heal" and src != null and src.team == 0:
				healed[src.id] = float(healed.get(src.id, 0.0)) + float(e.effective)
	for id in dealt:
		assert_near(float(sim.contrib[id].damage), dealt[id], 0.01, "skada som händelserna, " + id)
	for id in healed:
		if healed[id] > 0.0:
			assert_near(float(sim.contrib[id].heal), healed[id], 0.01, "helning som händelserna, " + id)
	return sim


func test_battle_counts_what_each_hero_did() -> void:
	var sim := _fight(4)
	assert_true(not sim.contrib.is_empty())
	for id in sim.contrib:
		assert_true(sim.unit(id).team == 0, "bara hjältar")


func test_accumulates_across_two_battles() -> void:
	var state := RunState.new()
	var a := _fight(4)
	var b := _fight(5)
	state.add_contrib(a.contrib)
	state.add_contrib(b.contrib)
	var want := float(a.contrib.get("paladin", {}).get("damage", 0.0)) + float(b.contrib.get("paladin", {}).get("damage", 0.0))
	assert_true(want > 0.0)
	assert_near(float(state.contrib.paladin.damage), want, 0.01)
	state.add_contrib({"alva": {"heal": 10.0, "overheal": 2.0}})
	state.add_contrib({"alva": {"heal": 5.0}, "torun": {"interrupts": 1.0}})
	assert_near(float(state.contrib.alva.heal), 15.0 + float(a.contrib.get("alva", {}).get("heal", 0.0))
			+ float(b.contrib.get("alva", {}).get("heal", 0.0)), 0.01)
	assert_eq(int(state.contrib.torun.interrupts), 1)


func test_new_descent_starts_empty_and_save_round_trip() -> void:
	var p := Profile.new()
	var state := RunState.new_run(p, _data)
	assert_true(state.contrib.is_empty(), "ny nedstigning börjar tom")
	state.add_contrib({"brokk": {"damage": 1240.0, "shield": 210.0, "deaths": 1.0}})
	var path := "user://test_run_contrib.cfg"
	state.save(path)
	var back := RunState.load_from(path)
	RunState.delete_saved(path)
	assert_near(float(back.contrib.brokk.damage), 1240.0)
	assert_near(float(back.contrib.brokk.shield), 210.0)


func test_line_and_last_descent() -> void:
	assert_eq(RunState.contrib_line({}), "")
	var line := RunState.contrib_line({"damage": 1240.0, "heal": 340.0, "overheal": 60.0, "shield": 210.0,
			"interrupts": 3.0, "deaths": 1.0})
	assert_eq(line, "skada 1%s240 · helat 340 (överhelning 60) · skyddat 210 (Barriär) · avbröt 3 gånger · stupat 1" % char(160))
	assert_eq(RunState.contrib_line({"heal": 40.0}), "helat 40", "noll visas inte")
	# Slutet av nedstigningen (Run.end_descent): bidraget flyttas till profilen och körningens töms.
	var p := Profile.new()
	var state := RunState.new()
	state.add_contrib({"eira": {"damage": 500.0}})
	var rows := RunState.contrib_rows(state, p, "eira")
	assert_eq(rows.size(), 1)
	assert_eq(rows[0][0], "Denna nedstigning")
	state.finish_contrib(p)  # hjältebladets "Förra nedstigningen"
	rows = RunState.contrib_rows(state, p, "eira")
	assert_eq(rows.size(), 1)
	assert_eq(rows[0][0], "Förra nedstigningen")
	var path := "user://test_progress_contrib.cfg"
	p.save(path)
	var back := Profile.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_near(float(back.last_contrib.eira.damage), 500.0)
