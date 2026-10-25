extends "res://tests/test_case.gd"
## 0.30.25: startmakronas kedjor ("pröva nästa rad" + raden den leder till) hålls ihop (Run.starter_lines), och Alvas
## helning prövar den skadade först (MacroRunner håller fast vid figuren som kedjans första rad valde).

var _data := GameData.load_all()
var _run: Script = load("res://scripts/game/run.gd")


## Skriver ut varje följeslagares startmakro (en ny profil) så att det går att läsa i testutskriften.
func test_print_every_starter_macro() -> void:
	for id in _data.macros:
		var lines: Array = _run.starter_lines(_data, id, _data.macros[id].lines)
		print("  startmakro %s:" % id)
		for i in lines.size():
			print("    %d. %s" % [i + 1, MacroRunner.describe_line(_data, lines[i])])
		assert_true(not lines.is_empty(), "%s har startrader" % id)


## Ingen startrad "pröva nästa rad" hänger löst eller leder till reservanfallet: varje kedja i startmakrot finns hel i mallen.
func test_no_starter_chain_ends_on_the_fallback() -> void:
	for id in _data.macros:
		var template: Array = _data.macros[id].lines
		var units: Array = _run.macro_units(template)
		var lines: Array = _run.starter_lines(_data, id, template)
		assert_true(lines.is_empty() or lines[-1].action != "test_next", "%s slutar inte med pröva nästa rad" % id)
		for unit in _run.macro_units(lines):
			if unit.size() > 1:
				assert_true(units.has(unit), "%s: kedjan %s finns hel i mallen" % [id, unit.map(func(l: Dictionary) -> String:
						return MacroRunner.describe_line(_data, l))])
				assert_true(not _run._is_fallback(unit[-1]), "%s: en kedja slutar inte på reservanfallet" % id)
		# Mallen själv: ingen kedja leder till ett anfall som nästan alltid passar.
		for unit in units:
			if unit.size() > 1:
				assert_true(not _run._is_fallback(unit[-1]), "%s: mallens kedja slutar inte på reservanfallet" % id)


func test_lirien_keeps_his_lullaby_chain() -> void:
	var lines: Array = _run.starter_lines(_data, "lirien", _data.macros.lirien.lines)
	var i := -1
	for k in lines.size():
		if lines[k].action == "test_next":
			i = k
			break
	assert_true(i >= 0, "kedjan finns kvar")
	assert_eq(lines[i + 1].get("ability", ""), "lullaby", "liv < 50 % leder till Vaggvisa, inte till anfallet")


func test_macro_units_drop_a_dangling_chain() -> void:
	var tn := {"subject": "any_ally", "cond": "hp_below", "value": 50, "action": "test_next"}
	var hit := {"subject": "any_enemy", "cond": "lowest_hp", "action": "attack", "target": "that"}
	assert_eq(_run.macro_units([hit, tn, hit, tn]), [[hit], [tn, hit]])


## Fel 2 i ChatGPT:s provspel 4: Arn fullfrisk utan Läkning, Imma skadad. Alvas kedja ska hela Imma.
func test_alva_heals_the_wounded_not_the_first_without_mending() -> void:
	var sim := CombatSim.create(_data, "crypt_1", 3, ["paladin", "imma", "alva"])
	var imma := sim.unit("imma")
	imma.hp = imma.max_hp * 0.5
	var alva := sim.unit("alva")
	var macro := {"lines": _data.macros.alva.lines.filter(func(l: Dictionary) -> bool:
			return l.get("ability", "") != "healing_light")}
	var d := MacroRunner.decide(sim, alva, macro)
	assert_true(d.ok, "något passar")
	assert_eq(d.get("ability", ""), "renew", "Läkande hand")
	assert_eq(str(d.get("target")), "imma", "på den skadade Imma")
	assert_true(String(d.get("text", "")).contains("Kedjan prövade bara"), "förklaringen säger att kedjan håller fast vid figuren")
	assert_true(MacroRunner.describe_line(_data, macro.lines[0]).ends_with("pröva nästa rad med den"), "radens text")
