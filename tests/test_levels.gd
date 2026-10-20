extends "res://tests/test_case.gd"
## 0.19: nivåer, erfarenhet, personlighet, uppdelningen per källa och hur fienderna möter nivåerna.

var _data := GameData.load_all()


func test_twenty_personalities_cover_every_pair() -> void:
	var pairs := {}
	var names := {}
	for id in _data.personalities:
		var p: Dictionary = _data.personalities[id]
		assert_true(p.up != p.down, "%s höjer och sänker olika stats" % id)
		assert_true(HeroStats.STATS.has(p.up) and HeroStats.STATS.has(p.down))
		pairs["%s/%s" % [p.up, p.down]] = true
		names[p.name] = true
	assert_eq(_data.personalities.size(), 20)
	assert_eq(pairs.size(), 20, "varje kombination en gång")
	assert_eq(names.size(), 20, "unika namn")
	for hero_id in _data.heroes:
		assert_true(_data.personalities.has(_data.heroes[hero_id].personality), "%s har en förvald personlighet" % hero_id)


func test_each_level_adds_thirty_percent_of_base() -> void:
	var base: Dictionary = _data.heroes.brokk.stats
	var neutral := HeroStats.level_stats(_data, "brokk", 3, "")
	assert_eq(neutral.attack, CombatSim.snap_stat(base.attack * 1.6))
	assert_eq(neutral.speed, roundf(base.speed * 1.6), "Speed växer också")
	# Envis: Health 40 %, Speed 20 %.
	var envis := HeroStats.level_stats(_data, "brokk", 3, "envis")
	assert_eq(envis.health, CombatSim.snap_stat(base.health * 1.8))
	assert_eq(envis.speed, roundf(base.speed * 1.4))
	assert_eq(envis.attack, CombatSim.snap_stat(base.attack * 1.6))
	assert_eq(HeroStats.level_stats(_data, "brokk", 1, "envis").health, float(base.health), "personligheten ändrar inte nivå 1")


func test_breakdown_sums_to_the_stats_in_combat() -> void:
	var art := {"type": "helm", "ability": ""}
	var levels := {"paladin": {"level": 4, "personality": "modig"}}
	var sim := CombatSim.create(_data, "crypt_1", 1, [], {}, {}, {"paladin": art}, 1, {"levels": levels})
	var pal := sim.unit("paladin")
	var b := HeroStats.breakdown(_data, "paladin", 4, "modig", art)
	assert_eq(b.health.total, pal.max_hp, "Health med hjälmens +5 %")
	assert_eq(b.attack.total, pal.attack)
	assert_eq(b.defense.total, pal.defense)
	for stat in HeroStats.STATS:
		var s: Dictionary = b[stat]
		assert_near(s.base + s.levels + s.personality + s.artifact, s.total, 0.001, "%s summerar" % stat)
	assert_true(b.attack.personality > 0.0 and b.defense.personality < 0.0, "Modig: Attack upp, Defense ned")
	assert_true(b.health.artifact > 0.0)


func test_xp_levels_up_without_a_cap() -> void:
	var p := {"level": 1, "xp": 0}
	var ups := HeroStats.add_xp(p, HeroStats.xp_to_next(1) + 5)
	assert_eq(ups, [2])
	assert_eq(p.xp, 5)
	ups = HeroStats.add_xp(p, 10000)
	assert_true(ups.size() > 8, "inget tak")
	assert_true(p.xp < HeroStats.xp_to_next(p.level))
	assert_true(HeroStats.xp_to_next(10) > HeroStats.xp_to_next(3), "högre nivåer kostar mer")


func test_expected_level_and_enemy_levels_follow_depth() -> void:
	assert_eq(HeroStats.expected_level(1), 3)
	assert_eq(HeroStats.expected_level(3), 13)
	assert_true(HeroStats.enemy_level(1, 0) < HeroStats.expected_level(1) and
			HeroStats.expected_level(1) < HeroStats.enemy_level(1, 2), "väntad nivå mitt i djupet")
	assert_true(HeroStats.battle_xp("end", 1, true) > HeroStats.battle_xp("end", 1) and
			HeroStats.battle_xp("end", 1) > HeroStats.battle_xp("battle", 1), "boss > slut > strid")
	assert_eq(HeroStats.battle_xp("battle", 3), 9 * HeroStats.battle_xp("battle", 1), "djup² som kurvan")
	assert_true(HeroStats.battle_xp("battle", 1) > 0, "lägre djup går att träna på")


