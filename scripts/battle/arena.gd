extends Node2D
## Kryptans golv: en stenplatta med runor, ben och svagt pulserande ljus.

var _t := 0.0
var _bones: Array = []


func _ready() -> void:
	z_index = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 26:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.55, 1.0)
		_bones.append({"pos": Vector2(cos(a) * 470 * d, sin(a) * 250 * d), "rot": rng.randf() * PI, "len": rng.randf_range(8, 18)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.53))
	draw_circle(Vector2.ZERO, 560, Color(0.07, 0.06, 0.09))
	draw_circle(Vector2.ZERO, 500, Color(0.15, 0.13, 0.17))
	draw_circle(Vector2.ZERO, 470, Color(0.19, 0.17, 0.21))
	for i in 12:
		var a := i * TAU / 12.0
		draw_line(Vector2(cos(a), sin(a)) * 140, Vector2(cos(a), sin(a)) * 470, Color(0, 0, 0, 0.22), 3.0)
	for ring in [140, 300, 470]:
		draw_arc(Vector2.ZERO, ring, 0, TAU, 96, Color(0, 0, 0, 0.3), 4.0, true)
	var glow := 0.25 + 0.1 * sin(_t * 1.3)
	draw_arc(Vector2.ZERO, 220, 0, TAU, 96, Color(0.6, 0.4, 1.0, glow * 0.6), 3.0, true)
	for i in 8:
		var a := i * TAU / 8.0 + _t * 0.05
		var p := Vector2(cos(a), sin(a)) * 220
		draw_circle(p, 9, Color(0.7, 0.5, 1.0, glow))
		draw_circle(p, 4, Color(0.9, 0.8, 1.0, glow + 0.2))
	draw_set_transform(Vector2.ZERO)
	for b in _bones:
		var dir: Vector2 = Vector2.from_angle(b.rot) * b.len
		draw_line(b.pos - dir, b.pos + dir, Color(0.75, 0.72, 0.65, 0.45), 3.0, true)
		draw_circle(b.pos - dir, 3.0, Color(0.75, 0.72, 0.65, 0.45))
		draw_circle(b.pos + dir, 3.0, Color(0.75, 0.72, 0.65, 0.45))
