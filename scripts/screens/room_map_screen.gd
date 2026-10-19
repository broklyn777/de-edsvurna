extends TapScreen
## Rumskartan (0.18): våningen på pergament, steg för steg från vänster till höger med stigar mellan
## rummen och våningens slut längst till höger. Rummen man kan gå till pulserar; tryck för att gå in.
## Strider går till striden; lägereld, skattkammare och helgedom avgörs här i en ruta ovanpå kartan.
## Kameran glider ut ur kampanjkartans område när skärmen öppnas (samma pergament).

const ZOOM_TIME := 0.55
const ROOM_R := 32.0
## Rumstypernas namn, färger och tecken (ritas som stämplar i bläck).
const KIND_NAMES := {"battle": "Strid", "elite": "Elit", "treasure": "Skattkammare", "shrine": "Helgedom",
		"campfire": "Lägereld", "portal": "Portal", "end": "Våningens slut", "portal_battle": "Portalens strid"}
const KIND_COLORS := {"battle": Color("#8a3a28"), "elite": Color("#b01830"), "treasure": Color("#c89a28"),
		"shrine": Color("#4a7aa8"), "campfire": Color("#d0661a"), "portal": Color("#6a3a9a"), "end": Color("#3a1010"),
		"portal_battle": Color("#6a3a9a")}
const KIND_MARKS := {"battle": "S", "elite": "E", "treasure": "$", "shrine": "+", "campfire": "L", "portal": "O", "end": "!",
		"portal_battle": "S"}

var parchment: Parchment
var _zoom_t := 0.0
## Rutan ovanpå kartan: {title, text, options: [{label, shrine}]} eller tom.
var _dialog := {}
var _shrine_options: Array = []
## 3D-ögonblicket som spelas när sällskapet går in i ett rum (RoomMoment), eller null.
var _moment: RoomMoment
## Rumstyper med ett ögonblick (stridsrum har inget, striden är själv 3D).
const MOMENT_KINDS := ["treasure", "shrine", "campfire", "portal"]


func _ready() -> void:
	super()
	parchment = Parchment.new()
	add_child(parchment)
	if run.state.map == null:
		run.go(run.CAMPAIGN_SCENE)
		return
	# Utvecklare: --enter=<typ> går in i första rummet av den typen (för att se ögonblicket).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--enter="):
			var want := arg.get_slice("=", 1)
			for r in run.state.map.steps[0]:
				r.kind = want if r.slot == 0 else r.kind
			get_tree().create_timer(0.8).timeout.connect(_enter.bind(run.state.map.steps[0][0].id))


func _process(delta: float) -> void:
	super(delta)
	if _zoom_t < 1.0:
		_zoom_t = minf(1.0, _zoom_t + delta / ZOOM_TIME)
		parchment.set_view(lerpf(3.2, 1.0, _smooth(_zoom_t)), Vector2(0.5, 0.5))


static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


# --- Inmatning --------------------------------------------------------------

func _tap(p: Vector2) -> void:
	var state: RunState = run.state
	if _moment != null:
		return  # ögonblicket tar själv emot trycket (hoppar över)
	if not _dialog.is_empty():
		_tap_dialog(p)
		return
	if _macro_rect().has_point(p):
		run.open_macros(run.ROOM_MAP_SCENE)
		return
	if _moments_rect().has_point(p):
		run.profile.room_moments = not run.profile.room_moments
		run.save()
		return
	for id in state.choices():
		if _room_pos(id).distance_to(p) < ROOM_R + 14.0:
			_enter(id)
			return


func _enter(id: String) -> void:
	var kind: String = run.state.map.room(id).kind
	if run.profile.room_moments and MOMENT_KINDS.has(kind):
		await _play_moment(kind)
	var r: Dictionary = run.enter_room(id)
	if RunState.is_battle(r):
		return  # striden tar över (portalen går in i sin strid efter ögonblicket)
	_show_room(r)


## Spelar rummets 3D-ögonblick i Realmens stil och väntar tills det är slut eller hoppas över.
func _play_moment(kind: String) -> void:
	var style := "chapel" if run.state.realm == "chapel" else "crypt"
	_moment = RoomMoment.create(kind, style, Array(run.state.party), run.data)
	add_child(_moment)
	await _moment.finished
	_moment.queue_free()
	_moment = null
	UnitModel.free_shared()


