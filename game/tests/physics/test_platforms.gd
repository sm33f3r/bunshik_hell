extends "res://tests/physics_base.gd"
## Real test room: the one-way platform and the soft dummy's patrol.


func test_one_way_platform_up_through_land_on_top_then_drop_through() -> void:
	await open_room()
	teleport(1.0, 0.33) # under the platform (x -1..3, top at y 1.6)
	await frames(30)
	Input.action_press("jump")
	await frames(45)
	Input.action_release("jump")
	check(await until(func() -> bool: return player.get("grounded"), 120), "landed")
	check(absf(player.global_position.y - (1.6 + 0.32)) < 0.08, "standing on top: " + describe())
	await tap("look_down")
	await frames(30)
	check(player.global_position.y < 0.6, "dropped through to the floor: " + describe())


func test_a_short_hop_under_the_platform_does_not_land_on_it() -> void:
	await open_room()
	teleport(1.0, 0.33)
	await frames(30)
	var jump_height: float = await jump_peak(3)
	check(jump_height < 1.2, "hop is lower than the platform (%.2f)" % jump_height)
	check(player.global_position.y < 0.6, "back on the floor, not on the platform: " + describe())


func test_soft_dummy_patrols_both_ways_and_stays_on_its_ledge() -> void:
	await open_room()
	var min_x: float = 999.0
	var max_x: float = -999.0
	var min_y: float = 999.0
	var max_z: float = 0.0
	for i: int in 720:
		await tree.physics_frame
		min_x = minf(min_x, soft_ledge.global_position.x)
		max_x = maxf(max_x, soft_ledge.global_position.x)
		min_y = minf(min_y, soft_ledge.global_position.y)
		max_z = maxf(max_z, absf(soft_ledge.global_position.z))
	check(max_x - min_x > 5.0, "patrols a range (%.2f..%.2f)" % [min_x, max_x])
	check(min_x > 20.0 and max_x < 30.0, "stays within the ledge x 20..30")
	check(min_y > 1.4, "never falls off (min y %.2f)" % min_y)
	check(max_z < 0.0001, "z locked")
