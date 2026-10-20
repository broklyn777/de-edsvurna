extends "res://tests/test_case.gd"
## 0.23.3: den oberoende kontrollen av siffrorna. numbers_reference.gd räknar formlerna i docs/formler.md utan
## spelets egna funktioner, och numbers_audit.gd räknar om varje skada, helning och undvikande i seedade strider
## (båda Realms, djup 1–3, artefakter, material, statusar och regler). Hela granskningen med fler frön:
##   godot --headless --path . --script res://tests/numbers_audit_report.gd

const Ref := preload("res://tests/numbers_reference.gd")
const Audit := preload("res://tests/numbers_audit.gd")
const AuditSim := preload("res://tests/audit_sim.gd")

var _data := GameData.load_all()


func test_reference_gives_the_examples_in_the_docs() -> void:
	# formler.md §2: Eira 198 Attack mot Botgörarens 22 Defense som försvarar sig (×1,5 = 33) → 167.
	assert_eq(roundf(Ref.attack(198, 1.0, Ref.defense_now(22, 22, [1.5]), 1.0)), 167.0, "Eiras exempel")
	# §7: Helande ljus, styrka 2,3, 104 Intelligence → 239.
	assert_eq(Ref.heal(104, 2.3, 1.0, []), 239.0, "Helande ljus")
	# Siralim: +75 % och +75 % = +150 %; −60 % och −50 % = −80 %; en minskning stannar vid −80 %.
	assert_near(Ref.mods([1.75, 1.75]), 2.5, 1e-9)
	assert_near(Ref.mods([0.4, 0.5]), 0.2, 1e-9)
	assert_near(Ref.mods([0.05]), 0.2, 1e-9)
	# Krit-skada: +75 % vid lika fart, +200 % vid tre gånger farten, ~+450 % vid 27 gånger.
	assert_near(Ref.crit_bonus(10, 10), 0.75, 1e-9)
	assert_near(Ref.crit_bonus(30, 10), 2.0, 1e-9)
	assert_near(Ref.crit_bonus(270, 10), 4.5, 1e-9)
	# Undvikande: 10 % per fördubbling av målets fart, högst 30 %, inget mot ett långsammare mål.
	assert_near(Ref.dodge(10, 20), 0.1, 1e-9)
	assert_near(Ref.dodge(10, 160), 0.3, 1e-9)
	assert_near(Ref.dodge(20, 10), 0.0, 1e-9)
	# Indirekt: Defense dras av sist och bara en femtedel.
	assert_near(Ref.indirect_after(100, 50), 90.0, 1e-9)


## Spelets formler mot referensens över ett rutnät (samma tal, inte bara samma egenskaper).
func test_game_formulas_equal_the_reference() -> void:
	for atk in [5.0, 40.0, 95.0, 250.0, 900.0]:
		for def in [0.0, 12.0, 60.0, 300.0]:
			for power in [0.3, 1.0, 1.6]:
				assert_near(CombatSim.attack_damage(atk, def, power), Ref.attack(atk, 1.0, def, power), 1e-9)
				for tier in Ref.TIERS:
					var t: Array = Ref.TIERS[tier]
					assert_near(CombatSim.spell_damage(atk * float(t[0]), def, power, float(t[1])),
							Ref.spell(atk, tier, 1.0, def, power), 1e-9, tier)
				assert_near(CombatSim.indirect_damage(atk * power, def), Ref.indirect_after(atk * power, def), 1e-9)
	for my in [3.0, 7.0, 10.0, 14.0, 40.0]:
		for their in [3.0, 7.0, 10.0, 18.0, 60.0]:
			var r: float = my / their
			assert_near(CombatSim.crit_chance_for(0.1, r), Ref.crit_chance(0.1, my, their), 1e-9)
			assert_near(CombatSim.crit_bonus(r), Ref.crit_bonus(my, their), 1e-9)
			assert_near(CombatSim.dodge_chance(1.0 / r), Ref.dodge(my, their), 1e-9)
	for f in [[1.5, 0.65], [0.1, 0.1], [1.2, 1.3, 0.7, 0.5], [2.0], [0.19]]:
		assert_near(CombatSim.combine_mods(f), Ref.mods(f), 1e-9, str(f))


