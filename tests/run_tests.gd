extends SceneTree
## Minimal testkörare. Kör alla `tests/test_*.gd` och deras `test_*`-metoder.
##   godot --headless --path . --script res://tests/run_tests.gd

const TEST_DIR := "res://tests/"

var _failures: Array[String] = []
var _current := ""


func _init() -> void:
	var passed := 0
	var total := 0
	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(TEST_DIR + file)
		if script == null or not script.can_instantiate():
			total += 1
			_current = file
			fail("skriptet gick inte att kompilera")
			continue
		var suite: Object = script.new()
		suite.set("runner", self)
		for method in suite.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			_current = "%s::%s" % [file, name]
			var before := _failures.size()
			suite.call(name)
			if _failures.size() == before:
				passed += 1
	for failure in _failures:
		printerr("FAIL  " + failure)
	print("%d/%d tester gick igenom" % [passed, total])
	quit(0 if _failures.is_empty() else 1)


func fail(message: String) -> void:
	_failures.append("%s: %s" % [_current, message])
