extends "res://tests/test_case.gd"
## Krönikan (Chronicle): loggen per nedstigning, räknarna, hemkomstens repliker (rätt händelse, rätt person, ingen
## upprepning, {titel}), titlarna och gamla profiler.

var _data := GameData.load_all()
const TMP := "user://test_chronicle.cfg"


func _profile() -> Profile:
	var p := Profile.new()
	p.intro_done = true
	p.set_hero_name("Tran")
	for id in ["imma", "brokk", "alva"]:
		p.recruit(_data, id)
	p.set_party(["imma", "brokk", "alva"])
	return p


const PARTY := ["paladin", "imma", "brokk", "alva"]


func _speakers(p: Profile) -> Array:
	return p.homecoming.get("remarks", []).map(func(r: Dictionary) -> String: return r.speaker)


func _keys(p: Profile) -> Array:
	return p.homecoming.get("remarks", []).map(func(r: Dictionary) -> String: return r.key)


func test_lines_have_ids_speakers_and_known_keys() -> void:
	var lines: Array = _data.dialog.chronicle.lines
	assert_true(lines.size() >= 40, "minst 40 repliker (%d)" % lines.size())
	var ids := {}
	var named := 0
	for l in lines:
		assert_true(not ids.has(l.id), "eget id: %s" % l.id)
		ids[l.id] = true
		assert_true(Chronicle.PRIO.has(l.key), "känd händelse: %s" % l.key)
		var who := String(l.who)
		assert_true(who == "subject" or Chronicle.KEEP_PEOPLE.has(who) or _data.heroes.has(who), "talare finns: %s" % who)
		if String(l.text).contains("{namn}"):
			named += 1
		if who == "ragnhild" and String(l.text).begins_with("»"):
			assert_true(l.has("ref"), "Ragnhilds bibelord har en referens (1917): %s" % l.id)
	# {namn} i ungefär var tredje replik, inte i varje.
	var share := float(named) / lines.size()
	assert_true(share > 0.2 and share < 0.45, "{namn} i ungefär var tredje (%.2f)" % share)


func test_entry_is_saved_and_read_back() -> void:
	var p := _profile()
	var e := Chronicle.simulate(p, _data, {"party": PARTY, "depth": 2, "outcome": "loss", "fell": {"brokk": 2},
			"rare": 1, "nether": 1, "trophies": ["bone_finger"], "vow": "vow_no_fall", "vow_broken": true})
	assert_eq(e.realm, "crypt")
	assert_eq(e.depth, 2)
	assert_eq(e.outcome, "loss")
	assert_eq(int(e.fell.brokk), 2)
	assert_eq(e.trophies, ["bone_finger"])
	assert_eq(e.vow_result, "broken")
	assert_eq(int(p.chron_stats.falls.brokk), 2)
	p.save(TMP)
	var back := Profile.load_from(TMP)
	assert_eq(back.chronicle.size(), 1)
	assert_eq(back.chronicle[0].outcome, "loss")
	assert_eq(int(back.chron_stats.falls.brokk), 2)
	assert_eq(back.homecoming.get("remarks", []).size(), p.homecoming.remarks.size())
	assert_true(Chronicle.entry_body(back, _data, back.chronicle[0]).contains("Brokk föll två gånger"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_old_profiles_load_and_earn_titles_they_already_deserve() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 99)
	cfg.set_value("progress", "boss_wins", {"bone_lich": 4})
	cfg.set_value("progress", "title", "bone_trapper")  # inte upplåst: tas bort
	cfg.save(TMP)
	var old := Profile.load_from(TMP)
	assert_true(old.chronicle.is_empty() and old.chron_stats.is_empty() and old.homecoming.is_empty())
	assert_eq(old.title, "")
	assert_true(Chronicle.recent(old).is_empty())
	var fresh := Chronicle.unlock_titles(old, _data)
	assert_true(fresh.has("bone_trapper"), "tre segrar mot Benfursten redan förtjänade")
	assert_eq(old.title, "bone_trapper", "den första titeln bärs direkt")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_someone_fell_mor_elin_speaks() -> void:
	var p := _profile()
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "fell": {"alva": 1}})
	assert_eq(_keys(p)[0], "fell")
	assert_true(_speakers(p)[0] in ["elin", "ragnhild"] or _speakers(p)[0] == "elin", str(_speakers(p)))
	assert_true(not _speakers(p).has("alva"), "den som föll talar inte om sig själv")


func test_paladin_fell_gets_its_own_line() -> void:
	var p := _profile()
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "loss", "fell": {"paladin": 1}})
	assert_eq(p.homecoming.remarks[0].id, "elin_fell_paladin")
	assert_true(String(p.homecoming.remarks[0].text).contains("Tran"))


