extends Node3D
## Animationslabb: visar en figur på nära håll och spelar en sekvens av rörelser via UnitModel,
## precis som i striden. Filma med --write-movie för att granska bild för bild.
##
##   godot --path . res://tools/anim_lab.tscn --write-movie /tmp/lab/f.png --fixed-fps 20 \
##       --quit-after 80 -- --unit=alva --seq=cast:holy:2.5,release,idle:0.5,hit
##
## Steg i --seq (kommaseparerade, valfri längd i sekunder efter kolon):
##   cast:<skola>:<s>  ladda en besvärjelse så länge, sedan släpp
##   ability:<förmåga>[:s]  förmågans egen rörelse (t.ex. ability:moss_throw, trollets kast)
##   attack[:s]  hit[:s]  block:<s>  kick[:s]  idle:<s>  walk:<s>  die[:s]  revive[:s]
##
## Nya modeller utan data: --models=gast,haxa (spelar Idle och Sword_Attack, se MODEL_PREVIEW).
## Uppställning: --units=heroes, --units=enemies, --units=all eller --units=paladin,brokk,…
## visar flera figurer i rad (alla gör samma sekvens). --shot=<fil.png> sparar en bild efter
## --frames=<n> bildrutor och avslutar.

## Vilo- och attackrörelser (och vapen) för --models, när filen inte har Idle (Idle_Loop).
const MODEL_PREVIEW := {
	"biskop": {"anims": {"idle": "Sword_Idle"}},
	"fallen_riddare": {"anims": {"idle": "Shield_Idle", "attack": ["Shield_Attack"]}},
	"falkenerare": {"weapons": {"grip_r": "Shortsword"}, "anims": {"idle": "Sword_Idle"}},
	"bard": {"anims": {"idle": "OneHand_Idle", "attack": ["OneHand_Attack"], "run": "Run"}},
	"munk": {"anims": {"idle": "OneHand_Idle", "attack": ["OneHand_Attack", "OneHand_Attack_B"], "run": "Run"}},
	"druid": {"weapons": {"grip_r": "Staff"}, "anims": {"idle": "Staff_Idle", "attack": ["Spell_Simple_Shoot"],
			"cast": "Staff_Cast", "walk": "Staff_Walk", "run": "Staff_Run"}},
	"brokk": {"anims": {"idle": "Shield_Idle", "attack": ["Shield_Attack"], "run": "Run"}},
	"imma": {"weapons": {"grip_l": "Shortbow"}, "anims": {"idle": "Bow_Idle", "attack": ["Bow_Shoot"], "run": "Run"}},
	"domare": {"weapons": {"grip_r": "Mace"}, "anims": {"idle": "OneHand_Idle", "attack": ["OneHand_Attack"], "run": "Run"}},
	"svardsdansare": {"weapons": {"grip_r": "Shortsword", "grip_l_hand": "Shortsword"},
			"anims": {"idle": "OneHand_Idle", "attack": ["OneHand_Attack", "OneHand_Attack_B"], "run": "Run"}},
}


var _model: UnitModel
var _models: Array[UnitModel] = []
var _shot := ""
var _shot_frames := 30
var _steps: Array = []
var _wait := 0.3


