extends Control
## Kryptporten (Siralims Teleportation Shrine), nås från basen: välj tre följeslagare och eventuellt
## en trofé från samlingen, och gå ned i kryptan. Eden väljs vid Edsaltaret (kortet leder dit).
## Knappar och kort reagerar när fingret släpps (undviker dubbeltryck mellan skärmar).

const MARGIN := 28.0
const GAP := 14.0
const COMPANIONS := ["brokk", "alva", "eira", "solveig"]

var companions: Array[String] = ["brokk", "alva", "eira"]
var brought := ""
var wearer := "paladin"
## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
@onready var run: Node = get_node("/root/Run")
var _t := 0.0
var _press_at := Vector2(-1, -1)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var previous: Array[String] = []
	for id in run.profile.party:
		if id != "paladin":
			previous.append(id)
	if previous.size() == 3:
		companions = previous


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


func _tap(p: Vector2) -> void:
	var data: Dictionary = run.data
	if _back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	if _oath_rect().has_point(p):
		run.go(run.ALTAR_SCENE)
		return
	for i in COMPANIONS.size():
		if _companion_rect(i).has_point(p):
			var id: String = COMPANIONS[i]
			if companions.has(id):
				companions.erase(id)
			elif companions.size() < 3:
				companions.append(id)
			else:
				companions.pop_front()
				companions.append(id)
			if not _party().has(wearer):
				wearer = "paladin"
			return
	for i in run.collection.size():
		if _trophy_rect(i).has_point(p):
			brought = "" if brought == run.collection[i] else run.collection[i]
			return
	if brought != "":
		var party := _party()
		for i in party.size():
			if _wearer_rect(i).has_point(p):
				wearer = party[i]
				return
	if _depth_rect(-1).has_point(p):
		run.profile.choose_depth(run.profile.depth - 1)
		run.save()
		return
	if _depth_rect(1).has_point(p):
		run.profile.choose_depth(run.profile.depth + 1)
		run.save()
		return
	if _macro_rect().has_point(p):
		run.open_macros(run.START_SCENE)
		return
	if _button_rect().has_point(p) and companions.size() == 3:
		var party := _party()
		run.start_run(party)
		if brought != "":
			run.state.take_trophy(brought)
			run.state.equip(wearer, brought)


func _party() -> Array[String]:
	var out: Array[String] = ["paladin"]
	for id in COMPANIONS:
		if companions.has(id):
			out.append(id)
	return out


# --- Layout -----------------------------------------------------------------

func _oath_rect() -> Rect2:
	return Rect2(MARGIN, 98, size.x - MARGIN * 2, 104)


func _companion_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 3) / 4.0
	return Rect2(MARGIN + i * (w + GAP), 240, w, 132)


func _trophy_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 5) / 6.0
	return Rect2(MARGIN + i * (w + GAP), 410, w, 112)


func _wearer_rect(i: int) -> Rect2:
	return Rect2(MARGIN + 110 + i * 150, 534, 140, 36)


func _button_rect() -> Rect2:
	return Rect2((size.x - 340) / 2.0, size.y - 76, 340, 60)


func _back_rect() -> Rect2:
	return Rect2(MARGIN, 18, 150, 44)


## Realm Depth: −1 till vänster, +1 till höger om siffran (nere till vänster).
func _depth_rect(dir: int) -> Rect2:
	return Rect2(MARGIN + (0.0 if dir < 0 else 170.0), size.y - 70, 50, 50)


func _macro_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 200, size.y - 70, 200, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.06))
	_small_button(_back_rect(), "‹ BASEN")
	UiStyle.text(self, Vector2(0, 46), "SILVER %d" % run.profile.silver, 22, Color("#d8dde6"),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - MARGIN, 4)
	UiStyle.text(self, Vector2(0, 48), "KRYPTPORTEN", 38, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	UiStyle.text(self, Vector2(0, 76), "Tre strider. Varje seger ger silver och en trofé från monstren du slog.", 16,
			Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)

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
	var ed_body := "%s\nPerks: %s" % [ed.text, ", ".join(perks) if not perks.is_empty() else "inga (köp vid Edsaltaret)"]
	UiStyle.card(self, _oath_rect(), ed.name, ed_body, true, UiStyle.GOLD, "PALADINENS ED – TRYCK FÖR EDSALTARET")

	UiStyle.text(self, Vector2(MARGIN, 230), "FÖLJESLAGARE – VÄLJ TRE", 14, Color(1, 1, 1, 0.6))
	for i in COMPANIONS.size():
		var id: String = COMPANIONS[i]
		var h: Dictionary = data.heroes[id]
		var t: Dictionary = data.traits[h.traits[0]]
		var names: Array = h.abilities.map(func(id: String) -> String: return data.abilities[id].name)
		var body := "%s: %s\nFörmågor: %s" % [t.name, t.text, ", ".join(names)]
		UiStyle.card(self, _companion_rect(i), h.name, body, companions.has(id), Color(h.color), h.title.to_upper())

	UiStyle.text(self, Vector2(MARGIN, 400), "TA MED EN TROFÉ FRÅN SAMLINGEN (VALFRITT)", 14, Color(1, 1, 1, 0.6))
	if run.collection.is_empty():
		UiStyle.text(self, Vector2(MARGIN, 450), "Samlingen är tom. Besegra monster för att hitta troféer.", 16, Color(1, 1, 1, 0.45))
	for i in run.collection.size():
		var t: Dictionary = data.traits[run.collection[i]]
		UiStyle.card(self, _trophy_rect(i), t.name, t.text, brought == run.collection[i], UiStyle.TRAIT_GOLD)
	if brought != "":
		UiStyle.text(self, Vector2(MARGIN, 558), "BÄRS AV", 14, Color(1, 1, 1, 0.6))
		var party := _party()
		for i in party.size():
			var r := _wearer_rect(i)
			var on := wearer == party[i]
			draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else Color(0, 0, 0, 0.6))
			draw_rect(r, Color(UiStyle.GOLD, 0.95) if on else Color(1, 1, 1, 0.35), false, 2.0)
			UiStyle.text(self, r.position + Vector2(0, 24), data.heroes[party[i]].name, 15, Color.WHITE,
					HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)

	_draw_depth()
	UiStyle.big_button(self, _button_rect(), "IN I KRYPTAN", _t, companions.size() == 3)
	_small_button(_macro_rect(), "MAKRON")


func _draw_depth() -> void:
	var prof: Profile = run.profile
	UiStyle.text(self, Vector2(MARGIN, size.y - 80), "DJUP (DJUPASTE KLARADE: %d)" % prof.best_depth, 14, Color(1, 1, 1, 0.6))
	var can_down := prof.depth > 1
	var can_up := prof.depth < prof.max_depth()
	_small_button(_depth_rect(-1), "−" if can_down else "")
	_small_button(_depth_rect(1), "+" if can_up else "")
	UiStyle.text(self, Vector2(MARGIN + 50, size.y - 36), str(prof.depth), 34, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 120, 6)
	var lines := ["Fiender +%d %%" % roundi((CombatSim.depth_mult(prof.depth) - 1.0) * 100.0),
			"Silver +%d %%" % roundi(Profile.SILVER_PER_DEPTH * (prof.depth - 1) * 100.0),
			"Troféchans %d %%" % roundi(RunState.trophy_chance(prof.depth) * 100.0)]
	for i in lines.size():
		UiStyle.text(self, Vector2(MARGIN + 232, size.y - 56 + i * 18), lines[i], 14, Color(1, 1, 1, 0.7))


func _small_button(r: Rect2, label: String) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + 8), label, 20, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 4)
