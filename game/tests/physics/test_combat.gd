extends "res://tests/physics_base.gd"
## Real test room: landing / stomp / roll / slam against both dummies through the reaction
## table, side hits, knockback and i-frames, and the bounce regression from Task 1b.


## Park an enemy at x and drop him onto it from above.
func _drop_on(enemy: Node3D, x: float, height: float = 3.0) -> void:
	park(enemy, x)
	teleport(x, height)
	await frames(2)


func test_stomp_kills_the_soft_dummy_and_bounces_him_up() -> void:
	await open_room()
	await _drop_on(soft_floor, -2.3)
	await tap("look_down")
	check(await until(func() -> bool: return not soft_floor.get("alive"), 60), "stomp killed soft")
	check(player.velocity.y > 0.0 or state() == "jump", "bounced up: " + describe())
	check_eq(gs.hearts, 14, "a stomp costs him nothing")


func test_plain_landing_on_soft_costs_the_dummy_one_hp_and_him_nothing() -> void:
	await open_room()
	await _drop_on(soft_floor, -2.3)
	check(await until(func() -> bool: return soft_floor.get("hp") < 2, 60), "landing damaged soft")
	check_eq(soft_floor.get("hp"), 1, "hp 2 -> 1")
	check(soft_floor.get("alive"), "still alive")
	await frames(40)
	check_eq(gs.hearts, 14, "no damage to him")


func test_landing_on_the_tall_dummy_bounces_off_with_no_damage_to_anyone() -> void:
	await open_room()
	park(tall, -4.0)
	teleport(-4.0, 3.5)
	await frames(60)
	check_eq(tall.get("hp"), 3, "tall unharmed")
	check(tall.get("alive"), "tall alive")
	check_eq(gs.hearts, 14, "he is unharmed too")


# Regression (Task 1b): right after a bounce he still overlaps the enemy for a frame; that was
# misread as a side hit and cost him a heart.
func test_no_side_hit_damage_right_after_a_stomp_bounce() -> void:
	await open_room()
	await _drop_on(tall, -4.0, 3.5)
	await tap("look_down") # stomp the tall one: it survives (3 hp), so he bounces off it
	await frames(60)
	check_eq(gs.hearts, 14, "no damage after bouncing off a surviving enemy: " + describe())


func test_no_side_hit_damage_right_after_a_landing_bounce_on_soft() -> void:
	await open_room()
	await _drop_on(soft_floor, -2.3)
	await frames(60)
	check_eq(gs.hearts, 14, "no damage after landing on an enemy: " + describe())
	check(soft_floor.get("hp") < 2, "the landing(s) did hurt the enemy")


func test_roll_is_locked_until_unlocked() -> void:
	await open_room()
	park(tall, -4.0)
	park(soft_floor, -30.0)
	teleport(-7.0, 0.33)
	await frames(20)
	await tap("roll")
	check(state() != "roll", "locked roll does nothing: " + describe())
	check(tall.get("alive"), "tall untouched")


func test_unlocked_roll_knocks_over_the_tall_dummy() -> void:
	await open_room()
	gs.call("unlock_skill", "roll")
	park(tall, -4.0)
	park(soft_floor, -30.0)
	teleport(-6.0, 0.33)
	await frames(20)
	Input.action_press("move_right")
	await frames(2)
	await tap("roll")
	check_eq(state(), "roll", "rolling")
	await frames(30)
	check(not tall.get("alive"), "knock_over killed tall")
	await frames(40)
	check(not tall.visible, "tall hidden after tipping over")


func test_unlocked_roll_damages_the_soft_dummy_once() -> void:
	await open_room()
	gs.call("unlock_skill", "roll")
	park(soft_floor, -2.3)
	park(tall, -30.0)
	teleport(-4.5, 0.33)
	await frames(20)
	Input.action_press("move_right")
	await frames(2)
	await tap("roll")
	await frames(40)
	check_eq(soft_floor.get("hp"), 1, "one roll = one damage (not one per frame)")


func test_slam_is_locked_in_the_air_until_unlocked() -> void:
	await open_room()
	park(soft_floor, -30.0)
	gs.call("unlock_skill", "roll") # roll alone must not give a slam
	teleport(-6.0, 3.0)
	await frames(2)
	await tap("roll")
	check(state() != "slam", "no slam while locked: " + describe())


func test_unlocked_slam_hits_every_enemy_within_its_radius() -> void:
	await open_room()
	gs.call("unlock_skill", "slam")
	park(soft_floor, -8.0)
	park(tall, -4.0)
	teleport(-6.0, 3.0) # both dummies about 2 m away
	await frames(2)
	await tap("roll")
	check_eq(state(), "slam", "slamming")
	await frames(30)
	check(not tall.get("alive") and not soft_floor.get("alive"), "slam killed both: tall=%s soft=%s" % [
		tall.get("alive"), soft_floor.get("alive")])


func test_slam_does_not_reach_a_dummy_outside_its_radius() -> void:
	await open_room()
	gs.call("unlock_skill", "slam")
	park(soft_floor, -12.0)
	park(tall, -30.0)
	teleport(-6.0, 3.0) # 6 m away, radius is 2.2
	await frames(2)
	await tap("roll")
	await frames(30)
	check(soft_floor.get("alive") and soft_floor.get("hp") == 2, "far dummy untouched")


func test_side_touch_costs_a_heart_and_knocks_him_back_with_one_second_of_i_frames() -> void:
	await open_room()
	park(soft_floor, -8.0)
	park(tall, -30.0)
	teleport(-9.5, 0.33)
	await frames(30)
	var before: int = gs.hearts
	Input.action_press("move_right")
	check(await until(func() -> bool: return gs.hearts < before, 90), "got hit from the side")
	Input.action_release("move_right")
	check_eq(gs.hearts, before - 2, "2 half-hearts = 1 heart")
	check_eq(state(), "hurt", "hurt state")
	check(player.call("is_invulnerable"), "invulnerable")
	check(player.velocity.x < 0.0, "knocked back away from the dummy: " + describe())
	await frames(20)
	check_eq(gs.hearts, before - 2, "no second hit during i-frames")
	await frames(60)
	check(not player.call("is_invulnerable"), "i-frames are over after about a second")
