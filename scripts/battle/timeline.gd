class_name Timeline
extends Control
## Tidslinjen överst: vem som agerar nu och vilka som står på tur. Kön roterar som i Siralim.

const SLOT := 46.0
const GAP := 6.0
const COUNT := 11

var sim: CombatSim
var _t := 0.0


func setup(s: CombatSim) -> void:
	sim = s
	size = Vector2(COUNT * (SLOT + GAP) + 70, 74)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var list := sim.upcoming(COUNT)
	# 0.29.5: vems tur det är står i klartext ovanför (förr bara "TIDSLINJE").
	if sim.current != null and sim.current.alive:
		var who := sim.current
		UiStyle.text(self, Vector2(0, 13), "NU:", 14, Color(1, 1, 1, 0.65))
		UiStyle.text(self, Vector2(34, 13), who.name.to_upper(), 16, UiStyle.GOLD if who.team == 0 else Color("#ff8a6a"))
	else:
		UiStyle.text(self, Vector2(0, 12), "TIDSLINJE", 13, Color(1, 1, 1, 0.6))
	for i in list.size():
		var u := sim.unit(list[i])
		var big: bool = i == 0 and sim.current != null and list[i] == sim.current.id
		var r := (SLOT / 2.0) * (1.08 if big else 0.78)
		var c := Vector2(i * (SLOT + GAP) + SLOT / 2.0, 20 + SLOT / 2.0)
		var a := 1.0 - 0.06 * i
		if big:
			draw_circle(c, r + 7, Color(UiStyle.GOLD, 0.18 + 0.1 * sin(_t * 6.0)))  # ett sken runt den som agerar
		draw_circle(c, r + 2, Color(0, 0, 0, 0.8 * a))
		draw_circle(c, r, Color(u.color.darkened(0.55), a))
		# 0.29.5: hjältarna med sina porträtt, fienderna med begynnelsebokstaven (elit i guld).
		var tex: Texture2D = DialogBox.portrait_texture(u.id) if u.team == 0 else null
		if tex != null:
			_round_texture(tex, c, r - 1.0, a)
		elif u.team == 0:
			Glyphs.draw(self, UiStyle.GLYPHS.get(u.id, "shield"), c, r * 0.5, Color(u.color.lightened(0.2), a))
		else:
			UiStyle.text(self, c + Vector2(-r, r * 0.42), u.name.left(1).to_upper(), int(r * 1.05),
					Color(UiStyle.GOLD if u.elite else Color("#ffd2c4"), a), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
		var ring := Color("#4a8cff") if u.team == 0 else (Color(UiStyle.GOLD, 0.8) if u.elite else Color("#e0412e"))
		if big:
			ring = Color(UiStyle.GOLD, 0.75 + 0.25 * sin(_t * 6.0))
		draw_arc(c, r + 1, 0, TAU, 32, Color(ring, a), 4.0 if big else 2.0, true)
		# 0.22: en prick för debuffar (röd) och buffar (ljus) under porträttet; Snärjd ger ett kors.
		var dots: Array = []
		if u.has_kind("debuff"):
			dots.append(StatusIcons.DEBUFF)
		if u.has_kind("buff"):
			dots.append(StatusIcons.BUFF)
		for k in dots.size():
			draw_circle(c + Vector2((k - (dots.size() - 1) / 2.0) * 10.0, r + 7), 3.5, Color(dots[k], a))
		if u.auras.keys().any(func(id: String) -> bool: return sim.data.auras[id].get("snare", false)):
			draw_line(c + Vector2(-r, -r) * 0.7, c + Vector2(r, r) * 0.7, Color(StatusIcons.DEBUFF, a), 2.0)


## Ett runt porträtt (en cirkel av trianglar med texturkoordinater).
func _round_texture(tex: Texture2D, c: Vector2, r: float, a: float) -> void:
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for k in 32:
		var ang := TAU * k / 32.0
		var d := Vector2(cos(ang), sin(ang))
		pts.append(c + d * r)
		uvs.append(Vector2(0.5, 0.42) + d * 0.4)
	draw_colored_polygon(pts, Color(1, 1, 1, a), uvs, tex)
