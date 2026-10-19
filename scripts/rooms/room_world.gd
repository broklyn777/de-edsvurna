class_name RoomWorld
extends Node3D
## Ett rum på rumskartan i 3D: väggar, golv, en dörr i främre väggen och rummets mittpunkt
## (kista, altare, bur, stentavla, lägereld eller portal). Byggs i kod som CryptWorld, utan modellfiler
## utom statyn och fången, som lånar figurerna i assets/models/ (torvald, alva).
##
##   var room := RoomWorld.new()
##   room.kind = "treasure"   # KINDS
##   room.style = "crypt"     # STYLES
##   add_child(room)
##   room.open_door(0.7)      # sekunder
##   room.reveal()            # rummets händelse: locket öppnas, runorna tänds …
##
## Koordinater: rummet går från z = BACK till z = FRONT, dörren sitter mitt i främre väggen
## och korridoren utanför fortsätter mot +z. Mittpunkten står i CENTER.

const KINDS := ["treasure", "shrine", "prisoner", "inscription", "campfire", "portal"]
const STYLES := ["crypt", "chapel"]
const NAMES := {
	"treasure": "Skattkammare", "shrine": "Helgedom", "prisoner": "Fånge",
	"inscription": "Inskrift", "campfire": "Lägereld", "portal": "Portal",
}

const HALF_W := 5.0
const FRONT := 5.0
const BACK := -6.5
const WALL_H := 5.5
const DOOR_W := 2.6
const DOOR_H := 3.6
const CENTER := Vector3(0, 0, -2.3)

## Rummets händelse: hur länge den tar innan den vilar i sitt slutläge.
const REVEAL_TIME := 1.8

var kind := "treasure"
var style := "crypt"
var revealed := 0.0  ## 0 → 1 under reveal()

var _t := 0.0
var _revealing := false
var _rng := RandomNumberGenerator.new()
var _pal: Dictionary
var _flicker: Array = []  ## [ljus, grundstyrka]
var _door_leaves: Array[Node3D] = []
var _door_open := 0.0
var _door_speed := 0.0
var _reveal_light: OmniLight3D
## Saker som rör sig när rummet visas: anropas med (andel 0–1, delta).
var _reveal_steps: Array[Callable] = []
var _idle_steps: Array[Callable] = []
var _bursts: Array[CPUParticles3D] = []
## Delar som rör sig och därför inte får slås ihop med resten (se _merge_static).
var _dynamic: Array[Node3D] = []


func _ready() -> void:
	_rng.seed = hash(kind + style)
	_pal = _palette()
	_build_environment()
	_build_shell()
	_build_door()
	_build_dressing()
	# Väggar, golv, dörr och utsmyckning kastar ingen skugga: bara mittpunkten och figurerna gör det.
	# Skuggpasset ritar annars om hela rummet en gång till.
	for g in find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	match kind:
		"treasure": _build_treasure()
		"shrine": _build_shrine()
		"prisoner": _build_prisoner()
		"inscription": _build_inscription()
		"campfire": _build_campfire()
		"portal": _build_portal()
	_merge_static()


func _process(delta: float) -> void:
	_t += delta
	for f in _flicker:
		var l: OmniLight3D = f[0]
		var i := l.get_instance_id() % 7
		l.light_energy = f[1] * (1.0 + 0.16 * sin(_t * 11.0 + i * 2.1) + 0.09 * sin(_t * 23.0 + i))
	if _door_speed > 0.0 and _door_open < 1.0:
		_door_open = minf(1.0, _door_open + delta * _door_speed)
		var k := 1.0 - pow(1.0 - _door_open, 3.0)
		_door_leaves[0].rotation.y = deg_to_rad(100.0) * k
		_door_leaves[1].rotation.y = deg_to_rad(-100.0) * k
	if _revealing and revealed < 1.0:
		revealed = minf(1.0, revealed + delta / REVEAL_TIME)
	for step in _reveal_steps:
		step.call(revealed, delta)
	for step in _idle_steps:
		step.call(delta)


## Svänger upp dörrbladen (utåt, mot korridoren) under så många sekunder.
func open_door(duration := 0.7) -> void:
	_door_speed = 1.0 / maxf(duration, 0.05)


## Startar rummets händelse.
func reveal() -> void:
	_revealing = true
	for b in _bursts:
		b.restart()
		b.emitting = true


## Var sällskapet ställer sig, vänt mot mittpunkten: [position, …] för n figurer.
func party_slots(n: int) -> Array[Vector3]:
	var angles := [-24.0, 24.0, -54.0, 54.0, 82.0, -82.0]
	var radius := 3.6
	var out: Array[Vector3] = []
	for i in n:
		var a := deg_to_rad(angles[i % angles.size()])
		out.append(CENTER + Vector3(sin(a) * radius, 0, cos(a) * radius))
	return out


## Var sällskapet väntar utanför dörren innan det går in.
func entry_slots(n: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in n:
		var x := -0.45 if i % 2 == 0 else 0.45
		out.append(Vector3(x, 0, FRONT + 1.2 + (i / 2) * 1.0 + (i % 2) * 0.35))
	return out


## Punkten kameran ska titta på när händelsen visas.
func focus_point() -> Vector3:
	match kind:
		"portal": return CENTER + Vector3(0, 1.7, 0)
		"shrine": return CENTER + Vector3(0, 1.4, -0.3)
		"inscription": return CENTER + Vector3(0, 1.3, 0)
		"campfire": return CENTER + Vector3(0, 0.6, 0)
	return CENTER + Vector3(0, 0.9, 0)


# --- Stil -----------------------------------------------------------------------

func _palette() -> Dictionary:
	if style == "chapel":
		return {
			"bg": Color(0.035, 0.03, 0.03), "ambient": Color(0.55, 0.48, 0.42), "ambient_energy": 0.52,
			"fog": Color(0.12, 0.09, 0.07), "stone": Color(0.66, 0.6, 0.52), "stone_dark": Color(0.42, 0.37, 0.32),
			"floor": Color(0.55, 0.5, 0.45), "trim": Color(0.82, 0.65, 0.32), "torch": Color(1.0, 0.72, 0.4),
			"accent": Color(1.0, 0.82, 0.45), "wood": Color(0.32, 0.18, 0.1),
		}
	return {
		"bg": Color(0.02, 0.018, 0.03), "ambient": Color(0.46, 0.39, 0.42), "ambient_energy": 0.55,
		"fog": Color(0.08, 0.06, 0.12), "stone": Color(0.38, 0.35, 0.36), "stone_dark": Color(0.24, 0.22, 0.25),
		"floor": Color(0.4, 0.37, 0.36), "trim": Color(0.55, 0.42, 0.75), "torch": Color(1.0, 0.55, 0.2),
		"accent": Color(0.6, 0.4, 1.0), "wood": Color(0.25, 0.16, 0.1),
	}


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _pal.bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _pal.ambient
	env.ambient_light_energy = _pal.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.fog_enabled = true
	env.fog_light_color = _pal.fog
	env.fog_density = 0.025
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.7, 0.72, 1.0) if style == "crypt" else Color(1.0, 0.9, 0.75)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-58, -30, 0)
	add_child(moon)


