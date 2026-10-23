extends "res://tests/test_case.gd"
## 0.28 steg 3 (docs/plan/0.27-fiender.md §2): kapellets nya fiender, familjerna Kultens folk och De fallna, motdragen
## (Ordensregeln, Skrattande låga), troféerna och elitgrupperna.

const Audit := preload("res://tests/numbers_audit.gd")

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


func test_new_chapel_enemies_have_data_trophies_and_traits() -> void:
	for kind in ["corrupted_deacon", "banner_bearer", "will_o_wisp", "mirror_warden", "cult_overseer", "inquisitor",
			"ascetic", "black_lance", "corrupted_abbess"]:
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
			assert_true(_data.traits[d.elite.trophy].has("answers"))
		if d.has("counter"):
			assert_true(_data.traits[d.counter.trait].get("counter", false), "%s: motdraget är märkt" % kind)
	var chapel: Dictionary = _data.realms.chapel
	for enc_id in chapel.elite_pools[0] + chapel.elite_pools[1] + chapel.pools[1] + chapel.pools[2]:
		assert_true(_data.encounters.has(enc_id), enc_id)
	assert_eq(chapel.elite_pools[0], ["chapel_e1"], "våning 1 har bara Lansens anstormning")
	assert_eq(chapel.pools[0], ["chapel_1a", "chapel_1b", "chapel_1c"], "tier 0 är orörd")


func test_two_families_count_their_own_kin() -> void:
	var sim := _sim("chapel_e5")  # Lansen, Fallen riddare, Häxa, Kultist
	var lance := _enemy(sim, "black_lance")
	var witch := _enemy(sim, "witch")
	assert_eq(sim.family_count(lance), 1, "Fallen riddare hör till De fallna")
	assert_eq(sim.family_count(witch), 1, "Kultisten hör till Kultens folk")
	assert_eq(_enemy(_sim("chapel_e1"), "will_o_wisp").family, "", "Irrblossen hör inte till någon familj")


func test_clouded_blessing_gives_mending_to_the_cult_only() -> void:
	var sim := _sim("chapel_e2")  # Förmannen, Kultist, Diakon
	var deacon := _enemy(sim, "corrupted_deacon")
	var cultist := _enemy(sim, "cultist")
	cultist.hp = 5.0
	sim._heal(deacon, cultist, 5.0, "deacon_heal")
	assert_true(cultist.auras.has("mending"), "en ur kulten får Läkning")
	deacon.hp = 5.0
	sim._heal(deacon, deacon, 5.0, "deacon_heal")
	assert_true(not deacon.auras.has("mending"), "inte diakonen själv")


func test_cult_banner_grows_with_the_cult_and_ends_with_the_bearer() -> void:
	var sim := _sim("chapel_2f")  # Fanbäraren, Kultist, Häxa
	var banner := _enemy(sim, "banner_bearer")
	var cultist := _enemy(sim, "cultist")
	var calc := _hit_calc(sim, cultist, sim.unit("brokk"), "cultist_knife")
	assert_near(_factor(calc, "Kultens fana"), 1.1, 1e-9, "två andra ur kulten: +10 %")
	calc = _hit_calc(sim, sim.unit("brokk"), cultist, "x")
	assert_near(_factor(calc, "Kultens fana"), 1.0, 1e-9, "inte hjältarna")
	sim._kill(banner)
	calc = _hit_calc(sim, cultist, sim.unit("brokk"), "cultist_knife")
	assert_near(_factor(calc, "Kultens fana"), 1.0, 1e-9, "fanan faller med bäraren")


func test_wisps_start_first_and_blind_with_the_first_hit() -> void:
	var sim := _sim("chapel_e1")
	sim.begin()
	var first: Array = sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "turn_start")
	assert_eq(sim.unit(first[0].unit).kind, "will_o_wisp", "ett Irrbloss börjar överst")
	sim = _sim("chapel_e1")
	var wisp := _enemy(sim, "will_o_wisp")
	var brokk := sim.unit("brokk")
	_hit_calc(sim, wisp, brokk, "wisp_spark", "spell")
	assert_true(brokk.auras.has("blind"), "första träffen förblindar")
	var alva := sim.unit("alva")
	_hit_calc(sim, wisp, alva, "wisp_spark", "spell")
	assert_true(not alva.auras.has("blind"), "bara den första")


