extends "res://tests/test_case.gd"
## Djupets tecken (0.30.45, docs/plan/mot-upprepning.md §3): en regel per nedstigning som gäller båda sidor.

var _data := GameData.load_all()
const PARTY := ["paladin", "alva", "imma", "eira"]


func _sim(omen := "", seed_value := 3) -> CombatSim:
	var rules := [] if omen == "" else [omen]
	var sim := CombatSim.create(_data, "crypt_1", seed_value, PARTY, {}, {}, {}, 1, {"rules": rules})
	for e in _foes(sim):
		e.max_hp = 100000.0
		e.hp = e.max_hp
	return sim


func _foes(sim: CombatSim) -> Array:
	return sim.units.filter(func(x: CombatUnit) -> bool: return x.team == 1)


func _dealt(sim: CombatSim, src: CombatUnit, tgt: CombatUnit, ability_id: String) -> float:
	var before := tgt.hp
	sim._deal_damage(src, tgt, 100.0, "holy", ability_id, false, true, "spell", false)
	return before - tgt.hp


func test_omens_exist_with_name_text_and_lines() -> void:
	var ids := RunState.omen_ids(_data)
	assert_eq(ids.size(), 6)
	for id in ids:
		var r: Dictionary = _data.floor_rules[id]
		assert_true(r.has("name") and r.has("text") and not r.has("silver"), "%s: namn, text och inget silver" % id)
		var lines: Dictionary = _data.dialog.omens.get(id, {})
		assert_true(String(lines.narrator.id).begins_with("omen_") and String(lines.sven.id).ends_with("_sven"), id)
	assert_true(_data.help.entries.has("omens") and (_data.help.order as Array).has("omens"))


func test_instability_never_draws_an_omen() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in 60:
		rng.seed = seed_value
		for level in RunState.MAX_INSTABILITY + 1:
			var r := RunState.roll_rules(_data, level, rng)
			for id in r.visible + r.hidden:
				assert_true(not RunState.is_omen(_data, id), "%s är ett tecken" % id)


func test_roll_omen_skips_the_last_one() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 40:
		var o := RunState.roll_omen(_data, rng, "omen_full_moon")
		assert_true(RunState.is_omen(_data, o) and o != "omen_full_moon")


func test_omen_is_saved_and_goes_into_battle_rules() -> void:
	var s := RunState.new()
	s.set_realm(_data, "crypt")
	s.omen = "omen_holy_ground"
	s.start_expedition(_data, 5)
	var t := RunState.from_dict(s.to_dict())
	assert_eq(t.omen, "omen_holy_ground")
	assert_true((t.battle_opts().rules as Array).has("omen_holy_ground"))
	assert_true(not t.active_rules().has("omen_holy_ground"), "tecknet är inte instabilitet")
	assert_near(t.silver_mult(_data), 1.0, 0.0001, "inget extra silver")
	var p := Profile.new()
	p.omen = "omen_echo_vault"
	p.omen_rerolled = true
	var path := "user://test_omen_profile.cfg"
	p.save(path)
	var q := Profile.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_eq(q.omen, "omen_echo_vault")
	assert_true(q.omen_rerolled)


func test_full_moon_doubles_crit_bonus_for_both_sides() -> void:
	for omen in ["", "omen_full_moon"]:
		var sim := _sim(omen)
		var pal := sim.unit("paladin")
		var foe: CombatUnit = _foes(sim)[0]
		pal.crit_chance = 10.0
		foe.crit_chance = 10.0
		var found := {}
		for i in 30:
			sim._deal_damage(pal, foe, 1.0, "physical", "strike", true, true, "attack", true)
			sim._deal_damage(foe, pal, 1.0, "physical", foe.attack_ability, true, true, "attack", true)
			pal.hp = pal.max_hp
			for e in sim.drain_events():
				if e.type == "damage" and e.get("calc", {}).get("crit", false):
					var c: Dictionary = e.calc
					var ratio: float = c.source_speed / maxf(c.target_speed, 1.0)
					found[c.source] = float(c.crit_bonus) / CombatSim.crit_bonus(ratio)
		assert_eq(found.size(), 2, "båda sidor kritar")
		for id in found:
			assert_near(found[id], 2.0 if omen != "" else 1.0, 0.001, "%s %s" % [omen, id])


