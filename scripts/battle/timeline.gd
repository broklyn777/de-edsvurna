class_name Timeline
extends Control
## Tidslinjen överst: vem som agerar nu och vilka som står på tur, resten av rundan och nästa.

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
	var x := 0.0
	var divider_drawn := false
	UiStyle.text(self, Vector2(0, 12), "RUNDA %d" % sim.round, 13, Color(1, 1, 1, 0.6))
	for i in list.size():
		var entry: Dictionary = list[i]
		if entry.next_round and not divider_drawn:
			divider_drawn = true
			draw_line(Vector2(x + 2, 20), Vector2(x + 2, 20 + SLOT), Color(1, 1, 1, 0.35), 2.0)
			x += 10.0
		var u := sim.unit(entry.id)
		var big: bool = i == 0 and sim.current != null and entry.id == sim.current.id
		var r := (SLOT / 2.0) * (1.0 if big else 0.78)
		var c := Vector2(x + SLOT / 2.0, 20 + SLOT / 2.0)
		var a := 0.5 if entry.next_round else 1.0
		draw_circle(c, r + 2, Color(0, 0, 0, 0.8 * a))
		draw_circle(c, r, Color(u.color.darkened(0.55), a))
		var glyph: String = UiStyle.GLYPHS.get(u.id, "skull") if u.team == 0 else "skull"
		Glyphs.draw(self, glyph, c, r * 0.5, Color(u.color.lightened(0.2), a))
		var ring := Color("#4a8cff") if u.team == 0 else Color("#e0412e")
		if big:
			ring = Color(UiStyle.GOLD, 0.75 + 0.25 * sin(_t * 6.0))
		draw_arc(c, r + 1, 0, TAU, 32, Color(ring, a), 3.0 if big else 2.0, true)
		x += SLOT + GAP
