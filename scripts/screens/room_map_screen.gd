extends TapScreen
## Grottan (0.27, docs/plan/0.27-grottan.md §1): våningen som ett rutnät 8×8 i tusch på pergament. Bara rutan man står
## på och de man har besökt syns; trappan eller bossen syns från start men är låst tills questen är klar. Ett tryck går ett
## steg; ett tryck på en besökt ruta får pjäsen att gå dit själv. Kliver man på en grupp syns den som ett kort till höger
## (ANFALL eller BACKA); en sedd grupp spärrar rutorna intill sig. Lägereld, skatt, helgedom, fånge och trappa avgörs i en
## ruta ovanpå kartan. Kameran glider ut ur kampanjkartans område när skärmen öppnas (samma pergament).

const ZOOM_TIME := 0.8
## Rutornas namn (symbolerna ritas i tusch av InkArt).
const KIND_NAMES := {"battle": "Fiendegrupp", "elite": "Elitgrupp", "treasure": "Skatt", "shrine": "Helgedom",
		"campfire": "Lägereld", "end": "Boss", "stairs": "Trappa", "item": "Föremål", "prisoner": "Fånge",
		"start": "Ingång", "empty": ""}
## Pjäsen går så här länge per ruta.
const STEP_TIME := 0.16
## Rutor med ett ögonblick (stridsrutor har inget, striden är själv 3D).
const MOMENT_KINDS := ["treasure", "shrine", "campfire", "prisoner"]
const BARK_TIME := 5.0
var parchment: Parchment
var _zoom_t := 0.0
## Rutan ovanpå kartan: {title, text, options: [{label, shrine|action|hint}]} eller tom.
var _dialog := {}
var _shrine_options: Array = []
## 3D-ögonblicket som spelas när sällskapet kommer till en ruta (RoomMoment), eller null.
var _moment: RoomMoment
## Pjäsens gång: rutorna kvar att gå (ruta för ruta) och tiden på det pågående steget (−1 = står still).
var _walk: Array = []
var _walk_from := 0
var _walk_t := -1.0
## 0.24: en replik från sällskapet (Run.pending_bark): rader {who, text}, en i taget, ungefär fem sekunder var.
var _bark: Array = []
var _story: StoryBox
var _bark_t := 0.0
## Ett kort meddelande under rutnätet (låst, spärrat) och hur länge det har synts.
var _toast := ""
var _toast_t := 0.0


func _ready() -> void:
	super()
	parchment = Parchment.new()
	add_child(parchment)
	if run.state.map == null:
		run.go(run.CAMPAIGN_SCENE)
		return
	_walk_from = run.state.pos
	if run.pending_rescue != "":
		_dialog = _rescue_dialog(run.pending_rescue)
		run.pending_rescue = ""
	run.imma_sneaks()  # 0.25.1: Imma ansluter här, efter segerskärmen
	# 0.25: berättelsen först (den första porten, Imma som smiter efter), sedan hjälprutorna för grottan.
	_story = StoryBox.play(self, run.pending_story)
	run.pending_story = []
	if _story:
		await _story.finished
		_story = null
	HelpBox.offer(self, ["room_map", "realm_quest"])
	# Utvecklare: --enter=<sort> lägger en sådan ruta bredvid start och går dit (för att se ögonblicket eller kortet).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--enter="):
			_dev_enter(arg.get_slice("=", 1))


## --enter=<sort>[:möte] (0.27: t.ex. elite:crypt_e5 visar Klockarens kort; striden: --encounter=crypt_e5).
func _dev_enter(arg: String) -> void:
	var parts := arg.split(":")
	var want: String = parts[0]
	var state: RunState = run.state
	var m: Grotto = state.map
	var n: int = Grotto.neighbors(state.pos)[0]
	var cell := {"kind": want}
	if want in ["battle", "elite"]:
		var other := m.group_cells().filter(func(i: int) -> bool: return m.cells[i].kind == "battle")
		cell = m.cells[other[0]].duplicate() if not other.is_empty() else {"kind": "battle", "encounter": state.floor_ids[0]}
		cell.kind = want
		cell.elite = want == "elite"
		if parts.size() > 1:
			cell.encounter = parts[1]
	m.cells[n] = cell
	get_tree().create_timer(0.8).timeout.connect(_go.bind(n))


