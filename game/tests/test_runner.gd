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
##
## A GDScript runtime error (a null call, a bad index, a wrong type...) inside a test or in anything it
## runs aborts that function and prints "SCRIPT ERROR", but the test then has no failed check, so it
## used to count as a pass. The runner now listens to the engine's log (OS.add_logger) and fails the
## test that was running when a script error was reported (res://tests/fixtures/test_script_error.gd
## proves it, see test_runner_failure.gd). Engine errors that are not script errors (the known
## "!is_inside_tree()" noise) are not counted.

const TESTS_DIR := "res://tests/"
const PHYSICS_DIR := "res://tests/physics/"
const FIXTURES_DIR := "res://tests/fixtures/"
const FIXTURES_FLAG := "--fixtures-only"
const PHYSICS_FLAG := "--physics"
const ONLY_PREFIX := "--only="


## Collects the script errors the engine logs. _log_error may be called from any thread.
class ScriptErrorLogger extends Logger:
	var messages: Array[String] = []
	var _mutex: Mutex = Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_SCRIPT:
			return
		var text: String = rationale if rationale != "" else code
		_mutex.lock()
		messages.append("SCRIPT ERROR in %s:%d (%s): %s" % [file.get_file(), line, function, text])
		_mutex.unlock()

	## Returns what was collected and forgets it.
	func take() -> Array[String]:
		_mutex.lock()
		var out: Array[String] = messages.duplicate()
		messages.clear()
		_mutex.unlock()
		return out


var _logger: ScriptErrorLogger


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
	_logger = ScriptErrorLogger.new()
	OS.add_logger(_logger)
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
	_logger.take() # whatever was logged before this file is not this file's
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
		for error_text: String in _logger.take():
			failures.append(error_text) # a script error inside the test (or what it ran) is a failure
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
