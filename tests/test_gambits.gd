extends "res://tests/test_case.gd"
## Gambits (docs/plan/gambits.md): ägande, migrering av gamla profiler, avstängda rader, platser och droppar.

var data := GameData.load_all()


func _line(cond: String, value: Variant = 0, action := "attack", subject := "any_enemy") -> Dictionary:
	return {"subject": subject, "cond": cond, "value": value, "action": action, "ability": "", "target": "that"}


func test_every_condition_has_one_gambit_or_is_free() -> void:
	var seen := {}
	for id in Gambits.all(data):
		for cond in Gambits.all(data)[id].conds:
			assert_true(not seen.has(cond), "%s finns i två gambits" % cond)
			seen[cond] = id
			assert_true(MacroRunner.CONDITIONS.has(cond) or cond == "test_next", "okänt villkor %s" % cond)
	for cond in MacroRunner.CONDITIONS:
		assert_true(seen.has(cond), "%s saknar en gambit (alla villkor förtjänas)" % cond)


func test_every_home_and_teacher_exists() -> void:
	for id in Gambits.all(data):
		var g: Dictionary = Gambits.all(data)[id]
		assert_true(g.get("clue", "") != "", "%s saknar rykte" % id)
		for kind in g.get("homes", []):
			assert_true(data.enemies.has(kind), "%s: okänd fiende %s" % [id, kind])
		if not g.rarity in ["start", "chest"]:
			assert_true(not g.get("homes", []).is_empty(), "%s har inget hem" % id)
	for hero_id in data.gambits.teach:
		assert_true(data.heroes.has(hero_id), "okänd hjälte " + hero_id)
		assert_true(Gambits.all(data).has(data.gambits.teach[hero_id]), "okänt villkor för " + hero_id)


func test_new_profile_starts_with_starters() -> void:
	var p := Profile.new()
	p.setup_gambits(data, {})
	assert_eq(p.gambits_state, "ok")
	for id in ["g_lowest_hp", "g_hp_below", "g_alive"]:
		assert_true(p.gambits.has(id), id)
	assert_true(not p.gambits.has("g_deaths"), "sällsynta villkor förtjänas")
	assert_true(Gambits.line_owned(data, Run_FIRST_LINE(), p.gambits), "introts första rad är ägd")
	assert_eq(p.gambit_slot_floor, 0)


func Run_FIRST_LINE() -> Dictionary:
	return load("res://scripts/game/run.gd").FIRST_LINE


func test_recruit_teaches_condition() -> void:
	var p := Profile.new()
	p.setup_gambits(data, {})
	assert_true(not p.gambits.has("g_buffs"))
	p.recruit(data, "imma")
	assert_true(p.gambits.has("g_buffs"), "Imma lär ut buffar")
	assert_true(p.gambit_news.has("g_buffs"))
	assert_true(not p.learn_gambit(data, "g_buffs"), "redan ägt")
	assert_true(not p.learn_gambit(data, "finns_inte"))


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
	assert_eq(p.gambit_slot_floor, longest)
	for hero_id in macros:
		if data.heroes.has(hero_id):
			assert_true(p.gambit_slots(data, hero_id) >= Gambits.used_slots(data, macros[hero_id].lines, null),
					"%s fick färre platser" % hero_id)
			# Inget försvinner: striden kör samma rader som förut.
			var before: Array = macros[hero_id].lines
			var after: Array = Gambits.playable(data, macros[hero_id], p.gambits, p.gambit_slots(data, hero_id)).lines
			assert_eq(after.size(), before.size(), hero_id)
	# Sparad och läst igen: migreringen görs bara en gång.
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.gambits_state, "ok")
	assert_eq(q.gambits.size(), p.gambits.size())
	assert_eq(q.gambit_slot_floor, longest)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_slots_grow_with_level() -> void:
	assert_eq(Gambits.slots_for_level(data, 1), 3)
	assert_eq(Gambits.slots_for_level(data, 2), 3)
	assert_eq(Gambits.slots_for_level(data, 3), 4)
	assert_eq(Gambits.slots_for_level(data, 5), 5)
	assert_eq(Gambits.slots_for_level(data, 19), 12)
	assert_eq(Gambits.slots_for_level(data, 60), 12, "taket")
	assert_eq(Gambits.next_slot_level(data, 1), 3)
	assert_eq(Gambits.next_slot_level(data, 3), 5)
	assert_eq(Gambits.next_slot_level(data, 19), 0)
	var p := Profile.new()
	p.gambit_slot_floor = 9
	assert_eq(p.gambit_slots(data, "paladin"), 9, "en gammal profil behåller sina platser")


