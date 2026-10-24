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
