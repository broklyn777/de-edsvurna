class_name ActionBar
extends Control
## Handlingarna för hjälten som har turen: Anfall, Förmåga (öppnar hjältens förmågor), Försvara,
## Provocera och Makro. Ett tryck väljer; behöver handlingen ett mål väljer spelaren det sedan i
## scenen (eller trycker samma knapp igen för det förvalda målet).

## action: "attack", "ability", "defend", "provoke" eller "macro"; ability_id bara för "ability".
signal chosen(action: String, ability_id: String)

const MAIN := ["attack", "ability", "defend", "provoke", "macro"]
const RADIUS := 44.0
const GAP := 12.0
const ABILITY_SIZE := Vector2(150, 64)

var sim: CombatSim
var unit: CombatUnit
## Vald handling som väntar på mål ("attack", "defend" … eller ett ability_id).
var selected := ""
var abilities_open := false
var _press := {}
var _shake := {}
var _t := 0.0


func setup(s: CombatSim) -> void:
	sim = s
	size = Vector2(MAIN.size() * (RADIUS * 2 + GAP), RADIUS * 2 + 60 + ABILITY_SIZE.y + 12)
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_for(u: CombatUnit) -> void:
	unit = u
	selected = ""
	abilities_open = false
	visible = true


func refuse(key: String) -> void:
	_shake[key] = 1.0


func _center(i: int) -> Vector2:
	return Vector2(RADIUS + i * (RADIUS * 2 + GAP), size.y - RADIUS - 4)


func _ability_rect(i: int) -> Rect2:
	var n := unit.abilities.size()
	var total := n * ABILITY_SIZE.x + (n - 1) * GAP
	return Rect2(size.x - total + i * (ABILITY_SIZE.x + GAP), size.y - RADIUS * 2 - 24 - ABILITY_SIZE.y,
			ABILITY_SIZE.x, ABILITY_SIZE.y)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if abilities_open:
		for i in unit.abilities.size():
			if _ability_rect(i).has_point(event.position):
				var id: String = unit.abilities[i]
				_press[id] = 1.0
				accept_event()
				chosen.emit("ability", id)
				return
	for i in MAIN.size():
		if event.position.distance_to(_center(i)) <= RADIUS + 6:
			var action: String = MAIN[i]
			_press[action] = 1.0
			accept_event()
			if action == "ability":
				abilities_open = not abilities_open
				selected = ""
			else:
				abilities_open = false
				chosen.emit(action, "")
			return


func _process(delta: float) -> void:
	_t += delta
	for k in _press.keys():
		_press[k] = maxf(0.0, _press[k] - delta * 7.0)
	for k in _shake.keys():
		_shake[k] = maxf(0.0, _shake[k] - delta * 4.0)
	queue_redraw()


func _draw() -> void:
	if unit == null:
		return
	UiStyle.text(self, Vector2(-400, 18), unit.name.to_upper() + "S TUR", 18, unit.color, HORIZONTAL_ALIGNMENT_RIGHT, size.x + 400, 5)
	var info := _info_text()
	if info != "":
		UiStyle.text(self, Vector2(-500, 40), info, 17, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, size.x + 500, 4)
	if abilities_open:
		for i in unit.abilities.size():
			_draw_ability(i, unit.abilities[i])
	for i in MAIN.size():
		_draw_button(i, MAIN[i])


func _info_text() -> String:
	if selected != "" and data_has(selected):
		var ab := sim.ability(selected)
		return "%s – %s" % [ab.name, ab.get("text", "")]
	match selected:
		"attack":
			return "Anfall – välj ett mål."
	if abilities_open:
		return "Välj en förmåga. Siffran är Charges kvar för hela körningen."
	return ""


func data_has(id: String) -> bool:
	return sim.data.abilities.has(id) and unit.abilities.has(id)


func _draw_ability(i: int, ability_id: String) -> void:
	var ab := sim.ability(ability_id)
	var r := _ability_rect(i).grow(-3.0 * _press.get(ability_id, 0.0))
	r.position.x += sin(_t * 70.0) * 6.0 * _shake.get(ability_id, 0.0)
	var col := Color(ab.get("button_color", "#888888"))
	var left: int = unit.charges.get(ability_id, 0)
	var usable := left > 0
	var cost: Dictionary = ab.get("stack_cost", {})  # Befäl: kostar Glöd, inte Charges
	if not cost.is_empty():
		usable = sim.can_act(unit, "ability", ability_id) == ""
	draw_rect(r, Color(col.darkened(0.6), 0.95 if usable else 0.5))
	draw_rect(r, Color(UiStyle.GOLD, 0.9) if selected == ability_id else Color(col.lightened(0.2), 0.8), false, 2.5)
	Glyphs.draw(self, ab.get("icon", "diamond"), r.position + Vector2(20, r.size.y / 2), 10.0, col.lightened(0.35))
	UiStyle.text(self, r.position + Vector2(36, 26), ab.name, 17, Color.WHITE if usable else Color(1, 1, 1, 0.4),
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40, 3)
	var count := "%d / %d" % [left, sim.full_charges(ability_id)]
	if not cost.is_empty():
		count = "%d Glöd" % int(cost.n)
	UiStyle.text(self, r.position + Vector2(36, 50), count, 16,
			UiStyle.TRAIT_GOLD if usable else Color(1, 0.4, 0.3), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)


func _draw_button(i: int, action: String) -> void:
	var c: Vector2 = _center(i) + Vector2(sin(_t * 70.0) * 7.0 * _shake.get(action, 0.0), 0)
	var r: float = RADIUS * (1.0 - 0.09 * _press.get(action, 0.0))
	var ab: Dictionary = {}
	if action in ["defend", "provoke"]:
		ab = sim.ability(action)
	var col: Color
	var icon: String
	var label: String
	match action:
		"attack":
			col = Color("#a05a3a")
			icon = "daggers"
			label = "Anfall"
		"ability":
			col = Color("#5a6fd0")
			icon = "flame"
			label = "Förmåga"
		"macro":
			col = Color("#8a7a3a")
			icon = "diamond"
			label = "Makro"
		_:
			col = Color(ab.get("button_color", "#888888"))
			icon = ab.get("icon", "diamond")
			label = ab.name
	var lit := action == selected or (action == "ability" and abilities_open)
	if lit:
		var p := 0.5 + 0.5 * sin(_t * 10.0)
		draw_circle(c, r + 7 + 3 * p, Color(UiStyle.GOLD, 0.3 + 0.25 * p))
	draw_circle(c, r + 3, Color(0, 0, 0, 0.75))
	draw_circle(c, r, col.darkened(0.62))
	draw_circle(c + Vector2(0, -r * 0.08), r * 0.88, col.darkened(0.35))
	Glyphs.draw(self, icon, c + Vector2(0, -9), r * 0.42, col.lightened(0.35))
	UiStyle.text(self, Vector2(c.x - r - 10, c.y + r * 0.55), label, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2 + 20, 4)
	draw_arc(c, r + 1, 0, TAU, 48, Color(UiStyle.GOLD if lit else col.lightened(0.2), 0.9), 3.0 if lit else 2.0, true)
