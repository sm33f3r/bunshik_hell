extends "res://tests/base_test.gd"
## Deliberately broken fixture. Only run with: -- --fixtures-only --only=script_error
## Proves the runner fails a test whose script hits a runtime error, even though no check failed:
## the first test errors at once, the second only after an await (as the physics tests do).


func test_script_error_before_any_check() -> void:
	var nothing: Node = null
	nothing.queue_free() # a null call: "SCRIPT ERROR", the function is aborted
	check(true, "never reached")


func test_script_error_after_an_await() -> void:
	await tree.process_frame
	var numbers: Array[int] = [1, 2, 3]
	var bad: int = numbers[10] # out of bounds: a script error
	check(bad == 0, "never reached")
