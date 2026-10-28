extends TapScreen
## Borgen (0.24 "Hemmet", docs/plan/0.24-hemmet.md): en planritning i tusch på pergament, sedd uppifrån, som
## rumskartan. Fördärvet flyter som bläck utanför murarna; innanför är det kvällsljus, rök och gnistor.
## Tryck i ett rum så går paladinpjäsen dit (1–2 sekunder), sällskapet följer efter i en rad, och personen där
## hälsar och erbjuder sina tjänster som val (Siralims dialogruta, sist "Ingenting just nu"). Dubbeltryck hoppar fram.
## Introts steg börjar med ett samtal hos den som ger uppdraget (Intro.needs_talk). Befriade lärjungar som inte är med
## i sällskapet bor i värdshuset. Layouten står i data/keep.json; VD:ns bild (assets/illustrations/borgen.webp)
## ersätter KeepArt när den finns. Kortraden längst ned är genvägar.

const STATIONS := ["gate", "practice", "altar", "smith", "macros", "inn", "library"]
## Kortraden längst ned: stationerna och SÄLLSKAPET (polering fynd 1: hjältarna och samlingen, inget rum i borgen).
const CHIPS := ["gate", "practice", "altar", "smith", "macros", "inn", "library", "party"]
const DOUBLE_TAP_MS := 350
const WALK_SPEED := 650.0  # planritningens pixlar per sekund
const PIECE_H := 92.0
const TRAIL_STEP := 10.0
const TRAIL_GAP := 7  # trail-punkter mellan pjäserna i raden (70 px: porträtten är 59 breda och får en glipa)

const INK_SHADER := """
shader_type canvas_item;
// Fördärvet utanför murarna (0.24): bläck som flyter, med samma brus som kampanjkartans vinjetter.
uniform vec4 keep = vec4(0.2, 0.1, 0.6, 0.8);
uniform vec2 aspect = vec2(1.78, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.1; a *= 0.5; } return v; }
void fragment() {
	vec2 p = UV * aspect;
	vec2 c = (keep.xy + keep.zw * 0.5) * aspect;
	vec2 h = keep.zw * 0.5 * aspect;
	vec2 q = abs(p - c) - h;
	float outside = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
	float n = fbm(p * 3.0 + vec2(TIME * 0.03, -TIME * 0.05));
	float veins = fbm(p * 11.0 - vec2(0.0, TIME * 0.06));
	float ink = smoothstep(0.0, 0.035, outside + (n - 0.5) * 0.07 + (veins - 0.5) * 0.02);
	vec3 col = mix(vec3(0.06, 0.035, 0.06), vec3(0.16, 0.07, 0.15), smoothstep(0.6, 0.85, veins) * 0.7);
	COLOR = vec4(col, ink * 0.97);
}
"""

const LIGHT_SHADER := """
shader_type canvas_item;
render_mode blend_mul;
// Kvällsljus (0.24): varmt och lite dunkelt innanför murarna, ljusare kring lyktor och eldar som fladdrar.
uniform vec4 keep = vec4(0.2, 0.1, 0.6, 0.8);
uniform vec2 aspect = vec2(1.78, 1.0);
uniform vec3 lights[10];
uniform int count = 0;
void fragment() {
	vec2 p = UV * aspect;
	vec2 c = (keep.xy + keep.zw * 0.5) * aspect;
	vec2 h = keep.zw * 0.5 * aspect;
	vec2 q = abs(p - c) - h;
	float inside = 1.0 - smoothstep(-0.02, 0.01, max(q.x, q.y));
	vec3 col = vec3(0.80, 0.70, 0.58);
	for (int i = 0; i < 10; i++) {
		if (i >= count) { break; }
		vec2 lp = lights[i].xy * aspect;
		float flick = 0.9 + 0.1 * sin(TIME * (5.0 + float(i) * 1.7) + float(i));
		float a = smoothstep(lights[i].z * flick, 0.0, distance(p, lp));
		col = mix(col, vec3(1.0, 0.96, 0.86), a);
	}
	COLOR = vec4(mix(vec3(1.0), col, inside), 1.0);
}
"""

## Ett lager som ritar med en funktion från skärmen (planen i planens koordinater, eller gränssnittet).
class Layer:
	extends Control
	var paint: Callable

	func _init(fn: Callable) -> void:
		paint = fn
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		paint.call(self)


var keep: Dictionary
var plan_rect := Rect2()
var scale_k := 1.0
var _plan_tex: Texture2D
var _ink: ColorRect
var _light: ColorRect
var _plan_layer: Layer
var _ui_layer: Layer
## Paladinpjäsen och raden bakom: positioner i planens koordinater.
var pal := Vector2.ZERO
var _path: Array[Vector2] = []
var _speed := WALK_SPEED
var _trail: Array[Vector2] = []
var _walking_to := ""
var _last_tap_ms := -1000
var _last_tap_station := ""
## Samtalet: {lines: [{who, text}], i, station, menu (visa valen på sista raden), after (Callable)}. 0.25: en rad med
## talaren "narrator" är berättarens ruta på svart (StoryBox.narrator).
var _conv := {}
## Följeslagaren man pratar med i värdshuset (0.29.3).
var _lodger := ""
var _option_rects: Array[Rect2] = []
## En kort text mitt på skärmen (en plats utan person som är stängd), och hur länge den syns.
var _toast_text := ""
var _toast_t := 0.0
## Den levande världen: hemkomsten (Profile.homecoming, Chronicle). Den som det viktigaste angår går från sin plats
## fram till paladinen och pratar i samtalsrutan; nästa kommer efter. Sist en kort sammanfattning. Ett tryck hoppar fram.
var _home_pending := false
var _home_queue: Array = []
## Den som går fram just nu: {who, from, to, t}.
var _visitor := {}
## De som har sagt sitt och står kvar tills sammanfattningen stängs: [{who, at}].
var _visitors: Array = []
var _home_summary := false
const VISIT_TIME := 1.1
const VISIT_SPOTS := [Vector2(-125, -30), Vector2(125, -30), Vector2(0, -120)]


