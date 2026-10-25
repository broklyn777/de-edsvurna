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


## Balans v1: varje nivå +20 % mot nivån innan (nivå 3 = 1,2² = 1,44); personligheten 40/30 respektive 20/30 av tillväxten.
func test_each_level_adds_twenty_percent() -> void:
	var base: Dictionary = _data.heroes.brokk.stats
	var neutral := HeroStats.level_stats(_data, "brokk", 3, "")
	assert_eq(neutral.attack, CombatSim.snap_stat(base.attack * 1.44))
	assert_eq(neutral.speed, roundf(base.speed * 1.44), "Speed växer också")
	# Envis: Health 40 %, Speed 20 % (av 30).
	var envis := HeroStats.level_stats(_data, "brokk", 3, "envis")
	assert_eq(envis.health, CombatSim.snap_stat(base.health * (1.0 + 0.44 * 4.0 / 3.0)))
	assert_eq(envis.speed, roundf(base.speed * (1.0 + 0.44 * 2.0 / 3.0)))
	assert_eq(envis.attack, CombatSim.snap_stat(base.attack * 1.44))
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
	ups = HeroStats.add_xp(p, 60000)
	assert_true(ups.size() > 8, "inget tak")
	assert_true(p.xp < HeroStats.xp_to_next(p.level))
	assert_true(HeroStats.xp_to_next(10) > HeroStats.xp_to_next(3), "högre nivåer kostar mer")


func test_expected_level_and_enemy_levels_follow_depth() -> void:
	assert_eq(HeroStats.expected_level(1), 3)
	assert_eq(HeroStats.expected_level(3), 7, "kurvan: djup 3 är nivå 7 (förr 13)")
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
	var a := HeroStats.level_stats(_data, "eira", 5, "rastlos")
	var b := HeroStats.level_stats(_data, "eira", 5, "stadig")
	var base: Dictionary = _data.heroes.eira.stats
	var m := pow(1.2, 4) - 1.0
	assert_eq(a.speed, roundf(base.speed * (1.0 + m * 4.0 / 3.0)), "Rastlös: Speed 40 % i stället för 30")
	assert_eq(b.speed, roundf(base.speed * (1.0 + m * 2.0 / 3.0)), "Stadig: Speed 20 %")
	assert_eq(b.defense, CombatSim.snap_stat(base.defense * (1.0 + m * 4.0 / 3.0)))


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


## Nivåskalan (VD 2026-10-25, variant C "kurva"): de fyra första nivåerna som förut, sedan glesare och större.
func test_level_curve_first_levels_as_before_then_sparser() -> void:
	assert_eq([HeroStats.xp_to_next(1), HeroStats.xp_to_next(2), HeroStats.xp_to_next(3), HeroStats.xp_to_next(4)],
			[15, 30, 55, 90], "nivå 2–5 kommer lika tätt som förut")
	for l in range(1, 6):
		assert_near(HeroStats.old_level(l), float(l), 1e-6)
	var last := 0
	for l in range(1, 20):
		var need := HeroStats.xp_to_next(l)
		assert_true(need > last, "nivå %d kostar mer än nivån innan" % (l + 1))
		last = need
		assert_near(HeroStats.new_level(HeroStats.old_level(l + 0.5)), l + 0.5, 1e-4, "omvändningen")
	# Varje nivå efter den femte ger mer än en nivå gav förut (+30 % av basen).
	for l in range(5, 13):
		assert_true(HeroStats.old_level(l + 1) - HeroStats.old_level(l) > 2.0, "nivå %d är ett stort steg" % (l + 1))
	assert_eq(HeroStats.expected_level(10), 13, "djup 10 är ungefär nivå 13")


## Balans v1 (VD 2026-10-25): varje nivå +20 % mot nivån innan för nivå 2–10, aldrig mer än +25 %; sedan krymper steget
## långsamt mot 12–15 %. Fienderna följer samma kurva på sin nivå (takten och nivån per djup är som förut).
func test_strength_steps() -> void:
	for l in range(2, 11):
		var step := HeroStats.strength(l) / HeroStats.strength(l - 1) - 1.0
		assert_near(step, 0.20, 1e-9, "nivå %d" % l)
	var last := 0.2
	for l in range(11, 80):
		var step := HeroStats.strength(l) / HeroStats.strength(l - 1) - 1.0
		assert_true(step < last and step > 0.12, "nivå %d: %.3f" % [l, step])
		last = step
	assert_true(last < 0.15, "långt upp 12–15 %")
	assert_near(HeroStats.strength(2.5), sqrt(1.2 * 1.44), 1e-9, "geometriskt mellan nivåer")
	for depth in range(1, 11):
		for f in 3:
			assert_near(HeroStats.enemy_level_mult(depth, f), HeroStats.strength(HeroStats.enemy_level(depth, f)), 1e-9,
					"djup %d våning %d" % [depth, f + 1])
	assert_eq([HeroStats.expected_level(1), HeroStats.expected_level(2), HeroStats.expected_level(3)], [3, 6, 7],
			"väntad nivå per djup som förut")


