extends "res://tests/test_case.gd"
## Makron som i Siralim Ultimate: se docs/plan/0.11-makron.md.

var _data := GameData.load_all()


func _sim() -> CombatSim:
	var sim := CombatSim.create(_data, "crypt_1", 42)
	sim.begin()
	return sim


func _line(subject: String, cond: String, value: Variant, action: String, ability := "", target := "that") -> Dictionary:
	return {"subject": subject, "cond": cond, "value": value, "action": action, "ability": ability, "target": target}


func test_first_matching_line_wins_top_to_bottom() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	var macro := {"lines": [
		_line("any_ally", "hp_below", 50, "defend"),
		_line("any_enemy", "is_alive", 0, "attack"),
		_line("self", "is_alive", 0, "provoke")]}
	var d := MacroRunner.decide(sim, eira, macro)
	assert_true(d.ok)
	assert_eq(d.line, 2, "rad 1 matchar inte (ingen under 50 %), rad 2 gör det")
	assert_eq(d.action, "attack")


func test_any_picks_first_match_in_slot_order() -> void:
	var sim := _sim()
	sim.unit("alva").hp = 100.0
	sim.unit("brokk").hp = 100.0
	var d := MacroRunner.decide(sim, sim.unit("eira"),
			{"lines": [_line("any_ally", "hp_below", 50, "ability", "hunters_mark")]})
	assert_true(not d.ok, "Märk byte är en fiendeförmåga – en allierad är inget giltigt mål")
	var paladin_line := _line("any_ally", "hp_below", 50, "attack")
	var match := MacroRunner.match_line(sim, sim.unit("eira"), paladin_line)
	assert_eq(match.id, "brokk", "Brokk är plats 2, före Alva på plats 3")


func test_test_next_line_remembers_the_matched_unit() -> void:
	var sim := _sim()
	var alva := sim.unit("alva")
	for id in ["paladin", "brokk", "alva"]:
		sim._add_aura(alva, sim.unit(id), "renew")
	sim.unit("eira").hp = 300.0  # låg och saknar Förnyelse
	var macro := {"lines": [
		_line("any_ally", "lacks_status", "renew", "test_next"),
		_line("any_ally", "hp_below", 90, "ability", "renew")]}
	var d := MacroRunner.decide(sim, alva, macro)
	assert_true(d.ok, d.text)
	assert_eq(d.get("target", ""), "eira")


func test_test_next_line_binds_to_same_unit() -> void:
	var sim := _sim()
	var alva := sim.unit("alva")
	sim.unit("paladin").auras["renew"] = {"remaining": 3.0, "duration": 3.0, "haste": 0.0, "damage_taken_mult": 1.0,
			"hot": 45.0, "dot": 0.0, "school": "holy", "source": "alva"}
	sim.unit("brokk").hp = 1100.0  # nästan fullt, utan Förnyelse
	sim.unit("eira").hp = 300.0
	sim.unit("eira").auras["renew"] = sim.unit("paladin").auras.renew.duplicate()
	var macro := {"lines": [
		_line("any_ally", "lacks_status", "renew", "test_next"),
		_line("any_ally", "hp_below", 50, "ability", "renew")]}
	var d := MacroRunner.decide(sim, alva, macro)
	# Brokk är första utan Förnyelse men har nästan fullt liv; Eira är låg men har redan Förnyelse.
	assert_true(not d.ok, "kedjan prövar samma allierade – ingen uppfyller båda")


func test_line_that_cannot_be_done_is_skipped_with_reason() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	eira.charges.hunters_mark = 0
	var macro := {"lines": [
		_line("any_enemy", "is_alive", 0, "ability", "hunters_mark"),
		_line("self", "is_alive", 0, "defend")]}
	var d := MacroRunner.decide(sim, eira, macro)
	assert_true(d.ok)
	assert_eq(d.line, 2)
	assert_eq(d.skipped.size(), 1)
	assert_true("inga Charges" in d.skipped[0], d.skipped[0])


func test_no_matching_line_returns_not_ok() -> void:
	var sim := _sim()
	var d := MacroRunner.decide(sim, sim.unit("eira"), {"lines": [_line("any_ally", "hp_below", 10, "defend")]})
	assert_true(not d.ok)
	assert_true("inget makro passade" in d.text)


func test_explanation_names_line_and_condition() -> void:
	var sim := _sim()
	sim.unit("brokk").hp = 300.0
	var alva := sim.unit("alva")
	var d := MacroRunner.decide(sim, alva, {"lines": [
		_line("self", "hp_below", 10, "defend"),
		_line("any_ally", "hp_below", 40, "ability", "healing_light")]})
	assert_true(d.ok)
	assert_eq(d.target, "brokk")
	assert_true("rad 2 matchade" in d.text, d.text)
	assert_true("någon allierad har liv < 40 %" in d.text, d.text)
	assert_true("Helande ljus på Brokk" in d.text, d.text)


func test_all_subject_requires_every_living_member() -> void:
	var sim := _sim()
	var line := _line("all_enemies", "hp_above", 50, "defend")
	assert_true(MacroRunner.match_line(sim, sim.unit("eira"), line) != null)
	sim.unit("skeleton_archer_1").hp = 10.0
	assert_true(MacroRunner.match_line(sim, sim.unit("eira"), line) == null)


func test_lowest_hp_compares_within_the_group() -> void:
	var sim := _sim()
	sim.unit("skeleton_warrior_2").hp = 50.0
	var hit := MacroRunner.match_line(sim, sim.unit("eira"), _line("any_enemy", "lowest_hp", 0, "attack"))
	assert_eq(hit.id, "skeleton_warrior_2")


func test_timeline_conditions() -> void:
	var sim := _sim()
	var eira := sim.unit("eira")
	assert_true(MacroRunner.match_line(sim, eira, _line("self", "top_of_timeline", 0, "attack")) != null)
	var last := sim.unit(sim.order[-1])
	var subject := "any_ally" if last.team == 0 else "any_enemy"
	var hit := MacroRunner.match_line(sim, eira, _line(subject, "bottom_of_timeline", 0, "attack"))
	assert_true(hit == last, "den sista i kön är sist på tidslinjen")
	assert_true(MacroRunner.match_line(sim, eira, _line("self", "not_top_of_timeline", 0, "attack")) == null)


func test_macro_drives_a_whole_fight() -> void:
	var sim := _sim()
	var guard := 0
	while sim.outcome == "" and guard < 400:
		guard += 1
		if sim.needs_input():
			var d := MacroRunner.decide(sim, sim.current, _data.macros[sim.current.id])
			assert_true(d.ok, "startmakrona har alltid en sista rad som passar")
			assert_eq(sim.act(d.action, d.target, d.ability), "", d.text)
		else:
			sim.ai_act()
	assert_true(sim.outcome != "", "striden ska ta slut")


func test_line_descriptions_read_like_siralim() -> void:
	var text := MacroRunner.describe_line(_data, _line("any_ally", "hp_below", 40, "ability", "healing_light"))
	assert_eq(text, "Om någon allierad har liv < 40 % → Förmåga: Helande ljus på den som matchade")