func _ready() -> void:
	super()
	keep = run.data.keep
	var img := "res://assets/illustrations/%s.webp" % keep.get("image", "borgen")
	if ResourceLoader.exists(img):
		_plan_tex = load(img)
	add_child(Parchment.new())
	_ink = _shader_rect(INK_SHADER, true)
	_plan_layer = Layer.new(_paint_plan)
	add_child(_plan_layer)
	_light = _shader_rect(LIGHT_SHADER, false)
	_ui_layer = Layer.new(_paint_ui)
	add_child(_ui_layer)
	_line_up()
	run.audio.start_ambience("ambience_home", -16.0)
	_start_dialog()
	_home_pending = _has_homecoming()
	if run.profile.intro_done and run.profile.path == "" and not run.profile.path_offered and not _home_pending \
			and not run.dev_profile:
		_offer_path.call_deferred()
	# Utvecklarflagga för skärmdumpar: --talk=<station> står vid stationen och pratar.
	for arg in OS.get_cmdline_user_args():
		if arg == "--home-summary" and _home_pending:
			_home_pending = false  # hemkomstens sammanfattning direkt (skärmdumpar)
			_home_summary = true
		if arg == "--settings":
			SettingsBox.open.call_deferred(self)  # 0.30: inställningarna öppna (skärmdumpar)
		if arg.begins_with("--talk="):
			var st := arg.get_slice("=", 1)
			pal = _v(keep.rooms[st].stand) if keep.rooms.has(st) else _v(keep.scene.people.get(st, keep.yard.home)) + Vector2(70, 40)
			_trail.append(pal)
			if keep.scene.people.has(st):
				_talk_scene(st)  # en av dem på gården under introts scen (0.25)
			elif _lodgers().has(st):
				pal = _v(keep.rooms.inn.stand)
				_talk_lodger(st)  # 0.29.3: en följeslagare i värdshuset
			else:
				_arrive(st)
		elif arg.begins_with("--line=") and not _conv.is_empty():
			_conv.i = clampi(int(arg.get_slice("=", 1)), 0, _conv.lines.size() - 1)  # 0.25: en viss rad i samtalet
		elif arg == "--rename":
			_rename()  # namnrutan hos Broder Alrik (0.24.2)
		elif arg == "--path-change":
			pal = _v(keep.rooms.macros.stand)
			_trail.append(pal)
			_change_path()  # Gorms bytesscen (paladinens inriktningar)
		elif arg == "--path-box":
			_offer_path.call_deferred(true)  # rutan för en gammal profil, utan att den sparas som visad
		elif arg.begins_with("--buy=") and run.dev_profile and WorldEvents.merchant_here(run.profile):
			# --buy=amber|trick (med --world-demo): ett köp hos handelsmannen, som sedan stannar (skärmdumpar)
			run.profile.silver = maxi(run.profile.silver, 200)
			pal = MERCHANT_AT + Vector2(70, 40)
			_trail.append(pal)
			_buy(arg.get_slice("=", 1))
		elif arg.begins_with("--walk="):
			_go(arg.get_slice("=", 1))  # --walk=<station>: paladinen går dit (för att se gången och raden)


func _exit_tree() -> void:
	run.audio.stop_ambience()


func _shader_rect(code: String, behind: bool) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.show_behind_parent = behind
	var sh := Shader.new()
	sh.code = code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	r.material = mat
	add_child(r)
	return r


static func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


static func _r(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2], a[3])


# --- Layout och tid -----------------------------------------------------------

func _layout() -> void:
	var ks := _v(keep.size)
	var top := 70.0
	var bottom := 70.0
	scale_k = minf((size.y - top - bottom) / ks.y, (size.x - 40.0) / ks.x)
	var w := ks.x * scale_k
	plan_rect = Rect2((size.x - w) / 2.0, top, w, ks.y * scale_k)
	var walls := _r(keep.walls)
	var wr := Rect2(to_screen(walls.position), walls.size * scale_k)
	var uv := Vector4(wr.position.x / size.x, wr.position.y / size.y, wr.size.x / size.x, wr.size.y / size.y)
	var aspect := Vector2(size.x / size.y, 1.0)
	for r in [_ink, _light]:
		(r.material as ShaderMaterial).set_shader_parameter("keep", uv)
		(r.material as ShaderMaterial).set_shader_parameter("aspect", aspect)
	var lights := PackedVector3Array()
	for l in keep.get("lights", []):
		var p := to_screen(Vector2(l[0], l[1]))
		lights.append(Vector3(p.x / size.x, p.y / size.y, l[2] * scale_k / size.y))
	(_light.material as ShaderMaterial).set_shader_parameter("lights", lights)
	(_light.material as ShaderMaterial).set_shader_parameter("count", lights.size())


func to_screen(p: Vector2) -> Vector2:
	return plan_rect.position + p * scale_k


func to_plan(p: Vector2) -> Vector2:
	return (p - plan_rect.position) / scale_k


func _process(delta: float) -> void:
	super(delta)
	_layout()
	_walk(delta)
	_visit(delta)
	_toast_t = maxf(0.0, _toast_t - delta)
	_plan_layer.queue_redraw()
	_ui_layer.queue_redraw()


func _walk(delta: float) -> void:
	if _path.is_empty():
		return
	var step := _speed * delta
	while step > 0.0 and not _path.is_empty():
		var d := pal.distance_to(_path[0])
		if d <= step:
			pal = _path.pop_front()
			step -= d
		else:
			pal = pal.move_toward(_path[0], step)
			step = 0.0
	if _trail.is_empty() or pal.distance_to(_trail.back()) >= TRAIL_STEP:
		_trail.append(pal)
		if _trail.size() > 200:
			_trail = _trail.slice(_trail.size() - 120)
	if _path.is_empty() and _walking_to != "":
		_arrive(_walking_to)


# --- Hemkomsten (den levande världen) ---------------------------------------------

func _has_homecoming() -> bool:
	var h: Dictionary = run.profile.homecoming
	return not h.get("remarks", []).is_empty() or not h.get("titles", []).is_empty() \
			or not h.get("summary", []).is_empty() or not h.get("tips", []).is_empty()


func _start_homecoming() -> void:
	_home_pending = false
	_line_up()
	_home_queue = Array(run.profile.homecoming.get("remarks", [])).duplicate(true)
	# tydliga-val: efter en förlust Gorms konkreta råd (LossTips) sist; pratar han redan läggs råden efter hans replik.
	var tips: Array = run.profile.homecoming.get("tips", [])
	if not tips.is_empty():
		var gorm := {}
		for r in _home_queue:
			if String(r.speaker) == "gorm":
				gorm = r
		if gorm.is_empty():
			_home_queue.append({"speaker": "gorm", "text": "Ett råd innan du går ned igen. " + String(tips[0]),
					"extra": tips.slice(1)})
		else:
			gorm.extra = tips.duplicate()
	_next_visitor()


## Nästa person går fram; när alla har pratat visas sammanfattningen (om det finns något att sammanfatta).
func _next_visitor() -> void:
	if _home_queue.is_empty():
		var h: Dictionary = run.profile.homecoming
		if not h.get("summary", []).is_empty() or not h.get("titles", []).is_empty():
			_home_summary = true
		else:
			_home_done()
		return
	var r: Dictionary = _home_queue.pop_front()
	var who := String(r.speaker)
	var spot: Vector2 = VISIT_SPOTS[mini(_visitors.size(), VISIT_SPOTS.size() - 1)]
	_visitor = {"who": who, "text": String(r.get("text", "")), "extra": Array(r.get("extra", [])), "from": _person_pos(who),
			"to": pal + spot, "t": 0.0}


func _visit(delta: float) -> void:
	if _home_pending and _conv.is_empty() and _path.is_empty():
		_start_homecoming()
	if _visitor.is_empty():
		return
	_visitor.t = float(_visitor.t) + delta / VISIT_TIME
	if float(_visitor.t) >= 1.0:
		_visitor_arrives()


