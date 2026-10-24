extends "res://tests/test_case.gd"
## Mot upprepning (textspelet, docs/plan/mot-upprepning.md, VD 2026-10-24): vanliga grupper per djupband med en prägel
## som ändrar vem man fäller först, inkräktare från en annan Realm från djup 4, våning 1:s elit som roterar, Nemesis ur
## båda våningarnas elit, väktarens ledare som inte blir vanlig elit intill väktarens djup, och lägrets troféer som
## föredrar det man inte äger och aldrig erbjuder det man just fått.

var _data := GameData.load_all().duplicate(true)
const PARTY := ["paladin", "brokk", "alva", "eira"]
const REALMS := ["crypt", "chapel", "mountain"]


func _run(realm_id: String, depth: int, seed_value: int) -> RunState:
	var s := RunState.new()
	s.set_realm(_data, realm_id)
	s.depth = depth
	s.fill_charges(_data)
	s.start_expedition(_data, seed_value)
	return s


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


func test_pools_follow_depth_band() -> void:
	for realm_id in REALMS:
		var r: Dictionary = _data.realms[realm_id]
		assert_eq(RunState.pools_for(_data, realm_id, 1), r.pools, "%s djup 1: grundpoolerna" % realm_id)
		assert_eq(RunState.pools_for(_data, realm_id, 2), r.pools, "%s djup 2: grundpoolerna" % realm_id)
		assert_eq(RunState.pools_for(_data, realm_id, 3), r.depth_pools[0].pools, "%s djup 3: band 3–5" % realm_id)
		assert_eq(RunState.pools_for(_data, realm_id, 5), r.depth_pools[0].pools, "%s djup 5: band 3–5" % realm_id)
		assert_eq(RunState.pools_for(_data, realm_id, 6), r.depth_pools[1].pools, "%s djup 6: band 6+" % realm_id)
		var twists := {}
		for band in r.depth_pools:
			assert_eq(band.pools.size(), 3, "tre tiers")
			for pool in band.pools:
				for enc_id in pool:
					assert_true(_data.encounters.has(enc_id), "%s finns" % enc_id)
					var e: Dictionary = _data.encounters[enc_id]
					assert_true(not e.get("elite_group", false), "%s: bara vanliga grupper i banden" % enc_id)
					if e.has("twist"):
						twists[e.twist.id] = true
						assert_true(_data.encounters.has(String(e.get("base", ""))), "%s: grundgruppen finns" % enc_id)
						assert_true(String(e.twist.text) != "", "%s: prägeln syns på kortet" % enc_id)
						for kind in e.overrides:
							assert_true(e.enemies.has(kind), "%s: prägeln sitter på en fiende i gruppen" % enc_id)
							for t in e.overrides[kind].get("traits", []):
								assert_true(_data.traits.has(t), "%s: egenskapen %s finns" % [enc_id, t])
		assert_true(twists.size() >= 3, "%s: tre sorters prägel (fäll prästen, livvakten, de bundna)" % realm_id)


func test_band_groups_and_twist_once_per_descent() -> void:
	for realm_id in REALMS:
		for seed_value in range(1, 25):
			var s := _run(realm_id, 4, seed_value)
			var band: Array = []
			for pool in RunState.pools_for(_data, realm_id, 4):
				band.append_array(pool)
			var used := {}
			for f in RunState.FLOORS_PER_RUN:
				if f > 0:
					s.floor = f
					s.start_floor(_data)
				for c in s.map.cells:
					if c.get("kind", "") != "battle" or c.has("intruder"):
						continue
					var e: Dictionary = _data.encounters[c.encounter]
					assert_true(band.has(c.encounter) or band.any(func(id: String) -> bool:
							return String(_data.encounters[id].get("base", "")) == c.encounter),
							"%s djup 4: %s ur bandets pooler" % [realm_id, c.encounter])
					if e.has("twist"):
						assert_true(not used.has(c.encounter), "%s: samma prägel två gånger (frö %d)" % [c.encounter, seed_value])
						used[c.encounter] = true


func test_intruders_only_from_depth_four() -> void:
	for realm_id in REALMS:
		var seen := 0
		for seed_value in range(1, 30):
			var low := _run(realm_id, 3, seed_value)
			assert_true(not low.map.cells.any(func(c: Dictionary) -> bool: return c.has("intruder")), "djup 3: inga inkräktare")
			var s := _run(realm_id, 5, seed_value)
			for c in s.map.cells:
				if c.has("intruder"):
					seen += 1
					assert_eq(c.kind, "battle", "bara en vanlig grupp byts")
					var src: Array = []
					for pool in RunState.pools_for(_data, String(c.intruder), 5):
						src.append_array(pool)
					src.append_array(src.map(func(id: String) -> String: return String(_data.encounters[id].get("base", ""))))
					assert_true(String(c.intruder) != realm_id and src.has(c.encounter), "inkräktaren kommer ur den andra Realmen")
		assert_true(seen >= 5, "%s djup 5: inkräktare ibland (%d av 29)" % [realm_id, seen])


func test_floor_one_elite_rotates_but_not_on_first_descent() -> void:
	for realm_id in REALMS:
		var met := {}
		for seed_value in range(1, 40):
			var s := _run(realm_id, 2 + seed_value % 4, seed_value)
			for c in s.map.cells:
				if c.get("elite", false) or c.get("nemesis", false):
					met[c.encounter] = true
					assert_true(_data.realms[realm_id].elite_pools[0].has(c.encounter), "våning 1: ur våning 1:s pool")
		assert_true(met.size() >= 2, "%s: våning 1:s elit roterar (%s)" % [realm_id, str(met.keys())])
	var first := RunState.new()
	first.set_realm(_data, "crypt")
	first.first_descent = true
	first.depth = 1
	assert_eq(first.elite_pools_for(_data)[0], ["crypt_e1"], "första nedstigningen: Kolossens vakt som förut")


