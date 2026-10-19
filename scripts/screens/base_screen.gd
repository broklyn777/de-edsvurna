extends TapScreen
## Basen mellan körningarna (Siralims slott, förenklat). Härifrån går man till Kampanjkartan,
## Övningsgården, Kallets altare, Smeden, Makron och Biblioteket. Förlust och seger på sista våningen leder hit.

## Borgen med smedja, bibliotekstorn och altargård tonad i bakgrunden (VD:ns illustration).
const BASE_ART := preload("res://assets/illustrations/basen.webp")

const PLACES := [
	{"id": "gate", "name": "Kampanjkartan", "tag": "TELEPORTATION SHRINE",
		"text": "Landet och dess Realms. Välj Realm, djup och instabilitet, förbered sällskapet och gå in."},
	{"id": "practice", "name": "Övningsgården", "tag": "ARENA",
		"text": "Prova sällskapet, makrona och troféerna mot valfria fiender. Inget förloras, Charges är fulla."},
	{"id": "altar", "name": "Kallets altare", "tag": "ENCHANTED WARDROBE",
		"text": "Välj Paladinens kall – det gäller hela sällskapet – och köp perks för perk-poäng. Återställ gratis."},
	{"id": "smith", "name": "Smeden", "tag": "BLACKSMITH",
		"text": "Smid en artefakt per hjälte och höj den: nivåerna öppnar platser för bärnsten, trick och Nether Stones."},
	{"id": "macros", "name": "Makron", "tag": "MACROS",
		"text": "Skriv om hjältarnas makron: villkor uppifrån och ned, första raden som passar vinner."},
	{"id": "library", "name": "Biblioteket", "tag": "CODEX",
		"text": "Samlingen: troféerna du har hittat och vad de gör, och sällskapets artefakter."},
]


func _tap(p: Vector2) -> void:
	# Sällskapet (0.20.1): ett tryck öppnar hjältebladet, pilarna där bläddrar mellan hjältarna.
	var party: Array = run.profile.party
	for i in party.size():
		if _hero_rect(i).has_point(p):
			run.open_sheet(party[i], party, run.BASE_SCENE)
			return
	for i in PLACES.size():
		if not _place_rect(i).has_point(p):
			continue
		match PLACES[i].id:
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
		return


func _place_rect(i: int) -> Rect2:
	var top := 120.0
	var h := 220.0
	var w := (size.x - MARGIN * 2 - GAP * 2) / 3.0
	if i < 3:
		return Rect2(MARGIN + i * (w + GAP), top, w, h)
	return Rect2(MARGIN + (i - 3) * (w + GAP), top + h + GAP, w, h - 50)


func _hero_rect(i: int) -> Rect2:
	var n: int = maxi(run.profile.party.size(), 1)
	var w := (size.x - MARGIN * 2 - GAP * (n - 1)) / n
	return Rect2(MARGIN + i * (w + GAP), 572, w, 84)


## Sällskapets hjältar längst ned: namn, nivå, personlighet och en tunn mätare till nästa nivå.
func _draw_party() -> void:
	var data: Dictionary = run.data
	var party: Array = run.profile.party
	UiStyle.text(self, Vector2(MARGIN, 562), "SÄLLSKAPET – TRYCK FÖR HJÄLTEBLADET", 13, Color(1, 1, 1, 0.55))
	for i in party.size():
		var r := _hero_rect(i)
		var h: Dictionary = data.heroes[party[i]]
		var prog: Dictionary = run.profile.hero(data, party[i])
		var level := int(prog.level)
		draw_rect(r, Color(0.04, 0.035, 0.06, 0.82))
		draw_rect(r, Color(Color(h.color), 0.5), false, 1.5)
		draw_rect(Rect2(r.position, Vector2(5, r.size.y)), Color(h.color))
		UiStyle.text(self, r.position + Vector2(18, 28), h.name, 18, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 110, 3)
		UiStyle.text(self, r.position + Vector2(0, 28), "NIVÅ %d" % level, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT,
				r.size.x - 14, 3)
		var pers: Dictionary = data.personalities.get(prog.personality, {})
		UiStyle.text(self, r.position + Vector2(18, 50), "%s · %s" % [h.get("title", h.role), pers.get("name", "")], 13,
				Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 30, 2)
		var need := HeroStats.xp_to_next(level)
		UiStyle.bar(self, Rect2(r.position + Vector2(18, 62), Vector2(r.size.x - 36, 6)), float(prog.xp) / need, UiStyle.GOLD)
		UiStyle.text(self, r.position + Vector2(0, 80), "%d / %d" % [int(prog.xp), need], 11, Color(1, 1, 1, 0.45),
				HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18, 0)


func _draw() -> void:
	header("BASEN", "Mellan körningarna. Här byggs sällskapet om – nere i kryptan prövas det.", BASE_ART)
	for i in PLACES.size():
		var pl: Dictionary = PLACES[i]
		var r := _place_rect(i)
		var hot: bool = pl.id == "gate"
		UiStyle.card(self, r, pl.name, pl.text, hot, UiStyle.GOLD, pl.tag)
		var extra := _status(pl.id)
		if extra != "":
			UiStyle.text(self, r.position + Vector2(16, r.size.y - 16), extra, 15, Color("#d8dde6"),
					HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 3)
	_draw_party()
	if run.last_silver > 0:
		UiStyle.text(self, Vector2(0, size.y - 34), "+%d silver från senaste striden" % run.last_silver, 16,
				Color("#d8dde6"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


func _status(id: String) -> String:
	var data: Dictionary = run.data
	match id:
		"gate":
			return "Djup %d · djupaste klarade %d · %d quests klarade" % [run.profile.depth, run.profile.best_depth,
					run.profile.quests_done.size()]
		"altar":
			return "%s · %d perks" % [data.traits[run.profile.oath].name,
					run.profile.owned_perks(run.profile.oath).size()]
		"smith":
			var stones: int = run.profile.stones.size()
			return "%d artefakter smidda · %d silver%s" % [run.profile.artifacts.size(), run.profile.silver,
					"" if stones == 0 else " · %d Nether Stones" % stones]
		"library":
			return "%d troféer i samlingen" % run.collection.size()
		"practice":
			return "Senast: " + data.encounters[run.practice_encounter].name
	return ""
