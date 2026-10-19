class_name CastleWorld
extends Node3D
## Borgen i 3D (0.23, Siralims slott): en borggård snett ovanifrån med stationerna runt om, byggd i kod av enkla
## former som kryptan. Hela borgen syns på en skärm. Paladinen går dit man trycker (ungefär en sekund).

const CAMERA_POS := Vector3(0.0, 10.2, 8.6)
const CAMERA_LOOK := Vector3(0.0, 0.0, -0.4)
## Stationernas platser på borggården: där paladinen ställer sig, och var namnet ritas.
const STATIONS := {
	"gate": Vector3(0.0, 0, -4.6),
	"altar": Vector3(-4.6, 0, -3.2),
	"library": Vector3(4.6, 0, -3.2),
	"practice": Vector3(-5.6, 0, 0.6),
	"inn": Vector3(5.6, 0, 0.6),
	"smith": Vector3(-3.4, 0, 3.6),
	"macros": Vector3(3.4, 0, 3.6),
}
## Var paladinen står när hen kommer fram (lite framför stationen).
const STAND_OFFSET := 1.1
const HOME := Vector3(0.0, 0, 1.2)

var camera: Camera3D
var _t := 0.0
var _fires: Array[OmniLight3D] = []
var _glows := {}


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_walls()
	_build_stations()
	camera = Camera3D.new()
	camera.fov = 44.0
	add_child(camera)
	camera.position = CAMERA_POS
	camera.look_at(CAMERA_LOOK)


func _process(delta: float) -> void:
	_t += delta
	for i in _fires.size():
		_fires[i].light_energy = 1.6 + 0.3 * sin(_t * 9.0 + i * 1.7)
	for id in _glows:
		var m: MeshInstance3D = _glows[id]
		if m.visible:
			var mat: StandardMaterial3D = m.material_override
			mat.albedo_color.a = 0.25 + 0.2 * sin(_t * 3.0)


func project(p: Vector3) -> Vector2:
	return camera.unproject_position(p)


## Där paladinen ska stå vid stationen.
func stand_at(station: String) -> Vector3:
	var p: Vector3 = STATIONS.get(station, HOME)
	return p + (HOME - p).normalized() * STAND_OFFSET


## Sätter på eller av glöden kring en station (aktuellt uppdrag eller något nytt).
func set_glow(station: String, on: bool) -> void:
	if _glows.has(station):
		_glows[station].visible = on


# --- Bygget ---------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.68, 0.72)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)


