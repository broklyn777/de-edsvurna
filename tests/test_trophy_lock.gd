extends "res://tests/test_case.gd"
## Trofélåset (0.30.48, fynd 13 i docs/plan/polering.md): en trofé i en artefakt sitter kvar tills den tas ut hos Smeden,
## rutorna visar var en trofé sitter, och att ta en trofé från en annan hjälte kräver en fråga.

var _data := GameData.load_all()


func _profile() -> Profile:
	var p := Profile.new()
	p.silver = 10000
	p.forge("brokk", "helm", "")
	p.artifacts.brokk.level = Forge.TROPHY_LEVEL
	for t in ["bone_finger", "rosary", "mold_jaw"]:
		p.add_trophy(t)
	return p


func test_artifact_trophy_is_locked() -> void:
	var p := _profile()
	assert_true(p.set_artifact_trophy("brokk", "rosary"))
	assert_true(not p.wear("eira", "rosary"), "går inte att ge till en hjälte")
	assert_eq(p.artifact("brokk").trophy, "rosary", "sitter kvar i hjälmen")
	assert_true(not p.worn.has("eira"))
	assert_true(p.set_artifact_trophy("brokk", ""), "Smeden tar ut den")
	assert_true(p.wear("eira", "rosary"), "sedan går den att bära")
	assert_eq(p.worn.eira, "rosary")


func test_run_equip_respects_the_lock() -> void:
	var p := _profile()
	p.set_artifact_trophy("brokk", "rosary")
	var state := RunState.new()
	state.artifacts = p.artifacts
	state.equip("eira", "rosary")
	assert_true(not state.equipped.has("eira"), "inte heller vid lägerelden")


func test_place_label() -> void:
	var p := _profile()
	assert_eq(p.trophy_label(_data, "rosary"), "", "ledig trofé")
	p.set_artifact_trophy("brokk", "rosary")
	var helm := String(_data.artifacts.helm.name).to_lower()
	assert_eq(p.trophy_label(_data, "rosary"), "I %ss %s" % [_data.heroes.brokk.name, helm])
	p.wear("alva", "bone_finger")
	assert_eq(p.trophy_label(_data, "bone_finger"), "Bärs av %s" % _data.heroes.alva.name)
	assert_eq(Profile.trophy_place(_data, {"eira": "mold_jaw"}, {}, "mold_jaw"), "Bärs av %s" % _data.heroes.eira.name,
			"körningens equipped fungerar lika")


func test_possessive() -> void:
	assert_eq(Profile.possessive("Brokk"), "Brokks")
	assert_eq(Profile.possessive("Imma"), "Immas")
	assert_eq(Profile.possessive("Tobias"), "Tobias")


func test_move_question() -> void:
	var p := _profile()
	assert_eq(Profile.move_question(_data, p.worn, p.artifacts, "eira", "bone_finger"), "", "ledig: ingen fråga")
	p.wear("brokk", "bone_finger")
	assert_eq(Profile.move_question(_data, p.worn, p.artifacts, "brokk", "bone_finger"), "", "samma hjälte: ingen fråga")
	assert_eq(Profile.move_question(_data, p.worn, p.artifacts, "eira", ""), "", "ta av: ingen fråga")
	assert_eq(Profile.move_question(_data, p.worn, p.artifacts, "eira", "bone_finger"),
			"Flytta %s från %s till %s?" % [_data.traits.bone_finger.name, _data.heroes.brokk.name, _data.heroes.eira.name])
	p.set_artifact_trophy("brokk", "rosary")
	assert_eq(Profile.move_question(_data, p.worn, p.artifacts, "eira", "rosary"), "", "artefakttrofén flyttas inte alls")
