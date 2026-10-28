class_name CryptWorld
extends Node3D
## Benkryptan i 3D: golv, pelare, facklor, runcirkel, ljus och kameran snett ovanifrån.
## Byggs i kod så att den är lätt att justera; riktiga miljömodeller kan ersätta delarna senare.

const ARENA_RADIUS := 7.5
const CAMERA_POS := Vector3(0.0, 8.6, 8.4)
const CAMERA_LOOK := Vector3(0.4, 1.3, -0.9)

## 0.31: "grove" (Sidenlunden, realms.json "style") gör kryptan till en lund: grönare dimma, mossigt golv, stammar med
## nät i stället för pelare och kokonger i stället för ben. Sätts före add_child.
## Trollberget: "mountain" ger kallt ljus, grå granit, grova stenpelare och flyttblock i stället för ben.
var style := "crypt"
var camera: Camera3D
var shake := 0.0
var _torches: Array[OmniLight3D] = []
var _trunks: Array[Vector3] = []
var _runes: StandardMaterial3D
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 11
	_build_environment()
	_build_floor()
	_build_pillars()
	if style == "grove":
		_build_webs()
	elif style == "mountain":
		_build_boulders()
	else:
		_build_bones()
	camera = Camera3D.new()
	camera.fov = 40.0
	add_child(camera)
	camera.position = CAMERA_POS
	camera.look_at(CAMERA_LOOK)


func _process(delta: float) -> void:
	_t += delta
	shake = maxf(0.0, shake - delta * 40.0)
	var k := shake * 0.004
	camera.h_offset = randf_range(-k, k)
	camera.v_offset = randf_range(-k, k)
	for i in _torches.size():
		_torches[i].light_energy = 2.2 + 0.35 * sin(_t * 11.0 + i * 2.1) + 0.2 * sin(_t * 23.0 + i)


func project(world_pos: Vector3) -> Vector2:
	return camera.unproject_position(world_pos)


func add_shake(amount: float) -> void:
	shake = minf(24.0, maxf(shake, amount))


## Röd varningscirkel på golvet under ett tungt slag. Anropa set_progress varje bildruta.
func make_telegraph(radius: float) -> Node3D:
	var root := Node3D.new()
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.01
	disc.mesh = cyl
	disc.name = "Fill"
	disc.material_override = _flat_material(Color(1, 0.15, 0.05, 0.35))
	root.add_child(disc)
	var edge := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.05
	torus.outer_radius = radius + 0.05
	torus.rings = 64
	edge.mesh = torus
	edge.material_override = _flat_material(Color(1, 0.25, 0.1, 0.9))
	root.add_child(edge)
	root.position.y = 0.03
	add_child(root)
	return root


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var grove := style == "grove"
	var mountain := style == "mountain"
	env.background_color = Color(0.015, 0.025, 0.02) if grove else (Color(0.014, 0.02, 0.03) if mountain else Color(0.02, 0.018, 0.03))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.44, 0.38) if grove else (Color(0.38, 0.42, 0.5) if mountain else Color(0.4, 0.37, 0.46))
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.1, 0.07) if grove else (Color(0.07, 0.085, 0.11) if mountain else Color(0.08, 0.06, 0.12))
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.75, 0.9, 0.8) if grove else (Color(0.72, 0.82, 1.0) if mountain else Color(0.7, 0.72, 1.0))
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-62, -35, 0)
	add_child(moon)

	var key := OmniLight3D.new()
	key.light_color = Color(0.86, 0.9, 1.0) if mountain else Color(1.0, 0.85, 0.7)
	key.light_energy = 1.2
	key.omni_range = 9.0
	key.position = Vector3(-1.0, 4.5, 2.5)
	add_child(key)


