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
		elif arg == "--contrib-demo":  # påhittade bidrag för skärmdumpar (sparas inte)
			run.state.contrib[hero_id] = {"damage": 1240.0, "heal": 340.0, "overheal": 60.0, "shield": 210.0,
					"interrupts": 3.0, "deaths": 1.0}
			run.profile.last_contrib[hero_id] = {"damage": 2310.0, "heal": 95.0, "shield": 40.0}
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
	return Rect2(MARGIN + t * 220, 178, 210, 48)


func _personality_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 440, 92, 440, 64)


## Vänsterkolumnens bredd och högerkolumnens början (0.20.3: bladet använder hela bredden).
func _left_w() -> float:
	return size.x * 0.54 - MARGIN


func _right_x() -> float:
	return MARGIN + _left_w() + 36


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
	var title := String(h.get("title", h.role))
	if hero_id == "paladin" and HeroStats.oath_rank(level) > 0:
		title = Dialog.oath_rank_title(data, HeroStats.oath_rank(level))  # edsgraden (VD 2026-10-25)
	var head_size := 24 if title.length() < 16 else 20  # edsgraden är lång: rymmas före fiendernas nivå (x 470)
	UiStyle.text(self, Vector2(MARGIN, 104), UiStyle.fit("%s · NIVÅ %d" % [title.to_upper(), level], head_size, 455),
			head_size, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 600, 3)
	var bar := Rect2(MARGIN, 118, 420, 18)
	UiStyle.bar(self, bar, float(prog.xp) / need, UiStyle.GOLD)
	var bar_text := "%d / %d erfarenhet till nivå %d" % [int(prog.xp), need, level + 1]
	UiStyle.text(self, Vector2(MARGIN, 160), bar_text, 18, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, 440, 2)
	if not picking:
		_draw_enemy_levels(data, prof, level, Vector2(MARGIN + 470, 100))
	# Personligheten.
	var pr := _personality_rect()
	draw_rect(pr, Color(0, 0, 0, 0.55))
	draw_rect(pr, Color(UiStyle.TRAIT_GOLD, 0.7 if run.sheet_can_change_personality else 0.3), false, 2.0)
	UiStyle.text(self, pr.position + Vector2(14, 26), "%s: ↑ %s 40 %%, ↓ %s 20 %%" % [pers.get("name", "?"),
			HeroStats.STAT_NAMES.get(pers.get("up", ""), "–"), HeroStats.STAT_NAMES.get(pers.get("down", ""), "–")], 19,
			UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 24, 2)
	UiStyle.text(self, pr.position + Vector2(14, 52), ("Tillväxt per nivå (annars 30 %%) · byt för %d silver" % Profile.PERSONALITY_COST)
			if run.sheet_can_change_personality else "Tillväxt per nivå (annars 30 %%). " + pers.get("text", ""), 16, Color(1, 1, 1, 0.75),
			HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 24, 2)
	if picking:
		_draw_picker(data, prog.personality)
		return
	for t in TABS.size():
		chip(_tab_rect(t), TABS[t], tab == t, 19)
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
	var carry := float(prog.get("carry", 0.0))
	var b := HeroStats.breakdown(data, hero_id, level, prog.personality, art, carry)
	var nxt := HeroStats.gains(data, hero_id, level + 1, prog.personality, carry)
	var pers: Dictionary = data.personalities.get(prog.personality, {})
	var lw := _left_w()
	var y := 266.0
	for stat in HeroStats.STATS:
		var s := HeroStats.shown_parts(b[stat])
		var arrow := " ↑" if pers.get("up", "") == stat else (" ↓" if pers.get("down", "") == stat else "")
		UiStyle.text(self, Vector2(MARGIN, y), HeroStats.STAT_NAMES[stat] + arrow, 22,
				UiStyle.GOLD if arrow == " ↑" else (Color("#ff9a7a") if arrow != "" else Color.WHITE), HORIZONTAL_ALIGNMENT_LEFT, 190, 3)
		UiStyle.text(self, Vector2(MARGIN + 180, y), HeroStats.shown(s.total), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 90, 3)
		UiStyle.text(self, Vector2(MARGIN, y), "nästa nivå +%s" % HeroStats.shown(nxt[stat]), 18, Color(UiStyle.TRAIT_GOLD, 0.9),
				HORIZONTAL_ALIGNMENT_RIGHT, lw, 2)
		var text := "="
		for source in HeroStats.SOURCES:
			var v: float = s.get(source, 0.0)
			if source == "base":
				text += " %s %s" % [HeroStats.shown(v), HeroStats.SOURCE_NAMES[source]]
			elif v != 0.0:
				text += (" + %s %s" if v > 0.0 else " − %s %s") % [HeroStats.shown(absf(v)), HeroStats.SOURCE_NAMES[source]]
		UiStyle.text(self, Vector2(MARGIN + 18, y + 25), text, 18, Color(1, 1, 1, 0.72), HORIZONTAL_ALIGNMENT_LEFT, lw - 18, 2)
		y += 62
	# Nästa steg (ChatGPT:s provspel 6): vad som väntar i artefakten och vad det kostar.
	var steps := Forge.next_steps(prof.artifact(hero_id))
	UiStyle.text(self, Vector2(MARGIN, y + 6), "NÄSTA STEG", 16, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, lw, 2)
	for line in steps:
		y += 26
		UiStyle.text(self, Vector2(MARGIN, y + 6), line, 17, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, lw, 2)
	_draw_meaning(data, prof, b, level, Vector2(_right_x(), 266))
	# Vad hjälten har gjort, denna och förra nedstigningen (RunState.contrib, Profile.last_contrib): högra spalten
	# under "Vad det betyder", högst två rader var.
	var rows := RunState.contrib_rows(run.state, prof, hero_id)
	if not rows.is_empty():
		var rx := _right_x()
		var rw := size.x - MARGIN - rx
		var ry := 582.0
		UiStyle.text(self, Vector2(rx, ry), "DET HÄR HAR %s GJORT" % String(data.heroes[hero_id].name).to_upper(), 16,
				Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, rw, 2)
		ry += 8
		for row in rows:
			var now: bool = row[0] == "Denna nedstigning"
			ry += UiStyle.para(self, Vector2(rx, ry + 18), "%s: %s" % row, 17,
					Color.WHITE if now else Color(1, 1, 1, 0.68), rw, 2) + 4


