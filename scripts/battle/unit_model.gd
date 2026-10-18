class_name UnitModel
extends Node3D
## En hjälte eller bossen i 3D: modell, vapen i händerna och animationer som följer striden.
## Rörelserna styrs av battle.gd utifrån simulatorns händelser (attack, kast, träff, död …).

const WORLD_SCALE := 1.0 / 55.0
const BLEND := 0.12
## Andel av upptaktsanimationen där bossen stannar med vapnet höjt tills slaget faller
## (före den snabbaste delen av svingen).
const WINDUP_HOLD := 0.09
## Vapnet träffar ungefär så här långt in i attackanimationerna (uppmätt på armarnas rotationsfart).
const IMPACT_AT := 0.2
const ATTACK_SPEED := 1.25
const KICK_IMPACT_AT := 0.3

static var _weapon_kit: Node3D

var unit: CombatUnit
var sim: CombatSim
var visual: Dictionary
var anims: Dictionary
var model_scale := 1.0

var _body: Node3D
var _model: Node3D
var _player: AnimationPlayer
var _overlay := StandardMaterial3D.new()
var _flash := 0.0
var _flash_color := Color.WHITE
var _oneshot := false
var _blocking := false
var _casting := false
var _winding := false
var _dead := false
## Sekunder från senaste attackens start tills vapnet träffar; battle.gd fördröjer träffeffekterna så.
var last_impact_delay := 0.0
var _moving := false
var _move_run := false
var _move_from := Vector3.ZERO
var _move_to := Vector3.ZERO
var _move_t := 0.0
var _move_dur := 1.0
var _offset := Vector3.ZERO
var _offset_vel := Vector3.ZERO
var _face_target := Vector3.ZERO
var _t := randf() * 10.0
var _cast_light: OmniLight3D
var _cast_color := Color.WHITE
var _shield: MeshInstance3D
var _renew: MeshInstance3D
var _lust: Node3D
var _cast_player: AudioStreamPlayer
var _cast_tween: Tween


func setup(u: CombatUnit, s: CombatSim, vis: Dictionary) -> void:
	unit = u
	sim = s
	visual = vis
	anims = vis.get("anims", {})
	model_scale = vis.get("scale", 1.0)
	position = to_world(u.position)

	_body = Node3D.new()
	add_child(_body)
	_model = load("res://assets/models/%s.glb" % vis.model).instantiate()
	_model.scale = Vector3.ONE * model_scale
	_body.add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0]
	ProceduralAnims.add_to(_player, vis.get("procedural", []))
	for loop_anim in [anims.get("idle", ""), anims.get("cast", ""), anims.get("block", ""),
			anims.get("run", ""), anims.get("walk", "")]:
		if _player.has_animation(loop_anim):
			_player.get_animation(loop_anim).loop_mode = Animation.LOOP_LINEAR
	_attach_weapons(vis.get("weapons", {}))
	_setup_materials(vis)
	_build_aura_meshes()

	_cast_light = OmniLight3D.new()
	_cast_light.position = Vector3(0, 1.3 * model_scale, 0.4 * model_scale)
	_cast_light.omni_range = 2.5 * model_scale
	_cast_light.light_energy = 0.0
	_body.add_child(_cast_light)
	_cast_player = AudioStreamPlayer.new()
	add_child(_cast_player)
	_idle(0.0)


static func to_world(p: Vector2) -> Vector3:
	return Vector3(p.x * WORLD_SCALE, 0, p.y * WORLD_SCALE)


## Frigör den delade vapenmodellen när striden stängs.
static func free_shared() -> void:
	if _weapon_kit:
		_weapon_kit.free()
		_weapon_kit = null


func head_position() -> Vector3:
	return global_position + Vector3(0, 2.0 * model_scale, 0)


func chest_position() -> Vector3:
	return global_position + _offset + Vector3(0, 1.1 * model_scale, 0)


func face(target: Vector3) -> void:
	_face_target = target


# --- Rörelser ---------------------------------------------------------------

func attack(toward: Vector3, lunge := 0.25) -> void:
	if _dead:
		return
	var list: Array = anims.get("attack", [])
	last_impact_delay = 0.0
	if not list.is_empty():
		var anim_name: String = list[randi() % list.size()]
		_play_oneshot(anim_name, 0.06, ATTACK_SPEED)
		last_impact_delay = _player.get_animation(anim_name).length * IMPACT_AT / (ATTACK_SPEED * unit.haste())
	_push_delayed((toward - global_position).normalized() * lunge * model_scale, last_impact_delay * 0.6)


