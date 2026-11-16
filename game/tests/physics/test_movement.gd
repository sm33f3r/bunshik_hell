extends "res://tests/physics_base.gd"
## Real test room: run, jump, coyote time, wall, Z lock, visual flip. Input is simulated with
## Input.action_press / parse_input_event; time advances in physics frames.

const MAX_SPEED := 5.5


func test_spawns_on_the_floor_at_the_start_steamer() -> void:
	await open_room()
	check(player.get("grounded"), "grounded after settling")
	check(absf(player.global_position.y - 0.32) < 0.05, "standing on the floor, y=%.3f" % player.global_position.y)
	check_eq(gs.checkpoint_id, "steamer_start", "start steamer is the first checkpoint")
	var start: Node3D = room.get_node("Steamers/SteamerStart")
	check(absf(player.global_position.x - start.call("spawn_point").x) < 0.3, "spawned at the start steamer")
	check_eq(state(), "idle", "idle at rest")


func test_z_stays_locked_while_running_and_jumping() -> void:
	await open_room()
	Input.action_press("move_right")
	Input.action_press("jump")
	var worst: float = 0.0
	for i: int in 120:
		await tree.physics_frame
		worst = maxf(worst, absf(player.global_position.z))
	check(worst < 0.0001, "max |z| was %f" % worst)


func test_full_push_reaches_max_speed_and_release_stops() -> void:
	await open_room()
	Input.action_press("move_right")
	await frames(40)
	check(absf(player.velocity.x - MAX_SPEED) < 0.1, "full speed, got %.2f" % player.velocity.x)
	check_eq(state(), "squiggle", "squiggling while running")
	Input.action_release("move_right")
	await frames(20)
	check(is_zero_approx(player.velocity.x), "stopped, got %.2f" % player.velocity.x)
	check_eq(state(), "idle", "idle again")


func test_speed_follows_input_strength() -> void:
	await open_room()
	park(soft_floor, -30.0) # nothing to bump into
	park(tall, -30.0)
	teleport(-2.0, 0.33)
	await frames(10)
	Input.action_press("move_left", 0.5)
	await frames(30)
	check(absf(player.velocity.x + MAX_SPEED * 0.5) < 0.1, "half push = half speed, got %.2f" % player.velocity.x)
	check(float(player.get("facing")) < 0.0, "faces left")
	Input.action_release("move_left")
	Input.action_press("move_right", 0.25)
	await frames(30)
	check(absf(player.velocity.x - MAX_SPEED * 0.25) < 0.1, "quarter push, got %.2f" % player.velocity.x)


func test_a_light_analog_stick_push_moves_him() -> void:
	# A real joypad axis event goes through the action's deadzone (0.2). Godot remaps the
	# strength to (|v| - deadzone) / (1 - deadzone), so a 0.5 push is 0.375, not 0.5.
	await open_room()
	var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = 0.5
	Input.parse_input_event(e)
	await frames(30)
	var speed: float = player.velocity.x
	check(speed > 0.0, "a half push must move him (got %.2f)" % speed)
	check(absf(speed - MAX_SPEED * 0.375) < 0.2, "half push = remapped 0.375 strength, got %.2f" % speed)
	e.axis_value = 0.1 # inside the 0.2 deadzone
	Input.parse_input_event(e)
	await frames(30)
	check(is_zero_approx(player.velocity.x), "inside the deadzone does nothing, got %.2f" % player.velocity.x)
	e.axis_value = 0.0
	Input.parse_input_event(e)


func test_visual_flips_with_direction_and_squiggles_but_collision_never_changes() -> void:
	await open_room()
	var pivot: Node3D = player.get_node("FacingPivot")
	var vis: Node3D = player.get_node("FacingPivot/Visual")
	var shape: CapsuleShape3D = (player.get_node("CollisionShape3D") as CollisionShape3D).shape
	Input.action_press("move_right")
	var smin: float = 9.0
	var smax: float = 0.0
	for i: int in 90:
		await tree.physics_frame
		smin = minf(smin, vis.scale.x)
		smax = maxf(smax, vis.scale.x)
		check(is_equal_approx(shape.radius, 0.32) and is_equal_approx(shape.height, 0.96), "collision unchanged")
	check(smax - smin > 0.1, "squiggle deforms the visual (%.3f..%.3f)" % [smin, smax])
	check(pivot.scale.x > 0.0, "faces right")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(5)
	check(pivot.scale.x < 0.0, "mirrored when facing left")


func test_full_jump_is_about_two_metres_and_a_short_hop_is_lower() -> void:
	await open_room()
	var full: float = await jump_peak(60)
	var hop: float = await jump_peak(3)
	check(full > 1.8 and full < 2.4, "full jump peak %.2f m" % full)
	check(hop < full * 0.6, "short hop %.2f m is well below %.2f m" % [hop, full])
	check(hop > 0.1, "short hop still leaves the ground (%.2f m)" % hop)


func test_coyote_time_allows_a_jump_just_after_leaving_a_ledge() -> void:
	await open_room()
	teleport(11.7, 0.33) # right at the edge of the start floor (gap starts at x=12)
	await frames(3)
	Input.action_press("move_right")
	check(await until(func() -> bool: return not player.get("grounded"), 120), "walked off the edge")
	await frames(3) # inside coyote_time (0.10 s = 6 frames)
	await tap("jump")
	check(player.velocity.y > 3.0 or state() == "jump", "jumped in mid-air thanks to coyote time: " + describe())


func test_a_jump_after_coyote_time_has_run_out_does_nothing() -> void:
	await open_room()
	teleport(11.7, 0.33)
	await frames(3)
	Input.action_press("move_right")
	await until(func() -> bool: return not player.get("grounded"), 120)
	Input.action_release("move_right")
	await frames(14) # well past 0.10 s, still high above the pit
	var vy_before: float = player.velocity.y
	await tap("jump")
	check(player.velocity.y <= vy_before + 0.01, "no late jump (vy %.2f -> %.2f)" % [vy_before, player.velocity.y])


func test_the_wall_stops_him() -> void:
	await open_room()
	teleport(32.0, 0.33)
	Input.action_press("move_right")
	await frames(90)
	check(player.global_position.x < 34.0, "stopped by the wall at x<34, got %.2f" % player.global_position.x)
	check(player.global_position.x > 33.0, "reached the wall, got %.2f" % player.global_position.x)