func _build_shell() -> void:
	var wall := _stone_material(_pal.stone, 3.0)
	var floor_mat := _stone_material(_pal.floor, 5.0)
	# Golv i rummet och korridoren utanför.
	_box(Vector3(HALF_W * 2 + 1, 0.2, FRONT - BACK + 1), Vector3(0, -0.1, (FRONT + BACK) / 2.0), floor_mat)
	_box(Vector3(DOOR_W + 1.6, 0.2, 9.0), Vector3(0, -0.1, FRONT + 4.5), floor_mat)
	# Golvplattor: fogar som tunna mörka streck.
	var seam := _material(_pal.stone_dark * 0.6)
	for x in range(-4, 5, 2):
		_box(Vector3(0.04, 0.012, FRONT - BACK), Vector3(x, 0.005, (FRONT + BACK) / 2.0), seam)
	for z in range(int(BACK) + 1, int(FRONT), 2):
		_box(Vector3(HALF_W * 2, 0.012, 0.04), Vector3(0, 0.005, z), seam)
	# Väggar. Främre väggen har en öppning för dörren.
	var t := 0.6
	_box(Vector3(HALF_W * 2 + 2 * t, WALL_H, t), Vector3(0, WALL_H / 2, BACK - t / 2), wall)
	for side in [-1, 1]:
		_box(Vector3(t, WALL_H, FRONT - BACK), Vector3(side * (HALF_W + t / 2), WALL_H / 2, (FRONT + BACK) / 2.0), wall)
		var w := HALF_W - DOOR_W / 2.0 + t
		_box(Vector3(w, WALL_H, t), Vector3(side * (DOOR_W / 2.0 + w / 2.0), WALL_H / 2, FRONT + t / 2), wall)
		# Korridorens väggar.
		_box(Vector3(t, DOOR_H + 0.6, 9.0), Vector3(side * (DOOR_W / 2.0 + 0.8 + t / 2), (DOOR_H + 0.6) / 2, FRONT + 4.5), wall)
	_box(Vector3(DOOR_W, WALL_H - DOOR_H, t), Vector3(0, DOOR_H + (WALL_H - DOOR_H) / 2, FRONT + t / 2), wall)
	# Pelare längs sidväggarna och i hörnen.
	var pillar := _stone_material(_pal.stone_dark, 2.0)
	for side in [-1, 1]:
		for z in [BACK + 0.6, -2.0, 2.0]:
			var p := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.32
			cyl.bottom_radius = 0.4
			cyl.height = WALL_H
			p.mesh = cyl
			p.material_override = pillar
			p.position = Vector3(side * (HALF_W - 0.35), WALL_H / 2, z)
			add_child(p)
			_box(Vector3(1.0, 0.25, 1.0), Vector3(side * (HALF_W - 0.35), 0.12, z), pillar)


func _build_door() -> void:
	var frame := _material(_pal.stone_dark)
	var trim := _material(_pal.trim, 0.0, 0.4)
	for side in [-1, 1]:
		_box(Vector3(0.35, DOOR_H + 0.2, 0.9), Vector3(side * (DOOR_W / 2.0 + 0.17), (DOOR_H + 0.2) / 2, FRONT + 0.3), frame)
	_box(Vector3(DOOR_W + 0.7, 0.45, 0.9), Vector3(0, DOOR_H + 0.22, FRONT + 0.3), frame)
	_box(Vector3(0.5, 0.5, 0.95), Vector3(0, DOOR_H + 0.25, FRONT + 0.3), trim)  # slutsten
	var wood := _material(_pal.wood)
	var iron := _material(Color(0.18, 0.18, 0.2), 0.0, 0.6, 0.5)
	for side in [-1, 1]:
		var hinge := Node3D.new()
		hinge.position = Vector3(side * DOOR_W / 2.0, 0, FRONT + 0.7)
		add_child(hinge)
		var leaf_w := DOOR_W / 2.0 - 0.02
		var leaf := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(leaf_w, DOOR_H - 0.05, 0.12)
		leaf.mesh = b
		leaf.material_override = wood
		leaf.position = Vector3(-side * leaf_w / 2.0, DOOR_H / 2.0, 0)
		hinge.add_child(leaf)
		for y in [0.6, DOOR_H - 0.7]:
			var band := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(leaf_w, 0.14, 0.16)
			band.mesh = bb
			band.material_override = iron
			band.position = Vector3(-side * leaf_w / 2.0, y, 0)
			hinge.add_child(band)
		var ring := MeshInstance3D.new()
		var tr := TorusMesh.new()
		tr.inner_radius = 0.08
		tr.outer_radius = 0.12
		ring.mesh = tr
		ring.material_override = iron
		ring.rotation.x = PI / 2
		ring.position = Vector3(-side * (leaf_w - 0.25), DOOR_H * 0.48, 0.1)
		hinge.add_child(ring)
		_door_leaves.append(hinge)
		_dynamic.append(hinge)
	# Två facklor i korridoren delar på ett ljus.
	for side in [-1, 1]:
		_torch(Vector3(side * (DOOR_W / 2.0 + 0.6), 2.4, FRONT + 2.6), false)
	_flicker.append([_light(Vector3(0, 2.6, FRONT + 2.4), _pal.torch, 1.8, 5.5), 1.8])


