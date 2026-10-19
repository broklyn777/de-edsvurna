extends TapScreen
## Rumskartan (0.18): våningen på pergament, steg för steg från vänster till höger med stigar mellan
## rummen och våningens slut längst till höger. Rummen man kan gå till pulserar; tryck för att gå in.
## Strider går till striden; lägereld, skattkammare och helgedom avgörs här i en ruta ovanpå kartan.
## Kameran glider ut ur kampanjkartans område när skärmen öppnas (samma pergament).

const ZOOM_TIME := 0.8
const ROOM_R := 32.0
## Rumstypernas namn (symbolerna ritas i tusch av InkArt).
const KIND_NAMES := {"battle": "Strid", "elite": "Elit", "treasure": "Skattkammare", "shrine": "Helgedom",
		"campfire": "Lägereld", "portal": "Portal", "end": "Våningens slut", "portal_battle": "Portalens strid"}
## Rum som går att gå till ritas i bläck, de andra blekt som torkat bläck.
const FADED := 0.32
## Paladinpjäsen glider längs stigen till rummet innan man går in.
const MOVE_TIME := 0.6
var parchment: Parchment
var _zoom_t := 0.0
## Rutan ovanpå kartan: {title, text, options: [{label, shrine}]} eller tom.
var _dialog := {}
var _shrine_options: Array = []
## 3D-ögonblicket som spelas när sällskapet går in i ett rum (RoomMoment), eller null.
var _moment: RoomMoment
## Pjäsens glidning: från, till och tid (−1 = står still).
var _move_from := Vector2.ZERO
var _move_to := Vector2.ZERO
var _move_t := -1.0
var _move_id := ""
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
	if _move_t >= 0.0:
		_move_t += delta / MOVE_TIME
		if _move_t >= 1.0:
			_move_t = -1.0
			_enter(_move_id)


static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


# --- Inmatning --------------------------------------------------------------

func _tap(p: Vector2) -> void:
	var state: RunState = run.state
	if _moment != null or _move_t >= 0.0:
		return  # ögonblicket tar själv emot trycket (hoppar över); pjäsen är på väg
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
			# Pjäsen glider längs stigen, sedan går sällskapet in.
			_move_from = _piece_pos()
			_move_to = _room_pos(id)
			_move_id = id
			_move_t = 0.0
			run.ui("ui_page", -14.0)
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
	_draw_decor(state)
	_draw_paths(m, state)
	for r in m.all_rooms():
		_draw_room(r, state)
	var lift := 0.0 if state.room_id == "" and _move_t < 0.0 else -ROOM_R - 30.0
	InkArt.icon(self, "paladin", _piece_pos() + Vector2(0, lift + sin(_t * 3.0) * 2.0), 74)
	draw_set_transform(Vector2.ZERO)
	if _zoom_t < 1.0:
		# Bilden av området (samma som kampanjkartan tonade fram) tonar bort medan kameran zoomar ut.
		var a := clampf(1.0 - _zoom_t * 1.25, 0.0, 1.0)
		var img: Texture2D = load("res://assets/illustrations/%s.webp" % data.realms[state.realm].map.zoom_image)
		var h := size.x * img.get_height() / img.get_width()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.86, 0.68, a))
		draw_texture_rect(img, Rect2(0, (size.y - h) / 2, size.x, h), false, Color(1, 1, 1, a))

	var realm: Dictionary = data.realms[state.realm]
	InkArt.cartouche(self, Rect2(MARGIN + 14, 16, 560, 46), "%s · VÅNING %d/%d · DJUP %d" % [realm.name.to_upper(),
			state.floor + 1, state.floor_ids.size(), state.depth], InkArt.INK, 20)
	silver_label()
	var quest := RunState.quest_text(state.quest) + ("  – KLAR!" if state.quest.get("done", false) else "")
	UiStyle.text(self, Vector2(MARGIN, 88), "QUEST: " + quest, 17, Parchment.SEAL, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 0)
	var known: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var hidden := state.active_rules().size() - known.size()
	if not state.active_rules().is_empty():
		UiStyle.text(self, Vector2(MARGIN, 110), "REGLER: %s%s" % [", ".join(known), "" if hidden == 0 else " · %d dolda" % hidden],
				15, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 0)
	_draw_charges(data, state)
	if state.side_index >= 0:
		UiStyle.text(self, Vector2(0, 160), "I PORTALEN – en svårare strid, sedan skatten", 18, Color("#6a3a9a"),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 0)
	if run.room_result != "" and _dialog.is_empty():
		UiStyle.text(self, Vector2(MARGIN + 150, size.y - 30), run.room_result, 16, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 670, 0)
	small_button(_macro_rect(), "MAKRON")
	small_button(_moments_rect(), "RUMSÖGONBLICK: " + ("PÅ" if run.profile.room_moments else "AV"))
	if not _dialog.is_empty():
		_draw_dialog()


