extends "res://tests/test_case.gd"
## Textspelet (tests/text_play.gd): en profil skapas, en nedstigning börjar, ett steg tas och läget sparas.

const TextPlay := preload("res://tests/text_play.gd")
var _dir := OS.get_user_data_dir().path_join("test_textplay_%d" % OS.get_process_id())


func _clean() -> void:
	for f in ["meta.json", "profile.cfg", "run.cfg", "log.txt"]:
		if FileAccess.file_exists(_dir.path_join(f)):
			DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func test_start_step_and_save() -> void:
	_clean()
	var text: String = TextPlay.new().execute(_dir, "new 3")
	assert_true(text.contains("BORGEN"), "borgen visas efter new")
	text = TextPlay.new().execute(_dir, "start")
	assert_true(text.contains("våning 1 av 2"), "grottan visas efter start")
	assert_true(FileAccess.file_exists(_dir.path_join("run.cfg")), "körningen sparas")
	var state := RunState.load_from(_dir.path_join("run.cfg"))
	var target := -1
	for n in Grotto.neighbors(state.pos):
		if state.can_step(n) == "":
			target = n
			break
	var p := Grotto.xy(target)
	text = TextPlay.new().execute(_dir, "go %s%d" % ["abcdefgh"[p.x], p.y + 1])
	assert_true(text.contains("Ni går till"), "steget tas")
	var after := RunState.load_from(_dir.path_join("run.cfg"))
	assert_true(after.visited.has(target), "steget sparas")
	assert_true(FileAccess.get_file_as_string(_dir.path_join("log.txt")).contains(">>> start"), "loggen skrivs")
	_clean()
