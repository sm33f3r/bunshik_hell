extends "res://tests/base_test.gd"
## Proves the runner's failure path: the deliberately failing fixture must make a real
## runner process exit non-zero. The fixture lives in res://tests/fixtures/ and is never
## picked up by a normal run (the runner only scans res://tests/ itself).


func test_fixture_is_not_part_of_a_normal_run() -> void:
	var normal: PackedStringArray = DirAccess.get_files_at("res://tests/")
	check("test_always_fails.gd" not in normal, "fixture must not sit in res://tests/")
	check("test_always_fails.gd" in DirAccess.get_files_at("res://tests/fixtures/"), "fixture exists")


func test_runner_exits_non_zero_for_the_failing_fixture() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"-s", "res://tests/test_runner.gd", "--", "--fixtures-only",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	check(code != 0, "runner must exit non-zero (got %d)" % code)
	check("FAIL  test_always_fails.gd::test_fails_on_purpose" in text, "runner must print the failure")
	check("0 passed, 1 failed" in text, "runner must print the summary")
