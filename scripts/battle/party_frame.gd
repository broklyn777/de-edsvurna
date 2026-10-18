class_name PartyFrame
extends Control
## Ram för en hjälte i sällskapet: liv, egenskaper och tillstånd. Lyser när det är hjältens tur.
## Tryck på ramen för att välja hjälten som mål (t.ex. för en helning).

signal tapped(unit_id: String)

const AURA_PIPS := {"defend": Color("#9fb4d8"), "provoke": Color("#ff6a4a"), "warded": Color("#bcd2ff"), "inspired": Color("#ffd75e"),
		"blessing": Color("#fff2b0"), "marked": Color("#e9cf3f"), "burning": Color("#ff8a2a")}

var unit: CombatUnit
var sim: CombatSim
var active := false
var targetable := false
var _ghost := 1.0
var _ghost_hold := 0.0
var _hit_flash := 0.0
var _heal_flash := 0.0
var _trait_flash := 0.0
var _press := 0.0
var _t := 0.0


func setup(u: CombatUnit, s: CombatSim) -> void:
	unit = u
	sim = s
	size = Vector2(240, 88 if not u.artifact.is_empty() else 74)
	mouse_filter = Control.MOUSE_FILTER_STOP


func on_damage(amount: float) -> void:
	_hit_flash = clampf(amount / (unit.max_hp * 0.25), 0.4, 1.0)
	_ghost_hold = 0.35


func on_heal() -> void:
	_heal_flash = 1.0


func on_trait() -> void:
	_trait_flash = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press = 1.0
		tapped.emit(unit.id)
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
	_heal_flash = maxf(0.0, _heal_flash - delta * 3.0)
	_trait_flash = maxf(0.0, _trait_flash - delta * 2.0)
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
	var border_w := 2.0
	if active:
		border = Color(UiStyle.GOLD, 0.75 + 0.25 * sin(_t * 6.0))
		border_w = 4.0
	elif targetable:
		border = Color(UiStyle.school_color("heal"), 0.6 + 0.4 * sin(_t * 8.0))
		border_w = 3.0
	elif unit.alive and unit.hp_pct() < 0.35:
		border = Color(1, 0.2, 0.15, 0.6 + 0.4 * sin(_t * 10.0))
	draw_rect(r, border, false, border_w)

	Glyphs.draw(self, UiStyle.GLYPHS.get(unit.id, "diamond"), Vector2(19, 15), 8.0, unit.color)
	UiStyle.text(self, Vector2(32, 21), unit.name, 17, unit.color)
	var hp_text := "DÖD" if not unit.alive else "%d / %d" % [int(unit.hp), int(unit.max_hp)]
	UiStyle.text(self, Vector2(10, 21), hp_text, 13, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 20)

	var hp_rect := Rect2(10, 28, size.x - 20, 18)
	UiStyle.bar(self, hp_rect, unit.hp_pct(), UiStyle.HP_GREEN, _ghost)
	if _hit_flash > 0.0:
		draw_rect(hp_rect, Color(1, 0.2, 0.1, 0.45 * _hit_flash))
	if _heal_flash > 0.0:
		draw_rect(hp_rect, Color(0.5, 1, 0.5, 0.35 * _heal_flash))

	var px := 10.0
	for aura_id in AURA_PIPS:
		if unit.auras.has(aura_id):
			draw_rect(Rect2(px, 50, 11, 6), AURA_PIPS[aura_id])
			px += 14.0

	if not unit.traits.is_empty():
		var shown := unit.traits.filter(func(t: String) -> bool:
			return not sim.data.traits[t].get("hidden", false) and not sim.data.traits[t].get("perk", false))
		var names: Array = shown.map(func(t: String) -> String: return sim.data.traits[t].name)
		# Edens perks (Edsaltaret) visas som ett antal efter Eden.
		var perks := unit.traits.filter(func(t: String) -> bool: return sim.data.traits[t].get("perk", false)).size()
		if perks > 0 and not names.is_empty():
			names[0] += " +%d perks" % perks
		var trait_name := " · ".join(names)
		var col := Color(UiStyle.TRAIT_GOLD, 0.6).lerp(Color.WHITE, _trait_flash * 0.8)
		if _trait_flash > 0.0:
			draw_rect(Rect2(6, 58, size.x - 12, 14), Color(UiStyle.TRAIT_GOLD, 0.25 * _trait_flash))
		UiStyle.text(self, Vector2(10, 69), trait_name, 13, col)

	if not unit.artifact.is_empty():
		var kind: Dictionary = sim.data.artifacts.get(unit.artifact.type, {})
		var ab: String = unit.artifact.ability
		Glyphs.draw(self, kind.get("icon", "diamond"), Vector2(16, 79), 5.0, Color("#b9c4d6"))
		var label: String = kind.get("name", "") + ((": " + sim.data.abilities[ab].name) if ab != "" else "")
		UiStyle.text(self, Vector2(26, 84), label, 12, Color("#b9c4d6"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 34)

	if not unit.alive:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
