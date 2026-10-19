class_name BattleOverlay
extends Control
## Helskärmstexter: nedräkning, paus, raidvarningar, felmeddelanden och resultat.

signal restart_requested

var mode := ""  # "", "countdown", "victory", "defeat"
var paused := false
var big_text := ""
var sub_text := ""
var _big_t := 0.0
var _announce := ""
var _announce_t := 0.0
var _message := ""
var _message_t := 0.0
var _t := 0.0
## Extra rader under resultatet (kvittot).
var lines: Array[String] = []
## Inspect: en figurs namn och rader (stats och egenskaper) medan spelaren håller fingret på den.
var inspect_title := ""
var inspect_lines: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_big(text: String, sub := "") -> void:
	big_text = text
	sub_text = sub
	_big_t = 0.0


func announce(text: String) -> void:
	_announce = text
	_announce_t = 3.0


func message(text: String) -> void:
	_message = text
	_message_t = 1.4


func show_inspect(title: String, rows: Array[String]) -> void:
	inspect_title = title
	inspect_lines = rows


func hide_inspect() -> void:
	inspect_title = ""
	inspect_lines = []


func set_result(result: String, sub: String, title := "") -> void:
	mode = result
	show_big(title if title != "" else ("SEGER!" if result == "victory" else "SÄLLSKAPET HAR STUPAT"), sub)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if mode in ["victory", "defeat"] and _big_t > 1.0 and event is InputEventMouseButton and event.pressed:
		restart_requested.emit()
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	_big_t += delta
	_announce_t = maxf(0.0, _announce_t - delta)
	_message_t = maxf(0.0, _message_t - delta)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.06, 0.45))
		UiStyle.text(self, Vector2(0, h * 0.42), "TAKTISK PAUS", 44, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, w, 8)
		UiStyle.text(self, Vector2(0, h * 0.42 + 38), "Ge order – de utförs när du fortsätter", 20,
				Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, w, 5)
	if mode in ["victory", "defeat"]:
		var a := minf(1.0, _big_t * 1.5)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5 * a))
	if big_text != "":
		var pop := 1.0 + 0.6 * maxf(0.0, 1.0 - _big_t / 0.18)
		var a := 1.0 if mode != "countdown" else clampf(1.0 - (_big_t - 0.6) / 0.35, 0.0, 1.0)
		var col := UiStyle.GOLD if mode != "defeat" else Color("#e0412e")
		draw_set_transform(Vector2(w / 2, h * 0.45), 0, Vector2.ONE * pop)
		UiStyle.text(self, Vector2(-w / 2, 0), big_text, 72, Color(col, a), HORIZONTAL_ALIGNMENT_CENTER, w, 10)
		draw_set_transform(Vector2.ZERO)
		if sub_text != "":
			UiStyle.text(self, Vector2(0, h * 0.45 + 50), sub_text, 22, Color(1, 1, 1, 0.85 * a),
					HORIZONTAL_ALIGNMENT_CENTER, w, 5)
		for i in lines.size():
			UiStyle.text(self, Vector2(0, h * 0.45 + 90 + i * 26), lines[i], 18, Color(UiStyle.TRAIT_GOLD, a),
					HORIZONTAL_ALIGNMENT_CENTER, w, 5)
		if mode in ["victory", "defeat"] and _big_t > 1.0:
			var blink := 0.6 + 0.4 * sin(_t * 4.0)
			UiStyle.text(self, Vector2(0, h - 40), "Tryck för att fortsätta", 20, Color(1, 1, 1, blink),
					HORIZONTAL_ALIGNMENT_CENTER, w, 5)
	if _announce_t > 0.0:
		var a := minf(1.0, _announce_t)
		var pop := 1.0 + 0.3 * maxf(0.0, (_announce_t - 2.8) / 0.2)
		draw_set_transform(Vector2(w / 2, 150), 0, Vector2.ONE * pop)
		UiStyle.text(self, Vector2(-w / 2, 0), _announce, 30, Color(1, 0.55, 0.2, a), HORIZONTAL_ALIGNMENT_CENTER, w, 6)
		draw_set_transform(Vector2.ZERO)
	if inspect_title != "":
		var bw := minf(w - 40.0, 760.0)
		var r := Rect2((w - bw) / 2.0, 70, bw, 70 + inspect_lines.size() * 46)
		draw_rect(r, Color(0.03, 0.025, 0.05, 0.94))
		draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
		UiStyle.text(self, r.position + Vector2(0, 38), inspect_title, 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, bw, 5)
		for i in inspect_lines.size():
			var font := UiStyle.bold()
			var pos := r.position + Vector2(20, 76 + i * 46)
			draw_multiline_string(font, pos, inspect_lines[i], HORIZONTAL_ALIGNMENT_LEFT, bw - 40, 17, 2, Color(1, 1, 1, 0.9))
	if _message_t > 0.0:
		UiStyle.text(self, Vector2(0, h - 150), _message, 20, Color(1, 0.35, 0.3, minf(1.0, _message_t * 2.0)),
				HORIZONTAL_ALIGNMENT_CENTER, w, 5)
