class_name Fx
extends RefCounted
## Kortlivade visuella effekter. Alla tar bort sig själva när de är klara.


## Expanderande ring vid träffar, healing och förmågor.
class Ring extends Node2D:
	var color := Color.WHITE
	var radius_from := 10.0
	var radius_to := 60.0
	var life := 0.35
	var width := 6.0
	var filled := false
	var _t := 0.0

	func _init(c: Color, from_r: float, to_r: float, duration := 0.35, w := 6.0, fill := false) -> void:
		color = c
		radius_from = from_r
		radius_to = to_r
		life = duration
		width = w
		filled = fill

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / life, 0.0, 1.0)
		var r := lerpf(radius_from, radius_to, 1.0 - pow(1.0 - k, 3.0))
		var a := (1.0 - k) * color.a
		if filled:
			draw_circle(Vector2.ZERO, r, Color(color, a * 0.3))
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(color, a), width * (1.0 - k * 0.6), true)


## Gnistor som sprids från en träffpunkt.
class Sparks extends Node2D:
	var color := Color.WHITE
	var life := 0.45
	var _t := 0.0
	var _parts: Array = []

	func _init(c: Color, count := 12, speed := 260.0, duration := 0.45) -> void:
		color = c
		life = duration
		for i in count:
			var a := randf() * TAU
			_parts.append({"dir": Vector2(cos(a), sin(a)), "speed": speed * randf_range(0.4, 1.0),
					"len": randf_range(6, 14)})

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := _t / life
		for p in _parts:
			var dist: float = p.speed * _t * (1.0 - k * 0.5)
			var a: Vector2 = p.dir * dist
			draw_line(a, a + p.dir * p.len * (1.0 - k), Color(color, 1.0 - k), 3.0 * (1.0 - k) + 1.0, true)


## Projektil med svans: Frostbolt, Pyroblast, Shadow Bolt.
class Projectile extends Node2D:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var travel := 0.3
	var color := Color.WHITE
	var size := 8.0
	var arc := 30.0
	var _t := 0.0
	var _trail: Array[Vector2] = []

	func _init(a: Vector2, b: Vector2, duration: float, c: Color, s := 8.0) -> void:
		from = a
		to = b
		travel = duration
		color = c
		size = s
		position = a
		arc = clampf(a.distance_to(b) * 0.15, 10.0, 60.0)

	func _process(delta: float) -> void:
		_t += delta
		var k := minf(_t / travel, 1.0)
		position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * arc)
		_trail.push_front(position)
		if _trail.size() > 12:
			_trail.pop_back()
		if k >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for i in range(_trail.size() - 1, -1, -1):
			var f := 1.0 - float(i) / _trail.size()
			draw_circle(_trail[i] - position, size * (0.35 + 0.65 * f), Color(color, 0.5 * f))
		draw_circle(Vector2.ZERO, size * 1.5, Color(color, 0.35))
		draw_circle(Vector2.ZERO, size, color)
		draw_circle(Vector2.ZERO, size * 0.5, Color(1, 1, 1, 0.9))


## Flygande siffra eller text. Kritiska träffar poppar större.
class FloatingText extends Node2D:
	var text := ""
	var color := Color.WHITE
	var font_size := 26
	var big := false
	var life := 1.0
	var _t := 0.0
	var _drift := Vector2.ZERO

	func _init(s: String, c: Color, size: int, crit := false, duration := 1.0) -> void:
		text = s
		color = c
		font_size = size
		big = crit
		life = duration
		_drift = Vector2(randf_range(-30, 30), -70.0 if not crit else -50.0)
		z_index = 50

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		position += _drift * delta * (1.0 - _t / life)
		var pop := 1.0
		if big:
			pop = 1.0 + 0.9 * maxf(0.0, 1.0 - _t / 0.12) if _t < 0.12 else 1.0 + 0.1 * maxf(0.0, 1.0 - (_t - 0.12) / 0.15)
		scale = Vector2.ONE * pop
		queue_redraw()

	func _draw() -> void:
		var a := clampf((life - _t) / 0.35, 0.0, 1.0)
		UiStyle.text(self, Vector2(-300, 0), text, font_size, Color(color, a),
				HORIZONTAL_ALIGNMENT_CENTER, 600, 7 if big else 5)


## Hälsomätare ovanför alla figurer. Fiender visar också sin avsikt: vad de gör på sin tur
## och mot vem.
class Overheads extends Node2D:
	const INTENT_GLYPHS := {"heal": "cross", "ranged": "bolt", "melee": "daggers"}

	var sim: CombatSim
	var world: CryptWorld
	var models: Dictionary
	var _t := 0.0

	func _init(s: CombatSim, w: CryptWorld, unit_models: Dictionary) -> void:
		sim = s
		world = w
		models = unit_models

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for u in sim.units:
			if not u.alive:
				continue
			var head := world.project(models[u.id].head_position())
			var c := UiStyle.HP_GREEN if u.team == 0 else Color("#c23a3a")
			UiStyle.bar(self, Rect2(head + Vector2(-36, -12), Vector2(72, 8)), u.hp_pct(), c)
			if u.team == 1:
				UiStyle.text(self, head + Vector2(-90, -18), u.name, 13, Color(u.color, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 180, 4)
				_draw_intent(u, head + Vector2(0, -42))

	func _draw_intent(u: CombatUnit, at: Vector2) -> void:
		if u.intent.is_empty():
			return
		var ab := sim.ability(u.intent.ability)
		var is_heal: bool = ab.effects.any(func(e: Dictionary) -> bool: return e.type == "heal")
		var kind := "heal" if is_heal else ("melee" if ab.get("melee", false) else "ranged")
		var col := UiStyle.school_color("heal") if is_heal else Color("#ff6a4a")
		var pulse := 0.8 + 0.2 * sin(_t * 5.0)
		draw_circle(at, 15, Color(0, 0, 0, 0.75))
		draw_arc(at, 15, 0, TAU, 32, Color(col, pulse), 2.0, true)
		Glyphs.draw(self, INTENT_GLYPHS[kind], at, 8.0, Color(col, pulse))
		var target_name := ""
		for id in u.intent.get("targets", []):
			var t := sim.unit(id)
			if t and t.alive:
				target_name = t.name
				break
		if target_name != "":
			UiStyle.text(self, at + Vector2(-80, -20), "→ " + target_name, 12, Color(col, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 160, 4)
