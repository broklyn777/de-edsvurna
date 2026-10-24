extends "res://tests/test_case.gd"
## 0.27 steg 2 (docs/plan/0.27-fiender.md): kryptans nya fiender, familjen Benfolket, AI-tilläggen och motdragen.

var _data := GameData.load_all()


func _sim(encounter: String, opts := {}, depth := 1, seed_value := 3) -> CombatSim:
	return CombatSim.create(_data, encounter, seed_value, ["paladin", "brokk", "alva", "eira"], {}, {}, {}, depth, opts)


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


## Den första skadan från src mot tgt (försöker igen om träffen undveks).
func _hit_calc(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, ability_id: String, kind := "attack") -> Dictionary:
	for i in 40:
		sim.drain_events()
		sim._deal_damage(src, tgt, 1.0, "physical", ability_id, false, true, kind, true)
		for e in sim.drain_events():
			if e.type == "damage" and e.source == src.id and e.target == tgt.id:
				return e.calc
	return {}


func _factor(calc: Dictionary, name: String) -> float:
	for m in calc.get("mods", []):
		if m.name == name:
			return float(m.f)
	return 1.0


func test_new_crypt_enemies_have_data_trophies_and_traits() -> void:
	for kind in ["bone_runner", "coffin_bearer", "mold_skeleton", "rattler", "bone_colossus", "grave_caller",
			"grave_mist", "bone_scribe", "bell_ringer"]:
		var d: Dictionary = _data.enemies[kind]
		for t in d.traits:
			assert_true(_data.traits.has(t), "%s: egenskapen %s finns" % [kind, t])
		assert_true(_data.traits[d.trophy].get("trophy", false), "%s lämnar en trofé" % kind)
		assert_true(_data.traits[d.trophy].has("answers"), "%s: trofén säger vad den svarar på" % kind)
		assert_true(_data.abilities.has(d.attack_ability), "%s har ett grundanfall" % kind)
		for rule in d.get("rules", []):
			assert_true(_data.abilities.has(rule.ability), "%s: förmågan %s finns" % [kind, rule.ability])
		if d.has("elite"):
			assert_true(_data.traits[d.elite.trophy].get("trophy", false))
	for enc_id in _data.realms.crypt.elite_pools[0] + _data.realms.crypt.elite_pools[1]:
		assert_true(_data.encounters.has(enc_id), enc_id)


func test_family_count_counts_living_kin_but_not_self_or_others() -> void:
	var sim := _sim("crypt_3c")  # två Skelettkrigare och Skramlaren
	var rattler := _enemy(sim, "rattler")
	assert_eq(sim.family_count(rattler), 2)
	sim._kill(sim.enemies[0])
	assert_eq(sim.family_count(rattler), 1, "en fallen räknas inte")
	var priest := _enemy(_sim("crypt_1b"), "grave_priest")
	assert_eq(_sim("crypt_1b").family_count(priest), 0, "Gravprästen hör inte till Benfolket")


func test_flock_bite_grows_with_the_family_on_the_first_attack() -> void:
	var sim := _sim("crypt_2d")  # två Benspringare och en Bågskytt
	var runner := _enemy(sim, "bone_runner")
	var calc := _hit_calc(sim, runner, sim.unit("brokk"), "runner_bite")
	assert_near(_factor(calc, "Flockbett"), 1.5, 1e-9, "två andra ur Benfolket: +50 %")
	runner.attacks_done = 1
	calc = _hit_calc(sim, runner, sim.unit("brokk"), "runner_bite")
	assert_near(_factor(calc, "Flockbett"), 1.0, 1e-9, "bara det första anfallet")


func test_last_service_gives_the_family_a_barrier_when_the_bearer_falls() -> void:
	var sim := _sim("crypt_3d")  # Gravväktare och Kistbärare
	var bearer := _enemy(sim, "coffin_bearer")
	var warden := _enemy(sim, "grave_warden")
	var want := roundf(bearer.defense_now() * 0.5 * 1)
	sim._kill(bearer)
	assert_near(warden.barrier, want, 1e-9, "50 % av Defense per levande ur Benfolket")
	assert_true(warden.auras.has("barrier"))


