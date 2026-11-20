extends "res://tests/base_test.gd"
## F1 (swapped in 2c-fix): in the popup and the inventory screen, the south button (JOY_BUTTON_A,
## the cross on a DualSense) confirms and the east button (JOY_BUTTON_B, the circle) cancels. Keyboard stays.
## And the press that closes a menu must not act in the game that unpauses.

const InventoryUiScript := preload("res://ui/inventory_ui.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")


func _joy_buttons(action: String) -> Array[int]:
	var out: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var b: InputEventJoypadButton = event as InputEventJoypadButton
		if b != null:
			out.append(b.button_index)
	return out


func _keys(action: String) -> Array[int]:
	var out: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var k: InputEventKey = event as InputEventKey
		if k != null:
			out.append(k.keycode if k.keycode != 0 else k.physical_keycode)
	return out


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	return e


func test_south_button_confirms_and_east_button_cancels() -> void:
	check_eq(JOY_BUTTON_A, 0, "JOY_BUTTON_A is the south button (index 0) in 4.7.2")
	check_eq(JOY_BUTTON_B, 1, "JOY_BUTTON_B is the east button (index 1) in 4.7.2")
	check(JOY_BUTTON_A in _joy_buttons("ui_accept"), "ui_accept has the south button (cross)")
	check(JOY_BUTTON_B not in _joy_buttons("ui_accept"), "ui_accept no longer has the east button")
	check(JOY_BUTTON_B in _joy_buttons("ui_cancel"), "ui_cancel has the east button (circle)")
	check(JOY_BUTTON_A not in _joy_buttons("ui_cancel"), "ui_cancel no longer has the south button")
	check(_pad(JOY_BUTTON_A).is_action("ui_accept"), "a cross press is ui_accept")
	check(_pad(JOY_BUTTON_B).is_action("ui_cancel"), "a circle press is ui_cancel")
	check(not _pad(JOY_BUTTON_B).is_action("ui_accept"), "a circle press is not ui_accept")
	check(not _pad(JOY_BUTTON_A).is_action("ui_cancel"), "a cross press is not ui_cancel")


func test_the_keyboard_confirm_and_cancel_stay() -> void:
	var accept: Array[int] = _keys("ui_accept")
	check(KEY_ENTER in accept and KEY_SPACE in accept and KEY_KP_ENTER in accept, "Enter, Space and keypad Enter confirm")
	check(KEY_ESCAPE in _keys("ui_cancel"), "Esc cancels")


func test_the_drop_button_stays_on_square() -> void:
	check(JOY_BUTTON_X in _joy_buttons("drop_item"), "drop is the west button (square)")


func test_closing_the_screen_or_the_popup_blocks_gameplay_presses_for_two_ticks() -> void:
	GameplayInputScript.clear()
	check(not GameplayInputScript.is_blocked(), "nothing is blocked to start with")
	var gs: GameStateScript = GameStateScript.new()
	var ui: InventoryUiScript = InventoryUiScript.new()
	ui.game_state = gs
	ui.open_screen()
	check(not GameplayInputScript.is_blocked(), "opening does not block gameplay")
	ui.close_screen()
	check(GameplayInputScript.is_blocked(), "closing the screen blocks")
	for action: StringName in [&"jump", &"roll", &"sauce_attack", &"special", &"heal", &"look_down"]:
		Input.action_press(action)
		check(not GameplayInputScript.just_pressed(action), "a press right after closing is not reported: " + String(action))
		Input.action_release(action)
	await tree.physics_frame
	check(GameplayInputScript.is_blocked(), "still blocked one tick later")
	await tree.physics_frame
	await tree.physics_frame
	check(not GameplayInputScript.is_blocked(), "free again after two ticks")
	ui._on_popup_closed()
	check(GameplayInputScript.is_blocked(), "closing the popup blocks too")
	GameplayInputScript.clear()
	check(not GameplayInputScript.is_blocked(), "clear() lifts it")
	ui.free()
	gs.free()


func test_the_block_does_not_touch_held_movement() -> void:
	GameplayInputScript.swallow()
	Input.action_press("move_right")
	check(Input.is_action_pressed("move_right"), "a held direction keeps walking")
	check(is_equal_approx(Input.get_axis("move_left", "move_right"), 1.0), "the axis is untouched")
	Input.action_release("move_right")
	GameplayInputScript.clear()
