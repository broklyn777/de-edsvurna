extends TapScreen
## Hjältebladet (0.19): allt om en hjälte, och allt som visas har betydelse.
##   Huvud: namn, roll, nivå, erfarenhet till nästa nivå, fiendernas nivå på valt djup och personligheten.
##   STATS: de fem statsen med uppdelning per källa (bas, nivåer, personlighet, artefakt), vad nästa
##          nivå ger, och vad statsen betyder i skada och helning mot en typisk fiende på valt djup
##          (spelets egna formler). Krit och undvikande visas inte i procent, som i Siralim.
##   EGENSKAPER: egen egenskap (kallet för Paladinen), trofé och artefakt med körningens statistik,
##          förmågorna med Charges och artefakten.
##   HISTORIK: strider, segrar, stupad och väckt, och nivå för nivå vad hjälten fick.
## Öppnas från lägret, Förberedelser och Biblioteket (där personligheten kan bytas mot silver).

const TABS := ["STATS", "EGENSKAPER", "HISTORIK"]

var hero_id := "paladin"
var tab := 0
## Väljaren för personlighet (bara från Biblioteket).
var picking := false


func _ready() -> void:
	super()
	hero_id = run.sheet_hero
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tab="):
			tab = int(arg.get_slice("=", 1))
		elif arg == "--pick" and run.sheet_can_change_personality:
			picking = true  # personlighetsväljaren direkt (för skärmdumpar)


func _heroes() -> Array:
	return run.sheet_heroes if not run.sheet_heroes.is_empty() else [hero_id]


# --- Inmatning --------------------------------------------------------------

func _tap(p: Vector2) -> void:
	var data: Dictionary = run.data
	if back_rect().has_point(p):
		run.go(run.sheet_return)
		return
	if picking:
		var ids: Array = data.personalities.keys()
		for i in ids.size():
			if _pick_rect(i).has_point(p):
				if run.profile.set_personality(data, hero_id, ids[i]):
					run.save("ui_forge")
				picking = false
				return
		picking = false
		return
	var heroes := _heroes()
	var i := heroes.find(hero_id)
	if _arrow_rect(-1).has_point(p) and heroes.size() > 1:
		hero_id = heroes[(i - 1 + heroes.size()) % heroes.size()]
		return
	if _arrow_rect(1).has_point(p) and heroes.size() > 1:
		hero_id = heroes[(i + 1) % heroes.size()]
		return
	for t in TABS.size():
		if _tab_rect(t).has_point(p):
			tab = t
			return
	if run.sheet_can_change_personality and _personality_rect().has_point(p):
		picking = true


# --- Layout -----------------------------------------------------------------

func _arrow_rect(dir: int) -> Rect2:
	return Rect2(size.x / 2 + (dir * 300.0) - 26, 20, 52, 44)


func _tab_rect(t: int) -> Rect2:
	return Rect2(MARGIN + t * 210, 166, 200, 44)


func _personality_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 380, 112, 380, 44)