## Androids bakåtknapp (Run.go_back): hoppar fram i ett samtal eller en hemkomst som ett tryck gör; en valmeny står
## kvar (valen har egna följder). Annars frågar Run om spelet ska avslutas.
func go_back() -> bool:
	if _home_summary or not _visitor.is_empty():
		_tap(Vector2(-1000, -1000))
		return true
	if not _conv.is_empty():
		if not (_conv.menu and _conv.i == _conv.lines.size() - 1):
			_advance()
		return true
	return false


func _visitor_arrives() -> void:
	var v := _visitor
	_visitor = {}
	_visitors.append({"who": v.who, "at": v.to})
	_talk(String(v.who), [String(v.text)] + Array(v.get("extra", [])), "", false, _next_visitor)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--home-line=") and not _conv.is_empty():
			_conv.i = clampi(int(arg.get_slice("=", 1)), 0, _conv.lines.size() - 1)  # en viss rad (Gorms råd, skärmdumpar)


func _home_done() -> void:
	_home_summary = false
	_visitors.clear()
	_visitor = {}
	run.profile.homecoming = {}
	run.profile.growth_news = {}
	run._save()


## Var personen står i planen (varifrån hen går): sin plats i borgen, sin plats i raden, en stol i värdshuset, annars
## porten (Tor och handelsmannen kommer utifrån).
func _person_pos(who: String) -> Vector2:
	for id in keep.rooms:
		if Intro.who_at(run.data, run.profile, id) == who and keep.rooms[id].has("person"):
			return _v(keep.rooms[id].person)
	var party: Array = _followers()
	if party.has(who):
		return _follower_pos(party.find(who))
	var lodgers := _lodgers()
	if lodgers.has(who) and lodgers.find(who) < keep.inn_seats.size():
		return _v(keep.inn_seats[lodgers.find(who)])
	if who == "tor" and _tor_here():
		return TOR_AT
	return _v(keep.rooms.gate.door)


## Är personen på väg fram eller står vid paladinen (då ritas hen inte på sin plats)?
func _away(who: String) -> bool:
	if not _visitor.is_empty() and _visitor.who == who:
		return true
	for v in _visitors:
		if v.who == who:
			return true
	return false


## Tor och arbetarna på gården: när kryptan står på steg 3+ (de vägrar gå ned) eller gravklockan ringer.
func _tor_here() -> bool:
	if not run.profile.intro_done:
		return false
	return WorldEvents.has_cost(run.profile, "crypt") or String(WorldEvents.active(run.profile).get("id", "")) == "bell_tolls"


const MERCHANT_AT := Vector2(700, 470)
## Tor och arbetarna på gården (planens pixlar), en bit från paladinens plats vid porten.
const TOR_AT := Vector2(615, 600)
const WORKERS_AT := [Vector2(560, 655), Vector2(650, 680), Vector2(575, 545)]
const PILGRIM_LINE := "pilgrim"


## En pilgrim sitter i värdshuset medan hans rykte (kapellet trycktes tillbaka) eller pilgrimernas välsignelse (de kom
## fram) väntar på nästa körning.
func _pilgrim_seat() -> int:
	if int(run.profile.world.get("bless_runs", 0)) <= 0 and not WorldEvents.rumour_pending(run.profile):
		return -1
	var i := _lodgers().size()
	return i if i < keep.inn_seats.size() else -1


func _talk_merchant() -> void:
	var t: Dictionary = run.data.dialog.get("world", {}).get("merchant", {})
	var greet: Array = t.get("greet", [""])
	var grateful: bool = run.profile.world.get("merchant", {}).get("grateful", false)
	_walk_to("yard", MERCHANT_AT + Vector2(70, 40))
	_talk("merchant", [String(greet[mini(1 if grateful else 0, greet.size() - 1)])], "merchant", true)


## Pilgrimen i värdshuset: ryktet om nästa körnings questmål, annars pilgrimsskarans välsignelse.
func _talk_pilgrim() -> void:
	var w: Dictionary = run.data.dialog.get("world", {})
	var lines: Array = []
	if WorldEvents.rumour_pending(run.profile):
		lines = Array(w.get("pilgrim_rumour", [])).map(func(l) -> String: return Dialog.line_text(l))
	else:
		lines = [String(w.get("pilgrim", ""))]
	_talk("pilgrim", lines, "", false)


## Valen hos en station; handelsmannens med vara och pris (det han redan har sålt finns inte kvar).
func _station_options(station: String) -> Array:
	var opts := Dialog.options(run.data, station)
	# Paladinens inriktningar: hos Gorm, efter introt, att välja eller byta väg (före "Ingenting just nu").
	if station == "macros" and run.profile.intro_done:
		var label := "Välj min väg: skölden eller ljuset" if run.profile.path == "" else "Byt väg (nu: %s)" % \
				Paths.path_name(run.data, run.profile.path)
		opts.insert(opts.size() - 1, {"label": label, "open": "path"})
	if station == "merchant":
		opts = opts.filter(func(o: Dictionary) -> bool:
			return not WorldEvents.merchant_sold(run.profile, String(o.get("open", "")).trim_prefix("buy_")))
		var goods := WorldEvents.merchant_goods(run.profile, run.data)
		for o in opts:
			if o.get("open", "") == "buy_amber":
				o.label = "%d %s – %d silver" % [WorldEvents.MERCHANT_AMBER, String(run.data.materials.amber[goods.amber].name).to_lower(),
						WorldEvents.merchant_price(run.profile, "amber")]
			elif o.get("open", "") == "buy_trick":
				o.label = "%s – %d silver" % [String(run.data.materials.tricks[goods.trick].name),
						WorldEvents.merchant_price(run.profile, "trick")]
	return opts


func _buy(what: String) -> void:
	var t: Dictionary = run.data.dialog.get("world", {}).get("merchant", {})
	if WorldEvents.merchant_buy(run.profile, run.data, what):
		run.ui("ui_coins", -10.0)
		run._save()
		# Han stannar tills nästa nedstigning, med det som finns kvar; när allt är sålt går han.
		if WorldEvents.merchant_here(run.profile):
			_talk("merchant", [String(t.get("bought", ""))], "merchant", true)
		else:
			_talk("merchant", [String(t.get("sold_out", ""))], "", false)
	else:
		run.ui("ui_error", -14.0)
		_talk("merchant", [String(t.get("poor", ""))], "merchant", true)


# --- Vem som är var -------------------------------------------------------------

## Sällskapet bakom paladinen (utom paladinen).
func _followers() -> Array:
	return run.profile.party.slice(1)


## Lärjungar som bor i värdshuset (inte med i sällskapet).
func _lodgers() -> Array:
	return Array(run.profile.recruited).filter(func(id: String) -> bool: return not run.profile.party.has(id))