## Defense kan aldrig gå under 20 % av startvärdet, hur många sänkningar som än ligger på.
func test_defense_never_below_a_fifth() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 3, ["paladin"], {}, {}, {}, 1, {"elite_chance": 0.0})
	var p := sim.unit("paladin")
	for aura in ["provoke", "salted"]:
		sim._add_aura(p, p, aura)
	assert_near(p.defense_now(), Ref.defense_now(p.defense, p.base_stats.defense, [0.65, 0.8]), 1e-9)
	p.auras["salted"].defense_mult = 0.1
	assert_near(p.defense_now(), p.base_stats.defense * 0.2, 1e-9, "golvet")
	assert_near(p.defense_now(), Ref.defense_now(p.defense, p.base_stats.defense, [0.65, 0.1]), 1e-9)


## Kärnan: varje skada, helning och undvikande i 72 strider räknas om och ska stämma med det spelet visade.
func test_every_number_in_seeded_battles() -> void:
	var audit := Audit.new(_data)
	for setup in Audit.setups(_data):
		audit.run_battle(setup.encounter, setup.floor, setup.depth, 500 + setup.i, setup.party, setup.artifacts,
				setup.statuses, setup.rules, setup.level, setup.traits, setup.bonus)
	for m in audit.mismatches:
		runner.fail("[%d] %s" % [audit.by_key.values()[audit.mismatches.find(m)].n, m])
	assert_true(audit.counts.damage > 2000 and audit.counts.heal > 100 and audit.counts.dodge > 20,
			"för få händelser: %s" % str(audit.counts))
	assert_eq(audit.counts.fixed_unchecked, 0, "fasta belopp utan omräkning %s" % str(audit.unchecked))


## Granskningen ska larma när en siffra är fel (annars bevisar den ingenting).
func test_the_audit_notices_a_wrong_number() -> void:
	var audit := Audit.new(_data)
	var sim: CombatSim = AuditSim.adopt(CombatSim.create(_data, "crypt_1", 4, ["paladin", "brokk"], {}, {}, {}, 1,
			{"elite_chance": 0.0}))
	sim.begin()
	var hit := {}
	while sim.outcome == "" and hit.is_empty():
		sim.auto = true
		sim.ai_act()
		for r in sim.records:
			if r.kind == "damage" and not r.event.is_empty() and r.event.type == "damage" and hit.is_empty():
				hit = r
		sim.records.clear()
	audit.check_record(sim, hit)
	assert_eq(audit.mismatches.size(), 0, "den riktiga träffen")
	hit.event.amount += 1.0
	audit.check_record(sim, hit)
	assert_true(audit.mismatches.size() > 0, "en träff som visar 1 för mycket")


## Varje stat-källa (bas, nivåer, personlighet, artefakt, bärnsten, Nether Stone) når striden och hjältebladet med
## samma värden, och bladets visade delar blir den visade summan.
func test_stat_sources_reach_battle_and_sheet_alike() -> void:
	var audit := Audit.new(_data)
	var arts: Array = [{}]
	arts.append_array(Audit.audit_artifacts(["a", "b", "c", "d", "e"], 0).values())
	var personalities: Array = [""] + _data.personalities.keys().slice(0, 4)
	var n := 0
	for hero_id in _data.heroes:
		for level in [1, 3, 8, 14]:
			for pi in personalities.size():
				var pers: String = personalities[pi]
				var art: Dictionary = arts[(n + pi) % arts.size()]
				n += 1
				var sheet := HeroStats.breakdown(_data, hero_id, level, pers, art)
				var want := audit.hero_parts(hero_id, level, pers, art)
				var sim := CombatSim.create(_data, "crypt_1", 1, [hero_id], {}, {}, {} if art.is_empty() else {hero_id: art},
						1, {"levels": {hero_id: {"level": level, "personality": pers}}})
				var u := sim.unit(hero_id)
				var label := "%s nivå %d %s %s" % [hero_id, level, pers, art.get("type", "utan artefakt")]
				for stat in HeroStats.STATS:
					for source in HeroStats.SOURCES:
						assert_near(float(sheet[stat].get(source, 0.0)), float(want[stat][source]), 1e-6,
								"%s: %s från %s" % [label, stat, source])
					var battle := u.max_hp if stat == "health" else float(u.get(stat))
					assert_near(battle, float(sheet[stat].total), 1e-6, "%s: %s i striden mot bladet" % [label, stat])
					var shown := HeroStats.shown_parts(sheet[stat])
					var sum := 0.0
					for source in HeroStats.SOURCES:
						sum += float(shown[source])
					assert_near(sum, float(shown.total), 1e-6, "%s: bladets delar för %s" % [label, stat])
					assert_true(absf(float(shown.total) - battle) <= 0.05 + 1e-9, "%s: visad %s" % [label, stat])


