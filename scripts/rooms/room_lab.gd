extends Control
## Testscen för rumsögonblicken. Visar en rumstyp, eller alla i tur och ordning (tryck för nästa).
##
##   godot --path . res://scripts/rooms/room_lab.tscn -- --room=treasure --style=chapel
##   godot --path . res://scripts/rooms/room_lab.tscn -- --room=all
##   godot --path . res://scripts/rooms/room_lab.tscn -- --room=portal --shot=/tmp/portal.png --at=4.5
##
## --party=paladin,brokk,alva väljer sällskapet (standard: alla fem hjältarna).
## --debug-walk skriver ut varje figurs animation och position under gången.
## --shot sparar en bild när ögonblicket kommit så långt (--at sekunder) och avslutar.

var _queue: Array = []
var _party: Array = ["paladin", "brokk", "alva", "eira", "solveig"]
var _shot := ""
var _at := 4.5
var _moment: RoomMoment
var _data: Dictionary


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process_internal(true)
	if OS.get_cmdline_user_args().has("--bench"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	_data = GameData.load_all()
	var room := "treasure"
	var style := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			room = arg.get_slice("=", 1)
		elif arg.begins_with("--style="):
			style = arg.get_slice("=", 1)
		elif arg.begins_with("--party="):
			_party = Array(arg.get_slice("=", 1).split(","))
		elif arg.begins_with("--shot="):
			_shot = arg.get_slice("=", 1)
		elif arg.begins_with("--at="):
			_at = float(arg.get_slice("=", 1))
	var kinds: Array = RoomWorld.KINDS if room == "all" else [room]
	var styles: Array = RoomWorld.STYLES if style == "" and room == "all" else [style if style != "" else "crypt"]
	for s in styles:
		for k in kinds:
			_queue.append([k, s])
	_next()


func _next() -> void:
	if _moment:
		_moment.queue_free()
		UnitModel.free_shared()
	if _queue.is_empty():
		_queue = [[RoomWorld.KINDS[0], "crypt"]]
	var item: Array = _queue.pop_front()
	_queue.append(item)
	_moment = RoomMoment.create(item[0], item[1], _party, _data)
	add_child(_moment)
	_moment.finished.connect(_on_finished)
	var args := OS.get_cmdline_user_args()
	if args.has("--no-msaa"):
		(_moment.world.get_viewport() as SubViewport).msaa_3d = Viewport.MSAA_DISABLED
	if args.has("--no-shadow"):
		for l in _moment.world.find_children("*", "DirectionalLight3D", true, false):
			l.shadow_enabled = false


func _on_finished(skipped: bool) -> void:
	if skipped:
		_next.call_deferred()


func _gui_input(event: InputEvent) -> void:
	# Efter att ögonblicket är slut går ett tryck vidare till nästa rum.
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_next.call_deferred()


func _process(_delta: float) -> void:
	if _shot != "" and _moment and _moment._t >= _at:
		var path := _shot
		_shot = ""
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path)
		_moment.world.get_viewport().get_texture().get_image().save_png(path.replace(".png", "_vp.png"))
		get_tree().quit()


func _physics_process(_d: float) -> void:
	if OS.get_cmdline_user_args().has("--debug-walk") and _moment and Engine.get_physics_frames() % 15 == 0:
		for m in _moment.models:
			var p: AnimationPlayer = m._player
			print("%.2f %s anim=%s pos=%s moving=%s" % [_moment._t, m.unit.id, p.current_animation, m.global_position, m.is_moving()])


# --bench: mäter bildtakten medan händelsen spelas (2,7–4,8 s), skriver ut och avslutar.
# Bildtiden låses till skärmens takt (macOS släpper inte vsync i GL); --load lägger till extra vyer
# som belastar grafikkortet, men mätningen spretar. Ljusen och ritanropen är det pålitliga måttet.
var _bench_frames := 0
var _bench_start := 0
var _bench_draws := 0
var _load_cams: Array[Camera3D] = []
## Extra vyer av samma rum i 1920×1080 som belastar grafikkortet, så att skillnader i ljus och
## MSAA syns i bildtiden trots att skärmen låser takten (macOS släpper inte vsync i GL).
const LOAD_VIEWS := 10


func _add_load_views() -> void:
	var main_vp := _moment.world.get_viewport() as SubViewport
	for i in LOAD_VIEWS:
		var vp := SubViewport.new()
		vp.size = Vector2i(1920, 1080)
		vp.world_3d = main_vp.world_3d
		vp.msaa_3d = main_vp.msaa_3d
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var cam := Camera3D.new()
		cam.fov = _moment.camera.fov
		cam.current = true
		vp.add_child(cam)
		add_child(vp)
		_load_cams.append(cam)


func _notification(what: int) -> void:
	if what != NOTIFICATION_INTERNAL_PROCESS or not _moment or not OS.get_cmdline_user_args().has("--bench"):
		return
	var t := _moment._t
	var vp := _moment.world.get_viewport().get_viewport_rid()
	if t >= RoomMoment.REVEAL_AT and _bench_start == 0:
		_bench_start = Time.get_ticks_usec()
		if OS.get_cmdline_user_args().has("--load"):
			_add_load_views()
	elif _bench_start > 0 and t < RoomMoment.LENGTH:
		_bench_frames += 1
		for c in _load_cams:
			c.global_transform = _moment.camera.global_transform
		_bench_draws = maxi(_bench_draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	elif _bench_start > 0:
		var ms := (Time.get_ticks_usec() - _bench_start) / 1000.0 / maxi(_bench_frames, 1)
		var lights := 0
		for l in _moment.world.find_children("*", "Light3D", true, false):
			if l.is_visible_in_tree():
				lights += 1
		var n := maxi(_bench_frames, 1)
		print("BENCH %s/%s ljus=%d msaa=%s bildtid=%.2f ms (%d extra vyer) drawcalls=%d" % [
				_moment.style, _moment.kind, lights, _moment.world.get_viewport().msaa_3d, ms, _load_cams.size(), _bench_draws])
		get_tree().quit()
		_bench_start = -1
