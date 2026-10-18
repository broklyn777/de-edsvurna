class_name GameData
extends RefCounted
## Läser speldata (förmågor, auror, hjältar, fiender, möten, egenskaper) från data/*.json.

const FILES := ["abilities", "auras", "heroes", "enemies", "encounters", "traits", "macros"]


static func load_all() -> Dictionary:
	var result := {}
	for file in FILES:
		result[file] = _load_json("res://data/%s.json" % file)
	return result


static func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Kunde inte läsa " + path)
	return parsed
