extends TapScreen
## Biblioteket (Siralims Codex): samlingen av troféer man någonsin hittat, vilket monster de kom
## från och vad de gör, samt sällskapets artefakter. Kryptans troféer syns som rykten innan man har dem (0.24.3).

const PER_ROW := 5
const RARITY := {"common": "VANLIG", "elite": "ELIT", "boss": "BOSS"}


## Vald trofé (dess text visas i rutan under korten).
var selected := -1
## Gambits (docs/plan/gambits.md): VILLKOR visar makronas villkor, ägda i guld och de andra som rykten.
var gambits_view := false
var gambit_selected := -1


func _ready() -> void:
	super()
	run.intro("library_read")  # 0.23: introts steg om troféer och kryptan
	gambits_view = "--library-gambits" in OS.get_cmdline_user_args()  # skärmdumpar


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var heroes: Array = _heroes()
	for i in heroes.size():
		if _hero_rect(i).has_point(p):
			run.open_sheet(heroes[i], heroes, run.LIBRARY_SCENE, true)
			return
	if _toggle_rect().has_point(p):
		gambits_view = not gambits_view
		run.ui("ui_toggle", -10.0)
		queue_redraw()
		return
	if gambits_view:
		for i in _gambit_ids().size():
			if _gambit_rect(i).has_point(p):
				gambit_selected = i
				run.ui_tap()
				queue_redraw()
				return
		return
	# 0.20.3: korten visar namnen; ett tryck visar hela texten i rutan under.
	for i in _all_trophies().size():
		if _trophy_rect(i).has_point(p):
			selected = i
			run.ui_tap()
			return


func _trophy_rect(i: int) -> Rect2:
	# 0.31: med fler än 25 troféer (Lunden) blir rutnätet tätare, sex per rad, så att rutan med texten och lärdomen
	# får plats ovanför hjältarna.
	var per := PER_ROW if _all_trophies().size() <= PER_ROW * 5 else 6
	var pitch := 68.0 if per == PER_ROW else 46.0
	var w := (size.x - MARGIN * 2 - GAP * (per - 1)) / per
	return Rect2(MARGIN + (i % per) * (w + GAP), 118 + (i / per) * pitch, w, pitch - 8.0)


## Alla troféer Realm för Realm: varje fiendetyps vanliga trofé och dess elittrofé, i den ordning
## fienderna möts. [{trophy, kind, realm, elite}]
func _all_trophies() -> Array:
	var data: Dictionary = run.data
	var out := []
	var seen := []
	for realm_id in data.realms:
		for enc_id in data.realms[realm_id].floors:
			for kind in data.encounters[enc_id].enemies:
				var d: Dictionary = data.enemies[kind]
				for pair in [[d.get("trophy", ""), false], [d.get("elite", {}).get("trophy", ""), true]]:
					if pair[0] != "" and not seen.has(pair[0]):
						seen.append(pair[0])
						out.append({"trophy": pair[0], "kind": kind, "realm": realm_id, "elite": pair[1]})
		# Väktarsteg 2: de roterande väktarnas egna troféer (efter GUARDIAN_WINS_FOR_TROPHY segrar).
		for enc_id in data.realms[realm_id].get("guardians", []):
			var gt := RunState.guardian_trophy(data, enc_id)
			if gt != "" and data.traits.has(gt) and not seen.has(gt):
				seen.append(gt)
				out.append({"trophy": gt, "kind": data.encounters[enc_id].enemies[0], "realm": realm_id, "elite": false,
						"guardian": enc_id})
	return out


## Hjälten som bär trofén (0.26.3: Profile.worn), annars "".
func _bearer(trophy_id: String) -> String:
	for hero_id in run.profile.worn:
		if run.profile.worn[hero_id] == trophy_id and run.data.heroes.has(hero_id):
			return run.data.heroes[hero_id].name
	return ""


## Rykten (0.24.3): kryptans vanliga troféer och bossens. Elitvarianternas troféer förblir okända tills man hittar dem.
func _rumoured(entry: Dictionary) -> bool:
	return entry.realm == "crypt" and not entry.elite


func _toggle_rect() -> Rect2:
	return Rect2(MARGIN + 164, 18, 150, 44)


## Makronas villkor i ordning: ägda först, sedan efter sällsynthet.
func _gambit_ids() -> Array:
	var g := Gambits.all(run.data)
	var order := {"start": 0, "common": 1, "chest": 2, "elite": 3, "boss": 4}
	var ids := g.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var oa: bool = run.profile.gambits.has(a)
		var ob: bool = run.profile.gambits.has(b)
		if oa != ob:
			return oa
		return order.get(g[a].get("rarity", ""), 1) < order.get(g[b].get("rarity", ""), 1))
	return ids


func _gambit_rect(i: int) -> Rect2:
	var per := 6
	var w := (size.x - MARGIN * 2 - GAP * (per - 1)) / per
	return Rect2(MARGIN + (i % per) * (w + GAP), 142 + (i / per) * 50, w, 42)


const GAMBIT_TAG := {"start": "START", "common": "VANLIGT", "chest": "KISTA", "elite": "ELIT", "boss": "BOSS"}


