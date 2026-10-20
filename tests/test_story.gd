extends "res://tests/test_case.gd"
## 0.25 "Berättelsen" (docs/plan/0.25-berattelsen.md): arbetarna från kryptan, paladinen ensam ned och Imma som smiter
## efter, berättarens rutor och hjälprutorna första gången.

const Bot := preload("res://tests/combat_bot.gd")
var _data := GameData.load_all()


func _step(id: String) -> Dictionary:
	for s in Intro.steps(_data):
		if s.id == id:
			return s
	return {}


func test_the_workers_tell_what_happened_and_gorm_sends_you_alone() -> void:
	var lines := Intro.lines(_step("workers"))
	assert_eq(lines[0].text, "(Efter en lång dag av att lära sig de allra enklaste sakerna går du och lägger dig.)")
	assert_eq(lines[1].text, "(Du vaknar av rop från gården.)")
	assert_true(lines[0].who == StoryBox.NARRATOR and lines[1].who == StoryBox.NARRATOR)
	var tor := lines.filter(func(l: Dictionary) -> bool: return l.who == "tor")
	assert_true(tor.size() >= 3 and tor.size() <= 5, "Tor berättar i 3–5 repliker (%d)" % tor.size())
	var said := lines.map(func(l: Dictionary) -> String: return "%s: %s" % [l.who, l.text])
	assert_true(said.has("gorm: Något har vaknat där nere. Gå ned och se efter, {namn}. Ensam."), str(said))
	assert_true(said.has("gorm: Imma, du stannar här."))
	assert_true(said.has("imma: Men jag—"), "Imma protesterar")
	assert_eq(lines.back().who, "gorm", "Gorm har sista ordet")
	assert_eq(Dialog.display_name(_data, "tor"), "Tor")


func test_imma_sneaks_after_and_gorm_greets_you_at_home() -> void:
	var join: Array = Intro.speech(_data.intro.imma_joins.lines)
	assert_eq(join[0].text, "Trodde du verkligen att jag skulle sitta och läsa?")
	assert_true(join.all(func(l: Dictionary) -> bool: return l.who == "imma"))
	var home := Intro.lines(_step("crypt"))
	assert_eq(home[0].who, "gorm")
	assert_true(home.any(func(l: Dictionary) -> bool: return l.who == "imma"), "Imma svarar")
	assert_true(_step("crypt").get("auto", false), "hemkomsten spelas av sig själv")


func test_older_profiles_keep_their_place_in_the_intro() -> void:
	# Före 0.25 var steg 5 Imma på gården, 6 Gorms ord om klockorna och 7 svärdet. Indexen gäller fortfarande.
	var p := Profile.new()
	p.intro_step = 5
	assert_eq(Intro.current(_data, p).id, "workers")
	p.intro_step = 6
	p.recruit(_data, "imma")
	p.set_party(["imma"])
	assert_eq(Intro.current(_data, p).id, "descent", "Imma är redan med: nedstigningen gäller")
	Intro.notify(_data, p, "came_home")
	assert_eq(Intro.current(_data, p).id, "crypt")
	assert_eq(p.party, ["paladin", "imma"])


func test_the_lone_paladin_almost_always_wins_the_first_fight() -> void:
	var fresh := Bot.new_profile_macros(_data)
	var won := 0
	for s in range(1, 41):
		var opts := {"levels": Bot.party_levels(_data, 1, ["paladin"]), "party": ["paladin"], "bot_macros": fresh,
				"recruited": _data.heroes.keys(), "first_descent": true, "max_fights": 1}
		won += 1 if Bot.run_expedition(_data, s, Bot.Skill.MACRO, {}, {}, 1, "crypt", opts).get("won", false) else 0
	assert_true(won >= 39, "lika lätt som övningen: %d/40" % won)


func test_the_narrator_speaks_in_parentheses() -> void:
	var narr: Dictionary = _data.dialog.narrator
	for kind in ["first_gate", "first_boss"]:
		assert_true(not narr.get(kind, []).is_empty(), kind)
	for kind in narr:
		if kind.begins_with("_"):
			continue
		for l in narr[kind]:
			assert_true(String(l).begins_with("(") and String(l).ends_with(")"), l)
	for step in Intro.steps(_data):
		for l in Intro.lines(step):
			if l.who == StoryBox.NARRATOR:
				assert_true(l.text.begins_with("(") and l.text.ends_with(")"), l.text)


func test_every_help_box_is_short_and_in_the_handbook() -> void:
	var want := ["room_map", "realm_quest", "trophies", "macros", "artifacts", "materials", "depth", "instability",
			"perks", "disciples", "timeline", "statuses", "forfeit"]
	var order := Help.order(_data)
	assert_eq(order.size(), want.size())
	for id in want:
		assert_true(order.has(id), "handboken har " + id)
	for id in _data.help.entries:
		assert_true(order.has(id), id + " står i handboken")
		var e := Help.entry(_data, id)
		assert_true(String(e.get("title", "")) != "", id)
		var n: int = e.text.size()
		assert_true(n >= 2 and n <= 3, "%s har %d stycken" % [id, n])
		for para in e.text:
			assert_true(String(para).length() <= 200, "%s: kort stycke (%d tecken)" % [id, String(para).length()])


func test_help_is_shown_once_per_profile_and_saved() -> void:
	var p := Profile.new()
	assert_eq(Help.take(_data, p, ["timeline", "nonsense", "room_map"]), ["timeline", "room_map"])
	assert_eq(Help.take(_data, p, ["timeline", "macros"]), ["macros"], "bara det som är nytt")
	p.narrated.append("first_gate")
	var path := "user://test_progress_help.cfg"
	p.save(path)
	var q := Profile.load_from(path)
	assert_eq(q.help_seen, ["timeline", "room_map", "macros"])
	assert_eq(q.narrated, ["first_gate"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_the_paladin_may_go_down_alone_only_before_anyone_has_joined() -> void:
	var p := Profile.new()
	assert_true(RunState.can_start(p), "introts nedstigning: paladinen ensam")
	p.recruit(_data, "imma")
	p.party.assign(["paladin"])
	assert_true(not RunState.can_start(p), "sedan minst en följeslagare")
	p.set_party(["imma"])
	assert_true(RunState.can_start(p))
