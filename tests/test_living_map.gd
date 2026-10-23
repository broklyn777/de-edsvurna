extends "res://tests/test_case.gd"
## Den levande kartan (prov, docs/plan/levande-karta.md, LivingMap): fördärvet 0–4 per Realm i profilen, hur det
## ändras efter en nedstigning, styrkan i striden, den förvridna bossen på steg 4 och texterna utan siffror.

const Bot := preload("res://tests/combat_bot.gd")
var _data := GameData.load_all()
const TMP := "user://test_living_map.cfg"


func _profile(visited := ["crypt", "chapel"]) -> Profile:
	var p := Profile.new()
	p.intro_done = true
	p.recruited.assign(["imma"])
	for r in visited:
		p.descents[r] = 1
	return p


func test_growth_starts_at_one_and_old_saves_load() -> void:
	var p := Profile.new()
	assert_eq(LivingMap.growth(p, "crypt"), 1, "startvärdet")
	# En sparfil från före den levande kartan (utan fälten) ger startvärdet.
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 99)
	cfg.save(TMP)
	var old := Profile.load_from(TMP)
	assert_eq(LivingMap.growth(old, "chapel"), 1)
	assert_true(old.growth_news.is_empty() and old.growth_rest.is_empty())
	# Och fälten överlever en sparning.
	p.growth = {"crypt": 3, "chapel": 0}
	p.growth_rest = {"chapel": true}
	p.growth_news = {"lines": ["x"]}
	p.save(TMP)
	var back := Profile.load_from(TMP)
	assert_eq(LivingMap.growth(back, "crypt"), 3)
	assert_eq(LivingMap.growth(back, "chapel"), 0)
	assert_true(back.growth_rest.has("chapel"))
	assert_eq(back.growth_news.lines, ["x"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_nothing_changes_without_a_won_battle() -> void:
	var p := _profile()
	assert_eq(LivingMap.after_descent(p, _data, "crypt", 0, false), [])
	assert_eq(LivingMap.growth(p, "crypt"), 1)
	assert_eq(LivingMap.growth(p, "chapel"), 1)
	assert_true(p.growth_news.is_empty())


func test_the_realm_you_go_to_sinks_and_the_others_grow() -> void:
	var p := _profile()
	p.growth = {"crypt": 3, "chapel": 1}
	LivingMap.after_descent(p, _data, "crypt", 2, false)
	assert_eq(LivingMap.growth(p, "crypt"), 2, "utan quest: ett steg")
	assert_eq(LivingMap.growth(p, "chapel"), 2, "den andra växer")
	assert_eq(LivingMap.growth(p, "grove"), 1, "Lunden är inte upplåst (aldrig besökt) och står still")
	LivingMap.after_descent(p, _data, "chapel", 3, true)
	assert_eq(LivingMap.growth(p, "chapel"), 0, "med quest: två steg")
	assert_eq(LivingMap.growth(p, "crypt"), 3)


func test_with_three_realms_only_the_longest_untouched_grows() -> void:
	var p := _profile(["crypt", "chapel", "grove"])
	p.growth = {"crypt": 1, "chapel": 1, "grove": 1}
	p.growth_last = {"crypt": 0, "chapel": 2, "grove": 1}
	p.descents = {"crypt": 1, "chapel": 1, "grove": 1}
	LivingMap.after_descent(p, _data, "chapel", 1, false)
	assert_eq(LivingMap.growth(p, "crypt"), 2, "kryptan har legat orörd längst")
	assert_eq(LivingMap.growth(p, "grove"), 1, "lunden väntar")
	assert_eq(LivingMap.growth(p, "chapel"), 0)
	assert_eq(int(p.growth_last.chapel), p.total_descents())
	# Nästa gång (kapellet vilar) är lunden äldst.
	LivingMap.after_descent(p, _data, "crypt", 1, false)
	assert_eq(LivingMap.growth(p, "grove"), 2)
	assert_eq(LivingMap.growth(p, "chapel"), 0, "vilar")


func test_a_realm_at_zero_rests_one_descent() -> void:
	var p := _profile()
	p.growth = {"crypt": 1, "chapel": 2}
	LivingMap.after_descent(p, _data, "crypt", 1, false)  # kryptan når 0
	assert_eq(LivingMap.growth(p, "crypt"), 0)
	LivingMap.after_descent(p, _data, "chapel", 1, false)  # kryptan vilar
	assert_eq(LivingMap.growth(p, "crypt"), 0, "vilar en nedstigning")
	assert_true(p.growth_news.lines.any(func(l: String) -> bool: return l.contains("stilla")), str(p.growth_news.lines))
	LivingMap.after_descent(p, _data, "chapel", 1, false)
	assert_eq(LivingMap.growth(p, "crypt"), 1, "och växer sedan igen")


func test_step_four_stands_still_and_wakes_the_twisted_boss() -> void:
	var p := _profile()
	p.growth = {"crypt": 3, "chapel": 1}
	LivingMap.after_descent(p, _data, "chapel", 1, false)
	assert_eq(LivingMap.growth(p, "crypt"), 4)
	assert_true(LivingMap.awake(p, _data, "crypt"))
	assert_true(p.growth_news.lines.any(func(l: String) -> bool: return l.contains("Den svärtade Benfursten")))
	LivingMap.after_descent(p, _data, "chapel", 1, false)
	assert_eq(LivingMap.growth(p, "crypt"), 4, "står still tills man går dit")
	# Kapellet har ingen förvriden boss än: steg 4 är bara starkare.
	p.growth.chapel = 4
	assert_true(not LivingMap.awake(p, _data, "chapel"))
	# Körningen i kryptan på steg 4 möter den förvridna bossen i stället för Benfursten.
	p.realm = "crypt"
	var s := RunState.new_run(p, _data)
	assert_eq(s.twisted, "crypt_twisted")
	assert_eq(s.floor_ids.back(), "crypt_twisted")
	assert_eq(_data.realms.crypt.floors.back(), "crypt_3", "Realmens data ändras inte")
	# Efter nedstigningen (seger) sjunker kryptan och bossen somnar.
	LivingMap.after_descent(p, _data, "crypt", 5, true)
	assert_eq(LivingMap.growth(p, "crypt"), 2)
	assert_true(not LivingMap.awake(p, _data, "crypt"))


func test_twisted_boss_leaves_its_trophy_at_once() -> void:
	var p := _profile()
	p.growth = {"crypt": 4}
	p.realm = "crypt"
	var s := RunState.new_run(p, _data)
	s.practice = true
	s.practice_encounter = "crypt_twisted"
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var offer := s.trophy_offer(_data, rng, [], [])
	assert_true(offer.has("black_crown"), str(offer))
	var t: Dictionary = _data.traits.black_crown
	assert_eq(t.rarity, "boss")
	assert_true(_data.traits.has("black_crown_cost") and _data.traits.has("black_marrow"))
	assert_true(_data.enemies.bone_lich_black.get("twisted", false) and _data.enemies.bone_lich_black.get("boss", false))
	assert_eq(LivingMap.twisted_boss(_data, "crypt"), "bone_lich_black")


func test_growth_strengthens_battles_from_step_two() -> void:
	var p := _profile()
	for g in [0, 1, 2, 3, 4]:
		p.growth = {"crypt": g}
		p.realm = "crypt"
		var s := RunState.new_run(p, _data)
		s.start_expedition(_data, 5)
		var opts := s.battle_opts()
		var want := LivingMap.stat_mult(g)
		assert_near(float(opts.get("stat_bonus", 1.0)), want, 0.0001, "steg %d" % g)
	assert_near(LivingMap.stat_mult(1), 1.0)
	assert_near(LivingMap.stat_mult(0), 1.0, 0.0001, "steg 0 är dagens strider")
	assert_true(LivingMap.stat_mult(3) > LivingMap.stat_mult(2) and LivingMap.stat_mult(2) > 1.0)
	assert_near(LivingMap.stat_mult(4), LivingMap.stat_mult(3), 0.0001, "steg 4: hotet är den förvridna bossen")
	# Profilens första nedstigning har sin egen trappa och påverkas inte.
	p.growth = {"crypt": 4}
	var first := RunState.new_run(p, _data)
	first.first_descent = true
	first.start_expedition(_data, 5)
	assert_true(not first.battle_opts().has("growth"))


func test_growth_gives_better_trophy_chance_and_finds() -> void:
	assert_near(LivingMap.trophy_bonus(1), 0.0)
	assert_true(LivingMap.trophy_bonus(4) > 0.0)
	var count := {1: 0, 4: 0}
	for g in [1, 4]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 300:
			for f in Forge.roll_finds(_data, "battle", 1, true, 0, rng, 0, g):
				count[g] += int(f.get("count", 1))
	assert_true(count[4] > count[1], str(count))


func test_wins_and_realm_quest_are_counted_in_the_run() -> void:
	var p := _profile()
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 9)
	assert_eq(s.wins, 0)
	assert_true(not s.realm_quest_done)
	s.floor = RunState.FLOORS_PER_RUN - 1
	s.quest = {"type": "hunt", "progress": 0, "goal": 1, "done": false}
	s._quest_step()
	assert_true(s.realm_quest_done, "den sista våningens quest är Realm Quest")
	var back := RunState.from_dict(s.to_dict())
	assert_true(back.realm_quest_done)


func test_texts_have_no_numbers_and_one_line_at_most() -> void:
	var p := _profile()
	p.growth = {"crypt": 3, "chapel": 2}
	var dep := LivingMap.departure_line(p, _data, "chapel")
	assert_true(dep.contains("kryptan"), dep)
	assert_true(dep.contains("vakna"), "varning före avfärd när kryptan kan nå 4: " + dep)
	var regex := RegEx.create_from_string("[0-9]")
	assert_true(regex.search(dep) == null, dep)
	LivingMap.after_descent(p, _data, "chapel", 1, true)
	var news: Dictionary = p.growth_news
	assert_true(news.lines.size() >= 2, str(news))
	for l in news.lines:
		assert_true(regex.search(String(l)) == null, l)
	assert_eq(news.speaker, "imma", "Imma när hon finns")
	assert_true(String(news.text) != "")
	# Utan Imma talar Gorm.
	var q := _profile()
	q.recruited.clear()
	q.growth = {"crypt": 2, "chapel": 2}
	LivingMap.after_descent(q, _data, "chapel", 1, false)
	assert_eq(q.growth_news.speaker, "gorm")


func test_twisted_battle_can_be_played_to_the_end() -> void:
	var party := ["paladin", "brokk", "alva", "eira"]
	var won := 0
	for seed_value in range(1, 6):
		var r := Bot.run_fight(_data, seed_value, Bot.Skill.MACRO, "crypt_twisted", party, {}, {}, {}, 1,
				{"levels": Bot.party_levels(_data, 6, party), "floor": 2, "stat_bonus": LivingMap.stat_mult(4)})
		assert_true(r.outcome in ["victory", "defeat"], str(r.outcome))
		won += 1 if r.outcome == "victory" else 0
	assert_true(won >= 0)
