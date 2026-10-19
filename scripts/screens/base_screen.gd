extends TapScreen
## Borgen (0.23, Siralims slott): en borggård i 3D med stationerna runt om. Tryck på en station så går paladinen
## dit (ungefär en sekund) och öppnar den; dubbeltryck hoppar över gången. Hela borgen syns på en skärm, namnen står
## över stationerna, och den som har något nytt (eller introts aktuella uppdrag) lyser. Kortraden längst ned är en
## genväg. Sällskapet står vid värdshuset; tryck på en hjälte för hjältebladet. Under introduktionen (Intro) visar
## ett hörn aktuellt uppdrag, och stationer som inte är aktuella svarar med en replik i stället för att öppnas.

const PLACES := [
	{"id": "gate", "name": "Porten", "tag": "Kampanjkartan"},
	{"id": "practice", "name": "Övningsgården", "tag": "Arena"},
	{"id": "altar", "name": "Kallets altare", "tag": "Kall och perks"},
	{"id": "smith", "name": "Smeden", "tag": "Artefakter"},
	{"id": "macros", "name": "Makron", "tag": "Krigsbordet"},
	{"id": "inn", "name": "Värdshuset", "tag": "Följeslagarna"},
	{"id": "library", "name": "Biblioteket", "tag": "Troféer"},
]
const WALK_TIME := 1.0
const DOUBLE_TAP_MS := 350

var world: CastleWorld
var paladin: UnitModel
var _figures := {}  # id -> UnitModel (sällskapet och borgens folk)
var _walking_to := ""
var _walk_left := 0.0
var _last_tap_ms := -1000
var _last_tap_station := ""
## Introts dialog: talare, rader och om slutet avslutar ett samtalssteg.
var _speaker := ""
var _lines: Array = []
var _line_i := 0
var _talk_step := false
var _reply := ""
var _reply_t := 0.0


func _ready() -> void:
	super()
	world = CastleWorld.new()
	add_child(world)
	_build_people()
	_start_intro_dialog()


func _build_people() -> void:
	var data: Dictionary = run.data
	paladin = _figure("paladin", data.heroes.paladin.visual, CastleWorld.HOME)
	# Sällskapet står vid värdshuset.
	var spots := [Vector3(4.4, 0, -0.9), Vector3(5.2, 0, -0.4), Vector3(3.8, 0, -0.3)]
	var party: Array = run.profile.party.slice(1)
	for i in mini(party.size(), spots.size()):
		var m := _figure(party[i], data.heroes[party[i]].visual, spots[i])
		m.face(CastleWorld.HOME)
	# Mäster Gorm vid altaret (platshållare: Alvas kåpa i grått).
	var gorm := _figure("gorm", {"model": "alva", "anims_from": ["sigrun_delar"], "hide": ["Ako_Staff"],
			"colors": {"Ako_Robe": "#6a6258", "Ako_Cord": "#c8a050", "Ako_Gold": "#c8a050"},
			"anims": data.heroes.alva.visual.anims}, Vector3(-3.6, 0, -2.0))
	gorm.face(CastleWorld.HOME)
	# Imma väntar vid övningsgården tills hon följer med (introts steg 6).
	if not run.profile.recruited.has("imma"):
		var imma := _figure("imma", data.heroes.imma.visual, Vector3(-4.2, 0, 1.8))
		imma.face(CastleWorld.HOME)
		imma.visible = Intro.current(data, run.profile).get("id", "") in ["imma", "bells"]


func _figure(id: String, vis: Dictionary, at: Vector3) -> UnitModel:
	var d: Dictionary = run.data.heroes.get(id, {"name": id, "stats": {"health": 1}})
	var u := CombatUnit.from_data(id, d, 0)
	var m := UnitModel.new()
	world.add_child(m)
	m.setup(u, null, vis)
	m.position = at
	_figures[id] = m
	return m


func _process(delta: float) -> void:
	super(delta)
	_reply_t = maxf(0.0, _reply_t - delta)
	if _walking_to != "":
		_walk_left -= delta
		if _walk_left <= 0.0:
			_open(_walking_to)
	for p in PLACES:
		world.set_glow(p.id, _glows(p.id))


# --- Introduktionen ----------------------------------------------------------

func _start_intro_dialog() -> void:
	if run.profile.intro_done:
		if not run.intro_lines.is_empty():
			_show(run.intro_lines.speaker, run.intro_lines.lines, false)
			run.intro_lines = {}
		return
	var step := Intro.current(run.data, run.profile)
	if not run.intro_lines.is_empty():
		_show(run.intro_lines.speaker, run.intro_lines.lines, step.get("station", "") == "base")
		run.intro_lines = {}
	elif step.get("station", "") == "base" or run.profile.intro_step == 0:
		_show(step.get("speaker", ""), step.get("lines", []), step.get("station", "") == "base")