func _process(delta: float) -> void:
	super(delta)
	if _zoom_t < 1.0:
		_zoom_t = minf(1.0, _zoom_t + delta / ZOOM_TIME)
		parchment.set_view(lerpf(3.2, 1.0, _smooth(_zoom_t)), Vector2(0.5, 0.5))
	if _bark.is_empty() and not run.pending_bark.is_empty() and _dialog.is_empty() and _moment == null and _story == null \
			and _walk_t < 0.0 and _zoom_t >= 1.0:
		_bark = run.pending_bark.lines.duplicate()
		run.pending_bark = {}
		_bark_t = 0.0
	if not _bark.is_empty():
		_bark_t += delta
		if _bark_t >= BARK_TIME:
			_next_bark()
	if _toast != "":
		_toast_t += delta
		if _toast_t > 3.0:
			_toast = ""
	if _walk_t >= 0.0:
		_walk_t += delta / STEP_TIME
		if _walk_t >= 1.0:
			_walk_from = _walk.pop_front()
			_walk_t = 0.0 if not _walk.is_empty() else -1.0
			if _walk.is_empty():
				_arrive()


static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


# --- Inmatning --------------------------------------------------------------

func _tap(p: Vector2) -> void:
	var state: RunState = run.state
	if _moment != null or _walk_t >= 0.0:
		return  # ögonblicket tar själv emot trycket (hoppar över); pjäsen är på väg
	if not _bark.is_empty():
		_next_bark()
		return
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
	if state.at_group():
		if _fight_rect().has_point(p):
			run.fight_here()
			return
		if _back_rect().has_point(p) and state.came_from >= 0:
			_back()
			return
	var i := _cell_at(p)
	if i < 0:
		return
	if i == state.came_from and state.at_group():
		_back()
		return
	var why := state.can_step(i)
	if why == "":
		_go(i)
		return
	_toast = {"locked": "Questen är inte klar – %s är låst." % ("bossen" if state.map.last_floor else "trappan"),
			"blocked": "En grupp spärrar vägen. Besegra den eller gå runt.",
			"group": "Gruppen står i vägen: anfall, eller backa dit ni kom ifrån.",
			"far": "Ett steg i taget – till en ruta bredvid en som ni har sett.",
			"path": "Det finns ingen väg dit genom rutorna ni känner."}.get(why, "")
	_toast_t = 0.0
	if why == "locked" and state.pos == state.map.goal:
		_toast = ""
	run.ui("ui_error", -16.0)


func _back() -> void:
	var from: int = run.state.pos
	run.back_off()
	_walk_from = from
	_walk = [run.state.pos]
	_walk_t = 0.0


## Går till rutan: pjäsen går ruta för ruta, sedan avgörs rutan.
func _go(i: int) -> void:
	var from: int = run.state.pos
	var walk: Array = run.step_to(i)
	if walk.is_empty():
		return
	_walk_from = from
	_walk = walk
	_walk_t = 0.0
	run.ui("ui_page", -16.0)


func _next_bark() -> void:
	_bark.pop_front()
	_bark_t = 0.0


## Pjäsen har kommit fram: rutans innehåll (en grupp visas som kort i panelen; resten som en ruta).
func _arrive() -> void:
	var state: RunState = run.state
	var r := state.current_room()
	if state.at_group():
		run.ui("room_lock", -10.0)
		return
	var kind: String = r.get("kind", "empty")
	var fresh: bool = not r.get("done", false) and not r.get("rescued", false)
	if kind == "stairs" and state.floor_cleared():
		_dialog = {"title": "Trappan", "text": "Questen är klar. Trappan leder ned till våning %d." % (state.floor + 2),
				"options": [{"label": "GÅ NED", "action": "descend"}, {"label": "STANNA KVAR"}]}
		return
	if not kind in ["treasure", "shrine", "campfire", "prisoner"] or (kind != "campfire" and not fresh):
		return
	if run.profile.room_moments and MOMENT_KINDS.has(kind) and fresh and not r.get("seen", false):
		await _play_moment(kind)
	r.seen = true  # 0.27.0: en lägereld man sparar spelar inte ögonblicket igen
	_show_room(r)