## Var pjäsen står: vid våningens början, i rummet, eller på väg längs stigen.
func _piece_pos() -> Vector2:
	if _move_t >= 0.0:
		var t := _smooth(_move_t)
		var normal := (_move_to - _move_from).orthogonal().normalized()
		return _move_from.lerp(_move_to, t) + normal * sin(t * PI) * 10.0
	var state: RunState = run.state
	return _start_pos() if state.room_id == "" else _room_pos(state.room_id)


## Dekor bara i marginalen (aldrig mellan stigarna): kompassros nere till vänster, Realmens figur
## (skelett vid kryptan, häxa vid kapellet) och ett svärd i sten i nederkanten.
func _draw_decor(state: RunState) -> void:
	var ink := Color(InkArt.INK, 0.55)
	InkArt.icon(self, "compass", Vector2(68, size.y - 70), 104, 0.75)
	var figure := Vector2(170, size.y - 70)
	if state.realm == "chapel":
		InkArt.witch(self, figure, 56, ink)
	else:
		InkArt.skeleton(self, figure, 56, ink)
	InkArt.icon(self, "sword_in_stone", Vector2(262, size.y - 62), 112, 0.7)


func _draw_paths(m: RoomMap, state: RunState) -> void:
	var choices := state.choices()
	if state.room_id == "":
		for id in m.choices(""):
			InkArt.path(self, _start_pos(), _room_pos(id), Color(InkArt.INK, 0.8), false)
	for r in m.all_rooms():
		for nxt in r.next:
			var walked: bool = state.visited.has(r.id) and state.visited.has(nxt)
			var open: bool = r.id == state.room_id and choices.has(nxt)
			var alpha := 0.9 if walked or open else FADED
			InkArt.path(self, _room_pos(r.id), _room_pos(nxt), Color(InkArt.INK, alpha), walked)


## Rummet som en liten tuschsymbol. Rum man kan gå till får en pulserande guldring och en tydlig
## tryckyta; rum man inte nått är bleka.
func _draw_room(r: Dictionary, state: RunState) -> void:
	var pos := _room_pos(r.id)
	var kind: String = r.kind
	var visited: bool = state.visited.has(r.id)
	var available: bool = state.choices().has(r.id)
	var boss: bool = r.get("boss", false)
	var alpha := 1.0 if available or r.id == state.room_id else (0.55 if visited else FADED)
	if available:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(pos, ROOM_R + 6, Color(0.95, 0.86, 0.6, 0.55))
		InkArt.ring(self, pos, ROOM_R + 6 + 3 * pulse, Color(UiStyle.GOLD.darkened(0.25), 0.6 + 0.4 * pulse), 3.0)
	InkArt.room_icon(self, kind, pos, 104.0 if kind == "end" else 86.0, alpha, boss)
	var label: String = KIND_NAMES.get(kind, kind)
	if kind == "end" and boss:
		label = "Boss: " + run.data.encounters[r.encounter].name
	UiStyle.text(self, pos + Vector2(-90, ROOM_R + 34), label, 14, Color(InkArt.INK, maxf(alpha, 0.5)),
			HORIZONTAL_ALIGNMENT_CENTER, 180, 0)
	if r.get("nemesis", false):
		draw_circle(pos + Vector2(ROOM_R * 0.9, -ROOM_R * 0.8), 12, Color(Parchment.SEAL, maxf(alpha, 0.6)))
		UiStyle.text(self, pos + Vector2(ROOM_R * 0.9 - 12, -ROOM_R * 0.8 + 6), "N", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 24, 0)


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
	UiStyle.text(self, Vector2(MARGIN, 132), "CHARGES: " + " · ".join(parts), 15, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT,
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
