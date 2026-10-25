extends "res://tests/test_case.gd"
## Balanssimuleringens hjälpfunktioner (tests/balance_report.gd, BALANS=sim): flaggor mot målen, reservanfallen,
## det kedjade nedstigningsmålet och mötena ur datan. Och textspelets kontroll av makrorader.

const Report := preload("res://tests/balance_report.gd")
const Bot := preload("res://tests/combat_bot.gd")
const TextPlay := preload("res://tests/text_play.gd")

var _data := GameData.load_all()


func test_win_flag_against_band() -> void:
	assert_eq(Report.sim_win_flag(40.0, [60, 75]), "FÖR SVÅR")
	assert_eq(Report.sim_win_flag(80.0, [60, 75]), "FÖR LÄTT")
	assert_eq(Report.sim_win_flag(60.0, [60, 75]), "", "gränsen räknas som innanför")
	assert_eq(Report.sim_win_flag(75.0, [60, 75]), "")
	assert_eq(Report.sim_win_flag(10.0, []), "", "inget mål, ingen flagga")
	assert_near(Report.sim_outside(40.0, [60, 75]), 20.0)
	assert_near(Report.sim_outside(90.0, [60, 75]), 15.0)
	assert_near(Report.sim_outside(70.0, [60, 75]), 0.0)


func test_level_flags_flat_and_steep() -> void:
	var ok := Report.sim_level_flags(40.0, 55.0, 70.0)
	assert_eq(ok[0], [], "15 ned och 15 upp ligger i bandet")
	var flat := Report.sim_level_flags(50.0, 55.0, 60.0)
	assert_eq(flat[0], ["PLATT NIVÅ"])
	assert_near(float(flat[1]), 5.0)
	var steep := Report.sim_level_flags(10.0, 55.0, 70.0)
	assert_eq(steep[0], ["BRANT NIVÅ"])
	assert_near(float(steep[1]), 25.0)
	var both := Report.sim_level_flags(52.0, 55.0, 90.0)
	assert_true(both[0].has("PLATT NIVÅ") and both[0].has("BRANT NIVÅ"))


func test_level_flags_ignore_saturated_side() -> void:
	# Redan 100 %: en nivå till kan inte ge mer, så bara tappet nedåt räknas.
	assert_eq(Report.sim_level_flags(85.0, 100.0, 100.0)[0], [])
	# 0 %: en nivå ned kan inte kosta något, bara vinsten uppåt räknas.
	assert_eq(Report.sim_level_flags(0.0, 0.0, 3.0)[0], ["PLATT NIVÅ"])


func test_reserve_pct_counts_fallbacks_per_decision() -> void:
	assert_near(Report.sim_reserve_pct(3, 20), 15.0)
	assert_near(Report.sim_reserve_pct(0, 0), 0.0, 0.001, "inga beslut ger 0, inte ett fel")
	var row := Report.sim_fight_row([
		{"outcome": "victory", "turns": 10, "units": 5, "deaths": 0, "alive": 4, "no_match": 1, "decisions": 4, "generic": 2},
		{"outcome": "defeat", "turns": 30, "units": 5, "deaths": 4, "alive": 0, "no_match": 3, "decisions": 6, "generic": 6}])
	assert_near(float(row.vinst_pct), 50.0)
	assert_near(float(row.reservanfall_pct), 40.0, 0.001, "4 reservanfall av 10 beslut")
	assert_near(float(row.standardanfall_pct), 80.0)
	assert_near(float(row.dod_minst_en_pct), 50.0)
	assert_near(float(row.lagwipe_pct), 50.0)


func test_macro_flag_above_limit() -> void:
	var rows := [_row({"reservanfall_pct": 16.0}), _row({"reservanfall_pct": 15.0, "mote": "b"})]
	Report.sim_flag(rows)
	assert_true(String(rows[0].flagga).contains("MAKRO"))
	assert_true(not String(rows[1].flagga).contains("MAKRO"), "15 % är gränsen, inte över")


func test_run_fight_counts_reserve_when_no_line_matches() -> void:
	# Ett makro med en rad som aldrig stämmer: varje hjältetur blir ett reservanfall.
	var macros := {"paladin": {"lines": [{"subject": "self", "cond": "hp_below", "value": 0, "action": "attack",
			"target": "that"}]}}
	var r := Bot.run_fight(_data, 1, Bot.Skill.MACRO, "crypt_1a", ["paladin"], {}, {}, {}, 1,
			{"bot_macros": macros, "levels": Bot.party_levels(_data, 3, ["paladin"])})
	assert_true(int(r.decisions) > 0)
	assert_eq(int(r.no_match), int(r.decisions), "ingen rad passade någon gång")


func test_wrong_warning_only_for_four_in_a_realm_for_five() -> void:
	var r := _row({"typ": "boss", "matning": "strid_tomd", "vinst_pct": 50.0, "_realm_size": 5, "lag": 4})
	assert_true(Report.sim_wrong_warning(r))
	r.vinst_pct = 30.0
	assert_true(not Report.sim_wrong_warning(r))
	r.vinst_pct = 50.0
	r.lag = 5
	assert_true(not Report.sim_wrong_warning(r), "fem i berget är det berget är byggt för")
	r.lag = 4
	r._realm_size = 4
	assert_true(not Report.sim_wrong_warning(r), "kryptan är byggd för fyra")