## Villkoren: ägda i guld, de andra som rykten (som troféernas), och ryktet i rutan under.
func _draw_gambits() -> void:
	var data: Dictionary = run.data
	var ids := _gambit_ids()
	UiStyle.text(self, Vector2(MARGIN, 120), "MAKRONAS VILLKOR %d / %d – TRYCK FÖR RYKTET" % [run.profile.gambits.size(), ids.size()],
			16, Color(1, 1, 1, 0.6))
	if gambit_selected < 0 or gambit_selected >= ids.size():
		gambit_selected = 0
		for i in ids.size():
			if not run.profile.gambits.has(ids[i]):
				gambit_selected = i
				break
	for i in ids.size():
		var id: String = ids[i]
		var own: bool = run.profile.gambits.has(id)
		var tag: String = GAMBIT_TAG.get(Gambits.all(data)[id].get("rarity", ""), "")
		UiStyle.card(self, _gambit_rect(i), UiStyle.fit(Gambits.name_of(data, id), 15, _gambit_rect(i).size.x - 12) if own else "Okänt villkor",
				"" if own else "rykte", gambit_selected == i, UiStyle.TRAIT_GOLD if own else Color("#b8a27a"), "" if own else tag)
	var last := _gambit_rect(ids.size() - 1)
	var box := Rect2(MARGIN, last.end.y + 12, size.x - MARGIN * 2, size.y - 150 - last.end.y - 12)
	draw_rect(box, Color(0, 0, 0, 0.35))
	draw_rect(box, Color(UiStyle.TRAIT_GOLD, 0.35), false, 1.5)
	var sel: String = ids[gambit_selected]
	var owned: bool = run.profile.gambits.has(sel)
	var g: Dictionary = Gambits.all(data)[sel]
	var conds: Array = g.get("conds", [])
	var example := MacroRunner.condition_name(data, conds[0], 50 if conds[0] in ["hp_below", "hp_above"] else 1) \
			if conds[0] != "test_next" else "pröva nästa rad"
	UiStyle.text(self, box.position + Vector2(16, 28), "%s – %s" % [Gambits.name_of(data, sel) if owned else "Okänt villkor",
			"ditt" if owned else "rykte"], 20, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 32, 3)
	var text := Gambits.clue(data, sel)
	if owned:
		text = "I makrona: \"%s\". %s" % [example, text]
	UiStyle.para(self, box.position + Vector2(16, 54), text, 18, Color(1, 1, 1, 0.9), box.size.x - 32, 2)