## Spelar rutans 3D-ögonblick i Realmens stil och väntar tills det är slut eller hoppas över.
func _play_moment(kind: String) -> void:
	var style := "chapel" if run.state.realm == "chapel" else "crypt"
	_moment = RoomMoment.create(kind, style, Array(run.state.party), run.data)
	add_child(_moment)
	await _moment.finished
	_moment.queue_free()
	_moment = null
	UnitModel.free_shared()


## Rutans händelse som en ruta på kartan.
func _show_room(r: Dictionary) -> void:
	match r.kind:
		"campfire":
			# 0.27.0 (VD): man väljer själv när man vilar, så att lägerelden kan sparas till när den behövs.
			if not r.get("done", false):
				_dialog = {"title": "Lägereld", "text": "Elden sprakar. Att vila ger +%d Charges på varje förmåga, en gång. Troféerna kan ni byta här när som helst." % RunState.CAMPFIRE_CHARGES,
						"options": [{"label": "VILA", "action": "rest"}, {"label": "BYT TROFÉER", "action": "camp"}, {"label": "SENARE"}]}
			else:
				_dialog = {"title": "Lägereld", "text": run.campfire(),
						"options": [{"label": "BYT TROFÉER", "action": "camp"}, {"label": "VIDARE"}]}
			HelpBox.offer(self, ["charges"])  # 0.26.2: om den inte redan visats i en strid
		"treasure":
			_dialog = {"title": "Skatt", "text": run.treasure(), "options": [{"label": "VIDARE"}]}
		"prisoner":
			# 0.23: en lärjunge befrias och ansluter (Siralims "enhörningsögonblick").
			_dialog = _rescue_dialog(run.rescue_prisoner())
		"shrine":
			_shrine_options = run.state.shrine_options(run.data, run.rng)
			var options := []
			for o in _shrine_options:
				options.append({"label": RunState.shrine_text(run.data, o), "shrine": o})
			_dialog = {"title": "Helgedom", "text": "Välj en gåva – eller låt Pandemonium avgöra.", "options": options}


## Befrielsen, och ett förslag på en ny makrorad för den nya sortens hjälte (0.23).
## Rutan visar porträttet och vem hen är (egen egenskap), och förslaget under (0.26.1).
func _rescue_dialog(text: String) -> Dictionary:
	var id: String = run.last_recruit
	var out := {"title": "En fånge befrias", "text": text, "hero": id, "about": rescue_about(run.data, id),
			"options": [{"label": "VÄLKOMMEN!"}]}
	var hint: Dictionary = run.macro_hint(id)
	if not hint.is_empty():
		out.hint = "Ny makrorad? " + String(hint.text)
		out.options = [{"label": "LÄGG TILL RADEN", "hint": id}, {"label": "INTE NU"}]
	return out


## En rad om den befriade: hens egen egenskap och vad den gör.
static func rescue_about(data: Dictionary, hero_id: String) -> String:
	var traits: Array = data.heroes.get(hero_id, {}).get("traits", [])
	if traits.is_empty() or not data.traits.has(traits[0]):
		return ""
	var t: Dictionary = data.traits[traits[0]]
	return "%s: %s" % [t.get("name", traits[0]), t.get("text", "")]


func _tap_dialog(p: Vector2) -> void:
	var options: Array = _dialog.options
	for i in options.size():
		if _option_rect(i, options.size()).has_point(p):
			if options[i].has("hint"):
				run.add_macro_hint(options[i].hint)
			var action: String = options[i].get("action", "")
			if options[i].has("shrine"):
				_dialog = {"title": "Helgedom", "text": run.shrine(options[i].shrine), "options": [{"label": "VIDARE"}]}
				return
			if action == "rest":
				_dialog = {"title": "Lägereld", "text": run.campfire(),
						"options": [{"label": "BYT TROFÉER", "action": "camp"}, {"label": "VIDARE"}]}
				return
			_dialog = {}
			if action == "camp":
				run.open_campfire_camp()
			elif action == "descend":
				run.descend()
				_walk_from = run.state.pos
				HelpBox.offer(self, ["realm_quest"])
			return