func test_rattle_makes_the_rattler_and_one_kin_defensive() -> void:
	var sim := _sim("crypt_3c")
	var rattler := _enemy(sim, "rattler")
	_hit_calc(sim, sim.unit("paladin"), rattler, "attack")
	assert_true(rattler.auras.has("defensive"))
	assert_eq(sim.enemies.filter(func(e: CombatUnit) -> bool:
		return e != rattler and e.auras.has("defensive")).size(), 1, "och en annan ur Benfolket")


func test_bone_wall_and_growing_wrath_on_the_colossus() -> void:
	var sim := _sim("crypt_e1")  # Kolossens vakt
	var colossus := _enemy(sim, "bone_colossus")
	var calc := _hit_calc(sim, sim.unit("paladin"), colossus, "attack")
	assert_near(_factor(calc, "Benmur"), 0.95, 1e-9, "en annan ur Benfolket lever")
	var base := colossus.attack
	for i in 7:
		sim._turn_procs = 0
		sim._emit({"type": "turn_start", "unit": colossus.id})
	assert_near(colossus.attack, base * 1.5, 0.01, "+10 % av startvärdet, högst fem gånger")
	sim._choose_intent(colossus)
	assert_eq(colossus.intent.ability, "bone_storm", "efter tre gånger sveper den med Benstorm")


func test_noted_reduces_damage_from_the_same_source_and_ability() -> void:
	var sim := _sim("crypt_e4")  # Benskrivaren och Skramlaren
	var scribe := _enemy(sim, "bone_scribe")
	var p := sim.unit("paladin")
	assert_near(_factor(_hit_calc(sim, p, scribe, "attack"), "Antecknat"), 1.0, 1e-9)
	assert_near(_factor(_hit_calc(sim, p, scribe, "attack"), "Antecknat"), 0.75, 1e-9)
	assert_near(_factor(_hit_calc(sim, p, scribe, "attack"), "Antecknat"), 0.5, 1e-9)
	assert_near(_factor(_hit_calc(sim, p, scribe, "attack"), "Antecknat"), 0.5, 1e-9, "strid-langd: taket är 50 %")
	assert_near(_factor(_hit_calc(sim, sim.unit("brokk"), scribe, "attack"), "Antecknat"), 1.0, 1e-9,
			"en annan källa är ny")


func test_calling_shields_a_revived_ally() -> void:
	var sim := _sim("crypt_e2")
	var caller := _enemy(sim, "grave_caller")
	var warrior := _enemy(sim, "skeleton_warrior")
	sim._kill(warrior)
	sim._revive(warrior, 0.6)
	assert_near(warrior.barrier, minf(roundf(caller.intelligence), warrior.max_hp), 1e-9)


func test_new_picks_and_ignore_taunt() -> void:
	var sim := _sim("crypt_e3")
	var mist := _enemy(sim, "grave_mist")
	var top := sim.heroes[0]
	for h in sim.heroes:
		if h.stat("attack") > top.stat("attack"):
			top = h
	assert_eq(sim._pick_targets(mist, {"target": "enemy", "pick": "highest_attack"}), [top.id])
	var healer: Array = sim._pick_targets(mist, {"target": "enemy", "pick": "healer"})
	assert_true(sim.is_healer(sim.unit(healer[0])), "en hjälte som kan hela")
	sim._last_caster[0] = "eira"
	assert_eq(sim._pick_targets(mist, {"target": "enemy", "pick": "caster"}), ["eira"])
	sim._add_aura(sim.unit("brokk"), sim.unit("brokk"), "provoke")
	assert_eq(sim._pick_targets(mist, {"target": "enemy", "pick": "caster"}), ["brokk"], "provokationen styr")
	assert_eq(sim._pick_targets(mist, {"target": "enemy", "pick": "caster", "ignore_taunt": true}), ["eira"],
			"utom för en förmåga som går förbi den")