func test_holy_ground_heals_more_for_everyone() -> void:
	var plain := _sim()
	var holy := _sim("omen_holy_ground")
	for sim in [plain, holy]:
		sim.unit("paladin").hp = 1.0
		_foes(sim)[0].hp = 1.0
		sim._heal(sim.unit("alva"), sim.unit("paladin"), 20.0, "healing_light")
		sim._heal(_foes(sim)[1] if _foes(sim).size() > 1 else _foes(sim)[0], _foes(sim)[0], 20.0, "")
	assert_near(holy.unit("paladin").hp - 1.0, (plain.unit("paladin").hp - 1.0) * 1.25, 1.0)
	assert_near(_foes(holy)[0].hp - 1.0, (_foes(plain)[0].hp - 1.0) * 1.25, 1.0)


func test_last_strength_only_below_half_health() -> void:
	var plain := _sim()
	var last := _sim("omen_last_strength")
	var base := _dealt(plain, plain.unit("paladin"), _foes(plain)[0], "")
	assert_near(_dealt(last, last.unit("paladin"), _foes(last)[0], ""), base, 0.6, "fullt liv: ingen skillnad")
	last.unit("paladin").hp = last.unit("paladin").max_hp * 0.4
	assert_near(_dealt(last, last.unit("paladin"), _foes(last)[0], ""), base * 1.25, 0.6)
	var foe: CombatUnit = _foes(last)[0]
	foe.hp = foe.max_hp * 0.3
	for sim in [plain, last]:
		sim.unit("alva").max_hp = 10000.0
		sim.unit("alva").hp = 10000.0
	var hit_plain := _dealt(plain, _foes(plain)[0], plain.unit("alva"), "")
	var hit_last := _dealt(last, foe, last.unit("alva"), "")
	assert_near(hit_last, hit_plain * 1.25, 0.6, "fienden också")


func test_narrow_pass_single_up_multi_down() -> void:
	var plain := _sim()
	var narrow := _sim("omen_narrow_pass")
	var imma_p := plain.unit("imma")
	var imma_n := narrow.unit("imma")
	var single := _dealt(plain, imma_p, _foes(plain)[0], "spark_arrow")
	var multi := _dealt(plain, imma_p, _foes(plain)[0], "smoke_arrow")
	assert_near(_dealt(narrow, imma_n, _foes(narrow)[0], "spark_arrow"), single * 1.25, 0.6)
	assert_near(_dealt(narrow, imma_n, _foes(narrow)[0], "smoke_arrow"), multi * 0.75, 0.6)
	assert_true(CombatSim.is_multi_target(_data.abilities.arrow_rain))
	assert_true(not CombatSim.is_multi_target(_data.abilities.holy_smite))


func test_echo_vault_every_third_ability_twice_without_charge() -> void:
	var sim := _sim("omen_echo_vault")
	var alva := sim.unit("alva")
	var foe: CombatUnit = _foes(sim)[0]
	var start := int(alva.charges.judgement)
	var echoes := 0
	for i in 6:
		if i == 2 or i == 5:
			assert_true(sim.next_ability_echoes(alva), "förmåga %d ekar" % (i + 1))
			assert_true(MacroRunner.test_condition(sim, alva, alva, {"cond": "next_ability_echoes"}, [alva]))
		else:
			assert_true(not sim.next_ability_echoes(alva))
		sim._perform(alva, "judgement", "ability", foe.id)
		for e in sim.drain_events():
			if e.type == "action" and e.action == "echo":
				echoes += 1
	assert_eq(echoes, 2)
	assert_eq(int(alva.charges.judgement), start - 6, "ekot kostar ingen Charge")
	assert_eq(alva.omen_casts, 6, "ekot räknas inte som en ny förmåga")
	# Anfall räknas inte.
	sim._perform(alva, alva.attack_ability, "attack", foe.id)
	assert_eq(alva.omen_casts, 6)
	var plain := _sim()
	for i in 3:
		plain._perform(plain.unit("alva"), "judgement", "ability", _foes(plain)[0].id)
	assert_true(not plain.drain_events().any(func(e: Dictionary) -> bool: return e.type == "action" and e.action == "echo"))


