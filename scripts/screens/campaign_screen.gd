extends TapScreen
## Kampanjkartan (0.18, ersätter Kryptporten): landet på pergament med Realms som områden. Tryck på
## ett område för att välja det; panelen till höger visar djup, instabilitet och våningsregler,
## bossarna x/3 till bosstrofén och klarade quests per djup. Därifrån går man till Förberedelser
## (sällskap och trofé) eller rakt in: kameran glider in i området och rumskartan tar vid.
##
## Fördärvets front: varje område är mörkt av fördärv, och för varje klarat djup växer det befriade,
## ljusa området i mitten (fronten drar sig tillbaka). Områdenas lägen och konturer står i
## data/realms.json ("map": center, outline i 1280×720).

const PANEL_W := 400.0
const ZOOM_TIME := 0.7
## Hur mycket av området som är befriat per klarat djup (högst FREED_MAX).
const FREED_PER_DEPTH := 0.18
const FREED_MAX := 0.85

var parchment: Parchment
## Kamerans glidning in i området när körningen startar (−1 = ingen).
var _zoom_t := -1.0


func _ready() -> void:
	super()
	parchment = Parchment.new()
	add_child(parchment)
	if not run.data.realms.has(run.profile.realm):
		run.profile.realm = "crypt"


func _process(delta: float) -> void:
	super(delta)
	if _zoom_t >= 0.0:
		_zoom_t += delta / ZOOM_TIME
		var center := _center(run.profile.realm)
		var z := 1.0 + 2.2 * _ease(_zoom_t)
		parchment.set_view(z, Vector2(center.x / size.x, center.y / size.y))
		if _zoom_t >= 1.0:
			_zoom_t = -1.0
			run.start_run(run.profile.party)


static func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


# --- Inmatning --------------------------------------------------------------

func _tap(p: Vector2) -> void:
	if _zoom_t >= 0.0:
		return
	var prof: Profile = run.profile
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	for realm_id in run.data.realms:
		if Geometry2D.is_point_in_polygon(p, _outline(realm_id)):
			if prof.realm != realm_id:
				prof.realm = realm_id
				run.save()
			return
	if _depth_rect(-1).has_point(p):
		prof.choose_depth(prof.depth - 1)
		run.save()
	elif _depth_rect(1).has_point(p):
		prof.choose_depth(prof.depth + 1)
		run.save()
	for dir in [-1, 1]:
		if _instability_rect(dir).has_point(p):
			var level: int = clampi(prof.instability + dir, 0, RunState.MAX_INSTABILITY)
			if level != prof.instability:
				prof.instability = level
				run.roll_rules()
				run.save()
			return
	if _prep_rect().has_point(p):
		run.go(run.START_SCENE)
	elif _start_rect().has_point(p) and prof.party.size() == RunState.PARTY_SIZE:
		run.ui("ui_door", -8.0)
		_zoom_t = 0.0


# --- Layout -----------------------------------------------------------------

## Kartans skala: data/realms.json är ritad i 1280×720.
func _scale() -> Vector2:
	return size / Vector2(1280, 720)


func _outline(realm_id: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	for pt in run.data.realms[realm_id].map.outline:
		out.append(Vector2(pt[0], pt[1]) * _scale())
	return out


func _center(realm_id: String) -> Vector2:
	var c: Array = run.data.realms[realm_id].map.center
	return Vector2(c[0], c[1]) * _scale()


func _panel() -> Rect2:
	return Rect2(size.x - PANEL_W - MARGIN, 84, PANEL_W, size.y - 104)


func _depth_rect(dir: int) -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 20 + (0.0 if dir < 0 else 150.0), p.position.y + 104, 44, 44)


func _instability_rect(dir: int) -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 20 + (0.0 if dir < 0 else 150.0), p.position.y + 200, 44, 44)


func _prep_rect() -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 20, p.end.y - 140, p.size.x - 40, 48)


