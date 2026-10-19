class_name MacroLog
extends Control
## Förklaringsloggen: varför hjältarna gjorde som de gjorde ("rad 2 matchade: …").
## Visar de senaste besluten i ett hörn; tryck för att öppna hela loggen, tryck igen för att stänga.

const SHOWN := 4
const LINE_H := 23.0

## [{text, ok, skipped: [text]}]
var entries: Array[Dictionary] = []
var expanded := false
var _scroll := 0.0
var _drag_from := -1.0
var _flash := 0.0


func setup() -> void:
	size = Vector2(740, SHOWN * LINE_H + 30)
	mouse_filter = Control.MOUSE_FILTER_STOP


func add(entry: Dictionary) -> void:
	entries.append(entry)
	_flash = 1.0
	_scroll = 0.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_from = event.position.y
		else:
			if absf(event.position.y - _drag_from) < 12.0:
				expanded = not expanded
				_scroll = 0.0
			_drag_from = -1.0
		accept_event()
	elif event is InputEventMouseMotion and expanded and _drag_from >= 0.0:
		_scroll = maxf(0.0, _scroll + event.relative.y)
		accept_event()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 2.0)
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	if expanded:
		return true
	return Rect2(Vector2.ZERO, size).has_point(point)


func _draw() -> void:
	if expanded:
		_draw_expanded()
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(Vector2.ZERO, size), Color(UiStyle.TRAIT_GOLD, 0.25 + 0.5 * _flash), false, 1.5)
	UiStyle.text(self, Vector2(8, 16), "MAKROLOGG – TRYCK FÖR ALLT", 15, Color(1, 1, 1, 0.5))
	var start := maxi(0, entries.size() - SHOWN)
	for i in range(start, entries.size()):
		var e: Dictionary = entries[i]
		var col := Color(1, 1, 1, 0.9) if e.ok else Color("#ff8a6a")
		UiStyle.text(self, Vector2(8, 38 + (i - start) * LINE_H), e.text, 17, col, HORIZONTAL_ALIGNMENT_LEFT, size.x - 14, 3)


func _draw_expanded() -> void:
	var vs := get_viewport_rect().size
	var top_left := -global_position
	draw_rect(Rect2(top_left, vs), Color(0.02, 0.02, 0.05, 0.92))
	UiStyle.text(self, top_left + Vector2(0, 40), "MAKROLOGG", 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 6)
	UiStyle.text(self, top_left + Vector2(0, 64), "Nyast överst. Dra för att bläddra, tryck för att stänga.", 16,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 4)
	var y := 100.0 - _scroll
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		if y > vs.y:
			break
		if y > 80.0:
			UiStyle.text(self, top_left + Vector2(40, y), e.text, 18, Color.WHITE if e.ok else Color("#ff8a6a"),
					HORIZONTAL_ALIGNMENT_LEFT, vs.x - 80, 3)
		y += 24.0
		for s in e.get("skipped", []):
			if y > 80.0 and y < vs.y:
				UiStyle.text(self, top_left + Vector2(70, y), s, 16, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, vs.x - 110, 3)
			y += 20.0
		y += 8.0
