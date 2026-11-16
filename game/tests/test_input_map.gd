extends "res://tests/base_test.gd"

const ACTIONS: Array[String] = [
	"move_left", "move_right", "look_up", "look_down", "jump", "roll",
	"sauce_attack", "special", "sauce_next", "sauce_prev", "heal",
	"inventory", "pause", "aim_left", "aim_right", "aim_up", "aim_down",
]
## aim_* are joypad-only for now.
const KEYBOARD_MOUSE_ACTIONS: Array[String] = [
	"move_left", "move_right", "look_up", "look_down", "jump", "roll",
	"sauce_attack", "special", "sauce_next", "sauce_prev", "heal",
	"inventory", "pause",
]


func _has_type(action: String, type_name: String) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event.is_class(type_name):
			return true
	return false


func test_all_actions_exist() -> void:
	for action: String in ACTIONS:
		check(InputMap.has_action(action), "missing action " + action)


func test_every_action_has_joypad() -> void:
	for action: String in ACTIONS:
		var pad: bool = _has_type(action, "InputEventJoypadButton") or _has_type(action, "InputEventJoypadMotion")
		check(pad, "no joypad binding for " + action)


func test_keyboard_or_mouse_bindings() -> void:
	for action: String in KEYBOARD_MOUSE_ACTIONS:
		var km: bool = _has_type(action, "InputEventKey") or _has_type(action, "InputEventMouseButton")
		check(km, "no keyboard/mouse binding for " + action)


func test_no_stomp_or_slam_actions() -> void:
	check(not InputMap.has_action("stomp"), "stomp must not be an action")
	check(not InputMap.has_action("slam"), "slam must not be an action")
