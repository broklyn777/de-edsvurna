extends Node3D
## Animationslabb: visar en figur på nära håll och spelar en sekvens av rörelser via UnitModel,
## precis som i striden. Filma med --write-movie för att granska bild för bild.
##
##   godot --path . res://tools/anim_lab.tscn --write-movie /tmp/lab/f.png --fixed-fps 20 \
##       --quit-after 80 -- --unit=alva --seq=cast:holy:2.5,release,idle:0.5,hit
##
## Steg i --seq (kommaseparerade, valfri längd i sekunder efter kolon):
##   cast:<skola>:<s>  ladda en besvärjelse så länge, sedan släpp
##   attack[:s]  hit[:s]  block:<s>  kick[:s]  idle:<s>  walk:<s>

var _model: UnitModel
var _steps: Array = []
var _wait := 0.3


func _ready() -> void:
	var data := GameData.load_all()
	var unit_id := "alva"
	var seq := "idle:1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--unit="):
			unit_id = arg.get_slice("=", 1)
		elif arg.begins_with("--seq="):
			seq = arg.get_slice("=", 1)
	_steps = Array(seq.split(","))
	var is_hero: bool = data.heroes.has(unit_id)
	var d: Dictionary = data.heroes[unit_id] if is_hero else data.enemies[unit_id]
	var u := CombatUnit.from_data(unit_id, d, 0 if is_hero else 1)
	u.position = Vector2.ZERO

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.15, 0.2)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.8)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mesh.mesh = plane
	add_child(floor_mesh)

	_model = UnitModel.new()
	add_child(_model)
	_model.setup(u, null, d.visual)
	_model.face(Vector3(1.0, 0, 1.0))
	var cam := Camera3D.new()
	var s := _model.model_scale
	add_child(cam)
	cam.fov = 35.0
	cam.position = Vector3(2.7, 1.3, 3.9) * s
	cam.look_at(Vector3(0, 0.95 * s, 0))


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0 or _steps.is_empty():
		return
	var parts: PackedStringArray = String(_steps.pop_front()).split(":")
	var arg := func(i: int, fallback: float) -> float: return float(parts[i]) if parts.size() > i else fallback
	var front := _model.global_position + Vector3(1, 0, 1)
	match parts[0]:
		"cast":
			_model.start_cast(parts[1] if parts.size() > 1 else "holy", false)
			_wait = arg.call(2, 2.0)
			_steps.push_front("release")
		"release":
			_model.end_cast(true)
			_wait = 1.0
		"attack":
			_model.attack(front)
			_wait = arg.call(1, 1.2)
		"kick":
			_model.kick(front)
			_wait = arg.call(1, 1.2)
		"hit":
			_model.hit(2.0, front)
			_wait = arg.call(1, 1.0)
		"block":
			_model.set_blocking(true)
			_wait = arg.call(1, 2.0)
			_steps.push_front("unblock")
		"unblock":
			_model.set_blocking(false)
			_wait = 0.6
		"walk":
			_model.move_to(_model.position + Vector3(-1.5, 0, 0), arg.call(1, 1.2), false)
			_wait = arg.call(1, 1.2) + 0.3
		_:
			_wait = arg.call(1, 1.0)
