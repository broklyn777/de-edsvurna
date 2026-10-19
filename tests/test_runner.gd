extends "res://tests/test_case.gd"
## 0.22.1: köraren själv. Kör fixturerna i tests/fixtures/ i en egen process och kontrollerar att ett körfel och
## en misslyckad assertion båda räknas som underkända (och att körningen avslutas med felkod).


func test_the_runner_catches_errors_and_failed_asserts() -> void:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tests/run_tests.gd", "--", "--dir=res://tests/fixtures/"], out, true)
	var text := "\n".join(out)
	assert_eq(code, 1, "felkod när något test misslyckas")
	assert_true(text.contains("1/3 tester gick igenom"), "bara det godkända testet räknas: " + text.right(300))
	assert_true(text.contains("test_runtime_error_must_fail: körfel"), "körfelet fångas")
	assert_true(text.contains("test_failed_assert_must_fail"), "assertionen fångas")
