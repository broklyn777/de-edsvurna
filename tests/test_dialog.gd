extends "res://tests/test_case.gd"
## 0.24 Hemmet: samtalen i borgen (data/dialog.json, Dialog), borgens planritning (data/keep.json), replikerna under
## nedstigningen och den första nedstigningen med Paladinen och Imma.

var _data := GameData.load_all()
const WHEN_KEYS := ["recruited", "not_recruited", "min_recruited", "min_descents", "min_best_depth", "boss", "intro_done"]


func test_every_station_has_a_person_and_a_conversation() -> void:
	for id in _data.keep.rooms:
		var st := Dialog.station(_data, id)
		assert_true(not st.is_empty(), "%s har ett samtal" % id)
		var who := Dialog.station_person(_data, id)
		if who == "":
			assert_eq(id, "altar", "bara altaret står utan person (0.24.3)")
			assert_true(_data.keep.rooms[id].has("person"), "Gorm har en plats vid altaret under eden")
		else:
			var p := Dialog.person(_data, who)
			assert_true(p.get("name", "") != "", "%s: %s har ett namn" % [id, who])
			assert_true(p.get("greet", []).size() >= 1 and p.get("idle", []).size() >= 3, "%s hälsar och har vardagsrepliker" % who)
			assert_true(_data.keep.rooms[id].has("person"), "%s står på kartan" % who)
		var opts := Dialog.options(_data, id)
		assert_true(opts.size() >= 2, id)
		assert_eq(opts.back().label, "Ingenting just nu", "sist kommer Ingenting just nu")
		assert_eq(opts.back().open, "")
		for o in opts.slice(0, opts.size() - 1):
			assert_true(_data.keep.rooms.has(o.open) or o.open in ["rename", "talk_trophies"], "%s öppnar något som finns" % o.label)
		assert_true(Dialog.reply(_data, id) != "", "%s har ett svar när den är stängd" % id)


func test_every_line_has_a_known_speaker_and_condition() -> void:
	for who in _data.dialog.people:
		for l in Dialog.person(_data, who).get("idle", []):
			assert_true(l.get("text", "") != "", who)
			for key in l.get("when", {}):
				assert_true(WHEN_KEYS.has(key), "%s: okänt villkor %s" % [who, key])
	for who in _data.dialog.barks:
		assert_true(_data.heroes.has(who), "%s är en hjälte" % who)
		for kind in _data.dialog.barks[who]:
			assert_true(Dialog.BARK_KINDS.has(kind), "%s: okänt läge %s" % [who, kind])
	for pair in _data.dialog.pairs:
		for l in pair.lines:
			assert_true(pair.heroes.has(l[0]) and l[1] != "", "varje rad i ett samtal har en talare ur paret")


func test_news_comes_first_in_the_idle_lines() -> void:
	var p := Profile.new()
	p.intro_done = true
	p.descents = {"crypt": 1}
	assert_true(Dialog.idle_line(_data, p, "gorm", 0).contains("Alva"), "Gorm nämner ryktet om Alva efter första nedstigningen")
	p.recruit(_data, "alva")
	assert_true(Dialog.idle_line(_data, p, "gorm", 0).contains("förband"), "och något annat när hon har kommit")


func test_barks_never_repeat_in_a_run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var used: Array = []
	var seen: Array = []
	for i in 40:
		var b := Dialog.bark(_data, "campfire", ["paladin", "imma", "alva"], used, rng)
		if b.is_empty():
			break
		var text: String = b.lines[0].text
		assert_true(not seen.has(text), "upprepas inte: " + text)
		seen.append(text)
	assert_true(seen.size() >= 4, "Imma, Alva och deras samtal")
	assert_true(Dialog.bark(_data, "campfire", ["paladin"], [], rng).is_empty(), "Paladinen ensam säger inget")


