class_name SettingsBox
extends CanvasLayer
## Inställningarna (0.30): musikens och ljudeffekternas volym (för hela spelet, GameSettings) och rumsögonblicken
## (profilens). Läggs ovanpå borgen eller striden; i striden pausas spelet medan rutan är öppen. Tryck eller dra på en
## stapel för att ändra, KLAR sparar och stänger. Under dem står speltiden (Playtime): snitt per strid och nedstigning,
## med NOLLSTÄLL SPELTID (och en bekräftelse). Klockan står still medan rutan är öppen.

signal closed

const W := 680.0
const H := 560.0
const STEPS := 10

var pause_tree := false
var _view: Control
var _drag := ""  # "music" | "sfx" medan fingret drar på en stapel
var _confirm_reset := false  # frågan om att nollställa speltiden visas


static func open(host: Node, pause := false) -> SettingsBox:
	var box := SettingsBox.new()
	box.pause_tree = pause
	host.add_child(box)
	return box


func _ready() -> void:
	layer = 61
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"stops_playtime")
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_paint)
	_view.gui_input.connect(_input_on)
	add_child(_view)
	if pause_tree:
		get_tree().paused = true
	_run().ui("ui_page", -10.0)


func _run() -> Node:
	return get_node("/root/Run")


func _panel() -> Rect2:
	var a := _view.size
	return Rect2((a.x - W) / 2.0, (a.y - H) / 2.0, W, H)


func _bar(i: int) -> Rect2:
	var r := _panel()
	return Rect2(r.position.x + 230, r.position.y + 96 + i * 72, W - 270, 36)


func _moments_rect() -> Rect2:
	var r := _panel()
	return Rect2(r.position.x + 40, r.position.y + 244, W - 80, 44)


## Speltidens knapp (eller JA/AVBRYT i bekräftelsen: i = 0 och 1).
func _reset_rect(i := -1) -> Rect2:
	var r := _panel()
	var y := r.position.y + 424  # 0.31: plats för fyra rader speltid
	if i < 0:
		return Rect2(r.position.x + (W - 300) / 2.0, y, 300, 44)
	return Rect2(r.position.x + W / 2.0 - 250 + i * 270, y, 230, 44)


## Prototyp (sallskap-fem): FPS PÅ/AV i hörnet bredvid KLAR.
func _fps_rect() -> Rect2:
	var r := _panel()
	return Rect2(r.position.x + 30, r.end.y - 64, 150, 42)


func _done_rect() -> Rect2:
	var r := _panel()
	return Rect2(r.position.x + (W - 200) / 2.0, r.end.y - 66, 200, 46)