## Det som gör stilen: facklor och benrester i kryptan, ljus, glasfönster och matta i kapellet.
func _build_dressing() -> void:
	if style == "chapel":
		var carpet := _material(Color(0.45, 0.07, 0.08))
		_box(Vector3(1.6, 0.03, FRONT - CENTER.z - 1.4), Vector3(0, 0.015, (FRONT + CENTER.z + 1.4) / 2.0), carpet)
		var hem := _material(_pal.trim, 0.0, 0.3)
		for side in [-1, 1]:
			_box(Vector3(0.08, 0.035, FRONT - CENTER.z - 1.4), Vector3(side * 0.76, 0.016, (FRONT + CENTER.z + 1.4) / 2.0), hem)
		# Spetsbågiga glasfönster på bakväggen och sidorna. De lyser själva; ett gemensamt
		# färgat ljus vid bakväggen ger rummet deras sken.
		var glass := [Color(0.9, 0.25, 0.2), Color(0.25, 0.45, 1.0), Color(1.0, 0.8, 0.3)]
		var spots := [[Vector3(-2.6, 3.2, BACK + 0.02), 0.0], [Vector3(2.6, 3.2, BACK + 0.02), 0.0],
				[Vector3(-HALF_W + 0.02, 3.2, 0.0), PI / 2], [Vector3(HALF_W - 0.02, 3.2, 0.0), -PI / 2]]
		for i in spots.size():
			_window(spots[i][0], spots[i][1], glass[i % glass.size()])
		_light(Vector3(0, 3.4, BACK + 1.4), Color(0.8, 0.62, 0.95), 1.0, 6.5)
		# Ljusstakar längs väggarna; lågorna lyser själva och ett ljus i taket ger skenet.
		for p in [Vector3(-3.8, 0, -4.8), Vector3(3.8, 0, -4.8), Vector3(-4.0, 0, 3.6), Vector3(4.0, 0, 3.6)]:
			_candelabra(p)
		_flicker.append([_light(Vector3(0, 4.2, 0.5), _pal.torch, 1.4, 11.0), 1.4])
	else:
		for p in [Vector3(-HALF_W + 0.1, 2.5, -4.2), Vector3(HALF_W - 0.1, 2.5, -4.2),
				Vector3(-HALF_W + 0.1, 2.5, 0.0), Vector3(HALF_W - 0.1, 2.5, 0.0)]:
			_torch(p, false)
		# Facklorna på varje sida delar på ett ljus mitt emellan sig.
		for side in [-1, 1]:
			var at := Vector3(side * (HALF_W - 0.9), 2.5, -2.1)
			_flicker.append([_light(at, _pal.torch, 2.6, 9.0), 2.6])
		# Runband längs bakväggen.
		var runes := _material(_pal.accent, 1.4)
		_box(Vector3(HALF_W * 2 - 0.4, 0.05, 0.03), Vector3(0, 3.9, BACK + 0.02), runes)
		var bone := _material(Color(0.82, 0.78, 0.68))
		for i in 26:
			var a := _rng.randf() * TAU
			var corner := Vector3(_rng.randf_range(-HALF_W + 0.4, HALF_W - 0.4), 0.04, _rng.randf_range(BACK + 0.4, FRONT - 0.6))
			if absf(corner.x) < 2.0 and corner.z > CENTER.z - 1.5:
				continue  # inga ben där sällskapet går
			var b := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.04
			cap.height = _rng.randf_range(0.3, 0.6)
			b.mesh = cap
			b.material_override = bone
			b.position = corner
			b.rotation = Vector3(PI / 2, a, 0)
			add_child(b)
		for p in [Vector3(-4.2, 0.1, -5.6), Vector3(4.3, 0.1, 3.9), Vector3(-4.4, 0.1, 2.6)]:
			_sphere(0.13, p, bone)
	# Spindelvävsmörker högst upp: ett svart tak så att rummet inte ser öppet ut.
	_box(Vector3(HALF_W * 2 + 2, 0.2, FRONT - BACK + 2), Vector3(0, WALL_H + 0.1, (FRONT + BACK) / 2.0), _material(_pal.bg))


# --- Rumstyperna --------------------------------------------------------------