# --- Layout -----------------------------------------------------------------

## Rutornas storlek och rutnätets plats (mitt på skärmen, under rubriken).
func _cell_size() -> float:
	return floorf(minf((size.y - 232.0) / Grotto.SIZE, (size.x - 700.0) / Grotto.SIZE))


func _grid_rect() -> Rect2:
	var cs := _cell_size()
	var w := cs * Grotto.SIZE
	return Rect2(floorf((size.x - w) / 2.0) - 60.0, 150.0, w, w)


func _cell_rect(i: int) -> Rect2:
	var g := _grid_rect()
	var cs := _cell_size()
	var p := Grotto.xy(i)
	return Rect2(g.position + Vector2(p.x, p.y) * cs, Vector2(cs, cs))


func _cell_center(i: int) -> Vector2:
	return _cell_rect(i).get_center()


func _cell_at(p: Vector2) -> int:
	var g := _grid_rect()
	if not g.has_point(p):
		return -1
	var cs := _cell_size()
	return Grotto.idx(Vector2i(int((p.x - g.position.x) / cs), int((p.y - g.position.y) / cs)))


## Panelen till höger om rutnätet (gruppens kort, rutans namn).
func _panel_rect() -> Rect2:
	var g := _grid_rect()
	var x := g.end.x + 28.0
	return Rect2(x, 150.0, size.x - MARGIN - x, size.y - 150.0 - 84.0)


func _fight_rect() -> Rect2:
	var p := _panel_rect()
	return Rect2(p.position.x + 16, p.end.y - 116, p.size.x - 32, 52)


func _back_rect() -> Rect2:
	var p := _panel_rect()
	return Rect2(p.position.x + 16, p.end.y - 56, p.size.x - 32, 42)


func _macro_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 180, size.y - 66, 180, 48)


func _moments_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 180 - 14 - 260, size.y - 66, 260, 48)


func _dialog_rect() -> Rect2:
	if _dialog.has("hero"):
		return Rect2(size.x / 2 - 380, size.y / 2 - 210, 760, 420)  # befrielsen: porträtt, egenskap och makroförslag
	return Rect2(size.x / 2 - 330, size.y / 2 - 150, 660, 300)


