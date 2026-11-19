extends "res://tests/base_test.gd"

const ACTIONS: Array[String] = [
	"move_left", "move_right", "look_up", "look_down", "jump", "roll",
	"sauce_attack", "special", "sauce_next", "sauce_prev", "heal",
	"inventory", "drop_item", "pause", "aim_left", "aim_right", "aim_up", "aim_down",
]
## aim_* are joypad-only for now.
const KEYBOARD_MOUSE_ACTIONS: Array[String] = [
	"move_left", "move_right", "look_up", "look_down", "jump", "roll",
	"sauce_attack", "special", "sauce_next", "sauce_prev", "heal",
	"inventory", "drop_item", "pause",
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


func _joy_buttons(action: String) -> Array[int]:
	var out: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var b: InputEventJoypadButton = event as InputEventJoypadButton
		if b != null:
			out.append(b.button_index)
	return out


func test_dualsense_inventory_is_on_the_touchpad_not_create() -> void:
	var buttons: Array[int] = _joy_buttons("inventory")
	check(JOY_BUTTON_TOUCHPAD in buttons, "inventory is on the touchpad button")
	check(JOY_BUTTON_BACK not in buttons, "no longer on Back / Create")
	check(JOY_BUTTON_BACK not in _joy_buttons("drop_item") and JOY_BUTTON_TOUCHPAD not in _joy_buttons("pause"), "no clashes")
	var keys: Array[int] = []
	for event: InputEvent in InputMap.action_get_events("inventory"):
		var k: InputEventKey = event as InputEventKey
		if k != null:
			keys.append(k.physical_keycode)
	check(KEY_TAB in keys, "keyboard stays Tab")