## Skattkammare: kista på ett podium, guldhögar; locket öppnas och guldet glimmar.
func _build_treasure() -> void:
	var gold := _material(Color(1.0, 0.76, 0.25), 0.0, 0.8, 0.3)
	gold.emission_enabled = true
	gold.emission = Color(0.6, 0.38, 0.05)
	gold.emission_energy_multiplier = 0.15
	var wood := _material(Color(0.42, 0.2, 0.08))
	var iron := _material(Color(0.75, 0.6, 0.3), 0.0, 0.7, 0.35)
	var root := Node3D.new()
	root.position = CENTER
	add_child(root)
	_box(Vector3(2.6, 0.3, 1.9), Vector3(0, 0.15, 0), _stone_material(_pal.stone_dark, 1.0), root)
	_box(Vector3(1.5, 0.75, 0.9), Vector3(0, 0.3 + 0.375, 0), wood, root)
	for x in [-0.6, 0.0, 0.6]:
		_box(Vector3(0.1, 0.78, 0.94), Vector3(x, 0.3 + 0.375, 0), iron, root)
	# Gulden i kistan syns först när locket lyfts.
	_box(Vector3(1.36, 0.08, 0.76), Vector3(0, 1.0, 0), gold, root)
	for i in 10:
		_sphere(0.12, Vector3(_rng.randf_range(-0.55, 0.55), 1.05, _rng.randf_range(-0.25, 0.25)), gold, root)
	var lid_hinge := Node3D.new()
	lid_hinge.position = Vector3(0, 1.05, -0.45)
	root.add_child(lid_hinge)
	_dynamic.append(lid_hinge)
	# Locket: en låg låda med en välvd topp (en tillplattad cylinder vars undre halva göms i lådan).
	_box(Vector3(1.52, 0.16, 0.92), Vector3(0, 0.08, 0.45), wood, lid_hinge)
	var dome := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.46
	cyl.bottom_radius = 0.46
	cyl.height = 1.52
	dome.mesh = cyl
	dome.material_override = wood
	dome.rotation.z = PI / 2
	dome.scale = Vector3(0.45, 1, 1)
	dome.position = Vector3(0, 0.12, 0.45)
	lid_hinge.add_child(dome)
	for x in [-0.6, 0.0, 0.6]:
		var band := MeshInstance3D.new()
		var tb := CylinderMesh.new()
		tb.top_radius = 0.475
		tb.bottom_radius = 0.475
		tb.height = 0.1
		band.mesh = tb
		band.material_override = iron
		band.rotation.z = PI / 2
		band.scale = Vector3(0.47, 1, 1)
		band.position = Vector3(x, 0.12, 0.45)
		lid_hinge.add_child(band)
		_box(Vector3(0.1, 0.17, 0.94), Vector3(x, 0.08, 0.45), iron, lid_hinge)
	# Mynthögar runt podiet.
	for i in 5:
		var a := _rng.randf_range(0, TAU)
		var p := Vector3(cos(a) * 1.7, 0, sin(a) * 1.1 - 0.3)
		var heap := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.06
		cone.bottom_radius = _rng.randf_range(0.3, 0.45)
		cone.height = cone.bottom_radius * 0.7
		heap.mesh = cone
		heap.material_override = gold
		heap.position = p + Vector3(0, cone.height / 2.0, 0)
		root.add_child(heap)
		for j in 6:
			var coin := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.07
			c.bottom_radius = 0.07
			c.height = 0.015
			coin.mesh = c
			coin.material_override = gold
			coin.position = p + Vector3(_rng.randf_range(-0.6, 0.6), 0.01, _rng.randf_range(-0.6, 0.6))
			coin.rotation = Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3))
			root.add_child(coin)

	_reveal_light = _light(CENTER + Vector3(0, 1.6, 0.3), Color(1.0, 0.75, 0.3), 0.0, 6.0)
	var sparkle := _particles(Color(1.0, 0.85, 0.4), 40, 1.6, 0.05)
	sparkle.position = CENTER + Vector3(0, 1.1, 0)
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparkle.emission_box_extents = Vector3(0.6, 0.05, 0.3)
	sparkle.direction = Vector3(0, 1, 0)
	sparkle.spread = 25.0
	sparkle.initial_velocity_min = 0.8
	sparkle.initial_velocity_max = 2.2
	sparkle.gravity = Vector3(0, -1.2, 0)
	var glints := _particles(Color(1.0, 0.95, 0.7), 14, 0.6, 0.09)
	glints.position = CENTER + Vector3(0, 0.3, 0)
	glints.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	glints.emission_box_extents = Vector3(1.9, 0.2, 1.3)
	glints.initial_velocity_max = 0.0
	glints.gravity = Vector3.ZERO
	_bursts.append_array([sparkle, glints])
	_reveal_steps.append(func(k: float, _d: float) -> void:
		var open := _ease_out(clampf(k / 0.45, 0.0, 1.0))
		lid_hinge.rotation.x = -deg_to_rad(112.0) * open
		_reveal_light.light_energy = 3.0 * open + 0.4 * sin(_t * 5.0) * open
		gold.emission_energy_multiplier = 0.15 + 1.1 * open)


## Helgedom: altare med ljus och en stenstaty bakom; ett ljusschakt faller och statyn lyser upp.
func _build_shrine() -> void:
	var stone := _stone_material(_pal.stone, 1.0)
	var root := Node3D.new()
	root.position = CENTER
	add_child(root)
	_box(Vector3(3.0, 0.25, 2.4), Vector3(0, 0.12, -0.3), _stone_material(_pal.stone_dark, 1.0), root)
	_box(Vector3(1.8, 0.95, 0.9), Vector3(0, 0.25 + 0.47, 0.3), stone, root)
	_box(Vector3(2.0, 0.12, 1.05), Vector3(0, 1.26, 0.3), stone, root)
	var cloth := _material(Color(0.62, 0.12, 0.1) if style == "chapel" else Color(0.35, 0.25, 0.5))
	_box(Vector3(0.7, 0.02, 1.08), Vector3(0, 1.33, 0.3), cloth, root)
	_box(Vector3(0.66, 0.6, 0.02), Vector3(0, 1.02, 0.84), cloth, root)
	for x in [-0.75, 0.75]:
		_candle(root, Vector3(x, 1.32, 0.45), 0.22)
	# Statyn: Paladinens figur i sten på en sockel, fryst i en pose.
	_box(Vector3(1.0, 0.6, 1.0), Vector3(0, 0.55, -1.0), stone, root)
	var statue_stone := _stone_material(Color(0.62, 0.6, 0.58), 1.0)
	statue_stone.emission_enabled = true
	statue_stone.emission = Color(1.0, 0.8, 0.45)
	statue_stone.emission_energy_multiplier = 0.0
	var statue := _frozen_figure("torvald", "Shield_Idle", 0.4, statue_stone, ["Longsword", "Shield"])
	statue.position = Vector3(0, 0.85, -1.0)
	statue.scale = Vector3.ONE * 1.35
	root.add_child(statue)

	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 1.2
	cyl.height = WALL_H
	cyl.cap_top = false
	cyl.cap_bottom = false
	beam.mesh = cyl
	var beam_mat := _material(Color(1.0, 0.85, 0.5, 0.0), 0.0)
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = beam_mat
	beam.position = Vector3(0, WALL_H / 2, -0.6)
	root.add_child(beam)
	_reveal_light = _light(CENTER + Vector3(0, 3.2, 0.4), Color(1.0, 0.88, 0.6), 0.0, 7.0)
	var motes := _particles(Color(1.0, 0.9, 0.55), 36, 2.2, 0.045)
	motes.position = CENTER + Vector3(0, 0.6, -0.5)
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.0
	motes.direction = Vector3(0, 1, 0)
	motes.initial_velocity_min = 0.3
	motes.initial_velocity_max = 0.9
	motes.gravity = Vector3.ZERO
	motes.one_shot = false
	motes.emitting = false
	_bursts.append(motes)
	_reveal_steps.append(func(k: float, _d: float) -> void:
		var on := _ease_out(clampf(k / 0.6, 0.0, 1.0))
		var pulse := 1.0 + 0.12 * sin(_t * 3.0)
		beam_mat.albedo_color.a = 0.22 * on * pulse
		statue_stone.emission_energy_multiplier = 0.35 * on * pulse
		_reveal_light.light_energy = 3.2 * on * pulse)


