extends SceneTree
## 0.31 (docs/plan/spindlar.md): vinst per möte i en Realm, en strid med fulla Charges, fyra hjältar på väntad nivå
## för våningen (djup 1), startmakrona. Visar vilka grupper som bär svårigheten.
##   DIAG_REALM=grove godot --headless --path . --script res://tests/spider_diag.gd
const Bot := preload("res://tests/combat_bot.gd")


func _init() -> void:
	var data := GameData.load_all()
	var realm_id := OS.get_environment("DIAG_REALM") if OS.get_environment("DIAG_REALM") != "" else "grove"
	var n := int(OS.get_environment("DIAG_N")) if OS.get_environment("DIAG_N") != "" else 40
	var r: Dictionary = data.realms[realm_id]
	var party := ["paladin", "brokk", "alva", "eira"]
	# Mätningen av Provocera: samma variabler som balance_report.gd (PROVOKE_CD) och combat_bot.gd (NO_PROVOKE).
	if not OS.get_environment("PROVOKE_CD") in ["", "0"]:
		data.abilities.provoke.cooldown = float(int(OS.get_environment("PROVOKE_CD")) - 1)
	var depth := int(OS.get_environment("DIAG_DEPTH")) if OS.get_environment("DIAG_DEPTH") != "" else 1
	if OS.get_environment("DIAG_MODE") == "boss":
		_boss(data, n)
		quit()
		return
	if OS.get_environment("DIAG_MODE") == "grotta":
		_grotto(data, realm_id, n, party)
		quit()
		return
	var rows := []
	for tier in r.pools.size():
		for enc in r.pools[tier]:
			rows.append([enc, tier])
	for f in r.elite_pools.size():
		for enc in r.elite_pools[f]:
			rows.append([enc, f])
	rows.append([r.floors[2], 2])
	for row in rows:
		var lv := 3 + int(row[1]) if depth == 1 else roundi(HeroStats.enemy_level(depth, int(row[1])))
		var wins := 0
		var alive := 0
		var hp_left := 0.0
		for s in range(1, n + 1):
			var res := Bot.run_fight(data, s, Bot.Skill.MACRO, row[0], party, {}, {}, {}, depth,
					{"levels": Bot.party_levels(data, lv, party), "counter": true, "floor": int(row[1])})
			wins += 1 if res.outcome == "victory" else 0
			alive += int(res.alive)
			var sim: CombatSim = res.sim
			var hp := 0.0
			var max_hp := 0.0
			for h in sim.heroes:
				hp += h.hp if h.alive else 0.0
				max_hp += h.max_hp
			hp_left += hp / max_hp
		print("  %-10s %-26s nivå %d  vinst %3d %%  överlevande %.1f  liv %2d %%" % [row[0], data.encounters[row[0]].name, lv,
				roundi(100.0 * wins / n), float(alive) / n, roundi(100.0 * hp_left / n)])
	quit()


## DIAG_MODE=grotta: hela körningar (som BALANS=grotta), var de förloras och hur mycket Charges som finns kvar.
func _grotto(data: Dictionary, realm_id: String, n: int, party: Array) -> void:
	for skill in [Bot.Skill.MACRO, Bot.Skill.TUNED]:
		var cleared := 0
		var lost := {}
		for s in range(1, n + 1):
			var depth := int(OS.get_environment("DIAG_DEPTH")) if OS.get_environment("DIAG_DEPTH") != "" else 1
			var opts := {"levels": Bot.party_levels(data, 3 + 5 * (depth - 1), party), "grow": true, "party": party}
			if OS.get_environment("DIAG_FRESH") != "":
				opts.bot_macros = Bot.new_profile_macros(data)  # en ny profils få rader (som karriären)
			var r := Bot.run_expedition(data, s, skill, {}, {}, depth, realm_id, opts, "simple")
			cleared += 1 if r.cleared else 0
			if r.has("lost_at"):
				lost[r.lost_at] = int(lost.get(r.lost_at, 0)) + 1
		var keys := lost.keys()
		keys.sort_custom(func(a: String, b: String) -> bool: return lost[a] > lost[b])
		print("  %s %s %3d %%  förluster: %s" % [realm_id, "MACRO" if skill == Bot.Skill.MACRO else "TUNED",
				roundi(100.0 * cleared / n), ", ".join(keys.slice(0, 8).map(func(k: String) -> String: return "%s %d" % [k, lost[k]]))])


## DIAG_MODE=boss: bossmötena med karriärens villkor (tre hjältar, nivå efter djupet minus två, halva Charges).
func _boss(data: Dictionary, n: int) -> void:
	for party in [["paladin", "imma", "alva"], ["paladin", "imma", "alva", "brokk"]]:
		for depth in [2, 3, 5]:
			var line := "  %d hjältar d%d" % [party.size(), depth]
			for realm_id in ["crypt", "chapel", "grove"]:
				var enc: String = data.realms[realm_id].floors[2]
				var wins := 0
				for s in range(1, n + 1):
					var st := RunState.new()
					st.party.assign(party)
					st.fill_charges(data)
					for h in st.charges:
						for a in st.charges[h]:
							st.charges[h][a] = int(st.charges[h][a]) / 2
					var res := Bot.run_fight(data, s, Bot.Skill.MACRO, enc, party, {}, st.charges, {}, depth,
							{"levels": Bot.party_levels(data, 5 * (depth - 1) + 1, party)})
					wins += 1 if res.outcome == "victory" else 0
				line += "  %s %3d %%" % [realm_id, roundi(100.0 * wins / n)]
			print(line)
