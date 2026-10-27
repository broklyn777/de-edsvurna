extends TapScreen
## Övningsgården (Siralims Arena): välj en fiendegrupp och strid med sällskapet, makrona,
## artefakterna och troféer ur samlingen – utan risk. Efter striden kommer man tillbaka hit med
## makrologgen kvar, och kan gå till makroredigeraren och tillbaka: skapa makro → kör → se bristen
## i loggen → ändra → kör igen.

const LOG_LINE := 19.0

var selected := ""
var _full_log: MacroLog


func _ready() -> void:
	super()
	_full_log = MacroLog.new()
	_full_log.setup()
	_full_log.entries = run.practice_log
	_full_log.visible = false
	add_child(_full_log)
	# Utvecklarflagga för skärmdumpar: alla Realmens elitgrupper som mötta (sparas inte om profilen är påhittad).
	if "--all-elites" in OS.get_cmdline_user_args():
		for pool in run.data.realms[run.profile.realm].get("elite_pools", []):
			for id in pool:
				if not run.profile.elites_met.has(id):
					run.profile.elites_met.append(id)


func _process(delta: float) -> void:
	super(delta)
	if _full_log.visible and not _full_log.expanded:
		_full_log.visible = false


## Mötena att öva mot. I introt (0.23) bara Övningsgårdens docka, för en ensam paladin.
func _encounters() -> Array:
	if run.intro_practice():
		run.practice_encounter = run.INTRO_PRACTICE
		return [run.INTRO_PRACTICE]
	return _floors() + _elites()


func _floors() -> Array:
	return run.data.realms[run.profile.realm].floors


## 0.29.5: Realmens elitgrupper som man har slagits mot i grottan (Profile.elites_met).
func _elites() -> Array:
	var out := []
	for pool in run.data.realms[run.profile.realm].get("elite_pools", []):
		for id in pool:
			if run.profile.elites_met.has(id) and run.data.encounters.has(id):
				out.append(id)
	return out


func _tap(p: Vector2) -> void:
	var data: Dictionary = run.data
	var profile: Profile = run.profile
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var encs: Array = _encounters()
	for i in encs.size():
		if _enc_rect(i).has_point(p):
			run.practice_encounter = encs[i]
			return
	for i in run.collection.size():
		if _chip_rect(i).has_point(p):
			if profile.artifact_trophy_owner(run.collection[i]) != "":
				selected = ""  # 0.30.48 (fynd 13): sitter i en artefakt tills den tas ut hos Smeden
				run.ui("ui_error", -10.0)
				return
			selected = "" if selected == run.collection[i] else run.collection[i]
			return
	for i in profile.party.size():
		if _hero_rect(i).has_point(p):
			var hero_id: String = profile.party[i]
			var trophy := selected
			var q := Profile.move_question(data, profile.worn, profile.artifacts, hero_id, trophy)
			if q == "":
				profile.wear(hero_id, trophy)
				selected = ""
				run.save()
			else:  # 0.30.48: att ta en trofé från en annan hjälte kräver ett ja
				ConfirmBox.ask(self, q).answered.connect(func(yes: bool) -> void:
					if yes:
						profile.wear(hero_id, trophy)
						run.save()
					selected = "")
			return
	if _log_rect().has_point(p) and not run.practice_log.is_empty():
		_full_log.visible = true
		_full_log.expanded = true
		return
	if _macro_rect().has_point(p):
		run.open_macros(run.PRACTICE_SCENE)
		return
	if _fight_rect().has_point(p) and data.encounters.has(run.practice_encounter):
		run.start_practice(run.practice_encounter)


# --- Layout -----------------------------------------------------------------

func _enc_rect(i: int) -> Rect2:
	var n := _floors().size()
	if _elites().is_empty():
		return Rect2(MARGIN, 124 + i * 104, 360, 94)
	if i < n:
		return Rect2(MARGIN, 124 + i * 80, 360, 72)  # 0.29.5: tätare när elitgrupperna står under
	return Rect2(MARGIN, 124 + n * 80 + 26 + (i - n) * 42, 360, 36)


func _right_x() -> float:
	return MARGIN + 360 + GAP * 2


func _hero_rect(i: int) -> Rect2:
	var x0 := _right_x()
	var n := maxi(4, run.profile.party.size())  # prototyp (sallskap-fem)
	var w := (size.x - MARGIN - x0 - GAP * (n - 1)) / float(n)
	return Rect2(x0 + i * (w + GAP), 124, w, 104)


func _chip_rect(i: int) -> Rect2:
	var x0 := _right_x()
	var w := 168.0
	var per_row := maxi(1, int((size.x - MARGIN - x0 + GAP) / (w + GAP)))
	return Rect2(x0 + (i % per_row) * (w + GAP), 248 + (i / per_row) * 54, w, 48)  # 0.30.48: två rader


func _log_rect() -> Rect2:
	var x0 := _right_x()
	var top := _chip_rect(maxi(run.collection.size() - 1, 0)).end.y + 16
	return Rect2(x0, top, size.x - MARGIN - x0, size.y - 96 - top)


func _fight_rect() -> Rect2:
	return Rect2(MARGIN, size.y - 76, 360, 60)