func test_breakdown_lists_every_source() -> void:
	var b := HeroStats.breakdown(_data, "brokk", 3, "envis", {"type": "sword", "ability": ""})
	for stat in HeroStats.STATS:
		for source in HeroStats.SOURCES:
			assert_true(b[stat].has(source), "%s har %s" % [stat, source])
			assert_true(HeroStats.SOURCE_NAMES.has(source))


func test_profile_keeps_levels_and_old_profiles_start_at_one() -> void:
	var path := "user://test_progress_levels.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 100)
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq(int(p.hero(_data, "brokk").level), 1, "gammal profil börjar på nivå 1")
	assert_eq(p.hero(_data, "brokk").personality, "envis")
	var ups := p.grant_xp(_data, ["paladin", "brokk"], 200)
	assert_eq(ups.brokk, [2, 3, 4, 5])
	assert_eq(p.hero(_data, "brokk").log.size(), 4, "historiken")
	assert_true(p.set_personality(_data, "brokk", "stadig"))
	assert_eq(p.silver, 100 - Profile.PERSONALITY_COST)
	assert_true(not p.set_personality(_data, "brokk", "stadig"), "samma personlighet igen kostar inget och görs inte")
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(int(q.hero(_data, "brokk").level), 5)
	assert_eq(q.hero(_data, "brokk").personality, "stadig")
	assert_eq(q.levels_for(_data, ["brokk"]).brokk.level, 5)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_personality_change_recomputes_backwards() -> void:
	var a := HeroStats.level_stats(_data, "eira", 6, "rastlos")
	var b := HeroStats.level_stats(_data, "eira", 6, "stadig")
	var base: Dictionary = _data.heroes.eira.stats
	assert_eq(a.speed, roundf(base.speed * 3.0), "Rastlös: Speed 40 % × 5 nivåer")
	assert_eq(b.speed, roundf(base.speed * 2.0), "Stadig: Speed 20 %")
	assert_eq(b.defense, roundf(base.defense * 3.0))


func test_enemy_level_follows_depth_and_floor_not_the_party() -> void:
	var plain := CombatSim.create(_data, "crypt_1", 1)
	var hp: float = plain.unit("skeleton_warrior_1").max_hp
	var levels := {"paladin": {"level": 3}, "brokk": {"level": 3}, "alva": {"level": 3}, "eira": {"level": 3}}
	var sim := CombatSim.create(_data, "crypt_1", 1, [], {}, {}, {}, 1, {"levels": levels, "elite_chance": 0.0})
	var w := sim.unit("skeleton_warrior_1")
	var lv := HeroStats.enemy_level(1, 0)
	assert_near(w.level, lv, 0.001)
	assert_eq(w.max_hp, CombatSim.snap_stat(hp * HeroStats.level_mult(lv)))
	var low := CombatSim.create(_data, "crypt_1", 1, [], {}, {}, {}, 1, {"levels": {"paladin": {"level": 1}}, "elite_chance": 0.0})
	assert_eq(low.unit("skeleton_warrior_1").level, w.level, "sällskapets nivå spelar ingen roll")
	var later := CombatSim.create(_data, "crypt_1", 1, [], {}, {}, {}, 1, {"levels": levels, "elite_chance": 0.0, "floor": 2})
	assert_true(later.unit("skeleton_warrior_1").level > w.level, "senare våningar har högre nivå")
	assert_true(HeroStats.enemy_level(2, 0) > HeroStats.enemy_level(1, 2), "nästa djup börjar över förra djupets sista våning")
	assert_eq(plain.unit("skeleton_warrior_1").level, 1.0, "utan nivåer som förut")


func test_battle_opts_carry_the_floor() -> void:
	var state := RunState.new()
	state.set_realm(_data, "crypt")
	state.fill_charges(_data)
	state.start_expedition(_data, 3)
	state.floor = 1
	assert_eq(state.battle_opts().floor, 1)
