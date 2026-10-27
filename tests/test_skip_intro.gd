extends "res://tests/test_case.gd"
## HOPPA ÖVER INTROT i testversioner (0.30.52): en ny profil som om introt vore klart, med Imma, svärdet och Gorms
## första rad, och med den första nedstigningen räknad så att trappan och berättelsen inte spelas om.

var _data := GameData.load_all()


func _skipped() -> Profile:
	var p := Profile.new()
	p.setup_gambits(_data, {})  # som Run.choose_slot: makrona läses före hoppet
	p.skip_intro(_data)
	return p


func test_intro_is_done() -> void:
	var p := _skipped()
	assert_true(p.intro_done)
	assert_eq(p.intro_step, Intro.steps(_data).size())
	assert_true(Intro.current(_data, p).is_empty(), "inget introsteg kvar")


func test_imma_has_joined() -> void:
	var p := _skipped()
	assert_eq(Array(p.recruited), ["imma"])
	assert_eq(Array(p.party), ["paladin", "imma"])
	for id in Gambits.recruit_gift(_data, "imma").blocks:
		assert_true(Gambits.has(p.gambits, id), "Immas kloss " + id)


func test_sword_and_silver() -> void:
	var p := _skipped()
	var art := p.artifact("paladin")
	assert_eq(art.type, "sword")
	assert_eq(art.ability, "holy_smite")
	assert_eq(int(art.level), 1)
	assert_eq(p.silver, 0)


func test_gorms_first_row_and_only_starters() -> void:
	var p := _skipped()
	assert_true(p.found_rows.any(func(r: Dictionary) -> bool: return r.source == "intro"), "Gorms första rad är funnen")
	var allowed: Array = Gambits.starters(_data) + Array(Gambits.recruit_gift(_data, "imma").blocks)
	for id in p.gambits:
		assert_true(allowed.has(id), "en ny profil äger inte " + id)


func test_first_descent_counted_and_alva_next() -> void:
	var p := _skipped()
	assert_eq(p.total_descents(), 1)
	assert_true(p.narrated.has("first_gate"))
	var s := RunState.new_run(p, _data)
	s.set_realm(_data, "crypt")
	s.place_prisoners(_data, p.recruited, int(p.descents.get("crypt", 0)))
	assert_true(s.prisoners.values().any(func(d: Dictionary) -> bool: return d.hero == "alva"), "Alva på andra nedstigningen")


func test_survives_save_and_load() -> void:
	var path := "user://test_skip_intro.cfg"
	_skipped().save(path)
	var q := Profile.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_true(q.intro_done)
	assert_eq(q.gambits_state, "ok")
	assert_eq(q.total_descents(), 1)
	assert_eq(q.artifact("paladin").ability, "holy_smite")
