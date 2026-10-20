class_name DialogBox
extends RefCounted
## Samtalsrutan (0.24, Siralims dialogruta): ett tuschporträtt till vänster, namnet i guld och 1–3 rader text.
## Valen (stationens tjänster) står i en kolumn ovanför rutans högra kant. Delas av borgen och rumskartan.
##
## Porträtten läses från assets/illustrations/portraits/<id>.png (eller .webp), utklippta ur VD:ns porträttark med
## tools/cut_symbols.gd. Tills arket finns ritas en enkel tuschbyst i personens färg.

const PORTRAIT_DIR := "res://assets/illustrations/portraits/"
const PAPER := Color(0.93, 0.85, 0.66)
const INK := Color(0.20, 0.12, 0.06)
const OPTION_H := 48.0
const OPTION_W := 330.0

static var _cache := {}


static func portrait_texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var tex: Texture2D = null
	for ext in ["png", "webp"]:
		var path := PORTRAIT_DIR + "%s.%s" % [id, ext]
		if ResourceLoader.exists(path):
			tex = load(path)
			break
	_cache[id] = tex
	return tex


static func color_of(data: Dictionary, id: String) -> Color:
	var p := Dialog.person(data, id)
	if p.has("color"):
		return Color(p.color)
	return Color(data.get("heroes", {}).get(id, {}).get("color", "#8a7a5a"))


## Porträttet i en ram: bilden om den finns, annars en tuschbyst med personens initial.
static func portrait(ci: CanvasItem, data: Dictionary, id: String, r: Rect2) -> void:
	ci.draw_rect(r, PAPER)
	var tex := portrait_texture(id)
	if tex:
		ci.draw_texture_rect(tex, r.grow(-4), false)
	else:
		var c := r.get_center()
		var s := r.size.x
		var col := color_of(data, id)
		# Axlar och bröst i personens färg, huvud i papper, tuschlinjer runt om.
		var chest := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			chest.append(c + Vector2(cos(a) * s * 0.38, s * 0.5 + sin(a) * s * 0.3))
		ci.draw_colored_polygon(chest, Color(col, 0.85))
		ci.draw_polyline(chest, INK, 2.0, true)
		ci.draw_circle(c + Vector2(0, -s * 0.08), s * 0.2, PAPER.lightened(0.1))
		ci.draw_arc(c + Vector2(0, -s * 0.08), s * 0.2, 0, TAU, 24, INK, 2.2, true)
		var name := Dialog.display_name(data, id)
		UiStyle.text(ci, Vector2(r.position.x, r.end.y - s * 0.1), name.substr(0, 1), int(s * 0.22), PAPER,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	ci.draw_rect(r, INK, false, 3.0)
	ci.draw_rect(r.grow(-6), Color(INK, 0.5), false, 1.0)


## Rutan längst ned: porträtt, namn (och titel) och texten. t = tid för den blinkande "Tryck"-raden.
## h: rutans höjd (replikerna under nedstigningen är en rad och får en lägre ruta).
static func box(ci: CanvasItem, data: Dictionary, area: Vector2, who: String, text: String, t: float, hint := true,
		h := 176.0) -> Rect2:
	var w := minf(area.x - 60, 980.0)
	var r := Rect2((area.x - w) / 2.0, area.y - h - 18, w, h)
	ci.draw_rect(r, Color(0.05, 0.04, 0.07, 0.95))
	ci.draw_rect(r, Color(UiStyle.GOLD, 0.85), false, 2.0)
	var pr := Rect2(r.position + Vector2(14, 14), Vector2(h - 28, h - 28))
	portrait(ci, data, who, pr)
	var x := pr.end.x + 22
	var name := Dialog.display_name(data, who)
	UiStyle.text(ci, Vector2(x, r.position.y + 36), name, 22, UiStyle.GOLD)
	var title: String = Dialog.person(data, who).get("title", data.get("heroes", {}).get(who, {}).get("title", ""))
	if title != "":
		var nw := UiStyle.bold().get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		UiStyle.text(ci, Vector2(x + nw + 14, r.position.y + 36), title, 16, Color(1, 1, 1, 0.55))
	UiStyle.para(ci, Vector2(x, r.position.y + 68), text, 20, Color.WHITE, r.end.x - x - 22, 3 if h > 140 else 2)
	if hint:
		UiStyle.text(ci, Vector2(r.position.x, r.end.y - 12), "Tryck för att fortsätta", 15,
				Color(1, 1, 1, 0.45 + 0.25 * sin(t * 4.0)), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18)
	return r


## Valen ovanför rutans högra kant. Returnerar rektanglarna (för trycken), uppifrån och ned.
static func option_rects(box_rect: Rect2, count: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var x := box_rect.end.x - OPTION_W
	var y := box_rect.position.y - 10 - count * (OPTION_H + 8)
	for i in count:
		out.append(Rect2(x, y + i * (OPTION_H + 8), OPTION_W, OPTION_H))
	return out


static func options(ci: CanvasItem, box_rect: Rect2, labels: Array) -> Array[Rect2]:
	var rects := option_rects(box_rect, labels.size())
	for i in labels.size():
		var r := rects[i]
		var last := i == labels.size() - 1
		ci.draw_rect(r, Color(0.05, 0.04, 0.07, 0.95))
		ci.draw_rect(r, Color(UiStyle.GOLD, 0.35 if last else 0.85), false, 2.0)
		UiStyle.text(ci, r.position + Vector2(18, r.size.y / 2 + 7), String(labels[i]), 19,
				Color(1, 1, 1, 0.6) if last else Color.WHITE)
	return rects
