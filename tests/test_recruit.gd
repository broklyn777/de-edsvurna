extends "res://tests/test_case.gd"
## 0.23: en ny profil börjar med Paladinen och en följeslagare, lärjungar befrias ur fånge-rum, Värdshuset,
## ikapphämtning, fiender efter sällskapets storlek och de sex nya följeslagarnas egenskaper.

var _data := GameData.load_all()


func test_a_new_profile_starts_small() -> void:
	var p := Profile.new()
	assert_eq(p.party, ["paladin", "imma"])
	assert_eq(p.recruited, ["imma"])


func test_old_profiles_keep_their_heroes() -> void:
	var path := "user://test_progress_legacy_023.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 300)
	cfg.set_value("progress", "party", ["paladin", "brokk", "alva", "eira"])
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq(p.recruited, ["brokk", "alva", "eira", "solveig", "imma"], "Imma kommer till Värdshuset")
	assert_eq(p.party, ["paladin", "brokk", "alva", "eira"])
	p.recruit(_data, "ronja")
	p.save(path)
	var q := Profile.load_from(path)
	assert_true(q.recruited.has("ronja") and q.recruited.size() == 6)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_prisoners_wait_on_their_floors() -> void:
	var p := Profile.new()
	var s := RunState.new_run(p, _data)
	assert_eq(s.prisoners["0"].hero, "brokk", "Brokk sitter fången hos skeletten på första våningen")
	assert_eq(s.prisoners["1"].hero, "alva")
	s.start_expedition(_data, 5)
	var first: Array = s.map.steps[0].filter(func(r: Dictionary) -> bool: return r.kind == "prisoner")
	assert_eq(first.size(), 1, "den första fången finns i första steget")
	assert_true(first[0].guarded and RunState.is_battle(first[0]), "Brokk är bevakad av skelett")
	s.next_floor(_data)
	var later: Array = s.map.all_rooms().filter(func(r: Dictionary) -> bool: return r.kind == "prisoner")
	assert_eq(later.size(), 1)
	assert_true(later[0].guarded and RunState.is_battle(later[0]), "de andra är bevakade")
	p.recruited.append("brokk")
	assert_true(not RunState.new_run(p, _data).prisoners.has("0") or RunState.new_run(p, _data).prisoners["0"].hero != "brokk",
			"den man redan har sitter inte fången")


func test_deeper_disciples_need_their_depth() -> void:
	var p := Profile.new()
	p.realm = "chapel"
	var s := RunState.new_run(p, _data)
	var heroes: Array = s.prisoners.values().map(func(x: Dictionary) -> String: return x.hero)
	assert_true(heroes.has("lirien") and not heroes.has("ronja"), "Ronja kräver djup 2")
	assert_true(not s.prisoners["0"].get("guarded", true), "Lirien är obevakad")
	p.depth = 2
	heroes = RunState.new_run(p, _data).prisoners.values().map(func(x: Dictionary) -> String: return x.hero)
	assert_true(heroes.has("hulda") or heroes.has("ronja"))


func test_recruits_join_weak_and_the_party_has_room_for_three() -> void:
	var p := Profile.new()
	assert_true(p.recruit(_data, "alva", 1.0))
	assert_eq(int(p.hero(_data, "alva").level), 1)
	assert_true(p.recruit(_data, "eira", 6.0))
	assert_eq(int(p.hero(_data, "eira").level), 2, "nivå 2 när sällskapet redan är starkt")
	assert_true(not p.recruit(_data, "alva"), "bara en gång")
	p.recruit(_data, "tove")
	p.set_party(["alva", "eira", "tove", "brokk"])
	assert_eq(p.party.size(), 4, "Paladinen + 3")
	p.set_party([])
	assert_eq(p.party.size(), 2, "minst en följeslagare")


func test_catch_up_brings_a_new_disciple_up_quickly() -> void:
	assert_near(Profile.catch_up(2.0, 8.0), 3.0, 1e-9)
	assert_near(Profile.catch_up(8.0, 8.0), 1.0, 1e-9)
	var p := Profile.new()
	for id in ["alva", "eira"]:
		p.recruit(_data, id)
	for id in ["paladin", "brokk", "alva"]:
		p.hero(_data, id).level = 8
	p.hero(_data, "eira").level = 2
	var party := ["paladin", "brokk", "alva", "eira"]
	var battles := 0
	while int(p.hero(_data, "eira").level) < 6 and battles < 50:
		p.grant_xp(_data, party, HeroStats.battle_xp("battle", 2))
		battles += 1
	assert_true(battles <= 6, "nivå 2 → 6 på %d strider på djup 2" % battles)


