extends "res://tests/test_case.gd"
## 0.22: ramverket för statusar (buffar och debuffar) och flytt på tidslinjen.

var _data := _with_test_statuses()


## Spelets data plus några teststatusar som prövar varje del av ramverket.
func _with_test_statuses() -> Dictionary:
	var d := GameData.load_all().duplicate(true)
	d.auras["t_stack"] = {"name": "Stapel", "duration": 2, "debuff": true, "stacking": "stack", "max_stacks": 3,
			"damage_taken_mult": 1.1}
	d.auras["t_haste"] = {"name": "Snabb", "duration": 2, "buff": true, "removes": ["t_slow"]}
	d.auras["t_slow"] = {"name": "Långsam", "duration": 2, "debuff": true, "removes": ["t_haste"]}
	d.auras["t_snare"] = {"name": "Snärjd", "duration": 2, "debuff": true, "snare": true}
	d.auras["t_leech"] = {"name": "Blodsugare", "duration": 2, "buff": true, "leech": 0.25}
	d.auras["t_locked"] = {"name": "Låst", "duration": 2, "buff": true, "cannot_dispel": true}
	d.auras["t_dot"] = {"name": "Gift", "duration": 3, "debuff": true, "stacking": "stack", "max_stacks": 5,
			"dot_stat": "attack", "dot_pct": 0.1}
	return d


func _sim(encounter := "crypt_1", party: Array = ["paladin", "brokk", "alva", "eira"]) -> CombatSim:
	return CombatSim.create(_data, encounter, 3, party)


func test_statuses_have_a_kind_and_count_down_in_the_owners_turns() -> void:
	var sim := _sim()
	var p := sim.unit("paladin")
	sim._add_aura(p, p, "inspired")
	sim._add_aura(p, p, "vulnerable")
	assert_eq(p.auras.inspired.kind, "buff")
	assert_eq(p.auras.vulnerable.kind, "debuff")
	assert_eq(p.statuses("buff"), ["inspired"])
	sim._tick_turn_start(p)
	assert_eq(p.auras.vulnerable.remaining, 2.0, "Sårbar varar tre av ägarens turer (originalet)")
	sim._tick_turn_start(p)
	sim._tick_turn_start(p)
	assert_true(not p.auras.has("vulnerable"), "försvinner när ägarens turer är slut")
	var found := false
	for e in sim.drain_events():
		if e.type == "aura_removed" and e.aura == "vulnerable" and e.reason == "expired" and e.aura_kind == "debuff":
			found = true
	assert_true(found)


func test_stacking_multiplies_the_effect_up_to_the_cap() -> void:
	var sim := _sim()
	var e := sim.enemies[0]
	var p := sim.unit("paladin")
	for i in 5:
		sim._add_aura(p, e, "t_stack")
	assert_eq(e.auras.t_stack.stacks, 3)
	assert_near(e.auras.t_stack.damage_taken_mult, 1.3, 1e-9, "tre staplar à +10 %")
	for i in 2:
		sim._add_aura(p, e, "t_dot")
	assert_eq(e.auras.t_dot.dot, roundf(p.attack * 0.1) * 2, "DoT gånger staplarna")
	sim._add_aura(p, p, "inspired")
	sim._add_aura(p, p, "inspired")
	assert_eq(p.auras.inspired.stacks, 1, "standard: varaktigheten fylls på, ingen stapel")


func test_a_status_can_remove_its_opposite() -> void:
	var sim := _sim()
	var p := sim.unit("paladin")
	sim._add_aura(p, p, "t_slow")
	sim._add_aura(p, p, "t_haste")
	assert_true(p.auras.has("t_haste") and not p.auras.has("t_slow"))
	sim._add_aura(p, p, "t_slow")
	assert_true(p.auras.has("t_slow") and not p.auras.has("t_haste"))


func test_resistant_only_changes_the_resistant_versions() -> void:
	var sim := _sim()
	var e := sim.enemies[0]
	e.resistant = true
	sim._add_aura(sim.unit("paladin"), e, "vulnerable")
	assert_near(e.auras.vulnerable.damage_taken_mult, 1.5, 1e-9, "Sårbar verkar fullt på bossar (originalet)")
	sim._add_aura(sim.unit("paladin"), e, "silenced")
	assert_true(not sim.is_silenced(e), "resistent: kan kasta ändå, men med −50 %")


func test_dispel_and_purge() -> void:
	var sim := _sim()
	var p := sim.unit("paladin")
	for id in ["inspired", "warded", "t_locked"]:
		sim._add_aura(p, p, id)
	for id in ["vulnerable", "weak"]:
		sim._add_aura(p, p, id)
	assert_eq(sim._strip(p, "buff", 5, "dispel"), 2, "Låst sitter kvar")
	assert_true(p.auras.has("t_locked") and p.auras.has("vulnerable"))
	sim._status_effect({"type": "purge", "count": 1}, p)
	assert_true(p.auras.has("vulnerable") and not p.auras.has("weak"), "den senaste debuffen först")


