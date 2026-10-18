extends "res://tests/test_case.gd"


func test_main_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert_true(scene != null, "main.tscn kunde inte laddas")


func test_all_data_references_exist() -> void:
	var data := GameData.load_all()
	for group in ["heroes", "enemies"]:
		for id in data[group]:
			var d: Dictionary = data[group][id]
			for key in ["attack_ability", "signature"]:
				if d.has(key):
					assert_true(data.abilities.has(d[key]), "%s.%s: okänd förmåga %s" % [id, key, d[key]])
			for t in d.get("traits", []):
				assert_true(data.traits.has(t), "%s: okänd egenskap %s" % [id, t])
	for id in data.abilities:
		for e in data.abilities[id].get("effects", []):
			if e.type == "aura":
				assert_true(data.auras.has(e.aura), "%s: okänd aura %s" % [id, e.aura])