func _pick_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 4) / 5.0
	return Rect2(MARGIN + (i % 5) * (w + GAP), 196 + (i / 5) * 130, w, 122)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var prof: Profile = run.profile
	var h: Dictionary = data.heroes[hero_id]
	var prog := prof.hero(data, hero_id)
	var level := int(prog.level)
	var pers: Dictionary = data.personalities.get(prog.personality, {})
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	small_button(back_rect(), "‹ TILLBAKA")
	silver_label()
	UiStyle.text(self, Vector2(0, 52), h.name.to_upper(), 34, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 6)
	if _heroes().size() > 1:
		small_button(_arrow_rect(-1), "‹")
		small_button(_arrow_rect(1), "›")
	# Nivå och erfarenhet (inget tak, som i Siralim).
	var need := HeroStats.xp_to_next(level)
	UiStyle.text(self, Vector2(MARGIN, 100), "%s · NIVÅ %d" % [String(h.get("title", h.role)).to_upper(), level], 20,
			Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 600, 3)
	var bar := Rect2(MARGIN, 112, 420, 16)
	UiStyle.bar(self, bar, float(prog.xp) / need, UiStyle.GOLD)
	var bar_text := "%d / %d erfarenhet till nivå %d" % [int(prog.xp), need, level + 1]
	UiStyle.text(self, Vector2(MARGIN, 148), bar_text, 14, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, 420, 2)
	if not picking:
		_draw_enemy_levels(data, prof, level, Vector2(480, 100))
	# Personligheten.
	var pr := _personality_rect()
	draw_rect(pr, Color(0, 0, 0, 0.55))
	draw_rect(pr, Color(UiStyle.TRAIT_GOLD, 0.7 if run.sheet_can_change_personality else 0.3), false, 2.0)
	UiStyle.text(self, pr.position + Vector2(12, 20), "%s: %s 40 %%, %s 20 %%" % [pers.get("name", "?"),
			HeroStats.STAT_NAMES.get(pers.get("up", ""), "–"), HeroStats.STAT_NAMES.get(pers.get("down", ""), "–")], 15,
			UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 20, 2)
	UiStyle.text(self, pr.position + Vector2(12, 38), ("Byt personlighet – %d silver" % Profile.PERSONALITY_COST)
			if run.sheet_can_change_personality else pers.get("text", ""), 13, Color(1, 1, 1, 0.7),
			HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 20, 2)
	if picking:
		_draw_picker(data, prog.personality)
		return
	for t in TABS.size():
		chip(_tab_rect(t), TABS[t], tab == t, 17)
	match tab:
		0:
			_draw_stats(data, prof, prog)
		1:
			_draw_traits(data, prof)
		2:
			_draw_history(data, prog)


func _draw_stats(data: Dictionary, prof: Profile, prog: Dictionary) -> void:
	var level := int(prog.level)
	var art: Dictionary = prof.artifacts.get(hero_id, {})
	var b := HeroStats.breakdown(data, hero_id, level, prog.personality, art)
	var nxt := HeroStats.gains(data, hero_id, level + 1, prog.personality)
	var pers: Dictionary = data.personalities.get(prog.personality, {})
	var y := 250.0
	for stat in HeroStats.STATS:
		var s: Dictionary = b[stat]
		var arrow := " ↑" if pers.get("up", "") == stat else (" ↓" if pers.get("down", "") == stat else "")
		UiStyle.text(self, Vector2(MARGIN, y), HeroStats.STAT_NAMES[stat] + arrow, 18,
				UiStyle.GOLD if arrow == " ↑" else (Color("#ff9a7a") if arrow != "" else Color.WHITE), HORIZONTAL_ALIGNMENT_LEFT, 170, 3)
		UiStyle.text(self, Vector2(MARGIN + 170, y), "%d" % s.total, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 70, 3)
		var text := "="
		for source in HeroStats.SOURCES:
			var v: float = s.get(source, 0.0)
			if source == "base":
				text += " %d %s" % [v, HeroStats.SOURCE_NAMES[source]]
			elif v != 0.0:
				text += (" + %d %s" if v > 0.0 else " − %d %s") % [absf(v), HeroStats.SOURCE_NAMES[source]]
		UiStyle.text(self, Vector2(MARGIN + 260, y), text, 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, 680, 2)
		UiStyle.text(self, Vector2(MARGIN + 960, y), "nästa nivå +%d" % nxt[stat], 14, Color(UiStyle.TRAIT_GOLD, 0.8),
				HORIZONTAL_ALIGNMENT_LEFT, 160, 2)
		y += 34
	_draw_meaning(data, prof, b, level, Vector2(MARGIN, y + 20))


