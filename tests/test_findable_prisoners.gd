extends "res://tests/test_case.gd"
## Fångar nämns först när de går att hitta (0.30.52): Syster Alva ("after_descents" 1) inte före den andra nedstigningen
## i kryptan, och inget på ett djup man inte får välja än. Samma regel i grottan och på skärmarna.

var _data := GameData.load_all()


func _heroes(list: Array) -> Array:
	return list.map(func(d: Dictionary) -> String: return d.hero)


func test_new_profile_does_not_hear_of_alva() -> void:
	var p := Profile.new()
	assert_true(not _heroes(RunState.findable_for(p, _data, "crypt")).has("alva"))
	assert_true(not _heroes(RunState.findable_disciples(_data, "crypt", p.recruited, 0)).has("alva"))


func test_nothing_deeper_than_can_be_chosen() -> void:
	var p := Profile.new()
	for d in RunState.findable_for(p, _data, "crypt") + RunState.findable_for(p, _data, "chapel"):
		assert_true(int(d.depth) <= p.max_depth(), "%s på djup %d" % [d.hero, int(d.depth)])


func test_alva_after_first_descent() -> void:
	var p := Profile.new()
	p.descents["crypt"] = 1
	assert_eq(_heroes(RunState.findable_for(p, _data, "crypt"))[0], "alva")
	p.recruited.append("alva")
	assert_true(not _heroes(RunState.findable_for(p, _data, "crypt")).has("alva"))


func test_grotto_places_the_same() -> void:
	var p := Profile.new()
	var s := RunState.new_run(p, _data)
	s.set_realm(_data, "crypt")
	s.place_prisoners(_data, p.recruited, 0)
	assert_true(not s.prisoners.values().any(func(d: Dictionary) -> bool: return d.hero == "alva"))
	s.place_prisoners(_data, p.recruited, 1)
	assert_true(s.prisoners.values().any(func(d: Dictionary) -> bool: return d.hero == "alva"))
