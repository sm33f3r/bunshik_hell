extends "res://tests/physics_base.gd"
## F2: 참기름 sources are real, solid objects. The `standable` flag decides whether the 떡 can
## land and stand on them. Test room: a bottle on the floor, a shelf with a bottle on it, and
## an oil brush hanging from a hook that has no collision at all.

const Layers := preload("res://systems/layers.gd")


func _source(node_name: String) -> StaticBody3D:
	return room.get_node("OilObjects/" + node_name) as StaticBody3D


func _shapes(node: Node) -> Array[Node]:
	return node.get_children().filter(func(c: Node) -> bool: return c is CollisionShape3D)


func _settle_at(x: float, y: float) -> void:
	park(soft_floor, -30.0)
	park(tall, -31.0)
	teleport(x, y)
	await frames(60)


func test_the_flag_decides_the_collision() -> void:
	await open_room()
	for node_name: String in ["BottleFloor", "BottleShelf"]:
		var s: StaticBody3D = _source(node_name)
		check_eq(s.get("standable"), true, node_name + " is standable")
		check_eq(s.collision_layer, Layers.WORLD, node_name + " is on the world layer")
		check_eq(_shapes(s).size(), 1, node_name + " has a collision shape")
	var brush: StaticBody3D = _source("OilBrush")
	check_eq(brush.get("standable"), false, "the brush is not standable")
	check_eq(brush.collision_layer, 0, "the brush is on no layer")
	check_eq(_shapes(brush).size(), 0, "and has no collision shape at all")
	var shelf: StaticBody3D = room.get_node("OilObjects/Shelf") as StaticBody3D
	check_eq(shelf.collision_layer, Layers.WORLD, "the shelf is solid too")


func test_the_ddeok_can_land_and_stand_on_the_bottle_on_the_floor() -> void:
	await open_room()
	await _settle_at(16.5, 2.5)
	check(player.is_on_floor(), "standing: " + describe())
	check(player.global_position.y > 0.7 + 0.2 and player.global_position.y < 0.7 + 0.4,
		"on top of the 0.7 m bottle, not on the floor: " + describe())
	check(absf(player.global_position.x - 16.5) < 0.1, "and he stays on it: " + describe())


func test_the_ddeok_can_land_and_stand_on_the_shelf_and_on_the_bottle_on_it() -> void:
	await open_room()
	await _settle_at(11.2, 4.5)
	check(player.is_on_floor(), "on the shelf: " + describe())
	check(absf(player.global_position.y - (3.1 + 0.32)) < 0.08, "the shelf top is at 3.1: " + describe())
	await _settle_at(10.3, 6.0)
	check(player.is_on_floor(), "on the bottle: " + describe())
	check(player.global_position.y > 3.8 + 0.2 and player.global_position.y < 3.8 + 0.4,
		"on top of the bottle that stands on the shelf: " + describe())


func test_the_ddeok_falls_through_the_space_of_the_oil_brush() -> void:
	await open_room()
	park(soft_floor, -30.0)
	park(tall, -31.0)
	teleport(-6.2, 3.8)
	var lowest_during_fall: float = 99.0
	var passed_brush: bool = false
	for i: int in 90:
		await tree.physics_frame
		lowest_during_fall = minf(lowest_during_fall, player.global_position.y)
		if player.global_position.y < 2.0 and player.global_position.y > 1.6:
			passed_brush = true
	check(passed_brush, "he went right through the brush's height (y 1.7 to 2.4)")
	check(lowest_during_fall < 0.5 and player.global_position.y < 0.5, "and ended on the floor: " + describe())
	check(player.is_on_floor(), "standing on the floor, not on the brush: " + describe())


func test_a_bottle_drop_falls_beside_the_bottle_to_the_floor() -> void:
	await open_room()
	var source: Node = _source("BottleFloor")
	var drop: Node3D = source.call("drip") as Node3D
	check(drop != null, "a drop spawned")
	check(absf(drop.global_position.x - 17.0) < 0.05, "beside the bottle (x offset 0.5): %.2f" % drop.global_position.x)
	var landed: bool = await until(func() -> bool: return is_instance_valid(drop) and drop.get("landed"), 120)
	check(landed, "it landed")
	check(absf(drop.global_position.y) < 0.2, "on the floor, not on the bottle: y=%.2f" % drop.global_position.y)
