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
	assert_eq(join[0].text, "Trodde du verkligen att jag skulle stanna och leta glasögon åt Broder Alrik?")
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
	# Mätt över 200 frön (main och elit-balans, 2026-10-21): 92 %. Gränsen 39/40 höll bara på fröna.
	assert_true(won >= 35, "nästan alltid: %d/40" % won)


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
			"perks", "disciples", "timeline", "statuses", "forfeit", "charges"]
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


## 0.25.1 (VD:ns fel): Imma var inte med i den första striden och ska inte stå på segerskärmen eller få trofé och
## erfarenhet. Striden märker bara att hon väntar; hon ansluter på rumskartan, och sparas så om appen stängs däremellan.
func test_imma_joins_on_the_map_not_on_the_victory_screen() -> void:
	const RunScript := preload("res://scripts/game/run.gd")
	var p := Profile.new()
	while Intro.current(_data, p).id != "descent":
		Intro.talked(_data, p)
		Intro.notify(_data, p, Intro.current(_data, p).event)
	var s := RunState.new_run(p, _data)
	s.first_descent = true
	s.start_expedition(_data, 3)
	assert_eq(s.party, ["paladin"], "paladinen går ned ensam")
	RunScript.mark_sneak(_data, p, s)
	assert_eq(s.party, ["paladin"], "segerskärmen visar bara den som var med i striden")
	assert_true(not p.recruited.has("imma"), "ingen trofé eller erfarenhet till Imma än")
	assert_eq(s.joins_next, "imma")
	var saved := RunState.from_dict(s.to_dict())
	assert_eq(saved.joins_next, "imma", "väntar kvar om appen stängs i lägret")
	assert_eq(saved.join_waiting(_data, p), "imma", "på rumskartan ansluter hon")
	assert_eq(saved.party, ["paladin", "imma"])
	assert_true(p.recruited.has("imma") and p.party == ["paladin", "imma"])
	assert_true(saved.charges.has("imma"), "med egna Charges")
	assert_eq(saved.join_waiting(_data, p), "", "bara en gång")
	RunScript.mark_sneak(_data, p, saved)
	assert_eq(saved.joins_next, "", "redan med")


## 0.26.1 (provspelet): Imma syns och pratar under introdagen, men ansluter inte förrän hon smiter efter i kryptan.
func test_imma_shows_up_during_the_day_but_does_not_join_early() -> void:
	var p := Profile.new()
	var heard := 0
	while Intro.current(_data, p).get("id", "") not in ["", "descent"]:
		var step := Intro.current(_data, p)
		for who in step.get("at", {}):
			for l in Intro.speech(step.at[who], who):
				heard += 1 if l.who == "imma" else 0
				if l.who == "imma":
					assert_true(l.text.find("följer med") < 0 and l.text.find("ansluter") < 0, l.text)
		assert_true(not p.recruited.has("imma") and not p.party.has("imma"), "Imma är inte med i steget %s" % step.id)
		Intro.talked(_data, p)
		Intro.notify(_data, p, step.get("event", ""), 3)
	assert_true(heard >= 2, "Imma säger något under dagen före gårdsscenen (%d repliker)" % heard)


## 0.26.1: räcker inte silvret till svärdets nästa nivå säger Hedda och uppdraget hur mycket som fattas.
func test_hedda_says_how_much_silver_is_missing() -> void:
	var p := Profile.new()
	while Intro.current(_data, p).get("id", "") not in ["", "crypt"]:
		Intro.talked(_data, p)
		Intro.notify(_data, p, Intro.current(_data, p).get("event", ""), 3)
	p.silver = Profile.FORGE_COST
	p.forge("paladin", "sword", "")
	p.intro_talked = true
	p.silver = Forge.level_cost(1) - 10
	var short: Array = Intro.at_lines(_data, p, "hedda")
	var text := " ".join(short.map(func(l: String) -> String: return Dialog.fill_for(l, p)))
	assert_true(text.find("Det fattas 10") >= 0 and text.find("kryptan igen") >= 0, text)
	assert_true(Intro.quest_text(_data, p).find("det fattas 10 silver") >= 0, Intro.quest_text(_data, p))
	p.silver = Forge.level_cost(1)
	var enough: Array = Intro.at_lines(_data, p, "hedda")
	assert_true(" ".join(enough).find("fattas") < 0, "räcker silvret säger hon inget om det")
	assert_true(Intro.quest_text(_data, p).find("fattas") < 0)


## 0.26.2: "Så du är den nya" och "Du måste vara {namn}" hör till första mötet och kommer inte tillbaka sedan.
func test_first_meeting_greetings_only_once() -> void:
	for who in ["stig", "hedda", "elin", "gorm", "alrik", "sven"]:
		var g: Array = Dialog.person(_data, who).greet
		assert_eq(Dialog.greeting(_data, who, 0), g[0], who)
		for turn in range(1, 12):
			assert_true(Dialog.greeting(_data, who, turn) != g[0], "%s hälsar som första gången vid möte %d" % [who, turn])


## 0.26.2: räcker silvret ber Hedda om det (inte "ta med det från kryptan"), och på nivå 3 säger hon inget om nästa nivå.
func test_hedda_asks_for_the_silver_and_stops_at_level_three() -> void:
	var p := Profile.new()
	while Intro.current(_data, p).get("id", "") not in ["", "crypt"]:
		Intro.talked(_data, p)
		Intro.notify(_data, p, Intro.current(_data, p).get("event", ""), 3)
	p.silver = Profile.FORGE_COST
	p.forge("paladin", "sword", "")
	p.intro_talked = true
	p.silver = 1000
	var text := " ".join(Intro.at_lines(_data, p, "hedda").map(func(l: String) -> String: return Dialog.fill_for(l, p)))
	assert_true(text.find("Lägg fram det") >= 0 and text.find("kryptan") < 0, text)
	p.artifacts.paladin.level = 3
	assert_eq(Intro.at_lines(_data, p, "hedda"), null, "ingen nästa nivå på nivå 3")