func _macro_rect() -> Rect2:
	return Rect2(_right_x(), size.y - 70, 260, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var profile: Profile = run.profile
	header("ÖVNINGSGÅRDEN", "Prova makron och troféer utan risk: inget förloras och Charges är fulla. Loggen visar varför hjältarna gjorde som de gjorde.")
	small_button(back_rect(), "‹ BASEN")

	UiStyle.text(self, Vector2(MARGIN, 114), "FIENDER", 14, Color(1, 1, 1, 0.6))
	var encs: Array = _encounters()
	var n := _floors().size()
	for i in encs.size():
		var enc: Dictionary = data.encounters[encs[i]]
		if i < n:
			UiStyle.card(self, _enc_rect(i), enc.name, _enemy_list(enc), run.practice_encounter == encs[i],
					Color("#ff8a6a"), "VÅNING %d" % (i + 1))
		else:
			if i == n:
				UiStyle.text(self, Vector2(MARGIN, _enc_rect(i).position.y - 8), "ELITGRUPPER NI HAR MÖTT", 14, Color(1, 1, 1, 0.6))
			chip(_enc_rect(i), "★ " + String(enc.name), run.practice_encounter == encs[i], 15)

	UiStyle.text(self, Vector2(_right_x(), 114), "SÄLLSKAPET – TRYCK PÅ EN TROFÉ OCH SEDAN PÅ EN HJÄLTE", 14, Color(1, 1, 1, 0.6))
	for i in profile.party.size():
		var hero_id: String = profile.party[i]
		var h: Dictionary = data.heroes[hero_id]
		var trophy: String = profile.worn.get(hero_id, "")
		var own: String = profile.oath if hero_id == "paladin" else h.traits[0]
		var art: Dictionary = profile.artifacts.get(hero_id, {})
		var body := "%s\nTrofé: %s\n%s" % [data.traits[own].name,
				data.traits[trophy].name if trophy != "" else "–", ArtifactText.name_of(data, art)]
		UiStyle.card(self, _hero_rect(i), h.name, body, trophy != "", Color(h.color))

	if run.collection.is_empty():
		UiStyle.text(self, Vector2(_right_x(), 276), "Samlingen är tom – troféer hittas i kryptan.", 15, Color(1, 1, 1, 0.45))
	for i in run.collection.size():
		var t: String = run.collection[i]
		var r := _chip_rect(i)
		var place := profile.trophy_label(data, t)  # 0.30.48: "Bärs av Brokk" / "I Brokks hjälm" på en egen rad
		var locked := profile.artifact_trophy_owner(t) != ""
		chip(r, "", selected == t)
		UiStyle.text(self, r.position + Vector2(0, 21 if place != "" else 30), UiStyle.fit(data.traits[t].name, 15, r.size.x - 10), 15,
				Color(1, 1, 1, 0.4 if locked else 1.0), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
		if place != "":
			UiStyle.text(self, r.position + Vector2(0, 40), UiStyle.fit(place, 15, r.size.x - 10), 15,
					Color(UiStyle.TRAIT_GOLD, 0.4 if locked else 0.8), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)

	_draw_log(data)
	UiStyle.big_button(self, _fight_rect(), "STRID!", _t)
	small_button(_macro_rect(), "MAKRON")
	if not run.last_receipt.is_empty() and not run.practice_log.is_empty():
		UiStyle.text(self, Vector2(_macro_rect().end.x + GAP, size.y - 40), run.last_receipt[0], 14,
				Color(UiStyle.TRAIT_GOLD, 0.8), HORIZONTAL_ALIGNMENT_LEFT, size.x - _macro_rect().end.x - GAP - MARGIN, 3)


## Senaste besluten med de överhoppade raderna, nyast längst ned.
func _draw_log(_data: Dictionary) -> void:
	var r := _log_rect()
	draw_rect(r, Color(0, 0, 0, 0.55))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.3), false, 1.5)
	var log: Array[Dictionary] = run.practice_log
	if log.is_empty():
		UiStyle.text(self, r.position + Vector2(12, 26), "MAKROLOGGEN visas här efter en övningsstrid.", 14, Color(1, 1, 1, 0.5))
		return
	UiStyle.text(self, r.position + Vector2(12, 18), "MAKROLOGG FRÅN SENASTE STRIDEN – TRYCK FÖR HELA", 11, Color(1, 1, 1, 0.5))
	var rows: Array = []
	for e in log:
		rows.append({"text": e.text, "col": Color(1, 1, 1, 0.9) if e.ok else Color("#ff8a6a"), "indent": 0.0})
		for sk in MacroLog.reasons(e):
			rows.append({"text": sk, "col": Color(1, 1, 1, 0.5), "indent": 24.0})
	var fit := int((r.size.y - 30) / LOG_LINE)
	var start := maxi(0, rows.size() - fit)
	for i in range(start, rows.size()):
		var row: Dictionary = rows[i]
		UiStyle.text(self, r.position + Vector2(12 + row.indent, 38 + (i - start) * LOG_LINE), row.text, 13, row.col,
				HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24 - row.indent, 3)


func _enemy_list(enc: Dictionary) -> String:
	var data: Dictionary = run.data
	var names := {}
	# Fienderna som faktiskt möter sällskapet (ett litet sällskap möter färre, CombatSim.enemy_lineup).
	var party_n: int = run.profile.party.size()
	for kind in CombatSim.enemy_lineup(data, CombatSim.encounter_kinds(enc, party_n), party_n):
		names[data.enemies[kind].name] = names.get(data.enemies[kind].name, 0) + 1
	var parts: Array[String] = []
	for n in names:
		parts.append(n if names[n] == 1 else "%s ×%d" % [n, names[n]])
	return ", ".join(parts)

