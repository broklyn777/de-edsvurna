class_name ChipButton
extends Control
## Liten rundad knapp i hörnet (Auto, snabbhet). Reagerar på tryck.

signal pressed

var label := ""
var on := false
var _press := 0.0


func setup(text: String, width := 92.0) -> void:
	label = text
	size = Vector2(width, 44)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press = 1.0
		accept_event()
		pressed.emit()


func _process(delta: float) -> void:
	_press = maxf(0.0, _press - delta * 6.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-2.0 * _press)
	draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else UiStyle.panel(0.8) if UiStyle.ink else Color(0, 0, 0, 0.7))
	draw_rect(r, Color(UiStyle.GOLD, 0.95) if on else UiStyle.INK_EDGE if UiStyle.ink else Color(1, 1, 1, 0.45), false, 2.0)
	UiStyle.text(self, Vector2(0, size.y / 2 + 7), label, 18, Color.WHITE if on else Color(1, 1, 1, 0.8),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
