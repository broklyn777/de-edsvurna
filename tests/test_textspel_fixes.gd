extends "res://tests/test_case.gd"
## Felen från textspelet (docs/provspel/textspel-dagbok.md, "Fel jag hittade"): egenskapen som går i arv, repliker som
## nämner någon som inte är med, timglasets avstängda val, händelsen "fäll biskopen", elitvarianter på gruppens kort,
## väktarens troférräkning och nivån en befriad lärjunge ansluter på.

var _data := GameData.load_all().duplicate(true)


func _enemy(sim: CombatSim, kind: String, n := 1) -> CombatUnit:
	var seen := 0
	for e in sim.enemies:
		if e.kind == kind:
			seen += 1
			if seen == n:
				return e
	return null


# --- 1. "Jägarinstinkt går vidare till Kistbärare 2" ----------------------------

func test_passed_trait_keeps_its_own_name_inside_another_trait() -> void:
	var sim := CombatSim.create(_data, "crypt_g2", 3, ["paladin", "brokk", "alva", "eira"])
	var lid := _enemy(sim, "coffin_bearer", 1)
	sim.drain_events()
	# Som när Eiras Jägarinstinkt fäller kistbäraren: döden sker inifrån en annan egenskap.
	sim._trait_ctx = "eira_followup"
	lid.hp = 1.0
	sim._kill(lid)
	sim._trait_ctx = ""
	var passed := sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "trait_passed")
	assert_eq(passed.size(), 1)
	assert_eq(passed[0].trait, "council_lid", "rådets egenskap, inte Jägarinstinkt")
	assert_eq(passed[0].get("ctx_trait", ""), "eira_followup", "egenskapen som skickade händelsen står kvar")


func test_trait_events_outside_a_trait_are_unchanged() -> void:
	var sim := CombatSim.create(_data, "crypt_g2", 3, ["paladin", "brokk", "alva", "eira"])
	sim.drain_events()
	sim._trait_ctx = "eira_followup"
	sim._emit({"type": "turn_note", "unit": sim.heroes[0].id})
	sim._trait_ctx = ""
	var ev := sim.drain_events()
	assert_eq(ev[0].get("trait", ""), "eira_followup", "vanliga händelser märks fortfarande med egenskapen")


# --- 2. "Ja, du också, Imma" utan Imma -------------------------------------------

func test_lines_need_everyone_they_name() -> void:
	var line := "Drick vatten. Alla. Ja, du också, Imma."
	assert_true(Dialog.mentioned(_data, line).has("imma"))
	assert_true(not Dialog.present(_data, line, ["paladin", "alva"]), "Imma sitter i Värdshuset")
	assert_true(Dialog.present(_data, line, ["paladin", "alva", "imma"]))
	assert_true(Dialog.present(_data, "Välkommen. Var har du ont?", ["paladin", "alva"]), "ingen nämns")
	assert_true(Dialog.mentioned(_data, {"text": "x", "needs": ["brokk"]}).has("brokk"), "needs i datan")


func test_campfire_bark_without_imma_never_names_her() -> void:
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var b := Dialog.bark(_data, "campfire", ["paladin", "alva"], [], rng)
		for l in b.get("lines", []):
			assert_true(not String(l.text).contains("Imma"), "seed %d: %s" % [seed_value, l.text])


func test_pairs_need_all_speakers() -> void:
	var data := {"heroes": _data.heroes, "dialog": {"pairs": [{"heroes": ["imma", "alva"], "kind": "campfire",
			"lines": [["imma", "Hej."], ["brokk", "Hm."]]}], "barks": {}}}
	var rng := RandomNumberGenerator.new()
	assert_true(Dialog.bark(data, "campfire", ["paladin", "imma", "alva"], [], rng).is_empty(), "Brokk talar men är inte med")
	assert_true(not Dialog.bark(data, "campfire", ["paladin", "imma", "alva", "brokk"], [], rng).is_empty())


# --- 3. Timglasets avstängda val ---------------------------------------------------

func test_hourglass_disabled_choice_has_its_own_text() -> void:
	var s := RunState.new_run(Profile.new(), _data)
	s.start_expedition(_data, 5)
	s.map.cells[s.pos] = {"kind": "object", "obj": "hourglass"}
	s.charges.clear()
	var scout: Array = s.object_options(_data).filter(func(o: Dictionary) -> bool: return o.id == "scout")
	assert_true(scout[0].get("disabled", false))
	var text := String(scout[0].get("disabled_text", ""))
	assert_true(text != "" and not text.contains("Gedigen ek"), text)
	s.map.cells[s.pos] = {"kind": "object", "obj": "pew"}
	s.seen.clear()
	var bar: Array = s.object_options(_data).filter(func(o: Dictionary) -> bool: return o.id == "barricade")
	assert_true(String(bar[0].get("disabled_text", "")).contains("Gedigen ek"), "bänken behåller sin text")


# --- 4. "Fäll biskopen" klarades av Abbedissans kör --------------------------------

