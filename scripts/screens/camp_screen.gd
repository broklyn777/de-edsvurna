extends Control
## Lägret mellan striderna: välj en trofé, fördela troféerna fritt mellan hjältarna och se vad
## nästa strid har att bjuda på. Allt reagerar när fingret släpps.

## Nattlägret tonat i bakgrunden.
const NIGHT_CAMP := preload("res://assets/illustrations/nattlagret.webp")
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
	run.base_music()
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
	run.ui_tap()


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
		if _sheet_rect(i).has_point(p):
			run.open_sheet(state.party[i], Array(state.party), run.CAMP_SCENE)
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
		run.after_camp()


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


## Knappen till hjältebladet nere till höger i hjältens kort.
func _sheet_rect(i: int) -> Rect2:
	var r := _hero_rect(i)
	return Rect2(r.end.x - 78, r.end.y - 36, 70, 30)


func _button_rect() -> Rect2:
	return Rect2(size.x - 340 - MARGIN, size.y - 76, 340, 60)


func _macro_rect() -> Rect2:
	return Rect2(size.x - 340 - MARGIN - 220, size.y - 70, 200, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var state: RunState = run.state
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.06))
	# Nattlägret (Drakvalvets illustration) svagt i bakgrunden.
	var bg_h := size.x * NIGHT_CAMP.get_height() / NIGHT_CAMP.get_width()
	draw_texture_rect(NIGHT_CAMP, Rect2(0, (size.y - bg_h) / 2, size.x, bg_h), false, Color(1, 1, 1, 0.13))
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
		var lv := int(run.profile.hero(data, hero_id).level)
		UiStyle.card(self, _hero_rect(i), "%s · nivå %d" % [h.name, lv], body, trophy != "", Color(h.color), h.title.to_upper(),
				0.0, 30.0)
		var sr := _sheet_rect(i)
		draw_rect(sr, Color(0, 0, 0, 0.7))
		draw_rect(sr, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
		UiStyle.text(self, sr.position + Vector2(0, 21), "BLAD", 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 3)

	# Vad som väntar: rumskartan med questen och reglerna (0.18).
	if state.map != null:
		InkArt.floor_markers(self, Vector2(size.x - 470, 44), state.floor, state.floor_ids.size(), UiStyle.GOLD, 18)
	var next := "TILLBAKA TILL RUMSKARTAN – VÅNING %d AV %d" % [state.floor + 1, state.floor_ids.size()]
	if state.floor_cleared():
		next = "KÖRNINGEN ÄR KLAR!" if state.is_last_floor() else "VÅNINGEN ÄR KLAR – VIDARE TILL VÅNING %d" % (state.floor + 2)
	UiStyle.text(self, Vector2(MARGIN, size.y - 112), next, 18, Color("#ff8a6a"))
	var known: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var unknown := state.active_rules().size() - known.size()
	if not state.active_rules().is_empty():
		var rule_line := "REGLER: " + ", ".join(known) + ("" if unknown == 0 else "%s%d dolda" % [", " if not known.is_empty() else "", unknown])
		UiStyle.text(self, Vector2(MARGIN, size.y - 136), rule_line, 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 420)
	UiStyle.text(self, Vector2(MARGIN, size.y - 88), RunState.quest_text(state.quest) + (" – KLAR!" if state.quest.get("done", false) else ""),
			15, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, size.x - 420)
	if not run.quest_reward.is_empty():
		UiStyle.text(self, Vector2(MARGIN, size.y - 64), "Questen klar: +%d silver%s" % [run.quest_reward.silver,
				" och en perk-poäng!" if run.quest_reward.point else ""], 15, Color("#ffb347"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 420)
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
