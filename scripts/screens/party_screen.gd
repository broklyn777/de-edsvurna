extends TapScreen
## Sällskapet (polering fynd 1, VD 2026-10-27, Siralims skapelser från slottets meny): knappen SÄLLSKAPET i borgens
## kortrad. Fliken HJÄLTARNA visar alla som har anslutit med nivå, trofé, artefakt och dess troféplats, och om de är med
## eller bor i värdshuset; ett tryck öppnar hjältebladet. Fliken SAMLINGEN visar alla troféer och var de sitter, först
## de som bärs, sedan efter sällsynthet. Logiken ligger i PartyOverview.

const TABS := ["HJÄLTARNA", "SAMLINGEN"]
const PER_ROW := 4
const COLS := 3
const ROW_H := 54.0
const TOP := 158.0
const DETAIL_H := 112.0
const RARITY_COLOR := {"boss": Color("#ff9a4a"), "elite": Color("#c58cff"), "common": Color("#b8c4d6")}

## Fliken och sidan står kvar när man kommer tillbaka från hjältebladet.
static var tab := 0
static var page := 0
static var selected := ""


func _ready() -> void:
	super()
	if "--party-collection" in OS.get_cmdline_user_args():
		tab = 1


func _tab_rect(i: int) -> Rect2:
	var w := 220.0
	return Rect2(size.x / 2.0 - w - GAP / 2.0 + i * (w + GAP), 100, w, 44)


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	for i in TABS.size():
		if _tab_rect(i).has_point(p):
			tab = i
			return
	if tab == 0:
		var list := PartyOverview.heroes(run.profile)
		for i in list.size():
			if _card_rect(i, list.size()).has_point(p):
				run.open_sheet(list[i], list, run.PARTY_SCENE)
				return
		return
	var all := PartyOverview.collection(run.data, run.profile)
	var pages := _pages(all.size())
	if pages > 1 and _page_rect(0).has_point(p):
		page = (page - 1 + pages) % pages
		return
	if pages > 1 and _page_rect(1).has_point(p):
		page = (page + 1) % pages
		return
	for j in _per_page():
		var i := page * _per_page() + j
		if i < all.size() and _row_rect(j).has_point(p):
			selected = String(all[i].id)
			return


# --- Hjältarna --------------------------------------------------------------------

func _card_rect(i: int, n: int) -> Rect2:
	var rows := ceili(n / float(PER_ROW))
	var h := minf(150.0, (size.y - TOP - 24.0) / maxi(rows, 1) - GAP)
	var w := (size.x - MARGIN * 2 - GAP * (PER_ROW - 1)) / PER_ROW
	return Rect2(MARGIN + (i % PER_ROW) * (w + GAP), TOP + (i / PER_ROW) * (h + GAP), w, h)


func _draw_heroes() -> void:
	var data: Dictionary = run.data
	var list := PartyOverview.heroes(run.profile)
	for i in list.size():
		var row := PartyOverview.hero_row(data, run.profile, list[i])
		var r := _card_rect(i, list.size())
		var color := Color(data.heroes[row.id].get("color", "#ffd75e"))
		UiStyle.card(self, r, "%s · nivå %d" % [row.short, row.level], "", row.with, color,
				"MED" if row.with else "VÄRDSHUSET")
		var w := r.size.x - 32.0
		var lines := []
		if row.trophy != "" and data.traits.has(row.trophy):
			lines.append(["Trofé: " + String(data.traits[row.trophy].name), Color(1, 1, 1, 0.9)])
		else:
			lines.append(["Trofé: tom plats", Color(1, 1, 1, 0.45)])
		match String(row.slot):
			"none":
				lines.append(["Ingen artefakt – smids hos Smeden", Color(1, 1, 1, 0.45)])
			"locked":
				lines.append(["%s · nivå %d" % [row.art_name, row.art_level], Color(1, 1, 1, 0.9)])
				lines.append(["Troféplats på nivå %d" % Forge.TROPHY_LEVEL, Color(1, 1, 1, 0.45)])
			"open":
				lines.append(["%s · nivå %d" % [row.art_name, row.art_level], Color(1, 1, 1, 0.9)])
				if row.art_trophy != "" and data.traits.has(row.art_trophy):
					lines.append(["I artefakten: " + String(data.traits[row.art_trophy].name), UiStyle.TRAIT_GOLD])
				else:
					lines.append(["Artefaktens troféplats: tom", Color(1, 1, 1, 0.45)])
		var step := clampf((r.size.y - 44.0) / lines.size(), 19.0, 26.0)
		for j in lines.size():
			var y := r.position.y + 52.0 + j * step
			if y > r.end.y - 4.0:
				break
			UiStyle.text(self, Vector2(r.position.x + 16, y), UiStyle.fit(lines[j][0], 16, w), 16, lines[j][1])


# --- Samlingen --------------------------------------------------------------------

func _rows() -> int:
	return maxi(1, int((size.y - TOP - DETAIL_H - 24.0) / ROW_H))


func _per_page() -> int:
	return _rows() * COLS