## Omräkningen av en gammal nivå (VD 2026-10-25): exakt lika stark som förut. Den högsta nya nivån som inte är starkare,
## och resten (carry) i 0.19:s skala tills nästa nivå.
func test_convert_legacy_levels_keeps_strength() -> void:
	for old in range(1, 6):
		var c0 := HeroStats.convert_legacy(old, 3)
		assert_eq(int(c0.level), old, "nivå 1–5 är desamma")
		assert_near(float(c0.carry), 0.0, 1e-9)
	assert_eq(int(HeroStats.convert_legacy(4, 7).xp), 7, "erfarenheten står kvar under knät")
	for old in range(6, 60):
		var c := HeroStats.convert_legacy(old, 0)
		var lv := int(c.level)
		assert_true(HeroStats.old_level(lv) <= old + 1e-6, "nivå %d → %d: aldrig starkare" % [old, lv])
		assert_true(HeroStats.old_level(lv + 1) > old, "nivå %d → %d: den högsta som inte är starkare" % [old, lv])
		# Balans v1: resten är en del av en nivå på takten; styrkan är kurvans på den nivån (lika långt från fienderna).
		assert_near(HeroStats.growth_level(lv, float(c.carry)),
				1.0 + (HeroStats.strength(HeroStats.new_level(float(old))) - 1.0) / HeroStats.GROWTH, 1e-6, "nivå %d" % old)
		assert_true(int(c.xp) >= 0 and int(c.xp) < HeroStats.xp_to_next(lv))
	assert_eq(int(HeroStats.convert_legacy(7, 0).level), 5)
	assert_eq(int(HeroStats.convert_legacy(12, 0).level), 7)
	assert_eq(int(HeroStats.convert_legacy(16, 0).level), 8)
	assert_eq(int(HeroStats.convert_legacy(24, 0).level), 9)


