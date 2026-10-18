class_name UiStyle
extends RefCounted
## Gemensamma typsnitt och färger för striden.

const SCHOOL_COLORS := {
	"physical": Color("#f2ede0"),
	"frost": Color("#86d8ff"),
	"fire": Color("#ff8a2a"),
	"holy": Color("#ffe48a"),
	"shadow": Color("#b47cff"),
	"nature": Color("#7fe05a"),
	"heal": Color("#5dff73"),
}
const HP_GREEN := Color("#3fbf4a")
const MANA_BLUE := Color("#2f6bff")
const PANEL := Color(0.05, 0.045, 0.07, 0.86)
const CAST_INTERRUPTIBLE := Color("#ffb21e")
const CAST_UNSTOPPABLE := Color("#d23a3a")
const GOLD := Color("#f2c85b")
const TRAIT_GOLD := Color("#ffd75e")
const GLYPHS := {"paladin": "shield", "brokk": "daggers", "alva": "cross", "eira": "bolt", "solveig": "flame"}

static var _bold: Font


static func bold() -> Font:
	if _bold == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Roboto", "Arial", "sans-serif"])
		f.font_weight = 700
		_bold = f
	return _bold


static func school_color(school: String) -> Color:
	return SCHOOL_COLORS.get(school, Color.WHITE)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0) -> void:
	if outline > 0:
		ci.draw_string_outline(bold(), pos, s, align, width, size, outline, Color(0, 0, 0, 0.85 * color.a))
	ci.draw_string(bold(), pos, s, align, width, size, color)


static func bar(ci: CanvasItem, rect: Rect2, pct: float, color: Color, ghost := -1.0) -> void:
	ci.draw_rect(rect, Color(0, 0, 0, 0.55))
	if ghost > pct:
		ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ghost, 0, 1), rect.size.y)), Color(1, 0.85, 0.75, 0.75))
	var fill := Rect2(rect.position, Vector2(rect.size.x * clampf(pct, 0, 1), rect.size.y))
	ci.draw_rect(fill, color)
	ci.draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.4)), Color(1, 1, 1, 0.12))
	ci.draw_rect(rect, Color(0, 0, 0, 0.8), false, 1.5)


static func pie(ci: CanvasItem, center: Vector2, radius: float, fraction: float, color: Color) -> void:
	if fraction <= 0.0:
		return
	var points := PackedVector2Array([center])
	var steps := maxi(3, int(48 * fraction))
	for i in steps + 1:
		var a := -PI / 2 + TAU * fraction * i / steps
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	ci.draw_colored_polygon(points, color)


## Kort med titel och brödtext (valskärmar). Markerat kort får guldram och guldkant till vänster.
static func card(ci: CanvasItem, r: Rect2, title: String, body: String, selected: bool, accent: Color,
		tag := "", flash := 0.0) -> void:
	ci.draw_rect(r, Color(0.09, 0.08, 0.12, 0.96) if selected else Color(0.06, 0.055, 0.08, 0.85))
	if flash > 0.0:
		ci.draw_rect(r, Color(TRAIT_GOLD, 0.3 * flash))
	if selected:
		ci.draw_rect(r, TRAIT_GOLD, false, 3.0)
		ci.draw_rect(Rect2(r.position, Vector2(6, r.size.y)), TRAIT_GOLD)
	else:
		ci.draw_rect(r, Color(accent, 0.35), false, 1.5)
	var a := 1.0 if selected else 0.7
	text(ci, r.position + Vector2(16, 26), title, 18, Color(TRAIT_GOLD, a), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24, 4)
	if tag != "":
		text(ci, r.position + Vector2(0, 26), tag, 13, Color(accent, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 12, 3)
	var lines := int((r.size.y - 38.0) / 18.0)
	if lines > 0 and body != "":
		ci.draw_multiline_string(bold(), r.position + Vector2(16, 48), body, HORIZONTAL_ALIGNMENT_LEFT,
				r.size.x - 28, 14, lines, Color(1, 1, 1, 0.9 if selected else 0.6))


## Stor knapp (valskärmar).
static func big_button(ci: CanvasItem, r: Rect2, label: String, t: float, enabled := true) -> void:
	var pulse := 0.85 + 0.15 * sin(t * 4.0)
	ci.draw_rect(r, Color(0.55, 0.12, 0.08, 0.95) if enabled else Color(0.2, 0.2, 0.22, 0.9))
	ci.draw_rect(r, Color(GOLD, pulse if enabled else 0.3), false, 3.0)
	text(ci, r.position + Vector2(0, r.size.y / 2 + 9), label, 24, Color.WHITE if enabled else Color(1, 1, 1, 0.4),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6)
