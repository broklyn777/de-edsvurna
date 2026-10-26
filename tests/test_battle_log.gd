extends "res://tests/test_case.gd"
## Stridsloggen (BattleLog): varje handling får en rad, också de som inte skadar.

var data := GameData.load_all()


func _sim() -> CombatSim:
	var s := CombatSim.create(data, "crypt_1", 7, ["paladin", "alva"])
	s.begin()
	s.drain_events()
	return s


func test_non_damage_events_get_a_swedish_line() -> void:
	var s := _sim()
	var p := s.heroes[0]
	var foe := s.enemies[0]
	var ab := String(data.heroes.alva.abilities[0])
	assert_eq(BattleLog.line(s, {"type": "action", "unit": "alva", "action": "ability", "ability": ab, "targets": ["paladin"]}),
			"Syster Alva använder %s mot %s." % [data.abilities[ab].name, p.name])
	assert_true(BattleLog.line(s, {"type": "aura_applied", "unit": foe.id, "aura": "silenced", "source": "alva",
			"aura_kind": "debuff"}).find("Tystad") >= 0, "debuffen syns")
	assert_true(BattleLog.line(s, {"type": "aura_applied", "unit": "paladin", "aura": "barrier", "source": "alva"}) != "",
			"Barriär syns")
	assert_true(BattleLog.line(s, {"type": "status_skip", "unit": foe.id, "aura": "frozen"}).find("står över") >= 0)
	assert_true(BattleLog.line(s, {"type": "timeline_move", "unit": foe.id, "dir": "bottom", "steps": 2}).find("tidslinjen") >= 0)
	assert_true(BattleLog.line(s, {"type": "death", "unit": foe.id}).ends_with("föll."))
	assert_true(BattleLog.line(s, {"type": "interrupt", "unit": "paladin", "target": foe.id, "ability": foe.attack_ability}) != "")


func test_attacks_and_bookkeeping_have_no_extra_line() -> void:
	var s := _sim()
	assert_eq(BattleLog.line(s, {"type": "action", "unit": "paladin", "action": "attack", "ability": s.heroes[0].attack_ability,
			"targets": [s.enemies[0].id]}), "", "anfallet syns i skaderaden")
	for t in ["turn_start", "acted", "intent_chosen", "damage", "heal", "dodge", "windup_start"]:
		assert_eq(BattleLog.line(s, {"type": t, "unit": "paladin"}), "", t)


func test_a_whole_battle_logs_without_errors() -> void:
	var s := CombatSim.create(data, "crypt_1", 3, ["paladin", "alva", "brokk", "eira"])
	s.begin()
	var lines := 0
	var guard := 0
	while s.outcome == "" and guard < 400:
		s.ai_act()
		for e in s.drain_events():
			if BattleLog.line(s, e) != "":
				lines += 1
		guard += 1
	assert_true(lines > 0, "en hel strid ger rader utan uträkning")