func _mat(c: Color, emissive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emissive:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.5
	return m


func _box(size: Vector3, pos: Vector3, c: Color, rot_y := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = _mat(c)
	m.position = pos
	m.rotation.y = rot_y
	add_child(m)
	return m


func _cyl(r: float, h: float, pos: Vector3, c: Color, top := -1.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.bottom_radius = r
	cy.top_radius = r if top < 0.0 else top
	cy.height = h
	m.mesh = cy
	m.material_override = _mat(c)
	m.position = pos
	add_child(m)
	return m


func _fire(pos: Vector3, c := Color(1.0, 0.6, 0.25)) -> void:
	var l := OmniLight3D.new()
	l.light_color = c
	l.omni_range = 3.5
	l.position = pos
	add_child(l)
	_fires.append(l)
	var flame := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.3
	flame.mesh = s
	flame.material_override = _mat(c, true)
	flame.position = pos
	add_child(flame)


func _build_ground() -> void:
	_box(Vector3(16, 0.2, 12), Vector3(0, -0.1, 0), Color(0.38, 0.35, 0.31))
	# Gångar av ljusare sten mellan stationerna.
	_box(Vector3(1.6, 0.02, 9.0), Vector3(0, 0.01, -0.2), Color(0.5, 0.46, 0.4))
	_box(Vector3(12.0, 0.02, 1.4), Vector3(0, 0.01, 1.2), Color(0.5, 0.46, 0.4))
	# Gräsplättar.
	for p in [Vector3(-2.2, 0.02, -1.8), Vector3(2.2, 0.02, -1.8)]:
		_box(Vector3(2.4, 0.02, 1.8), p, Color(0.28, 0.4, 0.24))


func _build_walls() -> void:
	var stone := Color(0.46, 0.44, 0.41)
	_box(Vector3(16, 2.2, 0.6), Vector3(0, 1.1, -6.2), stone)
	_box(Vector3(0.6, 2.2, 12), Vector3(-8.0, 1.1, 0), stone)
	_box(Vector3(0.6, 2.2, 12), Vector3(8.0, 1.1, 0), stone)
	for x in [-8.0, 8.0]:
		for z in [-6.2, 5.8]:
			_cyl(0.9, 3.4, Vector3(x, 1.7, z), stone.darkened(0.08))
			_cyl(1.0, 0.6, Vector3(x, 3.6, z), Color(0.55, 0.22, 0.18), 0.05)
	# Kreneleringar längs bakmuren.
	for i in 15:
		_box(Vector3(0.45, 0.4, 0.6), Vector3(-7.0 + i, 2.4, -6.2), stone)


func _glow_ring(station: String) -> void:
	var m := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 1.05
	t.outer_radius = 1.35
	m.mesh = t
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.82, 0.35, 0.35)
	m.material_override = mat
	m.position = STATIONS[station] + Vector3(0, 0.05, 0)
	m.visible = false
	add_child(m)
	_glows[station] = m


func _build_stations() -> void:
	for id in STATIONS:
		_glow_ring(id)
	var wood := Color(0.42, 0.28, 0.17)
	var stone := Color(0.52, 0.5, 0.46)
	# Porten: två pelare och en båge, med mörk öppning mot kryptan.
	var g: Vector3 = STATIONS.gate + Vector3(0, 0, -1.4)
	_box(Vector3(0.7, 3.0, 0.8), g + Vector3(-1.3, 1.5, 0), stone)
	_box(Vector3(0.7, 3.0, 0.8), g + Vector3(1.3, 1.5, 0), stone)
	_box(Vector3(3.3, 0.7, 0.9), g + Vector3(0, 3.2, 0), stone)
	_box(Vector3(1.9, 2.6, 0.2), g + Vector3(0, 1.3, -0.3), Color(0.08, 0.07, 0.1))
	_fire(g + Vector3(-1.3, 2.4, 0.6))
	_fire(g + Vector3(1.3, 2.4, 0.6))
	# Kallets altare: en upphöjd sten och ett gyllene ljus.
	var a: Vector3 = STATIONS.altar + Vector3(-0.4, 0, -0.6)
	_cyl(1.0, 0.3, a + Vector3(0, 0.15, 0), stone)
	_box(Vector3(1.2, 0.9, 0.7), a + Vector3(0, 0.75, 0), Color(0.82, 0.8, 0.74))
	_fire(a + Vector3(0, 1.45, 0), Color(1.0, 0.85, 0.45))
	# Biblioteket: ett torn med tak.
	var lb: Vector3 = STATIONS.library + Vector3(0.6, 0, -0.8)
	_cyl(1.0, 3.6, lb + Vector3(0, 1.8, 0), stone)
	_cyl(1.2, 1.2, lb + Vector3(0, 4.2, 0), Color(0.24, 0.3, 0.5), 0.05)
	_box(Vector3(0.7, 1.2, 0.1), lb + Vector3(0, 0.6, 1.0), wood)
	# Övningsgården: halmdockor på pålar.
	var pr: Vector3 = STATIONS.practice + Vector3(-1.0, 0, 0)
	for dz in [-0.9, 0.0, 0.9]:
		_cyl(0.08, 1.4, pr + Vector3(0, 0.7, dz), wood)
		_cyl(0.28, 0.7, pr + Vector3(0, 1.3, dz), Color(0.82, 0.7, 0.4))
	# Värdshuset: ett hus med sadeltak och varmt ljus i fönstret.
	var inn: Vector3 = STATIONS.inn + Vector3(1.1, 0, 0)
	_box(Vector3(1.8, 1.8, 2.6), inn + Vector3(0, 0.9, 0), Color(0.78, 0.7, 0.58))
	var roof := _box(Vector3(1.4, 1.4, 2.8), inn + Vector3(0, 2.0, 0), Color(0.55, 0.22, 0.18))
	roof.rotation.z = deg_to_rad(45)
	roof.scale = Vector3(1.0, 1.0, 1.0)
	_box(Vector3(0.1, 0.5, 0.6), inn + Vector3(-0.92, 1.1, 0), Color(1.0, 0.8, 0.4))
	_fire(inn + Vector3(-1.2, 1.1, 0), Color(1.0, 0.75, 0.4))
	# Smedjan: ässja med glöd och ett städ.
	var sm: Vector3 = STATIONS.smith + Vector3(-0.8, 0, 0.6)
	_box(Vector3(1.2, 1.0, 1.0), sm + Vector3(0, 0.5, 0), Color(0.35, 0.33, 0.32))
	_box(Vector3(0.8, 0.15, 0.6), sm + Vector3(0, 1.05, 0), Color(1.0, 0.45, 0.15)).material_override = _mat(Color(1.0, 0.45, 0.15), true)
	_fire(sm + Vector3(0, 1.4, 0), Color(1.0, 0.45, 0.15))
	_box(Vector3(0.7, 0.4, 0.3), sm + Vector3(1.2, 0.5, -0.2), Color(0.25, 0.25, 0.28))
	# Makron: ett krigsbord med kartor.
	var mc: Vector3 = STATIONS.macros + Vector3(0.8, 0, 0.6)
	_box(Vector3(1.6, 0.12, 1.0), mc + Vector3(0, 0.8, 0), wood)
	for dx in [-0.7, 0.7]:
		for dz in [-0.4, 0.4]:
			_box(Vector3(0.1, 0.8, 0.1), mc + Vector3(dx, 0.4, dz), wood)
	_box(Vector3(1.2, 0.02, 0.7), mc + Vector3(0, 0.87, 0), Color(0.88, 0.8, 0.6))
