extends "res://tests/test_case.gd"

var _data := GameData.load_all()
var _result := {}


func _picker() -> TraitPicker:
	_result = {}
	var p := TraitPicker.new()
	p.setup(_data, _data.encounters.bone_lich.party, {}, {})
	p.size = Vector2(1280, 720)
	(runner as SceneTree).root.add_child(p)
	p.confirmed.connect(func(t: Dictionary, a: Dictionary) -> void: _result = {"traits": t, "artifacts": a})
	return p


func _tap(p: TraitPicker, r: Rect2) -> void:
	p._step_age = 1.0  # som om spelaren väntat en stund sedan förra stegbytet
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = r.get_center()
		p._gui_input(e)


func test_double_tap_does_not_skip_artifacts() -> void:
	var p := _picker()
	_tap(p, p._button_rect())
	assert_eq(p.step, 2)
	for pressed in [true, false]:  # snabbt andra tryck direkt efter stegbytet
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p._button_rect().get_center()
		p._gui_input(e)
	assert_eq(p.step, 2)
	assert_true(_result.is_empty(), "striden får inte starta av ett dubbeltryck")
	p.queue_free()


func test_full_pick_flow() -> void:
	var p := _picker()
	_tap(p, p._card_rect(2, 1))  # Mage: Förbränning
	assert_eq(p.traits.mage, "combustion")
	_tap(p, p._button_rect())
	assert_eq(p.step, 2)
	_tap(p, p._artifact_rect(0))  # Warrior aktiv först
	assert_eq(p.artifacts.get("warrior", ""), "fateblade")
	assert_eq(p._active, 1, "nästa hjälte utan artefakt ska bli aktiv")
	_tap(p, p._artifact_rect(0))  # samma artefakt till Priest flyttas från Warrior
	assert_eq(p.artifacts.get("priest", ""), "fateblade")
	assert_true(not p.artifacts.has("warrior"), "en artefakt kan bara bäras av en")
	_tap(p, p._button_rect())
	assert_eq(_result.traits.mage, "combustion")
	assert_eq(_result.artifacts, {"priest": "fateblade"})
	p.queue_free()
