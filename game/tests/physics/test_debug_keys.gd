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
			check(code not in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_F1, KEY_F2, KEY_F3, KEY_F4],
				"%s must not be bound to a debug key" % action)


func test_the_hud_lists_the_new_keys() -> void:
	await open_room()
	await frames(3)
	var text: String = (room.get_node("DebugHud/Text") as Label).text
	check("1 unlock roll+slam" in text and "4 -1 heart" in text, "HUD shows the number keys")
	check("F1" not in text and "F4" not in text, "no F-key text left")
	check("Checkpoint: steamer_start" in text, "HUD shows the checkpoint")


func test_5_unlocks_the_flick_and_2_relocks_it() -> void:
	await open_room()
	check(not gs.call("has_skill", "sauce_flick"), "locked at the start")
	await key_event(KEY_5)
	check(gs.call("has_skill", "sauce_flick"), "5 unlocks the flick")
	await key_event(KEY_2)
	check(not gs.call("has_skill", "sauce_flick"), "2 relocks the flick too")


func test_6_defeats_the_noodle_dummy_and_unlocks_the_flick_once() -> void:
	await open_room()
	var noodle: Node3D = dummy("NoodleDummy")
	check(noodle.get("alive"), "the noodle dummy is alive")
	await key_event(KEY_6)
	check(not noodle.get("alive"), "6 defeated it")
	check(gs.call("has_skill", "sauce_flick"), "the first defeat unlocked the flick")
	await key_event(KEY_3)
	await frames(2)
	check(noodle.get("alive") and noodle.visible, "3 brings it back")
	await key_event(KEY_2) # relock and forget the defeat
	check(not gs.call("has_skill", "sauce_flick"), "relocked")
	await key_event(KEY_6)
	check(gs.call("has_skill", "sauce_flick"), "key 6 can exercise the unlock again after key 2")


func test_3_also_respawns_the_new_dummies() -> void:
	await open_room()
	var small: Node3D = dummy("FriedSmall")
	var medium: Node3D = dummy("FriedMedium")
	var tube_dummy: Node3D = dummy("TubeDummy")
	small.call("debug_defeat")
	medium.call("receive_attack", "sauce")
	tube_dummy.call("receive_attack", "sauce")
	check(not small.get("alive"), "small is dead")
	check_eq(medium.get("stage"), 0, "medium needs 2 hits per stage: still fresh")
	medium.call("receive_attack", "sauce")
	check_eq(medium.get("stage"), 1, "medium is now broken")
	check(tube_dummy.get("jammed"), "tube is jammed")
	await key_event(KEY_3)
	await frames(2)
	check(small.get("alive") and small.visible and small.get("stage") == 0, "small is back, fresh")
	check_eq(medium.get("stage"), 0, "medium is fresh again")
	check(not tube_dummy.get("jammed"), "tube is un-jammed again")


func test_the_hud_shows_sauce_type_flick_state_cooldown_and_fried_stages() -> void:
	await open_room()
	await frames(3)
	var text: String = (room.get_node("DebugHud/Text") as Label).text
	check("Sauce: 3 / 7" in text, "sauce x/7")
	check("Sauce type: gochujang" in text, "current sauce type")
	check("Flick: locked" in text, "flick locked")
	check("Cooldown: 0.00" in text, "cooldown")
	check("FriedSmall=fresh" in text and "FriedMedium=fresh" in text and "FriedLarge=fresh" in text, "fried stages")
	check("5 unlock flick" in text and "6 defeat noodle dummy" in text, "new keys listed")
	await key_event(KEY_5)
	await frames(3)
	check("Flick: unlocked" in (room.get_node("DebugHud/Text") as Label).text, "flick unlocked")
	dummy("FriedSmall").call("receive_attack", "stomp")
	await frames(3)
	check("FriedSmall=broken" in (room.get_node("DebugHud/Text") as Label).text, "stage follows the dummy")