## Spark (Rogue: Kick). Använder animationen "kick" om figuren har en, annars en vanlig attack.
func kick(toward: Vector3) -> void:
	if _dead:
		return
	if not anims.has("kick"):
		attack(toward, 0.4)
		return
	_play_oneshot(anims.kick, 0.05, 1.0)
	last_impact_delay = _player.get_animation(anims.kick).length * KICK_IMPACT_AT
	_push_delayed((toward - global_position).normalized() * 0.45 * model_scale, last_impact_delay * 0.6)


## Startar kaströrelsen. Närstridsslag (windup) lyfter vapnet och håller det tills slaget faller.
func start_cast(school: String, melee: bool) -> void:
	if _dead:
		return
	_casting = true
	_cast_color = UiStyle.school_color(school)
	_cast_light.light_color = _cast_color
	if melee and anims.has("windup"):
		_winding = true
		_oneshot = true
		_play(anims.windup, 0.15)
	elif anims.has("cast"):
		_oneshot = false
		_play(anims.cast, 0.15)
	elif not _oneshot:
		_idle(0.15)


func end_cast(success: bool) -> void:
	_casting = false
	if _dead:
		return
	if _winding:
		_winding = false
		if success:
			_player.speed_scale = 1.6
			_player.play()
		else:
			_idle(0.15)
		return
	if success and anims.has("release"):
		_play_oneshot(anims.release, 0.08, 1.4)
	elif not _oneshot:
		_idle(0.15)


func hit(strength := 1.0, from := Vector3.ZERO) -> void:
	_flash = minf(1.0, 0.55 + 0.35 * strength)
	_flash_color = Color.WHITE
	if from != Vector3.ZERO:
		_push((global_position - from).normalized() * 0.12 * strength)
	if _dead or _casting or _winding:
		return
	if strength >= 1.8 or not _oneshot:
		if _blocking and anims.has("block"):
			_play_oneshot(anims.block, 0.05, 1.5)
		elif anims.has("hit"):
			_play_oneshot(anims.hit, 0.05, 1.3)


func flash_color(c: Color) -> void:
	_flash = 1.0
	_flash_color = c


## Går eller springer till en ny plats. Bara utseende – stridslogiken bryr sig inte om positioner.
func move_to(target: Vector3, duration: float, run: bool) -> void:
	if _dead:
		return
	_move_from = position
	_move_to = target
	_move_t = 0.0
	_move_dur = maxf(duration, 0.05)
	_move_run = run
	_moving = true
	if not _oneshot and not _casting:
		_idle(0.15)


func is_moving() -> bool:
	return _moving


func set_blocking(on: bool) -> void:
	_blocking = on
	if not _oneshot and not _casting and not _dead:
		_idle(0.15)


func die() -> void:
	_dead = true
	_casting = false
	_winding = false
	_player.speed_scale = 1.0
	if anims.has("death"):
		_play(anims.death, 0.1)
	stop_cast_sound()


func start_cast_sound(s: AudioStream) -> void:
	if s == null:
		return
	if _cast_tween:
		_cast_tween.kill()
	_cast_player.stream = s
	_cast_player.volume_db = -13.0 if unit.team == 0 else -7.0
	_cast_player.play()


func stop_cast_sound() -> void:
	if not _cast_player.playing:
		return
	if _cast_tween:
		_cast_tween.kill()
	_cast_tween = create_tween()
	_cast_tween.tween_property(_cast_player, "volume_db", -40.0, 0.08)
	_cast_tween.tween_callback(_cast_player.stop)


# --- Bildruta ---------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	# Fjäder tillbaka till utgångsläget efter utfall och knuffar.
	_offset_vel += -_offset * 160.0 * delta - _offset_vel * 16.0 * delta
	_offset += _offset_vel * delta
	_body.position = _offset

	if _moving:
		_move_t += delta
		var k := clampf(_move_t / _move_dur, 0.0, 1.0)
		position = _move_from.lerp(_move_to, k * k * (3.0 - 2.0 * k))
		var dir := _move_to - _move_from
		if dir.length() > 0.01 and not _casting:
			_body.rotation.y = lerp_angle(_body.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 12.0))
		if k >= 1.0:
			_moving = false
			if not _oneshot and not _casting and not _dead:
				_idle(0.2)

	if _face_target != Vector3.ZERO and not _dead and not (_moving and not _casting):
		var dir := _face_target - global_position
		var want := atan2(dir.x, dir.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, want, minf(1.0, delta * 8.0))

	if _winding and _player.current_animation_position >= _player.current_animation_length * WINDUP_HOLD and _casting:
		_player.pause()
	if _oneshot and not _player.is_playing() and not _dead and not _winding:
		_oneshot = false
		_player.speed_scale = 1.0
		if _casting and anims.has("cast"):
			_play(anims.cast, 0.15)
		else:
			_idle(0.2)

	_flash = maxf(0.0, _flash - delta * 5.0)
	_overlay.albedo_color = Color(_flash_color, _flash * 0.7)

	var cast_target := 0.0
	if _casting:
		cast_target = 1.5 + 0.8 * sin(_t * 14.0)
	_cast_light.light_energy = move_toward(_cast_light.light_energy, cast_target, delta * 12.0)

	_update_auras(delta)


