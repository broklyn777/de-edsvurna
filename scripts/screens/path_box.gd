class_name PathBox
extends CanvasLayer
## Valet av paladinens inriktning (Paths, docs/plan/paladin-inriktningar.md): två stora kort, Sköldbäraren och
## Ljusbäraren, med vad de gör och känslan. Används vid eden (introt), hos Gorm (byte) och en gång för en profil som fanns
## före inriktningarna. Ett tryck på ett kort väljer det, knappen svär på det. "SENARE" bara när valet får vänta.

signal done(path_id: String)  # "" = senare

const W := 1000.0
const H := 600.0

var question := ""
var allow_later := false
var current := ""
var price := 0
var _view: Control
var _pick := ""


static func open(host: Node, q: String, later := false) -> PathBox:
	var box := PathBox.new()
	box.question = q
	box.allow_later = later
	host.add_child(box)
	return box


func _ready() -> void:
	layer = 62
	process_mode = Node.PROCESS_MODE_ALWAYS
	var run := get_node("/root/Run")
	current = run.profile.path
	price = Paths.cost(current, run.profile.path_changes)
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_paint)
	_view.gui_input.connect(_input_on)
	add_child(_view)
	run.ui("ui_page", -10.0)
	var args := OS.get_cmdline_user_args()
	for a in args:
		if String(a).begins_with("--path-pick="):
			_pick = String(a).get_slice("=", 1)


func _panel() -> Rect2:
	var a := _view.size
	return Rect2((a.x - W) / 2.0, (a.y - H) / 2.0, W, H)


func _card(i: int) -> Rect2:
	var r := _panel()
	var cw := (W - 90.0) / 2.0
	return Rect2(r.position.x + 30 + i * (cw + 30), r.position.y + 112, cw, 360)


func _swear_rect() -> Rect2:
	var r := _panel()
	return Rect2(r.position.x + (W - 340) / 2.0, r.end.y - 92, 340, 56)


func _later_rect() -> Rect2:
	var r := _panel()
	return Rect2(r.end.x - 200, r.end.y - 84, 170, 42)


func _input_on(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		return
	_view.accept_event()
	var p: Vector2 = event.position
	var run := get_node("/root/Run")
	for i in Paths.IDS.size():
		if _card(i).has_point(p) and Paths.IDS[i] != current:
			_pick = Paths.IDS[i]
			run.ui("ui_tap", -8.0)
	if allow_later and _later_rect().has_point(p):
		_finish("")
		return
	if _pick != "" and _swear_rect().has_point(p) and run.profile.silver >= price:
		_finish(_pick)
		return
	_view.queue_redraw()


func _finish(path_id: String) -> void:
	done.emit(path_id)
	queue_free()


func _paint() -> void:
	var run := get_node("/root/Run")
	var data: Dictionary = run.data
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color(0, 0, 0, 0.7))
	var r := _panel()
	_view.draw_rect(r, Color(0.05, 0.045, 0.06, 0.97))
	_view.draw_rect(r, Color(UiStyle.GOLD, 0.85), false, 2.0)
	UiStyle.text(_view, r.position + Vector2(0, 50), "VÄLJ DIN VÄG", 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, W)
	var qw := UiStyle.bold().get_string_size(question, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	if qw <= W - 60:
		UiStyle.text(_view, r.position + Vector2(0, 86), question, 17, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, W)
	else:  # Gorms längre fråga på två rader
		UiStyle.para(_view, r.position + Vector2(30, 76), question, 17, Color(1, 1, 1, 0.8), W - 60, 2)
	for i in Paths.IDS.size():
		var id: String = Paths.IDS[i]
		var p: Dictionary = data.paths[id]
		var c := _card(i)
		var on := id == _pick
		var tag := "DIN VÄG NU" if id == current else ""
		UiStyle.card(_view, c, p.name, "", on, UiStyle.GOLD, tag)
		Glyphs.draw(_view, p.get("icon", "shield"), c.position + Vector2(c.size.x - 34, 70), 14.0, Color(UiStyle.GOLD, 0.8))
		var y := c.position.y + 56
		y += UiStyle.para(_view, Vector2(c.position.x + 18, y), p.feel, 18, Color(1, 1, 1, 0.92), c.size.x - 70, 3) + 14
		for line in p.card:
			_view.draw_circle(Vector2(c.position.x + 24, y - 6), 3.0, Color(UiStyle.GOLD, 0.8))
			y += UiStyle.para(_view, Vector2(c.position.x + 36, y), line, 17, Color(1, 1, 1, 0.78), c.size.x - 56, 2) + 8
	var label := "VÄLJ EN VÄG" if _pick == "" else "SVÄR PÅ %s" % String(data.paths[_pick].short).to_upper()
	var ok: bool = _pick != "" and run.profile.silver >= price
	UiStyle.big_button(_view, _swear_rect(), label, 0.0, ok)
	var cost_text := "Gratis" if price == 0 else "Kostar %d silver (du har %d)" % [price, run.profile.silver]
	if current != "" or price > 0:
		UiStyle.text(_view, Vector2(r.position.x, _swear_rect().position.y - 10), cost_text, 16,
				Color(1, 1, 1, 0.65) if ok or _pick == "" else Color(1, 0.6, 0.5), HORIZONTAL_ALIGNMENT_CENTER, W)
	if allow_later:
		var b := _later_rect()
		_view.draw_rect(b, Color(0, 0, 0, 0.5))
		_view.draw_rect(b, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
		UiStyle.text(_view, b.position + Vector2(0, 29), "SENARE", 17, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