func test_mirror_ward_reflects_spells_more_with_the_fallen() -> void:
	var sim := _sim("chapel_2g")  # Spegelvakten och en Häxa (kulten)
	var warden := _enemy(sim, "mirror_warden")
	var alva := sim.unit("alva")
	for pct in [0.4, 0.5]:
		if pct == 0.5:
			_enemy(sim, "witch").family = "fallen_kin"
		sim.drain_events()
		sim._deal_damage(alva, warden, 1.0, "holy", "x", false, true, "spell", true)
		var events := sim.drain_events()
		var hit: Array = events.filter(func(e: Dictionary) -> bool: return e.type == "damage" and e.target == warden.id)
		var back: Array = events.filter(func(e: Dictionary) -> bool:
			return e.type == "damage" and e.source == warden.id and e.ability == "mirror_ward")
		assert_eq(back.size(), 1, "besvärjelsen studsar")
		assert_near(float(back[0].calc.amount_in), float(hit[0].amount) * pct, 1e-6, "%d %%" % roundi(pct * 100))
	sim.drain_events()
	_hit_calc(sim, alva, warden, "x", "attack")
	assert_true(not sim.drain_events().any(func(e: Dictionary) -> bool: return e.get("ability", "") == "mirror_ward"),
			"anfall slipper")


func test_overseer_takes_half_of_the_damage_to_the_cult() -> void:
	var sim := _sim("chapel_e2")
	var overseer := _enemy(sim, "cult_overseer")
	var cultist := _enemy(sim, "cultist")
	var before := overseer.hp
	var calc := _hit_calc(sim, sim.unit("eira"), cultist, "x")
	var total := float(calc.total) + float(calc.guarded)
	assert_eq(float(calc.guarded), roundf(total * 0.5), "hälften av den färdiga skadan")
	assert_near(overseer.hp, before - float(calc.guarded), 1e-9, "förmannen tar sin del")
	assert_true(DamageExplain.lines(sim.data, {"type": "damage", "calc": calc, "kind": "attack"}).any(
			func(l: String) -> bool: return l.find("som livvakt") >= 0), "skadeloggen visar det")
	calc = _hit_calc(sim, sim.unit("eira"), overseer, "x")
	assert_true(not calc.has("guarded"), "inte när förmannen själv träffas")
	sim._kill(overseer)
	calc = _hit_calc(sim, sim.unit("eira"), cultist, "x")
	assert_true(not calc.has("guarded"), "inte när förmannen har fallit")


func test_interrogation_silences_a_hero_who_repeats_an_ability() -> void:
	var sim := _sim("chapel_e3")
	var alva := sim.unit("alva")
	alva.prev_ability = "healing_light"
	sim._emit({"type": "acted", "unit": "alva", "action": "ability", "ability": "healing_light", "targets": []})
	assert_true(alva.auras.has("silenced"), "samma förmåga två gånger: Tystad")
	var eira := sim.unit("eira")
	eira.prev_ability = eira.attack_ability
	sim._emit({"type": "acted", "unit": "eira", "action": "attack", "ability": eira.attack_ability, "targets": []})
	assert_true(not eira.auras.has("silenced"), "grundanfallet räknas inte")
	var brokk := sim.unit("brokk")
	brokk.prev_ability = "x"
	sim._emit({"type": "acted", "unit": "brokk", "action": "ability", "ability": "y", "targets": []})
	assert_true(not brokk.auras.has("silenced"), "en ny förmåga går fri")


func test_fasting_raises_defense_more_with_the_fallen() -> void:
	var sim := _sim("chapel_e4")  # Asketen, Fallen riddare, Kultist
	var ascetic := _enemy(sim, "ascetic")
	var base := ascetic.defense
	sim._emit({"type": "turn_start", "unit": ascetic.id})
	assert_near(ascetic.defense, base * (1.0 + 0.08 + 0.04), 1e-6, "+8 % och +4 % för Fallen riddare")
	for i in 6:
		sim._emit({"type": "turn_start", "unit": ascetic.id})
	assert_near(ascetic.defense, base * (1.0 + 5 * 0.12), 1e-6, "högst fem gånger")


func test_black_lance_charges_then_braces_every_other_turn_and_avenges_the_fallen() -> void:
	var sim := _sim("chapel_e5")
	var lance := _enemy(sim, "black_lance")
	var calc := _hit_calc(sim, lance, sim.unit("brokk"), "lance_thrust")
	assert_near(_factor(calc, "Anstormning"), 3.0, 1e-9, "första anfallet +200 %")
	lance.last_ability = lance.attack_ability
	sim._choose_intent(lance)
	assert_eq(lance.intent.ability, "lance_brace", "efter ett anfall försvarar den sig")
	lance.last_ability = "lance_brace"
	sim._choose_intent(lance)
	assert_eq(lance.intent.ability, lance.attack_ability, "sedan anfaller den igen")
	sim._kill(_enemy(sim, "cultist"))
	assert_true(not lance.auras.has("berserk"), "en ur kulten är inte De fallna")
	sim._kill(_enemy(sim, "fallen_knight"))
	assert_true(lance.auras.has("berserk"), "Bruten ed: Bärsärk")


