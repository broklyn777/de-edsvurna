class_name Parchment
extends ColorRect
## Pergamentet under kampanjkartan och rumskartan, ritat med en shader (brus, fläckar, mörka kanter)
## i stället för en stor textur, så att APK:n inte växer (shadern körs en gång, se _bake). zoom och focus låter
## kameran glida in i ett område (samma pergament på båda kartorna).

const SHADER := """
shader_type canvas_item;
uniform float zoom = 1.0;
uniform vec2 focus = vec2(0.5, 0.5);
uniform float seed = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 uv = (UV - focus) / zoom + focus;
	vec2 p = uv * vec2(16.0, 9.0);
	float n = fbm(p * 0.9);
	float fibers = fbm(vec2(p.x * 6.0, p.y * 0.6)) * 0.08;
	float stains = smoothstep(0.62, 0.8, fbm(p * 0.35 + 7.0)) * 0.18;
	vec3 paper = mix(vec3(0.80, 0.70, 0.50), vec3(0.92, 0.84, 0.66), n);
	paper -= fibers + stains * vec3(0.5, 0.6, 0.8);
	vec2 d = UV - 0.5;
	float vignette = smoothstep(0.35, 0.8, length(d * vec2(1.0, 1.3)));
	paper *= 1.0 - vignette * 0.55;
	COLOR = vec4(paper, 1.0);
}
"""

var _mat: ShaderMaterial
## Prestanda (docs/research/prestanda-android.md punkt 2): bruset (15 brusanrop per pixel) ritas en gång till en
## textur i en egen SubViewport och visas sedan som en bild. Det ritas om bara när storleken eller vyn (zoomen) ändras.
var _vp: SubViewport
var _paper: ColorRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	color = Color(0.86, 0.77, 0.58)  # syns bara innan texturen är ritad
	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_vp = SubViewport.new()
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_paper = ColorRect.new()
	_paper.material = _mat
	_vp.add_child(_paper)
	add_child(_vp)
	resized.connect(_bake)


func _ready() -> void:
	_bake.call_deferred()


## Ritar pergamentet en gång i skärmens verkliga upplösning (canvas_items-skalningen inräknad).
func _bake() -> void:
	if not is_inside_tree() or size.x < 1.0 or size.y < 1.0:
		return
	var k := Vector2(get_window().size) / get_viewport_rect().size
	var px := Vector2i(maxi(1, ceili(size.x * k.x)), maxi(1, ceili(size.y * k.y)))
	var limit := 2560.0 / px.x
	if limit < 1.0:
		px = Vector2i(2560, maxi(1, int(px.y * limit)))
	_vp.size = px
	_paper.size = Vector2(px)
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_vp.get_texture(), Rect2(Vector2.ZERO, size), false)


## Kameran på pergamentet: zoom > 1 glider in mot focus (0–1 i skärmens mått).
func set_view(zoom: float, focus: Vector2) -> void:
	_mat.set_shader_parameter("zoom", zoom)
	_mat.set_shader_parameter("focus", focus)
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## Bläckfärger för kartornas linjer och text.
const INK := Color(0.22, 0.14, 0.08)
const INK_LIGHT := Color(0.22, 0.14, 0.08, 0.45)
const SEAL := Color(0.62, 0.12, 0.08)
const CORRUPTION := Color(0.20, 0.06, 0.22)
