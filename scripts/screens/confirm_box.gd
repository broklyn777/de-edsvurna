class_name ConfirmBox
extends CanvasLayer
## En fråga med JA och AVBRYT (0.30.48, först för trofébyten, fynd 13). Läggs ovanpå en skärm med ConfirmBox.ask(); svaret
## kommer med signalen answered och rutan stänger sig själv. Ett tryck utanför rutan är AVBRYT. Reagerar när fingret släpps.

signal answered(yes: bool)

const W := 640.0
const H := 250.0

var question := ""
var detail := ""
var _view: Control
var _press_at := Vector2(-1, -1)


static func ask(host: Node, q: String, more := "") -> ConfirmBox:
	var box := ConfirmBox.new()
	box.question = q
	box.detail = more
	host.add_child(box)
	return box


func _ready() -> void:
	layer = 62
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_paint)
	_view.gui_input.connect(_input_on)
	add_child(_view)
	_run().ui("ui_page", -10.0)


func _run() -> Node:
	return get_node("/root/Run")


func _panel() -> Rect2:
	var a := _view.size
	return Rect2((a.x - W) / 2.0, (a.y - H) / 2.0, W, H)


## 0 = JA, 1 = AVBRYT.
func _button(i: int) -> Rect2:
	var r := _panel()
	return Rect2(r.position.x + W / 2.0 - 260 + i * 280, r.end.y - 80, 240, 60)


## Androids bakåtknapp: som AVBRYT.
func go_back() -> bool:
	_answer(false)
	return true


func _input_on(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_view.accept_event()
	if event.pressed:
		_press_at = event.position
		return
	if _press_at.distance_to(event.position) > 30.0:
		return
	if _button(0).has_point(event.position):
		_answer(true)
	elif _button(1).has_point(event.position) or not _panel().has_point(event.position):
		_answer(false)


func _answer(yes: bool) -> void:
	_run().ui("ui_confirm" if yes else "ui_back", -8.0 if yes else -12.0)
	answered.emit(yes)
	queue_free()


func _paint() -> void:
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color(0, 0, 0, 0.72))
	var panel := _panel()
	_view.draw_rect(panel, Color(0.07, 0.06, 0.09, 0.97))
	_view.draw_rect(panel, Color(UiStyle.GOLD, 0.8), false, 2.0)
	UiStyle.para(_view, panel.position + Vector2(32, 56), question, 26, UiStyle.GOLD, W - 64, 2)
	if detail != "":
		UiStyle.para(_view, panel.position + Vector2(32, 118), detail, 17, Color(1, 1, 1, 0.8), W - 64, 2)
	for i in 2:
		var b := _button(i)
		_view.draw_rect(b, Color(0.35, 0.25, 0.05, 0.95) if i == 0 else Color(0, 0, 0, 0.7))
		_view.draw_rect(b, Color(UiStyle.GOLD, 0.9), false, 2.0)
		UiStyle.text(_view, b.position + Vector2(0, 39), ["JA", "AVBRYT"][i], 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, b.size.x, 4)