## Rummets händelse som en ruta på kartan.
func _show_room(r: Dictionary) -> void:
	match r.kind:
		"campfire":
			_dialog = {"title": "Lägereld", "text": run.campfire(), "options": [{"label": "VIDARE"}]}
		"treasure":
			_dialog = {"title": "Skattkammare", "text": run.treasure(), "options": [{"label": "VIDARE"}]}
		"shrine":
			_shrine_options = run.state.shrine_options(run.data, run.rng)
			var options := []
			for o in _shrine_options:
				options.append({"label": RunState.shrine_text(run.data, o), "shrine": o})
			_dialog = {"title": "Helgedom", "text": "Välj en gåva – eller låt Pandemonium avgöra.", "options": options}


func _tap_dialog(p: Vector2) -> void:
	var options: Array = _dialog.options
	for i in options.size():
		if _option_rect(i, options.size()).has_point(p):
			if options[i].has("shrine"):
				_dialog = {"title": "Helgedom", "text": run.shrine(options[i].shrine), "options": [{"label": "VIDARE"}]}
			else:
				_dialog = {}
			return


# --- Layout -----------------------------------------------------------------

func _map_rect() -> Rect2:
	return Rect2(110, 190, size.x - 220, size.y - 300)


## Var rummet ligger: steg från vänster till höger, rummen jämnt fördelade i höjd.
func _room_pos(id: String) -> Vector2:
	var m: RoomMap = run.state.map
	var area := _map_rect()
	var columns := m.steps.size() + 1
	var r := m.room(id)
	if r.is_empty():
		return Vector2(-1000, -1000)
	if r.kind == "end":
		return Vector2(area.end.x, area.get_center().y)
	var row: Array = m.steps[r.step]
	var x := area.position.x + area.size.x * float(r.step) / (columns - 1)
	var y := area.position.y + area.size.y * (float(r.slot) + 0.5) / row.size()
	return Vector2(x, y)


func _start_pos() -> Vector2:
	var area := _map_rect()
	return Vector2(area.position.x - 70, area.get_center().y)


func _macro_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 180, size.y - 66, 180, 48)


func _moments_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 180 - 14 - 260, size.y - 66, 260, 48)


func _dialog_rect() -> Rect2:
	return Rect2(size.x / 2 - 330, size.y / 2 - 150, 660, 300)


func _option_rect(i: int, n: int) -> Rect2:
	var d := _dialog_rect()
	var h := 46.0
	return Rect2(d.position.x + 30, d.end.y - 24 - (n - i) * (h + 8), d.size.x - 60, h)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var state: RunState = run.state
	var m: RoomMap = state.map
	if m == null:
		return
	var z := lerpf(3.2, 1.0, _smooth(_zoom_t))
	var c := size / 2
	draw_set_transform(c - c * z, 0.0, Vector2.ONE * z)
	_draw_paths(m, state)
	for r in m.all_rooms():
		_draw_room(r, state)
	_draw_party_marker(state)
	draw_set_transform(Vector2.ZERO)
	if _zoom_t < 1.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.07, 0.04, (1.0 - _smooth(_zoom_t)) * 0.5))

	var realm: Dictionary = data.realms[state.realm]
	UiStyle.text(self, Vector2(MARGIN, 46), "%s – VÅNING %d/%d · DJUP %d" % [realm.name.to_upper(), state.floor + 1,
			state.floor_ids.size(), state.depth], 26, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT, size.x - 300, 0)
	silver_label()
	var quest := RunState.quest_text(state.quest) + ("  – KLAR!" if state.quest.get("done", false) else "")
	UiStyle.text(self, Vector2(MARGIN, 76), "QUEST: " + quest, 17, Parchment.SEAL, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 0)
	var known: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var hidden := state.active_rules().size() - known.size()
	if not state.active_rules().is_empty():
		UiStyle.text(self, Vector2(MARGIN, 100), "REGLER: %s%s" % [", ".join(known), "" if hidden == 0 else " · %d dolda" % hidden],
				15, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 0)
	_draw_charges(data, state)
	if state.side_index >= 0:
		UiStyle.text(self, Vector2(0, 150), "I PORTALEN – en svårare strid, sedan skatten", 18, Color("#6a3a9a"),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 0)
	if run.room_result != "" and _dialog.is_empty():
		UiStyle.text(self, Vector2(MARGIN, size.y - 36), run.room_result, 16, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 520, 0)
	small_button(_macro_rect(), "MAKRON")
	small_button(_moments_rect(), "RUMSÖGONBLICK: " + ("PÅ" if run.profile.room_moments else "AV"))
	if not _dialog.is_empty():
		_draw_dialog()


func _draw_paths(m: RoomMap, state: RunState) -> void:
	if state.room_id == "":
		for id in m.choices(""):
			_ink_line(_start_pos(), _room_pos(id), true)
	for r in m.all_rooms():
		for nxt in r.next:
			var walked: bool = state.visited.has(r.id) and state.visited.has(nxt)
			_ink_line(_room_pos(r.id), _room_pos(nxt), walked)


