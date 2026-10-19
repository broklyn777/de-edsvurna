extends SceneTree
## Klipper ut symbolerna ur VD:ns symbolark till egna PNG:er med transparent bakgrund (0.18.2).
## Koordinaterna står i tools/symbolark.json, så skriptet kan köras om med ett nytt ark:
##   godot --headless --path . --script res://tools/cut_symbols.gd
## Pergamentet görs genomskinligt med en luminansmask: ju mörkare än papperet, desto mer bläck.
## Färgen blir bläckets egen, så symbolerna kan ritas ovanpå kartans pergament.

const CONFIG := "res://tools/symbolark.json"
## Mjuk tröskel: så här mycket mörkare än papperet ett streck måste vara för att synas, och när det
## är helt täckande (andelar av papperets luminans).
const START := 0.06
const FULL := 0.45
## Kanten tonas ut några pixlar så att inga bitar av grannsymbolerna syns.
const EDGE := 6.0


func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(cfg.source))
	sheet.convert(Image.FORMAT_RGBA8)
	var paper := _paper_luminance(sheet)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cfg.out))
	for name in cfg.symbols:
		var r: Array = cfg.symbols[name]
		var img := sheet.get_region(Rect2i(r[0], r[1], r[2], r[3]))
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var dark := (paper - c.get_luminance()) / paper
				var a := clampf((dark - START) / (FULL - START), 0.0, 1.0)
				var edge := minf(minf(x, img.get_width() - 1 - x), minf(y, img.get_height() - 1 - y))
				a *= clampf(edge / EDGE, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r * 0.85, c.g * 0.8, c.b * 0.75, a))
		var path := ProjectSettings.globalize_path(cfg.out + name + ".png")
		img.save_png(path)
		print("%s → %s (%d×%d)" % [name, path.get_file(), r[2], r[3]])
	quit()


## Papperets ljusstyrka: medianen av några fläckar i arkets marginal.
func _paper_luminance(img: Image) -> float:
	var samples: Array[float] = []
	for p in [Vector2i(8, 600), Vector2i(img.get_width() - 8, 600), Vector2i(img.get_width() / 2, 800),
			Vector2i(250, 1010), Vector2i(1300, 1010), Vector2i(760, 600)]:
		samples.append(img.get_pixelv(p).get_luminance())
	samples.sort()
	return samples[samples.size() / 2]
