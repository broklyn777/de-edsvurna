extends Control
## Förberedelser (0.18, nås från kampanjkartan): välj en till tre följeslagare bland dem man har (0.23) och vilka troféer
## ur samlingen de bär (0.26.3, som i Siralim: troféerna följer med tills man byter). Realm, djup och instabilitet väljs på kampanjkartan; Kallet vid Kallets altare
## (kortet leder dit). KLAR sparar valet och går tillbaka till kampanjkartan.
## Knappar och kort reagerar när fingret släpps (undviker dubbeltryck mellan skärmar).

const MARGIN := 28.0
const GAP := 14.0
const PARTY_ART := preload("res://assets/illustrations/sallskapet.webp")

var companions: Array[String] = []
## Trofén man har tryckt på och ska sätta på en hjälte.
var selected := ""
## 0.30.48: sidan i trofégallret och en rad om en låst trofé man tryckt på.
var _page := 0
var _locked_note := ""
## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
@onready var run: Node = get_node("/root/Run")
var _t := 0.0
var _press_at := Vector2(-1, -1)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	run.base_music()
	var previous: Array[String] = []
	for id in run.profile.party:
		if id != "paladin":
			previous.append(id)
	companions = previous.filter(func(id: String) -> bool: return run.profile.recruited.has(id))
	if companions.is_empty() and not run.profile.recruited.is_empty():
		companions = [run.profile.recruited[0]]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tap-trophy="):  # skärmdumpar: som ett tryck på trofén (en låst visar sin rad)
			var id := a.get_slice("=", 1)
			var i := _page_trophies().find(id)
			if i >= 0:
				_tap.call_deferred(_trophy_rect(i).get_center())
		elif a == "--ask-move":  # skärmdumpar: frågan när en buren trofé ska flyttas till en annan hjälte
			_ask_move_demo.call_deferred()


## "I Brokks sköld" → "i Brokks sköld" (namnet behåller sin stora bokstav).
static func _lower_first(s: String) -> String:
	return s.left(1).to_lower() + s.substr(1)


func _ask_move_demo() -> void:
	for hero_id in run.profile.worn:
		for other in _party():
			if other != hero_id:
				_put_on(other, run.profile.worn[hero_id])
				return


## Följeslagarna man har (0.23: de befriade lärjungarna; resten bor i Värdshuset).
func _roster() -> Array:
	return run.profile.recruited


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if event.pressed:
		_press_at = event.position
		return
	if _press_at.distance_to(event.position) > 30.0:
		return
	_tap(event.position)
	run.ui_tap()


func _tap(p: Vector2) -> void:
	var data: Dictionary = run.data
	if _back_rect().has_point(p):
		_done()
		return
	if _sheet_rect(-1).has_point(p):
		run.open_sheet("paladin", _party(), run.START_SCENE)
		return
	var roster := _roster()
	for i in roster.size():
		if _sheet_rect(i).has_point(p):
			run.open_sheet(roster[i], ["paladin"] + roster, run.START_SCENE)
			return
	if _oath_rect().has_point(p):
		run.go(run.ALTAR_SCENE)
		return
	for i in roster.size():
		if _companion_rect(i).has_point(p):
			var id: String = roster[i]
			if companions.has(id):
				companions.erase(id)
			elif companions.size() < run.profile.max_companions():
				companions.append(id)
			else:
				companions.pop_front()
				companions.append(id)
			return
	if _pages() > 1:
		for d in [-1, 1]:
			if _page_rect(d).has_point(p):
				_page = posmod(_page + d, _pages())
				return
	var shown := _page_trophies()
	for i in shown.size():
		if _trophy_rect(i).has_point(p):
			var id: String = shown[i]
			_locked_note = ""
			if run.profile.artifact_trophy_owner(id) != "":
				# 0.30.48 (fynd 13): en trofé i en artefakt sitter kvar tills den tas ut hos Smeden.
				selected = ""
				_locked_note = "%s sitter %s – ta ut den hos Hedda." % [data.traits[id].name, _lower_first(run.profile.trophy_label(data, id))]
				run.ui("ui_error", -10.0)
				return
			selected = "" if selected == id else id
			return
	var party := _party()
	for i in party.size():
		if _wearer_rect(i).has_point(p):
			_put_on(party[i], selected)  # utan vald trofé tar man av den hjälten bär
			return
	if _macro_rect().has_point(p):
		run.open_macros(run.START_SCENE)
		return
	if _button_rect().has_point(p) and _can_go():
		_done()


## Sätter trofén på hjälten; tas den från en annan hjälte frågar spelet först (0.30.48, fynd 13).
func _put_on(hero_id: String, trophy_id: String) -> void:
	var q := Profile.move_question(run.data, run.profile.worn, run.profile.artifacts, hero_id, trophy_id)
	if q == "":
		run.profile.wear(hero_id, trophy_id)
		selected = ""
		run.save()
		return
	ConfirmBox.ask(self, q).answered.connect(func(yes: bool) -> void:
		if yes:
			run.profile.wear(hero_id, trophy_id)
			run.save()
		selected = "")


