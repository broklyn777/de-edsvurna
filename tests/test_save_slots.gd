extends "res://tests/test_case.gd"
## 0.23.1: sparplatser. Gamla sparfiler flyttas orörda till plats 1, platserna hålls isär och kan raderas.

var _data := GameData.load_all()


func _root(name: String) -> String:
	var root := "user://%s/" % name
	_wipe(root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
	return root


func _wipe(root: String) -> void:
	for i in range(1, SaveSlots.COUNT + 1):
		for f in SaveSlots.FILES:
			if FileAccess.file_exists(SaveSlots.dir(i, root) + f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSlots.dir(i, root) + f))
	for f in SaveSlots.FILES + ["slots.cfg"]:
		if FileAccess.file_exists(root + f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(root + f))


func test_an_old_save_moves_to_slot_one_untouched() -> void:
	var root := _root("test_slots_migrate")
	# En profil från före 0.23 (inga följeslagare sparade, inget intro).
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 777)
	cfg.set_value("progress", "party", ["paladin", "brokk", "alva", "eira"])
	cfg.set_value("progress", "heroes", {"brokk": {"level": 7, "xp": 3, "personality": "envis", "battles": 1,
			"wins": 1, "deaths": 0, "revives": 0, "log": []}})
	cfg.save(root + "progress.cfg")
	var macros := '{"macros": {"brokk": {"name": "Min Brokk", "lines": []}}, "assignment": {"brokk": "brokk"}}'
	var f := FileAccess.open(root + "macros.json", FileAccess.WRITE)
	f.store_string(macros)
	f.close()
	assert_true(SaveSlots.migrate(root))
	assert_true(not FileAccess.file_exists(root + "progress.cfg"), "flyttad, inte kopierad")
	var p := Profile.load_from(SaveSlots.progress_path(1, root))
	assert_eq(p.silver, 777)
	assert_true(p.intro_done, "en gammal profil hoppar över introt")
	assert_eq(p.party, ["paladin", "brokk", "alva", "eira"])
	assert_eq(int(p.hero(_data, "brokk").level), 6, "nivåerna finns kvar (räknade om till kurvan: 0.19:s nivå 7 är nivå 6)")
	assert_true(p.recruited.has("imma") and p.recruited.has("solveig"))
	assert_eq(FileAccess.get_file_as_string(SaveSlots.macros_path(1, root)), macros, "makrona är orörda")
	assert_eq(SaveSlots.last(root), 1)
	assert_true(not SaveSlots.migrate(root), "bara en gång")
	_wipe(root)


func test_migration_never_overwrites_slot_one() -> void:
	var root := _root("test_slots_keep")
	var a := Profile.new()
	a.silver = 5
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveSlots.dir(1, root)))
	a.save(SaveSlots.progress_path(1, root))
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "silver", 999)
	cfg.save(root + "progress.cfg")
	assert_true(not SaveSlots.migrate(root))
	assert_eq(Profile.load_from(SaveSlots.progress_path(1, root)).silver, 5)
	_wipe(root)


func test_slots_are_kept_apart_and_can_be_deleted() -> void:
	var root := _root("test_slots_apart")
	for i in [1, 2]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveSlots.dir(i, root)))
		var p := Profile.new()
		p.silver = 100 * i
		p.set_hero_name("Tran" if i == 2 else "")
		p.save(SaveSlots.progress_path(i, root))
	assert_eq(Profile.load_from(SaveSlots.progress_path(1, root)).silver, 100)
	assert_eq(Profile.load_from(SaveSlots.progress_path(2, root)).silver, 200)
	assert_true(SaveSlots.is_empty(3, root))
	var s2 := SaveSlots.summary(2, _data, root)
	assert_true(not s2.empty and s2.silver == 200 and s2.intro, "en ny profil har introt kvar")
	assert_eq(s2.name, "Tran", "namnet syns på kortet")
	assert_eq(SaveSlots.summary(1, _data, root).name, "Paladinen")
	assert_true(SaveSlots.summary(3, _data, root).empty)
	SaveSlots.set_last(2, root)
	SaveSlots.delete(2, root)
	assert_true(SaveSlots.is_empty(2, root))
	assert_eq(Profile.load_from(SaveSlots.progress_path(1, root)).silver, 100, "plats 1 rörs inte")
	assert_eq(SaveSlots.last(root), 0, "den raderade är inte längre senast")
	_wipe(root)


func test_a_run_in_progress_shows_on_the_slot() -> void:
	var root := _root("test_slots_run")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveSlots.dir(1, root)))
	var p := Profile.new()
	p.save(SaveSlots.progress_path(1, root))
	var s := RunState.new_run(p, _data)
	s.start_expedition(_data, 3)
	s.save(SaveSlots.run_path(1, root))
	assert_true(SaveSlots.summary(1, _data, root).run)
	_wipe(root)
