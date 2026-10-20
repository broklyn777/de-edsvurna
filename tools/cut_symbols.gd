extends SceneTree
## Klipper ut symbolerna ur VD:ns bilder (symbolarket och enskilda bilder som skelettet) till egna
## PNG:er med transparent bakgrund (0.18.2). Källorna, papperets provpunkter och rutorna står i
## tools/symbolark.json, så skriptet kan köras om när en ny bild kommer:
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
	var images := {}
	var papers := {}
	for id in cfg.sources:
		var img := Image.load_from_file(ProjectSettings.globalize_path(cfg.sources[id].path))
		img.convert(Image.FORMAT_RGBA8)
		images[id] = img
		papers[id] = _paper_luminance(img, cfg.sources[id].paper)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cfg.out))
	for name in cfg.symbols:
		var entry: Variant = cfg.symbols[name]
		var source: String = entry.source if entry is Dictionary else "ark"
		var r: Array = entry.rect if entry is Dictionary else entry
		var paper: float = papers[source]
		var img: Image = images[source].get_region(Rect2i(r[0], r[1], r[2], r[3]))
		# 0.24: porträtten behåller pergamentet ("opaque") och hamnar i en egen mapp ("out").
		var opaque: bool = entry is Dictionary and entry.get("opaque", false)
		for y in (0 if opaque else img.get_height()):
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var dark := (paper - c.get_luminance()) / paper
				var a := clampf((dark - START) / (FULL - START), 0.0, 1.0)
				var edge := minf(minf(x, img.get_width() - 1 - x), minf(y, img.get_height() - 1 - y))
				a *= clampf(edge / EDGE, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r * 0.85, c.g * 0.8, c.b * 0.75, a))
		if entry is Dictionary and entry.has("height"):
			var h := int(entry.height)
			img.resize(int(img.get_width() * float(h) / img.get_height()), h, Image.INTERPOLATE_LANCZOS)
		var out_dir: String = entry.get("out", cfg.out) if entry is Dictionary else cfg.out
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
		var path := ProjectSettings.globalize_path(out_dir + name + ".png")
		img.save_png(path)
		print("%s → %s (%d×%d)" % [name, path.get_file(), r[2], r[3]])
	quit()


## Papperets ljusstyrka: medianen av några fläckar på bilden där det bara finns papper.
func _paper_luminance(img: Image, points: Array) -> float:
	var samples: Array[float] = []
	for p in points:
		samples.append(img.get_pixel(int(p[0]), int(p[1])).get_luminance())
	samples.sort()
	return samples[samples.size() / 2]
