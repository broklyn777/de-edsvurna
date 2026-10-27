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
## Prototyp (sallskap-fem): varningen under en Realm som är byggd för fler än profilen har platser för (Trollberget).
const FIVE_WARNING := "Byggt för fem i sällskapet – här får fyra stryk"
const ZOOM_TIME := 0.7
## Hur mycket av området som är befriat per klarat djup (högst FREED_MAX).
const FREED_PER_DEPTH := 0.18
const FREED_MAX := 0.85
## Den levande kartan: hur mycket närmare mitten bläcket når per steg av fördärvet (steg 1 = som förut).
const GROWTH_INK := 0.09

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
// Den levande kartan: Realmens fördärv 0–4 gör bläcket tätare och mörkare.
uniform float growth = 1.0;
// karta-synlig: bläcket andas (når in och drar sig ut) i en levande Realm; 0 = stilla. flow 0 = bläcket flyter inte alls.
uniform float breath = 0.0;
uniform float flow = 1.0;
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
	float tm = TIME * flow;
	float n = fbm(UV * vec2(4.0, 3.0) + vec2(tm * 0.02, -tm * 0.035));
	float veins = fbm(UV * vec2(14.0, 10.0) - vec2(0.0, tm * 0.05));
	// Andningen: långsam, med en ojämn rytm så att den inte ser ut som en maskin.
	float b = breath * (0.65 * sin(TIME * 1.3) + 0.35 * sin(TIME * 2.9 + 1.0));
	float ink = smoothstep(inner - 0.05, inner + 0.05, d + b + (n - 0.5) * 0.9 + (veins - 0.5) * 0.25);
	// Steg 0 (lugnt): tunnare och brunare bläck, som gammal tusch; från steg 1 det mörka fördärvet.
	float calm = 1.0 - clamp(growth, 0.0, 1.0);
	float dense = 0.75 - 0.33 * calm + 0.05 * growth + breath * 1.5 * (0.5 + 0.5 * sin(TIME * 1.3));
	vec3 ink_col = mix(vec3(0.14, 0.07, 0.12) * (1.0 - 0.12 * growth), vec3(0.45, 0.34, 0.22), calm);
	c = mix(c, ink_col, ink * dense * smoothstep(0.0, fade * 0.5, e));
	COLOR = vec4(c, 1.0);
}
"""
## Kamerans glidning in i området när körningen startar (−1 = ingen).
var _zoom_t := -1.0
## 0.30.17: rutan där löftet väljs (data/vows.json) är öppen.
var _vow_open := false
## Den levande kartan: hemkomstens nyheter (Profile.growth_news) visas i en ruta tills man trycker.
var _news_open := false


func _ready() -> void:
	super()
	_vow_open = "--vows" in OS.get_cmdline_user_args()  # 0.30.17: löftesrutan öppen (skärmdumpar)
	# Den levande världen: hemkomsten visas i borgen (base_screen); rutan här bara för --news (äldre skärmdumpar).
	_news_open = "--news" in OS.get_cmdline_user_args() and (not run.profile.growth_news.get("lines", []).is_empty()
			or _has_homecoming(run.profile))
	_offer_help.call_deferred()
	parchment = Parchment.new()
	add_child(parchment)
	if not run.data.realms.has(run.profile.realm) \
			or (not run.dev_profile and not RunState.realm_open(run.profile, run.data, run.profile.realm)):
		run.profile.realm = "crypt"
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	for realm_id in run.data.realms:
		_vignettes[realm_id] = _vignette_rect(run.data.realms[realm_id].map.vignette, shader)
	_warden = _vignette_rect("vaktaren", shader)
	_witch = _vignette_rect("haxan", shader)


## Hjälprutorna: djup och instabilitet efter den första nedstigningen (0.25, den första hålls enkel), och första gången
## något har vuxit på den levande kartan "Den levande kartan" med en pil mot området som växte (karta-synlig).
func _offer_help() -> void:
	var prof: Profile = run.profile
	var wanted := []
	if prof.total_descents() > 0:
		wanted = ["depth", "instability"]
	if prof.intro_done and prof.omen != "":
		wanted.append("omens")  # 0.30.45 Djupets tecken
	var grown := LivingMap.grown_realm(prof, run.data) if prof.intro_done else ""
	if grown != "":
		wanted.push_front("living_map")  # först: det är den nya (pilen pekar medan den syns)
	if wanted.is_empty():
		return
	var box := HelpBox.offer(self, wanted)
	if box != null and grown != "":
		box.focus = {"living_map": _rect(grown)}


## 0.30.45 Djupets tecken: "DET HÄR DJUPET: <tecken>" med regeln, och SLUMPA OM för silver en gång. Höjden som gick åt.
var _omen_button := Rect2()


func _draw_omen(x: float, y: float, w: float) -> float:
	var prof: Profile = run.profile
	_omen_button = Rect2()
	if not prof.intro_done or prof.omen == "" or not run.data.floor_rules.has(prof.omen):
		return 0.0
	var rule: Dictionary = run.data.floor_rules[prof.omen]
	var bw := 96.0
	UiStyle.text(self, Vector2(x, y), UiStyle.fit("Det här djupet: " + String(rule.name), 17, w - bw - 8), 17,
			UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT, w - bw - 8, 3)
	if not prof.omen_rerolled:
		_omen_button = Rect2(x + w - bw, y - 22, bw, 30)
		draw_rect(_omen_button, Color(0, 0, 0, 0.6))
		draw_rect(_omen_button, Color(UiStyle.TRAIT_GOLD, 0.7 if run.can_reroll_omen() else 0.2), false, 2.0)
		UiStyle.text(self, _omen_button.position + Vector2(0, 21), "BYT · %d" % RunState.OMEN_REROLL_COST, 15,
				UiStyle.TRAIT_GOLD if run.can_reroll_omen() else Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER, bw)
	var h := UiStyle.para(self, Vector2(x, y + 20), String(rule.text), 15, Color("#e8d8b0"), w, 2)
	return 24.0 + h


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


## Prestanda (Run.update_fps): 60 bilder per sekund medan kameran glider in i ett område.
func wants_smooth() -> bool:
	return _zoom_t >= 0.0


## Androids bakåtknapp (Run.go_back): stänger nyheterna eller löftesrutan; annars frågar Run om spelet ska avslutas.
func go_back() -> bool:
	if _zoom_t >= 0.0:
		return true
	if _news_open or _vow_open:
		_tap(Vector2(-1000, -1000))  # ett tryck utanför stänger rutan som vanligt
		return true
	return false


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
	if _news_open:
		_news_open = false
		prof.growth_news = {}
		prof.homecoming = {}
		run.save("ui_page")
		queue_redraw()
		return
	if _vow_open:
		_tap_vow(p)
		return
	if _vows_on() and _vow_rect().has_point(p):
		_vow_open = true
		run.ui("ui_page", -10.0)
		queue_redraw()
		return
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	for realm_id in run.data.realms:
		if _rect(realm_id).has_point(p):
			if not RunState.realm_open(prof, run.data, realm_id):
				run.ui("ui_page", -14.0)  # stängd (Trollberget före kapellet): raden under området säger varför
				return
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
	if _omen_button.has_point(p):
		if run.reroll_omen():
			run.ui("ui_confirm", -8.0)
		else:
			run.ui("ui_page", -14.0)
		return
	if _prep_rect().has_point(p):
		run.go(run.START_SCENE)
	elif _start_rect().has_point(p) and RunState.can_start(prof):
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
	var w := p.size.x - 40
	return Rect2(p.position.x + 20, p.end.y - 140, (w - 10) / 2.0 if _vows_on() else w, 48)


## 0.30.17: LÖFTE bredvid FÖRBEREDELSER, efter introt (som Värdshuset).
func _vows_on() -> bool:
	return run.profile.intro_done and not run.data.get("vows", {}).is_empty()


func _vow_rect() -> Rect2:
	var r := _prep_rect()
	return Rect2(r.end.x + 10, r.position.y, r.size.x, r.size.y)


func _vow_ids() -> Array:
	return [""] + run.data.vows.keys().filter(func(k: String) -> bool: return not k.begins_with("_"))


func _vow_box() -> Rect2:
	var n := _vow_ids().size()
	var h := 96.0 + n * 84.0
	return Rect2((size.x - 680) / 2.0, (size.y - h) / 2.0, 680, h)


func _vow_option(i: int) -> Rect2:
	var b := _vow_box()
	return Rect2(b.position.x + 20, b.position.y + 70 + i * 84, b.size.x - 40, 76)


func _tap_vow(p: Vector2) -> void:
	var ids := _vow_ids()
	for i in ids.size():
		if _vow_option(i).has_point(p):
			run.profile.vow = ids[i]
			run.save()
			run.ui("ui_confirm", -8.0)
			break
	_vow_open = false
	queue_redraw()


func _draw_vow_box(data: Dictionary) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var b := _vow_box()
	draw_rect(b, Color(0.16, 0.11, 0.07, 0.97))
	draw_rect(b, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
	UiStyle.text(self, b.position + Vector2(0, 44), "PALADINENS LÖFTE FÖR NEDSTIGNINGEN", 22, UiStyle.GOLD,
			HORIZONTAL_ALIGNMENT_CENTER, b.size.x, 3)
	var ids := _vow_ids()
	for i in ids.size():
		var r := _vow_option(i)
		var on: bool = run.profile.vow == ids[i]
		draw_rect(r, Color(0, 0, 0, 0.45) if not on else Color(UiStyle.GOLD, 0.18))
		draw_rect(r, UiStyle.GOLD if on else Color(1, 1, 1, 0.2), false, 2.0 if on else 1.0)
		if ids[i] == "":
			UiStyle.text(self, r.position + Vector2(14, 28), "Inget löfte", 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 3)
			UiStyle.para(self, r.position + Vector2(14, 50), "Nedstigningen som vanligt.", 15, Color(1, 1, 1, 0.7), r.size.x - 28, 1)
			continue
		var v: Dictionary = data.vows[ids[i]]
		var silver := float(v.get("silver", 0.0))
		UiStyle.text(self, r.position + Vector2(14, 28), v.name, 19, UiStyle.TRAIT_GOLD.lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT,
				r.size.x - 28, 3)
		if silver > 0.0:
			UiStyle.text(self, r.position + Vector2(14, 28), "silver +%d %% medan det hålls" % roundi(silver * 100.0), 15,
					Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 28, 3)
		UiStyle.para(self, r.position + Vector2(14, 50), v.text, 15, Color(1, 1, 1, 0.8), r.size.x - 28, 2)


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
	_draw_event_strip(data, prof)
	if _vow_open:
		_draw_vow_box(data)
	elif _news_open:
		_draw_news(data, prof)


## Vinjetterna följer kamerans glidning (de ritas av egna noder bakom linjerna).
func _place_vignettes(zoom: float, focus: Vector2) -> void:
	for realm_id in _vignettes:
		_place(_vignettes[realm_id], _rect(realm_id), zoom, focus)
	_place(_warden, _warden_rect(), zoom, focus)
	_place(_witch, _witch_rect(), zoom, focus)
	# Trollberget ligger där Väktaren stod uppe till vänster; häxan står kvar mellan berget och kapellet.
	_warden.visible = not run.data.realms.has("mountain")


func _place(node: TextureRect, r: Rect2, zoom: float, focus: Vector2) -> void:
	node.position = focus + (r.position - focus) * zoom
	node.size = r.size * zoom


## Dekoren i marginalen: kompassros, drake i hörnet, svärd i sten, skelett vid kryptan och en spindel vid Lunden
## (häxan vid kapellet och Väktaren är vinjetter). 0.31: kompassen och draken flyttade för Sidenlunden.
func _draw_decor() -> void:
	var ink := Color(InkArt.INK, 0.6)
	var k := _scale()
	# Trollberget: kompassen flyttade ned under bergets kartusch.
	InkArt.icon(self, "compass", Vector2(72, 420) * k, 96 * k.y, 0.8)
	InkArt.icon(self, "dragon", Vector2(772, 672) * k, 88 * k.y, 0.8)
	InkArt.icon(self, "sword_in_stone", Vector2(530, 660) * k, 96 * k.y, 0.75)
	InkArt.icon(self, "skeleton", Vector2(78, 596) * k, 150 * k.y, 0.8)
	if run.data.realms.has("grove"):
		InkArt.spider(self, Vector2(805, 392) * k, 46 * k.y, ink)


## Ett område: vinjetten (egen nod), fördärvets bläckflöde, ram, kartusch med namnet och bossens sigill.
func _draw_realm(realm_id: String, selected: bool) -> void:
	var prof: Profile = run.profile
	var r := _rect(realm_id)
	var center := r.get_center()
	var cleared := int(prof.realm_depth.get(realm_id, 0))
	# Fördärvet ritas av vinjettens shader: bläcket når in till "inner" och drar sig tillbaka per djup.
	# Den levande kartan: fördärvet (0–4) drar bläcket närmare mitten.
	var g := LivingMap.growth(prof, realm_id) if _living(realm_id) else LivingMap.GROWTH_START
	var open := RunState.realm_open(prof, run.data, realm_id)
	# En stängd Realm (Trollberget före kapellet) syns blekare och helt täckt av fördärvet.
	_vignettes[realm_id].modulate.a = 1.0 if open else 0.7
	var mat := _vignettes[realm_id].material as ShaderMaterial
	mat.set_shader_parameter("inner", 0.58 + 0.4 * minf(FREED_PER_DEPTH * cleared, FREED_MAX) - GROWTH_INK * (g - 1))
	mat.set_shader_parameter("growth", float(g))
	mat.set_shader_parameter("breath", breath(g) if _living(realm_id) else 0.0)
	mat.set_shader_parameter("flow", 0.0 if _living(realm_id) and g == 0 else 1.0)
	if not open:
		mat.set_shader_parameter("inner", -0.4)  # stängd: fördärvet täcker hela området
	var frame := r.grow(6)
	var pts := PackedVector2Array([frame.position, Vector2(frame.end.x, frame.position.y), frame.end,
			Vector2(frame.position.x, frame.end.y), frame.position])
	for i in 4:
		InkArt.path(self, pts[i], pts[i + 1], Color(InkArt.INK, 0.85 if selected else 0.45), true, 1.6)
	if selected:
		var glow := 0.5 + 0.5 * sin(_t * 3.0)
		draw_rect(r.grow(12), Color(UiStyle.GOLD.darkened(0.2), 0.25 + 0.35 * glow), false, 4.0)
	if _living(realm_id):
		_draw_growth_marks(realm_id, r, g)
	if WorldEvents.in_event(prof, run.data, realm_id):
		_draw_event_mark(r)
	var name: String = run.data.realms[realm_id].name
	var cart := Rect2(maxf(center.x - 190, 4.0), r.end.y + 2, 380, 58)
	draw_texture_rect(InkArt.icon_texture("cartouche"), cart, false)
	UiStyle.text(self, Vector2(cart.position.x, cart.get_center().y + 4), name.to_upper(), 15, InkArt.INK,
			HORIZONTAL_ALIGNMENT_CENTER, cart.size.x, 0)
	var under := "Djup klarat: %d" % cleared if open else RunState.realm_lock_text(run.data, realm_id)
	UiStyle.text(self, Vector2(cart.position.x, cart.end.y + 12), under, 14, InkArt.INK,
			HORIZONTAL_ALIGNMENT_CENTER, cart.size.x, 0)
	if not open:
		return
	# Prototyp (sallskap-fem, VD): Trollberget är byggt för fem; med färre platser en allvarlig varning.
	if RunState.realm_too_big(prof, run.data, realm_id):
		UiStyle.text(self, Vector2(cart.position.x - 40, cart.end.y + 32), FIVE_WARNING, 15, Parchment.SEAL,
				HORIZONTAL_ALIGNMENT_CENTER, cart.size.x + 80, 0)
	# Sigill för bossen i vinjettens hörn: fylls i takt med segrarna (x/3 till bosstrofén).
	for boss in _bosses(realm_id):
		var wins: int = mini(int(prof.boss_wins.get(boss, 0)), RunState.BOSS_WINS_FOR_TROPHY)
		var at := Vector2(r.end.x - 24, r.position.y + 24)
		draw_circle(at, 18, Color(Parchment.SEAL, 0.35 + 0.2 * wins))
		draw_arc(at, 18, 0, TAU * wins / RunState.BOSS_WINS_FOR_TROPHY, 24, Parchment.SEAL, 4.0)
		UiStyle.text(self, at + Vector2(-30, 6), "%d/%d" % [wins, RunState.BOSS_WINS_FOR_TROPHY], 14, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER, 60, 2)


## karta-synlig: hur mycket bläcket andas per steg, utan siffror: 0 stilla och ljusare, 1 en svag andning, 2–4 tydligare.
static func breath(g: int) -> float:
	return [0.0, 0.09, 0.1, 0.12, 0.13][clampi(g, 0, LivingMap.GROWTH_MAX)]


## Den levande kartan visas för Realms man har gått ned i (efter introts första nedstigning).
func _living(realm_id: String) -> bool:
	return int(run.profile.descents.get(realm_id, 0)) > 0


## Mörka märken över området efter fördärvet, utan siffror: bläckfläckar (steg 2+), fiendens eldar (steg 2+), och på
## steg 4 den förvridna bossens sigill i rött. Platserna är fasta per Realm (samma varje gång).
func _draw_growth_marks(realm_id: String, r: Rect2, g: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(realm_id)
	if g == 1:
		# karta-synlig: på steg 1 lever området redan – några svaga droppar vid ramen som andas med bläcket.
		var breathe := 0.5 + 0.5 * sin(_t * 1.3)
		for i in 4:
			var t := rng.randf_range(0.15, 0.85)
			var at := Vector2(r.position.x + t * r.size.x, r.position.y - rng.randf_range(2.0, 7.0)) if i % 2 == 0 \
					else Vector2(r.end.x + rng.randf_range(2.0, 7.0), r.position.y + t * r.size.y)
			var rad := rng.randf_range(2.5, 4.5) * (0.85 + 0.3 * breathe)
			draw_circle(at, rad, Color(0.08, 0.03, 0.06, 0.25 + 0.3 * breathe))
		return
	if g < 2:
		return
	# Bläcket spiller över ramen ut på pergamentet (inne i området är det redan mörkt).
	var ink := Color(0.08, 0.03, 0.06, 0.5 + 0.1 * g)
	for i in (g - 1) * 4:
		var side := rng.randi() % 4
		var t := rng.randf_range(0.05, 0.95)
		var out := rng.randf_range(4.0, 10.0 + 4.0 * g)
		var at: Vector2
		match side:
			0: at = Vector2(r.position.x + t * r.size.x, r.position.y - out)
			1: at = Vector2(r.end.x + out, r.position.y + t * r.size.y)
			2: at = Vector2(r.position.x + t * r.size.x, r.end.y + out * 0.5)
			_: at = Vector2(r.position.x - out, r.position.y + t * r.size.y)
		var rad := rng.randf_range(3.0, 7.0) + g
		draw_circle(at, rad, ink)
		draw_circle(at + Vector2(rad * 0.8, rad * 0.4), rad * 0.45, ink)
		draw_circle(at + Vector2(-rad * 0.5, rad * 0.7), rad * 0.3, ink)
	for i in g - 1:
		var at := r.position + Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.55, 0.88)) * r.size
		var flicker := 0.6 + 0.4 * sin(_t * 5.0 + i * 1.7)
		draw_circle(at + Vector2(0, -4), 9.0, Color(1.0, 0.35, 0.1, 0.25 * flicker))
		InkArt.campfire(self, at, 16.0, Color(0.9, 0.3, 0.1, 0.6 + 0.3 * flicker))
	if LivingMap.awake(run.profile, run.data, realm_id):
		var c := r.get_center()
		var pulse := 0.5 + 0.5 * sin(_t * 2.0)
		draw_circle(c, 34.0, Color(0.05, 0.0, 0.02, 0.8))
		draw_arc(c, 36.0, 0, TAU, 40, Color(0.75, 0.1, 0.1, 0.5 + 0.4 * pulse), 3.0, true)
		InkArt.skull(self, c, 40.0, Color(0.85, 0.18, 0.15, 0.85))


## Den levande världen: en pågående händelse (WorldEvents) i området – ett pulserande rött sigill med ett timglas.
func _draw_event_mark(r: Rect2) -> void:
	var at := Vector2(r.position.x + 26, r.position.y + 26)
	var pulse := 0.5 + 0.5 * sin(_t * 3.2)
	draw_circle(at, 24.0 + 4.0 * pulse, Color(0.75, 0.12, 0.08, 0.25 + 0.2 * pulse))
	draw_circle(at, 19.0, Color(0.55, 0.06, 0.05, 0.95))
	draw_arc(at, 19.0, 0, TAU, 32, UiStyle.GOLD, 2.0, true)
	var gold := Color(UiStyle.GOLD)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-8, -11), at + Vector2(8, -11), at]), gold)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 11), at + Vector2(8, 11), at]), gold)
	draw_line(at + Vector2(-9, -12), at + Vector2(9, -12), gold, 2.0)
	draw_line(at + Vector2(-9, 12), at + Vector2(9, 12), gold, 2.0)


## Den levande världen: händelsen som pågår, som en rad längst ned på kartan (panelen är redan full).
func _draw_event_strip(data: Dictionary, prof: Profile) -> void:
	var line := WorldEvents.map_line(prof, data) if prof.intro_done else ""
	if line == "":
		return
	var r := Rect2(20, size.y - 46, _panel().position.x - 40, 36)
	draw_rect(r, Color(0.12, 0.05, 0.04, 0.88))
	draw_rect(r, Color(UiStyle.GOLD, 0.7), false, 1.5)
	var pulse := 0.5 + 0.5 * sin(_t * 3.2)
	draw_circle(r.position + Vector2(20, 18), 7.0, Color(0.85, 0.15, 0.1, 0.6 + 0.4 * pulse))
	UiStyle.text(self, r.position + Vector2(36, 25), UiStyle.fit("HÄNDELSE: " + line, 16, r.size.x - 48), 16,
			Color("#ffcf9a"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48, 3)


## Krönikan: hemkomstens repliker eller nya titlar (Profile.homecoming).
static func _has_homecoming(prof: Profile) -> bool:
	return not prof.homecoming.get("remarks", []).is_empty() or not prof.homecoming.get("titles", []).is_empty()


## Hemkomstens ruta: vad som ändrades och varför, nya titlar och högst två repliker. Krönikan (Chronicle.homecoming)
## väljer repliken (den levande kartans tävlar med krönikans); utan krönikan säger Imma eller Gorm kartans replik.
func _draw_news(data: Dictionary, prof: Profile) -> void:
	var news: Dictionary = prof.growth_news
	var lines: Array = news.get("lines", [])
	var remarks: Array = []
	if prof.homecoming.has("remarks"):
		remarks = prof.homecoming.remarks
	elif String(news.get("speaker", "")) != "":
		remarks = [{"speaker": news.speaker, "text": news.get("text", "")}]
	var titles: Array = prof.homecoming.get("titles", [])
	var w := 760.0
	var x := (size.x - w) / 2.0
	var body := 0.0
	for l in lines:
		body += UiStyle.bold().get_multiline_string_size(String(l), HORIZONTAL_ALIGNMENT_LEFT, w - 64, 17).y + 8
	var h := 96.0 + body + 34.0 * titles.size() + 112.0 * remarks.size() + 40.0
	var b := Rect2(x, (size.y - h) / 2.0, w, h)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	draw_rect(b, Color(0.16, 0.11, 0.07, 0.97))
	draw_rect(b, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
	UiStyle.text(self, b.position + Vector2(0, 44), "MEDAN NI VAR BORTA", 22, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, w, 3)
	var y := b.position.y + 72
	for l in lines:
		draw_circle(Vector2(x + 30, y + 10), 3.5, UiStyle.TRAIT_GOLD)
		y += UiStyle.para(self, Vector2(x + 44, y + 16), String(l), 17, Color(1, 1, 1, 0.9), w - 64) + 8
	for t in titles:
		UiStyle.text(self, Vector2(x + 24, y + 24), "Ny titel: " + Chronicle.title_name(data, t), 20, UiStyle.TRAIT_GOLD,
				HORIZONTAL_ALIGNMENT_LEFT, w - 48, 3)
		y += 34
	for r in remarks:
		y += 8
		var speaker := String(r.speaker)
		var pr := Rect2(x + 24, y, 96, 96)
		DialogBox.portrait(self, data, speaker, pr)
		UiStyle.text(self, Vector2(pr.end.x + 16, y + 22), Dialog.display_name(data, speaker), 18, UiStyle.GOLD)
		UiStyle.para(self, Vector2(pr.end.x + 16, y + 48), Dialog.fill_for(String(r.get("text", "")), prof), 17,
				Color(1, 1, 1, 0.9), w - 160, 3)
		y += 104
	UiStyle.text(self, Vector2(x, b.end.y - 16), "Tryck för att fortsätta", 15, Color(1, 1, 1, 0.55),
			HORIZONTAL_ALIGNMENT_CENTER, w)


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
	# Polering: beskrivningen får sina två rader hel; varningen för fem (sallskap-fem) står längre ned, under questraden.
	draw_multiline_string(UiStyle.bold(), Vector2(x, p.position.y + 58), realm.text, HORIZONTAL_ALIGNMENT_LEFT, w, 15, 2,
			Color(1, 1, 1, 0.8))

	# Djup
	UiStyle.text(self, Vector2(x, p.position.y + 98), "DJUP (DJUPASTE KLARADE %d)" % prof.best_depth, 15, Color(1, 1, 1, 0.6))
	small_button(_depth_rect(-1), "−", prof.depth > 1)
	small_button(_depth_rect(1), "+", prof.depth < prof.max_depth())
	UiStyle.text(self, Vector2(x + 44, p.position.y + 138), str(prof.depth), 30, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 106, 4)
	UiStyle.text(self, Vector2(x + 210, p.position.y + 122), "Fiender +%d %%" % roundi((CombatSim.depth_mult(prof.depth + RunState.realm_depth_offset(data, prof.realm)) - 1.0) * 100.0),
			13, Color(1, 1, 1, 0.75))
	UiStyle.text(self, Vector2(x + 210, p.position.y + 140), "Silver +%d %%" % roundi(Profile.SILVER_PER_DEPTH * (prof.depth - 1) * 100.0),
			13, Color(1, 1, 1, 0.75))

	# Instabilitet och regler
	UiStyle.text(self, Vector2(x, p.position.y + 194), "INSTABILITET", 15, Color(1, 1, 1, 0.6))
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
	draw_multiline_string(UiStyle.bold(), Vector2(x, p.position.y + 268), rule_text, HORIZONTAL_ALIGNMENT_LEFT, w, 16, 2,
			UiStyle.TRAIT_GOLD)

	# Bossar och quests
	var y := p.position.y + 300  # 0.30.48: tätare, så att fångarna ryms under tecknet
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
	# 0.30.48 (B5, fynd 4): allt under questraden ritas nedåt mot en fast gräns ovanför Sällskap-raden, aldrig över den.
	var limit := _prep_rect().position.y - 30
	var c := y + 48
	if RunState.realm_too_big(prof, data, prof.realm):
		UiStyle.text(self, Vector2(x, c + 4), UiStyle.fit(FIVE_WARNING, 15, w), 15, Color("#ff8a6a"))
		c += 24
	c += _draw_omen(x, c, w)
	# 0.23: lärjungar som sitter fångna här syns i förväg (Siralims varelser hör till sina Realms). 0.30.48: på en rad,
	# den närmaste med namn och resten som ett antal.
	var captives: Array[String] = []
	for d in RunState.findable_for(prof, data, prof.realm):
		captives.append("%s (djup %d)" % [data.heroes[d.hero].get("short", d.hero), int(d.depth)])
	if not captives.is_empty() and c + 4 <= limit:
		var line := "Sägs sitta fången här: " + captives[0] + ("" if captives.size() == 1 else " och %d till" % (captives.size() - 1))
		UiStyle.text(self, Vector2(x, c + 4), UiStyle.fit(line, 15, w), 15, Color("#ffd27a"), HORIZONTAL_ALIGNMENT_LEFT, w)
		c += 24
	# Den levande kartan: en rad före avfärd om vad som händer här och på andra håll (utan siffror).
	# Den levande världen: händelsen som pågår (alla Realms) och vad den här Realmen kostar hemma.
	var cost := WorldEvents.cost_line(prof, data, prof.realm)
	var yy := c + 8
	if prof.intro_done and _living(prof.realm):
		var room := limit - yy
		var rumour := WorldEvents.rumour_line(prof, data)
		var text := ("" if cost == "" else cost + " ") + ("" if rumour == "" else rumour + " ") \
				+ LivingMap.departure_line(prof, data, prof.realm)
		if room >= 16:
			UiStyle.para(self, Vector2(x, yy), text, 15,
					Color("#f0b49a") if LivingMap.awake(prof, data, prof.realm) or cost != "" else Color(1, 1, 1, 0.85), w,
					clampi(int(room / 19.0) + 1, 1, 5))

	var companions: Array = prof.party.map(func(id: String) -> String: return data.heroes[id].name)
	UiStyle.text(self, Vector2(x, _prep_rect().position.y - 10), "Sällskap: " + ", ".join(companions), 13,
			Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, w, 2)
	small_button(_prep_rect(), "FÖRBEREDELSER")
	if _vows_on():
		# Polering: "LÖFTE: INGEN S…" klipptes; ordet LÖFTE överst och löftet på en egen rad.
		var vr := _vow_rect()
		var vname := "INGET" if prof.vow == "" else String(data.vows[prof.vow].name).to_upper()
		small_button(vr, "")
		UiStyle.text(self, vr.position + Vector2(0, 19), "LÖFTE", 15, Color(UiStyle.TRAIT_GOLD, 0.7), HORIZONTAL_ALIGNMENT_CENTER,
				vr.size.x, 3)
		UiStyle.text(self, vr.position + Vector2(0, 40), UiStyle.fit(vname, 17, vr.size.x - 12), 17, UiStyle.TRAIT_GOLD,
				HORIZONTAL_ALIGNMENT_CENTER, vr.size.x, 4)
	UiStyle.big_button(self, _start_rect(), "IN I " + str(realm.short).to_upper(), _t, RunState.can_start(prof))
