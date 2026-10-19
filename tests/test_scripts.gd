extends "res://tests/test_case.gd"
## Alla skript i spelet ska gå att kompilera. En skärm som inte kompilerar kraschar först när man når den
## (0.18.3: lägret efter första striden).


func test_all_game_scripts_compile() -> void:
	for dir in ["res://scripts", "res://src"]:
		for path in _scripts(dir):
			var script := load(path) as GDScript
			assert_true(script != null and script.can_instantiate(), "%s kompilerar inte" % path)


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(d)))
	return out
