class_name PartyFrame
extends Control
## Raidram för en hjälte. Tryck på ramen för att kasta Flash Heal på just den hjälten.

signal tapped(unit_id: String)

const AURA_PIPS := {"shield_wall": Color("#9fb4d8"), "renew": Color("#5dff73"), "bloodlust": Color("#ff5a2a")}

var unit: CombatUnit
var _ghost := 1.0
var _ghost_hold := 0.0
var _hit_flash := 0.0
var _heal_flash := 0.0
var _press := 0.0
var _t := 0.0


func setup(u: CombatUnit) -> void:
	unit = u
	size = Vector2(236, 66)
	mouse_filter = Control.MOUSE_FILTER_STOP


func on_damage(amount: float) -> void:
	_hit_flash = clampf(amount / (unit.max_hp * 0.25), 0.4, 1.0)
	_ghost_hold = 0.35


func on_heal() -> void:
	_heal_flash = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press = 1.0
		tapped.emit(unit.id)
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
	_heal_flash = maxf(0.0, _heal_flash - delta * 3.0)
	_press = maxf(0.0, _press - delta * 6.0)
	var pct := unit.hp_pct()
	if pct >= _ghost:
		_ghost = pct
	elif _ghost_hold > 0.0:
		_ghost_hold -= delta
	else:
		_ghost = maxf(pct, _ghost - delta * 0.6)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-2.0 * _press)
	draw_rect(r, UiStyle.PANEL)
	var border := Color(unit.color, 0.5)
	if unit.alive and unit.hp_pct() < 0.35:
		border = Color(1, 0.2, 0.15, 0.6 + 0.4 * sin(_t * 10.0))
	draw_rect(r, border, false, 2.0)

	UiStyle.text(self, Vector2(10, 21), unit.name, 17, unit.color)
	var hp_text := "DÖD" if not unit.alive else str(int(unit.hp))
	UiStyle.text(self, Vector2(10, 21), hp_text, 15, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 20)

	var px := 10.0 + UiStyle.bold().get_string_size(unit.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 8.0
	for aura_id in AURA_PIPS:
		if unit.auras.has(aura_id):
			draw_rect(Rect2(px, 9, 12, 12), AURA_PIPS[aura_id])
			draw_rect(Rect2(px, 9, 12, 12), Color(0, 0, 0, 0.8), false, 1.0)
			px += 15.0

	var hp_rect := Rect2(10, 28, size.x - 20, 20)
	UiStyle.bar(self, hp_rect, unit.hp_pct(), UiStyle.HP_GREEN, _ghost)
	if _hit_flash > 0.0:
		draw_rect(hp_rect, Color(1, 0.2, 0.1, 0.45 * _hit_flash))
	if _heal_flash > 0.0:
		draw_rect(hp_rect, Color(0.5, 1, 0.5, 0.35 * _heal_flash))

	if unit.max_mana > 0.0:
		UiStyle.bar(self, Rect2(10, 51, size.x - 20, 6), unit.mana / unit.max_mana, UiStyle.MANA_BLUE)
	if unit.is_casting():
		UiStyle.bar(self, Rect2(10, 59, size.x - 20, 4), unit.cast_progress(), UiStyle.GOLD)

	if not unit.alive:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