func test_family_and_alone_conditions() -> void:
	var sim := _sim("crypt_e5")  # Klockaren, Skelettkrigare, Benspringare
	var bell := _enemy(sim, "bell_ringer")
	assert_true(sim._rule_matches(bell, {"if": {"family_at_least": 2}}))
	assert_true(not sim._rule_matches(bell, {"if": {"alone": true}}))
	for e in sim.enemies:
		if e != bell:
			sim._kill(e)
	assert_true(not sim._rule_matches(bell, {"if": {"family_at_least": 1}}))
	assert_true(sim._rule_matches(bell, {"if": {"alone": true}}))


func test_bell_toll_moves_the_whole_family_to_the_top() -> void:
	var sim := _sim("crypt_e5")
	sim.begin()
	var bell := _enemy(sim, "bell_ringer")
	var kin := sim.enemies.filter(func(e: CombatUnit) -> bool: return e != bell).map(func(e: CombatUnit) -> String: return e.id)
	sim._apply_effects(bell, "bell_toll", [bell.id])
	var front: Array = sim.order.slice(0, kin.size())
	for id in kin:
		var on_turn: bool = sim.current != null and sim.current.id == id and sim.current.next_slot == "top"
		assert_true(front.has(id) or on_turn, "%s står överst (eller kommer först igen efter sin tur)" % id)


func test_counters_follow_the_rule_one_per_group_elite_only_and_by_depth() -> void:
	assert_eq(CombatSim.counter_for(_data, "crypt_e5", 1, {}, 4), {}, "inget motdrag utanför elit och boss")
	assert_eq(CombatSim.counter_for(_data, "crypt_e5", 1, {"counter": true}, 4).get("trait"), "last_chime")
	assert_eq(CombatSim.counter_for(_data, "crypt_e3", 1, {"counter": true}, 4), {}, "Gravdimmans från djup 2")
	assert_eq(CombatSim.counter_for(_data, "crypt_e3", 2, {"counter": true}, 4).get("trait"), "mist_weight")
	assert_eq(CombatSim.counter_for(_data, "crypt_e6", 2, {"counter": true, "force_elites": 1}, 4), {},
			"Likbärarens från djup 3")
	assert_eq(CombatSim.counter_for(_data, "crypt_e6", 3, {"counter": true, "force_elites": 1}, 4).get("trait"),
			"pallbearer_wrath")
	var sim := _sim("crypt_e5", {"counter": true, "force_elites": 1})
	assert_eq(sim.enemies.filter(func(e: CombatUnit) -> bool: return e.counter != "").size(), 1, "högst ett per grupp")
	assert_eq(_sim("crypt_e5").enemies.filter(func(e: CombatUnit) -> bool: return e.counter != "").size(), 0)


func test_last_chime_allows_only_one_revive_per_battle() -> void:
	var sim := _sim("crypt_e5", {"counter": true})
	var a := sim.unit("alva")
	var b := sim.unit("brokk")
	sim._kill(a)
	sim._kill(b)
	sim._revive(a, 0.5)
	sim._revive(b, 0.5)
	assert_true(a.alive, "den första väckningen går")
	assert_true(not b.alive, "den andra stoppas")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "revive_blocked"))


func test_mist_weight_dulls_the_party_after_a_spell() -> void:
	var sim := _sim("crypt_e3", {"counter": true}, 2)
	var p := sim.unit("paladin")
	var before := p.stat("intelligence")
	sim._emit({"type": "acted", "unit": "alva", "action": "ability", "ability": "x", "targets": [], "ability_kind": "spell"})
	assert_true(p.auras.has("dulled"))
	assert_near(p.stat("intelligence"), before * 0.8, 1e-6)


func test_pallbearer_wrath_strikes_three_times_when_it_falls() -> void:
	var sim := _sim("crypt_e6", {"counter": true, "force_elites": 1}, 3)
	var bearer := _enemy(sim, "coffin_bearer")
	assert_eq(bearer.name, "Likbärare")
	assert_eq(bearer.counter, "pallbearer_wrath")
	sim.drain_events()
	sim._kill(bearer)
	var swings := sim.drain_events().filter(func(e: Dictionary) -> bool:
		return e.type in ["damage", "dodge"] and e.get("source", "") == bearer.id and e.get("ability", "") == "pallbearer_wrath")
	assert_eq(swings.size(), 3)


