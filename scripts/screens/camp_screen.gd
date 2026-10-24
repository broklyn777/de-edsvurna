extends Control
## Lägret efter en strid: välj en trofé och se vad som väntar. 0.27 (VAL, plan "Troféer och makron i grottan"):
## troféerna byts bara vid en lägereld i grottan; då öppnas samma skärm utan erbjudande (Run.camp_mode "campfire") och
## man fördelar troféerna mellan hjältarna. Allt reagerar när fingret släpps.

## Nattlägret tonat i bakgrunden.
const NIGHT_CAMP := preload("res://assets/illustrations/nattlagret.webp")
const MARGIN := 28.0
const GAP := 14.0
## Lägrets märken (mot upprepning): grönt för nya troféer, ett varmt sken för de sällsynta.
const NEW_GREEN := Color("#7fe08a")
const RARE_GLOW := Color("#ff9a3c")

var chosen := ""
var selected := ""
## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
@onready var run: Node = get_node("/root/Run")
var _t := 0.0
var _press_at := Vector2(-1, -1)


## Androids bakåtknapp (Run.go_back): lägret har inget bakåt (trofévalet väntar); trycket gör ingenting.
func go_back() -> bool:
	return true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	run.base_music()
	if not run.offer.is_empty():
		HelpBox.offer(self, ["trophies"])  # 0.25: den första trofén
	if not run.offer.is_empty():
		chosen = run.camp_chosen if run.offer.has(run.camp_chosen) else run.offer[0]
		run.camp_chosen = chosen
		selected = chosen


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


## Vid en lägereld byter man troféer; efter en strid väljer man bara den nya.
func _swap() -> bool:
	return run.camp_mode == "campfire"


func _tap(p: Vector2) -> void:
	var state: RunState = run.state
	for i in run.offer.size():
		if _offer_rect(i).has_point(p):
			var old := chosen
			chosen = run.offer[i]
			run.camp_chosen = chosen
			# Byter man val flyttas den tidigare valda troféns plats till den nya.
			var w := state.wearer(old)
			if w != "":
				state.equip(w, "")
			selected = chosen
			return
	var inv := _inventory()
	for i in inv.size():
		if _swap() and _chip_rect(i).has_point(p):
			selected = "" if selected == inv[i] else inv[i]
			return
	for i in state.party.size():
		if _sheet_rect(i).has_point(p):
			run.open_sheet(state.party[i], Array(state.party), run.CAMP_SCENE)
			return
	for i in state.party.size():
		if _swap() and _hero_rect(i).has_point(p):
			var hero_id := state.party[i]
			if selected != "":
				state.equip(hero_id, selected)
				selected = ""
			else:
				state.equip(hero_id, "")
			return
	if _macro_rect().has_point(p):
		run.open_macros(run.CAMP_SCENE)
		return
	if _button_rect().has_point(p):
		if chosen != "":
			state.take_trophy(chosen)
		run.after_camp()


## Troféer att fördela: de hittade plus den nyss valda.
func _inventory() -> Array[String]:
	var out: Array[String] = run.state.trophies.duplicate()
	if chosen != "" and not out.has(chosen):
		out.append(chosen)
	return out


# --- Layout -----------------------------------------------------------------

func _offer_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 2) / 3.0
	return Rect2(MARGIN + i * (w + GAP), 150, w, 120)


func _chip_rect(i: int) -> Rect2:
	return Rect2(MARGIN + i * 230, 318, 220, 40)


func _hero_rect(i: int) -> Rect2:
	var n := maxi(4, run.state.party.size())  # prototyp (sallskap-fem): fem kort på raden
	var w := (size.x - MARGIN * 2 - GAP * (n - 1)) / float(n)
	return Rect2(MARGIN + i * (w + GAP), 396, w, 116)


## Knappen till hjältebladet nere till höger i hjältens kort.
func _sheet_rect(i: int) -> Rect2:
	var r := _hero_rect(i)
	return Rect2(r.end.x - 78, r.end.y - 36, 70, 30)


func _button_rect() -> Rect2:
	return Rect2(size.x - 340 - MARGIN, size.y - 76, 340, 60)


