extends "res://tests/map1_base.gd"
## Task 3c-i-a-fix4, real Map 1 scene, REAL input: walk to the kitchen door, press W, arrive in the
## kitchen, press W, come back; a locked door (the flag forced off) gives feedback and stays shut; dying
## keeps the flag; W does nothing outside the zone or while the game is paused.

const WallDoorScript := preload("res://maps/layout/wall_door.gd")

const FLAG: String = "ramen1_defeated"


func door(id: String = "kitchen_door") -> WallDoorScript:
	return flow.builder.door_nodes.get(id)


## The dining room, the skip done, standing on the open floor before the dispenser.
func open_floor() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	teleport(plat("chair_kf_t2_9").right + 12.0, plat("kitchen_floor").top + 0.5)
	await until(func() -> bool: return player.get("grounded"), 90)
	await frames(10)


## Walks (real input) until he stands in front of x.
func walk_to(x: float) -> void:
	var action: String = "move_right" if x > player.global_position.x else "move_left"
	var side: float = signf(x - player.global_position.x)
	Input.action_press(action)
	await until(func() -> bool: return (x - player.global_position.x) * side <= 0.5, 900)
	Input.action_release(action)
	await frames(30)


## Press W and wait out the fade.
func press_w() -> void:
	await tap("look_up")
	await frames(2)
	await until(func() -> bool: return flow.phase == MapFlowScript.Phase.IDLE, 180)
	await frames(10)


func in_kitchen() -> bool:
	var lane: LayoutGeometryScript.Placed = plat("kitchen_room_floor")
	return player.global_position.x >= lane.left and player.global_position.x <= lane.right


func test_walk_to_the_door_press_w_arrive_in_the_kitchen_and_w_back() -> void:
	await open_floor()
	var there: WallDoorScript = door()
	var back: WallDoorScript = door("kitchen_arrival_door")
	check(not there.prompt_visible(), "no glyph from afar")
	await walk_to(there.global_position.x)
	check(there.near, "in the zone: " + describe())
	check(there.prompt_visible() and "W" in there.prompt_text(), "the W glyph: " + there.prompt_text())
	check_eq(there.highlight, WallDoorScript.Highlight.BRIGHT, "highlighted")
	var max_alpha: float = 0.0
	Input.action_press("look_up")
	for i: int in 90:
		await tree.physics_frame
		max_alpha = maxf(max_alpha, flow.ui.fade_alpha())
		if i == 2:
			Input.action_release("look_up")
	check(max_alpha > 0.9, "behind a fade (%.2f)" % max_alpha)
	check_eq(flow.ui.fade_alpha(), 0.0, "which clears again")
	check(in_kitchen(), "in the kitchen: " + describe())
	check(absf(player.global_position.x - back.global_position.x) < 0.2, "at the arrival door: " + describe())
	check(player.get("grounded") and back.near, "standing in its zone")
	check(flow.enabled_sections.has("kitchen"), "the section is on")
	check_eq(gs.checkpoint_id, "kitchen_start", "the kitchen's checkpoint")
	check(back.prompt_visible(), "its glyph is up")
	await press_w()
	check(not in_kitchen(), "back in the dining room: " + describe())
	check(absf(player.global_position.x - there.global_position.x) < 0.2 and there.near, "at the dining door: " + describe())


func test_the_kitchen_is_walled_at_both_ends() -> void:
	await open_floor()
	await walk_to(door().global_position.x)
	await press_w()
	var lane: LayoutGeometryScript.Placed = plat("kitchen_room_floor")
	Input.action_press("move_right")
	await frames(400)
	Input.action_release("move_right")
	check(player.global_position.x < lane.right and player.global_position.x > lane.right - 2.0, "the end wall: " + describe())
	Input.action_press("move_left")
	await frames(500)
	Input.action_release("move_left")
	check(player.global_position.x > lane.left and player.global_position.x < lane.left + 2.0, "the left wall: " + describe())


func test_walking_past_the_door_goes_to_the_end_wall_and_w_outside_the_zone_does_nothing() -> void:
	await open_floor()
	var there: WallDoorScript = door()
	var lane: LayoutGeometryScript.Placed = plat("kitchen_floor")
	await walk_to(there.global_position.x - 3.0)
	check(not there.near, "outside the zone: " + describe())
	await press_w()
	check(not in_kitchen() and absf(player.global_position.x - there.global_position.x) > 1.5, "nothing: " + describe())
	Input.action_press("move_right")
	await frames(240)
	Input.action_release("move_right")
	check(player.global_position.x > there.global_position.x + 3.0, "nothing solid at the door: " + describe())
	check(player.global_position.x < lane.right + 0.01, "the end wall stops him")


func test_a_locked_door_gives_feedback_and_does_not_open() -> void:
	await open_floor()
	gs.get("debug_flag_overrides")[FLAG] = false
	var there: WallDoorScript = door()
	await walk_to(there.global_position.x)
	check(there.near and there.highlight == WallDoorScript.Highlight.DIM, "dim: " + describe())
	check(not there.lock_visible(), "no padlock before he tries")
	var at: Vector3 = player.global_position
	await tap("look_up")
	check(there.shaking() and there.lock_visible(), "it shakes and shows the padlock")
	check_eq(there.locked_tries, 1, "once")
	await frames(120)
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "no fade")
	check_eq(flow.ui.fade_alpha(), 0.0, "no black")
	check(player.global_position.distance_to(at) < 0.2, "he stays: " + describe())
	check(not there.shaking() and not there.lock_visible(), "and the feedback ends")
	gs.get("debug_flag_overrides").clear()
	await frames(2)
	await press_w()
	check(in_kitchen(), "unlocked again it opens: " + describe())


func test_dying_and_respawning_keeps_the_flag() -> void:
	await open_floor()
	gs.call("set_flag", FLAG, false)
	var there: WallDoorScript = door()
	await put_on("kf_t1", 2.0)
	check(await until(func() -> bool: return gs.checkpoint_id == "kitchen_front_start", 60), "checkpoint")
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 60), "he died")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400), "and came back")
	check(not gs.call("has_flag", FLAG) and there.is_locked(), "still locked")
	gs.call("set_flag", FLAG, true)
	teleport(there.global_position.x, there.global_position.y + 0.5)
	await until(func() -> bool: return player.get("grounded"), 90)
	await frames(6)
	await press_w()
	check(in_kitchen(), "open once set: " + describe())
	await frames(30)
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 60), "he died in the kitchen")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400), "and came back")
	await frames(30)
	check(in_kitchen(), "in the kitchen, at its checkpoint: " + describe())
	check(gs.call("has_flag", FLAG) and gs.get("flags").get(FLAG) == true, "the flag is still set")


func test_w_in_a_paused_game_does_not_open_the_door() -> void:
	await open_floor()
	await walk_to(door().global_position.x)
	tree.paused = true
	await tap("look_up")
	await frames(20)
	tree.paused = false
	await frames(40)
	check(not in_kitchen() and flow.phase == MapFlowScript.Phase.IDLE, "still outside: " + describe())