func _show(speaker: String, lines: Array, talk: bool) -> void:
	_speaker = speaker
	_lines = lines
	_line_i = 0
	_talk_step = talk


func _advance_dialog() -> void:
	_line_i += 1
	if _line_i < _lines.size():
		run.ui_tap()
		return
	_lines = []
	if _talk_step:
		run.intro("talked")
		if _figures.has("imma") and run.profile.recruited.has("imma"):
			_figures.imma.move_to(Vector3(4.4, 0, -0.9), 1.2, true)
		_start_intro_dialog()


# --- Inmatning ---------------------------------------------------------------

func _tap(p: Vector2) -> void:
	if not _lines.is_empty():
		_advance_dialog()
		return
	# 0.23.1: tillbaka till sparplatserna (profilerna).
	if back_rect().has_point(p):
		run._save()
		run.go(run.SLOTS_SCENE)
		return
	var station := _station_at(p)
	if station != "":
		_go(station)
		return
	for id in _figures:
		if id in ["gorm", "paladin"] or not run.data.heroes.has(id) or not run.profile.recruited.has(id):
			continue
		if world.project(_figures[id].head_position()).distance_to(p) < 60.0:
			run.open_sheet(id, run.profile.party, run.BASE_SCENE)
			return
	if world.project(paladin.head_position()).distance_to(p) < 60.0:
		run.open_sheet("paladin", run.profile.party, run.BASE_SCENE)


## Stationen under fingret: nära namnet eller själva stationen, eller i kortraden.
func _station_at(p: Vector2) -> String:
	for i in PLACES.size():
		if _chip_rect(i).has_point(p):
			return PLACES[i].id
	for pl in PLACES:
		var base_pos: Vector3 = CastleWorld.STATIONS[pl.id]
		if world.project(base_pos + Vector3(0, 2.6, 0)).distance_to(p) < 80.0 or world.project(base_pos).distance_to(p) < 80.0:
			return pl.id
	return ""


func _go(station: String) -> void:
	var state := Intro.station_state(run.data, run.profile, station)
	if state == "locked":
		_reply = Intro.reply(run.data, station)
		_reply_t = 3.0
		run.ui("ui_error", -12.0)
		return
	var now := Time.get_ticks_msec()
	var double: bool = now - _last_tap_ms < DOUBLE_TAP_MS and _last_tap_station == station
	_last_tap_ms = now
	_last_tap_station = station
	if double or _walking_to == station:
		_open(station)  # dubbeltryck (eller tryck igen under gången) hoppar över gången
		return
	_walking_to = station
	_walk_left = WALK_TIME
	paladin.move_to(world.stand_at(station), WALK_TIME, false)
	run.ui_tap()


func _open(station: String) -> void:
	_walking_to = ""
	match station:
		"gate":
			run.go(run.CAMPAIGN_SCENE)
		"practice":
			run.go(run.PRACTICE_SCENE)
		"altar":
			run.go(run.ALTAR_SCENE)
		"smith":
			run.go(run.SMITH_SCENE)
		"macros":
			run.open_macros(run.BASE_SCENE)
		"library":
			run.go(run.LIBRARY_SCENE)
		"inn":
			run.profile.inn_seen = run.profile.recruited.size()
			run.go(run.INN_SCENE)


## Lyser stationen? Introts aktuella uppdrag, Värdshuset när någon ny har kommit, Smeden när ett material kan sättas in.
func _glows(station: String) -> bool:
	if Intro.station_state(run.data, run.profile, station) == "current":
		return true
	if not run.profile.intro_done:
		return false
	match station:
		"inn":
			return run.profile.recruited.size() > run.profile.inn_seen
		"smith":
			return _smith_has_news()
	return false


func _smith_has_news() -> bool:
	var amber := 0
	var tricks := 0
	for id in run.profile.materials:
		if run.data.materials.amber.has(id):
			amber = maxi(amber, int(run.profile.materials[id]))
		else:
			tricks += int(run.profile.materials[id])
	for hero_id in run.profile.artifacts:
		var a: Dictionary = run.profile.artifact(hero_id)
		for i in Forge.STAT_SLOT_LEVELS.size():
			if Forge.stat_slot_open(int(a.level), i) and a.stat_slots[i] == "" and amber >= Forge.AMBER_PER_SLOT:
				return true
		for i in Forge.TRICK_SLOT_LEVELS.size():
			if Forge.trick_slot_open(int(a.level), i) and a.trick_slots[i] == "" and tricks > 0:
				return true
	return false


# --- Ritning -----------------------------------------------------------------

