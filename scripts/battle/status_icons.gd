class_name StatusIcons
## Statusikoner (0.22): en liten ruta per status under livmätaren. Ljus kant = buff, röd = debuff, guld =
## tillstånd (Försvarar, Provocerar). Siffran nere till höger är turer kvar, uppe till höger staplarna.
## Glyfer i kod tills riktiga ikoner (tuschark) finns.

const BUFF := Color("#e8f0ff")
const DEBUFF := Color("#e0412e")
const STATE := Color("#e8c547")


static func color_of(a: Dictionary) -> Color:
	match a.get("kind", ""):
		"buff":
			return BUFF
		"debuff":
			return DEBUFF
	return STATE


## Ritar figurens statusar i en rad från pos (övre vänstra hörnet). Returnerar bredden.
static func draw(ci: CanvasItem, data: Dictionary, u: CombatUnit, pos: Vector2, s := 20.0, max_w := 9999.0) -> float:
	var x := 0.0
	var font := UiStyle.bold()
	for aura_id in u.auras:
		if x + s > max_w:
			break
		var a: Dictionary = u.auras[aura_id]
		var d: Dictionary = data.auras.get(aura_id, {})
		var r := Rect2(pos + Vector2(x, 0), Vector2(s, s))
		var col := color_of(a)
		ci.draw_rect(r, Color(0.05, 0.04, 0.07, 0.9))
		ci.draw_rect(r, col, false, 2.0)
		Glyphs.draw(ci, d.get("glyph", "diamond"), r.get_center(), s * 0.3, col.lerp(Color.WHITE, 0.2))
		var fs := 15 if s >= 22.0 else 12
		if float(a.get("remaining", -1)) > 0.0:
			var n := str(int(a.remaining))
			ci.draw_string_outline(font, r.position + Vector2(s - fs * 0.6, s + 3), n, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
			ci.draw_string(font, r.position + Vector2(s - fs * 0.6, s + 3), n, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		if int(a.get("stacks", 1)) > 1:
			var st := "×%d" % int(a.stacks)
			ci.draw_string_outline(font, r.position + Vector2(s - fs * 0.8, fs * 0.75), st, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, 3, Color.BLACK)
			ci.draw_string(font, r.position + Vector2(s - fs * 0.8, fs * 0.75), st, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, col)
		x += s + 4.0
	return x


## Rader för Inspect: "Sårbar (debuff, 2 turer): tar 50 % mer skada."
static func lines(data: Dictionary, u: CombatUnit) -> Array[String]:
	var out: Array[String] = []
	for aura_id in u.auras:
		var a: Dictionary = u.auras[aura_id]
		var d: Dictionary = data.auras.get(aura_id, {})
		var kind: String = {"buff": "buff", "debuff": "debuff"}.get(a.get("kind", ""), "tillstånd")
		var left := "" if float(a.get("remaining", -1)) <= 0.0 else ", %d %s" % [int(a.remaining),
				"tur" if int(a.remaining) == 1 else "turer"]
		var stacks := "" if int(a.get("stacks", 1)) <= 1 else " ×%d" % int(a.stacks)
		var text: String = d.get("text", "")
		if text.contains(": "):
			text = text.get_slice(": ", 1)
		out.append("%s%s (%s%s): %s" % [d.get("name", aura_id), stacks, kind, left, text])
	return out
