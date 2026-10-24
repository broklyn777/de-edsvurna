class_name BattleOverlay
extends Control
## Helskärmstexter: nedräkning, paus, raidvarningar, felmeddelanden och resultat.

signal restart_requested
## Ge upp (0.20.1): bekräftelsen svarar ja eller nej.
signal forfeit_answered(yes: bool)

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
## Nivåuppgångar efter segern (0.19): [{name, level, gains: {stat: ökning}, xp}]. Siffrorna räknas upp.
var level_ups: Array = []
## Fynden efter segern (0.20): material och Nether Stones, till höger, ett i taget med glöd.
var finds: Array = []
## 0.30: "Det här avgjorde striden" till vänster (BattleSummary.deciders): [{name, tag, who, text}].
var deciders: Array = []
## 0.30.16: fingeravtryckets andra halva. Radindex -> troféer man äger som kunde ta dess plats (BattleSummary.alternatives);
## ett tryck på raden öppnar listan, ett tryck utanför stänger den.
var alternatives := {}
var alt_open := -1
var alt_hint := "Byt troféer vid en lägereld."
var data: Dictionary = {}
## Våningsreglerna som gäller (visas uppe till höger under knapparna).
var rules_text := ""
## Rader i Inspect som börjar med det här tecknet är en troféns lärdom (VD 2026-10-23) och ritas kursivt.
const LESSON_MARK := "§"
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


## Uträkningen bakom en siffra (0.21): visas tills nästa tryck.
var calc_title := ""
var calc_lines: Array[String] = []


func show_calc(title: String, rows: Array[String]) -> void:
	calc_title = title
	calc_lines = rows


func hide_calc() -> void:
	calc_title = ""
	calc_lines = []


func _draw_calc(w: float) -> void:
	var bw := minf(w - 40.0, 860.0)
	var font := UiStyle.bold()
	var h := 64.0
	for line in calc_lines:
		h += font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, bw - 40, 18).y + 6
	var r := Rect2((w - bw) / 2.0, 66, bw, h + 34)
	draw_rect(r, Color(0.03, 0.025, 0.05, 0.95))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.85), false, 2.0)
	UiStyle.text(self, r.position + Vector2(20, 36), calc_title, 22, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT, bw - 40, 4)
	var y := r.position.y + 70
	for i in calc_lines.size():
		var last := i == calc_lines.size() - 1
		y += 6 + UiStyle.para(self, Vector2(r.position.x + 20, y), calc_lines[i], 19 if last else 18,
				UiStyle.GOLD if last else Color(1, 1, 1, 0.9), bw - 40)
	UiStyle.text(self, Vector2(r.position.x, r.end.y - 10), "Tryck för att stänga", 15, Color(1, 1, 1, 0.5),
			HORIZONTAL_ALIGNMENT_CENTER, bw, 0)


## "Brokk nådde nivå 5!" med statsen som steg, uppräknade, under kvittot.
func _draw_level_ups(w: float, h: float, a: float) -> void:
	var y := h * 0.45 + 100 + lines.size() * 26
	# Mittfältet mellan "Det här avgjorde striden" och fynden.
	var cw := minf(w - 2 * 380.0, 600.0) if w > 1100.0 else w - 32.0
	var cx := (w - cw) / 2.0
	for i in level_ups.size():
		var u: Dictionary = level_ups[i]
		var start := 1.0 + i * 0.35
		var t := clampf((_big_t - start) / 0.8, 0.0, 1.0)
		if t <= 0.0:
			continue
		var rows: Array = []
		if not Array(u.get("jump", [])).is_empty():
			# Nivåskalan (VD 2026-10-25): hoppet i det striden gör, mot en typisk fiende på djupet (som hjältebladet).
			var jump: Array = u.jump
			rows.append(LevelJump.text(jump.slice(0, 2)))
			if jump.size() > 2:
				rows.append(LevelJump.text(jump.slice(2)))
		else:
			var parts: Array = []
			for stat in HeroStats.STATS:
				var g := float(u.gains.get(stat, 0))
				if g > 0.0:
					parts.append("+%s %s" % [HeroStats.shown(g * t), HeroStats.STAT_NAMES[stat]])
			rows.append("  ".join(parts))
		var pop := 1.0 + 0.25 * maxf(0.0, 1.0 - t * 4.0)
		draw_set_transform(Vector2(w / 2, y), 0, Vector2.ONE * pop)
		UiStyle.text(self, Vector2(-w / 2, 0), "%s nådde nivå %d!" % [u.name, u.level], 20, Color(UiStyle.GOLD, a * minf(1.0, t * 3.0)),
				HORIZONTAL_ALIGNMENT_CENTER, w, 5)
		draw_set_transform(Vector2.ZERO)
		y += 20
		for row in rows:
			UiStyle.text(self, Vector2(cx, y), UiStyle.fit(String(row), 16, cw), 16, Color(1, 1, 1, 0.85 * a * t),
					HORIZONTAL_ALIGNMENT_CENTER, cw, 4)
			y += 20
		if u.has("rank"):
			# Edsgraden (VD 2026-10-25): titeln och en replik, inga siffror.
			var rt := clampf((_big_t - start - 0.6) / 0.8, 0.0, 1.0)
			y += 8
			UiStyle.text(self, Vector2(cx, y), "EDSGRAD: %s" % String(u.rank.title).to_upper(), 19,
					Color(UiStyle.TRAIT_GOLD, a * rt), HORIZONTAL_ALIGNMENT_CENTER, cw, 5)
			y += 4
			var line: Dictionary = u.rank.get("line", {})
			if not line.is_empty():
				y += UiStyle.para(self, Vector2(cx, y + 18), "%s: ”%s”" % [line.name, line.text], 16,
						Color(1, 1, 1, 0.8 * a * rt), cw, 4)
			y += 4
		y += 14


