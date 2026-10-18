class_name UnitView
extends Node2D
## Ritar en hjälte eller bossen och spelar upp dess egna rörelser:
## träffblink, utfall vid attacker, kastglöd, aurornas effekter och död.

const GLYPHS := {"warrior": "shield", "priest": "cross", "mage": "diamond", "rogue": "daggers"}
const LUNGE_OUT := 0.07
const LUNGE_BACK := 0.2

var unit: CombatUnit
var sim: CombatSim
var flash := 0.0
var _flash_color := Color.WHITE
var _lunge_dir := Vector2.ZERO
var _lunge_t := 1.0
var _lunge_dist := 16.0
var _recoil := Vector2.ZERO
var _bob := randf() * TAU
var _t := 0.0
var _death_k := 0.0
var _cast_player: AudioStreamPlayer
var _cast_tween: Tween


func setup(u: CombatUnit, s: CombatSim) -> void:
	unit = u
	sim = s
	position = u.position
	_cast_player = AudioStreamPlayer.new()
	add_child(_cast_player)


func hit(strength := 1.0, from := Vector2.ZERO) -> void:
	flash = minf(1.0, 0.6 + 0.4 * strength)
	_flash_color = Color.WHITE
	var dir := (position - from).normalized() if from != Vector2.ZERO else Vector2.ZERO
	_recoil = dir * 7.0 * strength


## Färgad blink, t.ex. grön när enheten blir healad.
func flash_color(c: Color) -> void:
	flash = 1.0
	_flash_color = c


func lunge(toward: Vector2, dist := 16.0) -> void:
	_lunge_dir = (toward - position).normalized()
	_lunge_dist = dist
	_lunge_t = 0.0


func start_cast_sound(s: AudioStream) -> void:
	if s == null:
		return
	if _cast_tween:
		_cast_tween.kill()
	_cast_player.stream = s
	_cast_player.volume_db = -13.0 if unit.team == 0 else -7.0
	_cast_player.play()


func stop_cast_sound() -> void:
	if not _cast_player.playing:
		return
	if _cast_tween:
		_cast_tween.kill()
	_cast_tween = create_tween()
	_cast_tween.tween_property(_cast_player, "volume_db", -40.0, 0.08)
	_cast_tween.tween_callback(_cast_player.stop)


func _process(delta: float) -> void:
	_t += delta
	flash = maxf(0.0, flash - delta * 6.0)
	_lunge_t += delta
	_recoil = _recoil.lerp(Vector2.ZERO, minf(1.0, delta * 14.0))
	if not unit.alive:
		_death_k = minf(1.0, _death_k + delta * 2.5)
	_bob += delta * (2.0 + (1.5 if unit.haste() > 1.2 else 0.0))
	queue_redraw()


func _body_offset() -> Vector2:
	var lunge := 0.0
	if _lunge_t < LUNGE_OUT:
		lunge = _lunge_t / LUNGE_OUT
	elif _lunge_t < LUNGE_OUT + LUNGE_BACK:
		lunge = 1.0 - (_lunge_t - LUNGE_OUT) / LUNGE_BACK
	var bob := Vector2(0, sin(_bob) * 2.0) if unit.alive else Vector2.ZERO
	return _lunge_dir * _lunge_dist * lunge + _recoil + bob


func _draw() -> void:
	var r := unit.radius
	var off := _body_offset()
	draw_set_transform(Vector2(0, r * 0.8), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, r * 1.1, Color(0, 0, 0, 0.4 * (1.0 - _death_k * 0.5)))
	draw_set_transform(Vector2.ZERO)

	_draw_auras_behind(off, r)

	var base := unit.color
	if not unit.alive:
		base = base.lerp(Color(0.25, 0.25, 0.28), 0.85)
	var body := base.lerp(_flash_color, flash * 0.85)
	draw_set_transform(off + Vector2(0, r * 0.5 * _death_k), 0, Vector2(1.0 + 0.2 * _death_k, 1.0 - 0.5 * _death_k))
	draw_circle(Vector2.ZERO, r, body.darkened(0.5))
	draw_circle(Vector2(-r * 0.12, -r * 0.14), r * 0.84, body.darkened(0.1))
	draw_circle(Vector2(-r * 0.3, -r * 0.35), r * 0.3, Color(1, 1, 1, 0.12))
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0, 0, 0, 0.7), 3.0, true)
	if unit.team == 1:
		_draw_boss_face(r)
	else:
		Glyphs.draw(self, GLYPHS.get(unit.id, "diamond"), Vector2.ZERO, r * 0.55, Color(0, 0, 0, 0.55))
	draw_set_transform(Vector2.ZERO)

	_draw_auras_front(off, r)
	if unit.is_casting():
		_draw_casting(off, r)
	if unit.team == 0 and unit.alive:
		_draw_overhead(r)
	if unit.team == 0:
		var name_color := unit.color if unit.alive else Color(0.5, 0.5, 0.5)
		UiStyle.text(self, Vector2(-80, r + 34), unit.name, 15, name_color, HORIZONTAL_ALIGNMENT_CENTER, 160, 4)


