class_name HelpBox
extends CanvasLayer
## Hjälprutan (0.25, Siralims "?"-rutor, docs/plan/0.25-berattelsen.md §3): ett grönt ?, en rubrik och 2–3 korta
## stycken. Help.take väljer vilka rutor som är nya för profilen; HelpBox.offer lägger dem ovanpå skärmen, en i taget,
## och ett tryck går vidare. I striden pausas spelet medan rutan syns. Broder Alriks handbok ritar samma ruta.

signal finished

const GREEN := Color("#5fd16a")
const W := 780.0

var ids: Array = []
var data: Dictionary
var custom := {}  # 0.30: en ruta med egen text (kombinationen i striden), annars Help.entry
## karta-synlig: rutor som pekar på något på skärmen, {id: Rect2}. Det området lämnas ljust med en pulserande ring och
## en pil, och rutan läggs bredvid i stället för över det.
var focus := {}
var pause_tree := false
var _i := 0
var _t := 0.0
var _view: Control


## Visar de rutor av ids som profilen inte har sett. Returnerar rutan, eller null om allt redan är sett
## (eller --no-help gäller, för skärmdumpar).
static func offer(host: Node, wanted: Array, pause := false) -> HelpBox:
	var run := host.get_node("/root/Run")
	if "--no-help" in OS.get_cmdline_user_args():
		return null
	var fresh := Help.take(run.data, run.profile, wanted)
	if fresh.is_empty():
		return null
	run._save()
	var box := HelpBox.new()
	box.ids = fresh
	box.data = run.data
	box.pause_tree = pause
	host.add_child(box)
	return box


## 0.30: rutan id första gången, med en egen text i stället för handbokens (t.ex. siffrorna i en kombination).
static func offer_custom(host: Node, id: String, e: Dictionary, pause := false) -> HelpBox:
	var run := host.get_node("/root/Run")
	if "--no-help" in OS.get_cmdline_user_args() or Help.take(run.data, run.profile, [id]).is_empty():
		return null
	run._save()
	var box := HelpBox.new()
	box.ids = [id]
	box.custom = e
	box.data = run.data
	box.pause_tree = pause
	host.add_child(box)
	return box


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"stops_playtime")  # speltiden står still medan rutan läses
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_paint)
	_view.gui_input.connect(_input_on)
	add_child(_view)
	if pause_tree:
		get_tree().paused = true
	var run := get_node_or_null("/root/Run")
	if run:
		run.ui("ui_page", -10.0)


func _process(delta: float) -> void:
	_t += delta
	_view.queue_redraw()


