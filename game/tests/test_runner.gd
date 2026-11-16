extends SceneTree
## Run: godot --headless --path game -s res://tests/test_runner.gd
## Discovers res://tests/test_*.gd (except this file), runs every test_* method,
## prints a summary and exits non-zero on any failure.
##
## Failure-path proof: res://tests/fixtures/ holds a deliberately failing test. It is
## NEVER part of a normal run; it only runs with the flag below, and must exit non-zero:
##   godot --headless --path game -s res://tests/test_runner.gd -- --fixtures-only

const TESTS_DIR := "res://tests/"
const FIXTURES_DIR := "res://tests/fixtures/"
const FIXTURES_FLAG := "--fixtures-only"


func _init() -> void:
	var dir_path: String = FIXTURES_DIR if FIXTURES_FLAG in OS.get_cmdline_user_args() else TESTS_DIR
	var passed: int = 0
	var failed: int = 0
	var files: Array[String] = _discover(dir_path)
	if files.is_empty():
		print("No test files found.")
		quit(1)
		return
	for file_name: String in files:
		var script: GDScript = load(dir_path + file_name) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL  %s: cannot load script" % file_name)
			failed += 1
			continue
		var suite: Object = script.new()
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			suite.set("failures", [] as Array[String])
			suite.call(method_name)
			var failures: Array = suite.get("failures")
			if failures.is_empty():
				passed += 1
				print("ok    %s::%s" % [file_name, method_name])
			else:
				failed += 1
				print("FAIL  %s::%s" % [file_name, method_name])
				for message: String in failures:
					print("        " + message)
	print("")
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _discover(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	for file_name: String in dir.get_files():
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd":
			found.append(file_name)
	found.sort()
	return found
