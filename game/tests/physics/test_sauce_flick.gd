extends "res://tests/physics_base.gd"
## Real test room: the sauce flick, pools, drips, and what the flick does to the new dummies.
## Layout (x): start 찜기 -11 · pool -16.5 · drips -19.5 / -21 / -22.5 · 튀김 small -27, medium -31,
## large -35 · 라면 -39 · tube -45. The old dummies sit near x -4 / -2.3 and are parked away here.


func _quiet_old_dummies() -> void:
	park(soft_floor, 16.0)
	park(tall, 17.0)
	park(soft_ledge, 18.0)


## Fires the flick (real input) and follows it until it disappears. Returns
## {"start": Vector3, "end": Vector3, "min_y": float, "max_y": float, "frames": int}.
func _fire_and_follow() -> Dictionary:
	await tap("sauce_attack")
	var seen: Array[Node3D] = flicks()
	if seen.is_empty():
		return {}
	var flick: Node3D = seen[0]
	var info: Dictionary = {"start": flick.global_position, "end": flick.global_position,
		"min_y": flick.global_position.y, "max_y": flick.global_position.y, "min_z": flick.global_position.z,
		"max_z": flick.global_position.z, "frames": 0}
	while is_instance_valid(flick) and not flick.is_queued_for_deletion() and info["frames"] < 120:
		info["end"] = flick.global_position
		info["min_y"] = minf(info["min_y"], flick.global_position.y)
		info["max_y"] = maxf(info["max_y"], flick.global_position.y)
		info["min_z"] = minf(info["min_z"], flick.global_position.z)
		info["max_z"] = maxf(info["max_z"], flick.global_position.z)
		info["frames"] += 1
		await tree.physics_frame
	return info


func test_locked_flick_does_nothing_and_shows_nothing() -> void:
	await open_room()
	_quiet_old_dummies()
	check(not gs.call("has_skill", "sauce_flick"), "locked at the start")
	await tap("sauce_attack")
	await frames(5)
	check_eq(gs.sauce, 3, "no sauce spent")
	check_eq(flicks().size(), 0, "no projectile")
	gs.sauce = 0
	await tap("sauce_attack")
	await frames(3)
	var text: String = (room.get_node("DebugHud/Text") as Label).text
	check("NOT ENOUGH" not in text, "no cue while locked, even with 0 sauce")


func test_flick_flies_right_and_stops_at_about_8_metres() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	teleport(-9.4, 0.33)
	await frames(10)
	var info: Dictionary = await _fire_and_follow()
	check(not info.is_empty(), "a flick appeared")
	if info.is_empty():
		return
	var dist: float = (info["end"] as Vector3).x - (info["start"] as Vector3).x
	check(dist > 7.4 and dist < 8.6, "travelled about 8 m to the right, got %.2f" % dist)
	check(info["max_y"] - info["min_y"] < 0.001, "horizontal: y never changed")
	check(info["max_z"] - info["min_z"] < 0.001, "locked to the plane: z never changed")
	check_eq(gs.sauce, 2, "one sauce spent")
	await frames(3)
	check_eq(flicks().size(), 0, "gone after its range")


func test_flick_flies_left_and_stops_at_about_8_metres() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	teleport(2.0, 0.33) # clear floor to the left (the start 찜기 at -11 is solid)
	player.set("facing", -1.0)
	await frames(10)
	var info: Dictionary = await _fire_and_follow()
	check(not info.is_empty(), "a flick appeared")
	if info.is_empty():
		return
	var dist: float = (info["start"] as Vector3).x - (info["end"] as Vector3).x
	check(dist > 7.4 and dist < 8.6, "travelled about 8 m to the left, got %.2f" % dist)
	check((info["start"] as Vector3).x < player.global_position.x, "started on the left side of him")


func test_flick_stops_on_world_geometry() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	teleport(1.0, 0.33) # Step1's face is at x = 5.0, 4 m ahead
	await frames(10)
	var info: Dictionary = await _fire_and_follow()
	check(not info.is_empty(), "a flick appeared")
	if info.is_empty():
		return
	var end_x: float = (info["end"] as Vector3).x
	check(end_x < 5.1, "stopped at the step, not at 8 m (last seen at x=%.2f)" % end_x)
	check(end_x > 3.5, "but only after flying to it (x=%.2f)" % end_x)


func test_flick_hits_a_fried_dummy_and_advances_its_stage() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	var small: Node3D = dummy("FriedSmall")
	check_eq(small.call("stage_name"), "fresh", "starts fresh")
	teleport(-24.0, 0.33)
	player.set("facing", -1.0)
	await frames(10)
	await _fire_and_follow()
	check_eq(small.call("stage_name"), "broken", "one flick = one stage")
	check_eq(gs.sauce, 2, "one sauce spent")
	await frames(20) # cooldown
	await tap("sauce_attack")
	await frames(30)
	check_eq(small.get("stage"), 2, "second flick: crumbling")
	check(small.get("alive"), "still alive while crumbling")
	await frames(20)
	await tap("sauce_attack")
	await frames(30)
	check(not small.get("alive"), "third flick: soggy = dead")
	check_eq(gs.sauce, 0, "three sauce spent")


