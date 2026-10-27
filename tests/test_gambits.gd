extends "res://tests/test_case.gd"
## Gambits (docs/plan/gambits.md): klossar (villkor, gränser, subjekt och mål), funna rader, migrering av gamla profiler,
## avstängda rader, platser och droppar.

var data := GameData.load_all()


func _line(cond: String, value: Variant = 0, action := "attack", subject := "any_enemy", target := "that") -> Dictionary:
	return {"subject": subject, "cond": cond, "value": value, "action": action, "ability": "", "target": target}


func test_every_condition_has_one_gambit() -> void:
	var seen := {}
	for id in Gambits.all(data):
		for cond in Gambits.all(data)[id].get("conds", []):
			assert_true(not seen.has(cond), "%s finns i två gambits" % cond)
			seen[cond] = id
			assert_true(MacroRunner.CONDITIONS.has(cond) or cond == "test_next", "okänt villkor %s" % cond)
	for cond in MacroRunner.CONDITIONS:
		assert_true(seen.has(cond), "%s saknar en gambit (alla villkor förtjänas)" % cond)


func test_every_subject_and_target_is_free_or_a_block() -> void:
	for s in MacroRunner.SUBJECTS:
		var b := Gambits.subject_block(data, s)
		assert_true(b != "" or s in ["self", "any_ally", "any_enemy"], "subjektet %s saknar kloss" % s)
	for t in MacroRunner.TARGETS:
		var b := Gambits.target_block(data, t)
		assert_true(b != "" or t in ["that", "self"], "målet %s saknar kloss" % t)
	assert_eq(Gambits.subject_block(data, "ally_3"), "g_ally_n")
	assert_eq(Gambits.target_block(data, "enemy_5"), "g_enemy_n")
	assert_eq(Gambits.target_block(data, "random_ally"), "g_random")


func test_every_block_has_home_clue_and_rows() -> void:
	var blocks := Gambits.blocks(data)
	assert_true(blocks.has("g_hp_below@50") and blocks.has("g_hp_below@10"), "gränserna är egna klossar")
	assert_true(not blocks.has("g_hp_below"), "familjen är ingen kloss att hitta")
	for id in blocks:
		var g: Dictionary = blocks[id]
		assert_true(g.get("clue", "") != "", "%s saknar rykte" % id)
		assert_true(not g.get("rows", []).is_empty(), "%s saknar radmall" % id)
		for kind in g.get("homes", []):
			assert_true(data.enemies.has(kind), "%s: okänd fiende %s" % [id, kind])
		if not g.rarity in ["start", "chest"]:
			assert_true(not g.get("homes", []).is_empty(), "%s har inget hem" % id)
	for hero_id in data.gambits.teach:
		assert_true(data.heroes.has(hero_id), "okänd hjälte " + hero_id)


func test_sharp_thresholds_live_with_harder_enemies() -> void:
	for v in ["10", "20"]:
		var e := Gambits.entry(data, "g_hp_below@" + v)
		assert_true(e.rarity in ["elite", "boss"], "liv under %s %% är skarp" % v)
		for kind in e.homes:
			var rank: String = data.enemies[kind].get("rank", "normal")
			assert_true(rank != "normal" or kind in ["bone_lich", "fallen_bishop", "mountain_king"], "%s är inte svår" % kind)
	assert_eq(Gambits.entry(data, "g_hp_below@50").rarity, "common")
	assert_eq(Gambits.name_of(data, "g_hp_below@20"), "Liv under 20 %")
	assert_eq(Gambits.name_of(data, "g_hp_below@35"), "Liv under 35 %", "en gräns utanför listan (gamla makron)")


func test_thresholds_are_separate_blocks() -> void:
	var owned := ["g_hp_below@50"]
	assert_true(Gambits.line_owned(data, _line("hp_below", 50, "attack"), owned))
	assert_true(not Gambits.line_owned(data, _line("hp_below", 20, "attack"), owned), "20 % är en egen kloss")
	assert_eq(Gambits.missing(data, _line("hp_below", 20), owned), "g_hp_below@20")
	# Hela familjen (gamla profiler) äger alla gränser.
	assert_true(Gambits.line_owned(data, _line("hp_below", 20), ["g_hp_below"]))
	assert_true(Gambits.has(["g_hp_below"], "g_hp_below@35"))