## Fånge: en bur med en fjättrad gestalt; låset faller, burdörren glider upp och fången reser sig.
func _build_prisoner() -> void:
	var iron := _material(Color(0.22, 0.21, 0.23), 0.0, 0.6, 0.45)
	var root := Node3D.new()
	root.position = CENTER
	add_child(root)
	var radius := 0.95
	var height := 2.5
	for y in [0.06, height]:
		var disc := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = radius + 0.08
		c.bottom_radius = radius + 0.08
		c.height = 0.12
		disc.mesh = c
		disc.material_override = iron
		disc.position = Vector3(0, y, 0)
		root.add_child(disc)
	var hook := MeshInstance3D.new()
	var hc := CylinderMesh.new()
	hc.top_radius = 0.04
	hc.bottom_radius = 0.04
	hc.height = WALL_H - height
	hook.mesh = hc
	hook.material_override = iron
	hook.position = Vector3(0, height + (WALL_H - height) / 2.0, 0)
	root.add_child(hook)
	var door_bars := Node3D.new()  # burdörren: de fyra främre stängerna
	root.add_child(door_bars)
	_dynamic.append(door_bars)
	for i in 16:
		var a := i * TAU / 16.0
		var bar := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.035
		c.bottom_radius = 0.035
		c.height = height
		bar.mesh = c
		bar.material_override = iron
		bar.position = Vector3(sin(a) * radius, height / 2.0, cos(a) * radius)
		if i <= 1 or i >= 15:
			door_bars.add_child(bar)
		else:
			root.add_child(bar)
	var lock := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.18, 0.22, 0.08)
	lock.mesh = lb
	var lock_mat := _material(Color(0.7, 0.55, 0.25), 0.0, 0.7, 0.3)
	lock.material_override = lock_mat
	lock.position = Vector3(0.0, 1.2, radius + 0.06)
	root.add_child(lock)
	_dynamic.append(lock)
	# Bojor och kedjor på bakväggen bakom buren.
	for x in [-1.6, 1.6]:
		for j in 7:
			var link := MeshInstance3D.new()
			var tr := TorusMesh.new()
			tr.inner_radius = 0.04
			tr.outer_radius = 0.075
			link.mesh = tr
			link.material_override = iron
			link.position = Vector3(CENTER.x + x, 3.4 - j * 0.12, BACK + 0.12)
			link.rotation = Vector3(PI / 2 if j % 2 == 0 else 0, 0, PI / 2)
			add_child(link)
	_box(Vector3(0.6, 0.3, 0.6), Vector3(-0.3, 0.27, -0.3), _material(Color(0.4, 0.33, 0.2)), root)  # halm
	var prisoner := UnitModel.new()
	var u := CombatUnit.from_data("prisoner", {"name": "Fånge", "stats": {"health": 1}}, 0)
	root.add_child(prisoner)
	# sigrun.glb följer inte med i APK:n; fången är Alvas kåpklädda figur i smutsgrått.
	prisoner.setup(u, null, {"model": "alva", "scale": 0.95, "anims_from": ["sigrun_delar"],
			"anims": {"idle": "OneHand_Idle", "hit": "Hit_Chest", "walk": "Walk"},
			"tint": "#7d766e"})
	prisoner.position = Vector3(0, 0.12, -0.1)
	for l in prisoner.find_children("*", "Light3D", true, false):
		l.visible = false
	for mesh in prisoner.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = null
	prisoner.face(prisoner.global_position + Vector3(0.4, 0, -1))
	_box(Vector3(0.5, 0.06, 0.04), Vector3(0, 0.95, 0.1), iron, root)  # bojan mellan händerna

	_reveal_light = _light(CENTER + Vector3(0, 2.8, 1.2), Color(0.85, 0.9, 1.0), 0.0, 5.0)
	var sparks := _particles(Color(1.0, 0.7, 0.3), 18, 0.5, 0.035)
	sparks.position = CENTER + Vector3(0, 1.2, radius + 0.1)
	sparks.direction = Vector3(0, 0.5, 1)
	sparks.spread = 70.0
	sparks.initial_velocity_min = 1.5
	sparks.initial_velocity_max = 3.0
	sparks.gravity = Vector3(0, -9.0, 0)
	var turned := [false, false]
	_reveal_steps.append(func(k: float, _d: float) -> void:
		var drop := clampf((k - 0.1) / 0.25, 0.0, 1.0)
		if drop > 0.0 and not turned[0]:
			turned[0] = true
			sparks.restart()
			sparks.emitting = true
		lock.position = Vector3(0.12 * drop, 1.2 - 1.1 * drop * drop, radius + 0.06 + 0.25 * drop)
		lock.rotation.z = 2.0 * drop
		var open := _ease_out(clampf((k - 0.3) / 0.4, 0.0, 1.0))
		door_bars.rotation.y = 1.5 * open  # dörren glider runt buren
		_reveal_light.light_energy = 2.0 * clampf(k / 0.3, 0.0, 1.0)
		if k > 0.35 and not turned[1]:
			turned[1] = true
			prisoner.face(prisoner.global_position + Vector3(0, 0, 3))
			prisoner.hit(0.6, prisoner.global_position + Vector3(0, 0, -1)))


