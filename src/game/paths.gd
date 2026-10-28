class_name Paths
extends RefCounted
## Paladinens inriktningar (docs/plan/paladin-inriktningar.md, VD 2026-10-28): Sköldbäraren (tank) och Ljusbäraren
## (helare), data/paths.json. Inriktningen är vad paladinen är (stats, förmågor, kärna och Glöd); kallet är ett eget val.
## Väljs vid eden, byts hos Gorm: det första bytet är gratis, sedan BYTE_COST silver. Utan inriktning är paladinen som
## förut ("Den edsvurne"), så gamla profiler förlorar ingenting.

const IDS := ["shield", "light"]
const BYTE_COST := 50

## Paladinens egna värden ur heroes.json, så att en inriktning kan tas bort eller bytas utan att något blir kvar.
static var _base := {}


static func valid(data: Dictionary, path_id: String) -> bool:
	return data.get("paths", {}).has(path_id) and path_id in IDS


static func path_name(data: Dictionary, path_id: String) -> String:
	return String(data.get("paths", {}).get(path_id, {}).get("name", "Den edsvurne"))


## Vad bytet kostar: inget första gången (och inget när man väljer för första gången), sedan BYTE_COST.
static func cost(current: String, changes: int) -> int:
	return 0 if current == "" or changes == 0 else BYTE_COST


## Ger paladinen inriktningens stats, förmågor och egenskaper i datan (striden, botarna, hjältebladet). "" = som förut.
## path_traits läses av RunState.hero_traits; traits (hjältens egna) läses av botarna.
static func apply(data: Dictionary, path_id: String) -> void:
	var pal: Dictionary = data.heroes.paladin
	if _base.is_empty():
		var src: Dictionary = GameData._load_json("res://data/heroes.json").paladin
		_base = {"stats": src.stats.duplicate(), "abilities": src.abilities.duplicate(), "traits": src.traits.duplicate()}
	pal.stats = _base.stats.duplicate()
	pal.abilities = _base.abilities.duplicate()
	pal.traits = _base.traits.duplicate()
	pal.erase("path_traits")
	pal.erase("path")
	if not valid(data, path_id):
		return
	var p: Dictionary = data.paths[path_id]
	pal.stats = p.stats.duplicate()
	pal.abilities = p.abilities.duplicate()
	pal.path_traits = p.traits.duplicate()
	pal.traits = _base.traits + p.traits
	pal.path = path_id


## Startraderna eden ger (Gambits: färdiga rader), som {line, hero, block}.
static func rows(data: Dictionary, path_id: String) -> Array:
	var out := []
	if not valid(data, path_id):
		return out
	for l in data.paths[path_id].get("rows", []):
		out.append({"line": l.duplicate(true), "hero": "paladin", "block": ""})
	return out
