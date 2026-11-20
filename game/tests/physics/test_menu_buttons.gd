extends "res://tests/physics_base.gd"
## F1 with real gamepad events (swapped in 2c-fix): in the popup and the inventory screen the south
## button (cross, JOY_BUTTON_A) confirms and the east button (circle, JOY_BUTTON_B) cancels, and the
## press that closes a menu does not reach the game that unpauses (no jump, roll or flick).


func _pad(button: JoyButton, pressed: bool) -> void:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)


## Press a pad button for two idle frames like a real tap, then let go.
func _pad_tap(button: JoyButton) -> void:
	_pad(button, true)
	await tree.process_frame
	await tree.process_frame
	_pad(button, false)
	await tree.process_frame


func _ui() -> Node:
	return room.get_node("InventoryUi")


func _stand() -> void:
	park(soft_floor, 16.0)
	park(tall, 17.0)
	teleport(-8.0, 0.33)
	await frames(30)


func _open_popup(item: String = "ggul") -> void:
	gs.call("try_equip_container", "starter_container")
	for id: String in ["kongomul", "kongomul", "jocheong"]:
		gs.call("try_pickup_item", id)
	gs.call("take_damage", 6)
	gs.call("open_popup", item)
	await frames(8) # past the open guard


func _max_height_over(n: int) -> float:
	var top: float = player.global_position.y
	for i: int in n:
		await tree.physics_frame
		top = maxf(top, player.global_position.y)
	return top


func test_cross_confirms_use_it_now_in_the_popup() -> void:
	await open_room()
	await _stand()
	await _open_popup()
	check(gs.popup_open() and tree.paused, "popup open, game paused")
	check_eq(_ui().get("popup_choice"), 0, "use it now is selected")
	await _pad_tap(JOY_BUTTON_A)
	await frames(4)
	check(not gs.popup_open(), "the cross confirmed and closed the popup")
	check_eq(gs.hearts, 10, "use it now: the 조청 healed 1 heart (8 + 2)")
	check_eq(gs.items.size(), 3, "the carried items stayed")


func test_cross_drops_it_when_drop_it_is_selected() -> void:
	await open_room()
	await _stand()
	await _open_popup()
	await tap("ui_right")
	await frames(3)
	check_eq(_ui().get("popup_choice"), 1, "drop it is selected")
	await _pad_tap(JOY_BUTTON_A)
	await frames(4)
	check(not gs.popup_open(), "closed")
	check_eq(gs.hearts, 8, "nothing was used")
	check_eq(gs.items.size(), 3, "and the item stayed on the ground, not in the inventory")


func test_circle_cancels_and_closes_the_popup_without_a_roll() -> void:
	await open_room()
	await _stand()
	gs.call("unlock_skill", "roll")
	await _open_popup()
	var x0: float = player.global_position.x
	await _pad_tap(JOY_BUTTON_B)
	check(not gs.popup_open(), "the circle closed the popup")
	check_eq(gs.hearts, 8, "and used nothing")
	var rolled: bool = false
	for i: int in 30:
		await tree.physics_frame
		rolled = rolled or state() == "roll"
	check(not rolled, "the closing circle did not start a roll")
	check(absf(player.global_position.x - x0) < 0.05, "and he did not move")


func test_cross_in_the_popup_does_not_jump_the_ddeok() -> void:
	await open_room()
	await _stand()
	await _open_popup()
	var base: float = player.global_position.y
	await _pad_tap(JOY_BUTTON_A)
	check(not gs.popup_open(), "the cross confirmed and closed the popup")
	var top: float = await _max_height_over(30)
	check(top - base < 0.05, "no jump from the confirming cross: rose %.2f m" % (top - base))
	check(player.call("state_name") != "jump", "state: " + state())


func test_the_square_that_drops_in_the_popup_does_not_fire_the_flick() -> void:
	await open_room()
	await _stand()
	gs.call("unlock_skill", "sauce_flick")
	await _open_popup()
	var sauce: int = gs.sauce
	await _pad_tap(JOY_BUTTON_X)
	check(not gs.popup_open(), "the square dropped it and closed the popup")
	await frames(20)
	check_eq(gs.sauce, sauce, "no sauce was spent")
	check_eq(flicks().size(), 0, "no flick flew")


func test_the_inventory_screen_cross_uses_and_circle_closes_without_a_roll() -> void:
	await open_room()
	await _stand()
	gs.call("try_equip_container", "starter_container")
	for id: String in ["jocheong", "kongomul"]:
		gs.call("try_pickup_item", id)
	gs.call("take_damage", 6)
	await tap("inventory")
	await frames(8)
	check(_ui().get("screen_open") and tree.paused, "the screen is open")
	await _pad_tap(JOY_BUTTON_A)
	await frames(3)
	check_eq(gs.hearts, 10, "the cross used the first item (+1 heart)")
	check_eq(gs.items.size(), 1, "one item left")
	check(_ui().get("screen_open"), "the screen stays open after using")
	var base: float = player.global_position.y
	var x0: float = player.global_position.x
	gs.call("unlock_skill", "roll")
	await _pad_tap(JOY_BUTTON_B)
	check(not _ui().get("screen_open"), "the circle closed the screen")
	check(not tree.paused, "unpaused")
	var rolled: bool = false
	var top: float = base
	for i: int in 30:
		await tree.physics_frame
		rolled = rolled or state() == "roll"
		top = maxf(top, player.global_position.y)
	check(not rolled, "the closing circle did not start a roll")
	check(absf(player.global_position.x - x0) < 0.05 and top - base < 0.05, "and he neither moved nor jumped")


func test_space_that_confirms_on_the_keyboard_does_not_jump_either() -> void:
	await open_room()
	await _stand()
	await _open_popup()
	var base: float = player.global_position.y
	var e: InputEventKey = InputEventKey.new()
	e.keycode = KEY_SPACE
	e.physical_keycode = KEY_SPACE
	e.pressed = true
	Input.parse_input_event(e)
	await tree.process_frame
	await tree.process_frame
	e = e.duplicate() as InputEventKey
	e.pressed = false
	Input.parse_input_event(e)
	await tree.process_frame
	check(not gs.popup_open(), "Space confirmed the popup (the keyboard is unchanged)")
	var top: float = await _max_height_over(30)
	check(top - base < 0.05, "and it did not jump: rose %.2f m" % (top - base))


func test_a_fresh_cross_press_after_the_menu_closed_does_jump() -> void:
	await open_room()
	await _stand()
	await _open_popup()
	await _pad_tap(JOY_BUTTON_B)
	await frames(10)
	var base: float = player.global_position.y
	_pad(JOY_BUTTON_A, true)
	var top: float = await _max_height_over(20)
	_pad(JOY_BUTTON_A, false)
	check(top - base > 0.5, "control: a real jump press after the menu closed works: rose %.2f m" % (top - base))