## Inskrift: en stentavla med runor som tänds rad för rad.
func _build_inscription() -> void:
	var stone := _stone_material(_pal.stone_dark.lerp(_pal.stone, 0.5), 1.0)
	var root := Node3D.new()
	root.position = CENTER
	add_child(root)
	_box(Vector3(2.2, 0.35, 1.2), Vector3(0, 0.17, 0), _stone_material(_pal.stone_dark, 1.0), root)
	var slab := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(1.8, 2.4, 0.35)
	slab.mesh = sb
	slab.material_override = stone
	slab.position = Vector3(0, 0.35 + 1.2, 0)
	slab.rotation.x = -0.08
	root.add_child(slab)
	# Rundad topp.
	var top := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 0.9
	tc.bottom_radius = 0.9
	tc.height = 0.35
	top.mesh = tc
	top.material_override = stone
	top.rotation.x = PI / 2
	top.position = Vector3(0, 1.2, 0)
	slab.add_child(top)
	# Runorna: små ristade streck i ett rutnät, varje runa 2–3 streck.
	var rune_color: Color = Color(0.45, 0.75, 1.0) if style == "crypt" else Color(1.0, 0.78, 0.35)
	var rows := 5
	var cols := 4
	var mats: Array[StandardMaterial3D] = []
	for r in rows:
		var m := _material(rune_color * 0.25, 0.0)
		m.emission_enabled = true
		m.emission = rune_color
		m.emission_energy_multiplier = 0.0
		mats.append(m)
		for c in cols:
			var cell := Vector3(-0.54 + c * 0.36, 0.78 - r * 0.38, 0.18)
			_rune(slab, cell, m)
	_reveal_light = _light(CENTER + Vector3(0, 1.6, 1.0), rune_color, 0.0, 4.5)
	var dust := _particles(rune_color.lerp(Color.WHITE, 0.4), 30, 1.8, 0.03)
	dust.position = CENTER + Vector3(0, 1.5, 0.3)
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(0.8, 1.0, 0.05)
	dust.direction = Vector3(0, 0.3, 1)
	dust.initial_velocity_min = 0.2
	dust.initial_velocity_max = 0.6
	dust.gravity = Vector3(0, 0.15, 0)
	_bursts.append(dust)
	_reveal_steps.append(func(k: float, _d: float) -> void:
		for r in rows:
			var on := clampf((k * 1.4 - r * 0.15) / 0.2, 0.0, 1.0)
			mats[r].emission_energy_multiplier = (2.2 + 0.4 * sin(_t * 4.0 + r)) * on
			mats[r].albedo_color = (rune_color * 0.25).lerp(rune_color, on)
		_reveal_light.light_energy = 2.4 * clampf(k * 1.4, 0.0, 1.0))


## Lägereld: stenring, vedträn och sovfällar; elden flammar upp.
func _build_campfire() -> void:
	var root := Node3D.new()
	root.position = CENTER
	add_child(root)
	var rock := _stone_material(_pal.stone_dark, 1.0)
	for i in 10:
		var a := i * TAU / 10.0
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = _rng.randf_range(0.16, 0.22)
		sm.height = sm.radius * 1.3
		s.mesh = sm
		s.material_override = rock
		s.position = Vector3(cos(a) * 0.7, 0.08, sin(a) * 0.7)
		root.add_child(s)
	var log_mat := _material(Color(0.3, 0.18, 0.1))
	for i in 4:
		var l := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.07
		c.bottom_radius = 0.09
		c.height = 0.95
		l.mesh = c
		l.material_override = log_mat
		var a := i * TAU / 4.0 + 0.4
		l.position = Vector3(cos(a) * 0.18, 0.22, sin(a) * 0.18)
		l.rotation = Vector3(0, -a, 1.1)
		root.add_child(l)
	var embers_mat := _material(Color(1.0, 0.35, 0.08), 2.0)
	_sphere(0.28, Vector3(0, 0.02, 0), embers_mat, root).scale = Vector3(1, 0.25, 1)
	# Sovfällar och en kittel på varsin sida.
	var fur := _material(Color(0.42, 0.3, 0.2))
	for side in [-1, 1]:
		var roll := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.8
		roll.mesh = cap
		roll.material_override = fur
		roll.rotation = Vector3(PI / 2, side * 0.5, 0)
		roll.scale = Vector3(1, 1, 0.3)
		roll.position = Vector3(side * 2.0, 0.1, -0.9)
		root.add_child(roll)
	var pot := _sphere(0.25, Vector3(-0.95, 0.25, -0.5), _material(Color(0.12, 0.12, 0.13), 0.0, 0.6), root)
	pot.scale = Vector3(1, 0.8, 1)

	var flames := CPUParticles3D.new()
	flames.amount = 40
	flames.lifetime = 0.8
	flames.mesh = _particle_quad(0.35)
	flames.material_override = _particle_material()
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = 0.18
	flames.direction = Vector3(0, 1, 0)
	flames.spread = 12.0
	flames.initial_velocity_min = 0.6
	flames.initial_velocity_max = 1.1
	flames.gravity = Vector3(0, 0.8, 0)
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	flames.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
	ramp.add_point(0.4, Color(1.0, 0.45, 0.1, 0.9))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.6, 0.1, 0.05, 0.0))
	flames.color_ramp = ramp
	flames.position = CENTER + Vector3(0, 0.2, 0)
	flames.scale_amount_min = 0.5
	flames.scale_amount_max = 0.8
	add_child(flames)
	var embers := _particles(Color(1.0, 0.55, 0.15), 16, 1.6, 0.03)
	embers.one_shot = false
	embers.position = CENTER + Vector3(0, 0.5, 0)
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 30.0
	embers.initial_velocity_min = 0.6
	embers.initial_velocity_max = 1.6
	embers.gravity = Vector3(0.3, 0.4, 0)
	embers.emitting = true
	var fire_light := _light(CENTER + Vector3(0, 0.9, 0), Color(1.0, 0.55, 0.2), 1.0, 7.0)
	_reveal_light = fire_light
	_reveal_steps.append(func(k: float, _d: float) -> void:
		var flare := clampf(k / 0.25, 0.0, 1.0) * (1.0 - 0.5 * clampf((k - 0.3) / 0.7, 0.0, 1.0))
		var lvl := 0.5 + flare
		flames.scale_amount_min = 0.5 + 0.9 * flare
		flames.scale_amount_max = 0.8 + 1.2 * flare
		flames.initial_velocity_max = 1.1 + 1.5 * flare
		fire_light.light_energy = (1.2 + 3.0 * lvl) * (1.0 + 0.15 * sin(_t * 13.0) + 0.08 * sin(_t * 29.0)))


