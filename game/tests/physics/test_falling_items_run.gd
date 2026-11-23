extends "res://tests/map1_base.gd"
## Task 3b-ii-fix, item 4, real Map 1 scene: the falling chopsticks and spoons of the floor lane. An item
## that really falls on him hurts for half a heart, once, and then lies there as a harmless solid prop he
## can run into, jump over and stand on; the zones' own clock drops items only where no table is above,
## keeps at most four props, and everything is gone when the section starts over. The table chopsticks
## still grab him.

const FallingItemDefScript := preload("res://hazards/falling_item_def.gd")


func lane() -> LayoutGeometryScript.Placed:
	return plat("dining_floor")


func on_floor() -> bool:
	return player.get("grounded") and absf(feet_y() - lane().top) < 0.15


func zones() -> Array[Node3D]:
	return hazards_of("falling_zone.gd")


## A calm dining room: no enemies, every other hazard and every falling zone switched off.
func quiet_dining() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])


func chopsticks_def() -> FallingItemDefScript:
	return load("res://data/hazards/falling_chopsticks.tres") as FallingItemDefScript


func test_a_real_fall_hurts_for_half_a_heart_once_and_then_the_prop_is_solid_and_harmless() -> void:
	await quiet_dining()
	var zone: Node3D = zones()[1]
	var item_def: FallingItemDefScript = chopsticks_def()
	var columns: Array[Vector2] = zone.call("free_columns", item_def)
	check(not columns.is_empty(), "the zone has a free column")
	var x: float = (columns[0].x + columns[0].y) * 0.5
	teleport(x, lane().top + 0.4)
	await until(func() -> bool: return on_floor(), 90)
	check_eq(gs.hearts, 14, "full hearts to begin with")
	var item: Node3D = zone.call("drop", item_def, x)
	check(await until(func() -> bool: return gs.hearts < 14, 200), "it fell on him: " + describe())
	check_eq(gs.hearts, 13, "half a heart")
	check(player.get("held_by") == null and not player.get("controlled"), "no grab: it is not the table chopsticks")
	check(await until(func() -> bool: return (zone.get("falling") as Array).is_empty(), 300), "it landed")
	await frames(90)
	check_eq(gs.hearts, 13, "it hurt once and only once")
	check_eq(zone.get("player_hits"), 1, "counted once")
	var props: Array[Node3D] = zone.call("live_props")
	check_eq(props.size(), 1, "one prop lies there")
	var prop: StaticBody3D = props[0] as StaticBody3D
	var shape: CollisionShape3D = prop.get_node("CollisionShape3D") as CollisionShape3D
	check(await until(func() -> bool: return not shape.disabled, 240), "it is solid once nobody stands in it")
	var size: Vector3 = (shape.shape as BoxShape3D).size
	var top: float = prop.global_position.y + size.y * 0.5
	check(absf(top - (lane().top + size.y)) < 0.1, "low: %.2f m high, on the floor" % size.y)
	var left: float = prop.global_position.x - size.x * 0.5
	var right: float = prop.global_position.x + size.x * 0.5
	# Running into it: it is a wall.
	teleport(left - 2.0, lane().top + 0.4)
	await until(func() -> bool: return on_floor(), 90)
	Input.action_press("move_right")
	await frames(90)
	Input.action_release("move_right")
	check(player.global_position.x < left + 0.05, "it stops him (x %.2f, the prop starts at %.2f)" % [player.global_position.x, left])
	check_eq(gs.hearts, 13, "and it does not hurt him")
	# ... jumping onto it: he stands on it.
	Input.action_press("move_right")
	Input.action_press("jump")
	var stood: bool = false
	for i: int in 120:
		await tree.physics_frame
		if i == 14:
			Input.action_release("jump")
		if player.get("grounded") and absf(feet_y() - top) < 0.1 and player.global_position.x > left and player.global_position.x < right:
			stood = true
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	check(stood, "he can stand on it: " + describe())
	check_eq(gs.hearts, 13, "still no damage")
	check(not is_instance_valid(item) or item.is_queued_for_deletion(), "the falling item itself is gone")