func test_the_keep_layout_fits_together() -> void:
	var yard := _rect(_data.keep.yard.rect)
	for id in _data.keep.rooms:
		var room: Dictionary = _data.keep.rooms[id]
		var r := _rect(room.rect)
		assert_true(r.grow(1).has_point(_v(room.stand)), "%s: paladinen står i rummet" % id)
		assert_true(r.grow(2).has_point(_v(room.door)) and not r.grow(-2).has_point(_v(room.door)), "%s: dörren sitter i väggen" % id)
		assert_true(yard.grow(6).has_point(_v(room.yard)), "%s: gången når gården" % id)
		if room.has("person"):
			assert_true(r.has_point(_v(room.person)), "%s: personen står i rummet" % id)


func test_the_first_descent_has_weaker_enemies_and_no_prisoner() -> void:
	var p := Profile.new()
	p.recruit(_data, "imma")
	var s := RunState.new_run(p, _data)
	assert_true(s.prisoners.is_empty(), "ingen fånge första gången")
	s.first_descent = true
	s.start_expedition(_data, 4)
	assert_near(float(s.battle_opts().get("stat_bonus", 1.0)), RunState.first_descent_mult(0), 1e-6)
	assert_true(RunState.first_descent_mult(0) < RunState.first_descent_mult(1), "våning 2 är svårare än våning 1")
	assert_true(RunState.first_descent_mult(2) < 1.0, "Benfursten är också lite svagare första gången")
	var saved := RunState.from_dict(s.to_dict())
	assert_true(saved.first_descent, "sparas med körningen")


static func _rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2], a[3])


static func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


## 0.24.2: paladinens namn.
func test_the_name_is_saved_and_trimmed() -> void:
	var p := Profile.new()
	assert_eq(p.hero_name, "Paladinen", "standardnamnet")
	p.set_hero_name("  Tran  ")
	assert_eq(p.hero_name, "Tran")
	p.set_hero_name("Ett mycket långt namn som inte får plats")
	assert_true(p.hero_name.length() <= Profile.NAME_MAX)
	p.set_hero_name("   ")
	assert_eq(p.hero_name, "Paladinen", "tomt blir Paladinen")
	p.set_hero_name("Sigrun")
	var path := "user://test_progress_name.cfg"
	p.save(path)
	assert_eq(Profile.load_from(path).hero_name, "Sigrun")
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 10)
	cfg.save(path)
	assert_eq(Profile.load_from(path).hero_name, "Paladinen", "äldre profiler heter Paladinen")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_the_name_token_fills_the_lines_now_and_then() -> void:
	assert_eq(Dialog.fill("Väl mött, {namn}.", "Tran"), "Väl mött, Tran.")
	var named := 0
	var total := 0
	for who in _data.dialog.people:
		for g in Dialog.person(_data, who).get("greet", []):
			total += 1
			named += 1 if String(g).contains("{namn}") else 0
	for step in Intro.steps(_data):
		for l in step.get("talk", []):
			total += 1
			named += 1 if String(l).contains("{namn}") else 0
	assert_true(named >= 6, "namnet sägs ibland (%d repliker)" % named)
	assert_true(named * 3 < total, "men inte i varje replik (%d av %d)" % [named, total])
	var p := Profile.new()
	p.set_hero_name("Tran")
	p.intro_done = true
	assert_true(not Dialog.fill(Dialog.greeting(_data, "gorm", 0), p.hero_name).contains("{namn}"))
	assert_true(Dialog.options(_data, "library").any(func(o: Dictionary) -> bool: return o.open == "rename"),
			"Broder Alrik kan skriva om namnet")


## Allt som någon säger: [talare, text] (hälsningar, vardagsrepliker, introts samtal och repliker, svar, trofésamtal).
func _spoken() -> Array:
	var out := []
	for who in _data.dialog.people:
		var p := Dialog.person(_data, who)
		for g in p.get("greet", []):
			out.append([who, g])
		for l in p.get("idle", []):
			out.append([who, l.text])
		for l in p.get("trophies", []):
			out.append([who, l])
	for step in Intro.steps(_data):
		for l in step.get("talk", []):
			out.append([step.giver, l])
		for who in step.get("at", {}):
			var at: Variant = step.at[who]
			for l in (at if at is Array else [at]):
				out.append([who, l])
	for st in _data.intro.replies:
		var who := Dialog.station_person(_data, st)
		if who != "":
			out.append([who, _data.intro.replies[st]])
	for who in _data.dialog.barks:
		for kind in _data.dialog.barks[who]:
			for l in _data.dialog.barks[who][kind]:
				out.append([who, l])
	return out


