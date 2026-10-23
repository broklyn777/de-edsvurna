extends "res://tests/test_case.gd"
## Speltidsmätningen (Playtime): räkningen per strid, våning och körning, pausen, snitten, filen och gränserna 200/50.

var TMP := "user://test_playtime_%d.cfg" % OS.get_process_id()


func _fresh() -> Playtime:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	var p := Playtime.load_from(TMP)
	return p


func test_counts_battle_floor_and_run() -> void:
	var p := _fresh()
	p.tick(5.0)
	assert_true(not p.active(), "ingen körning: klockan står still")
	p.start_run(1, "crypt", 2)
	p.tick(10.0)
	p.start_battle("elite")
	p.tick(30.0)
	p.end_battle(true, 17)
	assert_eq(p.battles.size(), 1)
	assert_near(float(p.battles[0].sec), 30.0, 0.01, "striden")
	assert_eq(p.battles[0].kind, "elite")
	assert_eq(p.battles[0].turns, 17)
	assert_eq(p.battles[0].depth, 2)
	assert_eq(p.battles[0].floor, 0)
	p.next_floor()
	p.start_battle("boss")
	p.tick(20.0)
	p.end_battle(false, 40, true)
	assert_true(p.last_forfeit, "GE UPP märks")
	assert_eq(p.battles[1].floor, 1)
	p.finish_run("forfeit")
	assert_true(not p.active())
	assert_eq(p.runs.size(), 1)
	var r: Dictionary = p.runs[0]
	assert_near(float(r.sec), 60.0, 0.01, "körningen")
	assert_near(float(r.floors[0]), 40.0, 0.01, "våning 1")
	assert_near(float(r.floors[1]), 20.0, 0.01, "våning 2")
	assert_eq(r.battles, 2)
	assert_eq(r.outcome, "forfeit")
	assert_eq(r.realm, "crypt")
	assert_true(p.current.is_empty(), "den pågående körningen är borta")


func test_paused_clock_does_not_count() -> void:
	# Pausen ligger hos Run (ingen tick när trädet är pausat, appen i bakgrunden eller en ruta öppen); här: ingen
	# tick utan körning, ingen strid utan körning och inga negativa steg.
	var p := _fresh()
	p.start_battle("normal")
	assert_true(p.battle.is_empty(), "ingen strid utan körning (Övningsgården)")
	p.end_battle(true, 3)
	assert_eq(p.battles.size(), 0)
	p.start_run(2, "chapel", 1)
	p.tick(-3.0)
	p.tick(4.0)
	p.suspend()
	p.tick(100.0)
	assert_true(p.resume_run(2))
	p.tick(1.0)
	assert_near(float(p.current["2"].sec), 5.0, 0.01, "bara aktiv tid")


func test_averages_and_lines() -> void:
	var p := _fresh()
	p.start_run(1, "crypt", 1)
	for s in [60.0, 120.0]:
		p.start_battle("normal")
		p.tick(s)
		p.end_battle(true, 10)
	p.start_battle("boss")
	p.tick(300.0)
	p.end_battle(true, 30)
	p.finish_run("boss")
	var a := p.averages()
	assert_near(float(a.battle[0]), 160.0, 0.01, "snitt per strid")
	assert_eq(a.battle[1], 3)
	assert_near(float(a.kinds.normal[0]), 90.0, 0.01, "snitt vanlig")
	assert_eq(a.kinds.elite[1], 0)
	assert_near(float(a.run[0]), 480.0, 0.01, "snitt körning")
	var lines := p.summary_lines()
	assert_eq(lines[0], "Strid: snitt 2,7 min (3 st)  ·  Körning: snitt 8 min (1 st)")
	assert_eq(lines[1], "Vanlig 1,5 min  ·  Boss 5,0 min")
	assert_eq(Playtime.new().summary_lines()[0], "Strid: snitt – (0 st)  ·  Körning: snitt – (0 st)")


func test_saves_and_loads_and_resumes() -> void:
	var p := _fresh()
	p.start_run(3, "crypt", 1)
	p.tick(42.0)
	p.next_floor()
	p.tick(8.0)
	p.start_battle("nemesis")
	p.tick(5.0)
	p.end_battle(true, 9)
	p.save()
	var q := Playtime.load_from(TMP)
	assert_eq(q.battles.size(), 1)
	assert_true(not q.active(), "en laddad körning räknar först när den återupptas")
	assert_true(q.resume_run(3, 1))
	q.tick(5.0)
	assert_near(float(q.current["3"].sec), 60.0, 0.01, "fortsätter där den slutade")
	q.finish_run("home")
	assert_eq(q.runs[0].floors.size(), 2)
	assert_eq(q.runs[0].battles, 1)
	assert_true(not Playtime.load_from(TMP).resume_run(3), "avslutad körning återupptas inte")
	assert_true(not q.resume_run(1), "ingen körning på plats 1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_limits_and_reset() -> void:
	var p := _fresh()
	p.start_run(1, "crypt", 1)
	for i in Playtime.MAX_BATTLES + 25:
		p.start_battle("normal")
		p.tick(float(i))
		p.end_battle(true, 5)
	assert_eq(p.battles.size(), Playtime.MAX_BATTLES, "högst 200 strider")
	assert_near(float(p.battles[0].sec), 25.0, 0.01, "de äldsta försvinner först")
	for i in Playtime.MAX_RUNS + 7:
		p.start_run(1, "crypt", 1)
		p.tick(1.0)
		p.finish_run("loss")
	assert_eq(p.runs.size(), Playtime.MAX_RUNS, "högst 50 körningar")
	assert_eq(Playtime.load_from(TMP).runs.size(), Playtime.MAX_RUNS, "gränsen håller i filen")
	p.start_run(2, "crypt", 1)
	p.tick(9.0)
	p.reset()
	assert_eq(p.battles.size() + p.runs.size(), 0)
	assert_near(float(p.current["2"].sec), 0.0, 0.01, "den pågående körningen börjar om från noll")
	assert_true(p.active())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_demo_never_saves() -> void:
	var p := Playtime.make_demo()
	p.path = TMP
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	p.save()
	assert_true(not FileAccess.file_exists(TMP), "demon sparar inte")
	assert_true(p.averages().battle[1] > 0)


func test_battle_kind() -> void:
	assert_eq(Playtime.battle_kind({"kind": "battle"}, false), "normal")
	assert_eq(Playtime.battle_kind({"kind": "battle", "elite": true}, false), "elite")
	assert_eq(Playtime.battle_kind({"kind": "battle", "nemesis": true}, false), "nemesis")
	assert_eq(Playtime.battle_kind({"kind": "end"}, true), "boss")
