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


func _on_finished(skipped: bool) -> void:
	if skipped:
		_next.call_deferred()


func _gui_input(event: InputEvent) -> void:
	# Efter att ögonblicket är slut går ett tryck vidare till nästa rum.
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_next.call_deferred()


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 10 == 0: print("t=", _moment._t, " rev=", _moment.world.revealed, " title=", _moment._title.get_rect(), _moment._title.modulate.a)
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