func _input_on(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_view.accept_event()
		var p: Vector2 = event.position
		if event.pressed:
			for i in 2:
				if _bar(i).grow(14).has_point(p):
					_drag = ["music", "sfx"][i]
					_set_from(p)
			return
		var was := _drag
		_drag = ""
		if was == "sfx":
			_run().ui("ui_tap", -6.0)  # så att man hör den nya volymen
		elif was == "":
			if _moments_rect().has_point(p):
				_run().profile.room_moments = not _run().profile.room_moments
				_run().save()
			elif _confirm_reset and _reset_rect(0).has_point(p):
				_run().playtime.reset()
				_confirm_reset = false
				_run().ui("ui_confirm", -8.0)
			elif _confirm_reset and _reset_rect(1).has_point(p):
				_confirm_reset = false
				_run().ui("ui_back", -12.0)
			elif not _confirm_reset and _reset_rect().has_point(p):
				_confirm_reset = true
				_run().ui("ui_tap", -8.0)
			elif _fps_rect().has_point(p):
				GameSettings.show_fps = not GameSettings.show_fps
				FpsMeter.set_shown(_run(), GameSettings.show_fps)
			elif _done_rect().has_point(p):
				_close()
		_view.queue_redraw()
	elif event is InputEventMouseMotion and _drag != "":
		_view.accept_event()
		_set_from(event.position)


func _set_from(p: Vector2) -> void:
	var i := 0 if _drag == "music" else 1
	var b := _bar(i)
	var v := roundf(clampf((p.x - b.position.x) / b.size.x, 0.0, 1.0) * STEPS) / STEPS
	if _drag == "music":
		GameSettings.music = v
	else:
		GameSettings.sfx = v
	GameSettings.apply()
	_view.queue_redraw()


func _close() -> void:
	GameSettings.save()
	_run().ui("ui_back", -12.0)
	if pause_tree:
		get_tree().paused = false
	closed.emit()
	queue_free()


func _paint() -> void:
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color(0, 0, 0, 0.6))
	var r := _panel()
	_view.draw_rect(r, Color(0.05, 0.045, 0.06, 0.97))
	_view.draw_rect(r, Color(UiStyle.GOLD, 0.85), false, 2.0)
	UiStyle.text(_view, r.position + Vector2(0, 56), "INSTÄLLNINGAR", 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, W)
	var labels := ["Musik", "Ljudeffekter"]
	var values := [GameSettings.music, GameSettings.sfx]
	for i in 2:
		var b := _bar(i)
		UiStyle.text(_view, Vector2(r.position.x + 40, b.position.y + 26), labels[i], 20, Color(1, 1, 1, 0.92))
		_view.draw_rect(b, Color(1, 1, 1, 0.08))
		_view.draw_rect(Rect2(b.position, Vector2(b.size.x * values[i], b.size.y)), Color(UiStyle.GOLD, 0.75))
		_view.draw_rect(b, Color(UiStyle.GOLD, 0.6), false, 1.5)
		# Ett handtag vid värdet, så att det syns att stapeln går att dra i.
		var hx: float = b.position.x + b.size.x * float(values[i])
		_view.draw_rect(Rect2(hx - 9, b.position.y - 8, 18, b.size.y + 16), Color(0.95, 0.9, 0.75))
		_view.draw_rect(Rect2(hx - 9, b.position.y - 8, 18, b.size.y + 16), Color(UiStyle.GOLD), false, 2.0)
		var pct := "AV" if values[i] <= 0.0 else "%d %%" % roundi(values[i] * 100.0)
		UiStyle.text(_view, b.position + Vector2(0, 26), pct, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	UiStyle.text(_view, r.position + Vector2(0, 84), "Dra i staplarna för att ändra.", 15, Color(1, 1, 1, 0.55),
			HORIZONTAL_ALIGNMENT_CENTER, W)
	var m := _moments_rect()
	_view.draw_rect(m, Color(0, 0, 0, 0.5))
	_view.draw_rect(m, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(_view, m.position + Vector2(0, 29), "RUMSÖGONBLICK I GROTTAN: " + ("PÅ" if _run().profile.room_moments else "AV"),
			18, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, m.size.x)
	# Speltiden (alla profiler): snitt per strid och nedstigning, och per typ av strid.
	var y := r.position.y + 316
	_view.draw_line(Vector2(r.position.x + 40, y - 18), Vector2(r.end.x - 40, y - 18), Color(UiStyle.GOLD, 0.3), 1.0)
	if _confirm_reset:
		UiStyle.text(_view, Vector2(r.position.x, y + 12), "Nollställa all speltid? Det går inte att ångra.", 17,
				Color(1, 0.85, 0.75), HORIZONTAL_ALIGNMENT_CENTER, W)
		_small_button(_reset_rect(0), "JA, NOLLSTÄLL", Color(0.55, 0.12, 0.08, 0.95))
		_small_button(_reset_rect(1), "AVBRYT", Color(0, 0, 0, 0.5))
	else:
		var lines: Array[String] = _run().playtime.summary_lines()
		for i in lines.size():
			UiStyle.text(_view, Vector2(r.position.x + 30, y + i * 26),
					UiStyle.fit(lines[i], 17 if i == 0 else 16, W - 60), 17 if i == 0 else 16,
					Color(1, 1, 1, 0.9 if i == 0 else 0.7), HORIZONTAL_ALIGNMENT_CENTER, W - 60)
		_small_button(_reset_rect(), "NOLLSTÄLL SPELTID", Color(0, 0, 0, 0.5))
	UiStyle.big_button(_view, _done_rect(), "KLAR", 0.0)
	_small_button(_fps_rect(), "FPS: " + ("PÅ" if GameSettings.show_fps else "AV"), Color(0, 0, 0, 0.5))


func _small_button(b: Rect2, label: String, fill: Color) -> void:
	_view.draw_rect(b, fill)
	_view.draw_rect(b, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(_view, b.position + Vector2(0, 29), label, 17, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
