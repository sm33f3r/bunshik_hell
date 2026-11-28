extends "res://tests/physics_base.gd"
## Task 3c-i-a-bugs, real test room (Map 1 has no usable object yet), REAL input: with the inventory
## open, or the game paused, neither `special` (the use button) nor W sets off a usable object.


func bottle() -> Node3D:
	return room.get_node("Specials/WaterBottle1") as Node3D


func beside_bottle() -> void:
	await open_room()
	gs.call("add_sodium", 3)
	teleport(bottle().global_position.x - 1.0, 0.33)
	await frames(30)
	check(bottle().call("in_range_of", player.global_position), "in range: " + describe())


func press_both() -> void:
	await tap("special")
	await frames(3)
	await tap("look_up")
	await frames(20)


func check_untouched(why: String) -> void:
	check(not bottle().get("used"), why + ": not used")
	check_eq(gs.sodium, 3, why + ": nothing spent")


func check_works() -> void:
	await tap("look_up")
	await frames(3)
	check(not bottle().get("used"), "W is not its use button")
	await tap("special")
	await frames(3)
	check(bottle().get("used"), "unpaused, special uses it")


func test_nothing_goes_off_while_the_inventory_is_open() -> void:
	await beside_bottle()
	await tap("inventory")
	await frames(20)
	check(tree.paused, "the inventory is open")
	await press_both()
	check_untouched("inventory")
	await tap("ui_cancel")
	await frames(20)
	check(not tree.paused, "closed again")
	check_untouched("after closing")
	await check_works()


func test_nothing_goes_off_while_the_game_is_paused() -> void:
	await beside_bottle()
	tree.paused = true
	await press_both()
	check_untouched("paused")
	tree.paused = false
	await frames(20)
	check_untouched("unpaused")
	await check_works()
