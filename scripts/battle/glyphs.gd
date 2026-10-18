class_name Glyphs
extends RefCounted
## Enkla ikoner ritade med former, så att vi slipper bildfiler i prototypen.


static func draw(ci: CanvasItem, kind: String, c: Vector2, s: float, color: Color) -> void:
	var dark := Color(0, 0, 0, 0.55 * color.a)
	match kind:
		"shield":
			var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.8, -s * 0.65),
					c + Vector2(s * 0.7, s * 0.2), c + Vector2(0, s), c + Vector2(-s * 0.7, s * 0.2),
					c + Vector2(-s * 0.8, -s * 0.65)])
			ci.draw_colored_polygon(pts, color)
			pts.append(pts[0])
			ci.draw_polyline(pts, dark, s * 0.08, true)
			ci.draw_line(c + Vector2(0, -s * 0.7), c + Vector2(0, s * 0.7), dark, s * 0.1)
		"cross":
			ci.draw_rect(Rect2(c - Vector2(s * 0.22, s * 0.85), Vector2(s * 0.44, s * 1.7)), color)
			ci.draw_rect(Rect2(c - Vector2(s * 0.75, s * 0.42), Vector2(s * 1.5, s * 0.44)), color)
		"flame":
			ci.draw_circle(c + Vector2(0, s * 0.25), s * 0.6, color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.58, s * 0.1),
					c + Vector2(-s * 0.2, -s * 0.6), c + Vector2(0, -s * 0.25), c + Vector2(s * 0.15, -s),
					c + Vector2(s * 0.58, s * 0.1)]), color)
			ci.draw_circle(c + Vector2(0, s * 0.35), s * 0.3, Color(1, 0.95, 0.7, color.a))
		"bolt":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, -s), c + Vector2(-s * 0.55, s * 0.12),
					c + Vector2(-s * 0.05, s * 0.12), c + Vector2(-s * 0.25, s), c + Vector2(s * 0.55, -s * 0.15),
					c + Vector2(s * 0.05, -s * 0.15)]), color)
		"drop":
			ci.draw_circle(c + Vector2(0, s * 0.3), s * 0.58, color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, s * 0.15), c + Vector2(0, -s),
					c + Vector2(s * 0.55, s * 0.15)]), color)
			ci.draw_circle(c + Vector2(-s * 0.2, s * 0.3), s * 0.15, Color(1, 1, 1, 0.5 * color.a))
		"diamond":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.6, 0),
					c + Vector2(0, s), c + Vector2(-s * 0.6, 0)]), color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.28, 0),
					c + Vector2(0, s * 0.5), c + Vector2(-s * 0.28, 0)]), Color(1, 1, 1, 0.6 * color.a))
		"daggers":
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.7), c + Vector2(s * 0.6, -s * 0.6), color, s * 0.2)
			ci.draw_line(c + Vector2(s * 0.7, s * 0.7), c + Vector2(-s * 0.6, -s * 0.6), color, s * 0.2)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.2), c + Vector2(-s * 0.2, s * 0.6), color, s * 0.16)
			ci.draw_line(c + Vector2(s * 0.6, s * 0.2), c + Vector2(s * 0.2, s * 0.6), color, s * 0.16)
		"skull":
			ci.draw_circle(c + Vector2(0, -s * 0.1), s * 0.75, color)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, s * 0.35), Vector2(s * 0.8, s * 0.45)), color)
			ci.draw_circle(c + Vector2(-s * 0.3, -s * 0.1), s * 0.22, dark)
			ci.draw_circle(c + Vector2(s * 0.3, -s * 0.1), s * 0.22, dark)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.2 + s * 0.2 * i, s * 0.45), c + Vector2(-s * 0.2 + s * 0.2 * i, s * 0.8), dark, s * 0.06)
