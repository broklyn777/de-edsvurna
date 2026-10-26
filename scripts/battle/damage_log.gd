class_name DamageLog
extends Control
## Stridsloggen (0.21 som skadeloggen; Siralims stridslogg): varje handling i striden, nyast överst. Skador, helningar
## och undvikanden har sin uträkning (tryck på raden, DamageExplain); allt annat – förmågor som inte skadar, buffar,
## debuffar, Barriär, statusar som tar en tur, tidslinjen, avbrott – får en rad ur BattleLog. Dra för att bläddra.
## Striden står still medan den är öppen.

## [{e: händelsen, title, color}]
var entries: Array[Dictionary] = []
var open := false
var data: Dictionary = {}
var hero_ids: Array = []
var _open_rows := {}
var _scroll := 0.0
var _press := Vector2(-1, -1)
## Raderna som ritades senast: [{rect, index}] (för tryck).
var _rows: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func add(e: Dictionary) -> void:
	var color := Color.WHITE
	match e.type:
		"heal":
			color = UiStyle.school_color("heal")
		"dodge":
			color = Color("#d8e6ff")
		_:
			color = Color("#ffb38a") if hero_ids.has(e.target) else Color.WHITE
	entries.append({"e": e, "title": DamageExplain.title(data, e), "color": color})


## Varje händelse ur simulatorn: med uträkning som förut, annars BattleLog-raden (om händelsen loggas).
func log_event(sim: CombatSim, e: Dictionary) -> void:
	if e.type in ["damage", "heal", "dodge"]:
		if e.has("calc"):
			add(e)
		return
	var text := BattleLog.line(sim, e)
	if text != "":
		add_note(text, note_color(sim, e))


static func note_color(sim: CombatSim, e: Dictionary) -> Color:
	match e.type:
		"death":
			return Color("#ff7a6a")
		"interrupt":
			return UiStyle.GOLD
		"aura_applied":
			return Color("#9fe0a0") if e.get("aura_kind", "") == "buff" else (Color("#d7a6ff") if e.get("aura_kind", "") == "debuff" else Color("#cfd8e6"))
		"action":
			var u := sim.unit(e.get("unit", ""))
			return Color("#ffd9b0") if u != null and u.team == 1 else Color("#e8e2cf")
	return Color(1, 1, 1, 0.72)


## 0.31: en rad utan uträkning (en varslad attack som laddas eller bryts).
func add_note(text: String, color: Color) -> void:
	entries.append({"e": {"type": "note"}, "title": text, "color": color})


func show_log() -> void:
	open = true
	visible = true
	_scroll = 0.0


func close() -> void:
	open = false
	visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_press = event.position
			return
		if _press.distance_to(event.position) > 14.0:
			return
		if _close_rect().has_point(event.position):
			close()
			return
		for r in _rows:
			if r.rect.has_point(event.position):
				_open_rows[r.index] = not _open_rows.get(r.index, false)
				return
	elif event is InputEventMouseMotion and _press.x >= 0.0 and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_scroll = maxf(0.0, _scroll - event.relative.y)
		accept_event()


func _close_rect() -> Rect2:
	return Rect2(size.x - 200, 20, 176, 48)


func _process(_delta: float) -> void:
	if open:
		size = get_viewport_rect().size
		queue_redraw()


func _draw() -> void:
	if not open:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.95))
	UiStyle.text(self, Vector2(0, 50), "STRIDSLOGG", 30, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 6)
	UiStyle.text(self, Vector2(0, 80), "Nyast överst. Tryck på en rad med ▸ för uträkningen, dra för att bläddra.", 17,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	var c := _close_rect()
	draw_rect(c, Color(0, 0, 0, 0.7))
	draw_rect(c, Color(UiStyle.GOLD, 0.9), false, 2.0)
	UiStyle.text(self, c.position + Vector2(0, 31), "STÄNG", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 4)
	_rows.clear()
	var x := 40.0
	var w := size.x - 80.0
	var y := 120.0 - _scroll
	if entries.is_empty():
		UiStyle.text(self, Vector2(0, 160), "Inget har hänt än.", 19, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	for i in range(entries.size() - 1, -1, -1):
		if y > size.y:
			break
		var en: Dictionary = entries[i]
		var opened: bool = _open_rows.get(i, false)
		var row := Rect2(x - 10, y - 24, w + 20, 34)
		if y > 96.0:
			draw_rect(row, Color(1, 1, 1, 0.07 if opened else 0.03))
			var note: bool = en.e.get("type", "") == "note"
			UiStyle.text(self, Vector2(x, y), ("    " if note else ("▾ " if opened else "▸ ")) + String(en.title),
					17 if note else 19, en.color, HORIZONTAL_ALIGNMENT_LEFT, w, 3)
			_rows.append({"rect": row, "index": i})
		y += 36.0
		if opened:
			for line in DamageExplain.lines(data, en.e):
				var h := UiStyle.bold().get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, w - 30, 17).y
				if y > 96.0 and y < size.y:
					UiStyle.para(self, Vector2(x + 30, y - 6), line, 17, Color(1, 1, 1, 0.85), w - 30)
				y += h + 4.0
			y += 8.0
