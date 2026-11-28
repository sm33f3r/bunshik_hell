extends "res://tests/map1_base.gd"
## Task 3c-i-a-bugs, real Map 1 scene, REAL input: with a menu open (pause menu, inventory), or in the
## very press that closes it, W does nothing at the 찜기 and at the kitchen door. Closed again, W works.
## The save goes to a temp file, never the player's slot.

const TEMP_SAVE := "user://test_paused_triggers/slot.json"
const JJIGI_ID := "map01_dining_mid"
## Frames for a menu to open or close and get past its own guard.
const MENU_FRAMES: int = 20

var saves: Node
var real_path: String = ""


func after_each() -> void:
	Input.action_release("pause")
	if saves != null:
		saves.set("save_path", real_path)
		saves = null
	for file: String in ["slot.json", "slot.json.tmp", "slot.json.bak"]:
		DirAccess.remove_absolute(TEMP_SAVE.get_base_dir() + "/" + file)
	DirAccess.remove_absolute(TEMP_SAVE.get_base_dir())
	await super()


## The quiet dining room, hurt, standing beside the 찜기.
func beside_jjigi() -> Node3D:
	saves = tree.root.get_node("SaveSystem")
	real_path = saves.get("save_path")
	saves.set("save_path", TEMP_SAVE)
	DirAccess.remove_absolute(TEMP_SAVE)
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	await put_on("r_t8", 2.0)
	await frames(8)
	gs.call("take_damage", 9)
	return flow.builder.jjigi_nodes[JJIGI_ID] as Node3D


## The quiet dining room, standing in front of the kitchen door.
func beside_door() -> Node3D:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	var there: Node3D = flow.builder.door_nodes["kitchen_door"]
	teleport(there.global_position.x, there.global_position.y + 0.5)
	await until(func() -> bool: return player.get("grounded"), 90)
	await frames(8)
	check(there.get("near"), "in the door's zone: " + describe())
	return there


func open_menu(action: String) -> void:
	await tap(action)
	await frames(MENU_FRAMES)
	check(tree.paused, "the '%s' menu is open" % action)


## W while the menu is open, then close it.
func press_w_in_menu(action: String) -> void:
	await open_menu(action)
	await tap("look_up")
	await frames(MENU_FRAMES)
	await tap("ui_cancel")
	await frames(MENU_FRAMES)
	check(not tree.paused, "the '%s' menu is closed again" % action)


## One press closes the menu and is W at the same time.
func close_with_w(action: String) -> void:
	await open_menu(action)
	Input.action_press("ui_cancel")
	Input.action_press("look_up")
	await frames(3)
	Input.action_release("ui_cancel")
	Input.action_release("look_up")
	await frames(MENU_FRAMES)
	check(not tree.paused, "the '%s' menu is closed again" % action)


func check_unused(steamer: Node3D, why: String) -> void:
	check(not steamer.call("is_spent"), why + ": the 찜기 is not used")
	check_eq(gs.hearts, 5, why + ": no heal")
	check(not FileAccess.file_exists(TEMP_SAVE), why + ": no save")


func check_works(steamer: Node3D) -> void:
	await tap("look_up")
	await frames(3)
	check(steamer.call("is_spent"), "unpaused, W uses it")
	check_eq(gs.hearts, 14, "unpaused, W heals")
	check(FileAccess.file_exists(TEMP_SAVE), "unpaused, W saves")


func test_w_in_the_pause_menu_does_not_use_the_jjigi() -> void:
	var steamer: Node3D = await beside_jjigi()
	await press_w_in_menu("pause")
	check_unused(steamer, "pause menu")
	await check_works(steamer)


func test_w_in_the_inventory_does_not_use_the_jjigi() -> void:
	var steamer: Node3D = await beside_jjigi()
	await press_w_in_menu("inventory")
	check_unused(steamer, "inventory")
	await check_works(steamer)


func test_the_w_that_closes_a_menu_does_not_use_the_jjigi() -> void:
	var steamer: Node3D = await beside_jjigi()
	await close_with_w("pause")
	check_unused(steamer, "closing the pause menu")
	await close_with_w("inventory")
	check_unused(steamer, "closing the inventory")
	await check_works(steamer)


func test_w_in_a_menu_does_not_open_the_kitchen_door() -> void:
	var there: Node3D = await beside_door()
	var at: Vector3 = player.global_position
	for action: String in ["pause", "inventory"]:
		await press_w_in_menu(action)
		await close_with_w(action)
		await frames(60)
		check_eq(flow.phase, MapFlowScript.Phase.IDLE, action + ": no fade")
		check(player.global_position.distance_to(at) < 0.2, action + ": he stays: " + describe())
	await tap("look_up")
	check(await until(func() -> bool: return player.global_position.distance_to(at) > 5.0, 180),
		"unpaused, W goes through (%s, door at %.1f)" % [describe(), there.global_position.x])
