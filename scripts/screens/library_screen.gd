extends TapScreen
## Biblioteket (Siralims Codex): samlingen av troféer man någonsin hittat, vilket monster de kom
## från och vad de gör, samt sällskapets artefakter.

const PER_ROW := 4


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)


func _trophy_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * (PER_ROW - 1)) / PER_ROW
	return Rect2(MARGIN + (i % PER_ROW) * (w + GAP), 116 + (i / PER_ROW) * 112, w, 102)


func _draw() -> void:
	var data: Dictionary = run.data
	header("BIBLIOTEKET", "Troféerna du har hittat. Ta med en ned i kryptan från Kryptporten, eller prova dem i Övningsgården.")
	small_button(back_rect(), "‹ BASEN")
	var known := 0
	for kind in data.enemies:
		if data.enemies[kind].get("trophy", "") != "":
			known += 1
	UiStyle.text(self, Vector2(MARGIN, 106), "TROFÉER %d / %d" % [run.collection.size(), known], 14, Color(1, 1, 1, 0.6))
	if run.collection.is_empty():
		UiStyle.text(self, Vector2(MARGIN, 150), "Samlingen är tom. Besegra monster i kryptan för att hitta troféer.", 16, Color(1, 1, 1, 0.45))
	for i in run.collection.size():
		var t: Dictionary = data.traits[run.collection[i]]
		UiStyle.card(self, _trophy_rect(i), t.name, t.text, false, UiStyle.TRAIT_GOLD, _source(run.collection[i]).to_upper())

	var y := size.y - 120.0
	UiStyle.text(self, Vector2(MARGIN, y), "ARTEFAKTER", 14, Color(1, 1, 1, 0.6))
	var x := MARGIN
	for hero_id in data.heroes:
		var line := "%s: %s" % [data.heroes[hero_id].name, ArtifactText.name_of(data, run.profile.artifacts.get(hero_id, {}))]
		UiStyle.text(self, Vector2(x, y + 28 + 0), line, 14, Color("#d8dde6"), HORIZONTAL_ALIGNMENT_LEFT, 236, 3)
		x += 245.0


func _source(trophy_id: String) -> String:
	for kind in run.data.enemies:
		if run.data.enemies[kind].get("trophy", "") == trophy_id:
			return run.data.enemies[kind].name
	return ""