func _start_rect() -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 20, p.end.y - 80, p.size.x - 40, 62)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var prof: Profile = run.profile
	var zoom := 1.0 + 2.2 * _ease(_zoom_t) if _zoom_t >= 0.0 else 1.0
	var focus := _center(prof.realm)
	draw_set_transform(focus - focus * zoom, 0.0, Vector2.ONE * zoom)
	for realm_id in data.realms:
		_draw_realm(realm_id, realm_id == prof.realm)
	draw_set_transform(Vector2.ZERO)
	if _zoom_t >= 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.07, 0.04, _ease(_zoom_t) * 0.5))
		return
	UiStyle.text(self, Vector2(0, 50), "KAMPANJKARTAN", 36, Parchment.INK, HORIZONTAL_ALIGNMENT_CENTER, size.x - PANEL_W, 0)
	UiStyle.text(self, Vector2(0, 76), "Tryck på ett område. Fördärvet viker för varje klarat djup.", 16,
			Parchment.INK_LIGHT, HORIZONTAL_ALIGNMENT_CENTER, size.x - PANEL_W, 0)
	small_button(back_rect(), "‹ BASEN")
	silver_label()
	_draw_panel(data, prof)


## Ett område: fördärvet, det befriade området i mitten, kontur, namn och stämplar.
func _draw_realm(realm_id: String, selected: bool) -> void:
	var prof: Profile = run.profile
	var outline := _outline(realm_id)
	var center := _center(realm_id)
	var cleared := int(prof.realm_depth.get(realm_id, 0))
	draw_colored_polygon(outline, Color(Parchment.CORRUPTION, 0.55))
	# Fronten: det befriade området växer från mitten med varje klarat djup.
	var freed := minf(FREED_PER_DEPTH * cleared + 0.08, FREED_MAX)
	var inner := PackedVector2Array()
	for i in outline.size():
		var wobble := 0.92 + 0.08 * sin(i * 2.3 + _t * 0.6)
		inner.append(center + (outline[i] - center) * freed * wobble)
	draw_colored_polygon(inner, Color(0.95, 0.88, 0.66, 0.85))
	_dashed(inner, Color(Parchment.SEAL, 0.7), 2.0)
	var border := outline.duplicate()
	border.append(outline[0])
	draw_polyline(border, Color(Parchment.INK, 0.95 if selected else 0.55), 4.0 if selected else 2.5, true)
	if selected:
		var glow := 0.5 + 0.5 * sin(_t * 3.0)
		draw_polyline(border, Color(UiStyle.GOLD, 0.25 + 0.3 * glow), 9.0, true)
	var name: String = run.data.realms[realm_id].name
	UiStyle.text(self, center + Vector2(-160, -6), name.to_upper(), 20, Parchment.INK, HORIZONTAL_ALIGNMENT_CENTER, 320, 0)
	UiStyle.text(self, center + Vector2(-160, 18), "Djup klarat: %d" % cleared, 15, Parchment.INK, HORIZONTAL_ALIGNMENT_CENTER, 320, 0)
	# Sigill för bossen: fylls i takt med segrarna (x/3 till bosstrofén).
	for boss in _bosses(realm_id):
		var wins: int = mini(int(prof.boss_wins.get(boss, 0)), RunState.BOSS_WINS_FOR_TROPHY)
		var at := center + Vector2(0, 52)
		draw_circle(at, 18, Color(Parchment.SEAL, 0.25 + 0.25 * wins))
		draw_arc(at, 18, 0, TAU * wins / RunState.BOSS_WINS_FOR_TROPHY, 24, Parchment.SEAL, 4.0)
		UiStyle.text(self, at + Vector2(-30, 6), "%d/%d" % [wins, RunState.BOSS_WINS_FOR_TROPHY], 14, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER, 60, 2)


func _dashed(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var n := int(a.distance_to(b) / 14.0)
		for k in n:
			if k % 2 == 0:
				draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), color, width)


func _bosses(realm_id: String) -> Array:
	var out := []
	for enc_id in run.data.realms[realm_id].floors:
		for kind in run.data.encounters[enc_id].enemies:
			if run.data.enemies[kind].get("boss", false) and not out.has(kind):
				out.append(kind)
	return out