## 0.24.3: uppdraget står bara överst, aldrig i någons mun, och ingen talar om sig själv i tredje person.
func test_no_one_reads_the_quest_or_names_themselves() -> void:
	var quests := Intro.steps(_data).map(func(s: Dictionary) -> String: return s.quest)
	var own := {"gorm": "Gorm", "hedda": "Hedda", "alrik": "Alrik", "stig": "Stig", "elin": "Elin", "sven": "Sven",
			"imma": "Imma", "alva": "Alva", "brokk": "Brokk", "eira": "Eira", "solveig": "Solveig"}
	var lines := _spoken()
	assert_true(lines.size() > 60, "alla repliker granskas (%d)" % lines.size())
	for pair in lines:
		var text: String = pair[1]
		for q in quests:
			assert_true(not text.contains(q), "%s läser upp uppdraget: %s" % [pair[0], text])
		if own.has(pair[0]):
			assert_true(not text.contains(own[pair[0]]), "%s nämner sig själv: %s" % [pair[0], text])
		assert_true(not text.begins_with("{namn}.") and not text.contains(". {namn}."), "namnet som en egen mening: " + text)


func test_every_intro_step_has_a_line_from_the_person_there() -> void:
	for step in Intro.steps(_data):
		if step.event == "talked":
			continue
		var p := Profile.new()
		while Intro.current(_data, p).get("id", "") != step.id:
			Intro.talked(_data, p)
			Intro.notify(_data, p, Intro.current(_data, p).event, 3)
		var who := Intro.who_at(_data, p, step.station)
		if who != "":
			assert_true(step.get("at", {}).has(who), "%s säger något egen vid %s" % [who, step.id])
	assert_eq(Dialog.person(_data, "gorm").station, "macros", "Gorm bor i sin kammare")
	var q := Profile.new()
	assert_eq(Intro.who_at(_data, q, "altar"), "gorm", "under eden står Gorm vid altaret")
	assert_eq(Intro.who_at(_data, q, "macros"), "", "och inte i kammaren")
	assert_eq(Intro.quest_text(_data, q), "Prata med Mäster Gorm vid altaret i kapellet.")
	while Intro.current(_data, q).id != "macro":
		Intro.talked(_data, q)
		Intro.notify(_data, q, Intro.current(_data, q).event)
	assert_eq(Intro.who_at(_data, q, "macros"), "gorm", "vid makrosteget sitter han i sin kammare")
	q.intro_done = true
	assert_eq(Intro.who_at(_data, q, "macros"), "gorm", "efter introt bor han där")


func test_the_sword_quest_shows_its_progress() -> void:
	var p := Profile.new()
	while Intro.current(_data, p).id != "crypt":
		Intro.talked(_data, p)
		Intro.notify(_data, p, Intro.current(_data, p).event)
	Intro.talked(_data, p)
	p.silver = 160
	p.forge("paladin", "sword", "")
	assert_true(Intro.quest_text(_data, p).ends_with("Nu nivå 1 av 3 – nästa nivå 60 silver."), Intro.quest_text(_data, p))
	p.silver = 77
	assert_true(p.level_artifact("paladin") != null, "77 silver räcker till nivå 2")
	assert_eq(p.silver, 17)
	assert_true(Intro.quest_text(_data, p).ends_with("nivå 2 av 3 – nästa nivå 80 silver."))
	assert_true(p.level_artifact("paladin") == null, "men inte till nivå 3")
	var hedda: String = Intro.current(_data, p).at.hedda[0]
	assert_eq(Dialog.fill_for(hedda, p).substr(0, 48), "Svärdet är på nivå 2 av 3. Nästa nivå kostar 80 ")
	assert_true(Dialog.person(_data, "alrik").get("trophies", []).size() >= 3, "Alrik förklarar troféerna")
