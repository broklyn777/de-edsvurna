extends "res://tests/test_case.gd"
## Sällskapet från borgen (polering fynd 1): hjältarnas rader och samlingen sorterad med de burna först.

var _data := GameData.load_all()


func _profile() -> Profile:
	var p := Profile.new()
	p.silver = 10000
	p.recruited.assign(["imma", "brokk"])
	p.set_party(["imma"])
	p.forge("brokk", "helm", "")
	p.artifacts.brokk.level = Forge.TROPHY_LEVEL
	for t in ["bone_finger", "rosary", "mold_jaw", "bishop_mitre"]:
		p.add_trophy(t)
	return p


func test_heroes_are_paladin_and_recruited() -> void:
	assert_eq(PartyOverview.heroes(_profile()), ["paladin", "imma", "brokk"])


func test_hero_row() -> void:
	var p := _profile()
	p.wear("imma", "mold_jaw")
	p.set_artifact_trophy("brokk", "rosary")
	var imma := PartyOverview.hero_row(_data, p, "imma")
	assert_true(imma.with, "Imma är med")
	assert_eq(imma.trophy, "mold_jaw")
	assert_eq(imma.slot, "none", "ingen artefakt")
	var brokk := PartyOverview.hero_row(_data, p, "brokk")
	assert_true(not brokk.with, "Brokk bor i värdshuset")
	assert_eq(brokk.trophy, "", "tom plats")
	assert_eq(brokk.slot, "open")
	assert_eq(brokk.art_trophy, "rosary")
	assert_eq(brokk.art_name, "Hjälm")


func test_locked_slot_below_trophy_level() -> void:
	var p := _profile()
	p.artifacts.brokk.level = Forge.TROPHY_LEVEL - 1
	assert_eq(PartyOverview.hero_row(_data, p, "brokk").slot, "locked")


func test_collection_worn_first_then_rarity() -> void:
	var p := _profile()
	p.wear("imma", "mold_jaw")
	p.set_artifact_trophy("brokk", "rosary")
	var ids := PartyOverview.collection(_data, p).map(func(e: Dictionary) -> String: return e.id)
	assert_eq(ids.size(), 4)
	assert_true(ids.slice(0, 2).has("mold_jaw") and ids.slice(0, 2).has("rosary"), "de som sitter på någon först")
	assert_eq(ids[2], "bishop_mitre", "sedan bossens trofé före den vanliga")
	assert_eq(ids[3], "bone_finger")
	var first: Dictionary = PartyOverview.collection(_data, p).filter(func(e: Dictionary) -> bool: return e.id == "rosary")[0]
	assert_eq(first.place, "I Brokks hjälm")
