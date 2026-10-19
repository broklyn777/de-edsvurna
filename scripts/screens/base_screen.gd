extends TapScreen
## Basen mellan körningarna (Siralims slott, förenklat). Härifrån går man till Kryptporten,
## Övningsgården, Edsaltaret, Smeden, Makron och Biblioteket. Förlust och seger på sista våningen leder hit.

const PLACES := [
	{"id": "gate", "name": "Kryptporten", "tag": "TELEPORTATION SHRINE",
		"text": "Välj följeslagare, ta med en trofé och gå ned i kryptan. Varje vunnen strid ger silver."},
	{"id": "practice", "name": "Övningsgården", "tag": "ARENA",
		"text": "Prova sällskapet, makrona och troféerna mot valfria fiender. Inget förloras, Charges är fulla."},
	{"id": "altar", "name": "Edsaltaret", "tag": "ENCHANTED WARDROBE",
		"text": "Välj Paladinens Ed – den gäller hela sällskapet – och köp perks för silver. Återställ gratis."},
	{"id": "smith", "name": "Smeden", "tag": "BLACKSMITH",
		"text": "Smid en artefakt per hjälte: svärd, stav, sköld, hjälm eller stövlar, med en förmåga som slår till av sig själv."},
	{"id": "macros", "name": "Makron", "tag": "MACROS",
		"text": "Skriv om hjältarnas makron: villkor uppifrån och ned, första raden som passar vinner."},
	{"id": "library", "name": "Biblioteket", "tag": "CODEX",
		"text": "Samlingen: troféerna du har hittat och vad de gör, och sällskapets artefakter."},
]


func _tap(p: Vector2) -> void:
	for i in PLACES.size():
		if not _place_rect(i).has_point(p):
			continue
		match PLACES[i].id:
			"gate":
				run.go(run.START_SCENE)
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


func _draw() -> void:
	header("BASEN", "Mellan körningarna. Här byggs sällskapet om – nere i kryptan prövas det.")
	for i in PLACES.size():
		var pl: Dictionary = PLACES[i]
		var r := _place_rect(i)
		var hot: bool = pl.id == "gate"
		UiStyle.card(self, r, pl.name, pl.text, hot, UiStyle.GOLD, pl.tag)
		var extra := _status(pl.id)
		if extra != "":
			UiStyle.text(self, r.position + Vector2(16, r.size.y - 16), extra, 15, Color("#d8dde6"),
					HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 3)
	if run.last_silver > 0:
		UiStyle.text(self, Vector2(0, size.y - 24), "+%d silver från senaste striden" % run.last_silver, 16,
				Color("#d8dde6"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


func _status(id: String) -> String:
	var data: Dictionary = run.data
	match id:
		"gate":
			return "Djup %d · djupaste klarade %d · %d troféer" % [run.profile.depth, run.profile.best_depth,
					run.collection.size()]
		"altar":
			return "%s · %d perks" % [data.traits[run.profile.oath].name,
					run.profile.owned_perks(run.profile.oath).size()]
		"smith":
			return "%d artefakter smidda · %d silver" % [run.profile.artifacts.size(), run.profile.silver]
		"library":
			return "%d troféer i samlingen" % run.collection.size()
		"practice":
			return "Senast: " + data.encounters[run.practice_encounter].name
	return ""
