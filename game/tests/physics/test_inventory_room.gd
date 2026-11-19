extends "res://tests/physics_base.gd"
## Real test room: walking into carried items, the popup and the pause, the heal button,
## the coat, dropping, the debug keys, and 참기름 falling from its source.

const POPUP_GUARD_FRAMES: int = 6


func _ui() -> Node:
	return room.get_node("InventoryUi")


## Dummies out of the way; standing at x on the floor.
func _stand(x: float) -> void:
	park(soft_floor, -30.0)
	park(tall, -30.0)
	await frames(3) # let the physics server see them gone before he arrives
	teleport(x, 0.33)
	await frames(10)


func _walk_right_until(cond: Callable, max_frames: int) -> bool:
	Input.action_press("move_right")
	var ok: bool = await until(cond, max_frames)
	Input.action_release("move_right")
	return ok


func test_walking_over_items_without_a_container_picks_nothing_up() -> void:
	await open_room()
	room.get_node("Pickups/ContainerPickup").queue_free() # he would walk into it at x = 0
	await _stand(0.5)
	await _walk_right_until(func() -> bool: return player.global_position.x > 5.0, 120)
	check_eq(gs.items.size(), 0, "nothing carried")
	check_eq(room.get_tree().get_nodes_in_group("item_pickups").size(), 6, "all 6 items still lie there")
	check_eq(gs.popup_open(), false, "no popup")


func test_walking_into_the_container_then_items_and_the_fourth_opens_the_popup() -> void:
	await open_room()
	await _stand(-0.8)
	await _walk_right_until(func() -> bool: return gs.has_container(), 120)
	check_eq(gs.container_id, "starter_container", "the container was picked up by walking into it")
	var ok: bool = await _walk_right_until(func() -> bool: return gs.popup_open(), 200)
	check(ok, "the 4th item opened the popup: " + describe())
	check_eq(gs.items.size(), 3, "three carried: kongomul, kongomul, jocheong")
	check_eq(gs.items, ["kongomul", "kongomul", "jocheong"] as Array[String], "in pickup order")
	check_eq(gs.popup_item_id, "jocheong", "asked about the 4th")
	check_eq(gs.hearts, 14, "nothing healed on touch")
	await frames(2)
	check(room.get_tree().paused, "the game is paused while the popup is open")
	var x_before: float = player.global_position.x
	await frames(10)
	check_eq(player.global_position.x, x_before, "he does not move while paused")


func test_the_popup_drop_choice_closes_it_and_unpauses_without_reopening() -> void:
	await open_room()
	gs.call("try_equip_container", "starter_container")
	for id: String in ["ggul", "ggul", "ggul"]:
		gs.call("try_pickup_item", id)
	await _stand(-8.0)
	# On top of the items at x = 2.1, 2.8 and 3.5 at once: one popup, not a chain of three.
	teleport(2.8, 0.33)
	await until(func() -> bool: return gs.popup_open(), 30)
	check(gs.popup_open(), "popup opened")
	await frames(POPUP_GUARD_FRAMES)
	await tap("drop_item")
	await frames(4)
	check_eq(gs.popup_open(), false, "closed")
	check(not room.get_tree().paused, "unpaused")
	await frames(30)
	check_eq(gs.popup_open(), false, "standing on it does not re-open the popup")
	check_eq(gs.items.size(), 3, "still three items")


func test_the_inventory_key_opens_pauses_and_closes() -> void:
	await open_room()
	await _stand(-8.0)
	await tap("inventory")
	await frames(5)
	check(_ui().get("screen_open"), "screen open")
	check(room.get_tree().paused, "paused")
	check("no container" in (_ui().call("screen_text") as String), "with no container the screen says so")
	await tap("inventory")
	await frames(5)
	check(not _ui().get("screen_open"), "closed")
	check(not room.get_tree().paused, "unpaused")