func _draw_panel(data: Dictionary, prof: Profile) -> void:
	var p := _panel()
	draw_rect(p, Color(0.16, 0.11, 0.07, 0.92))
	draw_rect(p, Color(UiStyle.TRAIT_GOLD, 0.6), false, 2.0)
	var realm: Dictionary = data.realms[prof.realm]
	var x := p.position.x + 20
	var w := p.size.x - 40
	UiStyle.text(self, Vector2(x, p.position.y + 34), realm.name.to_upper(), 22, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT, w, 3)
	draw_multiline_string(UiStyle.bold(), Vector2(x, p.position.y + 58), realm.text, HORIZONTAL_ALIGNMENT_LEFT, w, 14, 2,
			Color(1, 1, 1, 0.75))

	# Djup
	UiStyle.text(self, Vector2(x, p.position.y + 98), "DJUP (DJUPASTE KLARADE %d)" % prof.best_depth, 13, Color(1, 1, 1, 0.6))
	small_button(_depth_rect(-1), "−", prof.depth > 1)
	small_button(_depth_rect(1), "+", prof.depth < prof.max_depth())
	UiStyle.text(self, Vector2(x + 44, p.position.y + 138), str(prof.depth), 30, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 106, 4)
	UiStyle.text(self, Vector2(x + 210, p.position.y + 122), "Fiender +%d %%" % roundi((CombatSim.depth_mult(prof.depth) - 1.0) * 100.0),
			13, Color(1, 1, 1, 0.75))
	UiStyle.text(self, Vector2(x + 210, p.position.y + 140), "Silver +%d %%" % roundi(Profile.SILVER_PER_DEPTH * (prof.depth - 1) * 100.0),
			13, Color(1, 1, 1, 0.75))

	# Instabilitet och regler
	UiStyle.text(self, Vector2(x, p.position.y + 194), "INSTABILITET", 13, Color(1, 1, 1, 0.6))
	small_button(_instability_rect(-1), "−", prof.instability > 0)
	small_button(_instability_rect(1), "+", prof.instability < RunState.MAX_INSTABILITY)
	UiStyle.text(self, Vector2(x + 44, p.position.y + 234), str(prof.instability), 30,
			Color("#ff8a6a") if prof.instability > 0 else UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 106, 4)
	var rules: Dictionary = run.pending_rules
	var rule_text := "Inga våningsregler."
	if prof.instability > 0:
		var names: Array = rules.visible.map(func(id: String) -> String: return data.floor_rules[id].name)
		var silver := 0.0
		for id in rules.visible + rules.hidden:
			silver += float(data.floor_rules[id].get("silver", 0.0))
		rule_text = "%s · %d dolda · silver +%d %%" % [", ".join(names), rules.hidden.size(), roundi(silver * 100.0)]
	draw_multiline_string(UiStyle.bold(), Vector2(x, p.position.y + 268), rule_text, HORIZONTAL_ALIGNMENT_LEFT, w, 14, 2,
			UiStyle.TRAIT_GOLD)

	# Bossar och quests
	var y := p.position.y + 318
	for boss in _bosses(prof.realm):
		UiStyle.text(self, Vector2(x, y), "%s: %d/%d segrar till trofén" % [data.enemies[boss].name,
				mini(int(prof.boss_wins.get(boss, 0)), RunState.BOSS_WINS_FOR_TROPHY), RunState.BOSS_WINS_FOR_TROPHY],
				14, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, w, 2)
		y += 22
	var done: Array = []
	for key in prof.quests_done:
		if String(key).get_slice(":", 0) == prof.realm:
			done.append("djup " + String(key).get_slice(":", 1))
	UiStyle.text(self, Vector2(x, y), "Quests klarade: " + (", ".join(done) if not done.is_empty() else "inga än"), 14,
			Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, w, 2)
	UiStyle.text(self, Vector2(x, y + 22), "Perk-poäng: %d (en per ny quest)" % prof.perk_points(), 14,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, w, 2)

	var companions: Array = prof.party.slice(1).map(func(id: String) -> String: return data.heroes[id].name)
	UiStyle.text(self, Vector2(x, _prep_rect().position.y - 10), "Sällskap: Paladinen, " + ", ".join(companions), 13,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, w, 2)
	small_button(_prep_rect(), "FÖRBEREDELSER")
	UiStyle.big_button(self, _start_rect(), "IN I " + str(realm.short).to_upper(), _t, prof.party.size() == RunState.PARTY_SIZE)