func _input_on(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_view.accept_event()
		if not event.pressed and _t > 0.35:
			_next()


func _next() -> void:
	_i += 1
	_t = 0.0
	if _i < ids.size():
		return
	if pause_tree:
		get_tree().paused = false
	finished.emit()
	queue_free()


func _paint() -> void:
	var area := _view.size
	var e := custom if not custom.is_empty() else Help.entry(data, ids[_i])
	var r := panel_rect(area, e)
	var spot: Variant = focus.get(ids[_i])
	if spot is Rect2:
		r = _paint_focus(area, e, spot)
	else:
		_view.draw_rect(Rect2(Vector2.ZERO, area), Color(0, 0, 0, 0.6))
	draw_entry(_view, r, e)
	var foot := "Tryck för att fortsätta" + ("   (%d/%d)" % [_i + 1, ids.size()] if ids.size() > 1 else "")
	UiStyle.text(_view, Vector2(r.position.x, r.end.y - 16), foot, 17, Color(UiStyle.GOLD, 0.75 + 0.25 * sin(_t * 4.0)),
			HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 22)


## Mörkt runt området (spot lämnas ljust), en pulserande guldring och en pil från rutan. Returnerar rutans plats.
func _paint_focus(area: Vector2, e: Dictionary, spot: Rect2) -> Rect2:
	var hole := spot.grow(14)
	var dim := Color(0, 0, 0, 0.6)
	_view.draw_rect(Rect2(0, 0, area.x, maxf(hole.position.y, 0)), dim)
	_view.draw_rect(Rect2(0, hole.end.y, area.x, area.y - hole.end.y), dim)
	_view.draw_rect(Rect2(0, hole.position.y, maxf(hole.position.x, 0), hole.size.y), dim)
	_view.draw_rect(Rect2(hole.end.x, hole.position.y, area.x - hole.end.x, hole.size.y), dim)
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	_view.draw_rect(hole, Color(UiStyle.GOLD, 0.55 + 0.45 * pulse), false, 4.0)
	_view.draw_rect(hole.grow(6.0 + 6.0 * pulse), Color(UiStyle.GOLD, 0.35 * (1.0 - pulse)), false, 3.0)
	var r := focus_panel_rect(area, e, hole)
	# Pilen: från rutans kant mot området, med en spets som gungar lite.
	var c := hole.get_center()
	var from := Vector2(clampf(c.x, r.position.x + 24, r.end.x - 24), clampf(c.y, r.position.y + 24, r.end.y - 24))
	if not r.has_point(c):
		from = Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
	var to := Vector2(clampf(from.x, hole.position.x, hole.end.x), clampf(from.y, hole.position.y, hole.end.y))
	var dir := (to - from).normalized()
	if dir != Vector2.ZERO:
		var tip := to - dir * (10.0 + 8.0 * pulse)
		var gold := Color(UiStyle.GOLD, 0.95)
		_view.draw_line(from, tip, gold, 5.0, true)
		var side := Vector2(-dir.y, dir.x)
		_view.draw_colored_polygon(PackedVector2Array([tip + dir * 16.0, tip - dir * 6.0 + side * 13.0,
				tip - dir * 6.0 - side * 13.0]), gold)
	return r


## Rutan bredvid området hole: till höger, vänster, under eller över, där den får plats; annars mitt på skärmen.
static func focus_panel_rect(area: Vector2, e: Dictionary, hole: Rect2) -> Rect2:
	const GAP := 24.0  # under eller över (höjden är knapp)
	const SIDE_GAP := 56.0  # bredvid: plats för pilen
	const EDGE := 14.0
	const WIDE := 1100.0  # under eller över området får rutan vara bredare (färre rader)
	var cands: Array[Rect2] = []
	for side in ["right", "left", "below", "above"]:
		var room_w := area.x - 2 * EDGE
		var room_h := area.y - 2 * EDGE
		match side:
			"right": room_w = area.x - hole.end.x - SIDE_GAP - EDGE
			"left": room_w = hole.position.x - SIDE_GAP - EDGE
			"below": room_h = area.y - hole.end.y - GAP - EDGE
			"above": room_h = hole.position.y - GAP - EDGE
		var w := minf(room_w, W if side in ["right", "left"] else WIDE)
		if w < 520.0:
			continue
		var h := content_height(e, w) + 44.0
		if h > room_h:
			continue
		var x := 0.0
		var y := clampf(hole.get_center().y - h / 2.0, EDGE, area.y - EDGE - h)
		match side:
			"right": x = hole.end.x + SIDE_GAP
			"left": x = hole.position.x - SIDE_GAP - w
			_:
				x = clampf(hole.get_center().x - w / 2.0, EDGE, area.x - EDGE - w)
				y = hole.end.y + GAP if side == "below" else hole.position.y - GAP - h
		cands.append(Rect2(x, y, w, h))
	if cands.is_empty():
		return panel_rect(area, e)
	return cands[0]


## Rutan mitt på skärmen, så hög som texten behöver.
static func panel_rect(area: Vector2, e: Dictionary) -> Rect2:
	var w := minf(area.x - 60, W)
	var h := minf(area.y - 60, content_height(e, w) + 44.0)
	return Rect2((area.x - w) / 2.0, (area.y - h) / 2.0, w, h)


## Höjden som rubriken och styckena tar i en ruta med bredden w.
static func content_height(e: Dictionary, w: float) -> float:
	var h := 112.0
	for para in e.get("text", []):
		h += UiStyle.bold().get_multiline_string_size(String(para), HORIZONTAL_ALIGNMENT_LEFT, w - 68, 19).y + 14
	return h


## Rutan: mörk botten, ett grönt ? i en ring, rubriken och styckena.
static func draw_entry(ci: CanvasItem, r: Rect2, e: Dictionary) -> void:
	ci.draw_rect(r, Color(0.04, 0.05, 0.05, 0.97))
	ci.draw_rect(r, Color(GREEN, 0.8), false, 2.0)
	ci.draw_rect(r.grow(-6), Color(GREEN, 0.25), false, 1.0)
	var c := r.position + Vector2(52, 52)
	ci.draw_circle(c, 26, Color(0.05, 0.18, 0.07))
	ci.draw_arc(c, 26, 0, TAU, 40, GREEN, 3.0, true)
	UiStyle.text(ci, c + Vector2(-26, 12), "?", 34, GREEN, HORIZONTAL_ALIGNMENT_CENTER, 52)
	UiStyle.text(ci, r.position + Vector2(96, 62), String(e.get("title", "")), 28, GREEN)
	var y := r.position.y + 112
	for para in e.get("text", []):
		y += UiStyle.para(ci, Vector2(r.position.x + 34, y), String(para), 19, Color(1, 1, 1, 0.92), r.size.x - 68) + 14