func test_companions_comment_on_each_other_when_someone_falls_often() -> void:
	var p := _profile()
	p.chron_stats.falls = {"brokk": 2}
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "fell": {"brokk": 1}})
	var r: Dictionary = p.homecoming.remarks[0]
	assert_eq(r.key, "fell_often")
	assert_true(r.id in ["imma_fell_often_brokk", "alva_fell_often_brokk"], r.id)
	# Den som inte var med säger inget om det.
	var q := _profile()
	q.chron_stats.falls = {"brokk": 2}
	Chronicle.simulate(q, _data, {"party": ["paladin", "brokk"], "outcome": "boss", "fell": {"brokk": 1}})
	assert_true(not ["imma_fell_often_brokk", "alva_fell_often_brokk"].has(q.homecoming.remarks[0].id))
	assert_true(q.homecoming.remarks[0].speaker in ["elin", "gorm"])


func test_rare_stone_hedda_and_trophies_alrik() -> void:
	var p := _profile()
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "home", "rare": 1, "nether": 1})
	assert_eq(_speakers(p)[0], "hedda")
	var q := _profile()
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "home", "trophies": ["bone_finger", "rosary"]})
	assert_eq(_speakers(q)[0], "alrik")


func test_the_rescued_speaks_the_first_time_home() -> void:
	var p := _profile()
	Chronicle.simulate(p, _data, {"party": PARTY, "realm": "chapel", "outcome": "boss", "rescued": ["ragnhild"]})
	assert_eq(p.homecoming.remarks[0].id, "ragnhild_home_1")
	# Imma som smiter efter i introt är ingen befrielse.
	var q := Profile.new()
	q.intro_done = true
	var e := Chronicle.simulate(q, _data, {"party": ["paladin"], "outcome": "loss", "rescued": ["imma"]})
	assert_true(e.rescued.is_empty())
	assert_true(e.alone)


func test_new_depth_gorm_and_first_boss_imma() -> void:
	var p := _profile()
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "clear": true})
	assert_eq(_keys(p)[0], "new_depth")
	assert_true(_speakers(p)[0] in ["gorm", "stig"])
	var q := _profile()
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "boss", "bosses": ["bone_lich"]})
	assert_eq(_keys(q)[0], "first_boss")
	assert_true(_speakers(q)[0] in ["imma", "gorm"])
	assert_true(String(q.homecoming.remarks[0].text).contains("Benfursten"))
	assert_eq(Chronicle.fill("Vi slog {boss}!", q, _data, {"boss": "fallen_bishop"}), "Vi slog den fallne biskopen!")
	assert_eq(Chronicle.fill("{boss} föll.", q, _data, {"boss": "fallen_bishop"}), "Den fallne biskopen föll.")


func test_third_win_against_a_boss_and_the_title() -> void:
	var p := _profile()
	for i in 3:
		Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "bosses": ["bone_lich"]})
	var e: Dictionary = p.chronicle[-1]
	assert_eq(e.boss_trophies, ["bone_lich"])
	assert_true(e.titles.has("bone_trapper"))
	assert_eq(p.homecoming.remarks[0].speaker, "alrik")
	assert_eq(p.homecoming.remarks[0].key, "boss_trophy")
	assert_true(p.homecoming.titles.has("bone_trapper"), "Ny titel syns i rutan")
	assert_eq(p.title, "bone_trapper")
	assert_true(Chronicle.entry_body(p, _data, e).contains("Ny titel: Benfurstens fall"))


func test_patterns_same_realm_streak_and_comeback() -> void:
	var p := _profile()
	for i in 3:
		Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "home"})
	assert_eq(int(p.chronicle[-1].realm_streak), 3)
	assert_true(_keys(p).has("same_realm"), str(_keys(p)))
	var q := _profile()
	for i in 3:
		Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "loss"})
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "boss"})
	assert_true(q.chronicle[-1].comeback)
	assert_true(q.titles.has("risen"))
	for i in 2:
		Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "boss", "realm": "chapel"})
	assert_eq(int(q.chronicle[-1].win_streak), 3)
	assert_true(_keys(q).has("streak"), str(_keys(q)))
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "loss", "realm": "grove"})
	assert_eq(int(q.chronicle[-1].streak_broken), 3)
	assert_eq(_keys(q)[0], "streak_broken")


func test_no_line_repeats_until_the_others_are_said() -> void:
	var p := _profile()
	var pool: Array = _data.dialog.chronicle.lines.filter(func(l: Dictionary) -> bool:
			return l.key == "lost" and l.who in ["elin", "gorm", "imma", "brokk"] and not l.has("outcome"))
	var seen: Array = []
	for i in pool.size():
		var r := Chronicle.line_for(p, _data, {"n": i, "party": PARTY, "realm": "crypt"}, {"key": "lost", "prio": 54, "realm": "crypt"})
		assert_true(not seen.has(r.id), "upprepades för tidigt: %s" % r.id)
		seen.append(r.id)
	assert_eq(seen.size(), pool.size())
	var again := Chronicle.line_for(p, _data, {"n": 99, "party": PARTY, "realm": "crypt"}, {"key": "lost", "prio": 54, "realm": "crypt"})
	assert_true(seen.has(again.id), "sedan börjar de om")