## En bläckstig med en liten båge, heldragen om den är gången, annars streckad.
func _ink_line(a: Vector2, b: Vector2, solid: bool) -> void:
	var mid := (a + b) / 2 + (b - a).orthogonal().normalized() * 10.0
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	if solid:
		draw_polyline(pts, Color(Parchment.INK, 0.85), 3.0, true)
	else:
		for i in range(0, pts.size() - 1, 2):
			draw_line(pts[i], pts[i + 1], Parchment.INK_LIGHT, 2.0)


func _draw_room(r: Dictionary, state: RunState) -> void:
	var pos := _room_pos(r.id)
	var kind: String = r.kind
	var color: Color = KIND_COLORS.get(kind, Parchment.INK)
	var visited: bool = state.visited.has(r.id)
	var available: bool = state.choices().has(r.id)
	var radius := ROOM_R * (1.25 if kind == "end" else 1.0)
	if available:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(pos, radius + 10 + 4 * pulse, Color(UiStyle.GOLD, 0.25 + 0.3 * pulse))
	draw_circle(pos, radius, Color(color, 0.35 if visited else 0.85))
	draw_arc(pos, radius, 0, TAU, 32, Parchment.INK, 3.0)
	if kind == "elite" or (kind == "end" and r.get("boss", false)):
		draw_arc(pos, radius + 5, 0, TAU, 32, UiStyle.GOLD, 2.0)
	var mark: String = KIND_MARKS.get(kind, "?")
	if kind == "end" and r.get("boss", false):
		mark = "B"
	UiStyle.text(self, pos + Vector2(-radius, 9), mark, 26, Color(1, 0.96, 0.85, 0.5 if visited else 1.0),
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2, 2)
	var label: String = KIND_NAMES.get(kind, kind)
	if kind == "end" and r.get("boss", false):
		label = "Boss: " + run.data.encounters[r.encounter].name
	UiStyle.text(self, pos + Vector2(-80, radius + 22), label, 14, Parchment.INK, HORIZONTAL_ALIGNMENT_CENTER, 160, 0)
	if r.get("nemesis", false):
		draw_circle(pos + Vector2(radius * 0.8, -radius * 0.8), 12, Parchment.SEAL)
		UiStyle.text(self, pos + Vector2(radius * 0.8 - 12, -radius * 0.8 + 6), "N", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 24, 0)


## Sällskapets plats: en röd sigillmarkör i rummet där det står (eller vid våningens början).
func _draw_party_marker(state: RunState) -> void:
	var pos := _start_pos() if state.room_id == "" else _room_pos(state.room_id)
	var bob := sin(_t * 3.0) * 3.0
	var tip := pos + Vector2(0, -ROOM_R - 6 + bob)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-12, -22), tip + Vector2(12, -22)]), Parchment.SEAL)
	draw_circle(tip + Vector2(0, -24), 12, Parchment.SEAL)


## Charges kvar per hjälte (summa av förmågorna mot fullt).
func _draw_charges(data: Dictionary, state: RunState) -> void:
	var parts: Array = []
	for hero_id in state.party:
		var left := 0
		var full := 0
		for ability_id in state.charges.get(hero_id, {}):
			left += int(state.charges[hero_id][ability_id])
			full += int(data.abilities[ability_id].get("charges", 0))
		if full > 0:
			parts.append("%s %d/%d" % [data.heroes[hero_id].name, left, full])
	UiStyle.text(self, Vector2(MARGIN, 124), "CHARGES: " + " · ".join(parts), 15, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 60, 0)


func _draw_dialog() -> void:
	var d := _dialog_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	draw_rect(d, Color(0.93, 0.85, 0.66))
	draw_rect(d, Parchment.INK, false, 3.0)
	UiStyle.text(self, d.position + Vector2(0, 44), String(_dialog.title).to_upper(), 28, Parchment.INK,
			HORIZONTAL_ALIGNMENT_CENTER, d.size.x, 0)
	draw_multiline_string(UiStyle.bold(), d.position + Vector2(30, 84), _dialog.text, HORIZONTAL_ALIGNMENT_CENTER,
			d.size.x - 60, 18, 3, Parchment.INK)
	var options: Array = _dialog.options
	for i in options.size():
		var r := _option_rect(i, options.size())
		draw_rect(r, Color(0.25, 0.15, 0.08, 0.9))
		draw_rect(r, UiStyle.GOLD, false, 2.0)
		UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + 7), options[i].label, 17, UiStyle.GOLD,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 2)