func test_nemesis_draws_from_both_floors_on_floor_two() -> void:
	var pools := [["a", "b"], ["c"]]
	assert_eq(RunState.nemesis_pool(pools, 0), ["a", "b"])
	assert_eq(RunState.nemesis_pool(pools, 1), ["a", "b", "c"])
	var from_floor_one := 0
	for seed_value in range(1, 80):
		var s := _run("crypt", 3, seed_value)
		s.floor = 1
		s.start_floor(_data)
		for c in s.map.cells:
			if c.get("nemesis", false) and _data.realms.crypt.elite_pools[0].has(c.encounter):
				from_floor_one += 1
	assert_true(from_floor_one > 0, "Nemesis på våning 2 kan komma ur våning 1:s elit")


func test_guardian_leader_stays_away_from_its_depths() -> void:
	# Midnattsklockan (Klockaren) vaktar kryptans djup 2, 5, 8 …; Klockstapeln syns inte på väktarens eget djup
	# (GUARDIAN_GAP 0), men finns kvar på djupen emellan.
	for d in [1, 2, 3, 4, 5, 6]:
		var s := RunState.new()
		s.set_realm(_data, "crypt")
		s.depth = d
		var has_bell: bool = s.elite_pools_for(_data)[1].has("crypt_e5")
		if d in [2, 5]:
			assert_true(not has_bell, "djup %d: ingen Klockstapel" % d)
		else:
			assert_true(has_bell, "djup %d: Klockstapeln finns" % d)
	var c := RunState.new()
	c.set_realm(_data, "chapel")
	c.depth = 5
	assert_true(not c.elite_pools_for(_data)[1].has("chapel_e6"), "kapellet djup 5: ingen Abbedissans mässa")
	assert_true(not c.elite_pools_for(_data)[1].is_empty())


func test_twist_mechanics() -> void:
	# De bundna tar mindre skada så länge den andra står.
	var sim := CombatSim.create(_data, "crypt_2j", 3, PARTY)
	var bearer := _enemy(sim, "coffin_bearer")
	var rattler := _enemy(sim, "rattler")
	var probe := {"target": bearer.id, "kind": "attack", "direct": true}
	var names := func() -> Array: return sim._modifiers_named(bearer, "modify_damage_taken", probe).map(
			func(m: Dictionary) -> String: return m.name)
	assert_true(names.call().has("Bundna"), "Bundna medan Skramlaren står")
	rattler.alive = false
	assert_true(not names.call().has("Bundna"), "bandet brister när den andra fallit")
	# Livvakten tar skadan mot de andra i familjen.
	var g := CombatSim.create(_data, "crypt_2h", 3, PARTY)
	assert_eq(g._guard_for(g.heroes[0], _enemy(g, "skeleton_archer")), _enemy(g, "grave_warden"), "Gravväktaren är livvakt")
	# Prästen med Likpredikan har Sorgens vrede, bara i den gruppen.
	assert_true(_enemy(CombatSim.create(_data, "crypt_1f", 3, PARTY), "grave_priest").traits.has("grief_wrath"))
	assert_true(not _enemy(CombatSim.create(_data, "crypt_1b", 3, PARTY), "grave_priest").traits.has("grief_wrath"))


func test_trophy_offer_prefers_unowned_and_skips_taken() -> void:
	var s := _run("crypt", 3, 7)
	for i in s.map.cells.size():
		if s.map.cells[i].get("kind", "") == "battle":
			s.pos = i
			break
	var all := []
	for kind in _data.enemies:
		var t: String = _data.enemies[kind].get("trophy", "")
		if t != "" and not all.has(t):
			all.append(t)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var base := s.trophy_offer(_data, rng)
	assert_true(not base.is_empty())
	# Profilen äger allt utom en trofé ur Realmen: den kommer först.
	var fresh := "ember_shard" if _data.traits.has("ember_shard") else String(_data.enemies.ember_skeleton.trophy)
	var owned := all.filter(func(t: String) -> bool: return t != fresh)
	for seed_value in range(1, 10):
		rng.seed = seed_value
		var offer := s.trophy_offer(_data, rng, [], [], [], owned)
		assert_eq(offer[0], fresh, "den enda nya trofén står först")
	# En trofé som redan finns i körningen (t.ex. ur skatten bakom gruppen) erbjuds inte igen.
	for t in base:
		s.take_trophy(t)
	for seed_value in range(1, 10):
		rng.seed = seed_value
		for t in s.trophy_offer(_data, rng, [], [], [], owned):
			assert_true(not base.has(t), "%s togs nyss och erbjuds inte igen" % t)


func test_treasure_prefers_unowned() -> void:
	var s := _run("crypt", 3, 7)
	var pool := []
	for enc_id in s.floor_ids:
		for kind in _data.encounters[enc_id].enemies:
			var t: String = _data.enemies[kind].get("trophy", "")
			if t != "" and not _data.enemies[kind].get("boss", false) and not pool.has(t):
				pool.append(t)
	var keep: String = pool[0]
	var owned := pool.filter(func(t: String) -> bool: return t != keep)
	var rng := RandomNumberGenerator.new()
	for seed_value in range(1, 60):
		rng.seed = seed_value
		var t := s.treasure(_data, rng, owned)
		s.map.cells[s.pos].done = false
		if String(t.trophy) != "":
			assert_eq(t.trophy, keep, "skatten ger det man inte äger")