## Fiendernas nivå på valt djup, våning för våning, och om hjälten är rustad för dem.
func _draw_enemy_levels(data: Dictionary, prof: Profile, level: int, at: Vector2) -> void:
	var lv: Array[int] = []
	for f in 3:
		lv.append(roundi(HeroStats.enemy_level(prof.depth, f)))
	UiStyle.text(self, at, "FIENDERNA I %s, DJUP %d" % [String(data.realms[prof.realm].short).to_upper(), prof.depth], 14,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, 380, 2)
	UiStyle.text(self, at + Vector2(0, 24), "Våning 1–3: nivå %d · %d · %d" % [lv[0], lv[1], lv[2]], 17, Color.WHITE,
			HORIZONTAL_ALIGNMENT_LEFT, 380, 2)
	var verdict := "Rustad för hela djupet"
	var color := Color("#8fd18f")
	if level < lv[0]:
		verdict = "Under fienderna – träna på ett lägre djup"
		color = Color("#ff9a7a")
	elif level < lv[1]:
		verdict = "Räcker för våning 1"
		color = UiStyle.TRAIT_GOLD
	elif level < lv[2]:
		verdict = "Räcker för våning 1–2"
		color = UiStyle.TRAIT_GOLD
	UiStyle.text(self, at + Vector2(0, 48), verdict, 14, color, HORIZONTAL_ALIGNMENT_LEFT, 380, 2)


## Vad statsen betyder: skada och helning mot en typisk fiende i vald Realm på valt djup.
func _draw_meaning(data: Dictionary, prof: Profile, b: Dictionary, level: int, at: Vector2) -> void:
	var realm: Dictionary = data.realms[prof.realm]
	var enc_id: String = realm.floors[0]
	var enc: Dictionary = data.encounters[enc_id]
	var kind: String = enc.enemies[0]
	var e: Dictionary = data.enemies[kind]
	var lm := HeroStats.level_mult(HeroStats.enemy_level(prof.depth, 0))
	var m := CombatSim.enemy_mult(enc, prof.depth) * lm
	var e_def := roundf(float(e.stats.defense) * m)
	var e_hp := roundf(float(e.stats.health) * m)
	var e_atk := roundf(float(e.stats.attack) * m)
	var e_spd := roundf(float(e.stats.speed) * lm)
	var lines: Array[String] = []
	var h: Dictionary = data.heroes[hero_id]
	var atk_power := _power(data, h.get("attack_ability", "strike"))
	var hit := CombatSim.attack_damage(b.attack.total, e_def, atk_power)
	lines.append("Anfall: ~%d skada (%d träffar för att fälla den)" % [hit, ceili(e_hp / maxf(hit, 1.0))])
	for ability_id in h.get("abilities", []):
		var ab: Dictionary = data.abilities[ability_id]
		for eff in ab.get("effects", []):
			if eff.type == "damage" and eff.has("power"):
				var dmg := 0.0
				if ab.get("kind", "attack") == "spell":
					var tier: Array = CombatSim.SPELL_TIERS.get(ab.get("tier", ""), [1.0, 0.0])
					dmg = CombatSim.spell_damage(b.intelligence.total * tier[0], e_def, float(eff.power), tier[1])
				else:
					dmg = CombatSim.attack_damage(b.attack.total, e_def, float(eff.power))
				lines.append("%s: ~%d skada" % [ab.name, dmg])
			elif eff.type == "heal" and eff.has("power"):
				lines.append("%s: helar ~%d" % [ab.name, b.intelligence.total * float(eff.power)])
	var taken := CombatSim.attack_damage(e_atk, b.defense.total, 1.0)
	lines.append("Fiendens anfall: ~%d skada mot %s (%d av %d liv)" % [taken, h.name, taken, b.health.total])
	var faster := "snabbare" if b.speed.total > e_spd else ("lika snabb" if b.speed.total == e_spd else "långsammare")
	lines.append("Speed %d mot %d: %s än fienden – snabbare ger fler krittar och fler undvikanden" % [b.speed.total, e_spd, faster])
	UiStyle.text(self, at, "VAD DET BETYDER – mot %s i %s, djup %d, våning 1" % [e.name, realm.short, prof.depth], 15,
			Color(1, 1, 1, 0.6))
	for i in lines.size():
		UiStyle.text(self, at + Vector2(0, 26 + i * 22), lines[i], 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 2)


