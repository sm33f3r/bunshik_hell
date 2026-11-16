extends RefCounted
## Base for test suites. Methods named test_* are run by test_runner.gd.

var failures: Array[String] = []
## Set by the runner; needed by suites that load scenes.
var tree: SceneTree


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