## Portal: en stenring där en virvel till Nether öppnar sig.
func _build_portal() -> void:
	var root := Node3D.new()
	root.position = CENTER
	add_child(root)
	var stone := _stone_material(_pal.stone_dark, 1.0)
	_box(Vector3(3.4, 0.3, 1.4), Vector3(0, 0.15, 0), stone, root)
	var ring := MeshInstance3D.new()
	var tr := TorusMesh.new()
	tr.inner_radius = 1.35
	tr.outer_radius = 1.7
	tr.rings = 48
	ring.mesh = tr
	ring.material_override = stone
	ring.rotation.x = PI / 2
	ring.position = Vector3(0, 1.85, 0)
	root.add_child(ring)
	var rune_mat := _material(Color(0.6, 0.3, 1.0) * 0.3, 0.0)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.7, 0.35, 1.0)
	for i in 10:
		var a := i * TAU / 10.0
		var r := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.14, 0.14, 0.05)
		r.mesh = b
		r.material_override = rune_mat
		r.position = Vector3(cos(a) * 1.52, 1.85 + sin(a) * 1.52, 0.2)
		r.rotation.z = a
		root.add_child(r)
	var swirl := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.8, 2.8)
	swirl.mesh = q
	var sh := ShaderMaterial.new()
	sh.shader = _swirl_shader()
	sh.set_shader_parameter("open", 0.0)
	swirl.material_override = sh
	swirl.position = Vector3(0, 1.85, 0.0)
	root.add_child(swirl)
	_dynamic.append(swirl)
	_reveal_light = _light(CENTER + Vector3(0, 1.8, 1.0), Color(0.65, 0.3, 1.0), 0.0, 7.0)
	var pull := _particles(Color(0.8, 0.5, 1.0), 48, 1.2, 0.05)
	pull.one_shot = false
	pull.emitting = false
	pull.position = CENTER + Vector3(0, 1.85, 0.1)
	pull.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	pull.emission_ring_axis = Vector3(0, 0, 1)
	pull.emission_ring_radius = 2.2
	pull.emission_ring_inner_radius = 1.8
	pull.emission_ring_height = 0.1
	pull.initial_velocity_max = 0.0
	pull.radial_accel_min = -3.5
	pull.radial_accel_max = -2.5
	pull.tangential_accel_min = 2.0
	pull.tangential_accel_max = 3.0
	pull.gravity = Vector3.ZERO
	_bursts.append(pull)
	_reveal_steps.append(func(k: float, _d: float) -> void:
		var open := _ease_out(clampf(k / 0.7, 0.0, 1.0))
		sh.set_shader_parameter("open", open)
		swirl.scale = Vector3.ONE * (0.15 + 0.85 * open)
		rune_mat.emission_energy_multiplier = 2.0 * open
		_reveal_light.light_energy = (2.6 + 0.6 * sin(_t * 6.0)) * open)


# --- Byggstenar ----------------------------------------------------------------

## Slår ihop alla stillastående delar med samma material till ett mesh: rummet består av hundratals
## små lådor och klot, och varje del är annars ett eget ritanrop (dyrt på telefonen).
## Delar som rör sig (_dynamic) och figurerna (skelett) lämnas orörda.
func _merge_static() -> void:
	var groups := {}
	var inv := global_transform.affine_inverse()
	for node in find_children("*", "MeshInstance3D", true, false):
		var m := node as MeshInstance3D
		if m.material_override == null or m.mesh is ArrayMesh or _is_dynamic(m):
			continue
		var key := [m.material_override, m.cast_shadow]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(m)
	for key in groups:
		var list: Array = groups[key]
		if list.size() < 2:
			continue
		var st := SurfaceTool.new()
		for m in list:
			st.append_from(m.mesh, 0, inv * m.global_transform)
		var merged := MeshInstance3D.new()
		merged.mesh = st.commit()
		merged.material_override = key[0]
		merged.cast_shadow = key[1]
		add_child(merged)
		for m in list:
			m.get_parent().remove_child(m)
			m.free()


func _is_dynamic(n: Node) -> bool:
	while n != self and n != null:
		if n in _dynamic or n is Skeleton3D or n is UnitModel:
			return true
		n = n.get_parent()
	return false


var _shared_mats := {}

## Ett material som delas mellan alla anrop med samma värden, så att delarna kan slås ihop.
## Bara för material som aldrig ändras efteråt.
func _shared(c: Color, emit := 0.0, metallic := 0.0) -> StandardMaterial3D:
	var key := [c, emit, metallic]
	if not _shared_mats.has(key):
		_shared_mats[key] = _material(c, emit, metallic)
	return _shared_mats[key]

func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	m.position = pos
	(parent if parent else self).add_child(m)
	return m


