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
			elif companions.size() < 3:
				companions.append(id)
			else:
				companions.pop_front()
				companions.append(id)
			return
	for i in run.collection.size():
		if _trophy_rect(i).has_point(p):
			selected = "" if selected == run.collection[i] else run.collection[i]
			return
	var party := _party()
	for i in party.size():
		if _wearer_rect(i).has_point(p):
			run.profile.wear(party[i], selected)  # utan vald trofé tar man av den hjälten bär
			selected = ""
			run.save()
			return
	if _macro_rect().has_point(p):
		run.open_macros(run.START_SCENE)
		return
	if _button_rect().has_point(p) and _can_go():
		_done()


## 0.25: minst en följeslagare, utom när ingen har anslutit än (introts nedstigning, paladinen går ned ensam).
func _can_go() -> bool:
	return not companions.is_empty() or run.profile.recruited.is_empty()


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


## Samlingen som knappar, sju per rad.
func _trophy_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 6) / 7.0
	return Rect2(MARGIN + (i % 7) * (w + GAP), _trophy_top() + 76 + (i / 7) * 42, w, 36)


## Sällskapet med det var och en bär.
func _wearer_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 3) / 4.0
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
	var head := "FÖLJESLAGARE – VÄLJ EN TILL TRE (%d/3)" % companions.size() if not run.profile.recruited.is_empty() \
			else "FÖLJESLAGARE – INGA ÄN. DU GÅR NED ENSAM."
	UiStyle.text(self, Vector2(MARGIN, 230), head, 16, Color(1, 1, 1, 0.6))
	for i in roster.size():
		var id: String = roster[i]
		var h: Dictionary = data.heroes[id]
		var t: Dictionary = data.traits[h.traits[0]]
		var names: Array = h.abilities.map(func(id: String) -> String: return data.abilities[id].name)
		var body := "%s: %s\nFörmågor: %s" % [t.name, t.text, ", ".join(names)]
		if roster.size() > 4:
			body = t.name
		var lv := int(run.profile.hero(data, id).level)
		UiStyle.card(self, _companion_rect(i), "%s · nivå %d" % [h.name, lv], body, companions.has(id), Color(h.color),
				h.title.to_upper() if roster.size() <= 10 else "", 0.0, 30.0)  # tre rader: BLAD tar rollens plats
		_sheet_button(_sheet_rect(i))
		if companions.has(id):
			_check(_companion_rect(i).position + Vector2(-13, -13))

	var worn: Dictionary = run.profile.worn
	# Med en vald trofé står dess text i rubrikens ställe.
	var head_t := "TROFÉER – TRYCK PÅ EN TROFÉ OCH SEDAN PÅ EN HJÄLTE. DE BÄR DEM TILLS DU BYTER." if selected == "" \
			else "%s: %s" % [data.traits[selected].name, data.traits[selected].text]
	UiStyle.text(self, Vector2(MARGIN, _trophy_top() + 4), head_t, 16, Color(1, 1, 1, 0.6) if selected == "" else UiStyle.TRAIT_GOLD,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - MARGIN * 2, 3)
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
	if run.collection.is_empty():
		UiStyle.text(self, Vector2(MARGIN, _trophy_top() + 102), "Samlingen är tom. Besegra monster för att hitta troféer.", 18, Color(1, 1, 1, 0.45))
	for i in run.collection.size():
		var id: String = run.collection[i]
		var r := _trophy_rect(i)
		var on := selected == id
		var taken := worn.values().has(id)
		draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else Color(0, 0, 0, 0.6))
		draw_rect(r, Color(UiStyle.GOLD, 0.95) if on else Color(UiStyle.TRAIT_GOLD, 0.6 if taken else 0.3), false, 2.0)
		UiStyle.text(self, r.position + Vector2(0, 24), data.traits[id].name, 15,
				Color.WHITE if on or not taken else Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)

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