func _option_rect(i: int, n: int) -> Rect2:
	var d := _dialog_rect()
	var h := 46.0
	return Rect2(d.position.x + 30, d.end.y - 24 - (n - i) * (h + 8), d.size.x - 60, h)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var state: RunState = run.state
	var m: Grotto = state.map
	if m == null:
		return
	var z := lerpf(3.2, 1.0, _smooth(_zoom_t))
	var c := size / 2
	draw_set_transform(c - c * z, 0.0, Vector2.ONE * z)
	_draw_decor(state)
	_draw_grid(m, state)
	InkArt.icon(self, "paladin", _piece_pos() + Vector2(0, -_cell_size() * 0.18 + sin(_t * 3.0) * 1.5), _cell_size() * 1.05)
	draw_set_transform(Vector2.ZERO)
	if _zoom_t < 1.0:
		# Bilden av området (samma som kampanjkartan tonade fram) tonar bort medan kameran zoomar ut.
		var a := clampf(1.0 - _zoom_t * 1.25, 0.0, 1.0)
		var img: Texture2D = load("res://assets/illustrations/%s.webp" % data.realms[state.realm].map.zoom_image)
		var h := size.x * img.get_height() / img.get_width()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.86, 0.68, a))
		draw_texture_rect(img, Rect2(0, (size.y - h) / 2, size.x, h), false, Color(1, 1, 1, a))
	var realm: Dictionary = data.realms[state.realm]
	InkArt.cartouche(self, Rect2(MARGIN + 14, 16, 460, 46), "%s · DJUP %d" % [realm.name.to_upper(), state.depth], InkArt.INK, 20)
	InkArt.floor_markers(self, Vector2(MARGIN + 520, 47), state.floor, RunState.FLOORS_PER_RUN, InkArt.INK, 20)
	silver_label()
	var quest := RunState.quest_text(state.quest) + ("  – KLAR!" if state.quest.get("done", false) else "")
	var lock := "  · %s är öppen" % ("bossen" if m.last_floor else "trappan") if state.quest.get("done", false) \
			else "  · öppnar %s" % ("bossen" if m.last_floor else "trappan")  # 0.27.2: "låser" lät som att questen låste
	UiStyle.text(self, Vector2(MARGIN, 88), "QUEST: " + quest + lock, 17, Parchment.SEAL, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 420, 0)
	var known: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var hidden := state.active_rules().size() - known.size()
	if not state.active_rules().is_empty():
		UiStyle.text(self, Vector2(MARGIN, 110), "REGLER: %s%s" % [", ".join(known), "" if hidden == 0 else " · %d dolda" % hidden],
				15, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 0)
	_draw_charges(data, state)
	_draw_found(data, state)
	_draw_panel(data, state)
	var msg: String = _toast if _toast != "" else run.room_result
	if msg != "" and _dialog.is_empty():
		UiStyle.para(self, Vector2(_grid_rect().position.x, size.y - 50), msg, 16, Parchment.INK,
				_moments_rect().position.x - _grid_rect().position.x - 20, 2)
	small_button(_macro_rect(), "MAKRON")
	small_button(_moments_rect(), "RUMSÖGONBLICK: " + ("PÅ" if run.profile.room_moments else "AV"))
	if not _dialog.is_empty():
		_draw_dialog()
	if not _bark.is_empty():
		var l: Dictionary = _bark[0]
		DialogBox.box(self, run.data, size, l.who, Dialog.fill(l.text, run.profile.hero_name), _t, true, 124.0)


## Var pjäsen står: på sin ruta, eller på väg mellan två.
func _piece_pos() -> Vector2:
	if _walk_t >= 0.0 and not _walk.is_empty():
		return _cell_center(_walk_from).lerp(_cell_center(_walk[0]), _smooth(_walk_t))
	return _cell_center(run.state.pos if _walk.is_empty() else _walk_from)


## Dekor bara i marginalen: kompassros nere till vänster, Realmens figur och ett svärd i sten.
func _draw_decor(state: RunState) -> void:
	var ink := Color(InkArt.INK, 0.55)
	InkArt.icon(self, "compass", Vector2(68, size.y - 70), 104, 0.75)
	var figure := Vector2(170, size.y - 70)
	if state.realm == "chapel":
		InkArt.witch(self, figure, 56, ink)
	else:
		InkArt.icon(self, "skeleton", figure + Vector2(0, -6), 118, 0.75)
	InkArt.icon(self, "sword_in_stone", Vector2(262, size.y - 62), 112, 0.7)


## Rutnätet: dimman över det okända, de besökta rutorna i bläck, målet alltid synligt, spärrade rutor streckade och
## rutorna man kan gå till med en pulserande guldkant.
func _draw_grid(m: Grotto, state: RunState) -> void:
	var g := _grid_rect()
	var cs := _cell_size()
	draw_rect(g.grow(6), Color(InkArt.INK, 0.10))
	for i in Grotto.SIZE * Grotto.SIZE:
		var r := _cell_rect(i).grow(-2)
		var known: bool = state.visited.has(i) or i == m.goal
		if known:
			draw_rect(r, Color(0.96, 0.9, 0.74, 0.85))
		else:
			draw_rect(r, Color(0.42, 0.33, 0.22, 0.22))  # dimma
		draw_rect(r, Color(InkArt.INK, 0.28 if known else 0.12), false, 1.5)
		if not known and m.blocked(i, state.visited, state.seen):
			for k in 4:
				var o := cs * (0.2 + 0.2 * k)
				draw_line(r.position + Vector2(o, 0), r.position + Vector2(0, o), Color(Parchment.SEAL, 0.35), 1.5)
				draw_line(r.end - Vector2(o, 0), r.end - Vector2(0, o), Color(Parchment.SEAL, 0.35), 1.5)
	# Var man kan gå härnäst.
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	if _walk_t < 0.0 and _dialog.is_empty():
		for n in Grotto.neighbors(state.pos):
			if state.can_step(n) == "" and (not state.visited.has(n) or n == state.came_from):
				var r := _cell_rect(n).grow(-5)
				draw_rect(r, Color(UiStyle.GOLD.darkened(0.2), 0.45 + 0.4 * pulse), false, 3.0)
	for i in Grotto.SIZE * Grotto.SIZE:
		if state.visited.has(i) or i == m.goal:
			_draw_cell(m, state, i)


