extends "res://tests/test_case.gd"
## 0.23: introduktionen för en ny profil (data/intro.json, Intro) och att befintliga profiler hoppar över den.

var _data := GameData.load_all()


func test_a_new_profile_starts_alone_with_the_oath() -> void:
	var p := Profile.new()
	assert_eq(p.party, ["paladin"])
	assert_true(p.recruited.is_empty())
	assert_eq(Intro.current(_data, p).id, "oath")
	assert_eq(Intro.station_state(_data, p, "altar"), "current")
	assert_eq(Intro.station_state(_data, p, "gate"), "locked", "porten är stängd")
	assert_true(Intro.reply(_data, "smith").begins_with("Smeden"))


func test_the_chain_runs_in_order() -> void:
	var p := Profile.new()
	assert_true(Intro.notify(_data, p, "forged").is_empty(), "fel ordning gör inget")
	Intro.notify(_data, p, "oath_chosen")
	var silver := p.silver
	Intro.notify(_data, p, "practice_won")
	assert_eq(p.silver, silver + 100, "övningen ger silver")
	assert_true(p.silver >= Profile.FORGE_COST, "det räcker till svärdet")
	assert_eq(Intro.station_state(_data, p, "smith"), "current")
	assert_eq(Intro.station_state(_data, p, "practice"), "open", "det man har gjort går att besöka igen")
	for e in ["forged", "macro_line", "library_read"]:
		Intro.notify(_data, p, e)
	assert_eq(Intro.current(_data, p).id, "imma")
	Intro.notify(_data, p, "talked")
	assert_true(p.recruited.has("imma") and p.party == ["paladin", "imma"], "Imma följer med")
	Intro.notify(_data, p, "talked")
	assert_eq(Intro.station_state(_data, p, "gate"), "open", "porten öppnas efter Gorms ord")
	assert_true(Intro.notify(_data, p, "sword_level", 2).is_empty(), "nivå 2 räcker inte")
	Intro.notify(_data, p, "sword_level", 3)
	assert_true(p.intro_done)
	assert_eq(Intro.station_state(_data, p, "inn"), "locked", "Värdshuset öppnas när någon har räddats")
	p.recruit(_data, "brokk")
	assert_eq(Intro.station_state(_data, p, "inn"), "open")


func test_existing_profiles_skip_the_intro() -> void:
	var path := "user://test_progress_intro.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 300)
	cfg.save(path)
	var p := Profile.load_from(path)
	assert_true(p.intro_done)
	assert_true(p.recruited.has("imma"))
	var q := Profile.new()
	q.save(path)
	assert_true(not Profile.load_from(path).intro_done, "en ny profil sparas med introt kvar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_the_practice_fight_suits_a_lone_paladin() -> void:
	const Bot := preload("res://tests/combat_bot.gd")
	var wins := 0
	for s in 20:
		var r := Bot.run_fight(_data, s, Bot.Skill.BASIC, "intro_yard", ["paladin"])
		wins += 1 if r.outcome == "victory" else 0
	assert_true(wins >= 18, "en lätt strid: %d/20 med bara Anfall" % wins)