func _sphere(r: float, pos: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	m.mesh = s
	m.material_override = mat
	m.position = pos
	(parent if parent else self).add_child(m)
	return m


func _light(pos: Vector3, c: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	add_child(l)
	return l


## En fackla på väggen. Lågan lyser själv; ljuset läggs ut separat så att flera facklor kan dela
## på ett (GL Compatibility klarar bara ett fåtal ljus per objekt).
func _torch(pos: Vector3, lit := true, out := Vector3.ZERO, energy := 1.5) -> void:
	var holder := _shared(Color(0.15, 0.13, 0.12))
	_box(Vector3(0.12, 0.45, 0.12), pos - Vector3(0, 0.3, 0), holder)
	var flame := _sphere(0.11, pos, _shared(Color(1.0, 0.7, 0.3), 3.0))
	flame.scale = Vector3(1, 1.6, 1)
	if lit:
		_flicker.append([_light(pos + out * 0.5, _pal.torch, energy, 6.0), energy])


func _candle(parent: Node3D, pos: Vector3, h: float) -> void:
	var wax := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.045
	c.bottom_radius = 0.05
	c.height = h
	wax.mesh = c
	wax.material_override = _shared(Color(0.92, 0.88, 0.78))
	wax.position = pos + Vector3(0, h / 2.0, 0)
	parent.add_child(wax)
	var flame := _sphere(0.035, pos + Vector3(0, h + 0.05, 0), _shared(Color(1.0, 0.75, 0.35), 3.0), parent)
	flame.scale = Vector3(1, 1.8, 1)


func _candelabra(pos: Vector3) -> void:
	var iron := _shared(Color(0.2, 0.17, 0.14), 0.0, 0.5)
	_box(Vector3(0.08, 1.5, 0.08), pos + Vector3(0, 0.75, 0), iron)
	_box(Vector3(0.6, 0.06, 0.08), pos + Vector3(0, 1.5, 0), iron)
	var holder := Node3D.new()
	add_child(holder)
	for x in [-0.27, 0.0, 0.27]:
		_candle(holder, pos + Vector3(x, 1.53, 0), 0.18)


func _window(pos: Vector3, rot_y: float, c: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	var frame := _shared(_pal.stone_dark)
	_box(Vector3(1.3, 2.3, 0.1), Vector3(0, 0, 0.02), frame, root)
	var colors := [c, c.lerp(Color(0.2, 0.4, 1.0), 0.5), c.lerp(Color(1.0, 0.85, 0.3), 0.5)]
	for i in 6:
		var pane := _shared(colors[i % 3], 1.3)
		_box(Vector3(0.48, 0.62, 0.02), Vector3(-0.27 + (i % 2) * 0.54, -0.72 + (i / 2) * 0.68, 0.08), pane, root)
	var arch := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.65
	cyl.bottom_radius = 0.65
	cyl.height = 0.1
	arch.mesh = cyl
	arch.material_override = frame
	arch.rotation.x = PI / 2
	arch.position = Vector3(0, 1.15, 0.02)
	root.add_child(arch)
	var rose := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.45
	rc.bottom_radius = 0.45
	rc.height = 0.02
	rose.mesh = rc
	rose.material_override = _material(c.lerp(Color.WHITE, 0.2), 1.6)
	rose.rotation.x = PI / 2
	rose.position = Vector3(0, 1.15, 0.08)
	root.add_child(rose)


func _rune(parent: Node3D, cell: Vector3, mat: Material) -> void:
	# En stav och ett eller två snedstreck, som i den äldre futharken.
	var stave := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.035, 0.26, 0.02)
	stave.mesh = b
	stave.material_override = mat
	stave.position = cell + Vector3(_rng.randf_range(-0.05, 0.05), 0, 0)
	parent.add_child(stave)
	for i in _rng.randi_range(1, 2):
		var arm := MeshInstance3D.new()
		var ab := BoxMesh.new()
		ab.size = Vector3(0.03, 0.15, 0.02)
		arm.mesh = ab
		arm.material_override = mat
		var up := _rng.randf_range(-0.06, 0.08)
		var dir := 1.0 if _rng.randf() < 0.6 else -1.0
		arm.position = stave.position + Vector3(dir * 0.05, up, 0)
		arm.rotation.z = dir * (0.7 if _rng.randf() < 0.5 else -0.7)
		parent.add_child(arm)


## En figur ur assets/models/ som står still i en pose, med ett eget material på allt.
func _frozen_figure(model: String, anim: String, at: float, mat: Material, weapons: Array) -> Node3D:
	var fig: Node3D = load("res://assets/models/%s.glb" % model).instantiate()
	var players := fig.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var p := players[0] as AnimationPlayer
		p.play(anim)
		p.seek(at, true)
		p.pause()
	var kit: Node3D = load("res://assets/models/vapen.glb").instantiate()
	for grip_weapon in [["grip_r", weapons[0] if weapons.size() > 0 else ""], ["grip_l", weapons[1] if weapons.size() > 1 else ""]]:
		var grip := fig.find_child(grip_weapon[0], true, false)
		var w := kit.find_child(grip_weapon[1], true, false) if grip_weapon[1] != "" else null
		if grip and w:
			grip.add_child(w.duplicate())
	kit.free()
	for m in fig.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
	return fig


func _particles(c: Color, amount: int, lifetime: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 0.6
	p.emitting = false
	p.mesh = _particle_quad(size * 2.0)
	p.material_override = _particle_material()
	p.color = c
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	add_child(p)
	return p


func _particle_quad(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	return q


func _particle_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	return m


static var _dot: GradientTexture2D

static func _soft_dot() -> GradientTexture2D:
	if _dot:
		return _dot
	_dot = GradientTexture2D.new()
	_dot.fill = GradientTexture2D.FILL_RADIAL
	_dot.fill_from = Vector2(0.5, 0.5)
	_dot.fill_to = Vector2(1.0, 0.5)
	_dot.width = 32
	_dot.height = 32
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	_dot.gradient = g
	return _dot


static var _swirl: Shader

static func _swirl_shader() -> Shader:
	if _swirl:
		return _swirl
	_swirl = Shader.new()
	_swirl.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform float open = 1.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float arms = sin(a * 4.0 + r * 11.0 - TIME * 5.0) * 0.5 + 0.5;
	float fine = sin(a * 9.0 - r * 20.0 + TIME * 3.0) * 0.5 + 0.5;
	vec3 deep = vec3(0.05, 0.0, 0.12);
	vec3 violet = vec3(0.7, 0.25, 1.0);
	vec3 green = vec3(0.3, 1.0, 0.6);
	vec3 col = mix(deep, mix(violet, green, fine * 0.35), arms * smoothstep(0.05, 0.7, r));
	col += violet * 1.6 * smoothstep(0.75, 0.97, r) * (1.0 - smoothstep(0.97, 1.0, r));
	ALBEDO = col * 1.1;
	ALPHA = (1.0 - smoothstep(0.92, 1.0, r)) * open;
}
"""
	return _swirl


func _stone_material(c: Color, uv_scale: float) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.6, 0.58, 0.57))
	ramp.set_color(1, Color(1.0, 0.98, 0.95))
	tex.color_ramp = ramp
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = tex
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.uv1_triplanar = true
	m.roughness = 0.95
	return m


func _material(c: Color, emit := 0.0, metallic := 0.0, roughness := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = roughness
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


static func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)
