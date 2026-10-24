class_name FpsMeter
extends CanvasLayer
## Prototyp (sallskap-fem): bildtakten i ett hörn, för att mäta på telefonen. Visas med --fps eller med FPS PÅ i
## inställningarna (GameSettings.show_fps). Visar också animerade figurer (AnimationPlayer i scenen), ritanrop och
## objekt i bilden. Ändrar inte bildtaktsgränsen (Run.update_fps).

var _label: Label
var _wait := 0.0


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(262, 80)  # under tidslinjen, till höger om ramarna
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = 0.5
	var scene := get_tree().current_scene
	var anims := 0 if scene == null else scene.find_children("*", "AnimationPlayer", true, false).size()
	_label.text = "%d FPS · %d figurer · %d ritanrop · %d objekt" % [Engine.get_frames_per_second(), anims,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)]


## Visar eller tar bort mätaren under Run.
static func set_shown(host: Node, on: bool) -> void:
	var old := host.get_node_or_null("FpsMeter")
	if on and old == null:
		var m := FpsMeter.new()
		m.name = "FpsMeter"
		host.add_child(m)
	elif not on and old != null:
		old.queue_free()
