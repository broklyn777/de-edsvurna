extends "res://tests/test_case.gd"
## Träffytorna i striden (polering fynd 6, TargetPick): skylten och kroppen räknas, närmaste mitt vinner, och fiender
## vars ytor överlappar skjuts isär.


func test_plate_is_a_hit_area() -> void:
	var units := {"witch": [Vector2(500, 400), Vector2(500, 300)]}
	assert_eq(TargetPick.pick(Vector2(540, 270), units), "witch", "namnskylten ovanför huvudet")
	assert_eq(TargetPick.pick(Vector2(500, 380), units), "witch", "kroppen")
	assert_eq(TargetPick.pick(Vector2(800, 100), units), "", "långt bort")


func test_nearest_center_wins_on_overlap() -> void:
	# Häxan står bakom riddaren: riddarens skylt täcker häxans kropp.
	var units := {"knight": [Vector2(500, 420), Vector2(500, 330)], "witch": [Vector2(540, 330), Vector2(540, 250)]}
	assert_eq(TargetPick.pick(Vector2(540, 290), units), "witch", "häxans kropp ligger närmare än riddarens skylt")
	assert_eq(TargetPick.pick(Vector2(500, 300), units), "knight", "mitt på riddarens skylt")


func test_spread_separates_overlapping_areas() -> void:
	var heads := {"a": Vector2(500, 300), "b": Vector2(560, 360), "c": Vector2(900, 300)}
	for _i in 40:
		var push := TargetPick.spread_step(heads)
		if push.is_empty():
			break
		for id in push:
			heads[id] += push[id]
	assert_true(TargetPick.spread_step(heads).is_empty(), "inget överlappar längre")
	var ra := Rect2(heads.a + TargetPick.AREA.position, TargetPick.AREA.size)
	var rb := Rect2(heads.b + TargetPick.AREA.position, TargetPick.AREA.size)
	assert_true(not ra.intersects(rb))
	assert_true(heads.a.x < heads.b.x, "ordningen i sidled behålls")
	assert_eq(heads.c, Vector2(900, 300), "den som stod fri står kvar")
