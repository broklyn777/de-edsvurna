extends Node3D
## Visar samma figur flera gånger med olika benvridningar, för att se benens axlar.
##   godot --path . res://tools/pose_test.tscn -- --model=liria --base=OneHand_Idle --out=/tmp/p.png
##       --tests="UpperLeg.R:60,0,0;UpperLeg.R:0,60,0"
var _frames := 0
var _out := "/tmp/pose.png"
var _turn := 35.0

func _ready() -> void:
	var model := "liria"
	var base := "Idle"
	var tests := "none"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="): model = arg.get_slice("=", 1)
		elif arg.begins_with("--base="): base = arg.get_slice("=", 1)
		elif arg.begins_with("--out="): _out = arg.get_slice("=", 1)
		elif arg.begins_with("--tests="): tests = arg.get_slice("=", 1)
		elif arg.begins_with("--turn="): _turn = float(arg.get_slice("=", 1))
	var list := tests.split(";")
	for i in list.size():
		var bones := {}
		var pos := {}
		for part in list[i].split("|"):
			if part.contains(":"):
				var b := part.get_slice(":", 0)
				var v := part.get_slice(":", 1).split(",")
				if b.begins_with("@"):
					pos[b.substr(1)] = [float(v[0]), float(v[1]), float(v[2])]
				else:
					bones[b] = [float(v[0]), float(v[1]), float(v[2])]
		var n: Node3D = load("res://assets/models/%s.glb" % model).instantiate()
		n.position = Vector3((i - (list.size() - 1) / 2.0) * 1.3, 0, 0)
		n.rotation_degrees.y = _turn
		add_child(n)
		var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
		var def := {"base": base, "length": 1.0, "keys": [{"t": 0.0, "bones": bones, "pos": pos}, {"t": 1.0, "bones": bones, "pos": pos}]}
		ProceduralAnims.add_to(ap, ["T%d" % i], {"T%d" % i: def})
		ap.play("T%d" % i)
		var l := Label3D.new()
		l.text = list[i].replace("|", "\n")
		l.font_size = 22
		l.position = n.position + Vector3(0, -0.25, 0.5)
		add_child(l)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.1, 1.05 * list.size() + 1.2)
	cam.fov = 40
	cam.look_at(Vector3(0, 0.8, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.25, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	add_child(env)

func _process(_d: float) -> void:
	_frames += 1
	if _frames == 10:
		get_viewport().get_texture().get_image().save_png(_out)
		get_tree().quit()