## Fiendernas nivå på valt djup, våning för våning, och om hjälten är rustad för dem.
func _draw_enemy_levels(data: Dictionary, prof: Profile, level: int, at: Vector2) -> void:
	var lv: Array[int] = []
	for f in 3:
		lv.append(roundi(HeroStats.enemy_level(prof.depth + RunState.realm_depth_offset(data, prof.realm), f)))
	var w := _personality_rect().position.x - at.x - 16
	UiStyle.text(self, at, "FIENDERNA I %s, DJUP %d" % [String(data.realms[prof.realm].short).to_upper(), prof.depth], 16,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, w, 2)
	UiStyle.text(self, at + Vector2(0, 28), UiStyle.fit("Fiendernas nivå: %d–%d" % [lv[0], lv[2]], 21, w), 21,
			Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, w, 2)
	var verdict := "Rustad för hela djupet"
	var color := Color("#8fd18f")
	if level < lv[0]:
		# Djup 1 har inget lägre djup att träna på: där kommer nivåerna under körningen.
		verdict = "Under fienderna – nivåerna kommer under körningen" if prof.depth <= 1 \
				else "Under fienderna – träna på djup %d till nivå %d" % [prof.depth - 1, lv[0]]
		color = Color("#ff9a7a")
	elif level < lv[1]:
		verdict = "Räcker för våning 1"
		color = UiStyle.TRAIT_GOLD
	elif level < lv[2]:
		verdict = "Räcker för våning 1–2"
		color = UiStyle.TRAIT_GOLD
	# Två rader i 16 px om det behövs (i 1280 bredd klipptes "… nivåerna kommer under körningen" av), ovanför flikarna.
	UiStyle.para(self, at + Vector2(0, 50), verdict, 16, color, w, 2)


## Vad statsen betyder: skada och helning mot en typisk fiende i vald Realm på valt djup.
## 0.21: räknas av simulatorn själv (CombatSim.expected_damage) på riktiga figurer, med fiendens egenskaper
## (t.ex. Benrustning) och artefakten, så att bladet och striden alltid säger samma sak.
var _meaning_key := ""
var _meaning_lines: Array[String] = []
var _meaning_sub := ""


