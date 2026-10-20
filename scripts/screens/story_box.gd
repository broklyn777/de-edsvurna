class_name StoryBox
extends CanvasLayer
## Berättelsens rutor (0.25, docs/plan/0.25-berattelsen.md §1–2): rader {who, text} en i taget. Talaren "narrator" är
## berättarens röst på svart, kursiv och inom parentes, som i Siralim; andra talare får samtalsrutan (DialogBox) med
## porträtt. Ett tryck går vidare. Borgen ritar sina samtal själv men använder narrator() för berättarens rader.

signal finished

const NARRATOR := "narrator"

var lines: Array = []
var data: Dictionary
var hero_name := ""
var _i := 0
var _t := 0.0
var _view: Control

static var _italic: Font


static func italic() -> Font:
	if _italic == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Times New Roman", "Noto Serif", "serif"])
		f.font_italic = true
		_italic = f
	return _italic


## Lägger rutorna ovanpå värden; null om det inte finns några rader.
static func play(host: Node, story: Array) -> StoryBox:
	if story.is_empty():
		return null
	var run := host.get_node("/root/Run")
	var box := StoryBox.new()
	box.lines = story
	box.data = run.data
	box.hero_name = run.profile.hero_name
	host.add_child(box)
	return box


func _ready() -> void:
	layer = 55
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_paint)
	_view.gui_input.connect(_input_on)
	add_child(_view)


func _process(delta: float) -> void:
	_t += delta
	_view.queue_redraw()


func _input_on(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_view.accept_event()
		if not event.pressed and _t > 0.3:
			_i += 1
			_t = 0.0
			if _i >= lines.size():
				finished.emit()
				queue_free()


func _paint() -> void:
	var l: Dictionary = lines[_i]
	var text := Dialog.fill(String(l.text), hero_name)
	if l.who == NARRATOR:
		narrator(_view, _view.size, text, _t)
	else:
		_view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color(0, 0, 0, 0.35))
		DialogBox.box(_view, data, _view.size, l.who, text, _t)


## Berättarens rad: svart, kursiv text mitt på skärmen som tonar in, och en svag rad om att trycka.
static func narrator(ci: CanvasItem, area: Vector2, text: String, t: float) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, area), Color(0.0, 0.0, 0.0, 0.97))
	var a := clampf(t / 0.6, 0.0, 1.0)
	var w := minf(area.x - 120, 900.0)
	var f := italic()
	var h := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, w, 26).y
	ci.draw_multiline_string(f, Vector2((area.x - w) / 2.0, area.y / 2.0 - h / 2.0 + 20), text,
			HORIZONTAL_ALIGNMENT_CENTER, w, 26, -1, Color(0.92, 0.88, 0.80, a))
	UiStyle.text(ci, Vector2(0, area.y - 40), "Tryck för att fortsätta", 15,
			Color(1, 1, 1, (0.3 + 0.15 * sin(t * 4.0)) * a), HORIZONTAL_ALIGNMENT_CENTER, area.x)
