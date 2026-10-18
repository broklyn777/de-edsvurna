class_name AbilityButton
extends Control
## Rund förmågeknapp. Reagerar på tryckningen (inte släppet) för snabbast möjliga respons.
## Visar cooldown, GCD, köad order, kastförlopp och blinkar när förmågan blir redo.
## Om en egenskap laddar upp något som förmågan förbrukar visas laddningarna ovanför knappen.

signal activated(ability_id: String)
signal became_ready(ability_id: String)

const RADIUS := 52.0

var ability_id := ""
var ab: Dictionary
var owner_unit: CombatUnit
var sim: CombatSim
var key_label := ""
var hint := false
var _press := 0.0
var _ready_flash := 0.0
var _shake := 0.0
var _was_cooling := false
var _t := 0.0


func setup(id: String, ability: Dictionary, owner: CombatUnit, key: String) -> void:
	ability_id = id
	ab = ability
	owner_unit = owner
	key_label = key
	size = Vector2(RADIUS * 2 + 8, RADIUS * 2 + 8)
	mouse_filter = Control.MOUSE_FILTER_STOP


func press() -> void:
	_press = 1.0
	activated.emit(ability_id)


func refuse() -> void:
	_shake = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		press()
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	_press = maxf(0.0, _press - delta * 7.0)
	_shake = maxf(0.0, _shake - delta * 4.0)
	_ready_flash = maxf(0.0, _ready_flash - delta * 2.5)
	var cooling := owner_unit.cooldown_left(ability_id) > 0.0
	if _was_cooling and not cooling and owner_unit.alive:
		_ready_flash = 1.0
		became_ready.emit(ability_id)
	_was_cooling = cooling
	queue_redraw()


func _draw() -> void:
	var c := size / 2 + Vector2(sin(_t * 70.0) * 7.0 * _shake, 0)
	var r := RADIUS * (1.0 - 0.09 * _press)
	var col := Color(ab.get("button_color", "#888888"))
	var cd := owner_unit.cooldown_left(ability_id)
	var total_cd: float = ab.get("cooldown", 0.0)
	var usable: bool = owner_unit.alive and owner_unit.mana >= ab.get("cost", 0.0)

	if hint and usable and cd <= 0.0:
		var p := 0.5 + 0.5 * sin(_t * 10.0)
		draw_circle(c, r + 8 + 4 * p, Color(UiStyle.GOLD, 0.25 + 0.25 * p))
	draw_circle(c, r + 3, Color(0, 0, 0, 0.75))
	draw_circle(c, r, col.darkened(0.62))
	draw_circle(c + Vector2(0, -r * 0.08), r * 0.88, col.darkened(0.35))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.35), r * 0.4, Color(1, 1, 1, 0.08))
	Glyphs.draw(self, ab.get("icon", "diamond"), c + Vector2(0, -10), r * 0.42, col.lightened(0.35))
	UiStyle.text(self, Vector2(c.x - r, c.y + r * 0.55), ab.name, 14, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER, r * 2, 4)

	if owner_unit.is_casting() and owner_unit.cast.ability == ability_id:
		draw_arc(c, r + 1, -PI / 2, -PI / 2 + TAU * owner_unit.cast_progress(), 48, UiStyle.GOLD, 6.0, true)
	elif owner_unit.queued.get("ability", "") == ability_id:
		draw_arc(c, r + 1, 0, TAU, 48, Color(1, 1, 1, 0.55 + 0.45 * sin(_t * 14.0)), 4.0, true)
	else:
		draw_arc(c, r + 1, 0, TAU, 48, Color(col.lightened(0.2), 0.8), 2.5, true)

	if cd > 0.0 and total_cd > 0.0:
		if total_cd >= 120.0:
			# En gång per strid: visa att den är förbrukad i stället för en lång nedräkning.
			draw_circle(c, r, Color(0, 0, 0, 0.62))
			UiStyle.text(self, Vector2(c.x - r, c.y + 6), "ANVÄND", 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 4)
		else:
			UiStyle.pie(self, c, r, cd / total_cd, Color(0, 0, 0, 0.62))
			var label := str(ceili(cd)) if cd >= 1.0 else "%.1f" % cd
			UiStyle.text(self, Vector2(c.x - r, c.y + 12), label, 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2, 6)
	elif ab.get("gcd", true) and owner_unit.gcd > 0.0:
		UiStyle.pie(self, c, r, owner_unit.gcd / 1.5, Color(0, 0, 0, 0.35))

	if not owner_unit.alive:
		draw_circle(c, r, Color(0.1, 0.1, 0.1, 0.75))
	elif not usable:
		draw_circle(c, r, Color(0.1, 0.2, 0.7, 0.45))
	if _ready_flash > 0.0:
		draw_circle(c, r * (1.0 + 0.25 * (1.0 - _ready_flash)), Color(1, 1, 1, 0.5 * _ready_flash))
	_draw_charges(c, r)
	if key_label != "":
		UiStyle.text(self, Vector2(c.x - r * 0.95, c.y - r * 0.6), key_label, 13, Color(1, 1, 1, 0.5))


func _draw_charges(c: Vector2, r: float) -> void:
	var info := sim.charge_info(owner_unit, ability_id) if sim else {}
	if info.is_empty() or info.max <= 0.0:
		return
	var full: bool = info.value >= info.max
	var glow := 0.75 + 0.25 * sin(_t * 9.0) if full else 1.0
	if info.max <= 10.0:
		# Prickar i en båge över knappen.
		var n := int(info.max)
		for i in n:
			var a := -PI / 2 + (i - (n - 1) / 2.0) * 0.32
			var p := c + Vector2(cos(a), sin(a)) * (r + 13)
			var lit := i < int(info.value)
			draw_circle(p, 6.5, Color(0, 0, 0, 0.8))
			draw_circle(p, 5.0, Color(UiStyle.TRAIT_GOLD, glow) if lit else Color(1, 1, 1, 0.15))
	else:
		var label := str(int(info.value))
		var p := c + Vector2(0, -r - 12)
		draw_rect(Rect2(p - Vector2(30, 11), Vector2(60, 22)), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(p - Vector2(30, 11), Vector2(60 * info.value / info.max, 22)), Color(UiStyle.TRAIT_GOLD, 0.35 * glow))
		UiStyle.text(self, p + Vector2(-30, 6), label, 15, Color(UiStyle.TRAIT_GOLD, glow), HORIZONTAL_ALIGNMENT_CENTER, 60, 3)
