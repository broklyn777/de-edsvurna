class_name RoomMoment
extends Control
## Ögonblicksspelaren: ett kort 3D-ögonblick när sällskapet går in i ett rum på rumskartan.
## Dörren öppnas, sällskapet går in, kameran glider efter och rummets händelse spelas (ca 4,5 s).
## Ett tryck hoppar över. Ligger över hela skärmen och kan läggas på vilken 2D-skärm som helst:
##
##   var moment := RoomMoment.create("treasure", "crypt", ["paladin", "brokk", "alva"])
##   add_child(moment)
##   await moment.finished          # true om spelaren hoppade över
##   moment.queue_free()
##
## Se docs/rum3d.md.

## Skickas när ögonblicket är slut eller hoppades över. Ögonblicket ligger kvar tills det frigörs.
signal finished(skipped: bool)

## Tidpunkter i sekunder.
const FADE_IN := 0.35
const DOOR_AT := 0.3
const WALK_AT := 0.75
const WALK_TIME := 2.3
const STAGGER := 0.18
const CAMERA_TIME := 3.0
const REVEAL_AT := 2.7
const LENGTH := 4.8

## Ungefärlig fart (m/s) i gånganimationen vid normal uppspelning; gången spelas snabbare eller
## långsammare så att stegen följer marken och figurerna inte glider.
const WALK_PACE := 1.6

const CAM_PATH := [Vector3(0, 2.7, 14.5), Vector3(0, 3.1, 8.0), Vector3(0.15, 3.3, 4.0), Vector3(2.7, 4.1, 3.9)]

var kind := "treasure"
var style := "crypt"
var hero_ids: Array = []
## Hålls kvar på sista bilden efter finished i stället för att tona ut (t.ex. bakom en dialog).
var hold_last_frame := true
var play_sound := true

var world: RoomWorld
var camera: Camera3D
var models: Array[UnitModel] = []
var sfx: Sfx
var _t := 0.0
var _done := false
var _revealed := false
var _door := false
var _walking := false
var _fade: ColorRect
var _title: Label
var _hint: Label
var _data: Dictionary


static func create(room_kind: String, room_style: String, heroes: Array, data: Dictionary = {}) -> RoomMoment:
	var m := RoomMoment.new()
	m.kind = room_kind
	m.style = room_style
	m.hero_ids = heroes
	m._data = data
	return m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _data.is_empty():
		_data = GameData.load_all()

	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	container.add_child(vp)

	world = RoomWorld.new()
	world.kind = kind
	world.style = style
	vp.add_child(world)
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.current = true
	world.add_child(camera)

	if play_sound:
		sfx = Sfx.new()
		add_child(sfx)
		sfx.start_ambience("ambience_crypt", -16.0)

	var starts := world.entry_slots(hero_ids.size())
	for i in hero_ids.size():
		var id: String = hero_ids[i]
		var d: Dictionary = _data.heroes.get(id, {})
		if d.is_empty():
			continue
		var u := CombatUnit.from_data(id, d, 0)
		var m := UnitModel.new()
		world.add_child(m)
		m.setup(u, null, d.visual)
		m.sfx = sfx
		m.position = starts[i]
		m.face(m.position + Vector3(0, 0, -5))
		models.append(m)
	_place_camera(0.0)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_title = _label(RoomWorld.NAMES.get(kind, kind), 44)
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 40
	_title.modulate.a = 0.0
	add_child(_title)
	_hint = _label("Tryck för att hoppa över", 18)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -48
	_hint.offset_right = -24
	_hint.modulate.a = 0.0
	add_child(_hint)


func _process(delta: float) -> void:
	if _done and hold_last_frame:
		_t += delta
		_place_camera(_t)
		return
	_t += delta
	_fade.color.a = 1.0 - clampf(_t / FADE_IN, 0.0, 1.0)
	_hint.modulate.a = clampf((_t - 0.6) / 0.4, 0.0, 0.55)
	if not _door and _t >= DOOR_AT:
		_door = true
		world.open_door(0.8)
		if sfx:
			sfx.play("k_shield_wall", -14.0, 0.0)
	if not _walking and _t >= WALK_AT:
		_walking = true
		var slots := world.party_slots(models.size())
		for i in models.size():
			_walk_later(models[i], slots[i], WALK_AT + i * STAGGER)
	if not _revealed and _t >= REVEAL_AT:
		_revealed = true
		world.reveal()
		if sfx:
			sfx.play(_reveal_sound(), -5.0, 0.0)
	if _revealed:
		_title.modulate.a = clampf((_t - REVEAL_AT - 0.3) / 0.5, 0.0, 1.0)
	_place_camera(_t)
	if _t >= LENGTH:
		_finish(false)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed)
	if pressed and not _done:
		accept_event()
		_finish(true)


func _finish(skipped: bool) -> void:
	if _done:
		return
	_done = true
	_hint.visible = false
	finished.emit(skipped)


func _walk_later(m: UnitModel, target: Vector3, at: float) -> void:
	var wait := at - _t
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	if not is_instance_valid(m):
		return
	var dur := WALK_TIME - (at - WALK_AT)
	m.move_to(target, dur, false)
	m.face(world.focus_point())
	# move_to startar gånganimationen i jämn takt; anpassa den efter sträckan. Rörelsen bromsar in
	# mot slutet (smoothstep), så medelfarten räknas om till toppfarten (× 1,5) för stegen.
	var pace := m.position.distance_to(target) / dur * 1.5
	m._player.speed_scale = clampf(pace / WALK_PACE, 0.7, 1.8)


## Kameran åker längs en kubisk kurva genom dörren och svänger upp mot rummets mittpunkt,
## och andas sedan långsamt så att slutbilden inte står helt still.
func _place_camera(t: float) -> void:
	var k := clampf((t - 0.4) / CAMERA_TIME, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var u := 1.0 - k
	var pos: Vector3 = CAM_PATH[0] * u * u * u + CAM_PATH[1] * 3.0 * u * u * k \
			+ CAM_PATH[2] * 3.0 * u * k * k + CAM_PATH[3] * k * k * k
	var drift := maxf(0.0, t - 0.4 - CAMERA_TIME)
	pos += Vector3(-0.12 * drift, 0.02 * drift, -0.08 * drift).limit_length(0.8)
	var look := Vector3(0, 1.4, RoomWorld.FRONT - 1.0).lerp(world.focus_point(), k)
	camera.position = pos
	camera.look_at(look)


func _reveal_sound() -> String:
	match kind:
		"treasure": return "renew"
		"shrine": return "heal"
		"prisoner": return "k_shield_slam"
		"inscription": return "cast_holy"
		"campfire": return "cast_fire"
		"portal": return "cast_shadow"
	return "renew"


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
