extends TapScreen
## Kampanjkartan (0.18, ersätter Kryptporten): landet på pergament med Realms som områden. Tryck på
## ett område för att välja det; panelen till höger visar djup, instabilitet och våningsregler,
## bossarna x/3 till bosstrofén och klarade quests per djup. Därifrån går man till Förberedelser
## (sällskap och trofé) eller rakt in: kameran glider in i området och rumskartan tar vid.
##
## Varje område är en tuschvinjett ur Drakvalvet (data/realms.json "map": rect i 1280×720, vignette)
## med mjukt tonade kanter mot pergamentet. Fördärvet är ett mörkt bläckflöde över vinjetten som drar
## sig tillbaka mot kanterna för varje klarat djup. Dekoren (kompassros, kartuscher, drake, svärd i
## sten, skelett, häxa, Väktaren) ligger i marginalen och aldrig över det man trycker på.

const PANEL_W := 400.0
const ZOOM_TIME := 0.7
## Hur mycket av området som är befriat per klarat djup (högst FREED_MAX).
const FREED_PER_DEPTH := 0.18
const FREED_MAX := 0.85

var parchment: Parchment
## Vinjetterna (TextureRect med en kantshader) per Realm, och Väktaren bredvid kryptan.
var _vignettes := {}
var _warden: TextureRect
## Häxan vid kitteln: ett hot nära kapellet i marginalen.
var _witch: TextureRect


const VIGNETTE_SHADER := """
shader_type canvas_item;
render_mode blend_mul;
uniform float fade = 0.16;
// Fördärvet: bläck som flyter in från kanterna ända in till "inner" (0 = mitten, 1 = bara kanten).
uniform float inner = 1.2;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.1; a *= 0.5; } return v; }
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float e = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float a = smoothstep(0.0, fade, e) * COLOR.a;
	vec3 c = mix(vec3(1.0), t.rgb, a);
	float d = max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * 2.0;
	float n = fbm(UV * vec2(4.0, 3.0) + vec2(TIME * 0.02, -TIME * 0.035));
	float veins = fbm(UV * vec2(14.0, 10.0) - vec2(0.0, TIME * 0.05));
	float ink = smoothstep(inner - 0.05, inner + 0.05, d + (n - 0.5) * 0.9 + (veins - 0.5) * 0.25);
	c = mix(c, vec3(0.14, 0.07, 0.12), ink * 0.85 * smoothstep(0.0, fade * 0.5, e));
	COLOR = vec4(c, 1.0);
}
"""
## Kamerans glidning in i området när körningen startar (−1 = ingen).
var _zoom_t := -1.0


func _ready() -> void:
	super()
	parchment = Parchment.new()
	add_child(parchment)
	if not run.data.realms.has(run.profile.realm):
		run.profile.realm = "crypt"
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	for realm_id in run.data.realms:
		_vignettes[realm_id] = _vignette_rect(run.data.realms[realm_id].map.vignette, shader)
	_warden = _vignette_rect("vaktaren", shader)
	_witch = _vignette_rect("haxan", shader)


## En vinjett bakom kartans linjer (blandas med pergamentet så att den vita kanten försvinner).
func _vignette_rect(name: String, shader: Shader) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load("res://assets/illustrations/%s.webp" % name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = shader
	r.material = mat
	add_child(r)
	return r


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
		if _rect(realm_id).has_point(p):
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


func _rect(realm_id: String) -> Rect2:
	var r: Array = run.data.realms[realm_id].map.rect
	return Rect2(Vector2(r[0], r[1]) * _scale(), Vector2(r[2], r[3]) * _scale())


func _center(realm_id: String) -> Vector2:
	return _rect(realm_id).get_center()


## Väktaren (hotet bredvid kryptan) uppe till vänster i marginalen.
func _witch_rect() -> Rect2:
	return Rect2(Vector2(296, 176) * _scale(), Vector2(165, 110) * _scale())


func _warden_rect() -> Rect2:
	return Rect2(Vector2(26, 104) * _scale(), Vector2(200, 133) * _scale())


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
	_place_vignettes(zoom, focus)
	draw_set_transform(focus - focus * zoom, 0.0, Vector2.ONE * zoom)
	_draw_decor()
	for realm_id in data.realms:
		_draw_realm(realm_id, realm_id == prof.realm)
	draw_set_transform(Vector2.ZERO)
	if _zoom_t >= 0.0:
		# Mot slutet av glidningen tonar bilden av området fram (samma bild öppnar rumskartan).
		var img: Texture2D = load("res://assets/illustrations/%s.webp" % data.realms[prof.realm].map.zoom_image)
		var a := clampf((_zoom_t - 0.55) / 0.45, 0.0, 1.0)
		var h := size.x * img.get_height() / img.get_width()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.86, 0.68, a))
		draw_texture_rect(img, Rect2(0, (size.y - h) / 2, size.x, h), false, Color(1, 1, 1, a))
		return
	UiStyle.text(self, Vector2(0, 50), "KAMPANJKARTAN", 36, Parchment.INK, HORIZONTAL_ALIGNMENT_CENTER, size.x - PANEL_W, 0)
	UiStyle.text(self, Vector2(0, 76), "Tryck på ett område. Fördärvet viker för varje klarat djup.", 16,
			Parchment.INK_LIGHT, HORIZONTAL_ALIGNMENT_CENTER, size.x - PANEL_W, 0)
	small_button(back_rect(), "‹ BASEN")
	silver_label()
	_draw_panel(data, prof)