func test_the_grotto_takes_elites_from_the_elite_pools() -> void:
	var r: Dictionary = _data.realms.crypt
	for seed_value in range(1, 40):
		var floor_i := seed_value % 2
		var g := Grotto.generate(seed_value, floor_i, floor_i == 1, r.pools, r.floors[2], r.floors[floor_i],
				{"type": "clear", "goal": 2}, {}, r.elite_pools)
		for i in g.indices("elite"):
			assert_true(r.elite_pools[floor_i].has(g.cells[i].encounter), "eliten kommer ur våningens elitpool")
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.fill_charges(_data)
	s.start_expedition(_data, 5)
	s.pos = s.map.indices("elite")[0]
	assert_true(s.battle_opts().get("counter", false), "elitrutan slår på motdrag")
	assert_eq(s.map.cells[s.pos].encounter, "crypt_e1", "första våningens elit är Kolossens vakt")


## 0.30.19: våning 1:s elitgrupp är mildare för ett sällskap med högst två hjältar (svårighetskurvan).
func test_small_party_meets_a_milder_first_floor_elite() -> void:
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.party.assign(["paladin", "imma"])
	s.fill_charges(_data)
	s.start_expedition(_data, 5)
	s.first_descent = false
	s.pos = s.map.indices("elite")[0]
	assert_near(float(s.battle_opts().get("stat_bonus", 1.0)), RunState.SMALL_PARTY_ELITE, 1e-6)
	s.party.assign(["paladin", "imma", "alva"])
	assert_near(float(s.battle_opts().get("stat_bonus", 1.0)), 1.0, 1e-6, "tre hjältar möter eliten som vanligt")


## 0.30.21 (VD): den som äger fyra hjältar och går med färre möter fiender som mot fyra.
func test_owning_four_heroes_means_full_strength_enemies() -> void:
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.party.assign(["paladin", "imma"])
	s.fill_charges(_data)
	s.start_expedition(_data, 5)
	s.first_descent = false
	s.pos = s.map.indices("elite")[0]
	s.owned_heroes = 4
	var opts := s.battle_opts()
	assert_eq(opts.get("full_party", 0), 4, "fiender som mot fyra")
	assert_near(float(opts.get("stat_bonus", 1.0)), 1.0, 1e-6, "ingen mildring för små sällskap")
	var full := CombatSim.create(_data, "crypt_1", 3, ["paladin", "imma"], {}, {}, {}, 1, {"full_party": true})
	var small := CombatSim.create(_data, "crypt_1", 3, ["paladin", "imma"], {}, {}, {}, 1, {})
	assert_true(full.enemies.size() >= small.enemies.size(), "lika många fiender som mot fyra")
	assert_true(full.enemies[0].max_hp > small.enemies[0].max_hp, "fullstarka fiender")



## 0.31 (docs/plan/drakvalvet-fiender.md §1): Likätaren äter liken ur Benfolket, helar sig och växer; det uppätna kan
## aldrig väckas. Gravgnagaren (elitvarianten) äter aldrig hjältar. Benvargen har en egen figur.
func test_ghoul_feast_heals_consumes_and_blocks_revive() -> void:
	var sim := _sim("crypt_2g")
	var ghoul := _enemy(sim, "ghoul")
	var warrior := _enemy(sim, "skeleton_warrior")
	var rule: Dictionary = ghoul.rules[0]
	assert_true(not sim._rule_matches(ghoul, rule), "inget lik: ingen måltid")
	sim._kill(warrior, sim.unit("brokk"))
	assert_true(sim._rule_matches(ghoul, rule), "ett lik ur Benfolket")
	ghoul.hp = 10.0
	sim.drain_events()
	sim._perform(ghoul, "corpse_feast", "intent", "")
	assert_true(warrior.consumed, "liket är uppätet")
	assert_near(ghoul.hp, 10.0 + roundf(ghoul.max_hp * 0.35), 1.0, "Likmåltid helar 35 % av max liv")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "corpse_consumed" and e.by == ghoul.id))
	sim._revive(warrior, 0.6)
	assert_true(not warrior.alive, "liket kan inte väckas")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "revive_blocked" and e.get("consumed", false)))
	assert_true(sim._pick_targets(ghoul, {"target": "dead_ally"}).is_empty(), "ett uppätet lik går inte att välja")
	assert_true(not sim._rule_matches(ghoul, rule), "och kan inte ätas igen")
	# Gravpakt räknar fortfarande det uppätna som fallet.
	assert_eq(sim._dead_allies(ghoul), 1)


