extends "res://tests/test_case.gd"
## Roterande väktare (docs/plan/mot-upprepning.md §1): bossplatsen växlar med djupet (realms.json "guardians"), väktaren
## är ingen boss (inga bosstroféer eller boss_wins) men djupet klaras, questen räknas och körningen sparas som förut.

var _data := GameData.load_all()
const TMP := "user://test_guardians.cfg"


## En körning på den sista våningen i en Realm på ett visst djup.
func _last_floor(realm: String, depth: int, seed_value := 5) -> RunState:
	var s := RunState.new()
	s.set_realm(_data, realm)
	s.depth = depth
	s.fill_charges(_data)
	s.start_expedition(_data, seed_value)
	s.floor = RunState.FLOORS_PER_RUN - 1
	s.start_floor(_data)
	return s


func test_rotation_per_depth() -> void:
	assert_eq(RunState.guardian_for(_data, "crypt", 1), "", "djup 1: huvudbossen")
	assert_eq(RunState.guardian_for(_data, "crypt", 2), "crypt_g1")
	assert_eq(RunState.guardian_for(_data, "crypt", 3), "crypt_g2")
	assert_eq(RunState.guardian_for(_data, "crypt", 4), "", "djup 4: huvudbossen igen")
	assert_eq(RunState.guardian_for(_data, "crypt", 5), "crypt_g1")
	assert_eq(RunState.guardian_for(_data, "crypt", 7), "")
	assert_eq(RunState.guardian_for(_data, "chapel", 3), "chapel_g2")
	assert_eq(RunState.guardian_for(_data, "nowhere", 2), "", "okänd Realm: ingen väktare")
	# Samma djup ger alltid samma väktare (inget slump, inget frö).
	for seed_value in [1, 2, 9]:
		var s := _last_floor("crypt", 2, seed_value)
		assert_eq(s.map.cell(s.map.goal).encounter, "crypt_g1")


func test_guardian_encounters_are_sound() -> void:
	for realm_id in _data.realms:
		var r: Dictionary = _data.realms[realm_id]
		var main: String = r.floors[r.floors.size() - 1]
		assert_true(_data.encounters[main].enemies.any(func(k: String) -> bool: return _data.enemies[k].get("boss", false)),
				"%s: huvudbossen finns" % realm_id)
		for enc_id in r.get("guardians", []):
			assert_true(_data.encounters.has(enc_id), "%s finns" % enc_id)
			var enc: Dictionary = _data.encounters[enc_id]
			assert_true(enc.get("guardian", false), "%s är märkt som väktare" % enc_id)
			assert_true(enc.enemies.size() >= 3 and enc.enemies.size() <= 4, "%s: ledaren och 2–3 följeslagare" % enc_id)
			for kind in enc.enemies:
				assert_true(_data.enemies.has(kind), "%s: %s finns" % [enc_id, kind])
				assert_true(not _data.enemies[kind].get("boss", false), "%s: ingen boss i väktarens grupp" % enc_id)
			var leader: Dictionary = _data.enemies[enc.enemies[0]]
			assert_true(leader.get("rank", "") in ["elite", "miniboss"], "%s: ledaren är elit eller miniboss" % enc_id)
			assert_true(String(leader.get("trophy", "")) != "", "%s: ledaren lämnar en trofé" % enc_id)


func test_goal_cell_follows_depth() -> void:
	var d1 := _last_floor("crypt", 1)
	var g1 := d1.map.cell(d1.map.goal)
	assert_eq(g1.encounter, "crypt_3", "djup 1: Benfurstens sal")
	assert_true(not g1.get("guardian", false) and not d1.guardian_room(g1))
	var d2 := _last_floor("crypt", 2)
	var g2 := d2.map.cell(d2.map.goal)
	assert_eq(g2.encounter, "crypt_g1")
	assert_true(g2.boss and d2.guardian_room(g2), "väktaren står på bossrutan")
	var d3 := _last_floor("chapel", 3)
	assert_eq(d3.map.cell(d3.map.goal).encounter, "chapel_g2")
	# Den första våningen slutar fortfarande vid en trappa.
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.depth = 2
	s.start_expedition(_data, 3)
	assert_eq(s.map.cell(s.map.goal).kind, "stairs")


func test_twisted_boss_goes_first() -> void:
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.depth = 2
	s.set_growth(_data, LivingMap.GROWTH_MAX)
	assert_eq(s.boss_encounter(_data), "crypt_twisted", "den förvridna bossen tar platsen oavsett djup")


func test_guardian_win_clears_depth_without_boss_trophy() -> void:
	var s := _last_floor("crypt", 2)
	s.pos = s.map.goal
	s.quest.done = true
	s.quest.progress = s.quest.goal
	s.realm_quest_done = true
	var r := s.current_room()
	assert_eq(RunState.fight_kind(r), "end", "väktaren ger bossens erfarenhet och fynd")
	assert_eq(s.battle_opts().get("counter", false), true, "motdrag som i en bossstrid")
	s.battle_won()
	assert_true(s.floor_cleared(), "djupet är klart när väktaren är besegrad")
	assert_true(s.realm_quest_done, "Realm Quest är oberoende av vem som vaktar")
	# Run.battle_finished räknar boss_wins för fiender med "boss": väktarens grupp har inga.
	var p := Profile.new()
	for kind in _data.encounters[s.encounter()].enemies:
		if _data.enemies[kind].get("boss", false):
			p.defeat_boss(kind)
	assert_true(p.boss_wins.is_empty() and p.bosses_defeated.is_empty(), "boss_wins och smörjelsen bara för huvudbossen")
	p.clear_depth(s.depth, s.realm)
	assert_eq(int(p.realm_depth.get("crypt", 0)), 2, "djup 2 räknas som klarat")
	assert_eq(p.best_depth, 2)
	# Troféerna: ledarens egen (Klockarens rep) är säker, ingen bosstrofé.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var offer := s.trophy_offer(_data, rng, [], [])
	assert_true(not offer.is_empty() and offer[0] == _data.enemies.bell_ringer.trophy, "väktarens trofé först")
	for t in offer:
		assert_true(t != _data.enemies.bone_lich.trophy, "ingen bosstrofé från en väktare")


func test_save_load_keeps_guardian() -> void:
	var s := _last_floor("mountain", 2)
	s.save(TMP)
	var back := RunState.load_from(TMP)
	var g := back.map.cell(back.map.goal)
	assert_eq(g.encounter, "troll_g1")
	assert_true(back.guardian_room(g), "väktaren finns kvar efter sparning")
	assert_eq(back.depth, 2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_loss_tip_counts_guardian_as_boss() -> void:
	assert_true(LossTips._lost_to_boss(_data, "chapel_g1"))
	assert_true(not LossTips._lost_to_boss(_data, "chapel_e6"))
