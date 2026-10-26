extends "res://tests/test_case.gd"
## Den delade lågan (Irrblossets trofé): när bäraren helar någon får hela sällskapet Läkning i 1 tur, en gång per tur.
## En Läkning som tickar räknas inte som att bäraren helar (not_hot), så lågan håller inte sig själv vid liv.

var _data := GameData.load_all()


func _sim(trophy := "shared_flame") -> CombatSim:
	var sim := CombatSim.create(_data, "chapel_1a", 3, ["paladin", "brokk", "alva", "eira"], {"alva": _data.heroes.alva.traits + [trophy]}, {}, {}, 1,
			{"elite_chance": 0.0})
	sim.begin()
	sim.drain_events()
	for u in sim.heroes:
		u.auras.erase("mending")
	return sim


func _mended(sim: CombatSim) -> int:
	return sim.heroes.filter(func(u: CombatUnit) -> bool: return u.auras.has("mending")).size()


func test_irrbloss_leaves_the_trophy() -> void:
	assert_eq(String(_data.enemies.will_o_wisp.trophy), "shared_flame")
	assert_eq(String(_data.traits.shared_flame.rarity), "common")
	assert_true(_data.traits.shared_flame.has("combo"), "troféplatsen har en kombinationsrad")


func test_a_heal_gives_the_whole_party_mending_for_one_turn() -> void:
	var sim := _sim()
	var brokk := sim.unit("brokk")
	brokk.hp = brokk.max_hp * 0.5
	sim._heal(sim.unit("alva"), brokk, 5.0, "healing_light")
	sim.drain_events()
	assert_eq(_mended(sim), sim.heroes.size(), "hela sällskapet får Läkning")
	assert_eq(float(brokk.auras.mending.remaining), 1.0, "i en tur")


func test_only_once_per_turn() -> void:
	var sim := _sim()
	var alva := sim.unit("alva")
	var count := 0
	sim._heal(alva, sim.unit("brokk"), 5.0, "healing_light")
	sim._heal(alva, sim.unit("eira"), 5.0, "healing_light")
	for e in sim.drain_events():
		if e.type == "aura_applied" and e.aura == "mending":
			count += 1
	assert_eq(count, sim.heroes.size(), "den andra helningen samma tur ger ingen ny omgång")


func test_others_heals_and_trait_heals_do_not_trigger() -> void:
	var sim := _sim()
	sim._heal(sim.unit("paladin"), sim.unit("brokk"), 5.0, "healing_light")
	assert_eq(_mended(sim), 0, "någon annans helning")


func test_the_mending_tick_does_not_renew_itself() -> void:
	var sim := _sim()
	var brokk := sim.unit("brokk")
	brokk.hp = brokk.max_hp * 0.5
	sim._heal(sim.unit("alva"), brokk, 5.0, "healing_light")
	sim.drain_events()
	sim.turn_no += 1  # en ny tur: once_per_turn hindrar inte längre
	var hp := brokk.hp
	sim._tick_turn_start(brokk)
	sim.drain_events()
	assert_true(brokk.hp > hp, "Läkningen helade")
	assert_true(not brokk.auras.has("mending"), "och tog slut i stället för att fyllas på")
