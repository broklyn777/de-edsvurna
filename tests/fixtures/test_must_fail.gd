extends "res://tests/test_case.gd"
## Tester som MÅSTE misslyckas. Körs bara av tests/test_runner.gd (mappen fixtures), aldrig i den vanliga körningen.


func test_runtime_error_must_fail() -> void:
	var d := {}
	var x: int = d.missing_key  # körfel: nyckeln saknas
	assert_eq(x, 1)


func test_failed_assert_must_fail() -> void:
	assert_eq(1 + 1, 3, "avsiktligt fel")


func test_this_one_passes() -> void:
	assert_eq(2, 2)
