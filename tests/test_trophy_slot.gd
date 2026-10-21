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
	p.wear("paladin", "rosary")
	assert_eq(p.artifact("brokk").trophy, "", "att bära den tar den ur artefakten")
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