## Vinjetterna följer kamerans glidning (de ritas av egna noder bakom linjerna).
func _place_vignettes(zoom: float, focus: Vector2) -> void:
	for realm_id in _vignettes:
		_place(_vignettes[realm_id], _rect(realm_id), zoom, focus)
	_place(_warden, _warden_rect(), zoom, focus)
	_place(_witch, _witch_rect(), zoom, focus)


func _place(node: TextureRect, r: Rect2, zoom: float, focus: Vector2) -> void:
	node.position = focus + (r.position - focus) * zoom
	node.size = r.size * zoom


## Dekoren i marginalen: kompassros, drake i hörnet, svärd i sten och skelett vid kryptan (häxan vid
## kapellet och Väktaren är vinjetter).
func _draw_decor() -> void:
	var ink := Color(InkArt.INK, 0.6)
	var k := _scale()
	InkArt.icon(self, "compass", Vector2(700, 470) * k, 130 * k.y, 0.8)
	InkArt.icon(self, "dragon", Vector2(720, 640) * k, 130 * k.y, 0.8)
	InkArt.icon(self, "sword_in_stone", Vector2(560, 640) * k, 120 * k.y, 0.75)
	InkArt.icon(self, "skeleton", Vector2(78, 596) * k, 150 * k.y, 0.8)


## Ett område: vinjetten (egen nod), fördärvets bläckflöde, ram, kartusch med namnet och bossens sigill.
func _draw_realm(realm_id: String, selected: bool) -> void:
	var prof: Profile = run.profile
	var r := _rect(realm_id)
	var center := r.get_center()
	var cleared := int(prof.realm_depth.get(realm_id, 0))
	# Fördärvet ritas av vinjettens shader: bläcket når in till "inner" och drar sig tillbaka per djup.
	(_vignettes[realm_id].material as ShaderMaterial).set_shader_parameter("inner",
			0.58 + 0.4 * minf(FREED_PER_DEPTH * cleared, FREED_MAX))
	var frame := r.grow(6)
	var pts := PackedVector2Array([frame.position, Vector2(frame.end.x, frame.position.y), frame.end,
			Vector2(frame.position.x, frame.end.y), frame.position])
	for i in 4:
		InkArt.path(self, pts[i], pts[i + 1], Color(InkArt.INK, 0.85 if selected else 0.45), true, 1.6)
	if selected:
		var glow := 0.5 + 0.5 * sin(_t * 3.0)
		draw_rect(r.grow(12), Color(UiStyle.GOLD.darkened(0.2), 0.25 + 0.35 * glow), false, 4.0)
	var name: String = run.data.realms[realm_id].name
	var cart := Rect2(center.x - 190, r.end.y + 2, 380, 58)
	draw_texture_rect(InkArt.icon_texture("cartouche"), cart, false)
	UiStyle.text(self, Vector2(cart.position.x, cart.get_center().y + 4), name.to_upper(), 15, InkArt.INK,
			HORIZONTAL_ALIGNMENT_CENTER, cart.size.x, 0)
	UiStyle.text(self, Vector2(cart.position.x, cart.end.y + 12), "Djup klarat: %d" % cleared, 14, InkArt.INK,
			HORIZONTAL_ALIGNMENT_CENTER, cart.size.x, 0)
	# Sigill för bossen i vinjettens hörn: fylls i takt med segrarna (x/3 till bosstrofén).
	for boss in _bosses(realm_id):
		var wins: int = mini(int(prof.boss_wins.get(boss, 0)), RunState.BOSS_WINS_FOR_TROPHY)
		var at := Vector2(r.end.x - 24, r.position.y + 24)
		draw_circle(at, 18, Color(Parchment.SEAL, 0.35 + 0.2 * wins))
		draw_arc(at, 18, 0, TAU * wins / RunState.BOSS_WINS_FOR_TROPHY, 24, Parchment.SEAL, 4.0)
		UiStyle.text(self, at + Vector2(-30, 6), "%d/%d" % [wins, RunState.BOSS_WINS_FOR_TROPHY], 14, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER, 60, 2)


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
	draw_multiline_string(UiStyle.bold(), Vector2(x, p.position.y + 58), realm.text,
			HORIZONTAL_ALIGNMENT_LEFT, w, 14, 2, Color(1, 1, 1, 0.75))

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