func test_blocks_are_free_to_combine() -> void:
	# Klossarna i en funnen rad är ens egna: "liv < 50 %" går att använda både för helning och för att slå en fiende.
	var owned := ["g_lowest_hp", "g_hp_below@50"]
	var heal := {"subject": "any_ally", "cond": "hp_below", "value": 50, "action": "ability", "ability": "healing_light", "target": "that"}
	assert_true(Gambits.line_owned(data, heal, owned))
	assert_true(Gambits.line_owned(data, _line("hp_below", 50, "attack", "any_enemy"), owned))
	assert_true(Gambits.line_owned(data, _line("hp_below", 50, "defend", "self"), owned), "handlingarna är fria")
	assert_true(not Gambits.line_owned(data, _line("hp_below", 50, "attack", "enemy_2"), owned), "Fiende 1–6 förtjänas")
	assert_true(not Gambits.line_owned(data, _line("lowest_hp", 0, "attack", "any_enemy", "random_enemy"), owned),
			"Slumpvis förtjänas")
	assert_true(Gambits.line_owned(data, _line("lowest_hp", 0, "provoke", "any_enemy", "random_enemy"), owned),
			"ett mål som handlingen inte använder räknas inte")
	owned.append("g_enemy_n")
	assert_true(Gambits.line_owned(data, _line("hp_below", 50, "attack", "enemy_2", "enemy_4"), owned))


func test_new_profile_starts_nearly_empty() -> void:
	var p := Profile.new()
	p.setup_gambits(data, {})
	assert_eq(p.gambits_state, "ok")
	assert_eq(p.gambits, ["g_lowest_hp"], "bara introts första rad")
	assert_eq(p.found_rows.size(), 1, "Gorms rad är det första fyndet")
	assert_eq(p.found_rows[0].source, "intro")
	assert_true(Gambits.same_line(p.found_rows[0].line, load("res://scripts/game/run.gd").FIRST_LINE))
	assert_eq(p.gambit_slot_floor, 0)


func test_recruit_gives_a_found_row_and_its_blocks() -> void:
	var p := Profile.new()
	p.setup_gambits(data, {})
	p.recruit(data, "alva")
	assert_true(p.gambits.has("g_hp_below@50"), "Alvas förslag: liv < 50 %")
	var row: Dictionary = p.found_rows[p.found_rows.size() - 1]
	assert_eq(row.hero, "alva")
	assert_eq(row.line.ability, "healing_light")
	assert_eq(int(row.line.value), 50)
	# Hennes startrader ägs (kedjan med liv < 80 %), så att en ny profils Alva gör samma sak som förut.
	var lines: Array = load("res://scripts/game/run.gd").starter_lines(data, "alva", data.macros.alva.lines)
	for l in lines:
		assert_true(Gambits.line_owned(data, l, p.gambits), MacroRunner.describe_line(data, l))
	p.recruit(data, "imma")
	assert_true(p.gambits.has("g_buffs"), "Imma: Buff")
	assert_true(p.found_rows.any(func(r: Dictionary) -> bool: return r.hero == "imma" and r.line.cond == "has_buff"))
	assert_true(not p.learn_gambit(data, "g_buffs"), "redan ägd")
	assert_true(not p.learn_gambit(data, "finns_inte"))


func test_learn_row_owns_its_blocks_and_saves_it_once() -> void:
	var p := Profile.new()
	p.setup_gambits(data, {})
	var rng := RandomNumberGenerator.new()
	var row := Gambits.make_row(data, "g_ally_n", ["paladin", "alva"], rng)
	assert_eq(row.line.subject, "ally_1")
	var got := p.learn_row(data, row, "battle")
	assert_true(got.has("g_ally_n") and got.has("g_hp_below@50"), "subjektet och gränsen blir egna: %s" % [got])
	assert_true(Gambits.line_owned(data, row.line, p.gambits))
	var n := p.found_rows.size()
	p.learn_row(data, row, "chest")
	assert_eq(p.found_rows.size(), n, "samma rad sparas en gång")