## Hjältebladet räknar mot samma fiende som striden möter med sällskapet (inte en fiende skalad för en ensam hjälte).
func test_hero_sheet_faces_the_enemy_of_the_party() -> void:
	var screen: GDScript = load("res://scripts/screens/hero_screen.gd")
	var prof := Profile.new()
	prof.party.assign(["paladin", "brokk", "alva", "eira"])
	for hero_id in ["paladin", "eira", "solveig"]:
		var party: Array = screen.sheet_party(prof, hero_id)
		assert_true(party.has(hero_id) and party.size() == 4, "%s: %s" % [hero_id, str(party)])
		var sheet := CombatSim.create(_data, "crypt_1", 1, party, screen.sheet_traits(_data, prof), {}, {}, 1,
				{"levels": {hero_id: {"level": 3, "personality": ""}}, "elite_chance": 0.0, "floor": 0})
		var battle := CombatSim.create(_data, "crypt_1", 1, prof.party, {}, {}, {}, 1,
				{"levels": {hero_id: {"level": 3, "personality": ""}}, "elite_chance": 0.0, "floor": 0})
		assert_eq(sheet.enemies[0].max_hp, battle.enemies[0].max_hp, "%s: fiendens liv" % hero_id)
		assert_eq(sheet.enemies[0].attack, battle.enemies[0].attack, "%s: fiendens Attack" % hero_id)
	# Gryningens Större helning (+50 %, hela sällskapet): bladets helning räknar med den, som striden.
	var sim := CombatSim.create(_data, "crypt_1", 1, ["paladin", "alva"],
			{"paladin": ["oath_dawn", "dawn_greater_healing"]}, {}, {}, 1)
	var alva := sim.unit("alva")
	assert_eq(sim.expected_heal(alva, alva, "healing_light"), roundf(alva.intelligence * 2.3 * 1.5), "Större helning")
	assert_eq(screen.sheet_traits(_data, prof).paladin[0], prof.oath, "kallet")


## Profilens första nedstigning (0.24.1, vårt val): RunState ger striden trappan per våning, som docs/formler.md §9 säger.
func test_first_descent_scales_the_enemies_like_the_docs() -> void:
	var state := RunState.new()
	state.first_descent = true
	state.party.assign(["paladin", "imma"])
	for f in 3:
		state.floor = f
		assert_near(float(state.battle_opts().get("stat_bonus", 1.0)), Ref.battle_bonus(false, true, f), 1e-9, "våning %d" % (f + 1))
	# 0.25: den första striden gör paladinen ensam, innan Imma smiter efter.
	state.floor = 0
	state.party.assign(["paladin"])
	assert_near(float(state.battle_opts().get("stat_bonus", 1.0)), Ref.battle_bonus(false, true, 0, true), 1e-9, "ensam")
	state.party.assign(["paladin", "imma"])
	state.floor = 0
	state.first_descent = false
	assert_near(float(state.battle_opts().get("stat_bonus", 1.0)), 1.0, 1e-9, "senare")
	assert_near(RunState.PORTAL_STATS, Ref.battle_bonus(true, false), 1e-9, "Portalen")
	# Fienderna i striden: bas × trappan (våning 1) före sällskapets storlek, avrundat som referensen.
	var sim := CombatSim.create(_data, "crypt_1", 2, ["paladin", "imma"], {}, {}, {}, 1,
			{"stat_bonus": Ref.battle_bonus(false, true), "elite_chance": 0.0})
	var enc: Dictionary = _data.encounters.crypt_1
	assert_eq(sim.enemies.map(func(x: CombatUnit) -> String: return x.kind),
			Ref.lineup(_data.enemies, _data.traits, enc.enemies, 2), "fienderna mot två hjältar")
	for e in sim.enemies:
		var want := Ref.enemy_stats(_data.enemies[e.kind].stats, float(enc.get("stat_mult", 1.0)), 1, 2, 1.0, false, false,
				Ref.battle_bonus(false, true))
		assert_eq(e.max_hp, want.health, e.kind)
		assert_eq(e.attack, want.attack, e.kind)
