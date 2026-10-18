class_name ProceduralAnims
extends RefCounted
## Egna animationer byggda i kod ovanpå Quaternius-skelettet, för rörelser som saknas i
## materialet (spark, tydlig Shield Wall, kanalisering av besvärjelser).
##
## En animation utgår från en pose i en befintlig animation (base, base_time). Varje nyckel
## anger tid och vridningar i grader per ben (Euler XYZ i benets eget rum), plus valfri
## höjning/sänkning av höfterna ("hips_y" i meter) och förflyttning av fotbenen ("pos":
## {"Foot.R": [x, y, z]} i förälderns rum – fötterna är egna ben i riggen och följer inte
## med när benet vrids). Mellan nycklarna interpoleras mjukt.

const DEFS := {
	# Rogue: framspark. Knät dras upp, benet skjuts ut i höfthöjd, överkroppen lutar bakåt.
	"Kick": {"base": "OneHand_Idle", "length": 0.8, "keys": [
		{"t": 0.0, "bones": {}},
		{"t": 0.12, "bones": {"UpperLeg.R": [-55, 0, 0], "LowerLeg.R": [75, 0, 0], "Torso": [-6, 0, 0]}},
		{"t": 0.24, "bones": {"UpperLeg.R": [-95, 0, 0], "LowerLeg.R": [-8, 0, 0], "Torso": [-20, 0, 0],
				"UpperArm.R": [0, 0, -25], "UpperArm.L": [0, 0, 25]}},
		{"t": 0.38, "bones": {"UpperLeg.R": [-88, 0, 0], "LowerLeg.R": [0, 0, 0], "Torso": [-17, 0, 0],
				"UpperArm.R": [0, 0, -20], "UpperArm.L": [0, 0, 20]}},
		{"t": 0.56, "bones": {"UpperLeg.R": [-45, 0, 0], "LowerLeg.R": [65, 0, 0], "Torso": [-5, 0, 0]}},
		{"t": 0.8, "bones": {}},
	]},
	# Priest: båda händerna lyfts framåt och uppåt och pulserar medan healingen laddas.
	"Cast_Channel_Priest": {"base": "OneHand_Idle", "length": 1.2, "loop": true, "keys": [
		{"t": 0.0, "bones": {"UpperArm.R": [-25, 0, 70], "UpperArm.L": [-25, 0, -70], "Torso": [-6, 0, 0], "Head": [-8, 0, 0]}},
		{"t": 0.6, "bones": {"UpperArm.R": [-38, 0, 90], "UpperArm.L": [-38, 0, -90], "Torso": [-11, 0, 0], "Head": [-14, 0, 0]}},
		{"t": 1.2, "bones": {"UpperArm.R": [-25, 0, 70], "UpperArm.L": [-25, 0, -70], "Torso": [-6, 0, 0], "Head": [-8, 0, 0]}},
	]},
	# Mage: staven lyfts högt, fria handen sträcks fram mot målet.
	"Cast_Channel_Mage": {"base": "Staff_Idle", "length": 1.0, "loop": true, "keys": [
		{"t": 0.0, "bones": {"UpperArm.R": [-15, 0, 105], "UpperArm.L": [-25, 0, -75], "Torso": [-8, 0, 0], "Head": [-6, 0, 0]}},
		{"t": 0.5, "bones": {"UpperArm.R": [-22, 0, 120], "UpperArm.L": [-35, 0, -88], "Torso": [-12, 0, 0], "Head": [-10, 0, 0]}},
		{"t": 1.0, "bones": {"UpperArm.R": [-15, 0, 105], "UpperArm.L": [-25, 0, -75], "Torso": [-8, 0, 0], "Head": [-6, 0, 0]}},
	]},
	# Warrior: skölden lyfts upp framför ansiktet, kroppen lutar in bakom den.
	"Shield_Wall": {"base": "Shield_Idle", "length": 1.0, "loop": true, "keys": [
		{"t": 0.0, "bones": {"UpperArm.L": [-15, 0, -45], "Torso": [14, 0, 0], "Head": [6, 0, 0]}},
		{"t": 0.5, "bones": {"UpperArm.L": [-17, 0, -48], "Torso": [16, 0, 0], "Head": [7, 0, 0]}},
		{"t": 1.0, "bones": {"UpperArm.L": [-15, 0, -45], "Torso": [14, 0, 0], "Head": [6, 0, 0]}},
	]},
}


## Lägger till de animationer i DEFS som figuren ska ha (names) i dess AnimationPlayer.
static func add_to(player: AnimationPlayer, names: Array, defs := DEFS) -> void:
	var lib := player.get_animation_library("")
	for anim_name in names:
		if not defs.has(anim_name) or player.has_animation(anim_name):
			continue
		var anim := build(player, defs[anim_name])
		if anim:
			lib.add_animation(anim_name, anim)