func _draw_meaning(data: Dictionary, prof: Profile, _b: Dictionary, level: int, at: Vector2) -> void:
	var prog := prof.hero(data, hero_id)
	var art: Dictionary = prof.artifact(hero_id)
	var key := "%s|%d|%s|%s|%d|%s" % [hero_id, level, prog.personality, str(art), prof.depth, prof.realm]
	if key != _meaning_key:
		_meaning_key = key
		_build_meaning(data, prof, level, prog.personality, art)
	var w := size.x - MARGIN - at.x
	draw_rect(Rect2(at - Vector2(18, 28), Vector2(w + 18, 62 * 5 + 8)), Color(1, 1, 1, 0.035))
	UiStyle.text(self, at, "VAD DET BETYDER", 18, Color(1, 1, 1, 0.65), HORIZONTAL_ALIGNMENT_LEFT, w, 2)
	var y := at.y + 30 + UiStyle.para(self, Vector2(at.x, at.y + 26), _meaning_sub, 17, Color(1, 1, 1, 0.55), w)
	for line in _meaning_lines:
		y += 6 + UiStyle.para(self, Vector2(at.x, y), line, 19, Color.WHITE, w, 2)


## 0.23.3: bladet räknar mot sällskapet man har valt (med hjälten i), inte mot hjälten ensam. Ensam skalades
## fienden efter ett sällskap på en (CombatSim.PARTY_SCALE, ×0,45) och bladet visade för lite skada tagen och för
## få träffar för att fälla den.
static func sheet_party(prof: Profile, id: String) -> Array:
	var party: Array = prof.party.duplicate()
	if not party.has(id):
		if party.size() >= prof.party_slots():
			party.pop_back()
		party.append(id)
	return party


## Paladinens kall och perks, som i striden (RunState.hero_traits); de andra har sina egna egenskaper.
static func sheet_traits(data: Dictionary, prof: Profile) -> Dictionary:
	return {"paladin": [prof.oath] + prof.active_perks(data, prof.oath)}