## Det här avgjorde striden: till vänster om resultatet, spegelvänt mot fynden. Taggen säger vilken del av bygget
## (trofé, kall, artefakt, egen eller en kombination) som bar striden.
func _draw_deciders(w: float, h: float, a: float) -> void:
	if deciders.is_empty():
		return
	var x := 30.0
	var y := _deciders_top(h)
	# En mörk platta, så att raderna går att läsa ovanpå sällskapets ramar (tre eller fyra hjältar).
	var plate := Rect2(x - 14, y - 26, 358, 48 + deciders.size() * 64)
	draw_rect(plate, Color(0.03, 0.03, 0.05, 0.92 * a))
	draw_rect(plate, Color(UiStyle.TRAIT_GOLD, 0.35 * a), false, 1.5)
	UiStyle.text(self, Vector2(x, y), "DET HÄR AVGJORDE STRIDEN", 16, Color(1, 1, 1, 0.6 * a), HORIZONTAL_ALIGNMENT_LEFT, 330, 4)
	for i in deciders.size():
		var d: Dictionary = deciders[i]
		var t := clampf((_big_t - 1.2 - i * 0.3) / 0.4, 0.0, 1.0)
		if t <= 0.0:
			continue
		var p := Vector2(x, y + 30 + i * 64)
		var col := UiStyle.GOLD if d.tag == "KOMBINATION" else UiStyle.TRAIT_GOLD
		UiStyle.text(self, p, d.tag, 15, Color(col, 0.75 * a * t), HORIZONTAL_ALIGNMENT_LEFT, 330, 4)
		UiStyle.text(self, p + Vector2(0, 20), d.name, 17, Color(col.lightened(0.2), a * t), HORIZONTAL_ALIGNMENT_LEFT, 330, 4)
		UiStyle.text(self, p + Vector2(0, 40), "%s · %s" % [d.who, d.text], 15, Color(1, 1, 1, 0.75 * a * t),
				HORIZONTAL_ALIGNMENT_LEFT, 330, 4)
		if alternatives.has(i):
			var open := alt_open == i
			if open:
				draw_rect(_decider_rect(i), Color(UiStyle.GOLD, 0.12 * a * t))
			# Efter taggen, till vänster om resultatets rubrik (som ritas ovanpå plattans högra del).
			UiStyle.text(self, p + Vector2(62, 0), "· ANDRA TROFÉER ▸" if not open else "· STÄNG ◂", 15,
					Color(UiStyle.GOLD, 0.85 * a * t), HORIZONTAL_ALIGNMENT_LEFT, 200, 4)


func _deciders_top(h: float) -> float:
	return h * 0.45 - 40.0


func _decider_rect(i: int) -> Rect2:
	return Rect2(16, _deciders_top(size.y) + 12 + i * 64, 356, 62)