func test_to_top_and_to_bottom() -> void:
	var sim := _sim()
	sim.begin()
	sim.drain_events()
	var last: String = sim.order[-1]
	var first: String = sim.order[0]
	sim._move_on_timeline(sim.unit(last), "top")
	assert_eq(sim.order[0], last)
	sim._move_on_timeline(sim.unit(first), "bottom")
	assert_eq(sim.order[-1], first)
	var moves := sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "timeline_move")
	assert_eq(moves.size(), 3, "överst, den som skickades ned, och sist")


func test_snared_cannot_be_moved() -> void:
	var sim := _sim()
	sim.begin()
	var id: String = sim.order[-1]
	var u := sim.unit(id)
	sim._add_aura(u, u, "t_snare")
	sim._move_on_timeline(u, "top")
	assert_eq(sim.order[-1], id)
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "timeline_blocked"))


func test_a_boss_only_moves_one_step() -> void:
	var sim := CombatSim.create(_data, "crypt_3", 3)
	sim.begin()
	var boss: CombatUnit = sim.enemies.filter(func(e: CombatUnit) -> bool: return _data.enemies[e.kind].get("boss", false))[0]
	var i := sim.order.find(boss.id)
	if i < 0:
		return  # bossen har turen just nu
	sim._move_on_timeline(boss, "bottom")
	assert_eq(sim.order.find(boss.id), mini(i + 1, sim.order.size() - 1))


func test_moving_the_current_unit_to_top_gives_it_the_next_turn() -> void:
	var sim := _sim()
	sim.begin()
	var u := sim.current
	sim._move_on_timeline(u, "top")
	sim._end_turn()
	assert_eq(sim.order[-1] != u.id or sim.current == u, true)
	assert_true(sim.current == u, "flyttad överst under sin egen tur: får nästa tur också")


func test_turn_limits_reset_at_each_turn() -> void:
	var sim := _sim()
	sim.begin()
	var u := sim.current
	for i in CombatSim.TURN_LIMIT:
		assert_true(sim._within_limit(u, "attack"))
	assert_true(not sim._within_limit(u, "attack"))
	sim._move_on_timeline(u, "top")
	sim._end_turn()
	assert_true(sim._within_limit(sim.current, "attack"), "nollställs när figuren är överst igen")


func test_leeching_heals_and_points_to_the_hit() -> void:
	var sim := _sim()
	var p := sim.unit("paladin")
	p.hp = p.max_hp * 0.5
	var e := sim.enemies[0]
	p.speed = e.speed
	sim._add_aura(p, p, "t_leech")
	sim.drain_events()
	sim._deal_damage(p, e, 1.0, "physical", "attack", false, true, "attack", true)
	var ev := sim.drain_events()
	var dmg: Dictionary = ev.filter(func(x: Dictionary) -> bool: return x.type == "damage")[0]
	var heal: Dictionary = ev.filter(func(x: Dictionary) -> bool: return x.type == "heal")[0]
	assert_eq(heal.amount, roundf(dmg.amount * 0.25))
	assert_true(heal.calc.get("leech", false))
	assert_eq(heal.calc.damage_calc.lost, dmg.amount)
	assert_true(DamageExplain.lines(_data, heal)[0].begins_with("25 % av skadan"))


func test_status_conditions_for_traits_and_macros() -> void:
	var sim := _sim()
	var p := sim.unit("paladin")
	var e := sim.enemies[0]
	sim._add_aura(p, e, "vulnerable")
	assert_true(sim._when(p, {"target_has_kind": "debuff"}, {"target": e.id}))
	assert_true(not sim._when(p, {"target_has_kind": "buff"}, {"target": e.id}))
	assert_true(sim._when(p, {"self_lacks_aura": "vulnerable"}, {}))
	assert_true(sim._when(p, {"aura_kind": "debuff"}, {"aura_kind": "debuff"}))
	assert_true(MacroRunner.test_condition(sim, p, e, {"cond": "has_debuff"}, [e]))
	assert_true(MacroRunner.test_condition(sim, p, p, {"cond": "lacks_debuff"}, [p]))
	assert_eq(MacroRunner.condition_name(_data, "has_debuff", 0), "har en debuff")


func test_status_modifiers_show_in_the_calculation() -> void:
	var sim := _sim()
	var p := sim.unit("paladin")
	var e := sim.enemies[0]
	p.speed = e.speed
	for i in 2:
		sim._add_aura(p, e, "t_stack")
	sim.drain_events()
	sim._deal_damage(p, e, 1.0, "physical", "attack", false, true, "attack", true)
	var dmg: Dictionary = sim.drain_events().filter(func(x: Dictionary) -> bool: return x.type == "damage")[0]
	assert_true(dmg.calc.mods.any(func(m: Dictionary) -> bool: return m.name == "Stapel ×2" and is_equal_approx(m.f, 1.2)))