func _power(data: Dictionary, ability_id: String) -> float:
	for eff in data.abilities.get(ability_id, {}).get("effects", []):
		if eff.type == "damage":
			return float(eff.get("power", 1.0))
	return 1.0


func _draw_traits(data: Dictionary, prof: Profile) -> void:
	var state: RunState = run.state
	var h: Dictionary = data.heroes[hero_id]
	var list: Array = []
	if hero_id == "paladin":
		list.append(prof.oath)
		list.append_array(prof.active_perks(data, prof.oath))
	else:
		list.append_array(h.get("traits", []))
	if state.equipped.has(hero_id):
		list.append(state.equipped[hero_id])
	var y := 246.0
	var seen := []
	for trait_id in list:
		if seen.has(trait_id):
			continue
		seen.append(trait_id)
		var t: Dictionary = data.traits[trait_id]
		var tot: Dictionary = state.trait_totals.get(trait_id, {})
		var stat := ""
		if not tot.is_empty():
			stat = "Denna körning: slog till %d gånger" % int(tot.procs)
			if float(tot.damage) > 0.0:
				stat += ", %d skada" % tot.damage
			if float(tot.heal) > 0.0:
				stat += ", %d helat" % tot.heal
		var tag := "TROFÉ" if t.get("trophy", false) else ("KALL" if trait_id == prof.oath else ("PERK" if t.get("perk", false) else "EGEN"))
		UiStyle.card(self, Rect2(MARGIN, y, 760, 64), t.name, t.text + ("\n" + stat if stat != "" else ""), true,
				UiStyle.TRAIT_GOLD, tag)
		y += 72
		if y > size.y - 80:
			break
	# Förmågor och artefakt till höger.
	var x := MARGIN + 790
	var yy := 246.0
	UiStyle.text(self, Vector2(x, yy), "FÖRMÅGOR", 14, Color(1, 1, 1, 0.6))
	yy += 24
	for ability_id in h.get("abilities", []):
		var ab: Dictionary = data.abilities[ability_id]
		var full := int(ab.get("charges", 0))
		var left := int(state.charges.get(hero_id, {}).get(ability_id, full))
		UiStyle.text(self, Vector2(x, yy), "%s – %d/%d Charges" % [ab.name, left, full], 16, UiStyle.GOLD,
				HORIZONTAL_ALIGNMENT_LEFT, size.x - x - MARGIN, 2)
		draw_multiline_string(UiStyle.bold(), Vector2(x, yy + 20), ab.get("text", ""), HORIZONTAL_ALIGNMENT_LEFT,
				size.x - x - MARGIN, 13, 2, Color(1, 1, 1, 0.7))
		yy += 64
	var art: Dictionary = prof.artifact(hero_id)
	UiStyle.text(self, Vector2(x, yy + 10), "ARTEFAKT", 14, Color(1, 1, 1, 0.6))
	if art.is_empty():
		UiStyle.text(self, Vector2(x, yy + 34), "Ingen – smid en hos Smeden.", 15, Color(1, 1, 1, 0.75))
		return
	var wmax := size.x - x - MARGIN
	var level := int(art.level)
	UiStyle.text(self, Vector2(x, yy + 34), "%s · nivå %d av %d" % [ArtifactText.name_of(data, art).get_slice(" · ", 0), level,
			Forge.LEVEL_MAX], 16, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT, wmax, 2)
	UiStyle.text(self, Vector2(x, yy + 54), "%s · %s" % [ArtifactText.stat_text(data, art), ArtifactText.chance_text(data, art)],
			13, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, wmax, 2)
	# Platserna: vad varje material ger på artefaktens nivå, eller när platsen öppnas.
	var rows: Array = []
	for i in Forge.STAT_SLOT_LEVELS.size():
		rows.append(["amber", art.stat_slots[i], Forge.stat_slot_open(level, i), Forge.STAT_SLOT_LEVELS[i], "Stat"])
	for i in Forge.TRICK_SLOT_LEVELS.size():
		rows.append(["trick", art.trick_slots[i], Forge.trick_slot_open(level, i), Forge.TRICK_SLOT_LEVELS[i], "Trick"])
	var yr := yy + 70
	for row in rows:
		yr += 20
		if not row[2]:
			UiStyle.text(self, Vector2(x + 20, yr), "%s-plats: öppnas på nivå %d" % [row[4], row[3]], 12, Color(1, 1, 1, 0.35),
					HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
			continue
		if row[1] == "":
			UiStyle.text(self, Vector2(x + 20, yr), "%s-plats: tom" % row[4], 12, Color(1, 1, 1, 0.55),
					HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
			continue
		GemArt.draw_find(self, data, {"kind": row[0], "id": row[1], "count": 1}, Vector2(x + 8, yr - 4), 6.0, _t)
		UiStyle.text(self, Vector2(x + 20, yr), "%s: %s" % [ArtifactText.material_name(data, row[1]),
				ArtifactText.material_text(data, row[1], level)], 12, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	yr += 20
	if not Forge.nether_open(level):
		UiStyle.text(self, Vector2(x + 20, yr), "Nether-plats: öppnas på nivå %d" % Forge.NETHER_LEVEL, 12, Color(1, 1, 1, 0.35),
				HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	elif art.nether.is_empty():
		UiStyle.text(self, Vector2(x + 20, yr), "Nether-plats: tom", 12, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	else:
		var st: Dictionary = art.nether
		GemArt.draw_find(self, data, {"kind": "nether", "stone": st}, Vector2(x + 8, yr - 4), 6.0, _t)
		UiStyle.text(self, Vector2(x + 20, yr), "%s Nether Stone (%d): %s" % [Forge.rarity_of(data, st).name, st.number,
				", ".join(Forge.stone_lines(data, st))], 12, Color(Forge.rarity_of(data, st).color), HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)


func _draw_history(data: Dictionary, prog: Dictionary) -> void:
	UiStyle.text(self, Vector2(MARGIN, 250), "Strider %d · segrar %d · stupat %d · väckt %d" % [int(prog.battles), int(prog.wins),
			int(prog.deaths), int(prog.revives)], 18, Color.WHITE)
	var y := 290.0
	var log: Array = prog.get("log", [])
	if log.is_empty():
		UiStyle.text(self, Vector2(MARGIN, y), "Ingen nivå än. Erfarenhet ges när en strid vinns.", 15, Color(1, 1, 1, 0.6))
	for i in range(log.size() - 1, -1, -1):
		var entry: Dictionary = log[i]
		var g := HeroStats.gains(data, hero_id, int(entry.level), prog.personality)
		var parts: Array = []
		for stat in HeroStats.STATS:
			parts.append("+%d %s" % [g[stat], HeroStats.STAT_NAMES[stat]])
		UiStyle.text(self, Vector2(MARGIN, y), "Nivå %d (efter strid %d): %s" % [int(entry.level), int(entry.battle),
				", ".join(parts)], 15, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 2)
		y += 24
		if y > size.y - 30:
			break


func _draw_picker(data: Dictionary, current: String) -> void:
	UiStyle.text(self, Vector2(0, 184), "VÄLJ PERSONLIGHET – %d SILVER (allt räknas om bakåt)" % Profile.PERSONALITY_COST, 16,
			Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, size.x, 3)
	var ids: Array = data.personalities.keys()
	for i in ids.size():
		var p: Dictionary = data.personalities[ids[i]]
		UiStyle.card(self, _pick_rect(i), p.name, "↑ %s 40 %%\n↓ %s 20 %%\n%s" % [HeroStats.STAT_NAMES[p.up],
				HeroStats.STAT_NAMES[p.down], p.text], ids[i] == current, UiStyle.TRAIT_GOLD)
