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
	assert_eq(Intro.station_state(_data, p, "altar"), "current", "Gorm står vid altaret under eden")
	assert_eq(Intro.quest_text(_data, p), "Prata med Mäster Gorm vid altaret i kapellet.")
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
	var silver := p.silver
	_do(p, "oath_chosen")
	assert_eq(p.silver, silver + 100, "eden ger silver till svärdet (0.30: smedjan före övningsgården)")
	assert_true(p.silver >= Profile.FORGE_COST, "det räcker till svärdet")
	assert_eq(Intro.current(_data, p).id, "forge")
	assert_true(Intro.needs_talk(_data, p), "nästa uppdrag kommer först efter samtalet")
	assert_eq(Intro.station_state(_data, p, "smith"), "locked", "Smedjan väntar på Gorms ord")
	Intro.talked(_data, p)
	assert_eq(Intro.station_state(_data, p, "smith"), "current")
	Intro.notify(_data, p, "forged")
	assert_eq(Intro.current(_data, p).id, "practice")
	assert_eq(Intro.station_state(_data, p, "smith"), "current", "Hedda ger nästa uppdrag")
	Intro.talked(_data, p)
	assert_eq(Intro.station_state(_data, p, "practice"), "current")
	Intro.notify(_data, p, "practice_won")
	assert_eq(Intro.station_state(_data, p, "practice"), "current", "Stig ger nästa uppdrag")
	for e in ["macro_line", "library_read"]:
		_do(p, e)
	# 0.25: natten efter introdagen. Arbetarna kommer upp ur kryptan, och samtalet spelas direkt i borgen.
	assert_eq(Intro.current(_data, p).id, "workers")
	assert_true(Intro.auto_talk(_data, p), "arbetarnas berättelse spelas av sig själv")
	assert_true(Intro.scene(_data, p), "de skadade ligger på gården")
	assert_eq(Intro.lines(Intro.current(_data, p))[0].who, StoryBox.NARRATOR, "berättaren först")
	assert_eq(Intro.station_state(_data, p, "gate"), "locked")
	Intro.notify(_data, p, "talked")
	assert_eq(Intro.current(_data, p).id, "descent")
	assert_true(not p.recruited.has("imma") and p.party == ["paladin"], "paladinen går ned ensam")
	assert_true(not Intro.needs_talk(_data, p), "Gorm har redan gett uppdraget")
	assert_eq(Intro.station_state(_data, p, "gate"), "current", "porten öppnas")
	assert_eq(Intro.quest_text(_data, p), "Gå ned i kryptan ensam. Sven öppnar porten.")
	Intro.notify(_data, p, "came_home")
	assert_true(p.recruited.has("imma") and p.party == ["paladin", "imma"], "Imma följde med (och är kvar)")
	assert_eq(Intro.current(_data, p).id, "crypt")
	assert_true(Intro.auto_talk(_data, p), "Gorm tar emot er när ni kommer hem")
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
		assert_true(step.get("quest", "") != "", step.id)
		if not step.has("giver"):
			assert_eq(step.event, "came_home", "bara nedstigningen saknar samtal (Gorm gav uppdraget på gården)")
			continue
		assert_true(not Dialog.person(_data, step.giver).is_empty(), step.id)
		# 2–5 repliker per talare (0.25: arbetarnas berättelse har flera talare och berättaren).
		var per := {}
		for l in Intro.lines(step):
			assert_true(l.who == StoryBox.NARRATOR or not Dialog.person(_data, l.who).is_empty(), "%s: %s" % [step.id, l.who])
			per[l.who] = int(per.get(l.who, 0)) + 1
		assert_true(int(per.get(step.giver, 0)) >= 2, "%s: %s säger minst två repliker" % [step.id, step.giver])
		for who in per:
			assert_true(per[who] <= 5, "%s: %s har %d repliker" % [step.id, who, per[who]])



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


## 0.30: en profil som stod på övningsstriden eller svärdet i den gamla ordningen börjar på svärdet, och den som inte
## hade fått de hundra silvren får dem.
func test_old_profiles_move_to_the_new_order() -> void:
	var path := "user://test_intro_order.cfg"
	for old in [1, 2]:
		var p := Profile.new()
		p.intro_step = old
		p.silver = 0 if old == 1 else 100
		p.intro_talked = true
		p.save(path)
		var cfg := ConfigFile.new()
		cfg.load(path)
		cfg.set_value("progress", "intro_order", 1)
		cfg.save(path)
		var q := Profile.load_from(path)
		assert_eq(q.intro_step, 1, "börjar på svärdet")
		assert_eq(q.silver, 100, "har silver till svärdet")
		assert_true(not q.intro_talked, "svärdssteget börjar med samtalet")
		q.save(path)
		assert_eq(Profile.load_from(path).intro_step, 1, "flyttas bara en gång")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 0.30.16: föll paladinen innan Imma smet efter finns en egen kort hemkomst, och nedstigningen är fortfarande den första.
func test_alone_home_lines_exist() -> void:
	var lines := Intro.speech(_data.intro.get("alone_home", {}).get("lines", []))
	assert_true(lines.size() >= 2, "Gorm säger något när paladinen kommer hem ensam")
	for l in lines:
		assert_true(l.who in ["gorm", "imma"], "bara Gorm och Imma")