func test_ghoul_eats_only_its_own_family_and_never_heroes() -> void:
	var sim := _sim("crypt_e7")  # Gravväckaren, Likätare, Skelettkrigare ×2
	var ghoul := _enemy(sim, "ghoul")
	sim._kill(_enemy(sim, "grave_caller"))
	assert_true(not sim._rule_matches(ghoul, ghoul.rules[0]), "Gravväckaren hör inte till Benfolket")
	sim._kill(sim.unit("alva"))
	assert_true(not sim._rule_matches(ghoul, ghoul.rules[0]), "en fallen hjälte äts aldrig")
	# Elitvarianten Gravgnagaren: samma regel, och dess egen egenskap räknar fallna hjältar men äter dem inte.
	var elite := _sim("crypt_2g", {"force_elites": 1})
	var gnawer := _enemy(elite, "ghoul")
	assert_eq(gnawer.name, "Gravgnagaren")
	assert_true(gnawer.traits.has("gnawer_chain"))
	var atk := gnawer.attack
	elite._kill(elite.unit("eira"), gnawer)
	assert_true(not elite.unit("eira").consumed, "hjälten är inte uppäten")
	assert_near(gnawer.attack, atk + float(gnawer.base_stats.attack) * 0.08, 1e-6, "+8 % Attack när en hjälte faller")


func test_grave_hunger_stacks_at_most_three_times() -> void:
	var sim := _sim("crypt_3e")
	var ghoul := _enemy(sim, "ghoul")
	var base: float = ghoul.base_stats.attack
	for i in 5:
		sim._emit({"type": "corpse_consumed", "unit": "x", "by": ghoul.id})
	assert_near(ghoul.attack, base * 1.6, 1e-6, "högst 3 gånger +20 %")
	sim._emit({"type": "corpse_consumed", "unit": "x", "by": "skeleton_warrior_9"})
	assert_near(ghoul.attack, base * 1.6, 1e-6, "bara egna måltider")


func test_ghoul_trophy_and_the_bone_wolf() -> void:
	# Den brutna gravspaden: den bäraren fäller kan inte väckas, och bäraren helas 10 %.
	var sim := CombatSim.create(_data, "crypt_e2", 3, ["paladin", "brokk", "alva", "eira"], {"brokk": ["ghoul_spade"]})
	var brokk := sim.unit("brokk")
	var warrior := _enemy(sim, "skeleton_warrior")
	brokk.hp = 20.0
	sim._kill(warrior, brokk)
	assert_true(warrior.consumed, "den fällde är uppäten")
	assert_true(brokk.hp > 20.0, "bäraren helas")
	sim._revive(warrior, 0.6)
	assert_true(not warrior.alive, "Gravväckaren kan inte väcka den")
	var other := _enemy(sim, "skeleton_archer")
	sim._kill(other, sim.unit("eira"))
	assert_true(not other.consumed, "bara bärarens egna")
	# Benvargen (Benspringarens elitvariant) är en varg med benfärg.
	var wolf: Dictionary = _data.enemies.bone_runner.elite.visual
	assert_eq(wolf.model, "varg")
	assert_true(wolf.colors.has("Varg_Main"))
	assert_true(ResourceLoader.exists("res://assets/models/varg.glb"))
	for enc in ["crypt_2g", "crypt_3e"]:
		assert_true(_data.realms.crypt.pools[1].has(enc) or _data.realms.crypt.pools[2].has(enc), enc)
	assert_true(_data.realms.crypt.elite_pools[1].has("crypt_e7"))
	assert_true(_data.encounters.crypt_e7.elite_group)