## Listan bredvid raden: de troféer man äger som kunde ta dess plats, med vem som bär dem nu.
func _draw_alternatives(h: float, a: float) -> void:
	var list: Array = alternatives[alt_open]
	var r := Rect2(384, _deciders_top(h) - 26, 440, 52 + list.size() * 66)
	draw_rect(r, Color(0.03, 0.03, 0.05, 0.96 * a))
	draw_rect(r, Color(UiStyle.GOLD, 0.6 * a), false, 2.0)
	UiStyle.text(self, r.position + Vector2(14, 26), "KUNDE TA DESS PLATS", 16, Color(1, 1, 1, 0.6 * a), HORIZONTAL_ALIGNMENT_LEFT,
			r.size.x - 28, 4)
	for i in list.size():
		var o: Dictionary = list[i]
		var p := r.position + Vector2(14, 56 + i * 66)
		UiStyle.text(self, p, UiStyle.fit(o.name, 17, 250), 17, Color(UiStyle.TRAIT_GOLD.lightened(0.2), a), HORIZONTAL_ALIGNMENT_LEFT,
				r.size.x - 28, 4)
		var who: String = "ingen bär den" if o.wearer == "" else "bärs av " + String(o.wearer)
		UiStyle.text(self, p, who, 15, Color(1, 1, 1, 0.55 * a), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 28, 4)
		UiStyle.para(self, p + Vector2(0, 22), o.text, 15, Color(1, 1, 1, 0.8 * a), r.size.x - 28, 2)
	UiStyle.text(self, Vector2(r.position.x, r.end.y + 22), alt_hint, 15, Color(1, 1, 1, 0.55 * a),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 4)


## Fynden till höger om resultatet: en ädelsten i fyndets färg och namnet, ett i taget.
func _draw_finds(w: float, h: float, a: float) -> void:
	if finds.is_empty():
		return
	var x := w - 330.0
	var y := h * 0.45 - 40.0
	UiStyle.text(self, Vector2(x, y), "FYND", 16, Color(1, 1, 1, 0.6 * a), HORIZONTAL_ALIGNMENT_LEFT, 300, 4)
	for i in finds.size():
		var f: Dictionary = finds[i]
		var t := clampf((_big_t - 1.6 - i * 0.3) / 0.4, 0.0, 1.0)
		if t <= 0.0:
			continue
		var c := Vector2(x + 16, y + 34 + i * 50)
		var pop := 1.0 + 0.5 * maxf(0.0, 1.0 - t * 3.0)
		GemArt.draw_find(self, data, f, c, 12.0 * pop, _t)
		var col := Forge.find_color(data, f)
		UiStyle.text(self, c + Vector2(24, 2), Forge.find_text(data, f), 17, Color(col.lightened(0.2), a * t),
				HORIZONTAL_ALIGNMENT_LEFT, 290, 4)
		# 0.29.5: vad fyndet gör, på en rad under namnet.
		UiStyle.text(self, c + Vector2(24, 22), Forge.find_effect(data, f), 15, Color(1, 1, 1, 0.7 * a * t),
				HORIZONTAL_ALIGNMENT_LEFT, 290, 4)


func set_result(result: String, sub: String, title := "") -> void:
	mode = result
	show_big(title if title != "" else ("SEGER!" if result == "victory" else "SÄLLSKAPET HAR STUPAT"), sub)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Frågar om spelaren vill ge upp (striden står still under tiden).
func ask_forfeit(practice: bool) -> void:
	mode = "confirm"
	_confirm_practice = practice
	mouse_filter = Control.MOUSE_FILTER_STOP


var _confirm_practice := false


func confirm_yes_rect() -> Rect2:
	return Rect2(size.x / 2 - 290, size.y / 2 + 40, 270, 64)


func confirm_no_rect() -> Rect2:
	return Rect2(size.x / 2 + 20, size.y / 2 + 40, 270, 64)


func _draw_confirm(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.72))
	var panel := Rect2(w / 2 - 330, h / 2 - 120, 660, 250)
	draw_rect(panel, Color(0.07, 0.06, 0.09, 0.97))
	draw_rect(panel, Color("#e0412e", 0.8), false, 2.0)
	UiStyle.text(self, Vector2(0, h / 2 - 72), "GE UPP?", 34, Color("#e0412e"), HORIZONTAL_ALIGNMENT_CENTER, w, 6)
	var text := "Övningen avslutas." if _confirm_practice else "Körningen är förlorad och Realmen börjar om från våning 1."
	UiStyle.text(self, Vector2(0, h / 2 - 30), text, 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w, 4)
	if not _confirm_practice:
		UiStyle.text(self, Vector2(0, h / 2 - 4), "Det ni redan har vunnit – erfarenhet, troféer, silver och material – behåller ni.",
				15, Color(1, 1, 1, 0.65), HORIZONTAL_ALIGNMENT_CENTER, w, 3)
	UiStyle.big_button(self, confirm_yes_rect(), "GE UPP", _t, true)
	var no := confirm_no_rect()
	draw_rect(no, Color(0, 0, 0, 0.7))
	draw_rect(no, Color(UiStyle.GOLD, 0.9), false, 2.0)
	UiStyle.text(self, no.position + Vector2(0, no.size.y / 2 + 8), "FORTSÄTT STRIDEN", 21, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER, no.size.x, 4)


