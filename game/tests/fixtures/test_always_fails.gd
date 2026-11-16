extends "res://tests/base_test.gd"
## Deliberately failing fixture. Only run with: -- --fixtures-only
## Proves the runner reports failures and exits non-zero.


func test_fails_on_purpose() -> void:
	check(false, "this failure is deliberate")
	check_eq(1 + 1, 3, "arithmetic is deliberately wrong")
