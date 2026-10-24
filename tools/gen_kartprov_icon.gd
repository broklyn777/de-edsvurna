extends SceneTree
## Kartprov: ritar appikonen (assets/icons/kartprov_icon.svg, turkos i stället för spelets lila) till PNG för exporten
## "Android Kartprov": 192×192 och de adaptiva lagren 432×432.
##   godot --headless --path . --script res://tools/gen_kartprov_icon.gd

func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/icons/kartprov_icon.svg")
	var main := Image.new()
	main.load_svg_from_string(svg, 192.0 / 256.0)
	main.save_png("res://assets/icons/kartprov_192.png")
	# Adaptiv förgrund: ikonen i mitten (säker zon), resten genomskinligt; bakgrunden enfärgad.
	var small := Image.new()
	small.load_svg_from_string(svg, 432.0 * 0.62 / 256.0)
	var fg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	small.convert(Image.FORMAT_RGBA8)
	fg.blit_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), (Vector2i(432, 432) - small.get_size()) / 2)
	fg.save_png("res://assets/icons/kartprov_fg_432.png")
	var bg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(Color("#0b2a2b"))
	bg.save_png("res://assets/icons/kartprov_bg_432.png")
	print("klart: ", main.get_size(), " ", fg.get_size())
	quit()