func _draw_cell(m: Grotto, state: RunState, i: int) -> void:
	var c := m.cell(i)
	var at := _cell_center(i)
	var cs := _cell_size()
	var kind: String = c.get("kind", "empty")
	var group := m.has_group(i)
	var used: bool = c.get("done", false) or c.get("rescued", false) or (c.has("encounter") and c.get("beaten", false) \
			and kind in ["battle", "elite"])
	var alpha := 0.38 if used else 1.0
	match kind:
		"start":
			InkArt.ring(self, at, cs * 0.2, Color(InkArt.INK, 0.5), 2.0)
		"stairs":
			_draw_stairs(at, cs * 0.62, Color(InkArt.INK, 1.0))
		"end":
			InkArt.icon(self, "boss", at, cs * 1.0, 1.0 if not c.get("beaten", false) else 0.4)
		"item":
			_draw_item(at, cs * 0.36, Color(Parchment.SEAL, alpha))
		"battle", "elite", "treasure", "shrine", "campfire", "prisoner":
			InkArt.room_icon(self, kind, at, cs * 0.92, alpha)
	if group and kind in ["treasure", "item", "prisoner"]:
		InkArt.room_icon(self, "battle", at + Vector2(cs * 0.24, -cs * 0.24), cs * 0.5, 1.0)  # en grupp vaktar rutan
	if group and state.seen.has(i) and i != state.pos:
		InkArt.ring(self, at, cs * 0.44, Color(Parchment.SEAL, 0.7), 2.2)
	if c.get("nemesis", false) and group:
		draw_circle(at + Vector2(cs * 0.32, -cs * 0.32), 10, Parchment.SEAL)
		UiStyle.text(self, at + Vector2(cs * 0.32 - 12, -cs * 0.32 + 6), "N", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 24, 0)
	if kind == "prisoner" and not c.get("rescued", false):
		draw_circle(at, cs * 0.46, Color(1.0, 0.85, 0.4, 0.16 + 0.08 * sin(_t * 3.0)))
	if i == m.goal and state.goal_locked():
		_draw_lock(at + Vector2(cs * 0.3, cs * 0.28), cs * 0.2)


## En trappa i tusch: steg som går ned åt höger.
func _draw_stairs(c: Vector2, s: float, color: Color) -> void:
	var x0 := c.x - s / 2
	var y0 := c.y - s / 2
	var n := 4
	for k in n:
		var x := x0 + s * k / n
		var y := y0 + s * k / n
		draw_line(Vector2(x, y), Vector2(x + s / n, y), color, 2.4)
		draw_line(Vector2(x + s / n, y), Vector2(x + s / n, y + s / n), color, 2.4)
	draw_line(Vector2(x0, y0), Vector2(x0, c.y + s / 2), Color(color, 0.6), 1.8)


## Ett quest-föremål: en slipad sten i tusch.
func _draw_item(c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, r),
			c + Vector2(-r * 0.8, -r * 0.2)])
	draw_colored_polygon(pts, Color(color, 0.25))
	pts.append(pts[0])
	draw_polyline(pts, color, 2.2, true)
	draw_line(c + Vector2(-r * 0.8, -r * 0.2), c + Vector2(r * 0.8, -r * 0.2), Color(color, 0.7), 1.5)