func _ready() -> void:
	var data := GameData.load_all()
	var unit_ids: Array = ["alva"]
	var seq := "idle:1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--unit="):
			unit_ids = [arg.get_slice("=", 1)]
		elif arg.begins_with("--units="):
			var list := arg.get_slice("=", 1)
			match list:
				"heroes": unit_ids = data.heroes.keys()
				"enemies": unit_ids = data.enemies.keys()
				"all": unit_ids = data.heroes.keys() + data.enemies.keys()
				_: unit_ids = Array(list.split(","))
		elif arg.begins_with("--models="):
			unit_ids = []
			for model_name in arg.get_slice("=", 1).split(","):
				var id := "model:" + model_name
				var base: Dictionary = data.enemies.values()[0].duplicate()
				base.name = model_name
				# Godot tar bort ändelsen _Loop vid import: Idle_Loop heter Idle, Walk_Loop Walk.
				var preview: Dictionary = MODEL_PREVIEW.get(model_name, {})
				var anims := {"idle": "Idle", "attack": ["Sword_Attack"], "cast": "Spell_Simple_Shoot",
						"hit": "Hit_Chest", "death": "Death01", "walk": "Walk"}
				anims.merge(preview.get("anims", {}), true)
				base.visual = {"model": model_name, "anims": anims, "weapons": preview.get("weapons", {})}
				data.enemies[id] = base
				unit_ids.append(id)
		elif arg.begins_with("--seq="):
			seq = arg.get_slice("=", 1)
		elif arg.begins_with("--shot="):
			_shot = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_shot_frames = int(arg.get_slice("=", 1))
	_steps = Array(seq.split(","))

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
	plane.size = Vector2(40, 12)
	floor_mesh.mesh = plane
	add_child(floor_mesh)

	var x := 0.0
	var tallest := 1.0
	for unit_id in unit_ids:
		var is_hero: bool = data.heroes.has(unit_id)
		var d: Dictionary = data.heroes[unit_id] if is_hero else data.enemies[unit_id]
		var u := CombatUnit.from_data(unit_id, d, 0 if is_hero else 1)
		var m := UnitModel.new()
		add_child(m)
		var width: float = 1.3 * d.visual.get("scale", 1.0)
		x += width / 2.0
		u.position = Vector2(x, 0) / UnitModel.WORLD_SCALE
		m.setup(u, null, d.visual)
		m.face(m.position + Vector3(0.6 if unit_ids.size() == 1 else 0.0, 0, 1.0))
		x += width / 2.0
		tallest = maxf(tallest, m.model_scale)
		if unit_ids.size() > 1:
			var label := Label3D.new()
			label.text = d.get("name", unit_id)
			label.pixel_size = 0.004
			label.position = m.position + Vector3(0, 2.05 * m.model_scale + 0.1, 0)
			add_child(label)
		_models.append(m)
	_model = _models[0]
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 35.0
	if _models.size() == 1:
		var s := _model.model_scale
		cam.position = Vector3(2.7, 1.3, 3.9) * s
		cam.look_at(Vector3(0, 0.95 * s, 0))
	else:
		var mid := Vector3(x / 2.0, 0.95 * tallest, 0)
		cam.position = mid + Vector3(0, 0.5, maxf(x * 1.05, 2.6 * tallest + 1.5))
		cam.look_at(mid)


func _process(delta: float) -> void:
	if _shot != "":
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png(_shot)
			get_tree().quit()
	_wait -= delta
	if _wait > 0.0 or _steps.is_empty():
		return
	var parts: PackedStringArray = String(_steps.pop_front()).split(":")
	var arg := func(i: int, fallback: float) -> float: return float(parts[i]) if parts.size() > i else fallback
	var step := parts[0]
	for m in _models:
		var front := m.global_position + Vector3(1, 0, 1)
		match step:
			"cast": m.start_cast(parts[1] if parts.size() > 1 else "holy", false)
			"release": m.end_cast(true)
			"attack": m.attack(front)
			"ability":  # ability:<förmåga>: förmågans egen rörelse, och stenen i händerna om den kastar en
				var ab: Dictionary = GameData.load_all().abilities[parts[1]]
				m.attack(front, 0.15, ab.get("anim", ""), ab.get("release_at", UnitModel.IMPACT_AT))
				if ab.has("held"):
					m.hold_until(ab.held, ab.get("hide_while", []), maxf(m.last_impact_delay, 0.15))
			"kick": m.kick(front)
			"hit": m.hit(2.0, front)
			"block": m.set_blocking(true)
			"unblock": m.set_blocking(false)
			"die": m.die()
			"revive": m.revive()
			"walk": m.move_to(m.position + Vector3(-1.5, 0, 0), arg.call(1, 1.2), false)
	match step:
		"cast":
			_wait = arg.call(2, 2.0)
			_steps.push_front("release")
		"release":
			_wait = 1.0
		"attack", "kick":
			_wait = arg.call(1, 1.2)
		"ability":
			_wait = arg.call(2, 1.6)
		"hit":
			_wait = arg.call(1, 1.0)
		"block":
			_wait = arg.call(1, 2.0)
			_steps.push_front("unblock")
		"unblock":
			_wait = 0.6
		"walk":
			_wait = arg.call(1, 1.2) + 0.3
		_:
			_wait = arg.call(1, 1.0)
