class_name PartyOverview
extends RefCounted
## Sällskapet från borgen (polering fynd 1, VD 2026-10-27): ren logik bakom översikten (party_screen), så att den
## går att testa utan noder. Hjältarna med nivå, trofé och artefakt; samlingen med var varje trofé sitter.

const RARITY_ORDER := {"boss": 0, "elite": 1, "common": 2}
const RARITY_TAG := {"boss": "BOSS", "elite": "ELIT", "common": "VANLIG"}


## Paladinen och alla som har anslutit, i den ordningen.
static func heroes(profile: Profile) -> Array:
	return ["paladin"] + Array(profile.recruited)


## En hjältes rad i översikten: {id, name, short, level, with (med i sällskapet), trophy ("" = tom plats), art_type, art_name,
## art_level, art_trophy, slot ("open", "locked" eller "none" utan artefakt)}.
static func hero_row(data: Dictionary, profile: Profile, hero_id: String) -> Dictionary:
	var prog: Dictionary = profile.hero(data, hero_id)
	var art := profile.artifact(hero_id)
	var row := {
		"id": hero_id,
		"name": String(data.heroes[hero_id].name),
		"short": String(data.heroes[hero_id].get("short", data.heroes[hero_id].name)),
		"level": int(prog.get("level", 1)),
		"with": hero_id == "paladin" or profile.party.has(hero_id),
		"trophy": String(profile.worn.get(hero_id, "")),
		"art_type": "", "art_name": "", "art_level": 0, "art_trophy": "", "slot": "none",
	}
	if not art.is_empty():
		row.art_type = String(art.type)
		row.art_name = String(data.get("artifacts", {}).get(String(art.type), {}).get("name", "Artefakt"))
		row.art_level = int(art.level)
		row.art_trophy = String(art.get("trophy", ""))
		row.slot = "open" if Forge.trophy_open(int(art.level)) else "locked"
	return row


## Troféns sällsynthet ("boss", "elite" eller "common"); väktarnas troféer räknas som boss.
static func rarity(data: Dictionary, trophy_id: String) -> String:
	var r := String(data.traits.get(trophy_id, {}).get("rarity", "common"))
	if r == "common" and RunState.is_rare_trophy(data, trophy_id):
		return "boss"
	return r if RARITY_ORDER.has(r) else "common"


## Samlingen sorterad efter det som spelar roll: först de som bärs eller sitter i en artefakt, sedan sällsynthet (boss,
## elit, vanlig), sist namnet. [{id, name, place ("" = ledig), rarity}]
static func collection(data: Dictionary, profile: Profile) -> Array:
	var out := []
	for t in profile.collection:
		if not data.traits.has(t):
			continue
		out.append({"id": t, "name": String(data.traits[t].name), "rarity": rarity(data, t),
				"place": Profile.trophy_place(data, profile.worn, profile.artifacts, t)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: bool = a.place != ""
		var pb: bool = b.place != ""
		if pa != pb:
			return pa
		if a.rarity != b.rarity:
			return RARITY_ORDER[a.rarity] < RARITY_ORDER[b.rarity]
		return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	return out