func test_the_inventory_screen_uses_and_drops_with_the_keyboard() -> void:
	await open_room()
	await _stand(-8.0)
	gs.call("try_equip_container", "starter_container")
	for id: String in ["ggul", "jocheong", "kongomul"]:
		gs.call("try_pickup_item", id)
	gs.call("take_damage", 6)
	await tap("inventory")
	await frames(6)
	check_eq(_ui().get("selected"), 0, "first slot selected")
	await tap("look_down")
	await frames(3)
	check_eq(_ui().get("selected"), 1, "S moves down")
	await tap("ui_down")
	await frames(3)
	check_eq(_ui().get("selected"), 2, "the arrow keys move too")
	await tap("look_up")
	await frames(3)
	check_eq(_ui().get("selected"), 1, "W moves up")
	await tap("ui_accept")
	await frames(3)
	check_eq(gs.hearts, 10, "confirm used the 조청: +1 heart")
	check_eq(gs.items, ["ggul", "kongomul"] as Array[String], "slot emptied, order kept")
	check(room.get_tree().paused, "still paused")
	# Drop slot 1 (kongomul).
	await tap("drop_item")
	await frames(3)
	check_eq(gs.items, ["ggul"] as Array[String], "dropped")
	await tap("inventory")
	await frames(4)
	var dropped: Array[Node] = room.get_tree().get_nodes_in_group("item_pickups").filter(
		func(n: Node) -> bool: return n.get("dropped") == true)
	check_eq(dropped.size(), 1, "the item is on the ground")
	if dropped.size() == 1:
		var d: Node3D = dropped[0] as Node3D
		check(absf(d.global_position.x - player.global_position.x) < 0.1, "at his feet")
		check_eq(d.get("item_id"), "kongomul", "it is the kongomul")


func test_a_dropped_item_waits_a_second_then_is_picked_up_again_if_he_stays() -> void:
	await open_room()
	await _stand(-8.0)
	gs.call("try_equip_container", "starter_container")
	gs.call("try_pickup_item", "ggul")
	await tap("inventory")
	await frames(6)
	await tap("drop_item")
	await frames(2)
	await tap("inventory")
	await frames(6)
	check_eq(gs.items.size(), 0, "dropped")
	await frames(30)
	check_eq(gs.items.size(), 0, "0.5 s later it is still on the ground")
	await frames(45)
	check_eq(gs.items.size(), 1, "after about 1 s it was picked up again")


func test_the_heal_button_uses_the_lowest_item_in_the_room() -> void:
	await open_room()
	await _stand(-8.0)
	gs.call("try_equip_container", "starter_container")
	gs.call("try_pickup_item", "kongomul")
	gs.call("try_pickup_item", "ggul")
	await tap("heal")
	await frames(2)
	check_eq(gs.items.size(), 2, "full hearts: R does nothing and uses nothing up")
	gs.call("take_damage", 6)
	await tap("heal")
	await frames(2)
	check_eq(gs.items, ["kongomul"] as Array[String], "the 꿀 (no coat) went first")
	check_eq(gs.hearts, 10, "+1 heart")


func test_a_coated_hit_does_no_damage_but_still_knocks_back() -> void:
	await open_room()
	await _stand(-8.0)
	gs.set("coat", true)
	var ok: bool = player.call("hurt", 2, -9.0)
	check(ok, "the hit registered")
	check_eq(gs.hearts, 14, "no damage")
	check_eq(gs.coat, false, "coat used up")
	check(player.velocity.x > 0.0 and player.velocity.y > 0.0, "knocked back away from the source: " + describe())
	check(player.call("is_invulnerable"), "invulnerable")
	await frames(3)
	check_eq(state(), "hurt", "hurt state")
	check(not player.call("hurt", 2, -9.0), "the i-frames still protect him")
	check_eq(gs.hearts, 14, "still full")


func test_debug_keys_7_gives_the_container_2_clears_3_respawns() -> void:
	await open_room()
	check_eq(gs.has_container(), false, "none at the start")
	await key_event(KEY_7)
	check_eq(gs.container_id, "starter_container", "7 gives the starter container")
	gs.call("try_pickup_item", "ggul")
	gs.set("coat", true)
	await key_event(KEY_2)
	check(not gs.has_container() and gs.items.is_empty(), "2 clears the container and items")
	# 3 brings back taken pickups and used smudges.
	var pickup: Node3D = room.get_node("Pickups/ContainerPickup") as Node3D
	pickup.call("try_collect") # no container held: would equip, but needs a game state
	await key_event(KEY_7)
	var smudge: Node3D = room.get_node("OilSmudges/SmudgeFloor") as Node3D
	gs.call("take_damage", 4)
	check(smudge.call("try_use"), "smudge heals")
	check(smudge.get("used"), "smudge used")
	await key_event(KEY_3)
	await frames(2)
	check(not smudge.get("used") and smudge.visible, "3 respawns the smudge")
	check(pickup.visible and not pickup.get("consumed"), "3 respawns the pickups")


