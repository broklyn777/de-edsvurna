extends SceneTree
## Paladinens inriktningar i botarna (docs/plan/paladin-inriktningar.md): hela nedstigningar som balanssimuleringen
## (väntad nivå, en ny profils makron med makroförslagen, SIM_GEAR, MACRO, enkel väg) med dagens paladin, Sköldbäraren
## och Ljusbäraren. Inriktningen kommer ur spelets data (Paths.apply) och paladinen får edens startrader överst.
##   godot --headless --path . --script res://tests/paladin_paths_report.gd
## KORNINGAR=n (förval 100), PP_REALM=crypt,chapel, PP_DJUP=1,3, PP_NIVA=-1 (nivån mot den väntade), PP_LAG=standard|utan_alva,
## PP_BEFAL=1 (Befäl som andra rad), PP_VARIANT=idag,shield,light, PP_KALL=oath_dawn (paladinens kall i botarna, förval Domens kall), PP_MAKRO=fulla (följeslagarna
## kör sina fulla startmakron ur data/macros.json, som en profil som har hittat sina rader; paladinen har alltid bara
## edens rader och Gorms rad, så att jämförelsen gäller inriktningen).

const Bot := preload("res://tests/combat_bot.gd")
const Report := preload("res://tests/balance_report.gd")
const PARTIES := {"standard": ["paladin", "brokk", "alva", "eira"], "utan_alva": ["paladin", "brokk", "imma", "eira"]}


func _init() -> void:
	var runs := int(OS.get_environment("KORNINGAR")) if OS.get_environment("KORNINGAR") != "" else 100
	var realms := _list("PP_REALM", ["crypt", "chapel"])
	var depths := _list("PP_DJUP", ["1", "3"]).map(func(d: String) -> int: return int(d))
	var variants := _list("PP_VARIANT", ["idag", "shield", "light"])
	var party: Array = PARTIES[OS.get_environment("PP_LAG") if OS.get_environment("PP_LAG") != "" else "standard"]
	var lv_off := int(OS.get_environment("PP_NIVA"))
	print("=== Paladinens inriktningar: lag %s, %d nedstigningar per rad, nivå %+d mot väntad ===" % [",".join(party), runs, lv_off])
	for realm_id in realms:
		for depth in depths:
			for v in variants:
				var data := GameData.load_all()
				Paths.apply(data, "" if v == "idag" else v)
				if OS.get_environment("PP_KALL") != "":
					data.heroes.paladin.traits[0] = OS.get_environment("PP_KALL")
				var macros := Report.sim_macros(data, party)
				if OS.get_environment("PP_MAKRO") == "fulla":
					var gorm: Array = macros.paladin.lines
					macros = data.macros.duplicate(true)
					macros.paladin.lines = gorm
				var lines: Array = []
				for row in Paths.rows(data, "" if v == "idag" else v):
					lines.append(row.line)
				# PP_BEFAL=1: Befäl på den allierade med högst Attack som andra rad (Befäl mäts för sig; edens rader har det inte).
				if OS.get_environment("PP_BEFAL") == "1" and v != "idag":
					lines.insert(mini(1, lines.size()), {"subject": "any_ally", "cond": "highest_attack", "action": "ability",
							"ability": "pal_command", "target": "that"})
				lines.append_array(macros.paladin.lines)
				macros.paladin.lines = lines
				var r := _descents(data, realm_id, depth, party, macros, runs, lv_off)
				print("%-7s %-7s djup %d nivå %d  vinst %3d %%  stupat %3d %%  %s" % [v, realm_id, depth, r.level, r.win, r.died, r.kinds])
	quit()


func _list(env: String, fallback: Array) -> Array:
	return Array(OS.get_environment(env).split(",")) if OS.get_environment(env) != "" else fallback


func _descents(data: Dictionary, realm_id: String, depth: int, party: Array, macros: Dictionary, runs: int, lv_off: int) -> Dictionary:
	var lv := Report.sim_expected_level(data, realm_id, depth) + lv_off
	var gear := Report.sim_gear(data, party, depth)
	var cleared := 0
	var died := 0
	var kinds := {}
	for seed_value in range(1, runs + 1):
		var log := []
		var opts := {"levels": Bot.party_levels(data, lv, party), "grow": true, "party": party.duplicate(),
				"bot_macros": macros, "owned": party.size(), "slots": maxi(party.size(), Profile.BASE_SLOTS), "fight_log": log}
		var r := Bot.run_expedition(data, seed_value, Bot.Skill.MACRO, gear.traits, gear.artifacts, depth, realm_id, opts, "simple")
		cleared += 1 if r.cleared else 0
		var any_death := false
		for f in log:
			any_death = any_death or int(f.deaths) > 0
			var a: Array = kinds.get(f.type, [0, 0])
			kinds[f.type] = [int(a[0]) + (1 if f.outcome == "victory" else 0), int(a[1]) + 1]
		died += 1 if any_death else 0
	var bits := []
	for k in ["elit", "nemesis", "väktare", "boss"]:
		if kinds.has(k):
			bits.append("%s %d/%d" % [k, kinds[k][0], kinds[k][1]])
	return {"level": lv, "win": roundi(100.0 * cleared / runs), "died": roundi(100.0 * died / runs), "kinds": ", ".join(bits)}