func test_enemies_scale_with_the_party_size() -> void:
	var four := CombatSim.create(_data, "crypt_1", 1, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, 1, {"elite_chance": 0.0})
	var two := CombatSim.create(_data, "crypt_1", 1, ["paladin", "brokk"], {}, {}, {}, 1, {"elite_chance": 0.0})
	assert_near(two.enemies[0].max_hp, roundf(four.enemies[0].max_hp * CombatSim.PARTY_SCALE[2]), 1.0)
	assert_eq(two.enemies[0].defense, four.enemies[0].defense, "Defense skalas inte")


func test_every_new_companion_is_complete() -> void:
	for id in ["imma", "ronja", "lirien", "tove", "hulda", "ragnhild", "sefir"]:
		var h: Dictionary = _data.heroes[id]
		assert_true(_data.abilities.has(h.attack_ability), id)
		assert_eq(h.abilities.size(), 3, id)
		for a in h.abilities:
			assert_true(_data.abilities.has(a) and _data.abilities[a].has("text"), "%s %s" % [id, a])
		for t in h.traits:
			assert_true(_data.traits.has(t) and _data.traits[t].get("text", "") != "", "%s %s" % [id, t])
		assert_true(_data.personalities.has(h.personality))
		assert_true(_data.macros.has(id), "%s har startmakron" % id)


func _sim(party: Array, encounter := "crypt_1") -> CombatSim:
	return CombatSim.create(_data, encounter, 4, party, {}, {}, {}, 1, {"elite_chance": 0.0})


func test_ronja_falcon_answers_an_intent() -> void:
	var sim := _sim(["paladin", "ronja"])
	sim.begin()
	var marked := sim.enemies.filter(func(e: CombatUnit) -> bool: return e.auras.has("marked"))
	assert_true(not marked.is_empty(), "en fiende som valde ett mål blev Märkt")


func test_lirien_shares_a_buff() -> void:
	var sim := _sim(["paladin", "lirien", "brokk"])
	var l := sim.unit("lirien")
	sim._perform(l, "battle_song", "ability", "paladin")
	assert_true(sim.unit("paladin").auras.has("inspired"))
	assert_true(sim.unit("brokk").auras.has("inspired") and sim.unit("brokk").auras.inspired.remaining == 1.0,
			"de andra får samma buff i 1 tur")


func test_tove_counters_a_dodge_and_speeds_up() -> void:
	var sim := _sim(["paladin", "tove"])
	var t := sim.unit("tove")
	var e := sim.enemies[0]
	var speed := t.speed
	var hp := e.hp
	sim._emit({"type": "dodge", "source": e.id, "target": t.id, "ability": "x"})
	assert_true(e.hp < hp, "kontrar")
	assert_near(t.speed, speed * 1.1, 0.01)


func test_hulda_roots_strike_back() -> void:
	var sim := _sim(["paladin", "hulda"])
	var h := sim.unit("hulda")
	var p := sim.unit("paladin")
	sim._perform(h, "leaf_shield", "ability", "paladin")
	assert_true(p.auras.has("rootling") and p.barrier > 0.0)
	p.barrier = 0.0
	var e := sim.enemies[0]
	var hp := e.hp
	e.speed = p.speed
	sim._deal_damage(e, p, 1.0, "physical", "x", false, true, "attack", true)
	assert_true(e.hp < hp, "rötterna slår tillbaka")


func test_ragnhild_burns_an_enemy_heal() -> void:
	var sim := _sim(["paladin", "ragnhild"])
	var e := sim.enemies[0]
	e.hp = e.max_hp * 0.5
	var before := e.hp
	sim._heal(e, e, 50.0, "grave_mend")
	assert_true(e.hp < before + 50.0, "ljuset bränner helningen")


func test_sefir_crit_moves_to_the_top() -> void:
	var sim := _sim(["paladin", "sefir", "brokk"])
	sim.begin()
	var s := sim.unit("sefir")
	if sim.current == s:
		return
	sim._emit({"type": "damage", "source": "sefir", "target": sim.enemies[0].id, "amount": 10.0, "crit": true, "direct": true})
	assert_eq(sim.order[0], "sefir")


func test_imma_steals_a_buff_for_the_weakest() -> void:
	var sim := _sim(["paladin", "imma", "brokk"])
	var e := sim.enemies[0]
	var b := sim.unit("brokk")
	b.hp = b.max_hp * 0.2
	sim._add_aura(e, e, "berserk")
	sim._emit({"type": "damage", "source": "imma", "target": e.id, "amount": 10.0, "direct": true, "crit": false})
	assert_true(not e.auras.has("berserk"), "buffen är stulen")
	assert_true(b.auras.has("berserk"), "den svagaste fick den")


func test_imma_is_the_fastest_and_her_macro_starts_simple() -> void:
	for id in _data.heroes:
		if id != "imma":
			assert_true(_data.heroes.imma.stats.speed >= _data.heroes[id].stats.speed, id)
	assert_eq(_data.macros.imma.lines[0].cond, "has_buff")
