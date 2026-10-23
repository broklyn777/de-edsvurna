class_name GameData
extends RefCounted
## Läser speldata (förmågor, auror, hjältar, fiender, möten, egenskaper, artefakter) från data/*.json.

const FILES := ["abilities", "auras", "heroes", "enemies", "encounters", "traits", "macros", "artifacts", "oaths", "realms", "floor_rules", "personalities", "materials", "intro", "dialog", "keep", "help", "objects", "vows", "titles", "world_events"]


static func load_all() -> Dictionary:
	var result := {}
	for file in FILES:
		result[file] = _load_json("res://data/%s.json" % file)
	return result


static func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Kunde inte läsa " + path)
	return parsed


## Troféns lärdom (VD 2026-10-23, regel 2): vad bäraren lärde sig av fienden. "{bärare}" blir hjältens namn, annars
## "Bäraren". Tom sträng om trofén saknar lärdom.
static func lesson(data: Dictionary, trophy_id: String, bearer := "") -> String:
	var text: String = data.get("traits", {}).get(trophy_id, {}).get("lesson", "")
	return text.replace("{bärare}", bearer if bearer != "" else "Bäraren")
