class_name KeepArt
extends RefCounted
## Borgen uppifrån i tusch (0.24), ritad i planritningens koordinater (data/keep.json, 1536×1024). Används tills
## VD:ns bild (assets/illustrations/borgen.webp) finns; då ritas bilden i stället och bara stämningen (rök, gnistor,
## eld) läggs ovanpå. Allt i bläck på pergament, som rumskartan.

const INK := Color(0.20, 0.12, 0.06)
const INK_SOFT := Color(0.20, 0.12, 0.06, 0.55)
const FLOOR := Color(0.95, 0.88, 0.70)
const YARD := Color(0.86, 0.78, 0.60)
const WOOD := Color(0.62, 0.44, 0.26)
const EMBER := Color(1.0, 0.55, 0.18)


static func _rect(k: Array) -> Rect2:
	return Rect2(k[0], k[1], k[2], k[3])


static func _v(k: Array) -> Vector2:
	return Vector2(k[0], k[1])


## En handdragen linje: lite ojämn, som tusch.
static func line(ci: CanvasItem, a: Vector2, b: Vector2, w: float, color := INK) -> void:
	var n := maxi(2, int(a.distance_to(b) / 40.0))
	var pts := PackedVector2Array()
	var normal := (b - a).orthogonal().normalized()
	for i in n + 1:
		var t := float(i) / n
		var wob := sin(t * 9.0 + a.x * 0.013 + b.y * 0.007) * 1.6 if i > 0 and i < n else 0.0
		pts.append(a.lerp(b, t) + normal * wob)
	ci.draw_polyline(pts, color, w, true)


static func box(ci: CanvasItem, r: Rect2, w: float, fill := Color(0, 0, 0, 0), color := INK) -> void:
	if fill.a > 0.0:
		ci.draw_rect(r, fill)
	line(ci, r.position, Vector2(r.end.x, r.position.y), w, color)
	line(ci, Vector2(r.end.x, r.position.y), r.end, w, color)
	line(ci, r.end, Vector2(r.position.x, r.end.y), w, color)
	line(ci, Vector2(r.position.x, r.end.y), r.position, w, color)


static func ring(ci: CanvasItem, c: Vector2, r: float, w: float, color := INK, fill := Color(0, 0, 0, 0)) -> void:
	if fill.a > 0.0:
		ci.draw_circle(c, r, fill)
	ci.draw_arc(c, r, 0, TAU, maxi(16, int(r / 2)), color, w, true)


## Hela planritningen: golv, gångar, murar och inredning.
static func plan(ci: CanvasItem, k: Dictionary) -> void:
	var walls := _rect(k.walls)
	ci.draw_rect(walls, Color(0.80, 0.71, 0.52))
	var yard := _rect(k.yard.rect)
	ci.draw_rect(yard, YARD)
	_cobbles(ci, yard)
	# Gångarna från rummens dörrar ut på gården.
	for id in k.rooms:
		var room: Dictionary = k.rooms[id]
		var a := _v(room.door)
		var b := _v(room.yard)
		var side := (b - a).orthogonal().normalized() * 26.0
		if a.distance_to(b) > 4.0:
			ci.draw_colored_polygon(PackedVector2Array([a + side, b + side, b - side, a - side]), FLOOR)
			line(ci, a + side, b + side, 3.0, INK_SOFT)
			line(ci, a - side, b - side, 3.0, INK_SOFT)
	for id in k.rooms:
		box(ci, _rect(k.rooms[id].rect), 6.0, FLOOR)
	box(ci, _rect(k.store), 6.0, FLOOR)
	# Dörröppningar: en lucka i väggen.
	for id in k.rooms:
		var room: Dictionary = k.rooms[id]
		ci.draw_circle(_v(room.door), 16.0, FLOOR)
	# Yttermuren: tjock, med torn i hörnen.
	box(ci, walls, 14.0)
	box(ci, walls.grow(-14), 3.0, Color(0, 0, 0, 0), INK_SOFT)
	for c in [walls.position, Vector2(walls.end.x, walls.position.y), walls.end, Vector2(walls.position.x, walls.end.y)]:
		ring(ci, c, 46.0, 8.0, INK, Color(0.80, 0.71, 0.52))
		ring(ci, c, 30.0, 3.0, INK_SOFT)
	_furniture(ci, k)


