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
		UiStyle.text(self, Vector2(-150, 0), text, font_size, Color(color, a),
				HORIZONTAL_ALIGNMENT_CENTER, 300, 7 if big else 5)


## Ljusstråle från healern till målet medan healingen laddas, så att man ser vem som får den.
## Ritas i skärmkoordinater ovanpå 3D-scenen.
class HealBeams extends Node2D:
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
		var c := UiStyle.school_color("heal")
		for h in sim.heroes:
			if not h.is_casting() or not CombatSim.is_heal(sim.ability(h.cast.ability)):
				continue
			var target_id: String = h.cast.targets[0]
			var from := world.project(models[h.id].chest_position())
			var to := world.project(models[target_id].chest_position())
			var k := h.cast_progress()
			var pulse := 0.5 + 0.5 * sin(_t * 12.0)
			if target_id != h.id:
				draw_line(from, to, Color(c, 0.18 + 0.15 * pulse), 12.0, true)
				draw_line(from, from.lerp(to, k), Color(1, 1, 0.8, 0.75), 3.5, true)
			var feet := world.project(models[target_id].global_position)
			draw_set_transform(feet, 0, Vector2(1, 0.45))
			draw_arc(Vector2.ZERO, 44.0 + 5.0 * pulse, 0, TAU, 40, Color(c, 0.9), 5.0, true)
			draw_set_transform(Vector2.ZERO)
			draw_arc(to, 34.0, -PI / 2, -PI / 2 + TAU * k, 40, Color(c, 0.95), 4.0, true)


## Hälsomätare, kastmätare och namn ovanför hjältarnas huvuden.
class Overheads extends Node2D:
	var sim: CombatSim
	var world: CryptWorld
	var models: Dictionary

	func _init(s: CombatSim, w: CryptWorld, unit_models: Dictionary) -> void:
		sim = s
		world = w
		models = unit_models

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		for h in sim.heroes:
			var head := world.project(models[h.id].head_position())
			var name_color := h.color if h.alive else Color(0.55, 0.55, 0.55)
			UiStyle.text(self, head + Vector2(-80, -22), h.name, 15, name_color, HORIZONTAL_ALIGNMENT_CENTER, 160, 4)
			if not h.alive:
				continue
			var c := UiStyle.HP_GREEN if h.hp_pct() > 0.35 else Color("#e0412e")
			UiStyle.bar(self, Rect2(head + Vector2(-30, -14), Vector2(60, 7)), h.hp_pct(), c)
			if h.is_casting():
				var school: String = sim.ability(h.cast.ability).get("school", "physical")
				UiStyle.bar(self, Rect2(head + Vector2(-30, -5), Vector2(60, 5)), h.cast_progress(), UiStyle.school_color(school))
