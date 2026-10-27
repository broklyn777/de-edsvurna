extends "res://tests/test_case.gd"
## Segerns rubrik böjs efter Realmens genus (0.30.48, polering B4): "KAPELLET RENSAT!", inte "RENSAD".

var _data := GameData.load_all()


func test_every_realm_has_a_gender() -> void:
	for id in _data.realms:
		var realm: Dictionary = _data.realms[id]
		if realm.has("short"):
			assert_true(realm.get("gender", "") in ["en", "ett"], "%s saknar genus" % id)


func test_cleared_title() -> void:
	assert_eq(RunState.cleared_title(_data, "crypt"), "KRYPTAN RENSAD!")
	assert_eq(RunState.cleared_title(_data, "chapel"), "KAPELLET RENSAT!")
	assert_eq(RunState.cleared_title(_data, "grove"), "LUNDEN RENSAD!")
	assert_eq(RunState.cleared_title(_data, "mountain"), "BERGET RENSAT!")