static func _cobbles(ci: CanvasItem, r: Rect2) -> void:
	var i := 0
	var y := r.position.y + 18.0
	while y < r.end.y - 10.0:
		var x := r.position.x + 16.0 + (i % 2) * 22.0
		while x < r.end.x - 10.0:
			ci.draw_arc(Vector2(x, y), 9.0, PI * 1.1, PI * 1.9, 5, INK_SOFT, 1.5, true)
			x += 44.0
		y += 30.0
		i += 1


static func _furniture(ci: CanvasItem, k: Dictionary) -> void:
	var R := {}
	for id in k.rooms:
		R[id] = _rect(k.rooms[id].rect)
	# Gården: brunnen och två buskar.
	var well := _v(k.yard.well)
	ring(ci, well, 40.0, 6.0, INK, Color(0.6, 0.55, 0.45))
	ring(ci, well, 24.0, 3.0, INK, Color(0.18, 0.2, 0.25))
	line(ci, well + Vector2(-50, -46), well + Vector2(50, -46), 5.0)
	for b in [Vector2(560, 760), Vector2(980, 760)]:
		for j in 5:
			ring(ci, b + Vector2(cos(j * 1.3) * 14, sin(j * 1.3) * 10), 14.0, 2.5, INK, Color(0.45, 0.55, 0.32))
	# Kapellet: altare, ljus och bänkar.
	var al: Rect2 = R.altar
	var altar := Rect2(al.position + Vector2(60, 36), Vector2(130, 56))
	box(ci, altar, 5.0, Color(0.9, 0.86, 0.78))
	for i in 3:
		box(ci, Rect2(al.position + Vector2(50, 140 + i * 38), Vector2(170, 14)), 3.5, WOOD)
	ring(ci, al.position + Vector2(280, 60), 14.0, 3.0, INK, Color(0.9, 0.86, 0.78))
	# Värdshuset: härd, långbord med bänkar och tunnor.
	var inn: Rect2 = R.inn
	var hearth := _v(k.hearth)
	ci.draw_arc(hearth, 54.0, 0, PI, 16, INK, 8.0, true)
	ci.draw_colored_polygon(_half_disc(hearth, 46.0), Color(0.28, 0.16, 0.10))
	for t in [Rect2(inn.position + Vector2(60, 70), Vector2(200, 50)), Rect2(inn.position + Vector2(90, 160), Vector2(240, 50))]:
		box(ci, t, 5.0, WOOD.lightened(0.25))
		line(ci, t.position + Vector2(0, -12), Vector2(t.end.x, t.position.y - 12), 4.0, WOOD.darkened(0.2))
		line(ci, Vector2(t.position.x, t.end.y + 12), t.end + Vector2(0, 12), 4.0, WOOD.darkened(0.2))
	for b in [inn.end - Vector2(40, 40), inn.end - Vector2(84, 40)]:
		ring(ci, b, 18.0, 4.0, INK, WOOD)
	# Biblioteket: hyllor längs väggarna, läspulpet och rullar.
	var lb: Rect2 = R.library
	for i in 4:
		var shelf := Rect2(lb.position + Vector2(24, 24 + i * 60), Vector2(26, 50))
		box(ci, shelf, 3.0, WOOD)
		for j in 5:
			line(ci, shelf.position + Vector2(4, 8 + j * 9), shelf.position + Vector2(22, 8 + j * 9), 2.0, Color(0.5, 0.2, 0.15))
	box(ci, Rect2(lb.position + Vector2(90, 24), Vector2(220, 24)), 3.0, WOOD)
	box(ci, Rect2(lb.position + Vector2(170, 140), Vector2(90, 56)), 4.0, WOOD.lightened(0.2))
	for s in [Vector2(30, 0), Vector2(60, 14)]:
		ring(ci, lb.position + Vector2(190, 168) + s, 9.0, 2.5, INK, FLOOR.lightened(0.05))
	# Gorms kammare: skrivbord med kartor, stol och en kista.
	var st: Rect2 = R.macros
	var desk := Rect2(st.position + Vector2(70, 50), Vector2(150, 70))
	box(ci, desk, 5.0, WOOD.lightened(0.15))
	box(ci, Rect2(desk.position + Vector2(14, 10), Vector2(70, 46)), 2.5, Color(0.96, 0.9, 0.74))
	line(ci, desk.position + Vector2(20, 22), desk.position + Vector2(76, 40), 2.0, INK_SOFT)
	ring(ci, desk.position + Vector2(75, 96), 16.0, 3.5, INK, WOOD)
	box(ci, Rect2(st.position + Vector2(250, 30), Vector2(60, 40)), 4.0, WOOD)
	# Smedjan: ässja med kol, städ, vattentunna och verktyg.
	var sm: Rect2 = R.smith
	var forge := _v(k.forge)
	box(ci, Rect2(forge - Vector2(50, 40), Vector2(100, 80)), 6.0, Color(0.35, 0.32, 0.3))
	ci.draw_rect(Rect2(forge - Vector2(32, 22), Vector2(64, 44)), Color(0.45, 0.12, 0.05))
	var anvil := sm.position + Vector2(150, 160)
	ci.draw_colored_polygon(PackedVector2Array([anvil + Vector2(-36, -14), anvil + Vector2(36, -14), anvil + Vector2(50, -4),
			anvil + Vector2(36, 6), anvil + Vector2(20, 6), anvil + Vector2(20, 18), anvil + Vector2(-20, 18), anvil + Vector2(-20, 6),
			anvil + Vector2(-36, 6)]), Color(0.3, 0.3, 0.33))
	ring(ci, sm.position + Vector2(60, 210), 22.0, 4.0, INK, Color(0.35, 0.45, 0.55))
	for i in 4:
		line(ci, sm.position + Vector2(40 + i * 22, 30), sm.position + Vector2(40 + i * 22, 70), 3.0)
	# Övningsgården: sandring, halmdockor och ett vapenställ.
	var pr: Rect2 = R.practice
	ring(ci, pr.get_center() + Vector2(10, 20), 110.0, 3.0, INK_SOFT)
	for d in [Vector2(-70, -40), Vector2(-80, 70), Vector2(40, 100)]:
		var c: Vector2 = pr.get_center() + d
		ring(ci, c, 20.0, 3.5, INK, Color(0.86, 0.74, 0.42))
		line(ci, c + Vector2(-26, 0), c + Vector2(26, 0), 4.0, WOOD.darkened(0.3))
	box(ci, Rect2(pr.position + Vector2(24, 22), Vector2(150, 18)), 3.0, WOOD)
	for i in 6:
		line(ci, pr.position + Vector2(36 + i * 24, 16), pr.position + Vector2(36 + i * 24, 50), 3.0, Color(0.4, 0.4, 0.45))
	# Porthuset: två torn och porten mot mörkret.
	var gt: Rect2 = R.gate
	for x in [gt.position.x - 30, gt.end.x - 50]:
		box(ci, Rect2(x, gt.position.y + 10, 80, 100), 6.0, Color(0.80, 0.71, 0.52))
	var walls := _rect(k.walls)
	ci.draw_rect(Rect2(gt.get_center().x - 60, walls.end.y - 10, 120, 24), Color(0.12, 0.08, 0.1))
	for i in 7:
		line(ci, Vector2(gt.get_center().x - 54 + i * 18, walls.end.y - 12), Vector2(gt.get_center().x - 54 + i * 18, walls.end.y + 12), 3.0)
	# Förrådet: lådor och säckar.
	var store := _rect(k.store)
	for i in 4:
		var c: Vector2 = store.position + Vector2(50.0 + (i % 2) * 70.0, 50.0 + floorf(i / 2.0) * 70.0)
		box(ci, Rect2(c - Vector2(24, 24), Vector2(48, 48)), 3.5, WOOD.lightened(0.2))
		line(ci, c - Vector2(24, 24), c + Vector2(24, 24), 2.0, INK_SOFT)
		line(ci, c + Vector2(24, -24), c + Vector2(-24, 24), 2.0, INK_SOFT)
	for i in 3:
		ring(ci, store.position + Vector2(220 + i * 36, 140 + (i % 2) * 20), 18.0, 3.0, INK, Color(0.82, 0.74, 0.55))