func test_make_row_picks_a_hero_who_can_do_it() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in 20:
		rng.seed = seed_value
		var row := Gambits.make_row(data, "g_hp_below@30", ["paladin", "imma", "alva"], rng)
		assert_eq(row.hero, "alva", "bara Alva helar")
		assert_eq(row.line.action, "ability")
		assert_true(Gambits.ability_fits(data, row.line.ability, "heal"))
		assert_eq(int(row.line.value), 30, "gränsen följer klossen")
	# Utan helare: en annan handling med samma villkor (Helig sköld skyddar, annars Provocera).
	var row := Gambits.make_row(data, "g_hp_below@30", ["paladin", "imma"], rng)
	assert_eq(row.hero, "paladin")
	assert_eq(row.line.ability, "holy_shield")
	row = Gambits.make_row(data, "g_hp_below@30", ["imma"], rng)
	assert_eq(row.line.action, "provoke")
	# En skarp gräns slår en fiende som snart faller.
	row = Gambits.make_row(data, "g_hp_below@10", ["paladin"], rng)
	assert_eq(row.line.subject, "any_enemy")
	assert_eq(row.line.ability, "holy_smite")
	# Status: värdet är statusen förmågan ger.
	row = Gambits.make_row(data, "g_status", ["eira"], rng)
	assert_eq(row.line.cond, "lacks_status")
	assert_eq(row.line.value, "marked")
	# Svag mot förmågan: Rättfärdigt slag mot den som är Förblindad.
	row = Gambits.make_row(data, "g_weak", ["imma", "paladin"], rng)
	assert_eq(row.line.value, "holy_smite")
	assert_eq(row.hero, "paladin")
	# Varje kloss ger en rad som går att lägga i ett makro, med vilket sällskap som helst.
	for id in Gambits.blocks(data):
		for party in [["paladin"], ["paladin", "imma", "alva", "brokk"]]:
			row = Gambits.make_row(data, id, party, rng)
			assert_true(not row.is_empty(), id)
			assert_true(party.has(row.hero), id)
			assert_true(Gambits.needs(data, row.line).has(id) or Gambits.has(Gambits.needs(data, row.line), id),
					"%s: raden lär inte ut klossen (%s)" % [id, MacroRunner.describe_line(data, row.line)])


func test_new_conditions_work_in_battle() -> void:
	var sim := CombatSim.create(data, "crypt_1", 3, ["paladin", "imma"])
	sim.begin()
	while not sim.needs_input():
		sim.ai_act()
	var foe: CombatUnit = sim.enemies[0]
	var weak := {"subject": "any_enemy", "cond": "weak_to", "value": "holy_smite", "action": "attack", "target": "that"}
	assert_true(MacroRunner.match_line(sim, sim.current, weak) == null, "ingen är Förblindad")
	foe.auras["blind"] = {"turns": 2}
	assert_eq(MacroRunner.match_line(sim, sim.current, weak), foe)
	var next := MacroRunner.match_line(sim, sim.current, {"subject": "any_enemy", "cond": "next_in_turn", "action": "attack",
			"target": "that"})
	var any_next := next if next != null else MacroRunner.match_line(sim, sim.current, {"subject": "any_ally",
			"cond": "next_in_turn", "action": "defend"})
	assert_true(any_next != null and any_next.id == sim.order[0], "näst i tur är den första i kön")