func test_guardian_does_not_count_as_the_main_boss() -> void:
	var s := RunState.new_run(Profile.new(), _data)
	s.set_realm(_data, "chapel")
	s.depth = 1
	assert_eq(WorldEvents.outcome_for(s, _data, "boss"), "boss", "djup 1: biskopen")
	s.depth = 2
	assert_true(RunState.guardian_for(_data, "chapel", 2) != "", "djup 2 leds av en väktare")
	assert_eq(WorldEvents.outcome_for(s, _data, "boss"), "guardian")
	assert_eq(WorldEvents.outcome_for(s, _data, "loss"), "loss")
	assert_true(not WorldEvents._won("boss", "guardian", 5, true, false), "väktaren stoppar inte högtiden")


func test_feast_survives_a_guardian_win() -> void:
	var p := Profile.new()
	p.intro_done = true
	WorldEvents.start(p, _data, "cult_feast", 3)
	var before := {}
	for r in _data.realms:
		before[r] = LivingMap.growth(p, r)
	var rep := WorldEvents.after_descent(p, _data, "chapel", "guardian", 6, true, before, false, 4)
	assert_true(rep.event_end.is_empty() or String(rep.event_end.result) != "won", "högtiden bröts inte av abbedissan")


# --- 5 och (a). Gruppens kort visar striden ----------------------------------------

func test_card_shows_the_same_elite_variants_as_the_battle() -> void:
	var s := RunState.new_run(Profile.new(), _data)
	s.instability = 3
	s.depth = 6  # hög elitchans, så att varianter dyker upp
	var checked := 0
	var rare := 0
	for seed_value in range(1, 12):
		s.start_expedition(_data, seed_value)
		for i in s.map.cells.size():
			if not s.map.has_group(i):
				continue
			s.pos = i
			var preview := s.group_preview(_data, i)
			var sim := CombatSim.create(_data, s.encounter(), 1000 + i, s.party, {}, {}, {}, s.depth, s.battle_opts())
			var shown: Array = preview.map(func(x: Dictionary) -> String: return x.name)
			var fought: Array = sim.enemies.map(func(u: CombatUnit) -> String: return u.name.trim_prefix("Nemesis: "))
			assert_eq(shown, fought, "ruta %d (%s)" % [i, s.encounter()])
			checked += 1
			if not s.rare_variants(_data, i).is_empty():
				rare += 1
				assert_true(s.rare_warning(_data, i).contains("sällsynt"), "varningen på kortet")
				assert_true(s.lineup_text(_data, i).contains(s.rare_variants(_data, i)[0].name))
	assert_true(checked > 20 and rare > 0, "%d grupper, %d med sällsynta varianter" % [checked, rare])


func test_battle_seed_does_not_change_the_variants() -> void:
	var s := RunState.new_run(Profile.new(), _data)
	s.instability = 3
	s.depth = 6
	s.start_expedition(_data, 4)
	var n := 0
	for i in s.map.cells.size():
		if s.map.has_group(i):
			s.pos = i
			var a := CombatSim.create(_data, s.encounter(), 1, s.party, {}, {}, {}, s.depth, s.battle_opts())
			var b := CombatSim.create(_data, s.encounter(), 99, s.party, {}, {}, {}, s.depth, s.battle_opts())
			assert_eq(a.enemies.map(func(u: CombatUnit) -> bool: return u.elite),
					b.enemies.map(func(u: CombatUnit) -> bool: return u.elite), "ruta %d" % i)
			n += 1
	assert_true(n > 0)


# --- (b). Väktarens trofé: räkningen och erbjudandet --------------------------------

func test_guardian_progress_says_when_the_trophy_comes() -> void:
	assert_true(RunState.guardian_progress(0).begins_with("0/2"))
	assert_true(RunState.guardian_progress(1).contains("nästa seger ger trofén"), RunState.guardian_progress(1))
	assert_true(RunState.guardian_progress(2).contains("erbjuds"))
	# Erbjudandet: väktarens trofé först när segrarna räcker (segern räknas före erbjudandet).
	var p := Profile.new()
	p.guardian_wins = {"crypt_g1": 1}
	assert_true(not p.unlocked_guardians().has("crypt_g1"))
	p.guardian_wins = {"crypt_g1": RunState.GUARDIAN_WINS_FOR_TROPHY}
	assert_true(p.unlocked_guardians().has("crypt_g1"))


# --- 7. Befriade lärjungar ansluter nära sällskapets nivå --------------------------

func test_rescued_disciples_join_near_the_party() -> void:
	assert_eq(Profile.join_level(1.0), 1)
	assert_eq(Profile.join_level(3.0), 1)
	assert_eq(Profile.join_level(4.0), 2, "som förut")
	# Nivåskalan (kurvan): två nivåer under i 0.19:s skala är mindre än en nivå högt upp.
	assert_eq(Profile.join_level(9.0, 9.0), 9, "Sefir: två under snittet (0.19:s skala), inte nivå 2")
	assert_eq(Profile.join_level(9.0, 5.0), 6, "aldrig över den svagaste + 1")
	var p := Profile.new()
	assert_true(p.recruit(_data, "sefir", 9.0, 8.0))
	assert_eq(int(p.hero(_data, "sefir").level), 9)
	assert_eq(int(p.hero(_data, "sefir").xp), 0)
	# Ikapphämtningen finns kvar för den som ligger under snittet.
	assert_true(Profile.catch_up(7.0, 9.0) > 1.0)
