extends TapScreen
## Krönikan och titlarna hos Broder Alrik (Chronicle): de senaste nedstigningarna som korta rader i tusch på pergament
## till vänster, titlarna till höger. Ett tryck på en förtjänad titel bär den (ett tryck till tar av den); en titel som
## inte är förtjänad visar vad som krävs.

const HEAD_H := 22.0
const LINE_H := 19.0
const ROW_GAP := 9.0
const TOP := 124.0
## Titeln vars text visas längst ned till höger.
var _focus := ""


func _ready() -> void:
	super()
	add_child(Parchment.new())
	Chronicle.unlock_titles(run.profile, run.data)  # profiler från före krönikan: titlar som redan är förtjänade
	_focus = run.profile.title
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--title-focus="):
			_focus = arg.get_slice("=", 1)  # för skärmdumpar


func _split() -> float:
	return roundf(size.x * 0.62)


func _title_rect(i: int) -> Rect2:
	var n := maxi(Chronicle.title_ids(run.data).size(), 1)
	var step := minf(36.0, (size.y - TOP - 56.0) / n)
	var x := _split() + 24.0
	return Rect2(x, TOP + i * step, size.x - MARGIN - x, step - 4)


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var ids := Chronicle.title_ids(run.data)
	for i in ids.size():
		if _title_rect(i).has_point(p):
			var id: String = ids[i]
			_focus = id
			if run.profile.titles.has(id):
				Chronicle.choose_title(run.profile, "" if run.profile.title == id else id)
				run.save("ui_page")
			else:
				run.ui("ui_error", -16.0)
			return


func _draw() -> void:
	var data: Dictionary = run.data
	var prof: Profile = run.profile
	var ink := InkArt.INK
	small_button(back_rect(), "‹ BORGEN")
	InkArt.cartouche(self, Rect2(size.x / 2 - 200, 16, 400, 46), "KRÖNIKAN", ink, 24)
	var who := prof.hero_name
	if prof.title != "":
		who += ", " + Chronicle.title_name(data, prof.title)
	UiStyle.text(self, Vector2(0, 88), who, 18, Color(ink, 0.8), HORIZONTAL_ALIGNMENT_CENTER, size.x, 0)

	# Nedstigningarna, nyast först.
	var left := MARGIN + 8
	var w := _split() - left
	UiStyle.text(self, Vector2(left, TOP - 10), "DE SENASTE NEDSTIGNINGARNA", 15, Parchment.INK_LIGHT)
	var list := Chronicle.recent(prof)
	if list.is_empty():
		UiStyle.para(self, Vector2(left, TOP + 30), "Krönikan är tom än. Broder Alrik väntar med pennan.", 18, Color(ink, 0.8), w)
	var bodies: Array = list.map(func(e: Dictionary) -> String: return Chronicle.entry_body(prof, data, e))
	var rows := _row_lines(bodies, w - 40)
	var y := TOP + 4
	for i in list.size():
		var e: Dictionary = list[i]
		_glyph(String(e.get("outcome", "")), Vector2(left + 12, y + 12), Color(ink, 0.85))
		UiStyle.text(self, Vector2(left + 32, y + 18), UiStyle.fit(Chronicle.entry_head(data, e), 17, w - 40), 17, ink)
		UiStyle.para(self, Vector2(left + 32, y + 37), bodies[i], 15, Color(ink, 0.78), w - 40, rows[i])
		y += HEAD_H + LINE_H * rows[i] + ROW_GAP
		if i < list.size() - 1:
			InkArt.path(self, Vector2(left + 32, y - ROW_GAP / 2.0), Vector2(left + w - 20, y - ROW_GAP / 2.0), Color(ink, 0.18), true, 1.0)
	draw_line(Vector2(_split() + 8, TOP - 24), Vector2(_split() + 8, size.y - 24), Color(ink, 0.3), 1.5)

	# Titlarna.
	var ids := Chronicle.title_ids(data)
	var tx := _split() + 24.0
	UiStyle.text(self, Vector2(tx, TOP - 10), "TITLAR %d / %d – TRYCK FÖR ATT BÄRA" % [prof.titles.size(), ids.size()], 15,
			Parchment.INK_LIGHT, HORIZONTAL_ALIGNMENT_LEFT, size.x - MARGIN - tx)
	for i in ids.size():
		var id: String = ids[i]
		var r := _title_rect(i)
		var have: bool = prof.titles.has(id)
		var worn := prof.title == id
		if worn:
			draw_rect(r, Color(0.85, 0.66, 0.25, 0.35))
			draw_rect(r, Color(ink, 0.8), false, 2.0)
		elif id == _focus:
			draw_rect(r, Color(ink, 0.5), false, 1.2)
		var name := Chronicle.title_name(data, id) if have else "· · ·  " + Chronicle.title_name(data, id)
		UiStyle.text(self, r.position + Vector2(12, r.size.y / 2 + 6), UiStyle.fit(name, 17, r.size.x - 70), 17,
				ink if have else Color(ink, 0.32))
		if worn:
			UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + 6), "BÄRS", 15, ink, HORIZONTAL_ALIGNMENT_RIGHT,
					r.size.x - 10)
	if _focus != "" and data.titles.has(_focus):
		var t: Dictionary = data.titles[_focus]
		var how := String(t.get("text", ""))
		if prof.titles.has(_focus):
			how += " Tryck igen för att ta av den." if prof.title == _focus else " Tryck för att bära den."
		else:
			how = "Inte förtjänad än: " + how
		UiStyle.para(self, Vector2(tx, size.y - 44), how, 15, Color(ink, 0.85), size.x - MARGIN - tx, 2)


## Hur många rader varje post får (högst två); blir det för högt får de äldsta en rad (med "…").
func _row_lines(bodies: Array, width: float) -> Array:
	var f := UiStyle.bold()
	var rows: Array = bodies.map(func(b: String) -> int:
			return clampi(roundi(f.get_multiline_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, width, 15).y / f.get_height(15)), 1, 2))
	var avail := size.y - TOP - 20.0
	var i := rows.size() - 1
	while i >= 0 and _rows_height(rows) > avail:
		rows[i] = 1
		i -= 1
	return rows


func _rows_height(rows: Array) -> float:
	var h := 0.0
	for r in rows:
		h += HEAD_H + LINE_H * int(r) + ROW_GAP
	return h


## En liten tuschsymbol för utfallet.
func _glyph(outcome: String, c: Vector2, color: Color) -> void:
	match outcome:
		"boss":
			InkArt.crossed_swords(self, c, 18.0, color)
		"home":
			InkArt.campfire(self, c, 18.0, color)
		_:
			InkArt.skull(self, c, 16.0, color)