func _draw() -> void:
	var data: Dictionary = run.data
	header("BIBLIOTEKET", "Alla troféer. Elitfiender är sällsynta (fler på djupare djup och högre instabilitet); bossens trofé kräver tre segrar."
			if not gambits_view else "Makronas villkor. Handlingarna kan du alltid välja; villkoren förtjänar du i striderna.")
	small_button(back_rect(), "‹ BASEN")
	small_button(_toggle_rect(), "TROFÉER" if gambits_view else "VILLKOR")
	if gambits_view:
		_draw_gambits()
		_draw_heroes(data)
		return
	var all := _all_trophies()
	UiStyle.text(self, Vector2(MARGIN, 108), "TROFÉER %d / %d – TRYCK FÖR ATT LÄSA" % [run.collection.size(), all.size()], 16,
			Color(1, 1, 1, 0.6))
	if selected < 0:
		for i in all.size():
			if run.collection.has(all[i].trophy) or _rumoured(all[i]):
				selected = i
				break
	var detail_title := ""
	var detail_text := "Tryck på en trofé för att läsa vad den gör."
	var detail_lesson := ""
	for i in all.size():
		var entry: Dictionary = all[i]
		var t: Dictionary = data.traits[entry.trophy]
		var d: Dictionary = data.enemies[entry.kind]
		var realm_name: String = data.realms[entry.realm].short
		var boss: bool = d.get("boss", false)
		var tag: String = RARITY["boss" if boss else ("elite" if entry.elite else "common")]
		if entry.has("guardian"):
			var g_need := RunState.GUARDIAN_WINS_FOR_TROPHY
			var g_wins := mini(int(run.profile.guardian_wins.get(entry.guardian, 0)), g_need)
			tag = "VÄKTARE %d/%d" % [g_wins, g_need]
			if run.collection.has(entry.trophy):
				UiStyle.card(self, _trophy_rect(i), t.name, "", selected == i, UiStyle.TRAIT_GOLD, tag)
			else:
				UiStyle.card(self, _trophy_rect(i), "Okänd trofé", "", selected == i, Color("#8a93a6"), tag)
			if selected == i:
				var enc_name := String(data.encounters[entry.guardian].get("name", ""))
				detail_title = "%s – %s" % [t.name if run.collection.has(entry.trophy) else "Okänd trofé", tag]
				detail_text = "%s (Från väktaren i %s.)" % [t.text, enc_name] if run.collection.has(entry.trophy) else \
						"Från väktaren i %s (%s), efter %d segrar mot den." % [enc_name, realm_name, g_need]
				if run.collection.has(entry.trophy):
					detail_lesson = GameData.lesson(data, entry.trophy, _bearer(entry.trophy))
			continue
		if boss:
			tag += " %d/%d" % [mini(int(run.profile.boss_wins.get(entry.kind, 0)), RunState.BOSS_WINS_FOR_TROPHY),
					RunState.BOSS_WINS_FOR_TROPHY]
		if run.collection.has(entry.trophy):
			var source: String = d.elite.name if entry.elite else d.name
			UiStyle.card(self, _trophy_rect(i), t.name, "", selected == i, UiStyle.TRAIT_GOLD, tag)
			if selected == i:
				detail_title = "%s – %s" % [t.name, tag]
				detail_text = "%s (Från %s.)" % [t.text, source]
				detail_lesson = GameData.lesson(data, entry.trophy, _bearer(entry.trophy))
		elif _rumoured(entry):
			# 0.24.3: kryptans troféer är kända som rykten (som Siralims Bestiary), men inte ens egna.
			var source: String = d.name
			UiStyle.card(self, _trophy_rect(i), t.name, "rykte" if not boss else "rykte · %d/%d segrar" % [
					mini(int(run.profile.boss_wins.get(entry.kind, 0)), RunState.BOSS_WINS_FOR_TROPHY), RunState.BOSS_WINS_FOR_TROPHY],
					selected == i, Color("#b8a27a"), "")
			if selected == i:
				detail_title = "%s – %s, rykte, inte din än" % [t.name, tag.to_lower()]
				detail_text = "Sägs ge: %s (Från %s i %s%s.)" % [t.text, source, realm_name,
						", efter %d segrar" % RunState.BOSS_WINS_FOR_TROPHY if boss else ""]
		else:
			var hint := "Från ett monster i %s." % realm_name
			if entry.elite:
				hint = "Från en sällsynt elitfiende i %s." % realm_name
			elif boss:
				hint = "Från %s, efter %d segrar." % [d.name, RunState.BOSS_WINS_FOR_TROPHY]
			UiStyle.card(self, _trophy_rect(i), "Okänd trofé", "", selected == i, Color("#8a93a6"), tag)
			if selected == i:
				detail_title = "Okänd trofé – %s" % tag
				detail_text = hint
	var last := _trophy_rect(all.size() - 1)
	var box := Rect2(MARGIN, last.end.y + 12, size.x - MARGIN * 2, size.y - 150 - last.end.y - 12)
	draw_rect(box, Color(0, 0, 0, 0.35))
	draw_rect(box, Color(UiStyle.TRAIT_GOLD, 0.35), false, 1.5)
	if detail_title != "":
		UiStyle.text(self, box.position + Vector2(16, 28), detail_title, 20, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT,
				box.size.x - 32, 3)
	var used := UiStyle.para(self, box.position + Vector2(16, 54 if detail_title != "" else 30), detail_text, 18,
			Color(1, 1, 1, 0.9), box.size.x - 32, 2)
	# Lärdomen (VD 2026-10-23): kursiv och dämpad under effekten, om den ryms i rutan.
	var ly := box.position.y + (54.0 if detail_title != "" else 30.0) + used - 2.0
	if detail_lesson != "" and ly + 18.0 < box.end.y:
		UiStyle.lesson(self, Vector2(box.position.x + 16, ly), detail_lesson, box.size.x - 32,
				clampi(int((box.end.y - ly) / 20.0), 1, 2))

	_draw_heroes(data)


## Hjältarna (0.19): tryck för hjältebladet; här kan personligheten bytas mot silver.
func _draw_heroes(data: Dictionary) -> void:
	var y := size.y - (120.0 if _heroes().size() <= 5 else 126.0)
	UiStyle.text(self, Vector2(MARGIN, y), "HJÄLTARNA – TRYCK FÖR HJÄLTEBLADET (HÄR BYTS PERSONLIGHET)", 16, Color(1, 1, 1, 0.6))
	var heroes: Array = _heroes()
	for i in heroes.size():
		var h: Dictionary = run.profile.hero(data, heroes[i])
		var p: Dictionary = data.personalities.get(h.personality, {})
		var label := "%s · nivå %d · %s" % [data.heroes[heroes[i]].name, int(h.level), p.get("name", "")]
		chip(_hero_rect(i), UiStyle.fit(label, 15, _hero_rect(i).size.x - 10), false, 15)


## 0.24.3: bara Paladinen och de som har anslutit.
func _heroes() -> Array:
	return ["paladin"] + Array(run.profile.recruited)


func _hero_rect(i: int) -> Rect2:
	var n := _heroes().size()
	if n <= 5:
		var w := (size.x - MARGIN * 2 - GAP * 4) / 5.0
		return Rect2(MARGIN + i * (w + GAP), size.y - 96, w, 50)
	# 0.30.17: fler än fem hjältar: två rader med upp till sex i varje.
	var per := ceili(n / 2.0)
	var w2 := (size.x - MARGIN * 2 - GAP * (per - 1)) / per
	return Rect2(MARGIN + (i % per) * (w2 + GAP), size.y - 104 + (i / per) * 48, w2, 42)
