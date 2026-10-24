extends TapScreen
## Värdshuset (0.23, Siralims Menagerie): följeslagarna man har befriat. De som inte följer med bor här och
## behåller sina nivåer. Tryck på ett kort för att ta med eller lämna kvar (Paladinen och 1–3 följeslagare),
## BLAD öppnar hjältebladet. Lärjungar som ännu sitter fångna syns som rykten.

var companions: Array[String] = []


func _ready() -> void:
	super()
	HelpBox.offer(self, ["disciples"])  # 0.25: hjälprutan första gången
	for id in run.profile.party:
		if id != "paladin":
			companions.append(id)


func _roster() -> Array:
	return run.profile.recruited


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		_save_party()
		run.go(run.BASE_SCENE)
		return
	var roster := _roster()
	for i in roster.size():
		if _sheet_rect(i).has_point(p):
			_save_party()
			run.open_sheet(roster[i], ["paladin"] + roster, run.INN_SCENE)
			return
		if _card_rect(i).has_point(p):
			var id: String = roster[i]
			if companions.has(id):
				if companions.size() > 1:
					companions.erase(id)
			elif companions.size() < run.profile.max_companions():
				companions.append(id)
			else:
				companions.pop_front()
				companions.append(id)
			_save_party()
			return


func _save_party() -> void:
	run.profile.set_party(companions)
	run._save()


func _card_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 3) / 4.0
	return Rect2(MARGIN + (i % 4) * (w + GAP), 126 + (i / 4) * 150, w, 140)


func _sheet_rect(i: int) -> Rect2:
	var r := _card_rect(i)
	return Rect2(r.end.x - 78, r.end.y - 38, 70, 30)


func _draw() -> void:
	var data: Dictionary = run.data
	header("VÄRDSHUSET", "Följeslagarna du har befriat. Tryck för att ta med eller lämna kvar – de som stannar behåller sin nivå.")
	small_button(back_rect(), "‹ BASEN")
	UiStyle.text(self, Vector2(MARGIN, 116), "SÄLLSKAPET: PALADINEN + %d AV %d" % [companions.size(), run.profile.max_companions()], 16,
			Color(1, 1, 1, 0.6))
	# Prototyp (sallskap-fem): den låsta platsen till höger på raden, så att längtan syns.
	var lock: String = run.profile.next_slot_lock()
	if lock != "":
		UiStyle.locked_slot(self, Rect2(size.x - MARGIN - 760, 92, 760, 30), "FEMTE PLATSEN", lock)
	var roster := _roster()
	for i in roster.size():
		var id: String = roster[i]
		var h: Dictionary = data.heroes[id]
		var prog: Dictionary = run.profile.hero(data, id)
		var pers: Dictionary = data.personalities.get(prog.personality, {})
		var t: Dictionary = data.traits[h.traits[0]]
		var on := companions.has(id)
		var r := _card_rect(i)
		UiStyle.card(self, r, "%s · nivå %d" % [h.get("short", h.name), int(prog.level)], "%s · %s\n%s" % [h.title, pers.get("name", ""), t.name],
				on, Color(h.color), "MED" if on else "HEMMA", 0.0, 34.0)
		var need := HeroStats.xp_to_next(int(prog.level))
		UiStyle.bar(self, Rect2(r.position + Vector2(16, r.size.y - 18), Vector2(r.size.x - 110, 6)), float(prog.xp) / need, UiStyle.GOLD)
		var sr := _sheet_rect(i)
		draw_rect(sr, Color(0, 0, 0, 0.6))
		draw_rect(sr, Color(UiStyle.TRAIT_GOLD, 0.8), false, 1.5)
		UiStyle.text(self, sr.position + Vector2(0, 21), "BLAD", 15, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 3)
	# Rykten: lärjungar som ännu sitter fångna (Siralim: varelserna hör till sina Realms).
	var rumors: Array[String] = []
	for realm_id in data.realms:
		for d in data.realms[realm_id].get("disciples", []):
			if not run.profile.recruited.has(d.hero):
				rumors.append("%s sägs sitta fången i %s, djup %d" % [String(data.heroes[d.hero].get("short", data.heroes[d.hero].name)),
						String(data.realms[realm_id].short).to_lower(), int(d.depth)])
	if not rumors.is_empty():
		var y := 126 + ceili(roster.size() / 4.0) * 150 + 24
		UiStyle.text(self, Vector2(MARGIN, y), "RYKTEN", 16, Color(1, 1, 1, 0.6))
		for j in mini(rumors.size(), 4):
			UiStyle.text(self, Vector2(MARGIN, y + 28 + j * 26), rumors[j], 18, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT,
					size.x - MARGIN * 2, 3)