func test_echo_retargets_when_the_target_died() -> void:
	var sim := _sim("omen_echo_vault")
	var alva := sim.unit("alva")
	var foes := _foes(sim)
	if foes.size() < 2:
		return
	alva.omen_casts = 2
	var first: CombatUnit = foes[0]
	first.hp = 1.0
	first.max_hp = 1.0
	sim._perform(alva, "judgement", "ability", first.id)
	var echo := sim.drain_events().filter(func(e: Dictionary) -> bool: return e.type == "action" and e.action == "echo")
	assert_eq(echo.size(), 1)
	assert_true(not (echo[0].targets as Array).has(first.id), "ekot går till ett levande mål")


func test_quiet_mass_first_ability_is_free_once_per_battle() -> void:
	var sim := _sim("omen_quiet_mass")
	var alva := sim.unit("alva")
	var foe: CombatUnit = _foes(sim)[0]
	var start := int(alva.charges.judgement)
	assert_true(sim.free_ability_unused(alva))
	assert_true(MacroRunner.test_condition(sim, alva, alva, {"cond": "free_ability_unused"}, [alva]))
	sim._perform(alva, "judgement", "ability", foe.id)
	assert_eq(int(alva.charges.judgement), start, "den första är gratis")
	assert_true(not sim.free_ability_unused(alva))
	sim._perform(alva, "judgement", "ability", foe.id)
	assert_eq(int(alva.charges.judgement), start - 1)
	# Utan Charges kvar går den gratis förmågan ändå att använda (en gång).
	var s2 := _sim("omen_quiet_mass")
	var pal := s2.unit("paladin")
	pal.charges.holy_smite = 0
	assert_eq(s2.can_act(pal, "ability", "holy_smite"), "")
	s2._perform(pal, "holy_smite", "ability", _foes(s2)[0].id)
	assert_eq(int(pal.charges.holy_smite), 0)
	assert_eq(s2.can_act(pal, "ability", "holy_smite"), "charges")
	var plain := _sim()
	plain._perform(plain.unit("alva"), "judgement", "ability", _foes(plain)[0].id)
	assert_eq(int(plain.unit("alva").charges.judgement), start - 1)


func test_omen_is_condition_and_editor_text() -> void:
	var sim := _sim("omen_full_moon")
	var pal := sim.unit("paladin")
	assert_true(MacroRunner.test_condition(sim, pal, pal, {"cond": "omen_is", "value": "omen_full_moon"}, [pal]))
	assert_true(not MacroRunner.test_condition(sim, pal, pal, {"cond": "omen_is", "value": "omen_holy_ground"}, [pal]))
	assert_eq(MacroRunner.condition_name(_data, "omen_is", "omen_full_moon"), "tecknet är Fullmåne")
	for c in ["omen_is", "next_ability_echoes", "free_ability_unused"]:
		assert_true(MacroRunner.CONDITIONS.has(c))
		assert_true(MacroRunner.condition_name(_data, c, "omen_full_moon") != c, "%s har svensk text" % c)
	assert_true(MacroRunner.action_label(_data, "ability", "arrow_rain").ends_with("(alla)"))
	var line := {"subject": "self", "cond": "omen_is", "value": "omen_narrow_pass", "action": "attack", "target": "that"}
	assert_eq(load("res://tests/text_play.gd").validate_line(_data, line), "")
	line.value = "nope"
	assert_true(load("res://tests/text_play.gd").validate_line(_data, line) != "")
	# Tecknet kommer med i striden genom reglerna.
	assert_eq(sim.omen, "omen_full_moon")
	assert_eq(_sim().omen, "")
