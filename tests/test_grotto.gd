extends "res://tests/test_case.gd"
## 0.30.22: ryktena om questens mål och spåren efter grupper man lät vara (docs/plan/nya-grottor.md A och B).

func test_every_quest_target_has_a_rumour_within_one_step() -> void:
	var data := GameData.load_all()
	for seed_value in range(1, 30):
		var s := RunState.new()
		s.set_realm(data, "crypt")
		s.fill_charges(data)
		s.start_expedition(data, seed_value)
		var targets := s.quest_targets()
		assert_eq(s.quest_hints.size(), targets.size(), "en ring per mål (frö %d)" % seed_value)
		for h in s.quest_hints:
			var a := Grotto.xy(int(h.center))
			var b := Grotto.xy(int(h.target))
			assert_true(absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1, "målet ligger i ringens 3×3")
		var t := RunState.from_dict(s.to_dict())
		assert_eq(t.quest_hints.size(), s.quest_hints.size(), "ryktena sparas")


func test_rumour_goes_away_when_the_target_is_seen() -> void:
	var data := GameData.load_all()
	var s := RunState.new()
	s.set_realm(data, "crypt")
	s.fill_charges(data)
	s.start_expedition(data, 3)
	var n := s.active_hints().size()
	assert_true(n > 0)
	s.seen.append(int(s.quest_hints[0].target))
	assert_eq(s.active_hints().size(), n - 1)


func test_trail_pays_half_for_groups_left_standing_once() -> void:
	var data := GameData.load_all()
	var s := RunState.new()
	s.set_realm(data, "crypt")
	s.fill_charges(data)
	s.start_expedition(data, 5)
	var commons := 0
	for c in s.map.cells:
		if c.get("kind", "") == "battle" and c.has("encounter") and RunState.is_common_group(c):
			commons += 1
	var t := s.take_trail(data)
	assert_eq(int(t.groups), commons)
	assert_eq(int(t.xp), roundi(HeroStats.battle_xp("battle", 1) * RunState.TRAIL_SHARE * commons))
	assert_true(s.take_trail(data).is_empty(), "spåren ges en gång per våning")
