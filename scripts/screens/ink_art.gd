class_name InkArt
extends RefCounted
## Tuschteckningar i kod för kartorna (0.18): rumssymboler, stigar med handdragen ojämnhet,
## paladinpjäsen och dekoren i marginalen (kompassros, kartusch, drake, svärd i sten, skelett, häxa).
## Allt ritas med linjer på en CanvasItem i bläckfärg, tills riktiga bilder finns.

const INK := Color(0.20, 0.12, 0.06)


## Liten deterministisk ojämnhet (−1…1) så att linjerna ser handdragna ut men inte darrar.
static func jitter(seed_value: float) -> float:
	return sin(seed_value * 12.9898 + 78.233) * 0.5 + sin(seed_value * 4.1 + 1.3) * 0.5


## En stig: streckad bläcklinje med en mjuk båge och lite ojämnhet. solid = gången väg.
static func path(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, solid: bool, width := 2.6) -> void:
	var normal := (b - a).orthogonal().normalized()
	var bend := 10.0 + 6.0 * jitter(a.x * 0.01 + b.y * 0.013)
	var pts := PackedVector2Array()
	var n := 18
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t) + normal * sin(t * PI) * bend
		p += normal * jitter(t * 9.0 + a.x * 0.03) * 1.6
		pts.append(p)
	if solid:
		ci.draw_polyline(pts, color, width + 0.6, true)
		return
	for i in range(0, pts.size() - 1, 2):
		ci.draw_line(pts[i], pts[i + 1], color, width, true)


## En ojämn cirkel (bläckring), t.ex. runt ett rum man kan gå till.
static func ring(ci: CanvasItem, c: Vector2, r: float, color: Color, width := 2.5) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0 + 0.2
		pts.append(c + Vector2(cos(a), sin(a)) * (r + 2.0 * jitter(i * 0.7 + r)))
	ci.draw_polyline(pts, color, width, true)


# --- Rumssymboler (ritas runt mitten c med storleken s, ~40) -----------------------

static func symbol(ci: CanvasItem, kind: String, c: Vector2, s: float, color: Color, boss := false) -> void:
	match kind:
		"battle", "portal_battle":
			crossed_swords(ci, c, s, color)
		"elite":
			shield_skull(ci, c, s, color)
		"treasure":
			chest(ci, c, s, color)
		"shrine":
			altar(ci, c, s, color)
		"campfire":
			campfire(ci, c, s, color)
		"portal":
			swirl(ci, c, s, color)
		"end":
			if boss:
				skull(ci, c, s * 1.2, color)
			else:
				crossed_swords(ci, c, s * 1.15, color)
				ring(ci, c, s * 0.75, color, 2.0)


static func crossed_swords(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	for dir in [-1.0, 1.0]:
		var tip := c + Vector2(dir * s * 0.45, -s * 0.5)
		var hilt := c + Vector2(-dir * s * 0.32, s * 0.36)
		ci.draw_line(tip, hilt, color, 3.0, true)
		var along := (hilt - tip).normalized()
		var guard := hilt - along * s * 0.12
		var across := along.orthogonal() * s * 0.16
		ci.draw_line(guard - across, guard + across, color, 3.0, true)
		ci.draw_line(hilt, hilt + along * s * 0.14, color, 4.0, true)


static func shield_skull(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var w := s * 0.5
	var pts := PackedVector2Array([c + Vector2(-w, -s * 0.5), c + Vector2(w, -s * 0.5), c + Vector2(w, s * 0.05),
			c + Vector2(0, s * 0.55), c + Vector2(-w, s * 0.05), c + Vector2(-w, -s * 0.5)])
	ci.draw_polyline(pts, color, 3.0, true)
	skull(ci, c + Vector2(0, -s * 0.04), s * 0.55, color)


static func skull(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_arc(c + Vector2(0, -s * 0.08), s * 0.4, PI * 0.95, TAU + PI * 0.05, 18, color, 3.0, true)
	var jaw := c + Vector2(0, s * 0.28)
	ci.draw_line(c + Vector2(-s * 0.36, s * 0.0), jaw + Vector2(-s * 0.2, 0), color, 3.0, true)
	ci.draw_line(c + Vector2(s * 0.36, s * 0.0), jaw + Vector2(s * 0.2, 0), color, 3.0, true)
	ci.draw_line(jaw + Vector2(-s * 0.2, 0), jaw + Vector2(s * 0.2, 0), color, 3.0, true)
	ci.draw_circle(c + Vector2(-s * 0.15, -s * 0.06), s * 0.1, color)
	ci.draw_circle(c + Vector2(s * 0.15, -s * 0.06), s * 0.1, color)
	for i in 3:
		var x := -s * 0.1 + i * s * 0.1
		ci.draw_line(jaw + Vector2(x, -s * 0.08), jaw + Vector2(x, 0), color, 2.0, true)


static func chest(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var body := Rect2(c + Vector2(-s * 0.48, -s * 0.05), Vector2(s * 0.96, s * 0.45))
	ci.draw_rect(body, color, false, 3.0)
	ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.48, PI, TAU, 16, color, 3.0, true)
	ci.draw_line(c + Vector2(-s * 0.48, -s * 0.05), c + Vector2(s * 0.48, -s * 0.05), color, 3.0, true)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.08, -s * 0.1), Vector2(s * 0.16, s * 0.2)), color)
	for x in [-0.3, 0.3]:
		ci.draw_line(c + Vector2(s * x, -s * 0.4), c + Vector2(s * x, s * 0.4), Color(color, 0.6), 2.0, true)