func test_legacy_profile_keeps_everything_in_its_macros() -> void:
	var path := "user://test_gambits_legacy.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 10)  # sparad före gambits: nyckeln saknas
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq(p.gambits_state, "legacy")
	var macros: Dictionary = data.macros.duplicate(true)
	var longest := Gambits.most_lines(macros, data)
	p.setup_gambits(data, macros)
	for m in macros.values():
		for l in m.lines:
			assert_true(Gambits.line_owned(data, l, p.gambits), "gammal rad låst: %s" % MacroRunner.describe_line(data, l))
	assert_true(p.gambits.has("g_hp_below"), "alla gränser för ett villkor man äger")
	assert_true(Gambits.line_owned(data, _line("hp_below", 10), p.gambits))
	assert_eq(p.gambit_slot_floor, longest)
	for hero_id in macros:
		if data.heroes.has(hero_id):
			var before: Array = macros[hero_id].lines
			var after: Array = Gambits.playable(data, macros[hero_id], p.gambits, p.gambit_slots(data, hero_id)).lines
			assert_eq(after.size(), before.size(), hero_id)
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.gambits_state, "ok", "migreringen görs bara en gång")
	assert_eq(q.gambits.size(), p.gambits.size())
	assert_eq(q.found_rows.size(), p.found_rows.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_version_1_profile_keeps_its_conditions_and_subjects() -> void:
	# 0.30.50: villkoren ägdes utan gränser och subjekt. Allt i makrona och allt man ägde finns kvar.
	var path := "user://test_gambits_v1.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "gambits", ["g_lowest_hp", "g_hp_below", "g_alive", "g_buffs"])
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_eq(p.gambits_state, "legacy")
	var macros := {"x": {"lines": [_line("hp_below", 30, "attack", "enemy_3"), _line("lowest_hp", 0, "attack", "any_enemy",
			"random_enemy")]}}
	p.setup_gambits(data, macros)
	for l in macros.x.lines:
		assert_true(Gambits.line_owned(data, l, p.gambits), MacroRunner.describe_line(data, l))
	assert_true(Gambits.line_owned(data, _line("hp_below", 70), p.gambits), "Liv under … ägdes helt")
	assert_true(Gambits.line_owned(data, _line("is_alive"), p.gambits))
	assert_true(not Gambits.line_owned(data, _line("hp_above", 50), p.gambits), "men inget nytt")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_found_rows_roundtrip() -> void:
	var path := "user://test_gambits_rows.cfg"
	var p := Profile.new()
	p.setup_gambits(data, {})
	p.recruit(data, "brokk")
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.gambits_state, "ok")
	assert_eq(q.found_rows.size(), p.found_rows.size())
	assert_eq(q.found_rows[1].hero, "brokk")
	assert_eq(q.found_rows[1].line.action, "provoke")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_slots_grow_with_level() -> void:
	assert_eq(Gambits.slots_for_level(data, 1), 3)
	assert_eq(Gambits.slots_for_level(data, 2), 3)
	assert_eq(Gambits.slots_for_level(data, 3), 4)
	assert_eq(Gambits.slots_for_level(data, 5), 5)
	assert_eq(Gambits.slots_for_level(data, 19), 12)
	assert_eq(Gambits.slots_for_level(data, 60), 12, "taket")
	assert_eq(Gambits.next_slot_level(data, 1), 3)
	assert_eq(Gambits.next_slot_level(data, 19), 0)
	var p := Profile.new()
	p.gambit_slot_floor = 9
	assert_eq(p.gambit_slots(data, "paladin"), 9, "en gammal profil behåller sina platser")


func test_playable_drops_unowned_disabled_and_beyond_slots() -> void:
	var owned := ["g_lowest_hp", "g_hp_below@50", "g_alive"]
	var off := _line("lowest_hp")
	off.enabled = false
	var macro := {"lines": [_line("has_trait", "grave_pact"), off, _line("hp_below", 50), _line("is_alive"),
			_line("lowest_hp")]}
	var lines: Array = Gambits.playable(data, macro, owned, 3).lines
	assert_eq(lines.size(), 2, "oägd och avstängd bort, femte raden utanför platserna")
	assert_eq(lines[0].cond, "hp_below")
	assert_eq(Gambits.line_states(data, macro.lines, owned, 3), ["locked", "off", "ok", "ok", "beyond"])
	assert_eq(Gambits.used_slots(data, macro.lines, owned), 4)
	assert_eq(Gambits.playable(data, macro, null, 20).lines.size(), 4, "utan ägande: bara avstängda bort")
	# En gräns profilen inte äger låser raden.
	assert_eq(Gambits.line_states(data, [_line("hp_below", 20)], owned, 3), ["locked"])


