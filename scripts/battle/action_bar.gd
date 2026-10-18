class_name ActionBar
extends Control
## Handlingsknapparna för hjälten som har turen: Anfall, signaturförmågan och Försvara.
## Ett tryck väljer handlingen; om den behöver ett mål väljer spelaren det sedan i scenen
## (eller trycker på samma knapp igen för det förvalda målet).

signal chosen(action: String)

const RADIUS := 50.0
const GAP := 16.0

var sim: CombatSim
var unit: CombatUnit
var selected := ""
var _press := {}
var _shake := {}
var _t := 0.0


func setup(s: CombatSim) -> void:
	sim = s
	size = Vector2(CombatSim.ACTIONS.size() * (RADIUS * 2 + GAP), RADIUS * 2 + 70)
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_for(u: CombatUnit) -> void:
	unit = u
	selected = ""
	visible = true


func refuse(action: String) -> void:
	_shake[action] = 1.0


func _center(i: int) -> Vector2:
	return Vector2(RADIUS + i * (RADIUS * 2 + GAP), size.y - RADIUS - 4)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for i in CombatSim.ACTIONS.size():
		if event.position.distance_to(_center(i)) <= RADIUS + 6:
			var action: String = CombatSim.ACTIONS[i]
			_press[action] = 1.0
			accept_event()
			chosen.emit(action)
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
	var shown := selected if selected != "" else "signature"
	var info := sim.ability(sim.action_ability(unit, shown))
	var label := "%s – %s" % [info.name, info.get("text", "Anfall det valda målet.")]
	UiStyle.text(self, Vector2(0, 20), unit.name.to_upper() + "S TUR", 18, unit.color, HORIZONTAL_ALIGNMENT_RIGHT, size.x, 5)
	UiStyle.text(self, Vector2(-200, 42), label, 14, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, size.x + 200, 4)
	for i in CombatSim.ACTIONS.size():
		_draw_button(i, CombatSim.ACTIONS[i])


func _draw_button(i: int, action: String) -> void:
	var ability_id := sim.action_ability(unit, action)
	var ab := sim.ability(ability_id)
	var c: Vector2 = _center(i) + Vector2(sin(_t * 70.0) * 7.0 * _shake.get(action, 0.0), 0)
	var r: float = RADIUS * (1.0 - 0.09 * _press.get(action, 0.0))
	var col := Color(ab.get("button_color", "#a05a3a" if action == "attack" else "#888888"))
	var cd := unit.cooldown_left(ability_id)
	if action == selected:
		var p := 0.5 + 0.5 * sin(_t * 10.0)
		draw_circle(c, r + 8 + 4 * p, Color(UiStyle.GOLD, 0.3 + 0.25 * p))
	draw_circle(c, r + 3, Color(0, 0, 0, 0.75))
	draw_circle(c, r, col.darkened(0.62))
	draw_circle(c + Vector2(0, -r * 0.08), r * 0.88, col.darkened(0.35))
	var icon: String = ab.get("icon", "daggers" if action == "attack" else "diamond")
	Glyphs.draw(self, icon, c + Vector2(0, -10), r * 0.42, col.lightened(0.35))
	var label: String = "Anfall" if action == "attack" else ab.name
	UiStyle.text(self, Vector2(c.x - r - 10, c.y + r * 0.55), label, 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2 + 20, 4)
	draw_arc(c, r + 1, 0, TAU, 48, Color(UiStyle.GOLD if action == selected else col.lightened(0.2), 0.9), 3.0 if action == selected else 2.0, true)
	if cd > 0.0:
		draw_circle(c, r, Color(0, 0, 0, 0.62))
		UiStyle.text(self, Vector2(c.x - r, c.y + 12), str(int(cd)), 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2, 6)
	var charge := sim.charge_info(unit, ability_id)
	if not charge.is_empty() and charge.max > 0.0 and charge.max <= 10.0:
		var n := int(charge.max)
		for k in n:
			var a := -PI / 2 + (k - (n - 1) / 2.0) * 0.32
			var p: Vector2 = c + Vector2(cos(a), sin(a)) * (r + 13)
			draw_circle(p, 6.0, Color(0, 0, 0, 0.8))
			draw_circle(p, 4.5, UiStyle.TRAIT_GOLD if k < int(charge.value) else Color(1, 1, 1, 0.15))