func _pages(n: int) -> int:
	return maxi(1, ceili(n / float(_per_page())))


func _row_rect(j: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * (COLS - 1)) / COLS
	return Rect2(MARGIN + (j / _rows()) * (w + GAP), TOP + (j % _rows()) * ROW_H, w, ROW_H - 6.0)


func _page_rect(i: int) -> Rect2:
	return Rect2(size.x - MARGIN - 64 - (1 - i) * 74, 100, 64, 44)


func _draw_collection() -> void:
	var data: Dictionary = run.data
	var all := PartyOverview.collection(data, run.profile)
	var pages := _pages(all.size())
	page = clampi(page, 0, pages - 1)
	var worn := all.filter(func(e: Dictionary) -> bool: return e.place != "").size()
	UiStyle.text(self, Vector2(MARGIN, 128), "%d TROFÉER · %d SITTER PÅ NÅGON" % [all.size(), worn], 16, Color(1, 1, 1, 0.6))
	if all.is_empty():
		UiStyle.para(self, Vector2(MARGIN, TOP + 30), "Inga troféer än. Besegrade monster lämnar troféer; du väljer vem som bär dem i Förberedelser eller vid en lägereld.",
				18, Color(1, 1, 1, 0.8), size.x - MARGIN * 2, 3)
		return
	if pages > 1:
		small_button(_page_rect(0), "‹")
		small_button(_page_rect(1), "›")
		UiStyle.text(self, Vector2(0, 128), "SIDA %d AV %d" % [page + 1, pages], 16, Color(1, 1, 1, 0.6),
				HORIZONTAL_ALIGNMENT_RIGHT, _page_rect(0).position.x - 12)
	if selected == "" or not all.any(func(e: Dictionary) -> bool: return e.id == selected):
		selected = String(all[0].id)
	for j in _per_page():
		var i := page * _per_page() + j
		if i >= all.size():
			break
		var e: Dictionary = all[i]
		var r := _row_rect(j)
		var on: bool = e.id == selected
		var col: Color = RARITY_COLOR[e.rarity]
		draw_rect(r, Color(0.09, 0.08, 0.12, 0.96) if on else Color(0.06, 0.055, 0.08, 0.85))
		draw_rect(r, UiStyle.TRAIT_GOLD if on else Color(col, 0.4), false, 2.0 if on else 1.0)
		draw_rect(Rect2(r.position, Vector2(5, r.size.y)), col)
		var tag: String = PartyOverview.RARITY_TAG[e.rarity]
		var tag_w := UiStyle.bold().get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		UiStyle.text(self, r.position + Vector2(14, 21), UiStyle.fit(String(e.name), 17, r.size.x - tag_w - 34), 17,
				UiStyle.TRAIT_GOLD if e.place != "" else Color.WHITE)
		UiStyle.text(self, r.position + Vector2(0, 21), tag, 15, col, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 10)
		UiStyle.text(self, r.position + Vector2(14, 41), UiStyle.fit(String(e.place) if e.place != "" else "Ledig", 15,
				r.size.x - 24), 15, Color(1, 1, 1, 0.75 if e.place != "" else 0.45))
	# Den valda troféns text och lärdom.
	var box := Rect2(MARGIN, size.y - DETAIL_H - 16, size.x - MARGIN * 2, DETAIL_H)
	draw_rect(box, Color(0, 0, 0, 0.35))
	draw_rect(box, Color(UiStyle.TRAIT_GOLD, 0.35), false, 1.5)
	var t: Dictionary = data.traits[selected]
	var place := Profile.trophy_place(data, run.profile.worn, run.profile.artifacts, selected)
	UiStyle.text(self, box.position + Vector2(16, 28), UiStyle.fit("%s – %s" % [t.name, place if place != "" else "ledig"], 20,
			box.size.x - 32), 20, UiStyle.TRAIT_GOLD)
	var used := UiStyle.para(self, box.position + Vector2(16, 54), String(t.get("text", "")), 17, Color(1, 1, 1, 0.9),
			box.size.x - 32, 2)
	var bearer := ""
	if place.begins_with("Bärs av "):
		bearer = place.trim_prefix("Bärs av ")
	var lesson := GameData.lesson(data, selected, bearer)
	var ly := box.position.y + 54.0 + used - 2.0
	if lesson != "" and ly + 18.0 < box.end.y:
		UiStyle.lesson(self, Vector2(box.position.x + 16, ly), lesson, box.size.x - 32, 1)


func _draw() -> void:
	header("SÄLLSKAPET", "", load("res://assets/illustrations/sallskapet.webp") as Texture2D)
	small_button(back_rect(), "‹ BORGEN")
	for i in TABS.size():
		chip(_tab_rect(i), TABS[i], tab == i, 17)
	if tab == 0:
		UiStyle.text(self, Vector2(MARGIN, 128), "TRYCK PÅ EN HJÄLTE FÖR HJÄLTEBLADET", 16, Color(1, 1, 1, 0.6))
		_draw_heroes()
	else:
		_draw_collection()
