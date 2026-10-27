extends "res://tests/test_case.gd"
## Troféplatsen i artefakten (trofeplats, Siralims Artifact Trait Slot): öppnas på nivå 6, trofén kommer ur samlingen och
## går tillbaka dit, samma trofé sitter bara på ett ställe, och striden ger hjälten egenskapen.

var _data := GameData.load_all()


func _profile(level := Forge.TROPHY_LEVEL) -> Profile:
	var p := Profile.new()
	p.silver = 10000
	p.forge("brokk", "sword", "")
	p.artifacts.brokk.level = level
	for t in ["bone_finger", "rosary", "mold_jaw"]:
		p.add_trophy(t)
	return p


func test_slot_opens_at_level_six() -> void:
	assert_eq(Forge.unlock_text(Forge.TROPHY_LEVEL), "Troféplats")
	var p := _profile(Forge.TROPHY_LEVEL - 1)
	assert_true(not p.set_artifact_trophy("brokk", "rosary"), "stängd under nivå 6")
	p.artifacts.brokk.level = Forge.TROPHY_LEVEL
	assert_true(p.set_artifact_trophy("brokk", "rosary"))
	assert_eq(p.artifact("brokk").trophy, "rosary")


func test_only_trophies_from_the_collection() -> void:
	var p := _profile()
	assert_true(not p.set_artifact_trophy("brokk", "colossus_spine"), "inte i samlingen")


func test_taking_out_keeps_it_in_the_collection() -> void:
	var p := _profile()
	p.set_artifact_trophy("brokk", "rosary")
	assert_true(p.set_artifact_trophy("brokk", ""))
	assert_eq(p.artifact("brokk").trophy, "")
	assert_true(p.collection.has("rosary"), "förstörs inte")


func test_one_place_at_a_time_so_never_twice_on_a_hero() -> void:
	var p := _profile()
	p.wear("brokk", "rosary")
	p.set_artifact_trophy("brokk", "rosary")
	assert_true(not p.worn.has("brokk"), "togs av när den sattes i artefakten: ingen dubblett på Brokk")
	assert_true(not p.wear("paladin", "rosary"), "0.30.48: en trofé i en artefakt går inte att bära")
	assert_eq(p.artifact("brokk").trophy, "rosary", "den sitter kvar i artefakten tills den tas ut hos Smeden")
	assert_true(not p.worn.has("paladin"))
	p.forge("alva", "staff", "")
	p.artifacts.alva.level = Forge.TROPHY_LEVEL
	p.set_artifact_trophy("brokk", "mold_jaw")
	p.set_artifact_trophy("alva", "mold_jaw")
	assert_eq(p.artifact("brokk").trophy, "", "flyttas mellan artefakter")
	assert_eq(p.artifact_trophy_owner("mold_jaw"), "alva")


func test_the_battle_gives_the_hero_the_trait() -> void:
	var p := _profile()
	p.set_artifact_trophy("brokk", "rosary")
	var sim := CombatSim.create(_data, "crypt_1", 3, ["paladin", "brokk"], {}, {}, {"brokk": p.artifact("brokk")})
	assert_true(sim.unit("brokk").traits.has("rosary"))
	p.artifacts.brokk.level = Forge.TROPHY_LEVEL - 1
	sim = CombatSim.create(_data, "crypt_1", 3, ["paladin", "brokk"], {}, {}, {"brokk": p.artifact("brokk")})
	assert_true(not sim.unit("brokk").traits.has("rosary"), "en stängd plats ger inget")


func test_run_does_not_let_the_artifact_trophy_be_worn_too() -> void:
	var p := _profile()
	p.party = ["paladin", "brokk"]
	p.set_artifact_trophy("brokk", "rosary")
	var s := RunState.new_run(p, _data)
	s.take_trophy("rosary")
	s.equip("paladin", "rosary")
	assert_true(not s.equipped.has("paladin"), "trofén sitter redan i Brokks artefakt")


## trofeplats: varje trofé säger vilken händelse den behöver, vad den skapar och vem den gäller (docs/plan/trofeplats.md).
func test_every_trophy_has_a_combo_entry() -> void:
	for id in _data.traits:
		var t: Dictionary = _data.traits[id]
		if not t.get("trophy", false):
			continue
		var c: Dictionary = t.get("combo", {})
		for key in ["needs", "creates", "scope"]:
			assert_true(String(c.get(key, "")) != "", "%s saknar combo.%s" % [id, key])
		assert_true(["self", "party", "enemy", "enemies"].has(c.get("scope", "")), "%s: okänd scope" % id)



## VD 2026-10-23 (regel 2): varje trofé har en lärdom, och {bärare} blir hjältens namn (annars "Bäraren").
func test_every_trophy_has_a_lesson() -> void:
	var ids := {}
	for id in _data.traits:
		if _data.traits[id].get("trophy", false):
			ids[id] = true
	for kind in _data.enemies:
		var d: Dictionary = _data.enemies[kind]
		for t in [d.get("trophy", ""), d.get("elite", {}).get("trophy", "")]:
			if t != "":
				ids[t] = true
	for id in ids:
		var lesson: String = _data.traits[id].get("lesson", "")
		assert_true(lesson.length() > 20, "%s saknar lärdom" % id)
		assert_true(lesson.contains("{bärare}"), "%s: lärdomen nämner bäraren" % id)
	assert_true(GameData.lesson(_data, "bone_finger", "Brokk").contains("Brokk har lärt sig"))
	assert_true(GameData.lesson(_data, "bone_finger").contains("Bäraren har lärt sig"))
	assert_eq(GameData.lesson(_data, "no_such_trophy"), "")
