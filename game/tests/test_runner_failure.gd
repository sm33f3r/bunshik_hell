extends "res://tests/base_test.gd"
## Proves the runner's failure path: the deliberately failing fixture must make a real
## runner process exit non-zero. The fixture lives in res://tests/fixtures/ and is never
## picked up by a normal run (the runner only scans res://tests/ itself).


func test_fixture_is_not_part_of_a_normal_run() -> void:
	var normal: PackedStringArray = DirAccess.get_files_at("res://tests/")
	check("test_always_fails.gd" not in normal, "fixture must not sit in res://tests/")
	check("test_always_fails.gd" in DirAccess.get_files_at("res://tests/fixtures/"), "fixture exists")


## Runs the runner as a real process on the fixtures whose name contains `only`.
func _run_fixture(only: String) -> Dictionary:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"-s", "res://tests/test_runner.gd", "--", "--fixtures-only", "--only=" + only,
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	return {"code": code, "text": "\n".join(PackedStringArray(output))}


func test_runner_exits_non_zero_for_the_failing_fixture() -> void:
	var run: Dictionary = _run_fixture("always_fails")
	check(run["code"] != 0, "runner must exit non-zero (got %d)" % run["code"])
	check("FAIL  test_always_fails.gd::test_fails_on_purpose" in run["text"], "runner must print the failure")
	check("0 passed, 1 failed" in run["text"], "runner must print the summary")


## A runtime error in a test script (before or after an await) used to count as a pass.
func test_runner_exits_non_zero_for_a_script_error_in_a_test() -> void:
	var run: Dictionary = _run_fixture("script_error")
	var text: String = run["text"]
	check(run["code"] != 0, "runner must exit non-zero for a script error (got %d)" % run["code"])
	check("FAIL  test_script_error.gd::test_script_error_before_any_check" in text, "the immediate error is a failure")
	check("FAIL  test_script_error.gd::test_script_error_after_an_await" in text, "so is the one after an await")
	check("SCRIPT ERROR in test_script_error.gd" in text, "and the failure says what it was")
	check("0 passed, 2 failed" in text, "runner must print the summary: " + text)
