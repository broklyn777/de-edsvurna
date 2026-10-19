class_name GemArt
## Material och Nether Stones ritade i kod (0.20): bärnsten som en droppe, trick som en kantig sten och
## Nether Stones som en slipad sten med glöd efter sällsyntheten. Används av Smeden, segerskärmen,
## hjältebladet och fyndscenen.


## kind: "amber", "trick" eller "nether". glow 0–1 ger ett pulserande sken bakom.
static func draw(ci: CanvasItem, kind: String, c: Vector2, r: float, color: Color, glow := 0.0, t := 0.0) -> void:
	if glow > 0.0:
		var pulse := 0.75 + 0.25 * sin(t * 3.0)
		for i in 5:
			var k := 1.0 + i * 0.35
			ci.draw_circle(c, r * k, Color(color, 0.10 * glow * pulse * (1.0 - i * 0.18)))
	var pts := _shape(kind, c, r)
	ci.draw_colored_polygon(pts, color.darkened(0.25))
	# Fasetter: en ljusare övre halva och en glänsande punkt.
	var top := PackedVector2Array()
	for p in pts:
		top.append(c + (p - c) * 0.62 + Vector2(0, -r * 0.12))
	ci.draw_colored_polygon(top, color.lightened(0.15))
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, color.lightened(0.45), maxf(1.0, r * 0.08), true)
	ci.draw_circle(c + Vector2(-r * 0.28, -r * 0.32), r * 0.12, Color(1, 1, 1, 0.75))


static func _shape(kind: String, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match kind:
		"amber":
			# Droppe.
			for i in 18:
				var a := TAU * i / 18.0 - PI / 2.0
				var rr := r * (0.78 + 0.22 * maxf(0.0, -sin(a)))
				pts.append(c + Vector2(cos(a) * rr * 0.85, sin(a) * rr + r * 0.1))
		"trick":
			# Kantig sten.
			var radii := [1.0, 0.82, 0.95, 0.7, 0.9, 0.78, 1.0]
			for i in radii.size():
				var a := TAU * i / radii.size() - PI / 2.0 + 0.2
				pts.append(c + Vector2(cos(a), sin(a)) * r * float(radii[i]))
		_:
			# Slipad sten (Nether): åttakant, högre än bred.
			for i in 8:
				var a := TAU * i / 8.0 - PI / 2.0 + PI / 8.0
				pts.append(c + Vector2(cos(a) * r * 0.8, sin(a) * r))
	return pts


## Ett fynd ritat med sin färg; Nether Stones glöder efter sällsyntheten.
static func draw_find(ci: CanvasItem, data: Dictionary, find: Dictionary, c: Vector2, r: float, t := 0.0) -> void:
	var color := Forge.find_color(data, find)
	var glow := 0.0
	if find.kind == "nether":
		glow = [0.3, 0.6, 0.9, 1.2][maxi(0, ["common", "magic", "rare", "legendary"].find(find.stone.rarity))]
	elif find.kind == "trick":
		glow = 0.3
	draw(ci, find.kind, c, r, color, glow, t)
