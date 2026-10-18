extends RefCounted
## Basklass för tester. Ärv och skriv metoder som börjar med `test_`.

var runner: Object


func assert_true(value: bool, message := "förväntade true") -> void:
	if not value:
		runner.fail(message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		runner.fail("%s förväntade %s, fick %s" % [message, str(expected), str(actual)])


func assert_near(actual: float, expected: float, tolerance := 0.001, message := "") -> void:
	if absf(actual - expected) > tolerance:
		runner.fail("%s förväntade %s ± %s, fick %s" % [message, expected, tolerance, actual])