static func build(player: AnimationPlayer, def: Dictionary) -> Animation:
	var base_name := _find_anim(player, def.base)
	if base_name == "":
		push_warning("Hittar ingen basanimation " + def.base)
		return null
	var base := player.get_animation(base_name)
	var base_time: float = def.get("base_time", 0.0)
	var length: float = def.length
	var keys: Array = def.keys
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if def.get("loop", false) else Animation.LOOP_NONE

	var sk := _skeleton(player)
	# Fötterna är egna ben (IK-mål) i riggen och följer inte med när benet vrids.
	# Räkna ut var underbenet hamnar i varje nyckel och flytta fotbenet dit.
	var feet := {}
	if sk:
		for k in keys:
			feet[k.t] = _follow_feet(sk, base, base_time, k.bones)

	for i in base.get_track_count():
		var path := base.track_get_path(i)
		var bone := path.get_concatenated_subnames()
		match base.track_get_type(i):
			Animation.TYPE_ROTATION_3D:
				var rest: Quaternion = base.rotation_track_interpolate(i, base_time)
				var t := anim.add_track(Animation.TYPE_ROTATION_3D)
				anim.track_set_path(t, path)
				anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
				for k in keys:
					var q := rest * _euler(k.bones.get(bone, [0, 0, 0]))
					if feet.has(k.t) and feet[k.t].has(bone):
						q = feet[k.t][bone].basis.get_rotation_quaternion()
					anim.rotation_track_insert_key(t, k.t, q)
			Animation.TYPE_POSITION_3D:
				var pos: Vector3 = base.position_track_interpolate(i, base_time)
				var t := anim.add_track(Animation.TYPE_POSITION_3D)
				anim.track_set_path(t, path)
				anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
				for k in keys:
					var p := pos
					if bone == "Hips" or bone == "Body":
						p.y += k.get("hips_y", 0.0)
						p.z += k.get("hips_z", 0.0)
					if feet.has(k.t) and feet[k.t].has(bone):
						p = feet[k.t][bone].origin
					anim.position_track_insert_key(t, k.t, p)
	return anim


static func _euler(v: Variant) -> Quaternion:
	return Quaternion.from_euler(_vec(v) * PI / 180.0)


## Lokala transformer för fotbenen så att foten sitter kvar i änden av underbenet när benet vrids.
static func _follow_feet(sk: Skeleton3D, base: Animation, base_time: float, offsets: Dictionary) -> Dictionary:
	var out := {}
	for side in ["L", "R"]:
		var upper: String = "UpperLeg." + side
		var lower: String = "LowerLeg." + side
		var foot: String = "Foot." + side
		if not (offsets.has(upper) or offsets.has(lower) or offsets.has("Hips") or offsets.has("Body")):
			continue
		if sk.find_bone(foot) < 0 or sk.find_bone(lower) < 0:
			continue
		var before := _global_pose(sk, base, base_time, {}, lower)
		var after := _global_pose(sk, base, base_time, offsets, lower)
		var foot_before := _global_pose(sk, base, base_time, {}, foot)
		var foot_after := after * before.affine_inverse() * foot_before
		var parent := sk.get_bone_parent(sk.find_bone(foot))
		var parent_global := _global_pose(sk, base, base_time, offsets, sk.get_bone_name(parent)) if parent >= 0 else Transform3D()
		out[foot] = parent_global.affine_inverse() * foot_after
	return out


## Benets transform i skelettets rum för basposen plus vridningarna i offsets.
static func _global_pose(sk: Skeleton3D, base: Animation, base_time: float, offsets: Dictionary, bone_name: String) -> Transform3D:
	var idx := sk.find_bone(bone_name)
	var chain: Array[int] = []
	while idx >= 0:
		chain.push_front(idx)
		idx = sk.get_bone_parent(idx)
	var xf := Transform3D()
	for b in chain:
		var bname := sk.get_bone_name(b)
		var rest := sk.get_bone_rest(b)
		var rot := rest.basis.get_rotation_quaternion()
		var pos := rest.origin
		var path := NodePath(str(base.track_get_path(0)).get_slice(":", 0) + ":" + bname)
		var rt := base.find_track(path, Animation.TYPE_ROTATION_3D)
		if rt >= 0:
			rot = base.rotation_track_interpolate(rt, base_time)
		var pt := base.find_track(path, Animation.TYPE_POSITION_3D)
		if pt >= 0:
			pos = base.position_track_interpolate(pt, base_time)
		if offsets.has(bname):
			rot = rot * _euler(offsets[bname])
		xf = xf * Transform3D(Basis(rot).scaled(rest.basis.get_scale()), pos)
	return xf


static func _skeleton(player: AnimationPlayer) -> Skeleton3D:
	var root := player.get_node(player.root_node)
	var found := root.find_children("*", "Skeleton3D", true, false)
	return found[0] if not found.is_empty() else null


static func _vec(v: Variant) -> Vector3:
	if v is Vector3:
		return v
	return Vector3(v[0], v[1], v[2])


static func _find_anim(player: AnimationPlayer, wanted: String) -> String:
	if player.has_animation(wanted):
		return wanted
	for a in player.get_animation_list():
		if a.ends_with(wanted):
			return a
	return ""