func test_flick_on_the_noodle_dummy_does_no_damage_and_flashes() -> void:
	await open_room()
	_quiet_old_dummies()
	dummy("TubeDummy").set_physics_process(false) # keep its pellets out of this test
	gs.call("unlock_skill", "sauce_flick")
	var noodle: Node3D = dummy("NoodleDummy")
	teleport(-37.0, 0.33)
	player.set("facing", -1.0)
	await frames(10)
	var hp_before: int = noodle.get("hp")
	await tap("sauce_attack")
	await frames(6)
	check_eq(noodle.get("hp"), hp_before, "no damage")
	check(noodle.get("alive"), "still alive")
	check_eq(gs.sauce, 2, "the flick was spent")
	check_eq(flicks().size(), 0, "and consumed by the noodle")
	var overlay: StandardMaterial3D = noodle.get("_overlay") as StandardMaterial3D
	check(overlay != null and overlay.albedo_color.a > 0.2, "a slurp flash is showing")
	await frames(30)
	check(overlay.albedo_color.a < 0.05, "and it fades")
	check(gs.defeated_enemies.is_empty(), "nothing counted as a defeat")


func test_flick_jams_the_tube_dummy_and_it_stops_shooting() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	var tube_dummy: Node3D = dummy("TubeDummy")
	teleport(-42.0, 0.33)
	player.set("facing", -1.0)
	await frames(5)
	await tap("sauce_attack")
	await frames(10)
	check(tube_dummy.get("jammed"), "the flick jammed it")
	check(tube_dummy.get("alive"), "jam does not kill")
	await frames(400) # well over two shot intervals
	check_eq(gs.hearts, 14, "a jammed tube never hurt him")


func test_the_tube_dummy_pellet_costs_half_a_heart() -> void:
	await open_room()
	_quiet_old_dummies()
	teleport(-42.0, 0.33) # 3 m from the tube dummy, inside its range
	await frames(5)
	check(await until(func() -> bool: return gs.hearts < 14, 300), "a pellet reached him")
	check_eq(gs.hearts, 13, "one half-heart = half a heart")


func test_standing_in_the_pool_refills_sauce_up_to_the_cap() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.sauce = 0
	teleport(-16.5, 0.33)
	await frames(130) # about 2.2 s at 0.5 s per sauce
	check(gs.sauce >= 3 and gs.sauce <= 5, "about 4 sauce after 2.2 s, got %d" % gs.sauce)
	var mid: int = gs.sauce
	await frames(60)
	check(gs.sauce > mid, "still rising while he stands there")
	await frames(300)
	check_eq(gs.sauce, 7, "stops at the cap")


func test_the_pool_does_nothing_when_he_is_not_in_it() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.sauce = 1
	teleport(-12.0, 0.33)
	await frames(90)
	check_eq(gs.sauce, 1, "no refill outside the pool")


func test_a_drip_adds_one_sauce_and_disappears() -> void:
	await open_room()
	_quiet_old_dummies()
	var drip: Node3D = room.get_node("Sauce/Drip1") as Node3D
	teleport(-19.5, 0.33)
	await frames(10)
	check_eq(gs.sauce, 4, "3 + 1")
	await frames(3)
	check(not is_instance_valid(drip) or drip.is_queued_for_deletion(), "the drip is gone")


func test_a_drip_stays_put_at_7_sauce_and_is_taken_once_there_is_room() -> void:
	await open_room()
	_quiet_old_dummies()
	var drip: Node3D = room.get_node("Sauce/Drip2") as Node3D
	gs.sauce = 7
	teleport(-21.0, 0.33)
	await frames(30)
	check_eq(gs.sauce, 7, "still 7")
	check(is_instance_valid(drip) and not drip.is_queued_for_deletion(), "the drip was not consumed")
	gs.sauce = 5
	await frames(10)
	check_eq(gs.sauce, 6, "taken as soon as there is room, while he stands on it")
	await frames(3)
	check(not is_instance_valid(drip) or drip.is_queued_for_deletion(), "now it is gone")


func test_no_sauce_cue_on_the_hud_when_unlocked_and_empty() -> void:
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	gs.sauce = 0
	await tap("sauce_attack")
	await frames(2)
	check_eq(flicks().size(), 0, "no shot")
	check("NOT ENOUGH SAUCE" in (room.get_node("DebugHud/Text") as Label).text, "the HUD readout shows the cue")
	await frames(45)
	check("NOT ENOUGH SAUCE" not in (room.get_node("DebugHud/Text") as Label).text, "and it goes away again")


func test_a_flick_does_not_change_movement() -> void:
	# Movement feel is approved: firing must not push, slow or lift him.
	await open_room()
	_quiet_old_dummies()
	gs.call("unlock_skill", "sauce_flick")
	teleport(-9.4, 0.33)
	await frames(30)
	var x0: float = player.global_position.x
	var y0: float = player.global_position.y
	await tap("sauce_attack")
	await frames(20)
	check(absf(player.global_position.x - x0) < 0.01, "not pushed sideways")
	check(absf(player.global_position.y - y0) < 0.01, "not lifted")
	check_eq(state(), "idle", "still idle")
