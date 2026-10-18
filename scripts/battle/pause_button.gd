extends Control
## Knapp för taktisk paus.

signal toggled_pause

var paused := false


func _ready() -> void:
	size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggled_pause.emit()
		accept_event()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var c := size / 2
	draw_circle(c, 28, Color(0, 0, 0, 0.7))
	draw_arc(c, 28, 0, TAU, 40, Color(1, 1, 1, 0.5 if not paused else 0.95), 2.5, true)
	if paused:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -12), c + Vector2(13, 0), c + Vector2(-8, 12)]), Color.WHITE)
	else:
		draw_rect(Rect2(c + Vector2(-10, -11), Vector2(7, 22)), Color.WHITE)
		draw_rect(Rect2(c + Vector2(3, -11), Vector2(7, 22)), Color.WHITE)