func _chip_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * (PLACES.size() - 1)) / PLACES.size()
	return Rect2(MARGIN + i * (w + GAP), size.y - 58, w, 46)


func _draw() -> void:
	var data: Dictionary = run.data
	silver_label()
	small_button(back_rect(), "‹ PROFILER")
	# Namnen över stationerna.
	for pl in PLACES:
		var state := Intro.station_state(data, run.profile, pl.id)
		var pos := world.project(CastleWorld.STATIONS[pl.id] + Vector3(0, 2.6, 0))
		var col := UiStyle.GOLD if state == "current" else (Color.WHITE if state == "open" else Color(1, 1, 1, 0.45))
		UiStyle.text(self, pos + Vector2(-110, 0), pl.name + ("  !" if _glows(pl.id) else ""), 19, col, HORIZONTAL_ALIGNMENT_CENTER, 220, 5)
		UiStyle.text(self, pos + Vector2(-110, 20), pl.tag, 15, Color(col, col.a * 0.75), HORIZONTAL_ALIGNMENT_CENTER, 220, 4)
	# Kortraden: genvägar till stationerna.
	for i in PLACES.size():
		var r := _chip_rect(i)
		var state := Intro.station_state(data, run.profile, PLACES[i].id)
		draw_rect(r, Color(0.04, 0.035, 0.06, 0.85 if state != "locked" else 0.55))
		draw_rect(r, Color(UiStyle.GOLD, 0.9) if _glows(PLACES[i].id) else Color(1, 1, 1, 0.25 if state == "locked" else 0.5),
				false, 2.0 if _glows(PLACES[i].id) else 1.0)
		UiStyle.text(self, r.position + Vector2(0, 29), PLACES[i].name, 16,
				Color(1, 1, 1, 0.4) if state == "locked" else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
	if _lines.is_empty():
		_draw_quest(data)
	if _reply_t > 0.0:
		_draw_bubble(_reply, minf(1.0, _reply_t))
	if not _lines.is_empty():
		_draw_dialog()
	elif run.last_silver > 0:
		UiStyle.text(self, Vector2(0, size.y - 70), "+%d silver från senaste striden" % run.last_silver, 16,
				Color("#d8dde6"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


## Aktuellt uppdrag i hörnet (introt), annars ett rykte om en lärjunge som sitter fången.
func _draw_quest(data: Dictionary) -> void:
	var title := "UPPDRAG"
	var text := ""
	var step := Intro.current(data, run.profile)
	if not step.is_empty():
		text = step.get("quest", "")
	else:
		title = "RYKTE"
		for realm_id in data.realms:
			for d in data.realms[realm_id].get("disciples", []):
				if text == "" and not run.profile.recruited.has(d.hero):
					text = "%s sägs sitta fången i %s, djup %d." % [data.heroes[d.hero].get("short", d.hero),
							String(data.realms[realm_id].short).to_lower(), int(d.depth)]
	if text == "":
		return
	var r := Rect2(MARGIN, size.y - 170, 330, 96)
	draw_rect(r, Color(0.04, 0.035, 0.06, 0.82))
	draw_rect(r, Color(UiStyle.GOLD, 0.6), false, 1.5)
	UiStyle.text(self, r.position + Vector2(14, 24), title, 15, UiStyle.GOLD)
	UiStyle.para(self, r.position + Vector2(14, 46), text, 17, Color.WHITE, r.size.x - 28, 2)


func _draw_bubble(text: String, a: float) -> void:
	var w := minf(size.x - 80, 760.0)
	var r := Rect2((size.x - w) / 2.0, 160, w, 56)
	draw_rect(r, Color(0.05, 0.04, 0.07, 0.9 * a))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.6 * a), false, 1.5)
	UiStyle.text(self, r.position + Vector2(0, 35), text, 18, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, w, 3)


func _draw_dialog() -> void:
	var w := minf(size.x - 80, 900.0)
	var r := Rect2((size.x - w) / 2.0, size.y - 220, w, 140)
	draw_rect(r, Color(0.05, 0.04, 0.07, 0.94))
	draw_rect(r, Color(UiStyle.GOLD, 0.8), false, 2.0)
	UiStyle.text(self, r.position + Vector2(24, 34), _speaker, 20, UiStyle.GOLD)
	UiStyle.para(self, r.position + Vector2(24, 64), String(_lines[_line_i]), 21, Color.WHITE, w - 48, 2)
	UiStyle.text(self, r.position + Vector2(0, r.size.y - 12), "Tryck för att fortsätta", 15, Color(1, 1, 1, 0.5 + 0.3 * sin(_t * 4.0)),
			HORIZONTAL_ALIGNMENT_RIGHT, w - 20, 2)