func _draw_boss_face(r: float) -> void:
	var frenzy := unit.auras.has("frenzy")
	var eye := Color("#c9a0ff") if not frenzy else Color("#ff4a3a")
	var glow := 0.7 + 0.3 * sin(_t * 5.0)
	for i in 5:
		var x := (i - 2) * r * 0.32
		var h := r * (0.35 if i % 2 == 0 else 0.22)
		draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.13, -r * 0.82), Vector2(x, -r * 0.82 - h),
				Vector2(x + r * 0.13, -r * 0.82)]), unit.color.darkened(0.25))
	for side in [-1, 1]:
		var p := Vector2(side * r * 0.32, -r * 0.12)
		draw_circle(p, r * 0.2, Color(0.05, 0.02, 0.08))
		draw_circle(p, r * 0.09, Color(eye, glow))
		draw_circle(p, r * 0.2, Color(eye, 0.15 * glow))
	draw_line(Vector2(-r * 0.35, r * 0.4), Vector2(r * 0.35, r * 0.4), Color(0.05, 0.02, 0.08), 4.0)
	for i in 5:
		var x := -r * 0.28 + i * r * 0.14
		draw_line(Vector2(x, r * 0.32), Vector2(x, r * 0.48), Color(0.05, 0.02, 0.08), 2.0)


func _draw_auras_behind(off: Vector2, r: float) -> void:
	if unit.auras.has("frenzy"):
		var p := 0.5 + 0.5 * sin(_t * 9.0)
		draw_circle(off, r * (1.25 + 0.08 * p), Color(1, 0.15, 0.1, 0.18 + 0.1 * p))
	if unit.auras.has("bloodlust"):
		for i in 10:
			var a := _t * 3.0 + i * TAU / 10.0
			var flick := 0.6 + 0.4 * sin(_t * 23.0 + i * 1.7)
			var base := off + Vector2(cos(a), sin(a) * 0.6) * (r + 4.0)
			draw_line(base, base + Vector2(0, -10.0 * flick - 4.0), Color(1, 0.35 + 0.3 * flick, 0.1, 0.75), 4.0, true)


func _draw_auras_front(off: Vector2, r: float) -> void:
	if unit.auras.has("shield_wall"):
		var p := 0.5 + 0.5 * sin(_t * 6.0)
		draw_circle(off, r + 12.0, Color(0.6, 0.75, 1.0, 0.13 + 0.05 * p))
		draw_arc(off, r + 12.0, 0, TAU, 6, Color(0.75, 0.88, 1.0, 0.75), 3.0, true)
		draw_arc(off, r + 12.0, 0, TAU, 48, Color(0.75, 0.88, 1.0, 0.35 * p), 6.0, true)
	if unit.auras.has("renew"):
		for i in 3:
			var a := _t * 2.2 + i * TAU / 3.0
			draw_circle(off + Vector2(cos(a) * (r + 6), sin(a) * (r + 6) * 0.5 - 4), 3.5, Color(0.4, 1.0, 0.5, 0.85))


func _draw_casting(off: Vector2, r: float) -> void:
	var school: String = sim.ability(unit.cast.ability).get("school", "physical")
	var c := UiStyle.school_color(school)
	var p := 0.5 + 0.5 * sin(_t * 12.0)
	draw_arc(off, r + 5.0, 0, TAU, 48, Color(c, 0.35 + 0.35 * p), 3.0, true)
	draw_arc(off, r + 5.0, -PI / 2, -PI / 2 + TAU * unit.cast_progress(), 48, Color(c, 0.95), 4.0, true)
	if unit.team == 0:
		var rect := Rect2(Vector2(-r - 6, r + 10), Vector2(2 * r + 12, 6))
		UiStyle.bar(self, rect, unit.cast_progress(), c)


func _draw_overhead(r: float) -> void:
	var rect := Rect2(Vector2(-r, -r - 16), Vector2(2 * r, 6))
	var c := UiStyle.HP_GREEN if unit.hp_pct() > 0.35 else Color("#e0412e")
	UiStyle.bar(self, rect, unit.hp_pct(), c)