func test_chain_band_multiplies_per_fight_targets() -> void:
	var band := Report.sim_chain_band({"vanlig": 2.0, "boss": 1.0})
	assert_eq(band, [roundi(100.0 * 0.93 * 0.93 * 0.5), roundi(100.0 * 0.98 * 0.98 * 0.65)])
	assert_eq(Report.sim_chain_band({}), [100, 100])
	var death := Report.sim_chain_death_band({"boss": 1.0})
	assert_eq(death, [40, 60])


func test_cases_come_from_data() -> void:
	for realm_id in _data.realms:
		for depth in [1, 2, 3]:
			var cases := Report.sim_cases(_data, realm_id, depth)
			var types := {}
			for c in cases:
				assert_true(_data.encounters.has(c.enc), "%s finns i encounters.json" % c.enc)
				types[c.type] = true
			assert_true(types.has("vanlig") and types.has("elit") and types.has("nemesis"), "%s d%d" % [realm_id, depth])
			assert_true(types.has("boss") or types.has("väktare"))
	# Kryptan: huvudbossen på djup 1, väktarna på djup 2 och 3.
	var last: Dictionary = Report.sim_cases(_data, "crypt", 1).back()
	assert_eq(last.type, "boss")
	assert_eq(last.enc, _data.realms.crypt.floors.back())
	assert_eq(Report.sim_cases(_data, "crypt", 2).back().type, "väktare")


func test_expected_level_counts_realm_depth_offset() -> void:
	assert_eq(Report.sim_expected_level(_data, "crypt", 1), HeroStats.expected_level(1))
	var off := RunState.realm_depth_offset(_data, "mountain")
	assert_eq(Report.sim_expected_level(_data, "mountain", 1), HeroStats.expected_level(1 + off))


func test_sim_macros_are_starter_lines_with_hints() -> void:
	var m := Report.sim_macros(_data, ["paladin", "alva"])
	var hint: Dictionary = _data.heroes.alva.macro_hint.line
	assert_eq(m.alva.lines[0].cond, hint.cond, "makroförslaget först, som när spelaren lägger till raden")
	assert_eq(m.paladin.lines.size(), 1, "Paladinen har introts enda rad")


func test_drained_charges_fall_back_to_type() -> void:
	var by := {"elit f1": {"alva": {"renew": 2}}, "elit": {"alva": {"renew": 4}}}
	assert_eq(Report.sim_drained(by, {"type": "elit", "floor": 1}).alva.renew, 2)
	assert_eq(Report.sim_drained(by, {"type": "elit", "floor": 0}).alva.renew, 4)
	assert_eq(Report.sim_drained(by, {"type": "boss", "floor": 1}), {})
	assert_eq(Report.sim_avg_charges([{"a": {"x": 1}}, {"a": {"x": 4}}]).a.x, 3)


func test_csv_roundtrip() -> void:
	var path := "user://test_balans_sim.csv"
	var r := _row({"mote": "a,b", "flagga": "FÖR SVÅR;MAKRO"})
	Report.sim_write_csv([r], path)
	var back := Report.sim_read_csv(path)
	assert_eq(back.size(), 1)
	assert_eq(back[0].mote, "a,b")
	assert_eq(back[0].flagga, "FÖR SVÅR;MAKRO")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# --- Textspelets makrorader ---------------------------------------------------------------------------------------

func test_text_play_rejects_unknown_ids() -> void:
	var line := {"subject": "any_enemy", "cond": "has_status", "value": "bleed", "action": "attack", "target": "that"}
	assert_true(TextPlay.validate_line(_data, line, "paladin").contains("bleed"))
	line.value = "bleeding"
	assert_eq(TextPlay.validate_line(_data, line, "paladin"), "")
	var trait_line := {"subject": "any_enemy", "cond": "has_trait", "value": "protective_prayer", "action": "attack",
			"target": "that"}
	assert_true(TextPlay.validate_line(_data, trait_line, "paladin") != "")
	trait_line.value = "cultist_ward"
	assert_eq(TextPlay.validate_line(_data, trait_line, "paladin"), "")
	var ability := {"subject": "any_enemy", "cond": "lowest_hp", "action": "ability", "ability": "judgement", "target": "that"}
	assert_true(TextPlay.validate_line(_data, ability, "paladin") != "", "Paladinen har inte Alvas förmåga")
	assert_eq(TextPlay.validate_line(_data, ability, "alva"), "")
	ability.ability = "judgment"
	assert_true(TextPlay.validate_line(_data, ability, "") != "")
	assert_true(TextPlay.validate_line(_data, {"subject": "anyone", "cond": "is_alive", "action": "attack"}) != "")


func test_text_play_accepts_all_starter_macros() -> void:
	for id in _data.macros:
		for line in _data.macros[id].lines:
			var hero: String = id if _data.heroes.has(id) else ""
			assert_eq(TextPlay.validate_line(_data, line, hero), "", "%s: %s" % [id, str(line)])


func _row(extra: Dictionary) -> Dictionary:
	var r := {"rike": "crypt", "djup": 1, "mote": "a", "typ": "elit", "lag": 4, "niva": 3, "n": 10, "vinst_pct": 75.0,
			"turer_median": 10.0, "turer_p90": 12.0, "rundor_median": 2.0, "dod_minst_en_pct": 0.0, "lagwipe_pct": 0.0,
			"reservanfall_pct": 0.0, "matning": "strid_full", "vaning": 1, "strider": "", "laddningar_kvar_pct": 100,
			"_exp": true, "_realm_size": 4}
	r.merge(extra, true)
	return r
