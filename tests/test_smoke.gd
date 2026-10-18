extends "res://tests/test_case.gd"


func test_main_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert_true(scene != null, "main.tscn kunde inte laddas")


func test_math_sanity() -> void:
	assert_eq(2 + 2, 4)
