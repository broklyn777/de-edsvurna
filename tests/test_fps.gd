extends "res://tests/test_case.gd"
## Bildtakten per skärm (docs/research/prestanda-android.md punkt 1 och 8): Run.wanted_fps.

var _run: Script = load("res://scripts/game/run.gd")


func test_menus_are_capped_at_30() -> void:
	assert_eq(_run.wanted_fps(false, false, false), 30)


func test_map_animations_get_60() -> void:
	assert_eq(_run.wanted_fps(false, false, true), 60)


func test_battle_is_unchanged_until_it_stands_still() -> void:
	assert_eq(_run.wanted_fps(true, false, false), 0, "striden ritas som förut, utan gräns")
	assert_eq(_run.wanted_fps(true, true, false), 30, "pausad strid (makroredigeraren, inställningarna) i 30")


func test_fps_line_only_in_battle() -> void:
	var battle := Node.new()
	battle.scene_file_path = "res://scenes/main.tscn"
	var smith := Node.new()
	smith.scene_file_path = "res://scenes/smith.tscn"
	assert_true(FpsMeter.shown_in(battle), "striden visar raden")
	assert_true(not FpsMeter.shown_in(smith), "Smeden visar den inte")
	assert_true(not FpsMeter.shown_in(null))
	battle.free()
	smith.free()