func test_the_hud_shows_coat_container_and_contents() -> void:
	await open_room()
	await frames(3)
	var text: String = (room.get_node("DebugHud/Text") as Label).text
	check("Container: none" in text and "Coat: off" in text, "no container, no coat: " + text)
	check("7 give container" in text, "key 7 listed")
	gs.call("try_equip_container", "starter_container")
	gs.call("try_pickup_item", "kongomul")
	gs.set("coat", true)
	await frames(3)
	text = (room.get_node("DebugHud/Text") as Label).text
	check("Container: Starter container 1/3 [콩고물]" in text, "container line: " + text)
	check("Coat: ON" in text, "coat shown")


# --- 참기름 ---------------------------------------------------------------------------

func test_the_test_room_oil_sources_drip_every_3_to_6_seconds() -> void:
	await open_room()
	var sources: Array[Node] = []
	for shelf: Node in room.get_node("OilObjects").get_children():
		sources.append(shelf.get_node("OilSource"))
	check_eq(sources.size(), 2, "two sources")
	for s: Node in sources:
		check(s.get("drip_min_s") == 3.0 and s.get("drip_max_s") == 6.0, "test interval 3-6 s")
	var defaults: Node = (load("res://items/sesame_oil_source.gd") as GDScript).new()
	check(defaults.get("drip_min_s") == 10.0 and defaults.get("drip_max_s") == 30.0, "script defaults stay 10-30")
	defaults.free()


func test_an_oil_drop_falls_from_its_source_and_heals_the_ddeok_standing_under_it() -> void:
	await open_room()
	await _stand(-6.2)
	gs.call("take_damage", 4)
	var source: Node = room.get_node("OilObjects/ShelfA/OilSource")
	var drop: Node3D = source.call("drip") as Node3D
	check(drop != null, "a drop spawned")
	check(drop.global_position.y > 2.0, "it starts up at the shelf")
	var healed: bool = await until(func() -> bool: return gs.hearts == 11, 120)
	check(healed, "the drop fell onto him and healed ½ heart: hearts=%d %s" % [gs.hearts, describe()])
	check(not is_instance_valid(drop) or drop.get("gone"), "and was used up")


func test_an_oil_drop_that_lands_becomes_a_puddle_that_soaks_away() -> void:
	await open_room()
	await _stand(-8.0) # not under the shelf
	var source: Node = room.get_node("OilObjects/ShelfA/OilSource")
	source.set("puddle_lifetime_s", 1.0)
	var drop: Node3D = source.call("drip") as Node3D
	var landed: bool = await until(func() -> bool: return is_instance_valid(drop) and drop.get("landed"), 120)
	var surface_y: float = drop.global_position.y
	check(landed, "it landed on the floor")
	check(absf(surface_y) < 0.2, "on the floor surface: y=%.2f" % surface_y)
	await frames(30)
	check(is_instance_valid(drop) and not drop.get("gone"), "still a puddle after 0.5 s")
	await frames(45)
	check(not is_instance_valid(drop) or drop.get("gone"), "soaked away after its 1 s lifetime")
	check_eq(gs.hearts, 14, "nobody was hurt")


func test_walking_over_a_smudge_heals_once() -> void:
	await open_room()
	await _stand(-12.0)
	gs.call("take_damage", 4)
	await _walk_right_until(func() -> bool: return gs.hearts > 10, 5)
	teleport(-13.3, 0.33)
	await _walk_right_until(func() -> bool: return gs.hearts > 10, 120)
	check_eq(gs.hearts, 11, "½ heart from the smudge at x=-12.8")
	teleport(-13.3, 0.33)
	await _walk_right_until(func() -> bool: return player.global_position.x > -12.0, 60)
	check_eq(gs.hearts, 11, "it was used up: no second heal")
