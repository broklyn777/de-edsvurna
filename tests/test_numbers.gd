extends "res://tests/test_case.gd"
## 0.21 "Siffrorna stämmer": egenskapstester för formlerna, modifierarna, stat-källorna och uträkningen.

var _data := GameData.load_all()


# --- Formlerna -----------------------------------------------------------------

func test_more_defense_never_means_more_damage() -> void:
	for atk in [20.0, 80.0, 150.0, 400.0, 1200.0]:
		for power in [0.5, 1.0, 1.6]:
			var last_a := INF
			var last_s := INF
			var last_i := INF
			for def in range(0, 600, 7):
				var a := CombatSim.attack_damage(atk, def, power)
				var s := CombatSim.spell_damage(atk, def, power, 0.2)
				var i := CombatSim.indirect_damage(atk * power, def)
				assert_true(a <= last_a and s <= last_s and i <= last_i, "Attack %d, Defense %d" % [atk, def])
				last_a = a
				last_s = s
				last_i = i


func test_more_attack_or_intelligence_never_means_less_damage() -> void:
	for def in [0.0, 30.0, 120.0, 500.0]:
		var last_a := -1.0
		var last_s := -1.0
		for atk in range(1, 900, 11):
			var a := CombatSim.attack_damage(atk, def, 1.2)
			var s := CombatSim.spell_damage(atk, def, 1.2)
			assert_true(a >= last_a and s >= last_s, "Attack/Int %d mot Defense %d" % [atk, def])
			last_a = a
			last_s = s
	# Även när Defense är högre än Attack ger mer Attack lite mer (1 % av Attack går alltid igenom).
	assert_true(CombatSim.attack_damage(60, 200) > CombatSim.attack_damage(50, 200))


func test_each_modifier_gives_exactly_its_percent() -> void:
	assert_near(CombatSim.combine_mods([1.3]), 1.3, 1e-9)
	assert_near(CombatSim.combine_mods([0.65]), 0.65, 1e-9)
	assert_near(CombatSim.combine_mods([1.5, 1.5]), 2.0, 1e-9, "ökningar adderas")
	assert_near(CombatSim.combine_mods([0.5, 0.5]), 0.25, 1e-9, "minskningar multipliceras")
	assert_near(CombatSim.combine_mods([1.5, 0.65]), 1.5 * 0.65, 1e-9)
	assert_near(CombatSim.combine_mods([0.05]), 0.2, 1e-9, "en minskning stannar vid 80 %")


## Samma träff med och utan en aura (samma frö, så att variationen blir densamma): kvoten är aurans procent.
func _hit(aura_on_target: String, aura_on_source := "", ability := "attack") -> Dictionary:
	var sim := CombatSim.create(_data, "crypt_1", 9, ["paladin"], {}, {}, {}, 1, {"elite_chance": 0.0})
	var src := sim.unit("paladin")
	var tgt := sim.enemies[0]
	src.speed = tgt.speed  # inget undvikande
	if aura_on_target != "":
		sim._add_aura(src, tgt, aura_on_target)
	if aura_on_source != "":
		sim._add_aura(src, src, aura_on_source)
	sim.drain_events()
	sim._deal_damage(src, tgt, 1.0, "physical", ability, false, true, "attack", true)
	for e in sim.drain_events():
		if e.type == "damage":
			return e
	return {}


func test_auras_change_damage_by_their_percent() -> void:
	# Skelettkrigaren har Benrustning (−30 % från attacker); en ökning adderas, en minskning multipliceras.
	var plain := _hit("")
	var raw: float = plain.calc.raw
	var base: float = plain.calc.mod_total
	assert_near(base, 0.7, 1e-9, "Benrustning −30 %")
	assert_near(_hit("vulnerable").calc.mod_total / base, 1.5, 1e-9, "Sårbar +50 %")
	assert_near(_hit("marked").calc.mod_total / base, 1.2, 1e-9, "Märkt +20 %")
	assert_near(_hit("", "weak").calc.mod_total / base, 0.5, 1e-9, "Försvagad −50 %")
	assert_near(_hit("vulnerable").calc.raw, raw, 1e-6, "samma grundskada med samma frö")
	var defend := _hit("defend")
	assert_near(defend.calc.mod_total / base, 0.65, 1e-9, "Försvara −35 % skada")
	assert_near(defend.calc.defense, defend.calc.defense_base * 1.5, 1e-6, "Försvara +50 % Defense")
	var provoke := _hit("provoke")
	assert_near(provoke.calc.defense, provoke.calc.defense_base * 0.65, 1e-6, "Provocera −35 % Defense")


func test_defense_now_and_stat_agree() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 2, ["brokk"])
	var b := sim.unit("brokk")
	sim._add_aura(b, b, "defend")
	assert_near(b.defense_now(), b.defense * 1.5, 1e-6)
	assert_near(b.stat("defense"), b.defense_now(), 1e-6, "egenskaper och makron läser samma Defense")
	sim._add_aura(b, b, "salted")
	assert_near(b.defense_now(), b.defense * 1.5 * 0.8, 1e-6, "Saltad jord −20 %")


# --- Stat-källorna når striden ---------------------------------------------------

