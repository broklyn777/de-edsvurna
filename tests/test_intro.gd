extends "res://tests/test_case.gd"
## 0.23: introduktionen för en ny profil (data/intro.json, Intro) och att befintliga profiler hoppar över den.
## 0.24: varje steg börjar med ett samtal hos den som ger uppdraget, och kedjan rullar inte vidare utan det.

var _data := GameData.load_all()


func test_a_new_profile_starts_alone_with_gorm() -> void:
	var p := Profile.new()
	assert_eq(p.party, ["paladin"])
	assert_true(p.recruited.is_empty())
	assert_eq(Intro.current(_data, p).id, "oath")
	assert_true(Intro.needs_talk(_data, p))
	assert_eq(Intro.station_state(_data, p, "altar"), "current", "Gorm står vid altaret")
	assert_eq(Intro.quest_text(_data, p), "Prata med Mäster Gorm i kapellet.")
	assert_eq(Intro.station_state(_data, p, "gate"), "locked", "porten är stängd")
	assert_true(Dialog.reply(_data, "smith") != "")


## Steget: prata med den som ger uppdraget, sedan händelsen.
func _do(p: Profile, event: String, value := 0) -> void:
	assert_true(Intro.notify(_data, p, event, value).is_empty() or event == "talked",
			"%s gör inget innan man har pratat" % event)
	Intro.talked(_data, p)
	Intro.notify(_data, p, event, value)


func test_the_chain_waits_for_each_conversation() -> void:
	var p := Profile.new()
	assert_true(Intro.notify(_data, p, "oath_chosen").is_empty(), "inget uppdrag förrän Gorm har pratat")
	_do(p, "oath_chosen")
	assert_eq(Intro.current(_data, p).id, "practice")
	assert_true(Intro.needs_talk(_data, p), "nästa uppdrag kommer först efter samtalet")
	assert_eq(Intro.station_state(_data, p, "practice"), "locked", "Övningsgården väntar på Gorms ord")
	Intro.talked(_data, p)
	assert_eq(Intro.station_state(_data, p, "practice"), "current")
	var silver := p.silver
	Intro.notify(_data, p, "practice_won")
	assert_eq(p.silver, silver + 100, "övningen ger silver")
	assert_true(p.silver >= Profile.FORGE_COST, "det räcker till svärdet")
	assert_eq(Intro.station_state(_data, p, "practice"), "current", "Stig ger nästa uppdrag")
	Intro.talked(_data, p)
	assert_eq(Intro.station_state(_data, p, "smith"), "current")
	Intro.notify(_data, p, "forged")
	for e in ["macro_line", "library_read"]:
		_do(p, e)
	assert_eq(Intro.current(_data, p).id, "imma")
	assert_eq(Intro.giver_station(_data, p), "yard", "Imma väntar på gården")
	Intro.notify(_data, p, "talked")
	assert_true(p.recruited.has("imma") and p.party == ["paladin", "imma"], "Imma följer med")
	Intro.notify(_data, p, "talked")
	assert_eq(Intro.station_state(_data, p, "gate"), "current", "porten öppnas efter Gorms ord, och Sven har ett uppdrag")
	Intro.talked(_data, p)
	assert_eq(Intro.station_state(_data, p, "gate"), "open")
	assert_true(Intro.notify(_data, p, "sword_level", 2).is_empty(), "nivå 2 räcker inte")
	Intro.notify(_data, p, "sword_level", 3)
	assert_true(p.intro_done)
	assert_eq(Intro.station_state(_data, p, "inn"), "locked", "Värdshuset öppnas när någon har räddats")
	p.recruit(_data, "alva")
	assert_eq(Intro.station_state(_data, p, "inn"), "open")


func test_every_step_has_a_conversation() -> void:
	for step in Intro.steps(_data):
		assert_true(step.has("giver") and not Dialog.person(_data, step.giver).is_empty(), step.id)
		var n: int = step.get("talk", []).size()
		assert_true(n >= 2 and n <= 5, "%s har %d repliker" % [step.id, n])
		assert_true(step.get("quest", "") != "", step.id)



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