func test_at_most_three_remarks_by_different_people() -> void:
	var p := _profile()
	p.boss_wins["bone_lich"] = 2
	p.chron_stats.falls = {"brokk": 4}
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "bosses": ["bone_lich"], "fell": {"brokk": 1},
			"rare": 1, "rescued": ["eira"], "clear": true, "trophies": ["rosary"]})
	var r: Array = p.homecoming.remarks
	assert_true(r.size() >= 1 and r.size() <= Chronicle.MAX_REMARKS)
	var who := r.map(func(x: Dictionary) -> String: return x.speaker)
	for s in who:
		assert_eq(who.count(s), 1, "olika personer: %s" % str(who))
	# Den tredje platsen bara för världen eller ett råd.
	if r.size() == 3:
		assert_true(Chronicle.WORLD_KEYS.has(r[2].key) or Chronicle.WORLD_KEYS.has(r[1].key), str(r))
	# En lugn hemkomst: bara en replik.
	var q := _profile()
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "boss"})
	assert_eq(q.homecoming.remarks.size(), 1)


func test_title_lines_need_a_title_and_fall_back_to_the_name() -> void:
	var p := _profile()
	var ev := {"key": "home_won", "prio": 5, "realm": "crypt"}
	for i in 10:
		var r := Chronicle.line_for(p, _data, {"n": i, "party": PARTY, "realm": "crypt"}, ev)
		assert_true(r.id != "imma_home_won_3", "utan titel väljs inte {titel}-repliken")
	assert_eq(Chronicle.fill("Välkommen hem, {titel}.", p, _data), "Välkommen hem, Tran.", "{titel} faller tillbaka till {namn}")
	p.titles.append("oath_kept")
	Chronicle.choose_title(p, "oath_kept")
	assert_eq(Chronicle.fill("Välkommen hem, {titel}.", p, _data), "Välkommen hem, Den som höll eden.")
	assert_true(not Chronicle.choose_title(p, "black_bane"), "en titel som inte är förtjänad kan inte väljas")
	p.chron_said.clear()
	var said := []
	for i in 5:
		said.append(Chronicle.line_for(p, _data, {"n": i, "party": PARTY, "realm": "crypt"}, ev).id)
	assert_true(said.has("imma_home_won_3"), "med en titel kan den väljas")


func test_titles_unlock_from_the_chronicle() -> void:
	var p := _profile()
	var first := Profile.new()
	Chronicle.simulate(first, _data, {"party": ["paladin"], "outcome": "boss"})
	assert_true(first.titles.has("alone_first"), "den första nedstigningen ensam")
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "vow": "vow_no_fall"})
	assert_true(p.titles.has("oath_kept"), "ett hållet löfte")
	var q := _profile()
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "loss", "vow": "vow_no_fall"})
	assert_true(not q.titles.has("oath_kept"), "ett löfte i en förlorad nedstigning är inte hållet")
	Chronicle.simulate(q, _data, {"party": PARTY, "realm": "chapel", "depth": 3, "outcome": "boss", "clear": true})
	assert_true(q.titles.has("chapel_cleanser"))
	Chronicle.simulate(q, _data, {"party": PARTY, "outcome": "boss", "bosses": ["bone_lich_black"]})
	assert_true(q.titles.has("black_bane"))
	assert_eq(q.chronicle[-1].twisted, "bone_lich_black")
	assert_eq(q.homecoming.remarks[0].key, "twisted_boss")
	var ids := Chronicle.title_ids(_data)
	# 15 i krönikan, två till för den levande världens händelser (Den som bröt högtiden, Landets värn).
	assert_true(ids.size() >= 10 and ids.size() <= 17, "10–17 titlar (%d)" % ids.size())


func test_living_map_remark_competes_with_the_chronicle() -> void:
	var p := _profile()
	p.descents = {"crypt": 1, "chapel": 1}
	Chronicle.simulate(p, _data, {"party": PARTY, "outcome": "boss", "map": true})
	assert_true(not p.growth_news.get("lines", []).is_empty(), "kartans rader finns kvar")
	assert_true(p.homecoming.remarks.size() >= 1)
	assert_eq(Chronicle._map_key("imma_map_calm_twisted_1"), "calm_twisted")
	assert_eq(Chronicle._map_key("gorm_map_wake_1"), "wake")


func test_demo_builds_a_chronicle() -> void:
	var p := Profile.new()
	Chronicle.demo(p, _data)
	assert_eq(p.chronicle.size(), 12)
	assert_eq(Chronicle.recent(p).size(), Chronicle.SHOWN)
	assert_eq(int(Chronicle.recent(p)[0].n), 12, "nyast först")
	assert_true(p.titles.size() >= 5, str(p.titles))
	for kind in ["fell", "boss3", "rare", "depth"]:
		var q := Profile.new()
		Chronicle.demo_home(q, _data, kind)
		assert_true(not q.homecoming.remarks.is_empty(), kind)
