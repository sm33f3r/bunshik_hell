extends "res://tests/tutorial_bot.gd"
## Task 3b-ii-fix2: the tutorial cannot be soft-locked. The playtest report: he rolled the first 단무지,
## it lay flat, and the big box (the first ledge) blocked the way for good. Here the first wheel (and the
## second) is wasted every way a player can waste it, with real input, and he still reaches the dining
## room's first table: fade, checkpoint set, tutorial off. The wheels move as they do in the game.
## Every wait is counted in physics frames (60 per second).

## The respawn delay of the wheels (data: 4 s) in frames, and how much slack a test allows around it.
const DELAY_FRAMES: int = 240
const SLACK_FRAMES: int = 90


## Opens the tutorial and plays beats a and b: he stands on the second table with the first wheel rolling.
func at_t2() -> void:
	await open_tutorial()
	var step: String = await play_a_and_b()
	check_eq(step, "", "beats a and b")


## Frames until the first wheel is a fresh upright one (not `old`); -1 if it never is.
func frames_until_back(group: String, old: Node3D, max_frames: int) -> int:
	for i: int in max_frames:
		var w: Node3D = wheel(group)
		if w != null and w != old and w.get("alive") and not w.get("flat"):
			return i
		await tree.physics_frame
	return -1


func finish_checks() -> void:
	await frames(60)
	check(on_top_of("dining_1"), "standing on the dining room's first table: " + describe())
	check_eq(gs.checkpoint_id, "map01_dining_start", "the dining room's checkpoint is set")
	check(flow.tutorial_done, "the tutorial counts as finished")
	check(not flow.enabled_sections.has("tutorial"), "the tutorial is off")
	check_eq(flow.builder.enemies_of("tutorial").size(), 0, "its enemies are gone")
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "the fade is over")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "roll and slam are his")


# --- The reported case ---------------------------------------------------------------------------------

## Roll the first wheel before bouncing on it, wait, then finish the tutorial.
func test_rolling_the_first_wheel_first_and_waiting_does_not_cost_him_the_way_on() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	var first: Node3D = wheel("c1")
	check(await roll_into("c1", t2.left + 1.2), "he rolled into the first wheel")
	check(first.get("flat") and not first.get("alive"), "it lies flat: " + wheel_line("c1", "tut_t2"))
	var back: int = await frames_until_back("c1", first, DELAY_FRAMES + 4 * SLACK_FRAMES)
	check(back >= 0, "the first wheel springs back upright by itself: " + wheel_line("c1", "tut_t2"))
	check(back >= DELAY_FRAMES - 60 and back <= DELAY_FRAMES + 2 * SLACK_FRAMES, "after its delay of about 4 s (%d frames)" % back)
	await frames(120) # he waits some more
	check_eq(await play_c1_bounce(), "", "and he bounces up onto the first ledge")
	check_eq(await play_from_ledge1(), "", "and goes on to the end")
	await finish_checks()


## The second way: roll the first wheel flat against the napkin box, climb it, the box, the ledge. No bounce.
func test_the_roll_route_alone_gets_him_up_to_the_first_ledge() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	check(await roll_into("c1", t2.left + 1.2), "he rolled into the first wheel")
	var box: LayoutGeometryScript.Placed = plat("tut_box")
	var flat_wheel: Node3D = wheel("c1")
	await until(func() -> bool: return flat_wheel.get("is_static"), 120) # it slides on the way it was hit
	check(flat_wheel.get("flat") and absf(flat_wheel.global_position.x - (box.left - flat_wheel.call("half_width"))) < 1.0,
		"it slid to the box: " + wheel_line("c1", "tut_t2"))
	check(await climb_right_to("tut_ledge1", 600), "up the flat wheel, the box, the ledge: " + describe())
	check_eq(await play_from_ledge1(), "", "and he goes on to the end")
	await finish_checks()


# --- Every other way to waste the first wheel ----------------------------------------------------------

func test_a_first_wheel_killed_by_a_slam_comes_back_and_he_bounces() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	gs.call("unlock_skill", "slam", "tutorial")
	var dead_one: Node3D = wheel("c1")
	dead_one.set("speed_scale", 0.0)
	dead_one.global_position = Vector3(t2.left + 4.0, t2.top + 0.02, 0.0)
	for i: int in 2:
		teleport(dead_one.global_position.x + 1.2, t2.top + 4.0)
		await frames(3)
		await tap("roll")
		await until(func() -> bool: return player.get("grounded"), 90)
		await frames(20)
	check(not dead_one.get("alive"), "two slams killed it")
	var back: int = await frames_until_back("c1", dead_one, DELAY_FRAMES + 4 * SLACK_FRAMES)
	check(back >= 0 and back <= DELAY_FRAMES + 3 * SLACK_FRAMES, "a new one is rolling again (%d frames)" % back)
	check_eq(await play_c1_bounce(), "", "he bounces up onto the first ledge")


func test_a_first_wheel_that_fell_off_its_table_comes_back() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	var lost: Node3D = wheel("c1")
	lost.global_position = Vector3(t2.left - 1.0, t2.top - 4.0, 0.0) # into the gap, as if pushed off
	var back: int = await frames_until_back("c1", lost, DELAY_FRAMES + 4 * SLACK_FRAMES)
	check(back >= 0, "a new one is rolling again (%d frames)" % back)
	check_eq(await play_c1_bounce(), "", "he bounces up onto the first ledge")


