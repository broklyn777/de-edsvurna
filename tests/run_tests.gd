extends SceneTree
## Testkörare. Kör alla `tests/test_*.gd` och deras `test_*`-metoder.
##   godot --headless --path . --script res://tests/run_tests.gd
##   … -- --dir=res://tests/fixtures/   kör en annan mapp (testerna av köraren själv)
## 0.22.1: ett körfel i ett test (t.ex. en nyckel som saknas) fångas av en Logger och gör testet underkänt.
## Förut avbröts metoden tyst och räknades som godkänd.

var _failures: Array[String] = []
var _current := ""
var _catcher := ErrorCatcher.new()


## Samlar skriptfel och motorfel medan ett test körs.
class ErrorCatcher extends Logger:
	var errors: Array[String] = []
	var active := false

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if not active:
			return
		var what := rationale if rationale != "" else code
		errors.append("%s (%s:%d %s)" % [what, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _init() -> void:
	var dir := "res://tests/"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.get_slice("=", 1)
	OS.add_logger(_catcher)
	var passed := 0
	var total := 0
	for file in DirAccess.get_files_at(dir):
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(dir + file)
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
			_catcher.errors.clear()
			_catcher.active = true
			suite.call(name)
			_catcher.active = false
			for err in _catcher.errors:
				fail("körfel: " + err)
			if _failures.size() == before:
				passed += 1
	for failure in _failures:
		printerr("FAIL  " + failure)
	print("%d/%d tester gick igenom" % [passed, total])
	quit(0 if _failures.is_empty() else 1)


func fail(message: String) -> void:
	_failures.append("%s: %s" % [_current, message])