## Polering: sällskapet stod staplat 36 px isär under paladinen (porträtten klumpade ihop sig ovanför PORTEN). Nu en
## trail genom fasta platser i sicksack bakom paladinen, TRAIL_GAP * TRAIL_STEP isär, så att varje porträtt får egen yta
## och raden går vidare därifrån när paladinen börjar gå. Besökarna vid hemkomsten (VISIT_SPOTS) står ovanför.
const LINE_UP := [Vector2(-30, 63.2), Vector2(70, 0), Vector2(-35, 60.6), Vector2(70, 0)]


func _line_up() -> void:
	pal = _v(keep.yard.home)
	var spots: Array[Vector2] = [pal]
	for d in LINE_UP:
		spots.append(spots.back() + d)
	_trail.clear()
	for k in range(spots.size() - 1, 0, -1):
		for j in TRAIL_GAP:
			_trail.append(spots[k].lerp(spots[k - 1], float(j) / TRAIL_GAP))
	_trail.append(pal)


func _follower_pos(i: int) -> Vector2:
	var idx := _trail.size() - 1 - (i + 1) * TRAIL_GAP
	return _trail[maxi(idx, 0)]


## 0.25: introts scen på gården (arbetarna från kryptan). Personerna som står där just nu: Tor och Imma (som inte har
## anslutit) och de som steget flyttar till gården (Gorm, Mor Elin, Broder Alrik).
func _scene_people() -> Array:
	if not Intro.scene(run.data, run.profile):
		return []
	var out := []
	for who in keep.scene.people:
		if who == "tor" or (who == "imma" and not run.profile.recruited.has("imma")) \
				or Intro.person_station(run.data, run.profile, who) == "yard":
			out.append(who)
	return out


## Rummet vid en punkt i planen ("yard" för gården, "" utanför).
func _room_at(p: Vector2) -> String:
	for id in keep.rooms:
		if _r(keep.rooms[id].rect).has_point(p):
			return id
	if _r(keep.yard.rect).has_point(p):
		return "yard"
	return ""