static func altar(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_rect(Rect2(c + Vector2(-s * 0.45, s * 0.05), Vector2(s * 0.9, s * 0.14)), color, false, 3.0)
	ci.draw_line(c + Vector2(-s * 0.32, s * 0.19), c + Vector2(-s * 0.32, s * 0.5), color, 3.0, true)
	ci.draw_line(c + Vector2(s * 0.32, s * 0.19), c + Vector2(s * 0.32, s * 0.5), color, 3.0, true)
	ci.draw_line(c + Vector2(-s * 0.45, s * 0.5), c + Vector2(s * 0.45, s * 0.5), color, 3.0, true)
	ci.draw_line(c + Vector2(0, s * 0.05), c + Vector2(0, -s * 0.5), color, 3.0, true)
	ci.draw_line(c + Vector2(-s * 0.17, -s * 0.3), c + Vector2(s * 0.17, -s * 0.3), color, 3.0, true)
	for i in 4:
		var a := -PI / 2 + (i - 1.5) * 0.45
		ci.draw_line(c + Vector2(0, -s * 0.3) + Vector2(cos(a), sin(a)) * s * 0.28,
				c + Vector2(0, -s * 0.3) + Vector2(cos(a), sin(a)) * s * 0.42, Color(color, 0.6), 1.5, true)


static func campfire(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_line(c + Vector2(-s * 0.45, s * 0.45), c + Vector2(s * 0.45, s * 0.2), color, 4.0, true)
	ci.draw_line(c + Vector2(s * 0.45, s * 0.45), c + Vector2(-s * 0.45, s * 0.2), color, 4.0, true)
	var flame := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		var a := t * TAU
		var r := s * (0.28 + 0.06 * sin(a * 3.0))
		flame.append(c + Vector2(sin(a) * r * 0.8, -s * 0.05 - cos(a) * r * 1.2 - (s * 0.25 if absf(sin(a * 0.5)) < 0.2 else 0.0)))
	ci.draw_polyline(flame, color, 2.5, true)
	ci.draw_line(c + Vector2(0, -s * 0.05), c + Vector2(0, -s * 0.5), color, 2.5, true)


static func swirl(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var t := float(i) / 48.0
		var a := t * TAU * 2.5
		pts.append(c + Vector2(cos(a), sin(a)) * s * 0.5 * t)
	ci.draw_polyline(pts, color, 3.0, true)
	ring(ci, c, s * 0.55, Color(color, 0.7), 2.0)


## Paladinpjäsen: en liten tuschfigur med hjälm, sköld och svärd.
static func paladin(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var base := PackedVector2Array([c + Vector2(-s * 0.35, s * 0.5), c + Vector2(s * 0.35, s * 0.5),
			c + Vector2(s * 0.22, s * 0.38), c + Vector2(-s * 0.22, s * 0.38)])
	ci.draw_colored_polygon(base, Color(0.93, 0.85, 0.66))
	ci.draw_polyline(base + PackedVector2Array([base[0]]), color, 2.5, true)
	var body := PackedVector2Array([c + Vector2(-s * 0.2, s * 0.38), c + Vector2(-s * 0.16, -s * 0.12),
			c + Vector2(s * 0.16, -s * 0.12), c + Vector2(s * 0.2, s * 0.38)])
	ci.draw_colored_polygon(body, Color(0.93, 0.85, 0.66))
	ci.draw_polyline(body, color, 2.5, true)
	ci.draw_circle(c + Vector2(0, -s * 0.28), s * 0.17, Color(0.93, 0.85, 0.66))
	ci.draw_arc(c + Vector2(0, -s * 0.28), s * 0.17, 0, TAU, 14, color, 2.5, true)
	ci.draw_line(c + Vector2(-s * 0.12, -s * 0.28), c + Vector2(s * 0.12, -s * 0.28), color, 2.0, true)
	ci.draw_arc(c + Vector2(-s * 0.26, s * 0.08), s * 0.15, 0, TAU, 12, color, 2.5, true)
	ci.draw_line(c + Vector2(s * 0.28, s * 0.25), c + Vector2(s * 0.34, -s * 0.48), color, 2.5, true)
	ci.draw_line(c + Vector2(s * 0.2, s * 0.06), c + Vector2(s * 0.42, s * 0.1), color, 2.0, true)


# --- Dekor i marginalen ------------------------------------------------------

static func compass(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	ring(ci, c, r * 0.62, Color(color, 0.7), 1.5)
	ci.draw_arc(c, r * 0.7, 0, TAU, 40, Color(color, 0.5), 1.0, true)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2
		var long := i % 2 == 0
		var tip := c + Vector2(cos(a), sin(a)) * r * (1.0 if long else 0.6)
		var side := Vector2(cos(a + PI / 2), sin(a + PI / 2)) * r * (0.13 if long else 0.08)
		var tri := PackedVector2Array([c + side, tip, c - side])
		if i % 4 == 0:
			ci.draw_colored_polygon(PackedVector2Array([c, tip, c + side]), color)
		ci.draw_polyline(tri, color, 1.8, true)
	UiStyle.text(ci, c + Vector2(-20, -r - 8), "N", 18, color, HORIZONTAL_ALIGNMENT_CENTER, 40, 0)


## Kartusch: en inramad skylt med inrullade ändar och texten i mitten.
static func cartouche(ci: CanvasItem, rect: Rect2, title: String, color: Color, size := 22) -> void:
	ci.draw_rect(rect, Color(0.94, 0.87, 0.68, 0.92))
	ci.draw_rect(rect, color, false, 2.5)
	ci.draw_rect(rect.grow(-5), Color(color, 0.6), false, 1.2)
	for side in [-1.0, 1.0]:
		var x := rect.position.x if side < 0 else rect.end.x
		var cy := rect.get_center().y
		ci.draw_arc(Vector2(x + side * 10, cy), 10, 0, TAU, 14, color, 2.0, true)
		ci.draw_arc(Vector2(x + side * 10, cy), 4, 0, TAU, 10, color, 1.5, true)
	UiStyle.text(ci, Vector2(rect.position.x, rect.get_center().y + size * 0.35), title, size, color,
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 0)


static func dragon(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var body := PackedVector2Array()
	for i in 31:
		var t := float(i) / 30.0
		body.append(c + Vector2(-s + t * s * 2.0, sin(t * PI * 2.2) * s * 0.18 - t * s * 0.1))
	ci.draw_polyline(body, color, 3.0, true)
	var head := body[body.size() - 1]
	ci.draw_polyline(PackedVector2Array([head, head + Vector2(s * 0.22, -s * 0.06), head + Vector2(s * 0.08, s * 0.08), head]), color, 2.5, true)
	ci.draw_line(head + Vector2(s * 0.05, -s * 0.05), head + Vector2(-s * 0.02, -s * 0.18), color, 2.0, true)
	var wing_root := c + Vector2(s * 0.1, -s * 0.12)
	var wing := PackedVector2Array([wing_root, wing_root + Vector2(-s * 0.2, -s * 0.6), wing_root + Vector2(s * 0.05, -s * 0.38),
			wing_root + Vector2(s * 0.2, -s * 0.62), wing_root + Vector2(s * 0.3, -s * 0.05)])
	ci.draw_polyline(wing, color, 2.0, true)
	for i in 3:
		ci.draw_line(wing_root, wing[1 + i], Color(color, 0.5), 1.0, true)
	ci.draw_line(body[0], body[0] + Vector2(-s * 0.15, s * 0.12), color, 2.0, true)
	for i in range(4, 24, 5):
		ci.draw_line(body[i], body[i] + Vector2(0, -s * 0.08), color, 1.5, true)


static func sword_in_stone(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var stone := PackedVector2Array([c + Vector2(-s * 0.55, s * 0.4), c + Vector2(-s * 0.45, s * 0.05), c + Vector2(-s * 0.1, -s * 0.08),
			c + Vector2(s * 0.35, -s * 0.02), c + Vector2(s * 0.55, s * 0.4)])
	ci.draw_polyline(stone, color, 2.5, true)
	for i in 4:
		var x := -s * 0.35 + i * s * 0.22
		ci.draw_line(c + Vector2(x, s * 0.12), c + Vector2(x - s * 0.08, s * 0.36), Color(color, 0.45), 1.2, true)
	ci.draw_line(c + Vector2(0, -s * 0.04), c + Vector2(0, -s * 0.7), color, 3.0, true)
	ci.draw_line(c + Vector2(-s * 0.16, -s * 0.62), c + Vector2(s * 0.16, -s * 0.62), color, 3.0, true)
	ci.draw_line(c + Vector2(0, -s * 0.62), c + Vector2(0, -s * 0.85), color, 3.5, true)
	ci.draw_circle(c + Vector2(0, -s * 0.88), s * 0.04, color)


static func skeleton(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	skull(ci, c + Vector2(0, -s * 0.55), s * 0.4, color)
	ci.draw_line(c + Vector2(0, -s * 0.38), c + Vector2(0, s * 0.2), color, 2.5, true)
	for i in 4:
		var y := -s * 0.28 + i * s * 0.1
		ci.draw_arc(c + Vector2(0, y), s * 0.16, PI * 0.15, PI * 0.85, 8, color, 1.8, true)
	ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(-s * 0.3, s * 0.05), color, 2.0, true)
	ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(s * 0.32, -s * 0.05), color, 2.0, true)
	ci.draw_line(c + Vector2(0, s * 0.2), c + Vector2(-s * 0.18, s * 0.6), color, 2.0, true)
	ci.draw_line(c + Vector2(0, s * 0.2), c + Vector2(s * 0.18, s * 0.6), color, 2.0, true)
	ci.draw_line(c + Vector2(s * 0.32, -s * 0.05), c + Vector2(s * 0.45, -s * 0.5), color, 2.5, true)


static func witch(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var hat := PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.38), c + Vector2(s * 0.05, -s * 0.95),
			c + Vector2(s * 0.12, -s * 0.6), c + Vector2(s * 0.3, -s * 0.38)])
	ci.draw_polyline(hat, color, 2.5, true)
	ci.draw_line(c + Vector2(-s * 0.4, -s * 0.38), c + Vector2(s * 0.4, -s * 0.38), color, 2.5, true)
	ci.draw_arc(c + Vector2(0, -s * 0.25), s * 0.12, 0, TAU, 12, color, 2.0, true)
	var cloak := PackedVector2Array([c + Vector2(-s * 0.08, -s * 0.13), c + Vector2(-s * 0.4, s * 0.55),
			c + Vector2(s * 0.4, s * 0.55), c + Vector2(s * 0.08, -s * 0.13)])
	ci.draw_polyline(cloak, color, 2.5, true)
	for i in 4:
		ci.draw_line(c + Vector2(-s * 0.2 + i * s * 0.12, s * 0.1), c + Vector2(-s * 0.28 + i * s * 0.16, s * 0.5),
				Color(color, 0.4), 1.2, true)
	ci.draw_line(c + Vector2(s * 0.45, -s * 0.5), c + Vector2(s * 0.45, s * 0.55), color, 2.5, true)
	ci.draw_arc(c + Vector2(s * 0.45, -s * 0.55), s * 0.06, 0, TAU, 8, color, 2.0, true)
