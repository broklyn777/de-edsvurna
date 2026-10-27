class_name InkPost
extends MeshInstance3D
## Tuschstilen i striden (prototyp, grenen ink-proto, VD 2026-10-27): en efterbehandling över 3D-scenen, ritad som en
## skärmfyllande fyrkant framför kameran. Konturer ur djupet (silhuetter) och ur färgen (inre linjer), färgerna dragna mot
## sepia och bläck, papper med fibrer och fläckar som kartornas pergament och skraffering i skuggorna. Bara utseende.
## Djupet läses med hint_depth_texture, som GL Compatibility har (en kopia av djupbufferten per bildruta).

const SHADER := """
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float line_px = 1.8;
uniform float ink_amount = 1.0;
// Mätningen (INK_PROBE): 1 = inget papper, 2 = inga inre linjer, 3 = inget djup.
uniform int probe = 0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
	return -v.z / v.w;
}

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = line_px / VIEWPORT_SIZE;
	vec3 col = texture(screen_tex, uv).rgb;

	// Silhuetter: skillnaden i avstånd mot grannarna, i proportion till avståndet (så att långt bort inte blir svart).
	float sil = 0.0;
	if (probe != 3) {
	float dc = lin_depth(uv, INV_PROJECTION_MATRIX);
	float dl = lin_depth(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float dr = lin_depth(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float du = lin_depth(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float dd = lin_depth(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float lap = abs(dl + dr + du + dd - 4.0 * dc) / max(dc, 0.5);
	sil = smoothstep(0.02, 0.06, lap);
	}

	// Inre linjer: färgens kanter (Sobel på ljusheten), svagare än silhuetterna.
	float inner = 0.0;
	if (probe != 2) {
	float l00 = lum(texture(screen_tex, uv + vec2(-px.x, -px.y)).rgb);
	float l10 = lum(texture(screen_tex, uv + vec2(0.0, -px.y)).rgb);
	float l20 = lum(texture(screen_tex, uv + vec2(px.x, -px.y)).rgb);
	float l01 = lum(texture(screen_tex, uv + vec2(-px.x, 0.0)).rgb);
	float l21 = lum(texture(screen_tex, uv + vec2(px.x, 0.0)).rgb);
	float l02 = lum(texture(screen_tex, uv + vec2(-px.x, px.y)).rgb);
	float l12 = lum(texture(screen_tex, uv + vec2(0.0, px.y)).rgb);
	float l22 = lum(texture(screen_tex, uv + vec2(px.x, px.y)).rgb);
	float gx = (l20 + 2.0 * l21 + l22) - (l00 + 2.0 * l01 + l02);
	float gy = (l02 + 2.0 * l12 + l22) - (l00 + 2.0 * l10 + l20);
	inner = smoothstep(0.28, 0.6, length(vec2(gx, gy)));
	}

	// Papper: samma brus som kartornas pergament, fast i skärmen.
	vec2 p = uv * vec2(16.0, 9.0);
	float n = fbm(p * 0.9);
	float fibers = fbm(vec2(p.x * 6.0, p.y * 0.6)) * 0.07;
	float stains = smoothstep(0.62, 0.8, fbm(p * 0.35 + 7.0)) * 0.14;
	vec3 paper = mix(vec3(0.80, 0.70, 0.50), vec3(0.93, 0.85, 0.67), n) - fibers - stains * vec3(0.5, 0.6, 0.8);
	if (probe == 1) { paper = vec3(0.86, 0.77, 0.58); }
	vec3 ink = vec3(0.13, 0.09, 0.06);

	// Färgskalan: ljusheten blir en lavering mellan bläck och papper, med en svag rest av färgen (sepia, inte grått).
	float l = clamp(lum(col) * 1.25, 0.0, 1.0);
	float tone = smoothstep(0.0, 0.72, l);
	vec3 wash = mix(ink * 1.8, paper, tone);
	// Starka färger (manteln, lågor, elitens glöd) behåller mer av sig själva, som en lavering i akvarell.
	vec3 hue = col / max(lum(col), 0.05);
	float sat = max(col.r, max(col.g, col.b)) - min(col.r, min(col.g, col.b));
	wash *= mix(vec3(1.0), clamp(hue, 0.5, 1.6), 0.12 + 0.4 * smoothstep(0.25, 0.6, sat));

	// Skraffering i skuggorna: diagonala streck, tätare ju mörkare, och korsade i det mörkaste.
	vec2 sp = FRAGCOORD.xy;
	float h1 = step(0.55, fract((sp.x + sp.y) / 6.0));
	float h2 = step(0.55, fract((sp.x - sp.y) / 6.0));
	float wobble = noise(sp * 0.05) * 0.25;
	float hatch = h1 * (1.0 - smoothstep(0.12, 0.34 + wobble, l)) + h2 * (1.0 - smoothstep(0.04, 0.16 + wobble, l));
	wash = mix(wash, ink, clamp(hatch, 0.0, 1.0) * 0.4);

	// Linjerna i bläck, lite ojämna som en penna.
	float pen = 0.75 + 0.25 * noise(sp * 0.12);
	float line = clamp(max(sil, inner * 0.45) * pen, 0.0, 1.0);
	vec3 outc = mix(wash, ink, line);
	// Mörkare kanter som på kartorna.
	vec2 dv = uv - 0.5;
	outc *= 1.0 - smoothstep(0.35, 0.85, length(dv * vec2(1.0, 1.3))) * 0.45;

	ALBEDO = mix(col, outc, ink_amount);
}
"""

var _mat: ShaderMaterial


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	mesh = quad
	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.render_priority = 100
	material_override = _mat
	extra_cull_margin = 16384.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position = Vector3(0, 0, -1)
	if OS.get_environment("INK_PROBE") != "":
		_mat.set_shader_parameter("probe", int(OS.get_environment("INK_PROBE")))
