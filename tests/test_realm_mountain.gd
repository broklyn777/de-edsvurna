extends "res://tests/test_case.gd"
## Trollberget (Realm 4, docs/plan/trollens-realm.md steg 1, Bortbytingen i steg 2): bara troll, öppnas när kapellet är
## klarat på djup 1, grottan följer reglerna, föremålen lånar andra föremåls val med egen text, questen får egna namn.

const TROLLS := ["moss_troll", "porridge_troll", "grumpy_troll", "club_troll", "changeling_troll", "bridge_troll",
		"troll_mother", "mountain_king"]

var _data := GameData.load_all()


func test_mountain_uses_only_the_existing_trolls() -> void:
	var m: Dictionary = _data.realms.mountain
	assert_eq(m.short, "Berget")
	var all: Array = m.floors.duplicate()
	for pool in m.pools + m.elite_pools:
		all.append_array(pool)
	assert_eq(m.pools.size(), 3, "tre tiers")
	for enc_id in all:
		assert_true(_data.encounters.has(enc_id), enc_id)
		for kind in _data.encounters[enc_id].enemies:
			assert_true(TROLLS.has(kind), "%s: bara troll i berget (%s)" % [enc_id, kind])
	for pool in m.elite_pools:
		for enc_id in pool:
			assert_true(_data.encounters[enc_id].get("elite_group", false), "%s är en elitgrupp" % enc_id)
	assert_true("mountain_king" in _data.encounters[m.floors[2]].enemies, "Bergakungen är bossen")
	for obj in m.objects:
		assert_true(_data.objects.has(obj), obj)
	assert_true(ResourceLoader.exists("res://assets/illustrations/%s.webp" % m.map.vignette))
	assert_true(_data.dialog.narrator.has("boss_mountain_king"), "berättarrutan efter Bergakungen")


func test_mountain_opens_when_the_chapel_is_cleared_at_depth_one() -> void:
	var p := Profile.new()
	assert_true(RunState.realm_open(p, _data, "crypt"))
	assert_true(RunState.realm_open(p, _data, "chapel"))
	assert_true(not RunState.realm_open(p, _data, "mountain"), "stängt för en ny profil")
	p.realm_depth = {"crypt": 3}
	assert_true(not RunState.realm_open(p, _data, "mountain"), "kryptan räcker inte")
	p.realm_depth = {"chapel": 1}
	assert_true(RunState.realm_open(p, _data, "mountain"), "kapellet klarat på djup 1")
	assert_true(RunState.realm_lock_text(_data, "mountain").find("kapellet") >= 0)
	assert_eq(RunState.realm_lock_text(_data, "crypt"), "")


func test_the_map_rect_does_not_overlap_another_realm() -> void:
	var r: Array = _data.realms.mountain.map.rect
	var mine := Rect2(r[0], r[1], r[2], r[3])
	for realm_id in _data.realms:
		if realm_id == "mountain":
			continue
		var o: Array = _data.realms[realm_id].map.rect
		assert_true(not mine.grow(6).intersects(Rect2(o[0], o[1], o[2], o[3])), "berget och %s" % realm_id)


func test_mountain_grottos_follow_the_rules_for_many_seeds() -> void:
	for seed_value in range(1, 41):
		var s := RunState.new()
		s.set_realm(_data, "mountain")
		s.fill_charges(_data)
		s.start_expedition(_data, seed_value)
		assert_eq(s.map.problems(s.quest), [], "våning 1, frö %d" % seed_value)
		_assert_trolls(s.map, seed_value)
		s.floor = 1
		s.start_floor(_data)
		assert_eq(s.map.problems(s.quest), [], "våning 2, frö %d" % seed_value)
		_assert_trolls(s.map, seed_value)


func _assert_trolls(map: Grotto, seed_value: int) -> void:
	for c in map.cells:
		if c.has("encounter") and _data.encounters.has(c.encounter):
			for kind in _data.encounters[c.encounter].enemies:
				assert_true(TROLLS.has(kind), "frö %d: %s" % [seed_value, c.encounter])


func test_quests_get_the_mountain_names() -> void:
	var seen := {}
	for seed_value in range(1, 30):
		var s := RunState.new()
		s.set_realm(_data, "mountain")
		s.start_expedition(_data, seed_value)
		seen[s.quest.type] = RunState.quest_text(s.quest)
	for type in seen:
		assert_true(String(seen[type]).begins_with(_data.realms.mountain.quests[type]), seen[type])
	var plain := RunState.roll_quest(RandomNumberGenerator.new())
	assert_true(not RunState.quest_text(plain).begins_with("Tullen"), "andra Realms behåller typens ord")


func test_mountain_objects_use_their_own_text() -> void:
	var p := Profile.new()
	p.party = ["paladin", "brokk"]
	p.realm = "mountain"
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 5)
	assert_eq(s.realm, "mountain")
	var r := s.current_room()
	r.obj = "sunken_bell"
	var out := s.use_object(_data, "pull", RandomNumberGenerator.new())
	assert_true(String(out.text).begins_with("Klangen"), "klockans egen text")
	assert_near(s.next_stat_mult, 1.15, 1e-9, "nästa trollgrupp är beredd")
	r.obj = "light_crack"
	r.erase("done")
	out = s.use_object(_data, "valuables", RandomNumberGenerator.new())
	assert_true(String(out.text).begins_with("Ljusstrimman") or String(out.text).begins_with("Strimman"), out.text)
	r.obj = "troll_cup"
	r.erase("done")
	out = s.use_object(_data, "knock", RandomNumberGenerator.new())
	assert_true(out.fight, "bägaren väcker en trollgrupp")
	assert_true(_data.encounters[r.encounter].enemies.all(func(k: String) -> bool: return TROLLS.has(k)))
