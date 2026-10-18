extends Node2D
## Platshållare tills den första striden finns.


func _ready() -> void:
	var label := Label.new()
	label.text = "rpg007\nDen första striden kommer här."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.position = Vector2(0, 280)
	label.size = Vector2(1280, 160)
	add_child(label)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.08, 0.07, 0.10))
