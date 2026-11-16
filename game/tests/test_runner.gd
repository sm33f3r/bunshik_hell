extends SceneTree
## Run: godot --headless --path game -s res://tests/test_runner.gd
## Discovers res://tests/test_*.gd (except this file), runs every test_* method,
## prints a summary and exits non-zero on any failure.
##
## Failure-path proof: res://tests/fixtures/ holds a deliberately failing test. It is
## NEVER part of a normal run; it only runs with the flag below, and must exit non-zero:
##   godot --headless --path game -s res://tests/test_runner.gd -- --fixtures-only
##
## Tests may be coroutines (use await). The runner gives each suite the SceneTree in `tree`
## and calls `after_each()` after every test if the suite has one.
##
## Real-room physics suites live in res://tests/physics/. They run in real time (60 physics
## frames per second), so they are slow and sit behind a flag:
##   godot --headless --path game -s res://tests/test_runner.gd -- --physics
## Add --only=<text> to run only the test files whose name contains <text>.

const TESTS_DIR := "res://tests/"
const PHYSICS_DIR := "res://tests/physics/"
const FIXTURES_DIR := "res://tests/fixtures/"
const FIXTURES_FLAG := "--fixtures-only"
const PHYSICS_FLAG := "--physics"
const ONLY_PREFIX := "--only="


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dirs: Array[String] = [TESTS_DIR]
	if PHYSICS_FLAG in args:
		dirs.append(PHYSICS_DIR)
	if FIXTURES_FLAG in args:
		dirs = [FIXTURES_DIR]
	var only: String = ""
	for arg: String in args:
		if arg.begins_with(ONLY_PREFIX):
			only = arg.trim_prefix(ONLY_PREFIX)
	var started: int = Time.get_ticks_msec()
	var passed: int = 0
	var failed: int = 0
	var found_any: bool = false
	for dir_path: String in dirs:
		for file_name: String in _discover(dir_path):
			if only != "" and only not in file_name:
				continue
			found_any = true
			var result: Vector2i = await _run_file(dir_path, file_name)
			passed += result.x
			failed += result.y
	if not found_any:
		print("No test files found.")
		quit(1)
		return
	print("")
	print("%d passed, %d failed  (%.1f s)" % [passed, failed, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if failed > 0 else 0)


## Returns Vector2i(passed, failed).
func _run_file(dir_path: String, file_name: String) -> Vector2i:
	var passed: int = 0
	var failed: int = 0
	var script: GDScript = load(dir_path + file_name) as GDScript
	if script == null or not script.can_instantiate():
		print("FAIL  %s: cannot load script" % file_name)
		return Vector2i(0, 1)
	var suite: Object = script.new()
	suite.set("tree", self)
	var file_started: int = Time.get_ticks_msec()
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		suite.set("failures", [] as Array[String])
		await suite.call(method_name)
		if suite.has_method("after_each"):
			await suite.call("after_each")
		var failures: Array = suite.get("failures")
		if failures.is_empty():
			passed += 1
			print("ok    %s::%s" % [file_name, method_name])
		else:
			failed += 1
			print("FAIL  %s::%s" % [file_name, method_name])
			for message: String in failures:
				print("        " + message)
	if dir_path == PHYSICS_DIR:
		print("      (%s: %.1f s)" % [file_name, (Time.get_ticks_msec() - file_started) / 1000.0])
	return Vector2i(passed, failed)


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
