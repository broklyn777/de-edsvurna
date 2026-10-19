extends Control
## Lägret mellan striderna: välj en trofé, fördela troféerna fritt mellan hjältarna och se vad
## nästa strid har att bjuda på. Allt reagerar när fingret släpps.

const MARGIN := 28.0
const GAP := 14.0

var chosen := ""
var selected := ""
## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
@onready var run: Node = get_node("/root/Run")
var _t := 0.0
var _press_at := Vector2(-1, -1)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not run.offer.is_empty():
		chosen = run.camp_chosen if run.offer.has(run.camp_chosen) else run.offer[0]
		run.camp_chosen = chosen
		selected = chosen


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if event.pressed:
		_press_at = event.position
		return
	if _press_at.distance_to(event.position) > 30.0:
		return
	_tap(event.position)


func _tap(p: Vector2) -> void:
	var state: RunState = run.state
	for i in run.offer.size():
		if _offer_rect(i).has_point(p):
			var old := chosen
			chosen = run.offer[i]
			run.camp_chosen = chosen
			# Byter man val flyttas den tidigare valda troféns plats till den nya.
			var w := state.wearer(old)
			if w != "":
				state.equip(w, "")
			selected = chosen
			return
	var inv := _inventory()
	for i in inv.size():
		if _chip_rect(i).has_point(p):
			selected = "" if selected == inv[i] else inv[i]
			return
	for i in state.party.size():
		if _hero_rect(i).has_point(p):
			var hero_id := state.party[i]
			if selected != "":
				state.equip(hero_id, selected)
				selected = ""
			else:
				state.equip(hero_id, "")
			return
	if _macro_rect().has_point(p):
		run.open_macros(run.CAMP_SCENE)
		return
	if _button_rect().has_point(p):
		if chosen != "":
			state.take_trophy(chosen)
		run.next_floor()


## Troféer att fördela: de hittade plus den nyss valda.
func _inventory() -> Array[String]:
	var out: Array[String] = run.state.trophies.duplicate()
	if chosen != "" and not out.has(chosen):
		out.append(chosen)
	return out


# --- Layout -----------------------------------------------------------------

func _offer_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 2) / 3.0
	return Rect2(MARGIN + i * (w + GAP), 150, w, 120)


func _chip_rect(i: int) -> Rect2:
	return Rect2(MARGIN + i * 230, 318, 220, 40)


func _hero_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 3) / 4.0
	return Rect2(MARGIN + i * (w + GAP), 396, w, 116)


func _button_rect() -> Rect2:
	return Rect2(size.x - 340 - MARGIN, size.y - 76, 340, 60)


func _macro_rect() -> Rect2:
	return Rect2(size.x - 340 - MARGIN - 220, size.y - 70, 200, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var state: RunState = run.state
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.06))
	UiStyle.text(self, Vector2(0, 44), "SEGER! VÄLJ EN TROFÉ", 34, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	for i in run.last_receipt.size():
		UiStyle.text(self, Vector2(0, 76 + i * 20), run.last_receipt[i], 15, Color(1, 1, 1, 0.75),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)

	for i in run.offer.size():
		var t: Dictionary = data.traits[run.offer[i]]
		UiStyle.card(self, _offer_rect(i), t.name, t.text, chosen == run.offer[i], UiStyle.TRAIT_GOLD,
				"FRÅN " + _source_name(run.offer[i]).to_upper())

	UiStyle.text(self, Vector2(MARGIN, 306), "DINA TROFÉER – TRYCK PÅ EN TROFÉ OCH SEDAN PÅ EN HJÄLTE", 14, Color(1, 1, 1, 0.6))
	var inv := _inventory()
	for i in inv.size():
		var r := _chip_rect(i)
		var on := selected == inv[i]
		draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else Color(0, 0, 0, 0.6))
		draw_rect(r, Color(UiStyle.GOLD, 0.6 + 0.4 * sin(_t * 8.0)) if on else Color(UiStyle.TRAIT_GOLD, 0.4), false, 2.0)
		UiStyle.text(self, r.position + Vector2(10, 26), data.traits[inv[i]].name, 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 3)

	for i in state.party.size():
		var hero_id := state.party[i]
		var h: Dictionary = data.heroes[hero_id]
		var trophy: String = state.equipped.get(hero_id, "")
		var own: String = state.oath if hero_id == "paladin" else h.traits[0]
		var body := "%s\nTrofé: %s" % [data.traits[own].name, data.traits[trophy].name if trophy != "" else "–"]
		UiStyle.card(self, _hero_rect(i), h.name, body, trophy != "", Color(h.color), h.title.to_upper())

	var next_id: String = state.floor_ids[state.floor + 1]
	var enc: Dictionary = data.encounters[next_id]
	var names := {}
	var boss_text := ""
	for kind in enc.enemies:
		names[data.enemies[kind].name] = names.get(data.enemies[kind].name, 0) + 1
		boss_text = data.enemies[kind].get("boss_text", boss_text)
	var parts: Array[String] = []
	for n in names:
		parts.append(n if names[n] == 1 else "%s ×%d" % [n, names[n]])
	UiStyle.text(self, Vector2(MARGIN, size.y - 112), "NÄSTA: " + enc.name.to_upper(), 18, Color("#ff8a6a"))
	var known: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var unknown := state.active_rules().size() - known.size()
	if not state.active_rules().is_empty():
		var rule_line := "REGLER: " + ", ".join(known) + ("" if unknown == 0 else "%s%d dolda" % [", " if not known.is_empty() else "", unknown])
		UiStyle.text(self, Vector2(MARGIN, size.y - 136), rule_line, 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 420)
	UiStyle.text(self, Vector2(MARGIN, size.y - 88), ", ".join(parts), 15, Color(1, 1, 1, 0.8))
	if boss_text != "":
		UiStyle.text(self, Vector2(MARGIN, size.y - 64), boss_text, 15, Color("#ffb347"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 420)
	UiStyle.big_button(self, _button_rect(), "VIDARE", _t)
	var m := _macro_rect()
	draw_rect(m, Color(0, 0, 0, 0.6))
	draw_rect(m, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(self, m.position + Vector2(0, m.size.y / 2 + 8), "MAKRON", 20, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, 4)


func _source_name(trophy_id: String) -> String:
	for kind in run.data.enemies:
		if run.data.enemies[kind].get("trophy", "") == trophy_id:
			return run.data.enemies[kind].name
	return ""