static func _half_disc(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## Stämningen: rök ur smedjans skorsten, gnistor från ässjan, eld i härden och ljus i kapellet. t = tid.
## image: VD:ns bild ligger under (den har egen eld och egna ljus), så bara ett mjukt sken, gnistor och rök läggs till.
static func ambience(ci: CanvasItem, k: Dictionary, t: float, image := false) -> void:
	var chimney := _v(k.chimney)
	for i in 7:
		var ph := fmod(t * 0.18 + i / 7.0, 1.0)
		var c := chimney + Vector2(sin(ph * 4.0 + i) * 16.0 - ph * 30.0, -ph * 150.0)
		ci.draw_circle(c, 10.0 + ph * 26.0, Color(0.32, 0.28, 0.3, (1.0 - ph) * 0.28))
	var forge := _v(k.forge)
	if image:
		_glow(ci, forge, 46.0, t, 7.0)
		_glow(ci, _v(k.hearth), 52.0, t, 6.0)
		for i in 9:
			var ph := fmod(t * 1.1 + i * 0.37, 1.0)
			ci.draw_circle(forge + Vector2(sin(i * 7.3) * 22.0 + sin(t * 5.0 + i) * 5.0, -ph * 60.0), 2.5, Color(1.0, 0.75, 0.3, 1.0 - ph))
			var ph2 := fmod(t * 0.8 + i * 0.29, 1.0)
			ci.draw_circle(_v(k.hearth) + Vector2(sin(i * 5.1) * 26.0, -ph2 * 40.0), 2.0, Color(1.0, 0.7, 0.3, 1.0 - ph2))
		return
	ci.draw_circle(forge, 26.0 + sin(t * 7.0) * 3.0, Color(EMBER, 0.55 + 0.15 * sin(t * 11.0)))
	for i in 9:
		var ph := fmod(t * 1.1 + i * 0.37, 1.0)
		var c := forge + Vector2(sin(i * 7.3) * 26.0 + sin(t * 5.0 + i) * 6.0, -ph * 70.0)
		ci.draw_circle(c, 2.5, Color(1.0, 0.75, 0.3, 1.0 - ph))
	var hearth := _v(k.hearth)
	for j in 3:
		var fl := 0.6 + 0.4 * sin(t * (6.0 + j * 2.3) + j)
		ci.draw_circle(hearth + Vector2(-16 + j * 16, 18), 12.0 * fl, Color(1.0, 0.6 - j * 0.1, 0.2, 0.8))
	for i in 5:
		var ph := fmod(t * 0.8 + i * 0.23, 1.0)
		ci.draw_circle(hearth + Vector2(sin(i * 5.1) * 20.0, 20.0 + ph * 40.0), 2.0, Color(1.0, 0.7, 0.3, 1.0 - ph))
	# Ljusen på altaret.
	var altar: Rect2 = _rect(k.rooms.altar.rect)
	for i in 3:
		var c := altar.position + Vector2(80 + i * 45, 50)
		ci.draw_circle(c, 5.0, Color(0.95, 0.92, 0.85))
		ci.draw_circle(c + Vector2(0, -6), 4.0 + sin(t * 9.0 + i * 2.0), Color(1.0, 0.8, 0.35, 0.9))


## Ett mjukt, fladdrande eldsken (lager av genomskinliga cirklar).
static func _glow(ci: CanvasItem, c: Vector2, r: float, t: float, speed: float) -> void:
	var fl := 0.85 + 0.15 * sin(t * speed) * sin(t * speed * 1.7 + 1.0)
	for j in 4:
		ci.draw_circle(c, r * fl * (1.0 - j * 0.2), Color(1.0, 0.62, 0.22, 0.07 + j * 0.03))


## En liten tuschpjäs för en följeslagare: en bonde med ett band i hjältens färg.
static func pawn(ci: CanvasItem, c: Vector2, s: float, tint: Color) -> void:
	ci.draw_circle(c + Vector2(0, s * 0.42), s * 0.36, FLOOR)
	ci.draw_arc(c + Vector2(0, s * 0.42), s * 0.36, 0, TAU, 20, INK, 3.0, true)
	var body := PackedVector2Array([c + Vector2(-s * 0.26, s * 0.4), c + Vector2(-s * 0.12, -s * 0.12),
			c + Vector2(s * 0.12, -s * 0.12), c + Vector2(s * 0.26, s * 0.4)])
	ci.draw_colored_polygon(body, FLOOR)
	ci.draw_polyline(body, INK, 3.0, true)
	ci.draw_line(c + Vector2(-s * 0.2, s * 0.14), c + Vector2(s * 0.2, s * 0.14), tint, s * 0.12)
	ci.draw_circle(c + Vector2(0, -s * 0.28), s * 0.2, FLOOR)
	ci.draw_arc(c + Vector2(0, -s * 0.28), s * 0.2, 0, TAU, 20, INK, 3.0, true)