## En profil sparad i 0.19:s skala räknas om en gång när den läses, och Broder Alrik förklarar det. Resten (carry) sparas,
## går in i striden och försvinner vid nästa nivå.
func test_old_save_is_converted_once() -> void:
	var path := "user://test_progress_rescale.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 100)
	cfg.set_value("progress", "heroes", {"paladin": {"level": 12, "xp": 40, "personality": "modig", "battles": 50,
			"wins": 45, "deaths": 0, "revives": 0, "log": [{"level": 2, "battle": 1}, {"level": 6, "battle": 9},
			{"level": 9, "battle": 20}, {"level": 12, "battle": 40}]},
			"brokk": {"level": 4, "xp": 12, "personality": "envis", "battles": 3, "wins": 3, "deaths": 0, "revives": 0, "log": []}})
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq(int(p.hero(_data, "paladin").level), 7)
	var carry := p.carry(_data, "paladin")
	assert_near(carry, 12.0 - HeroStats.old_level(7), 1e-6, "resten i 0.19:s skala")
	assert_eq(int(p.hero(_data, "brokk").level), 4, "låga nivåer är desamma")
	assert_true(not p.hero(_data, "brokk").has("carry"), "ingen rest under knät")
	assert_eq(int(p.hero(_data, "brokk").xp), 12)
	assert_true(p.levels_rescaled)
	var log: Array = p.hero(_data, "paladin").log
	assert_eq(log.map(func(e: Dictionary) -> int: return int(e.level)), [2, 5, 6, 7], "historiken i den nya skalan")
	var line := Dialog.idle_line(_data, p, "alrik", 0)
	assert_true(line.contains("Nivåerna"), "Broder Alrik förklarar: " + line)
	# Striden och hjältebladet räknar med resten: styrkan på den del av en nivå som 0.19:s nivå 12 motsvarar.
	var gh := HeroStats.growth(_data, "modig", "health")
	var old_hp := CombatSim.snap_stat(float(_data.heroes.paladin.stats.health) * (1.0 + gh / HeroStats.GROWTH
			* (HeroStats.strength(HeroStats.new_level(12.0)) - 1.0)))
	var lv := p.levels_for(_data, ["paladin"])
	assert_near(float(lv.paladin.carry), carry, 1e-6)
	var sim := CombatSim.create(_data, "crypt_1", 1, ["paladin"], {}, {}, {}, 1, {"levels": lv})
	assert_near(sim.unit("paladin").max_hp, old_hp, 0.051, "striden är lika stark som förut")
	var sheet := HeroStats.breakdown(_data, "paladin", 7, "modig", {}, carry)
	assert_near(float(sheet.health.total), old_hp, 0.051, "hjältebladet visar samma")
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(int(q.hero(_data, "paladin").level), 7, "räknas inte om två gånger")
	assert_near(q.carry(_data, "paladin"), carry, 1e-6, "resten sparas")
	assert_true(not Dialog.idle_line(_data, q, "alrik", 1).contains("Nivåerna"), "en gång")
	# Nästa nivå är minst lika stark som den gamla tillväxten: resten försvinner.
	var need := HeroStats.xp_to_next(7) - int(q.hero(_data, "paladin").xp)
	var ups := q.grant_xp(_data, ["paladin"], need)
	assert_eq(ups.get("paladin", []), [8])
	assert_near(q.carry(_data, "paladin"), 0.0, 1e-9, "resten försvinner vid nästa nivå")
	assert_true(HeroStats.level_stats(_data, "paladin", 8, "modig").health >= old_hp, "nivå 8 är minst lika stark")
	var g := HeroStats.gains(_data, "paladin", 8, "modig", float(q.hero(_data, "paladin").get("carry_before", 0.0)))
	assert_near(float(g.health), HeroStats.level_stats(_data, "paladin", 8, "modig").health - old_hp, 0.051,
			"segerskärmen visar ökningen från den verkliga styrkan")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var fresh := Profile.new()
	assert_true(not fresh.levels_rescaled, "en ny profil har inget att förklara")


## Segerskärmen visar hoppet i skada och helning (LevelJump, som hjältebladet).
func test_level_jump_shows_damage_and_heal() -> void:
	var p := Profile.new()
	p.recruit(_data, "alva")
	p.hero(_data, "alva").level = 6
	var jump := LevelJump.compute(_data, p, "alva", 6, "crypt", 2, ["paladin", "alva"])
	assert_true(jump.size() >= 2, "liv och en förmåga")
	assert_eq(jump[0].label, "Liv")
	assert_true(int(jump[0].after) > int(jump[0].before), "mer liv")
	var heal: Array = jump.filter(func(j: Dictionary) -> bool: return j.unit == "helning")
	assert_eq(heal.size(), 1, "Alva helar")
	assert_true(int(heal[0].after) > int(heal[0].before), "starkare helning")
	assert_true(LevelJump.text(jump).contains("→"), LevelJump.text(jump))


## Edsgrader (VD 2026-10-25): var tredje nivå en titel för Paladinen, inga siffror.
func test_oath_rank_every_third_level() -> void:
	for lv in range(1, 31):
		assert_eq(HeroStats.oath_rank(lv), lv / 3, "nivå %d" % lv)
		var title := Dialog.oath_rank_title(_data, HeroStats.oath_rank(lv))
		assert_eq(title != "", lv >= 3, "titel från nivå 3 (nivå %d)" % lv)
	assert_eq(Dialog.oath_rank_title(_data, 2), "Edsvuren av andra graden")
	assert_eq(Dialog.oath_rank_title(_data, 4), "Edsvuren av fjärde graden")
	assert_true(Dialog.oath_rank_title(_data, 11) != "", "också högt upp")
	var titles := {}
	for r in range(1, 11):
		titles[Dialog.oath_rank_title(_data, r)] = true
	assert_eq(titles.size(), 10, "en egen titel per grad")
	var p := Profile.new()
	p.hero_name = "Tran"
	for r in range(1, 13):
		var alone := Dialog.oath_rank_line(_data, p, r, ["paladin"])
		assert_eq(alone.who, "gorm", "Gorm säger det när ingen kamrat har en rad (grad %d)" % r)
		assert_true(not String(alone.text).contains("{"), "ifylld: " + String(alone.text))
	assert_eq(Dialog.oath_rank_line(_data, p, 2, ["paladin", "brokk"]).who, "brokk", "en kamrat i sällskapet först")
