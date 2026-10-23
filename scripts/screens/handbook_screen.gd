extends TapScreen
## Broder Alriks handbok (0.25, docs/plan/0.25-berattelsen.md §3): alla hjälprutor att läsa igen. Rubrikerna till
## vänster, rutan till höger. De som ännu inte har visats står blekare, men går att läsa ändå.

const ROW_H := 40.0
var selected := ""


func _ready() -> void:
	super()
	var order := Help.order(run.data)
	selected = order[0] if not order.is_empty() else ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--help-entry="):
			selected = arg.get_slice("=", 1)  # utvecklarflagga för skärmdumpar: --handbook --help-entry=charges


func _row_rect(i: int) -> Rect2:
	# 0.30.17: raderna krymper så att alla ämnen ryms på skärmen.
	var step := minf(ROW_H + 4, (size.y - 84.0 - 10.0) / maxf(Help.order(run.data).size(), 1))
	return Rect2(MARGIN, 84 + i * step, 300, step - 4)


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var order := Help.order(run.data)
	for i in order.size():
		if _row_rect(i).has_point(p):
			selected = order[i]
			run.ui("ui_page", -14.0)
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	small_button(back_rect(), "‹ BORGEN")
	UiStyle.text(self, Vector2(0, 50), "BRODER ALRIKS HANDBOK", 24, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	var order := Help.order(run.data)
	for i in order.size():
		var id: String = order[i]
		var r := _row_rect(i)
		var on := id == selected
		var seen: bool = run.profile.help_seen.has(id)
		draw_rect(r, Color(0.08, 0.2, 0.1, 0.95) if on else Color(0, 0, 0, 0.5))
		draw_rect(r, Color(HelpBox.GREEN, 0.9 if on else 0.3), false, 2.0 if on else 1.0)
		UiStyle.text(self, r.position + Vector2(14, r.size.y / 2 + 7), String(Help.entry(run.data, id).get("title", id)), 17,
				Color.WHITE if seen or on else Color(1, 1, 1, 0.5))
	if selected != "":
		var x := _row_rect(0).end.x + 24
		var w := minf(size.x - x - MARGIN, HelpBox.W)
		var e := Help.entry(run.data, selected)
		HelpBox.draw_entry(self, Rect2(x, 84, w, minf(size.y - 110, HelpBox.content_height(e, w) + 24.0)), e)