func test_playable_drops_unowned_disabled_and_beyond_slots() -> void:
	var owned := Gambits.starters(data)
	var off := _line("lowest_hp")
	off.enabled = false
	var macro := {"lines": [_line("has_trait", "grave_pact"), off, _line("hp_below", 50), _line("is_alive"),
			_line("lowest_hp")]}
	# Den oägda raden tar ingen plats; den avstängda tar sin (som i FF XII); med 3 platser hamnar den sista utanför.
	var lines: Array = Gambits.playable(data, macro, owned, 3).lines
	assert_eq(lines.size(), 2, "oägd och avstängd bort, femte raden utanför platserna")
	assert_eq(lines[0].cond, "hp_below")
	assert_eq(lines[1].cond, "is_alive")
	assert_eq(Gambits.line_states(data, macro.lines, owned, 3), ["locked", "off", "ok", "ok", "beyond"])
	assert_eq(Gambits.used_slots(data, macro.lines, owned), 4)
	assert_eq(Gambits.playable(data, macro, null, 20).lines.size(), 4, "utan ägande: bara avstängda bort")


func test_chain_is_kept_whole_or_not_at_all() -> void:
	var owned := Gambits.starters(data)
	var macro := {"lines": [_line("hp_below", 80, "test_next", "any_ally"), _line("hp_below", 40, "defend", "any_ally"),
			_line("lowest_hp")]}
	var lines: Array = Gambits.playable(data, macro, owned, 10).lines
	assert_eq(lines.size(), 1, "kedjan kräver Kedja")
	assert_eq(lines[0].cond, "lowest_hp")
	owned.append("g_chain")
	assert_eq(Gambits.playable(data, macro, owned, 10).lines.size(), 3)
	# En kedja tar en plats.
	assert_eq(Gambits.playable(data, macro, owned, 1).lines.size(), 2)
	assert_eq(Gambits.used_slots(data, macro.lines, owned), 2)


func test_runner_skips_disabled_line() -> void:
	var sim := CombatSim.create(data, "crypt_1", 3, ["paladin"])
	sim.begin()
	while not sim.needs_input():
		sim.ai_act()
	var first := _line("is_alive", 0, "defend", "self")
	var macro := {"lines": [first, _line("lowest_hp")]}
	var d := MacroRunner.decide(sim, sim.current, macro)
	assert_eq(d.action, "defend")
	first.enabled = false
	d = MacroRunner.decide(sim, sim.current, macro, true)
	assert_eq(d.action, "attack", "den avstängda raden hoppas över")
	assert_eq(d.line, 2)
	assert_true(d.notes.any(func(n: String) -> bool: return n.contains("avstängd")))
	# En avstängd rad i en kedja bryter kedjan.
	var chain := _line("is_alive", 0, "test_next", "self")
	chain.enabled = false
	d = MacroRunner.decide(sim, sim.current, {"lines": [chain, _line("is_alive", 0, "defend", "self"), _line("lowest_hp")]})
	assert_eq(d.action, "attack")


func test_battle_drop_from_home() -> void:
	var owned := Gambits.starters(data)
	var got := {}
	var rng := RandomNumberGenerator.new()
	for seed_value in 200:
		rng.seed = seed_value
		var id := Gambits.roll_battle(data, owned, ["bell_ringer", "skeleton_warrior"], rng)
		got[id] = int(got.get(id, 0)) + 1
	assert_eq(int(got.get("g_deaths", 0)), 200, "Klockaren ger alltid Har stupat (boss 100 %, före Benfurstens laddning)")
	# Med Har stupat ägt kommer Skelettkrigarens Liv över … ibland, och aldrig ett ägt villkor.
	owned.append("g_deaths")
	got = {}
	for seed_value in 400:
		rng.seed = seed_value
		var id := Gambits.roll_battle(data, owned, ["skeleton_warrior"], rng)
		got[id] = int(got.get(id, 0)) + 1
	assert_true(not got.has("g_deaths"))
	var pct := float(got.get("g_hp_above", 0)) / 400.0
	assert_true(pct > 0.3 and pct < 0.5, "Liv över … ungefär 40 %% (%.2f)" % pct)
	assert_true(got.get("", 0) > 150, "oftast inget")


func test_anywhere_drop_is_common_only() -> void:
	var owned := Gambits.starters(data)
	var rng := RandomNumberGenerator.new()
	for seed_value in 300:
		rng.seed = seed_value
		var id := Gambits.roll_battle(data, owned, ["finns_inte"], rng)
		if id != "":
			assert_eq(Gambits.all(data)[id].rarity, "common", id)


func test_chest_drop_respects_depth() -> void:
	var owned := Gambits.starters(data)
	var rng := RandomNumberGenerator.new()
	var seen := {}
	for seed_value in 300:
		rng.seed = seed_value
		seen[Gambits.roll_chest(data, owned, 1, rng)] = true
	assert_true(seen.has("g_omen"), "Djupets tecken i kistor från djup 1")
	assert_true(not seen.has("g_artifact"), "Artefakt först från djup 2")
	seen = {}
	for seed_value in 300:
		rng.seed = seed_value
		seen[Gambits.roll_chest(data, owned, 2, rng)] = true
	assert_true(seen.has("g_artifact"))


func test_needs_covers_chain_action() -> void:
	assert_eq(Gambits.needs(data, _line("is_alive", 0, "test_next")), ["g_alive", "g_chain"])
	assert_eq(Gambits.missing(data, _line("is_alive", 0, "test_next"), Gambits.starters(data)), "g_chain")
	assert_eq(Gambits.used_in(data, {"a": {"lines": [_line("own_turn", 1)]}}), ["g_own_turn"])