## Samlingen i bokstavsordning (0.30.48), så att en trofé står på samma plats när den byter bärare.
func _trophies() -> Array:
	var out: Array = run.collection.duplicate()
	out.sort_custom(func(a: String, b: String) -> bool: return String(run.data.traits[a].name) < String(run.data.traits[b].name))
	return out


func _page_trophies() -> Array:
	var all := _trophies()
	var n := _per_page()
	_page = clampi(_page, 0, maxi(_pages() - 1, 0))
	return all.slice(_page * n, mini((_page + 1) * n, all.size()))


## 0.25: minst en följeslagare, utom när ingen har anslutit än (introts nedstigning, paladinen går ned ensam).
func _can_go() -> bool:
	return not companions.is_empty() or run.profile.recruited.is_empty()


## Androids bakåtknapp (Run.go_back): som ‹ KARTAN.
func go_back() -> bool:
	_done()
	run.ui_tap()
	return true


## Sparar sällskapet och går tillbaka till kampanjkartan.
func _done() -> void:
	if not companions.is_empty():
		run.profile.set_party(companions)
	run.save()
	run.go(run.CAMPAIGN_SCENE)


func _party() -> Array[String]:
	var out: Array[String] = ["paladin"]
	for id in _roster():
		if companions.has(id):
			out.append(id)
	return out


# --- Layout -----------------------------------------------------------------

func _oath_rect() -> Rect2:
	return Rect2(MARGIN, 98, size.x - MARGIN * 2, 104)


## Knappen till hjältebladet: −1 = Paladinen (i kallets kort), annars följeslagarens kort.
func _sheet_rect(i: int) -> Rect2:
	var r := _oath_rect() if i < 0 else _companion_rect(i)
	if r.size.y < 80:
		return Rect2(r.end.x - 78, r.end.y - 30, 70, 26)  # låga kort: under namnet
	return Rect2(r.end.x - 78, r.end.y - 36, 70, 30)


## Upp till fyra följeslagare som stora kort; fler (0.23) i två rader om fem.
func _companion_rect(i: int) -> Rect2:
	if _roster().size() <= 4:
		var w := (size.x - MARGIN * 2 - GAP * 3) / 4.0
		return Rect2(MARGIN + i * (w + GAP), 240, w, 176)
	var w5 := (size.x - MARGIN * 2 - GAP * 4) / 5.0
	# 0.26.3: tre rader (11+ lärjungar) blir lägre så att troféerna får plats under.
	var h := 84.0 if _roster().size() <= 10 else 58.0
	return Rect2(MARGIN + (i % 5) * (w5 + GAP), 240 + (i / 5) * (h + 8), w5, h)


## Trofédelens överkant: under följeslagarna.
func _trophy_top() -> float:
	return maxf(442.0, _companion_rect(_roster().size() - 1).end.y + 14) if not _roster().is_empty() else 442.0


## 0.30.48 (B6): gallret har en egen yta mellan bärarna och knapparna längst ned; ryms inte allt blir det sidor (‹ ›).
const TROPHY_COLS := 7
const TROPHY_H := 50.0
const TROPHY_STEP := 56.0


func _grid_top() -> float:
	return _trophy_top() + 72


func _grid_rows() -> int:
	return maxi(1, int((_button_rect().position.y - 10 - _grid_top() + TROPHY_STEP - TROPHY_H) / TROPHY_STEP))


func _per_page() -> int:
	return TROPHY_COLS * _grid_rows()


func _pages() -> int:
	return maxi(1, ceili(run.collection.size() / float(_per_page())))


## Bredden gallret har: med sidor tar pilarna en remsa till höger.
func _grid_width() -> float:
	if _pages() <= 1:
		return size.x - MARGIN * 2
	return size.x - MARGIN * 2 - (72.0 if _grid_rows() > 1 else 136.0)


## Samlingen som knappar, sju per rad (trofé i = plats på den visade sidan).
func _trophy_rect(i: int) -> Rect2:
	var w := (_grid_width() - GAP * (TROPHY_COLS - 1)) / float(TROPHY_COLS)
	return Rect2(MARGIN + (i % TROPHY_COLS) * (w + GAP), _grid_top() + (i / TROPHY_COLS) * TROPHY_STEP, w, TROPHY_H)