func test_abbess_mass_heals_and_purges_her_allies() -> void:
	var sim := _sim("chapel_e6")
	var abbess := _enemy(sim, "corrupted_abbess")
	var cultist := _enemy(sim, "cultist")
	cultist.hp = 1.0
	sim._add_aura(sim.unit("paladin"), cultist, "weak")
	sim._apply_effects(abbess, "abbess_mass", [abbess.id, cultist.id])
	assert_near(cultist.hp, 1.0 + roundf(cultist.max_hp * 0.3), 1e-9, "30 % av sitt liv")
	assert_true(not cultist.auras.has("weak"), "renad")


func test_counters_by_depth_and_only_one_wisp_carries_it() -> void:
	assert_eq(CombatSim.counter_for(_data, "chapel_e6", 1, {"counter": true}, 4).get("trait"), "order_rule",
			"Abbedissans från första mötet")
	assert_eq(CombatSim.counter_for(_data, "chapel_e6", 1, {}, 4), {}, "bara i elit- och bossrutor")
	assert_eq(CombatSim.counter_for(_data, "chapel_e1", 2, {"counter": true}, 4), {}, "Irrblossets från djup 3")
	var sim := _sim("chapel_e1", {"counter": true}, 3)
	var carriers := sim.enemies.filter(func(e: CombatUnit) -> bool: return e.counter != "")
	assert_eq(carriers.size(), 1, "bara det ena Irrblosset")
	assert_eq(carriers[0].counter, "laughing_wisp")


func test_order_rule_lets_the_party_be_healed_once_per_turn() -> void:
	var sim := _sim("chapel_e6", {"counter": true})
	var brokk := sim.unit("brokk")
	var alva := sim.unit("alva")
	brokk.hp = 10.0
	alva.hp = 10.0
	sim._heal(alva, brokk, 5.0, "healing_light")
	sim._heal(alva, alva, 5.0, "healing_light")
	assert_near(brokk.hp, 15.0, 1e-9, "den första helningen går")
	assert_near(alva.hp, 10.0, 1e-9, "den andra stoppas")
	assert_true(sim.drain_events().any(func(e: Dictionary) -> bool: return e.type == "heal_blocked"))
	var cultist := _enemy(sim, "cultist")
	cultist.hp = 5.0
	sim._heal(cultist, cultist, 3.0, "x")
	assert_near(cultist.hp, 8.0, 1e-9, "fienderna helas som vanligt")
	sim.begin()
	assert_true(int(sim._team_heals.get(0, 0)) <= 1, "räkningen börjar om varje tur")


func test_laughing_wisp_ignores_debuffs_and_drops_when_hit() -> void:
	var sim := _sim("chapel_e1", {"counter": true}, 3)
	var wisp: CombatUnit = sim.enemies.filter(func(e: CombatUnit) -> bool: return e.counter != "")[0]
	sim.begin()
	sim._add_aura(sim.unit("alva"), wisp, "blind")
	assert_true(not wisp.auras.has("blind"), "inga debuffar")
	sim.drain_events()
	_hit_calc(sim, sim.unit("eira"), wisp, "x")
	assert_true(sim.order.is_empty() or sim.order[-1] == wisp.id or not wisp.alive or sim.current == wisp,
			"längst ned på tidslinjen")