## Rolled away from the wall (toward the far end of the table): no step there, so it springs back.
func test_a_first_wheel_rolled_away_from_the_wall_springs_back() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	gs.call("unlock_skill", "roll", "tutorial")
	var away: Node3D = wheel("c1")
	away.set("speed_scale", 0.0)
	away.global_position = Vector3(t2.left + 5.0, t2.top + 0.02, 0.0)
	await put_on("tut_t2", 7.5)
	Input.action_press("move_left")
	await tap("roll")
	release_all()
	check(await until(func() -> bool: return away.get("is_static"), 300), "it lies flat at the far end: " + wheel_line("c1", "tut_t2"))
	var back: int = await frames_until_back("c1", away, DELAY_FRAMES + 4 * SLACK_FRAMES)
	check(back >= 0, "a new one is rolling again (%d frames)" % back)
	check_eq(await play_c1_bounce(), "", "he bounces up onto the first ledge")


## He leaves the table and comes back while the spent wheel lies there: it is replaced at once.
func test_stepping_back_onto_the_table_brings_the_spent_wheel_back_at_once() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	gs.call("unlock_skill", "roll", "tutorial")
	var away: Node3D = wheel("c1")
	away.set("speed_scale", 0.0)
	away.global_position = Vector3(t2.left + 5.0, t2.top + 0.02, 0.0)
	await put_on("tut_t2", 7.5)
	Input.action_press("move_left")
	await tap("roll")
	release_all()
	await until(func() -> bool: return away.get("is_static"), 300)
	var t1: LayoutGeometryScript.Placed = plat("tut_t1")
	await put_on("tut_t1", t1.length() - 2.0) # back on the first table (a hop away)
	await frames(20)
	check(wheel("c1") == away, "the spent wheel still lies there while he is away")
	check(await jump_to(t1.right - 0.6, "tut_t2"), "he comes back to the second table")
	var fresh: Node3D = wheel("c1")
	check(fresh != away and fresh.get("alive") and not fresh.get("flat"), "a new upright wheel is waiting: " + wheel_line("c1", "tut_t2"))


## A flat wheel he is standing on is not pulled from under him, however long he stays.
func test_a_flat_first_wheel_is_not_pulled_from_under_him() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	check(await roll_into("c1", t2.left + 1.2), "he rolled into the first wheel")
	var flat_wheel: Node3D = wheel("c1")
	await until(func() -> bool: return flat_wheel.get("is_static"), 120) # it slides on the way it was hit
	# up onto it: it lies against the box; stand on top of it
	var x_top: float = flat_wheel.global_position.x
	Input.action_press("move_right")
	var up: bool = false
	for i: int in 240:
		await tree.physics_frame
		if player.get("grounded") and absf(feet_y() - (flat_wheel.global_position.y + flat_wheel.get("body_height"))) < 0.2 \
				and absf(player.global_position.x - x_top) < 0.9:
			up = true
			break
		if player.get("grounded"):
			Input.action_press("jump")
		elif player.velocity.y <= 0.0:
			Input.action_release("jump")
	release_all()
	check(up, "he stands on the flat wheel: " + describe())
	await frames(DELAY_FRAMES + 2 * SLACK_FRAMES)
	check(wheel("c1") == flat_wheel and flat_wheel.get("flat"), "still the same flat wheel, 6 s later")
	check(player.get("grounded") and absf(feet_y() - (flat_wheel.global_position.y + flat_wheel.get("body_height"))) < 0.2, "and he is still on it: " + describe())
	teleport(t2.left + 1.0, t2.top + 0.4) # he steps off
	var back: int = await frames_until_back("c1", flat_wheel, SLACK_FRAMES)
	check(back >= 0, "once he is off it, it springs back (%d frames)" % back)


# --- Wasting both wheels -------------------------------------------------------------------------------

## The first wheel rolled flat and left, the second killed by a slam: both come back and he finishes.
func test_wasting_both_wheels_still_leaves_the_way_on() -> void:
	await at_t2()
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	check(await roll_into("c1", t2.left + 1.2), "he rolled into the first wheel")
	check_eq(await play_c1_bounce_after_respawn(), "", "the first wheel came back and he bounced up")
	check_eq(await walk_down_to_t3(), "", "down to the third table")
	var t3: LayoutGeometryScript.Placed = plat("tut_t3")
	gs.call("unlock_skill", "slam", "tutorial") # (a skip or an earlier visit gave him the slam already)
	var second: Node3D = wheel("c2")
	second.set("speed_scale", 0.0)
	second.global_position = Vector3(t3.left + 4.0, t3.top + 0.02, 0.0)
	for i: int in 2:
		teleport(second.global_position.x + 1.2, t3.top + 4.0)
		await frames(3)
		await tap("roll")
		await until(func() -> bool: return player.get("grounded"), 90)
		await frames(20)
	check(not second.get("alive"), "two slams killed the second wheel")
	var back: int = await frames_until_back("c2", second, DELAY_FRAMES + 4 * SLACK_FRAMES)
	check(back >= 0, "a new second wheel is rolling (%d frames)" % back)
	check_eq(await play_c2_to_end(), "", "he rolls into it, climbs, slams, and jumps the exit gap")
	await finish_checks()


## Waits until the wheel of c1 is a fresh upright one, then bounces.
func play_c1_bounce_after_respawn() -> String:
	var spent: Node3D = null
	var w: Node3D = wheel("c1")
	if w != null and not w.get("alive"):
		spent = w
	if await frames_until_back("c1", spent, DELAY_FRAMES + 4 * SLACK_FRAMES) < 0:
		return "c1: the wheel did not come back"
	return await play_c1_bounce()
