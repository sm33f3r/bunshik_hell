extends "res://tests/physics_base.gd"
## Real test room: 찜기 use, checkpoints, death and respawn. The respawn rule: he comes back at
## the 찜기 he used MOST RECENTLY (pressed look_up at), never the nearest or the first.


## Walk up to a steamer and press look_up at it.
func _use(steamer_name: String) -> void:
	var s: Node3D = room.get_node("Steamers/" + steamer_name)
	teleport(s.global_position.x + 0.4, 0.33)
	await frames(30)
	await tap("look_up")
	await frames(3)


## Kills him and returns the seconds until he is alive again.
func _die_and_wait() -> float:
	gs.call("take_damage", 14)
	await frames(2)
	var t0: int = Engine.get_physics_frames()
	await until(func() -> bool: return state() != "dead", 240)
	return float(Engine.get_physics_frames() - t0) / 60.0


func test_using_a_steamer_heals_fully_and_sets_the_checkpoint() -> void:
	await open_room()
	gs.call("take_damage", 6)
	await _use("SteamerFar")
	check_eq(gs.hearts, 14, "full heal")
	check_eq(gs.checkpoint_id, "steamer_far", "far steamer is now the checkpoint")


func test_a_steamer_does_nothing_without_pressing_look_up() -> void:
	await open_room()
	gs.call("take_damage", 6)
	var s: Node3D = room.get_node("Steamers/SteamerFar")
	teleport(s.global_position.x + 0.4, 0.33)
	await frames(40)
	check_eq(gs.hearts, 8, "standing next to it heals nothing")
	check_eq(gs.checkpoint_id, "steamer_start", "checkpoint unchanged")


func test_a_dead_player_cannot_use_a_steamer() -> void:
	await open_room()
	gs.call("take_damage", 14)
	var s: Node3D = room.get_node("Steamers/SteamerStart")
	check_eq(s.call("activate", gs), false, "refused while dead")


func test_respawn_goes_to_the_far_steamer_after_start_then_far() -> void:
	await open_room()
	await _use("SteamerStart")
	await _use("SteamerFar")
	check_eq(gs.checkpoint_id, "steamer_far", "far used last")
	var secs: float = await _die_and_wait()
	check(secs < 2.0, "respawn in under 2 s (%.2f)" % secs)
	check(player.global_position.x > 30.0, "respawned at the FAR steamer: " + describe())
	check_eq(gs.hearts, 14, "full hearts")


func test_respawn_goes_to_the_start_steamer_after_far_then_start() -> void:
	await open_room()
	await _use("SteamerFar")
	await _use("SteamerStart")
	check_eq(gs.checkpoint_id, "steamer_start", "start used last")
	await _die_and_wait()
	check(player.global_position.x < -5.0, "respawned at the START steamer: " + describe())
	check_eq(gs.hearts, 14, "full hearts")


func test_respawn_ignores_where_he_died() -> void:
	await open_room()
	await _use("SteamerStart")
	teleport(32.0, 0.33) # dies right next to the far steamer, which he never used
	await frames(5)
	await _die_and_wait()
	check(player.global_position.x < -5.0, "back at the start steamer, not the nearest one: " + describe())


func test_death_without_using_any_steamer_respawns_at_the_start() -> void:
	await open_room()
	teleport(5.0, 0.33)
	await frames(10)
	await _die_and_wait()
	check(player.global_position.x < -5.0, "start steamer is the default checkpoint: " + describe())


func test_death_keeps_sauce_and_respawn_takes_under_two_seconds() -> void:
	await open_room()
	gs.call("add_sauce", 2)
	gs.call("take_damage", 14)
	await frames(2)
	check_eq(state(), "dead", "dead state")
	var t0: int = Engine.get_physics_frames()
	await until(func() -> bool: return state() != "dead", 240)
	var secs: float = float(Engine.get_physics_frames() - t0) / 60.0
	check(secs > 0.5 and secs < 2.0, "respawn took %.2f s" % secs)
	check_eq(gs.sauce, 5, "sauce kept")


func test_falling_into_the_pit_is_a_death_and_he_comes_back_at_the_checkpoint() -> void:
	await open_room()
	teleport(13.5, 0.5) # above the 3 m pit (x 12..15)
	await until(func() -> bool: return state() == "dead", 240)
	check_eq(state(), "dead", "the fall killed him")
	await until(func() -> bool: return state() != "dead", 240)
	check(gs.hearts == 14 and player.global_position.y > -1.0 and player.global_position.x < -5.0,
		"respawned at the checkpoint: " + describe())