func test_chapel_trophies() -> void:
	# Lansspetsen: första Anfallet struntar i Defense.
	var sim := CombatSim.create(_data, "chapel_e4", 3, ["paladin", "brokk", "alva", "eira"], {"eira": ["lance_tip"]})
	var ascetic := _enemy(sim, "ascetic")
	var calc := _hit_calc(sim, sim.unit("eira"), ascetic, sim.unit("eira").attack_ability)
	assert_eq(float(calc.defense), 0.0, "Defense räknas inte")
	sim.unit("eira").attacks_done = 1
	calc = _hit_calc(sim, sim.unit("eira"), ascetic, sim.unit("eira").attack_ability)
	assert_true(float(calc.defense) > 0.0, "bara det första")
	# Den trasiga fanan: hela sällskapet +8 %.
	sim = CombatSim.create(_data, "chapel_1a", 3, ["paladin", "brokk", "alva", "eira"], {"brokk": ["torn_banner"]})
	calc = _hit_calc(sim, sim.unit("eira"), sim.enemies[0], "x")
	assert_near(_factor(calc, "Den trasiga fanan"), 1.08, 1e-9)
	# Abbedissans nyckel: renar, men helar 20 % mindre.
	sim = CombatSim.create(_data, "chapel_1a", 3, ["paladin", "brokk", "alva", "eira"], {"alva": ["abbess_key"]})
	var brokk := sim.unit("brokk")
	brokk.hp = 10.0
	sim._add_aura(sim.enemies[0], brokk, "weak")
	sim._heal(sim.unit("alva"), brokk, 10.0, "healing_light")
	assert_near(brokk.hp, 18.0, 1e-9, "−20 %")
	assert_true(not brokk.auras.has("weak"), "renad")
	# Irrblossets låga: undviker tills bäraren har agerat.
	sim = CombatSim.create(_data, "chapel_1a", 3, ["paladin", "brokk", "alva", "eira"], {"brokk": ["wisp_flame"]})
	var bearer := sim.unit("brokk")
	var probe := {"source": sim.enemies[0].id, "target": "brokk", "kind": "attack", "direct": true}
	var before := sim._dodge_for(sim.enemies[0], bearer, 1.0, probe)
	bearer.last_ability = "defend"
	assert_near(before - sim._dodge_for(sim.enemies[0], bearer, 1.0, probe), 0.3, 1e-9)


func test_the_grotto_takes_chapel_elites_from_the_elite_pools() -> void:
	var r: Dictionary = _data.realms.chapel
	for seed_value in range(1, 40):
		var floor_i := seed_value % 2
		var g := Grotto.generate(seed_value, floor_i, floor_i == 1, r.pools, r.floors[2], r.floors[floor_i],
				{"type": "clear", "goal": 2}, {}, r.elite_pools)
		for i in g.indices("elite"):
			assert_true(r.elite_pools[floor_i].has(g.cells[i].encounter), "eliten kommer ur våningens elitpool")
	var s := RunState.new()
	s.set_realm(_data, "chapel")
	s.fill_charges(_data)
	s.start_expedition(_data, 5)
	s.pos = s.map.indices("elite")[0]
	assert_eq(s.map.cells[s.pos].encounter, "chapel_e1", "första våningens elit är Lansens anstormning")


## Granskningen av siffrorna i kapellets elitgrupper, med motdragen på (djup 1 och 3).
func test_numbers_audit_in_the_chapel_elite_groups() -> void:
	var audit := Audit.new(_data)
	var parties := [["paladin", "brokk", "alva", "eira"], ["paladin", "imma"], ["paladin", "imma", "solveig", "hulda"]]
	var i := 0
	for enc_id in _data.realms.chapel.elite_pools[0] + _data.realms.chapel.elite_pools[1]:
		for depth in [1, 3]:
			audit.run_battle(enc_id, 1, depth, 11 + i, parties[i % parties.size()], {}, i % 2 == 0, [],
					5 * (depth - 1) + 3, {}, 1.0, {"counter": true})
			i += 1
	assert_eq(audit.mismatches, [], "inga avvikelser")
	assert_true(audit.counts.damage > 100)


## 0.29.4: Ragnhilds Sanningens ljus med nåd – när en fiende helas bränns den, och den svagaste i sällskapet helas.
func test_ragnhild_grace() -> void:
	var sim := CombatSim.create(_data, "chapel_1a", 3, ["paladin", "brokk", "ragnhild", "eira"])
	var brokk := sim.unit("brokk")
	brokk.hp = 5.0
	var foe: CombatUnit = sim.enemies[0]
	foe.hp = foe.max_hp * 0.5
	var before := foe.hp
	sim._heal(foe, foe, 5.0, "x")
	assert_true(foe.hp < before + 5.0, "ljuset brände fienden")
	var grace := sim.unit("ragnhild").stat("intelligence") * 0.12
	assert_true(brokk.hp > 5.0, "den svagaste helades")
	assert_near(brokk.hp, 5.0 + roundf(grace), 1.0, "med 12 % av Ragnhilds Intelligence")


## 0.30.19: den som försvarar sig vid lågt liv gör det varannan tur (karriärens dödläge mot Asketen, frö 30).
func test_low_health_defenders_alternate_with_attacks() -> void:
	var sim := _sim("chapel_e4", {}, 2)
	var asc := _enemy(sim, "ascetic")
	asc.hp = asc.max_hp * 0.1
	asc.last_ability = asc.attack_ability
	sim._choose_intent(asc)
	assert_eq(asc.intent.ability, "defend", "efter ett anfall försvarar hen sig")
	asc.last_ability = "defend"
	sim._choose_intent(asc)
	assert_eq(asc.intent.ability, asc.attack_ability, "efter att ha försvarat sig anfaller hen")