func _build_floor() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.55, 0.53, 0.52))
	ramp.set_color(1, Color(0.9, 0.88, 0.85))
	tex.color_ramp = ramp
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.3, 0.36, 0.26) if style == "grove" else (Color(0.37, 0.39, 0.41) if style == "mountain" else Color(0.42, 0.39, 0.38))
	stone.albedo_texture = tex
	stone.uv1_scale = Vector3(6, 6, 6)
	stone.roughness = 0.95

	var floor_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = ARENA_RADIUS + 6.0
	cyl.bottom_radius = ARENA_RADIUS + 6.0
	cyl.height = 0.2
	cyl.radial_segments = 64
	floor_mesh.mesh = cyl
	floor_mesh.material_override = stone
	floor_mesh.position.y = -0.1
	add_child(floor_mesh)

	var dais := MeshInstance3D.new()
	var d := CylinderMesh.new()
	d.top_radius = 4.6
	d.bottom_radius = 4.8
	d.height = 0.08
	d.radial_segments = 64
	dais.mesh = d
	var dais_mat := stone.duplicate() as StandardMaterial3D
	dais_mat.albedo_color = Color(0.34, 0.38, 0.3) if style == "grove" else (Color(0.42, 0.44, 0.47) if style == "mountain" else Color(0.45, 0.42, 0.47))
	dais.material_override = dais_mat
	dais.position.y = 0.0
	add_child(dais)

	_runes = StandardMaterial3D.new()
	_runes.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# 0.22.1: tonad, så att runcirkeln läses som en del av golvet och inte som en markering i striden.
	_runes.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_runes.albedo_color = Color(0.85, 0.85, 0.8, 0.22) if style == "grove" else (Color(0.62, 0.7, 0.82, 0.2) if style == "mountain" else Color(0.42, 0.36, 0.55, 0.28))
	_runes.emission_enabled = false
	for r in [3.2, 4.4]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.03
		torus.outer_radius = r + 0.03
		torus.rings = 96
		ring.mesh = torus
		ring.material_override = _runes
		ring.position.y = 0.05
		add_child(ring)
	for i in 8:
		var a := i * TAU / 8.0
		var rune := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.28, 0.02, 0.28)
		rune.mesh = box
		rune.material_override = _runes
		rune.position = Vector3(cos(a) * 3.8, 0.05, sin(a) * 3.8)
		rune.rotation.y = a + PI / 4
		add_child(rune)


func _build_pillars() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.17, 0.12) if style == "grove" else (Color(0.34, 0.35, 0.37) if style == "mountain" else Color(0.3, 0.28, 0.32))
	mat.roughness = 0.9
	_trunks.clear()
	for i in 10:
		var a := i * TAU / 10.0 + 0.3
		var p := Vector3(cos(a) * ARENA_RADIUS, 0, sin(a) * ARENA_RADIUS * 0.85)
		if p.z > 3.0:
			continue  # inga pelare framför kameran
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.3 if style == "grove" else (0.5 if style == "mountain" else 0.45)
		cyl.bottom_radius = 0.6 if style == "grove" else (0.85 if style == "mountain" else 0.55)
		if style == "mountain":
			cyl.radial_segments = 7  # grov sten, inte svarvad
		cyl.height = 5.0
		pillar.mesh = cyl
		pillar.material_override = mat
		pillar.position = p + Vector3(0, 2.5, 0)
		add_child(pillar)
		_trunks.append(p)
		if i % 2 == 0:
			var torch := OmniLight3D.new()
			torch.light_color = Color(1.0, 0.55, 0.2)
			torch.omni_range = 6.0
			torch.position = p + Vector3(0, 2.2, 0) - p.normalized() * 0.7
			add_child(torch)
			_torches.append(torch)
			var flame := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.12
			s.height = 0.3
			flame.mesh = s
			flame.material_override = _flat_material(Color(1.0, 0.7, 0.3), true)
			flame.position = torch.position
			add_child(flame)