func test_chain_is_kept_whole_or_not_at_all() -> void:
	var owned := ["g_lowest_hp", "g_hp_below@80", "g_hp_below@40"]
	var macro := {"lines": [_line("hp_below", 80, "test_next", "any_ally"), _line("hp_below", 40, "defend", "any_ally"),
			_line("lowest_hp")]}
	var lines: Array = Gambits.playable(data, macro, owned, 10).lines
	assert_eq(lines.size(), 1, "kedjan kräver Kedja")
	owned.append("g_chain")
	assert_eq(Gambits.playable(data, macro, owned, 10).lines.size(), 3)
	assert_eq(Gambits.playable(data, macro, owned, 1).lines.size(), 2, "en kedja tar en plats")


func test_runner_skips_disabled_line() -> void:
	var sim := CombatSim.create(data, "crypt_1", 3, ["paladin"])
	sim.begin()
	while not sim.needs_input():
		sim.ai_act()
	var first := _line("is_alive", 0, "defend", "self")
	var macro := {"lines": [first, _line("lowest_hp")]}
	assert_eq(MacroRunner.decide(sim, sim.current, macro).action, "defend")
	first.enabled = false
	var d := MacroRunner.decide(sim, sim.current, macro, true)
	assert_eq(d.action, "attack", "den avstängda raden hoppas över")
	assert_true(d.notes.any(func(n: String) -> bool: return n.contains("avstängd")))


func test_battle_drop_from_home() -> void:
	var owned := ["g_lowest_hp"]
	var got := {}
	var rng := RandomNumberGenerator.new()
	for seed_value in 200:
		rng.seed = seed_value
		var id := Gambits.roll_battle(data, owned, ["bell_ringer"], rng)
		got[id] = int(got.get(id, 0)) + 1
	assert_eq(int(got.get("g_deaths", 0)), 200, "Klockaren ger alltid Har stupat (boss 100 %)")
	owned.append("g_deaths")
	got = {}
	for seed_value in 400:
		rng.seed = seed_value
		var id := Gambits.roll_battle(data, owned, ["skeleton_warrior"], rng)
		got[id] = int(got.get(id, 0)) + 1
	assert_true(not got.has("g_deaths"))
	assert_true(got.has("g_hp_below@50") and got.has("g_hp_above@50") and got.has("g_alive"), "Skelettkrigarens klossar: %s" % [got])
	assert_true(not got.has("g_hp_below@10"), "skarpa gränser bara hos svåra fiender")
	assert_true(got.get("", 0) > 120, "ofta inget")
	# En ägd familj (gamla profiler) ger inga av sina gränser.
	got = {}
	for seed_value in 200:
		rng.seed = seed_value
		got[Gambits.roll_battle(data, ["g_hp_below", "g_hp_above", "g_alive"], ["skeleton_warrior"], rng)] = true
	assert_true(not got.keys().any(func(id: String) -> bool: return id.begins_with("g_hp_")))


func test_anywhere_drop_is_common_only() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in 300:
		rng.seed = seed_value
		var id := Gambits.roll_battle(data, ["g_lowest_hp"], ["finns_inte"], rng)
		if id != "":
			assert_eq(Gambits.entry(data, id).rarity, "common", id)


func test_chest_drop_respects_depth() -> void:
	var rng := RandomNumberGenerator.new()
	var seen := {}
	for seed_value in 300:
		rng.seed = seed_value
		seen[Gambits.roll_chest(data, ["g_lowest_hp"], 1, rng)] = true
	assert_true(seen.has("g_omen"))
	assert_true(not seen.has("g_artifact"), "Artefakt först från djup 2")
	seen = {}
	for seed_value in 300:
		rng.seed = seed_value
		seen[Gambits.roll_chest(data, ["g_lowest_hp"], 2, rng)] = true
	assert_true(seen.has("g_artifact"))


func test_needs_covers_chain_subject_and_target() -> void:
	assert_eq(Gambits.needs(data, _line("is_alive", 0, "test_next")), ["g_alive", "g_chain"])
	assert_eq(Gambits.needs(data, _line("hp_below", 50, "attack", "all_enemies", "enemy_2")),
			["g_hp_below@50", "g_all_enemies", "g_enemy_n"])
	assert_eq(Gambits.used_in(data, {"a": {"lines": [_line("own_turn", 1)]}}), ["g_own_turn"])
