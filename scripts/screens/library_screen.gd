extends TapScreen
## Biblioteket (Siralims Codex): samlingen av troféer man någonsin hittat, vilket monster de kom
## från och vad de gör, samt sällskapets artefakter.

const PER_ROW := 5
const RARITY := {"common": "VANLIG", "elite": "ELIT", "boss": "BOSS"}


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)


func _trophy_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * (PER_ROW - 1)) / PER_ROW
	return Rect2(MARGIN + (i % PER_ROW) * (w + GAP), 116 + (i / PER_ROW) * 88, w, 80)


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
	return out


func _draw() -> void:
	var data: Dictionary = run.data
	header("BIBLIOTEKET", "Alla troféer. Elitfiender är sällsynta (fler på djupare och instabilare våningar); bossens trofé kräver tre segrar.")
	small_button(back_rect(), "‹ BASEN")
	var all := _all_trophies()
	UiStyle.text(self, Vector2(MARGIN, 106), "TROFÉER %d / %d" % [run.collection.size(), all.size()], 14, Color(1, 1, 1, 0.6))
	for i in all.size():
		var entry: Dictionary = all[i]
		var t: Dictionary = data.traits[entry.trophy]
		var d: Dictionary = data.enemies[entry.kind]
		var realm_name: String = data.realms[entry.realm].short
		var boss: bool = d.get("boss", false)
		var tag: String = RARITY["boss" if boss else ("elite" if entry.elite else "common")]
		if boss:
			tag += " %d/%d" % [mini(int(run.profile.boss_wins.get(entry.kind, 0)), RunState.BOSS_WINS_FOR_TROPHY),
					RunState.BOSS_WINS_FOR_TROPHY]
		if run.collection.has(entry.trophy):
			var source: String = d.elite.name if entry.elite else d.name
			UiStyle.card(self, _trophy_rect(i), t.name, "%s (%s)" % [t.text, source], false, UiStyle.TRAIT_GOLD, tag)
		else:
			var hint := "Från ett monster i %s." % realm_name
			if entry.elite:
				hint = "Från en sällsynt elitfiende i %s." % realm_name
			elif boss:
				hint = "Från %s, efter %d segrar." % [d.name, RunState.BOSS_WINS_FOR_TROPHY]
			UiStyle.card(self, _trophy_rect(i), "Okänd trofé", hint, false, Color("#8a93a6"), tag)

	var y := size.y - 120.0
	UiStyle.text(self, Vector2(MARGIN, y), "ARTEFAKTER", 14, Color(1, 1, 1, 0.6))
	var x := MARGIN
	for hero_id in data.heroes:
		var line := "%s: %s" % [data.heroes[hero_id].name, ArtifactText.name_of(data, run.profile.artifacts.get(hero_id, {}))]
		UiStyle.text(self, Vector2(x, y + 28 + 0), line, 14, Color("#d8dde6"), HORIZONTAL_ALIGNMENT_LEFT, 236, 3)
		x += 245.0
