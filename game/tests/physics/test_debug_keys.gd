extends "res://tests/physics_base.gd"
## Real test room: the number-row debug keys, driven with real key events.


func test_1_unlocks_roll_and_slam_and_2_relocks_them() -> void:
	await open_room()
	check(not gs.call("has_skill", "roll") and not gs.call("has_skill", "slam"), "locked at the start")
	await key_event(KEY_1)
	check(gs.call("has_skill", "roll") and gs.call("has_skill", "slam"), "1 unlocks roll + slam")
	await key_event(KEY_2)
	check(not gs.call("has_skill", "roll") and not gs.call("has_skill", "slam"), "2 relocks them")


func test_4_takes_one_heart() -> void:
	await open_room()
	await key_event(KEY_4)
	check_eq(gs.hearts, 12, "one heart = 2 half-hearts")


func test_3_respawns_the_dummies() -> void:
	await open_room()
	soft_ledge.call("receive_attack", "slam")
	tall.call("receive_attack", "slam")
	check(not soft_ledge.get("alive") and not tall.get("alive"), "both dead")
	await key_event(KEY_3)
	await frames(2)
	check(soft_ledge.get("alive") and soft_ledge.visible and soft_ledge.get("hp") == 2, "soft is back")
	check(tall.get("alive") and tall.visible and tall.get("hp") == 3, "tall is back")


func test_the_old_function_keys_no_longer_do_anything() -> void:
	await open_room()
	await key_event(KEY_F1)
	check(not gs.call("has_skill", "roll"), "F1 is not bound")
	await key_event(KEY_F4)
	check_eq(gs.hearts, 14, "F4 is not bound")


func test_keypad_numbers_are_not_bound() -> void:
	await open_room()
	await key_event(KEY_KP_4)
	check_eq(gs.hearts, 14, "the number row only")


func test_the_debug_keys_are_not_in_the_input_map() -> void:
	for action: StringName in InputMap.get_actions():
		for ev: InputEvent in InputMap.action_get_events(action):
			var k: InputEventKey = ev as InputEventKey
			if k == null:
				continue
			var code: Key = k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			check(code not in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_F1, KEY_F2, KEY_F3, KEY_F4],
				"%s must not be bound to a debug key" % action)


func test_the_hud_lists_the_new_keys() -> void:
	await open_room()
	await frames(3)
	var text: String = (room.get_node("DebugHud/Text") as Label).text
	check("1 unlock roll+slam" in text and "4 -1 heart" in text, "HUD shows the number keys")
	check("F1" not in text and "F4" not in text, "no F-key text left")
	check("Checkpoint: steamer_start" in text, "HUD shows the checkpoint")