func _gui_input(event: InputEvent) -> void:
	if mode == "confirm" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		accept_event()
		if confirm_yes_rect().has_point(event.position):
			mode = ""
			forfeit_answered.emit(true)
		elif confirm_no_rect().has_point(event.position) or not Rect2(size.x / 2 - 330, size.y / 2 - 120, 660, 250).has_point(event.position):
			mode = ""
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			forfeit_answered.emit(false)
		return
	if mode == "confirm":
		accept_event()
		return
	if mode in ["victory", "defeat"] and _big_t > 1.0 and event is InputEventMouseButton and event.pressed:
		accept_event()
		for i in alternatives:
			if _decider_rect(i).has_point(event.position):
				alt_open = -1 if alt_open == i else i
				queue_redraw()
				return
		if alt_open >= 0:
			alt_open = -1  # ett tryck utanför stänger listan först
			queue_redraw()
			return
		restart_requested.emit()


func _process(delta: float) -> void:
	_t += delta
	_big_t += delta
	_announce_t = maxf(0.0, _announce_t - delta)
	_message_t = maxf(0.0, _message_t - delta)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if mode == "confirm":
		_draw_confirm(w, h)
		return
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
		_draw_deciders(w, h, a)  # före rubriken, så att plattan inte täcker den
		draw_set_transform(Vector2(w / 2, h * 0.45), 0, Vector2.ONE * pop)
		UiStyle.text(self, Vector2(-w / 2, 0), big_text, 72, Color(col, a), HORIZONTAL_ALIGNMENT_CENTER, w, 10)
		draw_set_transform(Vector2.ZERO)
		if sub_text != "":
			UiStyle.text(self, Vector2(0, h * 0.45 + 50), sub_text, 22, Color(1, 1, 1, 0.85 * a),
					HORIZONTAL_ALIGNMENT_CENTER, w, 5)
		for i in lines.size():
			UiStyle.text(self, Vector2(0, h * 0.45 + 90 + i * 26), lines[i], 18, Color(UiStyle.TRAIT_GOLD, a),
					HORIZONTAL_ALIGNMENT_CENTER, w, 5)
		_draw_level_ups(w, h, a)
		_draw_finds(w, h, a)
		if alt_open >= 0 and alternatives.has(alt_open):
			_draw_alternatives(h, a)  # sist, ovanpå rubriken
		if mode in ["victory", "defeat"] and _big_t > 1.0:
			var blink := 0.6 + 0.4 * sin(_t * 4.0)
			UiStyle.text(self, Vector2(0, h - 16), "Tryck för att fortsätta", 20, Color(1, 1, 1, blink),
					HORIZONTAL_ALIGNMENT_CENTER, w, 5)
	if _announce_t > 0.0:
		var a := minf(1.0, _announce_t)
		var pop := 1.0 + 0.3 * maxf(0.0, (_announce_t - 2.8) / 0.2)
		draw_set_transform(Vector2(w / 2, 150), 0, Vector2.ONE * pop)
		UiStyle.text(self, Vector2(-w / 2, 0), _announce, 30, Color(1, 0.55, 0.2, a), HORIZONTAL_ALIGNMENT_CENTER, w, 6)
		draw_set_transform(Vector2.ZERO)
	if rules_text != "":
		# Till vänster om knappkolumnen (SKADELOGG, MAKRON, LJUD), så att raden inte ritas ovanpå dem.
		UiStyle.text(self, Vector2(0, 92), UiStyle.fit(rules_text, 16, w * 0.45), 16, Color(UiStyle.TRAIT_GOLD, 0.9),
				HORIZONTAL_ALIGNMENT_RIGHT, w - 170, 4)
	if inspect_title != "":
		var bw := minf(w - 40.0, 760.0)
		var r := Rect2((w - bw) / 2.0, 70, bw, 70 + inspect_lines.size() * 46)
		draw_rect(r, Color(0.03, 0.025, 0.05, 0.94))
		draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
		UiStyle.text(self, r.position + Vector2(0, 38), inspect_title, 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, bw, 5)
		for i in inspect_lines.size():
			var font := UiStyle.bold()
			var pos := r.position + Vector2(20, 76 + i * 46)
			if inspect_lines[i].begins_with(LESSON_MARK):  # en troféns lärdom: kursiv och dämpad
				UiStyle.lesson(self, pos, inspect_lines[i].trim_prefix(LESSON_MARK), bw - 40, 2)
				continue
			draw_multiline_string(font, pos, inspect_lines[i], HORIZONTAL_ALIGNMENT_LEFT, bw - 40, 17, 2, Color(1, 1, 1, 0.9))
	if calc_title != "":
		_draw_calc(w)
	if _message_t > 0.0:
		UiStyle.text(self, Vector2(0, h - 150), _message, 20, Color(1, 0.35, 0.3, minf(1.0, _message_t * 2.0)),
				HORIZONTAL_ALIGNMENT_CENTER, w, 5)
