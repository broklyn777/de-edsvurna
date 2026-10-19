extends Control
## Ett sällsynt fynd (0.20): en egen liten scen ovanpå skärmen. Mörkret drar sig undan, ljusstrålar
## snurrar kring stenen, som glöder i sällsynthetens färg, och dess egenskaper skrivs fram en i taget.
## Ett tryck stänger (efter en kort stund, så att den inte försvinner av misstag).

var find: Dictionary = {}
var _t := 0.0
var _data: Dictionary


func _ready() -> void:
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_data = get_node("/root/Run").data


func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size  # i en CanvasLayer finns ingen förälder att fylla
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _t > 0.8:
		get_viewport().set_input_as_handled()
		get_parent().queue_free()


func _draw() -> void:
	if find.is_empty():
		return
	var w := size.x
	var h := size.y
	var a := clampf(_t / 0.5, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.82 * a))
	var color := Forge.find_color(_data, find)
	var c := Vector2(w / 2.0, h * 0.36)
	# Strålar.
	var grow := clampf((_t - 0.2) / 0.8, 0.0, 1.0)
	for i in 12:
		var ang := _t * 0.4 + TAU * i / 12.0
		var p1 := c + Vector2(cos(ang - 0.08), sin(ang - 0.08)) * 420.0 * grow
		var p2 := c + Vector2(cos(ang + 0.08), sin(ang + 0.08)) * 420.0 * grow
		draw_colored_polygon(PackedVector2Array([c, p1, p2]), Color(color, 0.10 * a))
	var pop := 1.0 + 0.25 * maxf(0.0, 1.0 - absf(_t - 0.6) * 4.0)
	GemArt.draw_find(self, _data, find, c, 70.0 * pop * grow + 1.0, _t)
	var title := "SÄLLSYNT FYND!" if find.kind != "nether" or find.stone.rarity != "legendary" else "LEGENDARISKT FYND!"
	UiStyle.text(self, Vector2(0, h * 0.36 + 125), title, 40, Color(color, a), HORIZONTAL_ALIGNMENT_CENTER, w, 8)
	UiStyle.text(self, Vector2(0, h * 0.36 + 165), Forge.find_text(_data, find), 22, Color(1, 1, 1, a),
			HORIZONTAL_ALIGNMENT_CENTER, w, 5)
	if find.kind == "nether":
		var lines := Forge.stone_lines(_data, find.stone)
		for i in lines.size():
			var la := clampf((_t - 1.0 - i * 0.35) / 0.3, 0.0, 1.0)
			UiStyle.text(self, Vector2(0, h * 0.36 + 205 + i * 28), lines[i], 18, Color(color.lightened(0.3), la),
					HORIZONTAL_ALIGNMENT_CENTER, w, 4)
		UiStyle.text(self, Vector2(0, h - 56), "Sätts i artefaktens Nether-plats hos Smeden (nivå %d)" % Forge.NETHER_LEVEL,
				15, Color(1, 1, 1, 0.6 * a), HORIZONTAL_ALIGNMENT_CENTER, w, 3)
	if _t > 0.8:
		UiStyle.text(self, Vector2(0, h - 22), "Tryck för att fortsätta", 18, Color(1, 1, 1, 0.6 + 0.4 * sin(_t * 4.0)),
				HORIZONTAL_ALIGNMENT_CENTER, w, 4)