func _update_auras(delta: float) -> void:
	_shield.visible = unit.auras.has("shield_wall")
	if _shield.visible:
		var p := 0.5 + 0.5 * sin(_t * 6.0)
		(_shield.material_override as StandardMaterial3D).albedo_color = Color(0.6, 0.78, 1.0, 0.16 + 0.08 * p)
	_renew.visible = unit.auras.has("renew")
	_renew.rotation.y += delta * 2.0
	_lust.visible = unit.auras.has("bloodlust") or unit.auras.has("frenzy")
	if _lust.visible:
		_lust.rotation.y -= delta * 3.0
		var s := 1.0 + 0.06 * sin(_t * 20.0)
		_lust.scale = Vector3(s, 1, s)


# --- Hjälpfunktioner --------------------------------------------------------

func _play(anim_name: String, blend: float, speed := 1.0) -> void:
	if not _player.has_animation(anim_name):
		return
	_player.speed_scale = speed * unit.haste()
	if _player.current_animation == anim_name:
		_player.seek(0.0, true)
	_player.play(anim_name, blend)


func _play_oneshot(anim_name: String, blend: float, speed := 1.0) -> void:
	_oneshot = true
	_play(anim_name, blend, speed)


func _idle(blend: float) -> void:
	_oneshot = false
	var anim_name: String = anims.get("idle", "")
	if _moving:
		anim_name = anims.get("run" if _move_run else "walk", anim_name)
	elif _blocking:
		anim_name = anims.get("block", anim_name)
	_play(anim_name, blend)


func _push(v: Vector3) -> void:
	_offset_vel += v * 14.0


func _push_delayed(v: Vector3, delay: float) -> void:
	if delay <= 0.0:
		_push(v)
	else:
		get_tree().create_timer(delay, false).timeout.connect(_push.bind(v))


func _attach_weapons(weapons: Dictionary) -> void:
	if weapons.is_empty():
		return
	if _weapon_kit == null:
		_weapon_kit = load("res://assets/models/vapen.glb").instantiate()
	for grip in weapons:
		var at := _model.find_child(grip, true, false)
		var part := _weapon_kit.find_child(weapons[grip], true, false)
		if at and part:
			at.add_child(part.duplicate())


func _setup_materials(vis: Dictionary) -> void:
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = Color(1, 1, 1, 0)
	var tint := Color(vis.get("tint", "#ffffff"))
	for m in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := m as MeshInstance3D
		mesh.material_overlay = _overlay
		if tint != Color.WHITE:
			for i in mesh.get_surface_override_material_count():
				var base := mesh.mesh.surface_get_material(i)
				if base is StandardMaterial3D:
					var mat: StandardMaterial3D = base.duplicate()
					mat.albedo_color = mat.albedo_color * tint
					mat.emission_enabled = true
					mat.emission = Color(0.35, 0.2, 0.6)
					mat.emission_energy_multiplier = 0.25
					mesh.set_surface_override_material(i, mat)


func _build_aura_meshes() -> void:
	var s := model_scale
	_shield = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.85 * s
	sphere.height = 1.9 * s
	_shield.mesh = sphere
	_shield.position = Vector3(0, 0.9 * s, 0)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.albedo_color = Color(0.6, 0.78, 1.0, 0.2)
	_shield.material_override = sm
	_body.add_child(_shield)

	_renew = _ring(0.6 * s, 0.035, Color(0.4, 1.0, 0.5, 0.9))
	_renew.position.y = 0.05
	add_child(_renew)

	_lust = Node3D.new()
	var col := Color(1.0, 0.35, 0.1, 0.9) if unit.team == 0 else Color(1.0, 0.15, 0.1, 0.9)
	for i in 2:
		var r := _ring((0.5 + i * 0.1) * s, 0.018, Color(col, 0.75 - i * 0.35))
		r.position.y = 0.04 + i * 0.3 * s
		_lust.add_child(r)
	add_child(_lust)


func _ring(radius: float, thickness: float, color: Color) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 48
	var m := MeshInstance3D.new()
	m.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m