func test_every_stat_source_reaches_combat() -> void:
	var art := {"type": "shield", "ability": "", "level": 9, "stat_slots": ["amber_grey", "amber_teal", "amber_grey"],
			"trick_slots": ["", ""], "nether": {"id": "x", "rarity": "magic", "number": 100,
			"affixes": [{"kind": "stat", "stat": "defense", "pct": 0.1, "q": 1.0}]}}
	var levels := {"brokk": {"level": 6, "personality": "stadig"}}
	var with_all := CombatSim.create(_data, "crypt_1", 1, ["brokk"], {}, {}, {"brokk": art}, 1, {"levels": levels})
	var b := HeroStats.breakdown(_data, "brokk", 6, "stadig", art)
	var u := with_all.unit("brokk")
	assert_near(u.defense, b.defense.total, 1e-6)
	assert_true(b.defense.levels > 0.0 and b.defense.personality > 0.0 and b.defense.artifact > 0.0
			and b.defense.material > 0.0 and b.defense.nether > 0.0, "alla källor bidrar")
	var plain := CombatSim.create(_data, "crypt_1", 1, ["brokk"], {}, {}, {}, 1, {"levels": {"brokk": {"level": 1}}})
	assert_true(u.defense > plain.unit("brokk").defense * 2.0)


func test_amber_defense_means_less_damage_in_a_real_battle() -> void:
	var per_hit := {}
	for with_amber in [false, true]:
		var taken := 0.0
		var hits := 0
		for s in 40:
			var art := {"type": "shield", "ability": "", "level": 9,
					"stat_slots": ["amber_grey", "amber_grey", "amber_grey"] if with_amber else ["", "", ""]}
			var sim := CombatSim.create(_data, "crypt_2", s, ["paladin", "brokk", "alva", "eira"], {}, {}, {"brokk": art}, 1,
					{"elite_chance": 0.0})
			sim.begin()
			var guard := 0
			while sim.outcome == "" and guard < 300:
				guard += 1
				if sim.needs_input():
					sim.act("provoke" if sim.current.id == "brokk" else "attack",
							sim.default_target(sim.current, "attack"), "")
				else:
					sim.ai_act()
				for e in sim.drain_events():
					if e.type == "damage" and e.target == "brokk" and e.get("direct", false) and not e.crit \
							and e.calc.get("kind", "") == "attack":
						taken += float(e.calc.total)
						hits += 1
		per_hit[with_amber] = taken / maxi(hits, 1)
	assert_true(per_hit[true] < per_hit[false] * 0.97,
			"tre Järngrå bärnsten på nivå 9 (+28 %% Defense) syns i skadan: %d mot %d per träff" % [per_hit[true], per_hit[false]])


# --- Hjältebladet och uträkningen ----------------------------------------------

func test_the_sheet_matches_the_simulator_average() -> void:
	var levels := {"eira": {"level": 4, "personality": "rastlos"}}
	var sim := CombatSim.create(_data, "crypt_1", 3, ["eira"], {}, {}, {}, 1, {"levels": levels, "elite_chance": 0.0})
	var eira := sim.unit("eira")
	var tgt := sim.enemies[0]
	eira.speed = tgt.speed
	var expected := sim.expected_damage(eira, tgt, eira.attack_ability)
	var sum := 0.0
	var n := 0
	for i in 400:
		tgt.hp = tgt.max_hp
		sim._deal_damage(eira, tgt, _power(eira.attack_ability), "physical", eira.attack_ability, false, false, "attack", true)
		for e in sim.drain_events():
			if e.type == "damage":
				sum += float(e.calc.total)
				n += 1
	var mean := sum / n
	assert_near(mean, expected, expected * CombatSim.VARIANCE * 0.25, "medel %d mot bladets %d" % [mean, expected])


func _power(ability_id: String) -> float:
	for eff in _data.abilities.get(ability_id, {}).get("effects", []):
		if eff.type == "damage":
			return float(eff.get("power", 1.0))
	return 1.0


func test_the_explanation_ends_with_the_number_shown() -> void:
	var seen := 0
	for s in 6:
		var sim := CombatSim.create(_data, "chapel_2", s, ["paladin", "brokk", "alva", "eira"])
		sim.begin()
		var guard := 0
		while sim.outcome == "" and guard < 200:
			guard += 1
			if sim.needs_input():
				sim.act("attack", sim.default_target(sim.current, "attack"), "")
			else:
				sim.ai_act()
			for e in sim.drain_events():
				if e.type == "damage":
					var lines := DamageExplain.lines(_data, e)
					assert_eq(lines[-1], "= %d skada" % int(e.amount))
					seen += 1
				elif e.type == "heal":
					assert_true(DamageExplain.lines(_data, e)[-1].begins_with("= %d helat" % int(e.effective)))
	assert_true(seen > 50)


func test_heals_grow_with_the_stats() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 1, ["alva"], {}, {}, {}, 1, {"levels": {"alva": {"level": 5}}})
	var alva := sim.unit("alva")
	sim._add_aura(alva, alva, "renew")
	assert_near(alva.auras.renew.hot, roundf(alva.intelligence * 0.7), 0.5, "Förnyelse följer Intelligence")
	assert_true(not _data.abilities.grave_mend.effects[0].has("min"), "Gravens lagning är en andel av Int")
	assert_true(not _data.traits.warden_helm.effects[0].has("min"), "Väktarens hjälm är en andel av Defense")
