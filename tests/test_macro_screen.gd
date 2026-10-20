extends "res://tests/test_case.gd"
## 0.23.2: makroskärmen i en ny profil – bara Paladinen och de som har anslutit, och ett tomt makro med en
## föreslagen första rad som klarar introts steg.

var _data := GameData.load_all()


func _run(profile: Profile) -> Node:
	var r: Node = load("res://scripts/game/run.gd").new()
	r.data = _data
	r.profile = profile
	r.dev_profile = true
	r._load_macros(true)
	return r


func test_a_new_profile_lists_only_its_own_heroes() -> void:
	var p := Profile.new()
	var r := _run(p)
	assert_eq(r.macro_heroes(), ["paladin"], "bara Paladinen innan Imma ansluter")
	assert_true(r.macros.paladin.lines.is_empty(), "Paladinens första rad skriver man själv i introt")
	p.recruit(_data, "imma")
	assert_eq(r.macro_heroes(), ["paladin", "imma"])
	r.free()


func test_the_suggested_line_attacks_the_weakest_enemy_and_ends_the_intro_step() -> void:
	var line: Dictionary = load("res://scripts/game/run.gd").FIRST_LINE
	assert_eq(MacroRunner.describe_line(_data, line), "Om någon fiende har lägst liv → Anfall på den som matchade")
	var sim := CombatSim.create(_data, "crypt_1", 1, ["paladin"], {}, {}, {}, 1, {"elite_chance": 0.0})
	sim.enemies[1].hp = 1.0
	var d := MacroRunner.decide(sim, sim.unit("paladin"), {"name": "Paladinen", "lines": [line.duplicate(true)]})
	assert_eq(d.get("action", ""), "attack")
	assert_eq(d.get("target", ""), sim.enemies[1].id, "den svagaste fienden")
	var p := Profile.new()
	while Intro.current(_data, p).get("id", "") != "macro":
		p.intro_step += 1
	p.intro_talked = true  # 0.24: Hedda har gett uppdraget
	assert_true(not Intro.notify(_data, p, "macro_line").is_empty(), "raden klarar steget")


func test_alva_teaches_a_condition_when_she_joins() -> void:
	var r := _run(Profile.new())
	var hint: Dictionary = r.macro_hint("alva")
	assert_true(not hint.is_empty(), "förslaget visas i en ny profil: hennes startrader saknar helningen")
	assert_eq(hint.line.cond, "hp_below", "ett villkor: lågt liv")
	assert_true(r.macros.alva.lines.size() >= 1, "hon har ändå något att göra")
	r.free()
