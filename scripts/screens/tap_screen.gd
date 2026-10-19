class_name TapScreen
extends Control
## Gemensam grund för valskärmarna i basen: reagerar när fingret släpps (undviker dubbeltryck
## mellan skärmar), ritar om varje bildruta och har små knappar och en tillbakaknapp.

const MARGIN := 28.0
const GAP := 14.0
const BG := Color(0.04, 0.035, 0.06)

## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
var run: Node
var _t := 0.0
var _press_at := Vector2(-1, -1)


func _ready() -> void:
	run = get_node("/root/Run")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	run.base_music()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if event.pressed:
		_press_at = event.position
		return
	if _press_at.distance_to(event.position) > 30.0:
		return
	_tap(event.position)
	run.ui_tap()


## Överskrivs: ett tryck (släpp) på punkten.
func _tap(_p: Vector2) -> void:
	pass


func back_rect() -> Rect2:
	return Rect2(MARGIN, 18, 150, 44)


func small_button(r: Rect2, label: String, enabled := true) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(r, Color(UiStyle.TRAIT_GOLD, 0.7 if enabled else 0.2), false, 2.0)
	UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + 7), label, 18,
			Color(UiStyle.TRAIT_GOLD, 1.0 if enabled else 0.35), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 4)


## Liten valbar knapp (chip), guldfärgad när den är vald.
func chip(r: Rect2, label: String, on: bool, size_px := 15) -> void:
	draw_rect(r, Color(0.35, 0.25, 0.05, 0.92) if on else Color(0, 0, 0, 0.6))
	draw_rect(r, Color(UiStyle.GOLD, 0.95) if on else Color(1, 1, 1, 0.3), false, 2.0)
	UiStyle.text(self, r.position + Vector2(0, r.size.y / 2 + size_px * 0.35), label, size_px, Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)


## Rubrik och bakgrund. backdrop: en tuschbild (assets/illustrations/) som tonas svagt i bakgrunden.
func header(title: String, sub := "", backdrop: Texture2D = null) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	if backdrop:
		var h := size.x * backdrop.get_height() / backdrop.get_width()
		draw_texture_rect(backdrop, Rect2(0, (size.y - h) / 2, size.x, h), false, Color(1, 1, 1, 0.13))
	UiStyle.text(self, Vector2(0, 50), title, 36, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8)
	if sub != "":
		UiStyle.text(self, Vector2(0, 78), sub, 16, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	silver_label()


func silver_label() -> void:
	UiStyle.text(self, Vector2(0, 46), "SILVER %d" % run.profile.silver, 22, Color("#d8dde6"),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - MARGIN, 4)