## Sidpilarna: -1 = föregående, 1 = nästa; under varandra, eller bredvid varandra när gallret har en rad.
func _page_rect(d: int) -> Rect2:
	var i := 0 if d < 0 else 1
	if _grid_rows() > 1:
		return Rect2(size.x - MARGIN - 58, _grid_top() + i * TROPHY_STEP * (_grid_rows() - 1), 58, TROPHY_H)
	return Rect2(size.x - MARGIN - 122 + i * 64, _grid_top(), 58, TROPHY_H)


## Sällskapet med det var och en bär: en kolumn per plats (4 eller 5), och en till för den låsta platsen.
func _wearer_cols() -> int:
	return maxi(4, run.profile.party_slots() + (1 if run.profile.next_slot_lock() != "" else 0))


func _wearer_rect(i: int) -> Rect2:
	var n := _wearer_cols()
	var w := (size.x - MARGIN * 2 - GAP * (n - 1)) / float(n)
	return Rect2(MARGIN + i * (w + GAP), _trophy_top() + 14, w, 48)


func _button_rect() -> Rect2:
	return Rect2((size.x - 340) / 2.0, size.y - 76, 340, 60)


func _back_rect() -> Rect2:
	return Rect2(MARGIN, 18, 150, 44)


func _macro_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 200, size.y - 70, 200, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.06))
	# Sällskapet på väg mot ruinerna (VD:ns illustration), svagt bakom valen.
	var art_h := size.x * PARTY_ART.get_height() / PARTY_ART.get_width()
	draw_texture_rect(PARTY_ART, Rect2(0, (size.y - art_h) / 2, size.x, art_h), false, Color(1, 1, 1, 0.14))
	_small_button(_back_rect(), "‹ KARTAN")
	UiStyle.text(self, Vector2(0, 46), "SILVER %d" % run.profile.silver, 22, Color("#d8dde6"),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - MARGIN, 4)
	UiStyle.text(self, Vector2(0, 48), "FÖRBEREDELSER", 38, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	var ed: Dictionary = data.traits[run.profile.oath]
	# Perkarna som verkar, med nivå ("Vrede ×2") och den lånade sist.
	var active: Array = run.profile.active_perks(data, run.profile.oath)
	var perks: Array = []
	for id in active:
		var label: String = data.traits[id].name + (" (lånad)" if run.profile.anointed.get(run.profile.oath, "") == id else "")
		var n: int = active.count(id)
		if n > 1:
			label += " ×%d" % n
		if not perks.has(label):
			perks.append(label)
	var ed_body := "%s\nPerks: %s" % [ed.text, ", ".join(perks) if not perks.is_empty() else "inga (köp vid Kallets altare)"]
	UiStyle.card(self, _oath_rect(), ed.name, ed_body, true, UiStyle.GOLD, "PALADINENS KALL – TRYCK FÖR KALLETS ALTARE", 0.0, 10.0)
	_sheet_button(_sheet_rect(-1))

	UiStyle.text(self, Vector2(0, 76), "Sällskapet och troféerna de bär. Realm, djup och instabilitet väljer du på kampanjkartan.", 16,
			Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	var roster := _roster()
	var most: int = run.profile.max_companions()
	var head := "FÖLJESLAGARE – VÄLJ EN TILL %s (%d/%d)" % [["EN", "TVÅ", "TRE", "FYRA", "FEM"][clampi(most - 1, 0, 4)],
			companions.size(), most] if not run.profile.recruited.is_empty() \
			else "FÖLJESLAGARE – INGA ÄN. DU GÅR NED ENSAM."
	UiStyle.text(self, Vector2(MARGIN, 230), head, 16, Color(1, 1, 1, 0.6))
	for i in roster.size():
		var id: String = roster[i]
		var h: Dictionary = data.heroes[id]
		var t: Dictionary = data.traits[h.traits[0]]
		var names: Array = h.abilities.map(func(id: String) -> String: return data.abilities[id].name)
		var body := "%s: %s\nFörmågor: %s" % [t.name, t.text, ", ".join(names)]
		var lv := int(run.profile.hero(data, id).level)
		var title := "%s · nivå %d" % [h.name, lv]
		if roster.size() > 4:
			# Polering: små kort klippte namnet ("Lirien Silversträng ·…"); kort namn i titeln, nivån på egen rad.
			title = String(h.get("short", h.name))
			body = "Nivå %d · %s" % [lv, t.name]
		UiStyle.card(self, _companion_rect(i), title, body, companions.has(id), Color(h.color),
				h.title.to_upper() if roster.size() <= 10 else "", 0.0, 30.0,
				_sheet_rect(i).size.x + 8 if roster.size() > 10 else 0.0)  # tre rader: BLAD tar rollens plats
		if roster.size() > 10:  # låga kort: ingen brödtext, nivån till vänster om BLAD
			var cr := _companion_rect(i)
			UiStyle.text(self, cr.position + Vector2(16, cr.size.y - 10), "nivå %d" % lv, 15,
					Color(1, 1, 1, 0.8 if companions.has(id) else 0.55))
		_sheet_button(_sheet_rect(i))
		if companions.has(id):
			_check(_companion_rect(i).position + Vector2(-13, -13))

	var worn: Dictionary = run.profile.worn
	# Med en vald trofé står dess text i rubrikens ställe.
	var head_t := "TROFÉER – TRYCK PÅ EN TROFÉ OCH SEDAN PÅ EN HJÄLTE. DE BÄR DEM TILLS DU BYTER." if selected == "" \
			else "%s: %s" % [data.traits[selected].name, data.traits[selected].text]
	if _locked_note != "" and selected == "":
		head_t = _locked_note
	UiStyle.text(self, Vector2(MARGIN, _trophy_top() + 4), head_t, 16, Color(1, 1, 1, 0.6) if selected == "" and _locked_note == "" \
			else UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, size.x - MARGIN * 2, 3)
	var party := _party()
	for i in party.size():
		var r := _wearer_rect(i)
		var t: String = worn.get(party[i], "")
		var hot := selected != ""
		draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if t != "" else Color(0, 0, 0, 0.6))
		draw_rect(r, Color(UiStyle.GOLD, 0.95) if hot or t != "" else Color(1, 1, 1, 0.35), false, 2.0)
		UiStyle.text(self, r.position + Vector2(10, 20), data.heroes[party[i]].name, 15, Color(1, 1, 1, 0.7),
				HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 3)
		UiStyle.text(self, r.position + Vector2(10, 40), data.traits[t].name if t != "" else "Ingen trofé", 16,
				UiStyle.TRAIT_GOLD if t != "" else Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 3)
	# Prototyp (sallskap-fem): den femte platsen syns låst från att profilen äger fyra hjältar.
	var lock: String = run.profile.next_slot_lock(true)
	if lock != "":
		UiStyle.locked_slot(self, _wearer_rect(run.profile.party_slots()), "FEMTE PLATSEN", lock)
	if run.collection.is_empty():
		UiStyle.text(self, Vector2(MARGIN, _grid_top() + 26), "Samlingen är tom. Besegra monster för att hitta troféer.", 18, Color(1, 1, 1, 0.45))
	var shown := _page_trophies()
	for i in shown.size():
		var id: String = shown[i]
		var r := _trophy_rect(i)
		var on := selected == id
		var place: String = run.profile.trophy_label(data, id)  # 0.30.48: var den sitter
		var locked: bool = run.profile.artifact_trophy_owner(id) != ""
		draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else Color(0, 0, 0, 0.75 if locked else 0.6))
		draw_rect(r, Color(UiStyle.GOLD, 0.95) if on else Color(UiStyle.TRAIT_GOLD, 0.15 if locked else (0.6 if place != "" else 0.3)), false, 2.0)
		var name_col := Color.WHITE if on or place == "" else Color(1, 1, 1, 0.35 if locked else 0.6)
		UiStyle.text(self, r.position + Vector2(0, 21 if place != "" else 31), UiStyle.fit(data.traits[id].name, 15, r.size.x - 8), 15, name_col,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
		if place != "":
			UiStyle.text(self, r.position + Vector2(0, 41), UiStyle.fit(place, 15, r.size.x - 8), 15, Color(UiStyle.TRAIT_GOLD, 0.4 if locked else 0.75),
					HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
	if _pages() > 1:
		for d in [-1, 1]:
			var pr := _page_rect(d)
			draw_rect(pr, Color(0, 0, 0, 0.6))
			draw_rect(pr, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
			UiStyle.text(self, pr.position + Vector2(0, 33), "‹" if d < 0 else "›", 26, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 4)
		UiStyle.text(self, Vector2(0, _grid_top() - 6), "SIDA %d/%d" % [_page + 1, _pages()], 15, Color(1, 1, 1, 0.5),
				HORIZONTAL_ALIGNMENT_RIGHT, size.x - MARGIN, 3)

	UiStyle.big_button(self, _button_rect(), "KLAR", _t, _can_go())
	_small_button(_macro_rect(), "MAKRON")


## 0.27.2: en bock i hörnet på valda följeslagare (inte bara ramen), så att ett mörkare kort inte ser otillgängligt ut.
func _check(at: Vector2) -> void:
	draw_circle(at + Vector2(12, 12), 13.0, UiStyle.GOLD)
	draw_polyline(PackedVector2Array([at + Vector2(6, 12), at + Vector2(11, 17), at + Vector2(19, 7)]), Color(0.08, 0.06, 0.04), 3.0)


func _sheet_button(r: Rect2) -> void:
	draw_rect(r, Color(0, 0, 0, 0.7))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
	UiStyle.text(self, r.position + Vector2(0, 21), "BLAD", 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)


func _small_button(r: Rect2, label: String) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + 8), label, 20, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 4)