## Ett hänglås (målet är låst tills questen är klar).
func _draw_lock(c: Vector2, s: float) -> void:
	var body := Rect2(c - Vector2(s * 0.6, s * 0.1), Vector2(s * 1.2, s))
	draw_arc(c + Vector2(0, -s * 0.1), s * 0.42, PI, TAU, 12, Parchment.SEAL, 2.4)
	draw_rect(body, Color(0.96, 0.9, 0.74))
	draw_rect(body, Parchment.SEAL, false, 2.4)


## Panelen: gruppens kort när man står på en grupp, annars rutans namn och vad man ser.
func _draw_panel(data: Dictionary, state: RunState) -> void:
	var p := _panel_rect()
	var r := state.current_room()
	var x := p.position.x + 16
	var w := p.size.x - 32
	var y := p.position.y + 34
	if not state.at_group():
		var name: String = KIND_NAMES.get(r.get("kind", "empty"), "")
		if r.get("kind", "") == "prisoner" and r.has("hero"):
			name = "Fånge: " + String(data.heroes[r.hero].get("short", data.heroes[r.hero].name))
		UiStyle.text(self, Vector2(x, y), name.to_upper() if name != "" else "TOM RUTA", 18, InkArt.INK,
				HORIZONTAL_ALIGNMENT_LEFT, w, 0)
		var hint := "Tryck på en ruta bredvid för att gå dit. En besökt ruta går pjäsen till själv."
		if state.goal_locked():
			hint += " %s syns men är låst tills questen är klar." % ("Bossen" if state.map.last_floor else "Trappan")
		UiStyle.para(self, Vector2(x, y + 28), hint, 16, Color(InkArt.INK, 0.8), w, 6)
		return
	# Gruppens kort (plan: fiender, storlek, egenskaper, möjlig trofé och för en elit en varning).
	draw_rect(p, Color(0.93, 0.85, 0.66, 0.92))
	draw_rect(p, Parchment.INK, false, 3.0)
	var enc: Dictionary = data.encounters[r.encounter]
	var title := "ELITGRUPP" if r.get("elite", false) else ("BOSS" if r.get("boss", false) else "FIENDEGRUPP")
	if r.get("nemesis", false):
		title = "NEMESIS"
	UiStyle.text(self, Vector2(x, y), title, 22, Parchment.SEAL if title != "FIENDEGRUPP" else InkArt.INK,
			HORIZONTAL_ALIGNMENT_LEFT, w, 0)
	y += 12
	var guards: String = {"treasure": "Vaktar en skatt.", "item": "Vaktar ett av questens föremål.",
			"prisoner": "Vaktar en fånge."}.get(r.kind, "")
	var kinds := CombatSim.enemy_lineup(data, enc.enemies, state.party.size())
	var count := {}
	for k in kinds:
		count[k] = int(count.get(k, 0)) + 1
	var names: Array = count.keys().map(func(k: String) -> String:
		return data.enemies[k].name + (" ×%d" % count[k] if count[k] > 1 else ""))
	var lines: Array[String] = ["%d fiender: %s" % [kinds.size(), ", ".join(names)]]
	if guards != "":
		lines.append(guards)
	var traits: Array = []
	var trophies: Array = []
	for k in count:
		for t in data.enemies[k].get("traits", []):
			var td: Dictionary = data.traits.get(t, {})
			if not td.get("hidden", false) and td.has("name") and not traits.has(td.name):
				traits.append(td.name)
		var tr: String = data.enemies[k].get("trophy", "")
		if tr != "" and data.traits.has(tr) and not trophies.has(data.traits[tr].name) and not data.enemies[k].get("boss", false):
			trophies.append(data.traits[tr].name)
	if not traits.is_empty():
		lines.append("Egenskaper: " + ", ".join(traits))
	if not trophies.is_empty():
		lines.append("Kan lämna: " + ", ".join(trophies))
	if r.get("elite", false) or r.get("nemesis", false):
		lines.append("Varning: en elitfiende är starkare än vanligt och har en egen regelbrytande egenskap. Backa och byt makro, eller troféer vid en lägereld, om det behövs.")
	# 0.27: elitens motdrag (Siralims counters) på en rad, t.ex. "Klockaren: ni får bara väcka döda en gång per strid".
	var c_opts := {"counter": r.get("elite", false) or r.get("nemesis", false) or r.get("boss", false),
			"force_elites": 1 if r.get("elite", false) or r.get("nemesis", false) else 0}
	var counter := CombatSim.counter_for(data, r.encounter, state.depth, c_opts, state.party.size())
	if not counter.is_empty():
		var who: Dictionary = data.enemies[counter.kind]
		var who_name: String = who.name
		if who.get("elite", {}).get("counter", {}).get("trait", "") == counter.trait:
			who_name = who.elite.name
		var td: Dictionary = data.traits[counter.trait]
		lines.append("%s: %s." % [who_name, td.get("card", td.get("text", ""))])
	y += 22
	for l in lines:
		y += UiStyle.para(self, Vector2(x, y), l, 16, Parchment.INK, w, 4) + 6
	UiStyle.big_button(self, _fight_rect(), "ANFALL", _t)
	small_button(_back_rect(), "BACKA")