## Vägen till en punkt i ett rum: ut genom dörren, över gården och in genom nästa dörr.
func _route(to_room: String, target: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var from_room := _room_at(pal)
	if from_room != to_room:
		if keep.rooms.has(from_room):
			out.append(_v(keep.rooms[from_room].door))
			out.append(_v(keep.rooms[from_room].yard))
		if keep.rooms.has(to_room):
			out.append(_v(keep.rooms[to_room].yard))
			out.append(_v(keep.rooms[to_room].door))
	out.append(target)
	return out


func _walk_to(room: String, target: Vector2, station := "") -> void:
	var same := room == _room_at(pal)
	_path = _route(room, target)
	var length := 0.0
	var prev := pal
	for p in _path:
		length += prev.distance_to(p)
		prev = p
	# 1–2 sekunder mellan rummen, kortare inne i ett rum.
	var seconds := maxf(length / WALK_SPEED, 0.2) if same else clampf(length / WALK_SPEED, 1.0, 2.0)
	_speed = maxf(length / seconds, 1.0)
	_walking_to = station


func _jump() -> void:
	while not _path.is_empty():
		pal = _path.pop_front()
		_trail.append(pal)
	if _walking_to != "":
		_arrive(_walking_to)


# --- Samtal -------------------------------------------------------------------

## När man kommer tillbaka till borgen: slutet på introt sägs direkt, berättaren efter den första bossen, och introts
## samtal som spelas av sig själva (0.25: natten när arbetarna kommer, hemkomsten efter den första nedstigningen).
func _start_dialog() -> void:
	var data: Dictionary = run.data
	# 0.25: den första nedstigningen är klar när man är hemma igen (vunnen eller inte).
	# 0.30.16: bara om Imma smet efter (hon rekryteras då på rumskartan); föll paladinen ensam börjar steget om.
	if Intro.current(data, run.profile).get("event", "") == "came_home" and run.profile.total_descents() > 0 \
			and run.profile.recruited.has("imma"):
		run.intro("came_home")
	var slot_opened: bool = run.check_slot_unlock()  # prototyp (sallskap-fem): den femte platsen öppnas
	var story: Array = run.pending_story
	run.pending_story = []
	if not run.intro_lines.is_empty():
		story += Intro.speech(run.intro_lines.lines, run.intro_lines.speaker)
		run.intro_lines = {}
	if Intro.auto_talk(data, run.profile):
		var step := Intro.current(data, run.profile)
		_talk("", story + Intro.lines(step), "", false, _after_intro_talk.bind(""))
	elif slot_opened:
		_talk("", story, "", false, func() -> void: _toast(run.slot_toast))
	elif not story.is_empty():
		_talk("", story, "", false)


func _toast(text: String) -> void:
	_toast_text = text
	_toast_t = 3.0


## Ett samtal. Raderna är texter (who säger dem) eller {who, text} (0.25: flera talare och berättaren).
func _talk(who: String, lines: Array, station: String, menu: bool, after := Callable()) -> void:
	var named := []
	for l in Intro.speech(lines, who):
		if l.text != "":
			named.append({"who": l.who, "text": Dialog.fill_for(l.text, run.profile)})
	_conv = {"lines": named, "i": 0, "station": station, "menu": menu, "after": after, "shown": _t}
	if named.is_empty():
		_conv = {}


func _arrive(station: String) -> void:
	_walking_to = ""
	var data: Dictionary = run.data
	var who := Intro.who_at(data, run.profile, station)
	var state := Intro.station_state(data, run.profile, station)
	if not run.profile.intro_done and Intro.needs_talk(data, run.profile) and Intro.giver_station(data, run.profile) == station:
		var step := Intro.current(data, run.profile)
		_met(step.giver)
		_talk(step.giver, Intro.lines(step), station, false, _after_intro_talk.bind(station))
		return
	# 0.24.3: en plats utan person (altaret i kapellet) öppnas direkt, eller säger kort varför den är stängd.
	if who == "":
		if state == "locked":
			_toast(Dialog.reply(data, station))
			run.ui("ui_error", -14.0)
		else:
			_open(String(Dialog.options(data, station)[0].open))
		return
	if state == "locked":
		_talk(who, [Dialog.reply(data, station)], station, false)
		run.ui("ui_error", -14.0)
		return
	# 0.29.5: uppdraget "Visa fyndet för Hedda" – hon förklarar materialen och platserna, och ger lite silver.
	if station == "smith" and run.profile.intro_done and run.profile.find_quest == 1:
		_find_quest_talk(who, station)
		return
	var turn := _met(who)
	var greeting := Dialog.greeting(data, who, turn)
	# Under introt säger personen sin egen replik för steget (uppdraget står bara överst, aldrig i någons mun);
	# annars hälsningen och en vardagsreplik (ibland bara hälsningen).
	var at: Variant = Intro.at_lines(data, run.profile, who) if not run.profile.intro_done else null
	if state == "current" and at != null:
		var lines: Array = (at as Array).duplicate() if at is Array else [String(at)]
		if turn == 0:
			lines.push_front(greeting)
		_talk(who, lines, station, true)
		return
	# Den levande världen: det som pågår (en händelse, en följd, handelsmannen) sägs varannan gång. Vardagsrepliken
	# hämtas bara när den visas (Dialog.idle_line minns den i Profile.said).
	var news := WorldEvents.ongoing_line(run.profile, data, who, turn / 2)
	var extra := ""
	if news != "" and turn % 2 == 0:
		extra = news
	elif turn % 3 != 2:
		extra = Dialog.idle_line(data, run.profile, who, turn)
	var said: Array = [(greeting + " " + extra).strip_edges()]
	# Väktarsteg 2: Sven säger vem som vaktar det valda djupet innan man går (dialog.json "gate_guard").
	if station == "gate" and run.profile.intro_done:
		var guard := Dialog.gate_guard_line(data, run.profile)
		if guard != "":
			said.append(guard)
		# 0.30.45: och vad djupets tecken betyder (dialog.json "omens").
		var omen_said: String = run.omen_line(run.profile.omen, "sven")
		if omen_said != "":
			said.append("Det här djupet: %s. %s" % [run.data.floor_rules[run.profile.omen].name, omen_said])
	_talk(who, said, station, true)


const FIND_QUEST_SILVER := 20


func _find_quest_talk(who: String, station: String) -> void:
	var q: Dictionary = run.data.dialog.get("find_quest", {})
	var lines: Array = (q.get("hedda", []) as Array).duplicate()
	var sword := int(run.profile.artifact("paladin").get("level", 1))
	lines.append(q.get("hedda_slot", "") if Forge.stat_slot_open(sword, 0) else q.get("hedda_no_slot", ""))
	lines.append(String(q.get("hedda_reward", "")).replace("{belöning}", str(FIND_QUEST_SILVER)))
	_met(who)
	run.profile.find_quest = 2
	run.profile.silver += FIND_QUEST_SILVER
	run._save()
	_talk(who, lines, station, true)


## Räknar ett möte med personen; returnerar hur många gånger man har pratat förut (0 = första mötet).
func _met(who: String) -> int:
	var turn := int(run.profile.talks.get(who, 0))
	run.profile.talks[who] = turn + 1
	return turn


func _after_intro_talk(station: String) -> void:
	var data: Dictionary = run.data
	var step := Intro.current(data, run.profile)
	Intro.talked(data, run.profile)
	if step.get("event", "") == "talked":
		run.intro("talked")
	else:
		run._save()
	# Gäller uppdraget den här stationen visas valen direkt (som eden vid altaret).
	if station != "" and Intro.station_state(data, run.profile, station) == "current":
		_arrive(station)


func _advance() -> void:
	if _conv.i < _conv.lines.size() - 1:
		_conv.i += 1
		_conv.shown = _t
		return
	if _conv.menu:
		return  # valen väntar
	var after: Callable = _conv.after
	_conv = {}
	if after.is_valid():
		after.call()


func _choose(i: int) -> void:
	var opts := _station_options(_conv.station)
	var open: String = opts[i].get("open", "")
	_conv = {}
	if open != "":
		_open(open)


func _open(station: String) -> void:
	run._save()
	match station:
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
		"inn":
			run.profile.inn_seen = run.profile.recruited.size()
			run.go(run.INN_SCENE)
		"rename":
			_rename()
		"path":
			_change_path()
		"handbook":
			run.go(run.HANDBOOK_SCENE)
		"chronicle":
			run.go(run.CHRONICLE_SCENE)  # krönikan och titlarna (Chronicle)
		"sheet":
			run.open_sheet(_lodger, run.profile.recruited, run.BASE_SCENE)
		"buy_amber":
			_buy("amber")
		"buy_trick":
			_buy("trick")
		"talk_trophies":
			_talk("alrik", Dialog.person(run.data, "alrik").get("trophies", []), "library", true)


## 0.24.2: namnet skrivs om i krönikan hos Broder Alrik.
func _rename() -> void:
	var entry := NameEntry.new()
	entry.title = "Skriv om mitt namn i krönikan"
	entry.hint = "Broder Alrik doppar pennan. Hur ska det stå?"
	entry.confirm_label = "SKRIV IN"
	entry.can_cancel = true
	entry.start_name = "" if run.profile.hero_name == Profile.DEFAULT_NAME else run.profile.hero_name
	entry.chosen.connect(_renamed)
	add_child(entry)


## Paladinens inriktningar: Gorms scen och sedan valet. Det första bytet är gratis, sedan Paths.BYTE_COST silver.
func _change_path() -> void:
	var t: Dictionary = run.data.dialog.get("paths", {})
	var key := "gorm_choose" if run.profile.path == "" else ("gorm_first_change" if run.profile.path_changes == 0 else "gorm_change")
	var lines: Array = Array(t.get(key, [])).map(func(l) -> String: return Dialog.line_text(l))
	_talk("gorm", lines, "", false, _open_path_box.bind(String(t.get("change_question", ""))))


func _open_path_box(question: String) -> void:
	var box := PathBox.open(self, Dialog.fill_for(question, run.profile))
	box.done.connect(_path_chosen)


func _path_chosen(path_id: String) -> void:
	if path_id == "" or not run.choose_path(path_id):
		return
	var said: Dictionary = run.data.dialog.get("paths", {}).get("chosen", {}).get(path_id, {})
	_talk("gorm", [Dialog.line_text(said)], "", false)


## En profil som fanns före inriktningarna får välja en gång när borgen öppnas, utan tvång (SENARE); sedan hos Gorm.
func _offer_path(dev := false) -> void:
	if not dev:
		run.profile.path_offered = true
		run._save()
	var box := PathBox.open(self, Dialog.fill_for(String(run.data.dialog.get("paths", {}).get("offer_question", "")), run.profile), true)
	box.done.connect(_path_chosen)


func _renamed(n: String) -> void:
	run.rename(n)
	_talk("alrik", ["Så där. {namn} står i krönikan nu. Med bläck, så det sitter."], "", false)


# --- Inmatning ------------------------------------------------------------------

## 0.30: knappen under ‹ PROFILER.
func _settings_rect() -> Rect2:
	return Rect2(back_rect().position.x, back_rect().end.y + 10, back_rect().size.x, 40)


func _tap(p: Vector2) -> void:
	if _home_summary:
		_home_done()
		return
	if not _visitor.is_empty():
		_visitor_arrives()  # ett tryck hoppar fram
		return
	if not _conv.is_empty():
		if _conv.menu and _conv.i == _conv.lines.size() - 1:
			for i in _option_rects.size():
				if _option_rects[i].has_point(p):
					_choose(i)
					return
			return
		_advance()
		return
	if back_rect().has_point(p):
		run._save()
		run.go(run.SLOTS_SCENE)
		return
	if _settings_rect().has_point(p):
		SettingsBox.open(self)  # 0.30: volym och rumsögonblick
		return
	for i in CHIPS.size():
		if _chip_rect(i).has_point(p):
			if CHIPS[i] == "party":
				run._save()
				run.go(run.PARTY_SCENE)
			else:
				_go(CHIPS[i])
			return
	var q := to_plan(p)
	# Pjäserna: folket på gården under introts scen, sällskapet, de som bor i värdshuset och paladinen själv.
	for who in _scene_people():
		if _v(keep.scene.people[who]).distance_to(q) < 50.0:
			_talk_scene(who)
			return
	if WorldEvents.merchant_here(run.profile) and run.profile.intro_done and MERCHANT_AT.distance_to(q) < 50.0:
		_talk_merchant()
		return
	if _tor_here() and TOR_AT.distance_to(q) < 50.0:
		_talk_scene("tor")
		return
	var ps := _pilgrim_seat()
	if ps >= 0 and _v(keep.inn_seats[ps]).distance_to(q) < 50.0:
		_talk_pilgrim()
		return
	var party: Array = _followers()
	for i in party.size():
		if _follower_pos(i).distance_to(q) < 50.0:
			run.open_sheet(party[i], run.profile.party, run.BASE_SCENE)
			return
	var lodgers := _lodgers()
	for i in mini(lodgers.size(), keep.inn_seats.size()):
		if _v(keep.inn_seats[i]).distance_to(q) < 50.0:
			_talk_lodger(lodgers[i])
			return
	if pal.distance_to(q) < 50.0 and _path.is_empty():
		run.open_sheet("paladin", run.profile.party, run.BASE_SCENE)
		return
	var room := _room_at(q)
	if keep.rooms.has(room):
		_go(room)
	elif room == "yard":
		_walk_to("yard", q)
	elif _r(keep.store).has_point(q):
		_walk_to("", q)


func _go(station: String) -> void:
	var now := Time.get_ticks_msec()
	var double: bool = now - _last_tap_ms < DOUBLE_TAP_MS and _last_tap_station == station
	_last_tap_ms = now
	_last_tap_station = station
	if double or (_walking_to == station and not _path.is_empty()):
		_jump()  # dubbeltryck (eller tryck igen under gången) hoppar fram
		return
	_walk_to(station, _v(keep.rooms[station].stand), station)
	run.ui_tap()


## 0.29.3: en följeslagare i värdshuset säger något (dialog.json "inn"); valet visar hjältebladet som förut.
func _talk_lodger(who: String) -> void:
	_lodger = who
	var turn := _met(who)
	var line := Dialog.inn_line(run.data, run.profile, who, turn)
	run.profile.inn_heard[who] = run.profile.total_descents()
	if line.is_empty():
		run.open_sheet(who, run.profile.recruited, run.BASE_SCENE)
		return
	_talk(who, [String(line.text)], "lodger", true)


## 0.25: någon på gården under introts scen säger sin replik för steget (eller en vardagsreplik).
func _talk_scene(who: String) -> void:
	_walk_to("yard", _v(keep.scene.people[who]) + Vector2(70, 40))
	var at: Variant = Intro.at_lines(run.data, run.profile, who)
	var news := WorldEvents.ongoing_line(run.profile, run.data, who, int(run.profile.talks.get(who, 0)))
	if at != null:
		_talk(who, (at as Array).duplicate() if at is Array else [String(at)], "", false)
	elif news != "" and run.profile.intro_done:
		_met(who)
		_talk(who, [news], "", false)
	else:
		var turn := _met(who)
		_talk(who, [(Dialog.greeting(run.data, who, turn) + " " + Dialog.idle_line(run.data, run.profile, who, turn)).strip_edges()],
				"", false)


# --- Ritning ----------------------------------------------------------------------

## Lyser stationen? Introts aktuella uppdrag, Värdshuset när någon ny har kommit, Smeden när ett material kan sättas in.
func _glows(station: String) -> bool:
	if Intro.station_state(run.data, run.profile, station) == "current":
		return true
	if not run.profile.intro_done:
		return false
	match station:
		"inn":
			return run.profile.recruited.size() > run.profile.inn_seen
		"smith":
			return run.profile.find_quest == 1 or _smith_has_news()
	return false


func _smith_has_news() -> bool:
	var amber := 0
	var tricks := 0
	for id in run.profile.materials:
		if run.data.materials.amber.has(id):
			amber = maxi(amber, int(run.profile.materials[id]))
		else:
			tricks += int(run.profile.materials[id])
	for hero_id in run.profile.artifacts:
		var a: Dictionary = run.profile.artifact(hero_id)
		for i in Forge.STAT_SLOT_LEVELS.size():
			if Forge.stat_slot_open(int(a.level), i) and a.stat_slots[i] == "" and amber >= Forge.AMBER_PER_SLOT:
				return true
		for i in Forge.TRICK_SLOT_LEVELS.size():
			if Forge.trick_slot_open(int(a.level), i) and a.trick_slots[i] == "" and tricks > 0:
				return true
	return false


## Planen i planens koordinater: bilden eller tuschritningen, stämningen, människorna och pjäserna.
func _paint_plan(ci: CanvasItem) -> void:
	ci.draw_set_transform(plan_rect.position, 0.0, Vector2.ONE * scale_k)
	var data: Dictionary = run.data
	if _plan_tex:
		ci.draw_texture_rect(_plan_tex, Rect2(Vector2.ZERO, _v(keep.size)), false)
	else:
		KeepArt.plan(ci, keep)
	KeepArt.ambience(ci, keep, _t, _plan_tex != null)
	if "--keep-debug" in OS.get_cmdline_user_args():
		_paint_debug(ci)
	# Gyllene ringar kring det som lyser.
	for id in STATIONS:
		if _glows(id):
			var c := _v(keep.rooms[id].get("person", keep.rooms[id].stand))
			ci.draw_arc(c, 62.0 + sin(_t * 3.0) * 5.0, 0, TAU, 40, Color(1.0, 0.8, 0.3, 0.75), 6.0, true)
	# Människorna vid sina platser (porträtt i en liten ram).
	for id in keep.rooms:
		var room: Dictionary = keep.rooms[id]
		var who := Intro.who_at(data, run.profile, id)
		if who == "" or not room.has("person") or _away(who):
			continue
		DialogBox.portrait(ci, data, who, Rect2(_v(room.person) - Vector2(36, 36), Vector2(72, 72)))
	# Den levande världen: arbetarna och Tor på gården, handelsmannen, en pilgrim i värdshuset.
	if _tor_here():
		for w in WORKERS_AT:
			KeepArt.pawn(ci, w, 58.0, Color("#7d6b52"))
		if not _away("tor"):
			DialogBox.portrait(ci, data, "tor", Rect2(TOR_AT - Vector2(32, 32), Vector2(64, 64)))
	if WorldEvents.merchant_here(run.profile) and run.profile.intro_done:
		KeepArt.pawn(ci, MERCHANT_AT, 72.0, Color("#8a6a3a"))
	var ps := _pilgrim_seat()
	if ps >= 0:
		KeepArt.pawn(ci, _v(keep.inn_seats[ps]), 60.0, Color("#b9b2a0"))
	# 0.25: arbetarna från kryptan på gården: de skadade på marken och folket som tar hand om dem.
	if Intro.scene(data, run.profile):
		for w in keep.scene.wounded:
			KeepArt.wounded(ci, _v(w), 100.0)
		for who in _scene_people():
			DialogBox.portrait(ci, data, who, Rect2(_v(keep.scene.people[who]) - Vector2(32, 32), Vector2(64, 64)))
	# De som bor i värdshuset.
	var lodgers := _lodgers()
	for i in mini(lodgers.size(), keep.inn_seats.size()):
		if not _away(lodgers[i]):
			_token(ci, lodgers[i], _v(keep.inn_seats[i]), 64.0)
	# Sällskapet i en rad bakom paladinen, sist paladinen själv.
	var party: Array = _followers()
	for i in range(party.size() - 1, -1, -1):
		if not _away(party[i]):
			_token(ci, party[i], _follower_pos(i), 70.0)
	# Hemkomsten: de som har gått fram till paladinen, och den som är på väg.
	for v in _visitors:
		_visit_token(ci, String(v.who), v.at)
	if not _visitor.is_empty():
		var t := _ease(float(_visitor.t))
		var at: Vector2 = (_visitor.from as Vector2).lerp(_visitor.to, t) + Vector2(0, -absf(sin(t * PI * 4.0)) * 8.0)
		_visit_token(ci, String(_visitor.who), at)
	# Ett ljust sken under pjäsen, så att den syns mot en detaljerad bild.
	for j in 3:
		ci.draw_circle(pal + Vector2(0, -PIECE_H * 0.2), PIECE_H * (0.62 - j * 0.14), Color(1.0, 0.93, 0.74, 0.18 + j * 0.12))
	var bob := sin(_t * 9.0) * 4.0 if not _path.is_empty() else sin(_t * 2.0) * 1.5
	InkArt.icon(ci, "paladin", pal + Vector2(0, -PIECE_H * 0.35 + bob), PIECE_H)
	ci.draw_set_transform(Vector2.ZERO)


static func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## En person som går fram vid hemkomsten: porträttet (folket i borgen och följeslagarna), annars en tuschpjäs.
func _visit_token(ci: CanvasItem, who: String, c: Vector2) -> void:
	if run.data.heroes.has(who):
		_token(ci, who, c, 74.0)
	elif DialogBox.portrait_texture(who) != null:
		var r := Rect2(c - Vector2(36, 50), Vector2(72, 72))
		ci.draw_rect(r.grow(3), Color(0.93, 0.85, 0.66))
		DialogBox.portrait(ci, run.data, who, r)
	else:
		KeepArt.pawn(ci, c, 72.0, Color(Dialog.person(run.data, who).get("color", "#6a6a6a")))


## Utvecklarflagga --keep-debug: rummens rutor, dörrar, gångar, platser och ljus, för att passa in en ny bild.
func _paint_debug(ci: CanvasItem) -> void:
	for id in keep.rooms:
		var room: Dictionary = keep.rooms[id]
		ci.draw_rect(_r(room.rect), Color(0, 0.6, 1, 0.9), false, 4.0)
		ci.draw_circle(_v(room.door), 10, Color.RED)
		ci.draw_circle(_v(room.yard), 10, Color.ORANGE)
		ci.draw_circle(_v(room.stand), 10, Color.GREEN)
		ci.draw_line(_v(room.door), _v(room.yard), Color.RED, 3.0)
	ci.draw_rect(_r(keep.yard.rect), Color(1, 1, 0, 0.9), false, 4.0)
	ci.draw_rect(_r(keep.walls), Color(1, 0, 1, 0.9), false, 4.0)
	for l in keep.lights:
		ci.draw_arc(Vector2(l[0], l[1]), l[2], 0, TAU, 32, Color(1, 1, 0.5, 0.8), 2.0)
	for p in keep.inn_seats:
		ci.draw_circle(_v(p), 8, Color.BLUE)


## En följeslagares pjäs (0.24.3): porträttet i en liten ram om det finns, som borgens folk, annars en tuschbonde.
func _token(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	if DialogBox.portrait_texture(id) != null:
		var r := Rect2(c - Vector2(s * 0.42, s * 0.62), Vector2(s * 0.84, s * 0.84))
		ci.draw_rect(r.grow(4), Color(run.data.heroes[id].color))
		DialogBox.portrait(ci, run.data, id, r)
	else:
		KeepArt.pawn(ci, c, s, Color(run.data.heroes[id].color))


func _chip_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * (CHIPS.size() - 1)) / CHIPS.size()
	return Rect2(MARGIN + i * (w + GAP), size.y - 58, w, 46)


## Gränssnittet ovanpå: namnen i rummen, uppdraget, kortraden och samtalet.
func _paint_ui(ci: CanvasItem) -> void:
	var data: Dictionary = run.data
	UiStyle.text(ci, Vector2(0, 46), "SILVER %d" % run.profile.silver, 22, Color("#d8dde6"), HORIZONTAL_ALIGNMENT_RIGHT,
			size.x - MARGIN, 4)
	ci.draw_rect(back_rect(), Color(0, 0, 0, 0.6))
	ci.draw_rect(back_rect(), Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(ci, back_rect().position + Vector2(0, 29), "‹ PROFILER", 18, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_CENTER,
			back_rect().size.x, 4)
	ci.draw_rect(_settings_rect(), Color(0, 0, 0, 0.6))
	ci.draw_rect(_settings_rect(), Color(UiStyle.TRAIT_GOLD, 0.7), false, 2.0)
	UiStyle.text(ci, _settings_rect().position + Vector2(0, 26), "INSTÄLLNINGAR", 16, UiStyle.TRAIT_GOLD,
			HORIZONTAL_ALIGNMENT_CENTER, _settings_rect().size.x, 4)
	# Rummens namn i tusch, och personernas namn under porträtten.
	for id in keep.rooms:
		var st := Dialog.station(data, id)
		var r := _r(keep.rooms[id].rect)
		var state := Intro.station_state(data, run.profile, id)
		var col := Color(0.20, 0.12, 0.06, 1.0 if state != "locked" else 0.5)
		var label := String(st.get("name", "")).to_upper() + ("  !" if _glows(id) else "")
		var lw := UiStyle.bold().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16
		var lp := to_screen(r.position) + Vector2((r.size.x * scale_k - lw) / 2.0, 6)
		ci.draw_rect(Rect2(lp, Vector2(lw, 22)), Color(0.93, 0.85, 0.66, 0.92))
		UiStyle.text(ci, lp + Vector2(0, 17), label, 16, col, HORIZONTAL_ALIGNMENT_CENTER, lw)
		var who := Intro.who_at(data, run.profile, id)
		if who != "" and keep.rooms[id].has("person") and not _away(who):
			UiStyle.text(ci, to_screen(_v(keep.rooms[id].person) + Vector2(-90, 0)) + Vector2(0, 40 * scale_k + 16),
					Dialog.display_name(data, who), 15, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 180 * scale_k, 4)
	for who in _scene_people():
		UiStyle.text(ci, to_screen(_v(keep.scene.people[who]) + Vector2(-90, 0)) + Vector2(0, 36 * scale_k + 16),
				Dialog.display_name(data, who), 15, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 180 * scale_k, 4)
	var world_names := []
	if _tor_here() and not _away("tor"):
		world_names.append(["Tor och arbetarna", TOR_AT + Vector2(0, 36)])
	if WorldEvents.merchant_here(run.profile) and run.profile.intro_done:
		world_names.append(["Handelsmannen", MERCHANT_AT + Vector2(0, 30)])
	if _pilgrim_seat() >= 0:
		world_names.append(["Pilgrimen", _v(keep.inn_seats[_pilgrim_seat()]) + Vector2(0, 30)])
	# Hemkomsten: namnen under dem som har gått fram till paladinen.
	for v in _visitors:
		if not run.data.heroes.has(v.who):
			world_names.append([Dialog.display_name(data, v.who), (v.at as Vector2) + Vector2(0, 30)])
	for n in world_names:
		UiStyle.text(ci, to_screen(n[1] + Vector2(-160, 0)) + Vector2(0, 16), n[0], 15, Color(1, 0.95, 0.85),
				HORIZONTAL_ALIGNMENT_CENTER, 320 * scale_k, 4)
	# Uppdraget eller ett rykte, som en rad överst.
	var quest := _quest_line(data)
	if quest != "":
		UiStyle.text(ci, Vector2(back_rect().end.x, 46), quest, 18, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER,
				size.x - back_rect().end.x * 2, 5)
	for i in CHIPS.size():
		var r := _chip_rect(i)
		var party: bool = CHIPS[i] == "party"
		var state := "open" if party else Intro.station_state(data, run.profile, CHIPS[i])
		var glow := not party and _glows(CHIPS[i])
		ci.draw_rect(r, Color(0.04, 0.035, 0.06, 0.88 if state != "locked" else 0.6))
		ci.draw_rect(r, Color(UiStyle.GOLD, 0.9) if glow else Color(1, 1, 1, 0.25 if state == "locked" else 0.5), false,
				2.0 if glow else 1.0)
		var label := "SÄLLSKAPET" if party else String(Dialog.station(data, CHIPS[i]).get("name", CHIPS[i]))
		UiStyle.text(ci, r.position + Vector2(0, 29), UiStyle.fit(label, 16, r.size.x - 8), 16,
				Color(1, 1, 1, 0.4) if state == "locked" else (UiStyle.TRAIT_GOLD if party else Color.WHITE),
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
	if run.last_silver > 0 and _conv.is_empty():
		UiStyle.text(ci, Vector2(0, size.y - 70), "+%d silver från senaste striden" % run.last_silver, 16,
				Color("#d8dde6"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	if _toast_t > 0.0:
		var a := minf(1.0, _toast_t)
		var w := minf(size.x - 80, 760.0)
		var tr := Rect2((size.x - w) / 2.0, 90, w, 56)
		ci.draw_rect(tr, Color(0.05, 0.04, 0.07, 0.92 * a))
		ci.draw_rect(tr, Color(UiStyle.GOLD, 0.6 * a), false, 1.5)
		UiStyle.text(ci, tr.position + Vector2(0, 35), _toast_text, 18, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, w, 3)
	_option_rects = []
	if not _conv.is_empty():
		var last: bool = _conv.i == _conv.lines.size() - 1
		var line: Dictionary = _conv.lines[_conv.i]
		if line.who == StoryBox.NARRATOR:
			StoryBox.narrator(ci, size, line.text, _t - _conv.get("shown", 0.0))
			return
		var box := DialogBox.box(ci, data, size, line.who, line.text, _t, not (last and _conv.menu))
		if last and _conv.menu:
			_option_rects = DialogBox.options(ci, box, _station_options(_conv.station).map(
					func(o: Dictionary) -> String: return o.label))
	if _home_summary:
		_paint_summary(ci, data)


## Hemkomstens sammanfattning efter samtalet: kartans och världens ändringar, nya titlar och händelsen som pågår.
func _paint_summary(ci: CanvasItem, data: Dictionary) -> void:
	var prof: Profile = run.profile
	var lines: Array = Array(prof.homecoming.get("summary", [])).duplicate()
	var ongoing := WorldEvents.map_line(prof, data)
	if ongoing != "":
		lines.append("Pågår: " + ongoing + ".")
	var titles: Array = prof.homecoming.get("titles", [])
	var w := 780.0
	var x := (size.x - w) / 2.0
	var body := 0.0
	for l in lines:
		body += UiStyle.bold().get_multiline_string_size(String(l), HORIZONTAL_ALIGNMENT_LEFT, w - 64, 17).y + 8
	var h := 96.0 + body + 34.0 * titles.size() + 30.0
	var b := Rect2(x, maxf(20.0, (size.y - h) / 2.0), w, h)
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	ci.draw_rect(b, Color(0.16, 0.11, 0.07, 0.97))
	ci.draw_rect(b, Color(UiStyle.TRAIT_GOLD, 0.8), false, 2.0)
	UiStyle.text(ci, b.position + Vector2(0, 44), "MEDAN NI VAR BORTA", 22, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, w, 3)
	var y := b.position.y + 72
	for l in lines:
		ci.draw_circle(Vector2(x + 30, y + 10), 3.5, UiStyle.TRAIT_GOLD)
		y += UiStyle.para(ci, Vector2(x + 44, y + 16), String(l), 17, Color(1, 1, 1, 0.9), w - 64) + 8
	for t in titles:
		UiStyle.text(ci, Vector2(x + 24, y + 24), "Ny titel: " + Chronicle.title_name(data, t), 20, UiStyle.TRAIT_GOLD,
				HORIZONTAL_ALIGNMENT_LEFT, w - 48, 3)
		y += 34
	UiStyle.text(ci, Vector2(x, b.end.y - 14), "Tryck för att fortsätta", 15, Color(1, 1, 1, 0.55),
			HORIZONTAL_ALIGNMENT_CENTER, w)


func _quest_line(data: Dictionary) -> String:
	if not run.profile.intro_done:
		var q := Intro.quest_text(data, run.profile)
		return "" if q == "" else "UPPDRAG: " + q
	if run.profile.find_quest == 1:
		return "UPPDRAG: " + String(data.dialog.get("find_quest", {}).get("quest_line", ""))
	for realm_id in data.realms:
		for d in RunState.findable_for(run.profile, data, realm_id):
			return "RYKTE: %s sägs sitta fången i %s, djup %d." % [data.heroes[d.hero].get("short", d.hero),
					String(data.realms[realm_id].short).to_lower(), int(d.depth)]
	return ""
