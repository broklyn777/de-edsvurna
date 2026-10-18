class_name TraitPicker
extends Control
## Valskärm före striden i två steg:
##   1. varje hjälte väljer en av sina klassegenskaper
##   2. artefakter fördelas – varje artefakt kan bara bäras av en hjälte

signal confirmed(traits: Dictionary, artifacts: Dictionary)
signal tapped

const MARGIN := 28.0
const GAP := 14.0
const CARD_GAP := 10.0
const BUTTON_SIZE := Vector2(320, 62)
const BACK_SIZE := Vector2(170, 52)
const ARTIFACT_COLUMNS := 4

var data: Dictionary
var party: Array = []
var artifact_ids: Array[String] = []
## hero_id -> trait_id
var traits := {}
## hero_id -> trait_id (artefakt) eller saknas
var artifacts := {}
var step := 1
var _active := 0  # hjälten som nästa artefakt hamnar på (steg 2)
var _t := 0.0
var _flash := {}  # id -> 1..0, kort glimt när något väljs
var _button_press := 0.0


func setup(game_data: Dictionary, hero_ids: Array, initial_traits: Dictionary, initial_artifacts: Dictionary) -> void:
	data = game_data
	party = hero_ids
	for trait_id in data.traits:
		if data.traits[trait_id].get("artifact", false):
			artifact_ids.append(trait_id)
	for hero_id in party:
		var options: Array = data.heroes[hero_id].get("trait_options", [])
		traits[hero_id] = initial_traits.get(hero_id, "") if initial_traits.get(hero_id, "") in options else options[0]
		var art: String = initial_artifacts.get(hero_id, "")
		if art in artifact_ids and not artifacts.values().has(art):
			artifacts[hero_id] = art
	_active = _next_without_artifact(0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	_button_press = maxf(0.0, _button_press - delta * 6.0)
	for k in _flash.keys():
		_flash[k] = maxf(0.0, _flash[k] - delta * 3.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	var p: Vector2 = event.position
	if _button_rect().has_point(p):
		_button_press = 1.0
		tapped.emit()
		_advance()
		return
	if step == 2 and _back_rect().has_point(p):
		tapped.emit()
		step = 1
		return
	if step == 1:
		_tap_trait(p)
	else:
		_tap_artifact_step(p)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_advance()


func _advance() -> void:
	if step == 1:
		step = 2
	else:
		confirmed.emit(traits, artifacts)


func _tap_trait(p: Vector2) -> void:
	for i in party.size():
		var options: Array = data.heroes[party[i]].trait_options
		for j in options.size():
			if _card_rect(i, j).has_point(p):
				traits[party[i]] = options[j]
				_flash[options[j]] = 1.0
				tapped.emit()
				return


func _tap_artifact_step(p: Vector2) -> void:
	for i in party.size():
		if _slot_rect(i).has_point(p):
			_active = i
			tapped.emit()
			return
	for k in artifact_ids.size():
		if not _artifact_rect(k).has_point(p):
			continue
		var art := artifact_ids[k]
		var hero_id: String = party[_active]
		if artifacts.get(hero_id, "") == art:
			artifacts.erase(hero_id)
		else:
			for other in artifacts.keys():
				if artifacts[other] == art:
					artifacts.erase(other)
			artifacts[hero_id] = art
			_flash[art] = 1.0
			_active = _next_without_artifact(_active)
		tapped.emit()
		return


func _next_without_artifact(from: int) -> int:
	for n in party.size():
		var i := (from + n) % party.size()
		if not artifacts.has(party[i]):
			return i
	return from


# --- Layout -----------------------------------------------------------------

func _column_width() -> float:
	return (size.x - MARGIN * 2 - GAP * (party.size() - 1)) / party.size()


func _card_height() -> float:
	return clampf((size.y - 150.0 - 110.0 - CARD_GAP * 2) / 3.0, 96.0, 150.0)


func _card_rect(i: int, j: int) -> Rect2:
	var w := _column_width()
	var h := _card_height()
	return Rect2(MARGIN + i * (w + GAP), 150.0 + j * (h + CARD_GAP), w, h)


func _slot_rect(i: int) -> Rect2:
	var w := _column_width()
	return Rect2(MARGIN + i * (w + GAP), 108.0, w, 70.0)


func _artifact_rect(k: int) -> Rect2:
	var rows := ceili(float(artifact_ids.size()) / ARTIFACT_COLUMNS)
	var top := 198.0
	var h := clampf((_button_rect().position.y - 18.0 - top - CARD_GAP * (rows - 1)) / rows, 90.0, 150.0)
	var w := (size.x - MARGIN * 2 - GAP * (ARTIFACT_COLUMNS - 1)) / ARTIFACT_COLUMNS
	var col := k % ARTIFACT_COLUMNS
	var row := k / ARTIFACT_COLUMNS
	return Rect2(MARGIN + col * (w + GAP), top + row * (h + CARD_GAP), w, h)


func _button_rect() -> Rect2:
	var top := minf(150.0 + 3 * (_card_height() + CARD_GAP) + 12.0, size.y - BUTTON_SIZE.y - 14.0)
	return Rect2((size.x - BUTTON_SIZE.x) / 2.0, top, BUTTON_SIZE.x, BUTTON_SIZE.y)


func _back_rect() -> Rect2:
	var b := _button_rect()
	return Rect2(MARGIN, b.position.y + (b.size.y - BACK_SIZE.y) / 2.0, BACK_SIZE.x, BACK_SIZE.y)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.9))
	if step == 1:
		_draw_header("VÄLJ EGENSKAPER", "En per hjälte. Leta efter egenskaper som sätter igång varandra.")
		for i in party.size():
			var hero_id: String = party[i]
			var hero: Dictionary = data.heroes[hero_id]
			var color := Color(hero.get("color", "#ffffff"))
			var col_x := _card_rect(i, 0).position.x
			Glyphs.draw(self, UiStyle.GLYPHS.get(hero_id, "diamond"), Vector2(col_x + 14, 128), 9.0, color)
			UiStyle.text(self, Vector2(col_x + 30, 136), hero.get("name", hero_id), 22, color, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
			var options: Array = hero.trait_options
			for j in options.size():
				_draw_card(_card_rect(i, j), options[j], traits[hero_id] == options[j], color)
		_draw_button("NÄSTA: ARTEFAKTER")
	else:
		_draw_header("VÄLJ ARTEFAKTER", "Tryck på en hjälte och sedan på en artefakt. Varje artefakt kan bara bäras av en.")
		for i in party.size():
			_draw_slot(i)
		for k in artifact_ids.size():
			var art := artifact_ids[k]
			var owner := _owner_of(art)
			var color := Color(data.heroes[owner].color) if owner != "" else Color(1, 1, 1, 0.3)
			_draw_card(_artifact_rect(k), art, owner != "", color)
			if owner != "":
				var r := _artifact_rect(k)
				UiStyle.text(self, r.position + Vector2(0, 28), data.heroes[owner].name, 15, color,
						HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 12, 3)
		_draw_button("TILL STRID")
		var back := _back_rect()
		draw_rect(back, Color(0.1, 0.1, 0.14, 0.95))
		draw_rect(back, Color(1, 1, 1, 0.35), false, 2.0)
		UiStyle.text(self, back.position + Vector2(0, back.size.y / 2 + 7), "TILLBAKA", 19, Color(1, 1, 1, 0.8),
				HORIZONTAL_ALIGNMENT_CENTER, back.size.x, 4)


func _draw_header(title: String, sub: String) -> void:
	UiStyle.text(self, Vector2(0, 54), title, 36, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	UiStyle.text(self, Vector2(0, 84), sub, 17, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


func _draw_button(label: String) -> void:
	var b := _button_rect().grow(-3.0 * _button_press)
	var pulse := 0.85 + 0.15 * sin(_t * 4.0)
	draw_rect(b, Color(0.55, 0.12, 0.08, 0.95))
	draw_rect(b, Color(UiStyle.GOLD, pulse), false, 3.0)
	UiStyle.text(self, b.position + Vector2(0, b.size.y / 2 + 10), label, 26, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER, b.size.x, 6)


func _draw_slot(i: int) -> void:
	var hero_id: String = party[i]
	var hero: Dictionary = data.heroes[hero_id]
	var color := Color(hero.get("color", "#ffffff"))
	var r := _slot_rect(i)
	var active := i == _active
	draw_rect(r, Color(0.09, 0.08, 0.12, 0.96))
	if active:
		draw_rect(r, Color(UiStyle.GOLD, 0.7 + 0.3 * sin(_t * 6.0)), false, 3.0)
	else:
		draw_rect(r, Color(color, 0.35), false, 1.5)
	Glyphs.draw(self, UiStyle.GLYPHS.get(hero_id, "diamond"), r.position + Vector2(18, 22), 8.0, color)
	UiStyle.text(self, r.position + Vector2(34, 30), hero.get("name", hero_id), 20, color, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
	var art: String = artifacts.get(hero_id, "")
	var label: String = data.traits[art].name if art != "" else "– ingen artefakt –"
	UiStyle.text(self, r.position + Vector2(14, 56), label, 16,
			UiStyle.TRAIT_GOLD if art != "" else Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 3)


func _draw_card(r: Rect2, trait_id: String, selected: bool, accent: Color) -> void:
	var t: Dictionary = data.traits[trait_id]
	var flash: float = _flash.get(trait_id, 0.0)
	draw_rect(r, Color(0.09, 0.08, 0.12, 0.96) if selected else Color(0.06, 0.055, 0.08, 0.85))
	if flash > 0.0:
		draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.3 * flash))
	if selected:
		draw_rect(r, UiStyle.TRAIT_GOLD, false, 3.0)
		draw_rect(Rect2(r.position, Vector2(6, r.size.y)), UiStyle.TRAIT_GOLD)
	else:
		draw_rect(r, Color(accent, 0.25), false, 1.5)
	var a := 1.0 if selected else 0.6
	UiStyle.text(self, r.position + Vector2(16, 28), t.name, 19, Color(UiStyle.TRAIT_GOLD, a), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
	var lines := int((r.size.y - 40.0) / 20.0)
	draw_multiline_string(UiStyle.bold(), r.position + Vector2(16, 52), t.text, HORIZONTAL_ALIGNMENT_LEFT,
			r.size.x - 28, 16, lines, Color(1, 1, 1, 0.9 if selected else 0.55))


func _owner_of(art: String) -> String:
	for hero_id in artifacts:
		if artifacts[hero_id] == art:
			return hero_id
	return ""