func _macro_rect() -> Rect2:
	return Rect2(size.x - 340 - MARGIN - 220, size.y - 70, 200, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var state: RunState = run.state
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.06))
	# Nattlägret (Drakvalvets illustration) svagt i bakgrunden.
	var bg_h := size.x * NIGHT_CAMP.get_height() / NIGHT_CAMP.get_width()
	draw_texture_rect(NIGHT_CAMP, Rect2(0, (size.y - bg_h) / 2, size.x, bg_h), false, Color(1, 1, 1, 0.13))
	var title := "LÄGERELD – BYT TROFÉER" if _swap() else ("SEGER! VÄLJ EN TROFÉ" if not run.offer.is_empty() else "SEGER!")
	UiStyle.text(self, Vector2(0, 44), title, 34, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	for i in run.last_receipt.size():
		UiStyle.text(self, Vector2(0, 76 + i * 20), run.last_receipt[i], 15, Color(1, 1, 1, 0.75),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)

	for i in run.offer.size():
		var id: String = run.offer[i]
		var t: Dictionary = data.traits[id]
		# Mot upprepning: NY eller ÄGD (och vem som bär den), och de sällsynta står först och glöder.
		var fresh: bool = run.offer_new.has(id)
		var rare := RunState.is_rare_trophy(data, id)
		var tag := ("NY" if fresh else "ÄGD") + " · " + _source_name(id).to_upper()
		if rare:
			tag = "SÄLLSYNT NY" if fresh else "SÄLLSYNT"  # källan står i lärdomen under korten
		var body: String = t.text if fresh else _owned_note(id) + " " + String(t.text)
		var accent: Color = RARE_GLOW if rare else (NEW_GREEN if fresh else UiStyle.TRAIT_GOLD)
		var r := _offer_rect(i)
		UiStyle.card(self, r, t.name, body, chosen == id, accent, tag, 0.25 + 0.2 * sin(_t * 4.0) if rare else 0.0)
		if rare:
			draw_rect(r.grow(5.0), Color(RARE_GLOW, 0.55 + 0.35 * sin(_t * 4.0)), false, 3.0)
	# Inget nytt: ingen valskärm, bara en kort rad (troféerna finns redan i samlingen och följer med i körningen).
	if not run.offer_known.is_empty():
		var names: Array = run.offer_known.map(func(id: String) -> String: return String(data.traits[id].name))
		var line := "Inget nytt den här gången: %s finns redan i samlingen och följer med i körningen." % ", ".join(names)
		UiStyle.text(self, Vector2(MARGIN, 200), line, 17, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER,
				size.x - MARGIN * 2, 3)

	# Lärdomen (VD 2026-10-23) för den valda trofén, kursiv på en rad under korten.
	var lesson_id := chosen if chosen != "" else (selected if _swap() else "")
	if lesson_id != "" and data.traits.has(lesson_id):
		var who := state.wearer(lesson_id)
		var lesson := GameData.lesson(data, lesson_id, String(data.heroes[who].name) if who != "" else "")
		UiStyle.lesson(self, Vector2(MARGIN, 287), lesson, size.x - MARGIN * 2, 1)

	# 0.27.2: med en vald trofé står vad den gör i rubrikens ställe.
	var head := "DINA TROFÉER – TRYCK PÅ EN TROFÉ OCH SEDAN PÅ EN HJÄLTE" if _swap() \
			else "DINA TROFÉER – DE BYTS VID EN LÄGERELD I GROTTAN"
	if _swap() and selected != "":
		head = "%s: %s Tryck på en hjälte." % [data.traits[selected].name, data.traits[selected].text]
	UiStyle.text(self, Vector2(MARGIN, 306), head, 15, Color(1, 1, 1, 0.6) if selected == "" or not _swap() else UiStyle.TRAIT_GOLD,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - MARGIN * 2, 3)
	var inv := _inventory()
	for i in inv.size():
		var r := _chip_rect(i)
		var on := selected == inv[i]
		draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else Color(0, 0, 0, 0.6))
		draw_rect(r, Color(UiStyle.GOLD, 0.6 + 0.4 * sin(_t * 8.0)) if on else Color(UiStyle.TRAIT_GOLD, 0.4), false, 2.0)
		var who := state.wearer(inv[i])
		var label: String = data.traits[inv[i]].name + (" · " + String(data.heroes[who].short) if who != "" else "")
		var left := 10.0
		if state.fresh_trophies.has(inv[i]):  # ny för profilen under den här körningen
			UiStyle.text(self, r.position + Vector2(8, 26), "NY", 15, NEW_GREEN, HORIZONTAL_ALIGNMENT_LEFT, 30, 3)
			left = 36.0
		UiStyle.text(self, r.position + Vector2(left, 26), label, 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT,
				r.size.x - left - 6, 3)

	for i in state.party.size():
		var hero_id := state.party[i]
		var h: Dictionary = data.heroes[hero_id]
		var trophy: String = state.equipped.get(hero_id, "")
		var own: String = state.oath if hero_id == "paladin" else h.traits[0]
		var body := "%s\nTrofé: %s" % [data.traits[own].name, data.traits[trophy].name if trophy != "" else "–"]
		# trofeplats (VAL): artefaktens trofé byts bara hos Smeden; lägret visar den.
		var art: Dictionary = Forge.normalize(state.artifacts.get(hero_id, {}))
		if not art.is_empty() and Forge.trophy_open(int(art.level)) and data.traits.has(art.trophy):
			body += " · Artefakt: %s" % data.traits[art.trophy].name
		var lv := int(run.profile.hero(data, hero_id).level)
		UiStyle.card(self, _hero_rect(i), "%s · nivå %d" % [h.name, lv], body, trophy != "", Color(h.color), h.title.to_upper(),
				0.0, 30.0)
		var sr := _sheet_rect(i)
		draw_rect(sr, Color(0, 0, 0, 0.7))
		draw_rect(sr, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
		UiStyle.text(self, sr.position + Vector2(0, 21), "BLAD", 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 3)

	# Vad som väntar: rumskartan med questen och reglerna (0.18).
	if state.map != null:
		InkArt.floor_markers(self, Vector2(size.x - 470, 44), state.floor, RunState.FLOORS_PER_RUN, UiStyle.GOLD, 18)
	var next := "TILLBAKA TILL GROTTAN – VÅNING %d AV %d" % [state.floor + 1, RunState.FLOORS_PER_RUN]
	if state.floor_cleared() and state.is_last_floor():
		next = "KÖRNINGEN ÄR KLAR!"
	UiStyle.text(self, Vector2(MARGIN, size.y - 112), next, 18, Color("#ff8a6a"))
	var known: Array = state.known_rules().map(func(id: String) -> String: return data.floor_rules[id].name)
	var unknown := state.active_rules().size() - known.size()
	if not state.active_rules().is_empty():
		var rule_line := "REGLER: " + ", ".join(known) + ("" if unknown == 0 else "%s%d dolda" % [", " if not known.is_empty() else "", unknown])
		UiStyle.text(self, Vector2(MARGIN, size.y - 136), rule_line, 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - 420)
	UiStyle.text(self, Vector2(MARGIN, size.y - 88), RunState.quest_text(state.quest) + (" – KLAR!" if state.quest.get("done", false) else ""),
			15, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, size.x - 420)
	if not run.quest_reward.is_empty():
		UiStyle.text(self, Vector2(MARGIN, size.y - 64), "Questen klar: +%d silver%s" % [run.quest_reward.silver,
				" och en perk-poäng!" if run.quest_reward.point else ""], 15, Color("#ffb347"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 420)
	UiStyle.big_button(self, _button_rect(), "TILL GROTTAN" if _swap() else "VIDARE", _t)
	var m := _macro_rect()
	draw_rect(m, Color(0, 0, 0, 0.6))
	draw_rect(m, Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(self, m.position + Vector2(0, m.size.y / 2 + 8), "MAKRON", 20, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, m.size.x, 4)


## "Bärs av Brokk." eller "I samlingen." för en trofé profilen redan äger.
func _owned_note(trophy_id: String) -> String:
	var who: String = run.state.wearer(trophy_id)
	if who == "":
		for hero_id in run.profile.worn:
			if run.profile.worn[hero_id] == trophy_id:
				who = hero_id
	if who != "" and run.data.heroes.has(who):
		return "Bärs av %s." % String(run.data.heroes[who].get("short", run.data.heroes[who].name))
	return "I samlingen."


func _source_name(trophy_id: String) -> String:
	for kind in run.data.enemies:
		if run.data.enemies[kind].get("trophy", "") == trophy_id:
			return run.data.enemies[kind].name
		var elite: Dictionary = run.data.enemies[kind].get("elite", {})
		if String(elite.get("trophy", "")) == trophy_id:
			return String(elite.get("name", run.data.enemies[kind].name))
	return ""
