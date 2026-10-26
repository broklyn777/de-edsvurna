extends "res://tests/test_case.gd"
## Textspelet i takt med 0.30.45–0.30.46: djupets tecken (visas, byts en gång, gäller i striden), Torun (party5),
## avbrott i stridsloggen, bossprognosen vid fördärv 4, kartans ändringar i klartext och hjältebladet.

const TextPlay := preload("res://tests/text_play.gd")
var _dir := OS.get_user_data_dir().path_join("test_textspel6_%d" % OS.get_process_id())


func _clean() -> void:
	for f in ["meta.json", "profile.cfg", "run.cfg", "log.txt"]:
		if FileAccess.file_exists(_dir.path_join(f)):
			DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _run(cmd: String) -> String:
	return TextPlay.new().execute(_dir, cmd)


func test_omen_shown_swapped_once_and_used_in_battle() -> void:
	_clean()
	var text := _run("new 5")
	assert_true(text.contains("Djupets tecken för nästa nedstigning:"), "borgen visar tecknet")
	var before := Profile.load_from(_dir.path_join("profile.cfg"))
	text = _run("omen swap")
	var after := Profile.load_from(_dir.path_join("profile.cfg"))
	assert_true(text.contains("Ni byter tecken"), "bytet görs")
	assert_eq(after.silver, before.silver - RunState.OMEN_REROLL_COST, "bytet kostar silver")
	assert_true(after.omen != before.omen, "ett annat tecken")
	text = _run("omen swap")
	assert_true(text.contains("redan bytt"), "bara en gång")
	text = _run("start")
	var state := RunState.load_from(_dir.path_join("run.cfg"))
	assert_eq(state.omen, after.omen, "tecknet som syntes hemma gäller nedstigningen")
	assert_true(text.contains("Djupets tecken: "), "nedstigningen visar tecknet")
	assert_true(state.battle_opts().rules.has(state.omen), "tecknet går in i striden som en regel")
	var next := Profile.load_from(_dir.path_join("profile.cfg"))
	assert_true(next.omen != "" and next.omen != state.omen and not next.omen_rerolled, "nästa tecken dras direkt")
	_clean()


func test_party5_brings_torun_with_her_abilities() -> void:
	_clean()
	_run("new 6")
	var text := _run("party5")
	assert_true(text.contains("Torun Bergsbrytare ansluter"), "Torun kommer")
	var prof := Profile.load_from(_dir.path_join("profile.cfg"))
	assert_true(prof.recruited.has("torun") and prof.party.has("torun"), "hon är med i sällskapet")
	text = _run("look")
	assert_true(text.contains("Paladinen + 4"), "den femte platsen gäller vid nästa anrop")
	text = _run("hero torun")
	assert_true(text.contains("Kilslag") and text.contains("Stå beredd") and text.contains("Stötta upp"), "förmågorna syns")
	_clean()


func test_interrupt_event_is_written() -> void:
	var tp := TextPlay.new()
	tp.data = GameData.load_all()
	var sim := CombatSim.create(tp.data, "troll_1a", 3, ["paladin", "torun"], {}, {}, {}, 1, {})
	var enemy: CombatUnit = sim.enemies[0]
	var labels := tp._labels(sim)
	var line: String = tp._event_text(sim, {"type": "interrupt", "unit": "torun", "target": enemy.id,
			"ability": String(tp.data.heroes.torun.abilities[0])}, labels, {})
	assert_true(line.begins_with("!! ") and line.contains("avbryter"), "avbrottet syns i loggen: " + line)


func test_boss_forecast_follows_twisted_boss() -> void:
	_clean()
	_run("new 7")
	var prof := Profile.load_from(_dir.path_join("profile.cfg"))
	prof.realm = "crypt"
	prof.depth = 2
	prof.growth["crypt"] = LivingMap.GROWTH_MAX
	prof.save(_dir.path_join("profile.cfg"))
	var text := _run("look")
	var name := String(GameData.load_all().encounters.crypt_twisted.get("name", "crypt_twisted"))
	assert_true(text.contains("Djupets slut: %s (förvriden" % name), "prognosen visar den förvridna bossen")
	_clean()


func test_map_change_is_readable() -> void:
	var data := GameData.load_all()
	var t := TextPlay.map_change_text(data, {"realm": "mountain", "from": 1, "to": 0, "why": "quest"})
	assert_true(t.contains("viker") and t.contains("questen klarades") and not t.contains("{"), t)


func test_hero_sheet_shows_sources_and_artifact() -> void:
	_clean()
	_run("new 8")
	var text := _run("hero alva")
	assert_true(text.contains("HJÄLTEBLADET") and text.contains("Erfarenhet:") and text.contains("Personlighet:"), "huvudet")
	assert_true(text.contains(" bas + ") and text.contains("nivåer"), "stats per källa")
	assert_true(text.contains("[EGEN]") and text.contains("[TROFÉ]"), "egenskaper med källa")
	assert_true(text.contains("Artefakt: Stav nivå") and text.contains("Stat-plats 1"), "artefakten och platserna")
	_clean()
