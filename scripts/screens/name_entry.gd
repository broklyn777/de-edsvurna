class_name NameEntry
extends Control
## Paladinens namn (0.24.2, som i Siralim): en ruta med ett textfält som öppnar telefonens tangentbord. Rutan ligger i
## skärmens övre del, så att tangentbordet (som täcker ungefär den nedre halvan på en telefon på tvären) inte döljer
## fältet. Används när en ny profil börjar (sparplatserna) och när namnet skrivs om i krönikan (Broder Alrik).

signal chosen(hero_name: String)
signal cancelled

var title := "Vad heter du, edsvurne?"
var hint := "Gorm, Imma och de andra kommer att kalla dig så. Lämnar du det tomt heter du Paladinen."
var confirm_label := "SVÄR EDEN"
var can_cancel := false
var start_name := ""
var edit: LineEdit
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	edit = LineEdit.new()
	edit.max_length = Profile.NAME_MAX
	edit.placeholder_text = Profile.DEFAULT_NAME
	edit.text = start_name
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.add_theme_font_override("font", UiStyle.bold())
	edit.add_theme_font_size_override("font_size", 28)
	edit.add_theme_color_override("font_color", Color.WHITE)
	edit.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.35))
	edit.add_theme_color_override("caret_color", UiStyle.GOLD)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.03)
	sb.border_color = UiStyle.GOLD
	sb.set_border_width_all(2)
	sb.set_content_margin_all(10)
	edit.add_theme_stylebox_override("normal", sb)
	edit.add_theme_stylebox_override("focus", sb)
	edit.virtual_keyboard_enabled = true
	edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	edit.text_submitted.connect(func(_t2: String) -> void: _confirm())
	add_child(edit)
	_place()
	edit.grab_focus.call_deferred()
	if edit.has_method("edit"):
		edit.call_deferred("edit")


func _panel() -> Rect2:
	var w := minf(size.x - 60, 720.0)
	return Rect2((size.x - w) / 2.0, 36, w, 270)


func _ok_rect() -> Rect2:
	var p := _panel()
	if can_cancel:
		return Rect2(p.get_center().x + 10, p.end.y - 70, 250, 54)
	return Rect2(p.get_center().x - 140, p.end.y - 70, 280, 54)


func _cancel_rect() -> Rect2:
	var p := _panel()
	return Rect2(p.get_center().x - 260, p.end.y - 70, 250, 54)


func _place() -> void:
	var p := _panel()
	edit.position = Vector2(p.position.x + 60, p.position.y + 108)
	edit.size = Vector2(p.size.x - 120, 58)


func _process(delta: float) -> void:
	_t += delta
	_place()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		return
	accept_event()
	if _ok_rect().has_point(event.position):
		_confirm()
	elif can_cancel and _cancel_rect().has_point(event.position):
		DisplayServer.virtual_keyboard_hide()
		cancelled.emit()
		queue_free()
	else:
		edit.grab_focus()


func _confirm() -> void:
	DisplayServer.virtual_keyboard_hide()
	chosen.emit(edit.text)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var p := _panel()
	draw_rect(p, Color(0.05, 0.04, 0.07, 0.97))
	draw_rect(p, Color(UiStyle.GOLD, 0.85), false, 2.0)
	UiStyle.text(self, p.position + Vector2(0, 46), title, 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, p.size.x, 4)
	UiStyle.text(self, p.position + Vector2(0, 82), hint, 16, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, p.size.x, 3)
	if can_cancel:
		var c := _cancel_rect()
		draw_rect(c, Color(0, 0, 0, 0.6))
		draw_rect(c, Color(1, 1, 1, 0.4), false, 2.0)
		UiStyle.text(self, c.position + Vector2(0, 35), "AVBRYT", 20, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
	var o := _ok_rect()
	draw_rect(o, Color(0.35, 0.25, 0.05, 0.95))
	draw_rect(o, UiStyle.GOLD, false, 2.0)
	UiStyle.text(self, o.position + Vector2(0, 35), confirm_label, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, o.size.x, 3)