func _build_bones() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.78, 0.68)
	for i in 34:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(4.9, ARENA_RADIUS - 0.6)
		var bone := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.04
		cap.height = _rng.randf_range(0.3, 0.6)
		bone.mesh = cap
		bone.material_override = mat
		bone.position = Vector3(cos(a) * d, 0.04, sin(a) * d * 0.85)
		bone.rotation = Vector3(PI / 2, _rng.randf() * TAU, 0)
		add_child(bone)
	for i in 5:
		var a := _rng.randf() * TAU
		var skull := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.13
		s.height = 0.24
		skull.mesh = s
		skull.material_override = mat
		skull.position = Vector3(cos(a) * 5.8, 0.1, sin(a) * 5.0)
		add_child(skull)


## Trollberget: flyttblock och grus vid kanten, som om berget har kastat dem.
func _build_boulders() -> void:
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.4, 0.41, 0.42)
	rock.roughness = 1.0
	var moss := StandardMaterial3D.new()
	moss.albedo_color = Color(0.24, 0.3, 0.22)
	moss.roughness = 1.0
	for i in 9:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(5.4, ARENA_RADIUS - 0.3)
		var b := MeshInstance3D.new()
		var s := SphereMesh.new()
		var r := _rng.randf_range(0.25, 0.6)
		s.radius = r
		s.height = r * _rng.randf_range(1.1, 1.6)
		s.radial_segments = 7
		s.rings = 4
		b.mesh = s
		b.material_override = moss if i % 3 == 0 else rock
		b.position = Vector3(cos(a) * d, r * 0.35, sin(a) * d * 0.85)
		b.rotation = Vector3(_rng.randf() * 0.4, _rng.randf() * TAU, _rng.randf() * 0.4)
		add_child(b)
	for i in 26:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(4.9, ARENA_RADIUS - 0.4)
		var g := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * _rng.randf_range(0.06, 0.14)
		g.mesh = box
		g.material_override = rock
		g.position = Vector3(cos(a) * d, 0.04, sin(a) * d * 0.85)
		g.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, 0)
		add_child(g)


## Sidenlunden: nät mellan stammarna och kokonger på marken.
func _build_webs() -> void:
	var silk := _flat_material(Color(0.92, 0.92, 0.88, 0.35))
	for i in _trunks.size():
		var a: Vector3 = _trunks[i]
		var b: Vector3 = _trunks[(i + 1) % _trunks.size()]
		if a.distance_to(b) > 6.0:
			continue
		for k in 4:
			var h1 := _rng.randf_range(0.6, 4.2)
			var h2 := _rng.randf_range(0.6, 4.2)
			_strand(a + Vector3(0, h1, 0), b + Vector3(0, h2, 0), silk)
		for k in 3:
			_strand(a + Vector3(0, _rng.randf_range(1.0, 4.0), 0), a.lerp(Vector3.ZERO, 0.25) + Vector3(0, 0.02, 0), silk)
	var cocoon := StandardMaterial3D.new()
	cocoon.albedo_color = Color(0.62, 0.6, 0.53)
	cocoon.roughness = 1.0
	for i in 6:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(5.6, ARENA_RADIUS - 0.4)
		var c := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.13
		cap.height = _rng.randf_range(0.45, 0.75)
		cap.radial_segments = 8
		c.mesh = cap
		c.material_override = cocoon
		c.position = Vector3(cos(a) * d, 0.15, sin(a) * d * 0.85)
		c.rotation = Vector3(PI / 2, _rng.randf() * TAU, 0)
		add_child(c)


func _strand(from: Vector3, to: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.015, 0.015, from.distance_to(to))
	m.mesh = box
	m.material_override = mat
	add_child(m)
	m.position = (from + to) * 0.5
	m.look_at_from_position(m.position, to, Vector3.UP if absf((to - from).normalized().y) < 0.95 else Vector3.RIGHT)


func _flat_material(c: Color, emissive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		m.emission_enabled = true
		m.emission = c
	return m