func _draw_dialog() -> void:
	var d := _dialog_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	draw_rect(d, Color(0.93, 0.85, 0.66))
	draw_rect(d, Parchment.INK, false, 3.0)
	UiStyle.text(self, d.position + Vector2(0, 44), String(_dialog.title).to_upper(), 28, Parchment.INK,
			HORIZONTAL_ALIGNMENT_CENTER, d.size.x, 0)
	if _dialog.has("hero"):
		var pr := Rect2(d.position + Vector2(30, 70), Vector2(120, 140))
		DialogBox.portrait(self, run.data, String(_dialog.hero), pr)
		var x := pr.end.x + 24
		var w := d.end.x - 30 - x
		var y := d.position.y + 88
		y += UiStyle.para(self, Vector2(x, y), _dialog.text, 18, Parchment.INK, w, 3) + 8
		if String(_dialog.about) != "":
			y += UiStyle.para(self, Vector2(x, y), _dialog.about, 16, Color(Parchment.INK, 0.8), w, 4) + 8
		if _dialog.has("hint"):
			UiStyle.para(self, Vector2(x, y), _dialog.hint, 16, Parchment.INK, w, 5)
	else:
		draw_multiline_string(UiStyle.bold(), d.position + Vector2(30, 84), _dialog.text, HORIZONTAL_ALIGNMENT_CENTER,
				d.size.x - 60, 20, 3, Parchment.INK)
	var options: Array = _dialog.options
	for i in options.size():
		var r := _option_rect(i, options.size())
		draw_rect(r, Color(0.25, 0.15, 0.08, 0.9))
		draw_rect(r, UiStyle.GOLD, false, 2.0)
		UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + 7), options[i].label, 17, UiStyle.GOLD,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 2)


## Fynden i körningen (0.20) uppe till höger, och om det här djupet ger trick och Nether Stones.
func _draw_found(data: Dictionary, state: RunState) -> void:
	var x := size.x - MARGIN - 330
	var y := 92.0
	UiStyle.text(self, Vector2(x, y), "FYND", 14, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT, 60, 0)
	var items := [["amber", "amber_red", Color("#c8862a")], ["trick", "whetstone", Color("#8a8070")],
			["nether", "", Color("#ff8a2a")]]
	for i in items.size():
		var c := Vector2(x + 70 + i * 86, y - 6)
		GemArt.draw(self, items[i][0], c, 9.0, items[i][2], 0.4 if items[i][0] == "nether" else 0.0, _t)
		UiStyle.text(self, c + Vector2(16, 6), str(int(state.found.get(items[i][0], 0))), 16, Parchment.INK,
				HORIZONTAL_ALIGNMENT_LEFT, 60, 0)
	if state.depth <= run.profile.best_depth:
		UiStyle.text(self, Vector2(x - 120, y + 22), "Inte ditt djupaste djup – här finns bara bärnsten", 13,
				Parchment.SEAL, HORIZONTAL_ALIGNMENT_RIGHT, 450, 0)


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
	UiStyle.text(self, Vector2(MARGIN, 134), "CHARGES: " + " · ".join(parts), 18, Parchment.INK, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 60, 0)