func _build_meaning(data: Dictionary, prof: Profile, level: int, personality: String, art: Dictionary) -> void:
	var realm: Dictionary = data.realms[prof.realm]
	var enc_id: String = realm.floors[0]
	var arts := {} if art.is_empty() else {hero_id: art}
	var sim := CombatSim.create(data, enc_id, 1, sheet_party(prof, hero_id), sheet_traits(data, prof), {}, arts,
			prof.depth, {"levels": {hero_id: {"level": level, "personality": personality, "carry": prof.carry(data, hero_id)}},
			"elite_chance": 0.0, "floor": 0, "depth_offset": RunState.realm_depth_offset(data, prof.realm)})
	var hero := sim.unit(hero_id)
	var foe: CombatUnit = sim.enemies[0]
	_meaning_sub = "mot %s (nivå %d) i %s, djup %d, våning 1" % [foe.name, roundi(foe.level), realm.short, prof.depth]
	_meaning_lines.clear()
	var hit := sim.expected_damage(hero, foe, hero.attack_ability)
	_meaning_lines.append("Anfall: ~%d skada (%d träffar för att fälla den)" % [hit, ceili(foe.max_hp / maxf(hit, 1.0))])
	for ability_id in hero.abilities:
		var ab: Dictionary = sim.data.abilities[ability_id]
		for eff in ab.get("effects", []):
			if eff.type == "damage" and eff.has("power"):
				_meaning_lines.append("%s: ~%d skada" % [ab.name, sim.expected_damage(hero, foe, ability_id)])
			elif eff.type == "heal" and eff.has("power"):
				_meaning_lines.append("%s: helar ~%d" % [ab.name, sim.expected_heal(hero, hero, ability_id)])
	var taken := sim.expected_damage(foe, hero, foe.attack_ability)
	sim._add_aura(hero, hero, "defend")
	var defended := sim.expected_damage(foe, hero, foe.attack_ability)
	_meaning_lines.append("Fiendens anfall: ~%d skada mot %s (%d om %s försvarar sig) av %d liv" % [taken, hero.name,
			defended, hero.name, hero.max_hp])
	var faster := "snabbare" if hero.speed > foe.speed else ("lika snabb" if hero.speed == foe.speed else "långsammare")
	_meaning_lines.append("Speed %s mot %s: %s än fienden – snabbare ger fler kritiska träffar och fler undvikanden" % [
			HeroStats.shown(hero.speed), HeroStats.shown(foe.speed), faster])


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
	# trofeplats: den andra trofén, i artefaktens troféplats.
	var slot_art := prof.artifact(hero_id)
	var art_trophy := ""
	if not slot_art.is_empty() and Forge.trophy_open(int(slot_art.level)) and slot_art.trophy != "" \
			and data.traits.has(slot_art.trophy):
		art_trophy = slot_art.trophy
		list.append(art_trophy)
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
		var tag := "ARTEFAKTENS TROFÉ" if trait_id == art_trophy else "TROFÉ" if t.get("trophy", false) else ("KALL" if trait_id == prof.oath else ("PERK" if t.get("perk", false) else "EGEN"))
		var body: String = t.text + ("\n" + stat if stat != "" else "")
		var lines := ceili(UiStyle.bold().get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.BODY_SIZE).x
				/ (_left_w() - 40)) + (1 if stat != "" else 0)
		var ch := 44.0 + 22.0 * clampi(lines, 1, 4)
		# Troféns lärdom (VD 2026-10-23): kursiv under effekten, i samma kort.
		var lesson := GameData.lesson(data, trait_id, String(h.name)) if t.get("trophy", false) else ""
		var lesson_h := 0.0
		if lesson != "":
			lesson_h = UiStyle.italic().get_multiline_string_size(lesson, HORIZONTAL_ALIGNMENT_LEFT, _left_w() - 28,
					UiStyle.LESSON_SIZE, 2).y + 2.0
		UiStyle.card(self, Rect2(MARGIN, y, _left_w(), ch + lesson_h), t.name, body, true, UiStyle.TRAIT_GOLD, tag, 0.0, lesson_h)
		if lesson != "":
			UiStyle.lesson(self, Vector2(MARGIN + 16, y + ch + 10), lesson, _left_w() - 28, 2)
		ch += lesson_h
		y += ch + 8
		if y > size.y - 80:
			break
	# Förmågor och artefakt till höger.
	var x := _right_x()
	var wr := size.x - x - MARGIN
	var yy := 256.0
	UiStyle.text(self, Vector2(x, yy), "FÖRMÅGOR", 16, Color(1, 1, 1, 0.6))
	yy += 28
	for ability_id in h.get("abilities", []):
		var ab: Dictionary = data.abilities[ability_id]
		var full := int(ab.get("charges", 0))
		var left := int(state.charges.get(hero_id, {}).get(ability_id, full))
		UiStyle.text(self, Vector2(x, yy), "%s – %d/%d Charges" % [ab.name, left, full], 19, UiStyle.GOLD,
				HORIZONTAL_ALIGNMENT_LEFT, wr, 2)
		yy += 30 + UiStyle.para(self, Vector2(x, yy + 24), ab.get("text", ""), 17, Color(1, 1, 1, 0.75), wr, 2)
	var art: Dictionary = prof.artifact(hero_id)
	UiStyle.text(self, Vector2(x, yy + 10), "ARTEFAKT", 16, Color(1, 1, 1, 0.6))
	if art.is_empty():
		UiStyle.text(self, Vector2(x, yy + 36), "Ingen – smid en hos Smeden.", 18, Color(1, 1, 1, 0.75))
		return
	var wmax := wr
	var level := int(art.level)
	UiStyle.text(self, Vector2(x, yy + 34), "%s · nivå %d av %d" % [ArtifactText.name_of(data, art).get_slice(" · ", 0), level,
			Forge.LEVEL_MAX], 19, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT, wmax, 2)
	UiStyle.text(self, Vector2(x, yy + 58), "%s · %s" % [ArtifactText.stat_text(data, art), ArtifactText.chance_text(data, art)],
			16, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, wmax, 2)
	# Platserna: vad varje material ger på artefaktens nivå, eller när platsen öppnas.
	var rows: Array = []
	for i in Forge.STAT_SLOT_LEVELS.size():
		rows.append(["amber", art.stat_slots[i], Forge.stat_slot_open(level, i), Forge.STAT_SLOT_LEVELS[i], "Stat"])
	for i in Forge.TRICK_SLOT_LEVELS.size():
		rows.append(["trick", art.trick_slots[i], Forge.trick_slot_open(level, i), Forge.TRICK_SLOT_LEVELS[i], "Trick"])
	var yr := yy + 64
	for row in rows:
		yr += 23
		if not row[2]:
			UiStyle.text(self, Vector2(x + 20, yr), "%s-plats: öppnas på nivå %d" % [row[4], row[3]], 16, Color(1, 1, 1, 0.35),
					HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
			continue
		if row[1] == "":
			UiStyle.text(self, Vector2(x + 20, yr), "%s-plats: tom" % row[4], 16, Color(1, 1, 1, 0.55),
					HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
			continue
		GemArt.draw_find(self, data, {"kind": row[0], "id": row[1], "count": 1}, Vector2(x + 8, yr - 6), 8.0, _t)
		UiStyle.text(self, Vector2(x + 20, yr), "%s: %s" % [ArtifactText.material_name(data, row[1]),
				ArtifactText.material_text(data, row[1], level)], 16, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	yr += 23
	if not Forge.nether_open(level):
		UiStyle.text(self, Vector2(x + 20, yr), "Nether-plats: öppnas på nivå %d" % Forge.NETHER_LEVEL, 16, Color(1, 1, 1, 0.35),
				HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	elif art.nether.is_empty():
		UiStyle.text(self, Vector2(x + 20, yr), "Nether-plats: tom", 16, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	else:
		var st: Dictionary = art.nether
		GemArt.draw_find(self, data, {"kind": "nether", "stone": st}, Vector2(x + 8, yr - 4), 6.0, _t)
		UiStyle.text(self, Vector2(x + 20, yr), "%s Nether Stone (%d): %s" % [Forge.rarity_of(data, st).name, st.number,
				", ".join(Forge.stone_lines(data, st))], 16, Color(Forge.rarity_of(data, st).color), HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	# trofeplats: troféplatsen (trofén själv står bland egenskaperna till vänster).
	yr += 23
	if not Forge.trophy_open(level):
		UiStyle.text(self, Vector2(x + 20, yr), "Troféplats: öppnas på nivå %d" % Forge.TROPHY_LEVEL, 16, Color(1, 1, 1, 0.35),
				HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	elif art.trophy == "" or not data.traits.has(art.trophy):
		UiStyle.text(self, Vector2(x + 20, yr), "Troféplats: tom (sätts hos Smeden)", 16, Color(1, 1, 1, 0.55),
				HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)
	else:
		UiStyle.text(self, Vector2(x + 20, yr), "Troféplats: %s" % data.traits[art.trophy].name, 16, UiStyle.TRAIT_GOLD,
				HORIZONTAL_ALIGNMENT_LEFT, wmax - 20, 0)


func _draw_history(data: Dictionary, prog: Dictionary) -> void:
	UiStyle.text(self, Vector2(MARGIN, 250), "Strider %d · segrar %d · stupat %d · väckt %d" % [int(prog.battles), int(prog.wins),
			int(prog.deaths), int(prog.revives)], 22, Color.WHITE)
	var y := 300.0
	var log: Array = prog.get("log", [])
	if log.is_empty():
		UiStyle.text(self, Vector2(MARGIN, y), "Ingen nivå än. Erfarenhet ges när en strid vinns.", 19, Color(1, 1, 1, 0.6))
	for i in range(log.size() - 1, -1, -1):
		var entry: Dictionary = log[i]
		var g := HeroStats.gains(data, hero_id, int(entry.level), prog.personality)
		var parts: Array = []
		for stat in HeroStats.STATS:
			parts.append("+%s %s" % [HeroStats.shown(g[stat]), HeroStats.STAT_NAMES[stat]])
		UiStyle.text(self, Vector2(MARGIN, y), "Nivå %d (efter strid %d): %s" % [int(entry.level), int(entry.battle),
				", ".join(parts)], 19, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 2)
		y += 30
		if y > size.y - 30:
			break


func _draw_picker(data: Dictionary, current: String) -> void:
	UiStyle.text(self, Vector2(0, 184), "VÄLJ PERSONLIGHET – %d SILVER (allt räknas om bakåt)" % Profile.PERSONALITY_COST, 19,
			Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, size.x, 3)
	var ids: Array = data.personalities.keys()
	for i in ids.size():
		var p: Dictionary = data.personalities[ids[i]]
		UiStyle.card(self, _pick_rect(i), p.name, "↑ %s växer 40 %%\n↓ %s bara 20 %%\n%s" % [HeroStats.STAT_NAMES[p.up],
				HeroStats.STAT_NAMES[p.down], p.text], ids[i] == current, UiStyle.TRAIT_GOLD)