func test_an_item_falls_on_an_enemy_with_the_foots_crush_rule() -> void:
	await quiet_dining()
	var zone: Node3D = zones()[1]
	var columns: Array[Vector2] = zone.call("free_columns", chopsticks_def())
	var x: float = (columns[0].x + columns[0].y) * 0.5
	teleport(x - 12.0, lane().top + 0.4) # near, out of the way
	await until(func() -> bool: return on_floor(), 90)
	var mandu: Node3D = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as Node3D
	mandu.set("width_m", 5.0 * 0.1745)
	mandu.set("speed_scale", 0.0)
	room.add_child(mandu)
	mandu.global_position = Vector3(x, lane().top + 0.02, 0.0)
	await frames(5)
	check(mandu.get("alive"), "the 만두 stands there")
	zone.call("drop", chopsticks_def(), x)
	check(await until(func() -> bool: return not mandu.get("alive"), 200), "the falling item crushed it, as the foot does")
	check_eq(gs.hearts, 14, "he is far away and unhurt")


func test_the_clock_drops_items_only_where_no_table_is_above_and_keeps_four_props() -> void:
	await quiet_dining()
	var zone: Node3D = zones()[zones().size() - 1]
	zone.call("set_enabled", true)
	var cover: Array[Vector2] = zone.get("cover")
	var item_count: int = 0
	var landed_xs: Array[float] = []
	zone.connect("landed", func(prop: Node3D) -> void: landed_xs.append(prop.global_position.x))
	# He watches from a table above the zone, where nothing can hit him.
	var table: LayoutGeometryScript.Placed = plat("r_t12")
	await put_on("r_t12", table.length() * 0.5)
	var most_props: int = 0
	var hearts_ok: bool = true
	for i: int in 3600:
		await tree.physics_frame
		most_props = maxi(most_props, (zone.call("live_props") as Array).size())
		if gs.hearts < 14:
			hearts_ok = false
	check(zone.get("dropped") >= 8, "it dropped plenty in a minute (%d)" % zone.get("dropped"))
	check(hearts_ok, "he was above the fall and never hit")
	check(most_props <= 4 and most_props == 4, "at most four props stood at once (%d)" % most_props)
	check(landed_xs.size() >= 8, "the landings were seen (%d)" % landed_xs.size())
	for x: float in landed_xs:
		for blocked: Vector2 in cover:
			check(x < blocked.x or x > blocked.y, "a prop landed at %.2f under a table (%.2f..%.2f)" % [x, blocked.x, blocked.y])
	var tables_x: Array[Vector2] = []
	for p: LayoutGeometryScript.Placed in flow.placed:
		if p.def.kind == "table":
			tables_x.append(Vector2(p.left, p.right))
	for x: float in landed_xs:
		for t: Vector2 in tables_x:
			check(x < t.x or x > t.y, "and none is under the table at %.1f..%.1f" % [t.x, t.y])
	check_eq(tree.get_nodes_in_group("falling_props").size() >= 1, true, "props are in the world")
	# The section starts over: everything is gone.
	flow.call("reset_sections")
	await frames(10)
	check_eq(tree.get_nodes_in_group("falling_props").size(), 0, "no props are left after the section resets")
	check_eq((zones()[zones().size() - 1].call("live_props") as Array).size(), 0, "and the new zone starts empty")


func test_the_table_chopsticks_still_grab_him_and_no_item_falls_on_a_table() -> void:
	await quiet_dining()
	var table_zones: Array[Node3D] = []
	for z: Node3D in hazards_of("chopsticks.gd"):
		if z.global_position.y > 5.0:
			table_zones.append(z)
	check(not table_zones.is_empty(), "the table chopsticks are still on the tables")
	for z: Node3D in zones():
		check(z.global_position.y < lane().top + 0.5, "a falling zone stands on the floor, not on a table")
	var zone: Node3D = table_zones[0]
	for z: Node3D in table_zones:
		z.call("set_enabled", z == zone)
	var table: LayoutGeometryScript.Placed = plat("r_t8")
	await put_on("r_t8", table.length() * 0.5)
	zone.global_position.x = player.global_position.x
	zone.global_position.y = table.top
	var grabbed: bool = await until(func() -> bool: return player.get("held_by") != null, 900)
	check(grabbed, "they grabbed him: " + describe())
	check_eq(gs.hearts, 13, "half a heart, as before")
	for i: int in 4:
		Input.action_press("move_right" if i % 2 == 0 else "move_left")
		await frames(3)
		Input.action_release("move_right")
		Input.action_release("move_left")
		await frames(2)
	check(await until(func() -> bool: return player.get("held_by") == null, 60), "and he wiggles free: " + describe())
