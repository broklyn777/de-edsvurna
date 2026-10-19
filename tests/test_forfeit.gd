extends "res://tests/test_case.gd"
## 0.20.1: att ge upp (Siralims Forfeit). Striden blir en förlust, den sparade körningen tas bort så att
## Realmen börjar om från våning 1, och det som redan är vunnet finns kvar i profilen.

var _data := GameData.load_all()


func test_forfeit_is_a_defeat() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 3)
	sim.begin()
	sim.drain_events()
	sim.forfeit()
	assert_eq(sim.outcome, "defeat")
	assert_true(sim.forfeited)
	var events := sim.drain_events()
	assert_true(events.any(func(e: Dictionary) -> bool: return e.type == "outcome" and e.get("forfeit", false)))
	sim.forfeit()
	assert_eq(sim.drain_events().size(), 0, "bara en gång")


func test_forfeit_clears_the_saved_run_and_keeps_what_was_won() -> void:
	var run_path := "user://test_run_forfeit.cfg"
	var prof_path := "user://test_progress_forfeit.cfg"
	var p := Profile.new()
	var state := RunState.new()
	state.set_realm(_data, "crypt")
	state.fill_charges(_data)
	state.start_expedition(_data, 7)
	state.floor = 2
	state.quest.done = true
	state.save(run_path)
	assert_true(RunState.load_from(run_path) != null)
	# Det som vunnits under körningen ligger redan i profilen.
	p.silver = 333
	p.grant_xp(_data, ["brokk"], 60)
	p.add_finds([{"kind": "amber", "id": "amber_red", "count": 4}])
	p.add_trophy("bone_finger")
	p.save(prof_path)
	var quests := p.quests_done.size()
	RunState.delete_saved(run_path)
	assert_true(not FileAccess.file_exists(run_path), "run.cfg är borta")
	assert_eq(RunState.load_from(run_path), null, "nästa körning börjar om från våning 1")
	var q := Profile.load_from(prof_path)
	assert_eq(q.silver, 333)
	assert_eq(int(q.hero(_data, "brokk").level), int(p.hero(_data, "brokk").level))
	assert_true(int(q.hero(_data, "brokk").level) > 1, "erfarenheten finns kvar")
	assert_eq(q.materials.amber_red, 4)
	assert_true(q.collection.has("bone_finger"))
	assert_eq(q.quests_done.size(), quests, "questens belöning ges inte")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(prof_path))
