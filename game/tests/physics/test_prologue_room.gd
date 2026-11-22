extends "res://tests/physics_base.gd"
## Task 3a / 3a-fix, real Map 1 scene at real scale: the cutscene gate, the pick (and that it stays
## inside him), a stab and its shadow, her forearm and the jump to the next table, the live 만두 and
## the pause menu in the real map. Every wait is counted in physics frames.

const MAP_SCENE := "res://maps/ep01/map01_bunsikjip/map01.tscn"
const DirectorScript := preload("res://prologue/prologue_director.gd")

var map: Node3D
var dir: DirectorScript


## Opens Map 1 on a fresh game. skip_cutscene = pretend the cutscene was already seen.
## The three live 만두 are removed unless keep_mandu (they hurt on contact and would add noise).
func open_map(skip_cutscene: bool = true, keep_mandu: bool = false) -> void:
	gs = tree.root.get_node_or_null("GameState")
	if gs == null:
		failures.append("GameState autoload missing")
		return
	gs.call("reset")
	gs.set("prologue_intro_seen", skip_cutscene)
	room = (load(MAP_SCENE) as PackedScene).instantiate() as Node3D
	tree.root.add_child(room)
	map = room
	player = room.get_node("Player") as CharacterBody3D
	await frames(3) # the map's _ready finishes during the first frames of the first run
	dir = map.get("director")
	if not keep_mandu:
		# The live 만두 hurt on contact: tests about hearts and stabs start without them.
		for mandu: Node3D in (map.call("live_mandu") as Array):
			mandu.call("debug_defeat")
		# ... and they do not come back by themselves (that is tested on its own, with keep_mandu).
		map.get("_mandu_respawn").set("count", 0)


## Frees him from the opening pick at once and waits until he stands on the counter. The
## stabbing does not start for a while (PRE_STAB), so tests can set things up first.
func stand_on_counter() -> void:
	dir.debug_free()
	await until(func() -> bool: return player.get("grounded"), 120)


## Keeps the director in its pause before the stabbing, so nothing stabs during the test.
func hold_stabs_back() -> void:
	dir.set("_pre_left", 1000.0)


func tap_alternating(n: int) -> void:
	for i: int in n:
		await tap("move_left" if i % 2 == 0 else "move_right")
		await frames(3)


# --- Start ----------------------------------------------------------------------------------

func test_map_1_is_the_main_scene_and_the_test_room_is_still_there() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), MAP_SCENE, "main scene")
	check(ResourceLoader.exists("res://maps/test/test_room.tscn"), "the test room still exists")
	check(ResourceLoader.exists(ROOM_SCENE), "and is still loaded by its path")


func test_a_new_game_starts_with_the_cutscene_and_it_can_be_skipped() -> void:
	await open_map(false)
	check_eq(dir.state, DirectorScript.State.INTRO, "the cutscene plays")
	check(player.get("controlled"), "the 떡 is held (no input) during it")
	check_eq(gs.hearts, 14, "7 hearts")
	check_eq(gs.sauce, 3, "3 sauce")
	check_eq(gs.sodium, 0, "0 나트륨")
	check(not gs.has_skill("roll") and not gs.has_skill("slam") and not gs.has_skill("sauce_flick"), "roll, slam, flick locked")
	check(gs.has_skill("move") and gs.has_skill("jump") and gs.has_skill("landing") and gs.has_skill("stomp"), "move, jump, landing, stomp")
	var cam: Camera3D = room.get_node("SideCamera") as Camera3D
	var start_x: float = cam.global_position.x
	await frames(60)
	check(absf(cam.global_position.x - start_x) > 0.5, "the camera pans across the shop")
	await tap("jump")
	await frames(3)
	check_eq(dir.state, DirectorScript.State.PICK, "jump skipped the cutscene")
	check_eq(map.get("ui").subtitle_text(), "오~~~ 맛있겠다~~~~~", "and her line is on the subtitle box")


func test_enter_also_skips_the_cutscene() -> void:
	await open_map(false)
	await frames(15)
	await tap("ui_accept")
	await frames(3)
	check_eq(dir.state, DirectorScript.State.PICK, "Enter / the south button skips too")


func test_the_cutscene_ends_by_itself_on_the_cup() -> void:
	await open_map(false)
	await frames(int(dir.intro_total() * 60.0) + 30)
	check_eq(dir.state, DirectorScript.State.PICK, "after the shots the pick begins")
	check(gs.get("prologue_intro_seen"), "marked seen")


func test_no_cutscene_when_it_was_already_seen() -> void:
	await open_map(true)
	check_eq(dir.state, DirectorScript.State.PICK, "straight to the pick")


# --- Pick and wiggle ----------------------------------------------------------------------------

func test_wiggling_with_the_real_keys_frees_him_onto_the_counter() -> void:
	await open_map()
	check(player.get("controlled"), "speared: no control")
	var y0: float = player.global_position.y
	await frames(60)
	check(player.global_position.y > y0 + 0.5, "the pick is rising with him on it")
	await tap_alternating(10)
	check_eq(dir.state, DirectorScript.State.PRE_STAB, "10 alternations freed him")
	check(await until(func() -> bool: return player.get("grounded"), 180), "he dropped onto the counter: " + describe())
	check(absf(player.global_position.y - (dir.data.counter_top_y + 0.32)) < 0.1, "standing on the counter: " + describe())
	check(not player.get("controlled"), "control is back")
	check(map.get("ui").wiggle_visible() == false, "the meter is gone")


func test_the_wiggle_meter_shows_while_he_is_speared() -> void:
	await open_map()
	await frames(5)
	check(map.get("ui").wiggle_visible(), "meter visible")
	await tap("move_left")
	await frames(3)
	await tap("move_right")
	check(dir.wiggle_alts >= 2, "presses reach the director (%d)" % dir.wiggle_alts)


func test_failing_the_wiggle_gets_him_eaten_then_back_to_the_opening_line() -> void:
	await open_map()
	gs.call("take_damage", 4)
	await frames(int(dir.data.window_s * 60.0) + 12)
	check_eq(dir.state, DirectorScript.State.EATEN, "eaten")
	await frames(40)
	check(map.get("ui").blackout_progress() > 0.0, "the screen blacks out from the top")
	await frames(int(dir.data.eaten_total_s * 60.0))
	check_eq(dir.state, DirectorScript.State.PICK, "restart at the 맛있겠다 moment")
	check_eq(dir.count, 0, "count 0")
	check_eq(gs.hearts, 14, "hearts 7")
	check_eq(map.get("ui").subtitle_text(), "오~~~ 맛있겠다~~~~~", "her line again")
	check_eq(map.get("ui").blackout_progress(), 0.0, "the screen is clear again")
	check(player.get("controlled"), "speared again")


# --- A stab and its shadow ------------------------------------------------------------------------

func _wait_for_lock() -> bool:
	return await until(func() -> bool: return dir.stab != null and dir.stab.locked, 400)


func test_a_stab_lands_where_its_shadow_was_and_hurts_him_standing_there() -> void:
	await open_map()
	dir.debug_free()
	dir.force_next_pattern(dir.find_pattern("single_small"))
	check(await _wait_for_lock(), "the shadow locked")
	check(map.get("actor").shadow_visible(), "the shadow is on the tabletop")
	var shadow: float = map.get("actor").shadow_node_x()
	check(absf(shadow - dir.stab.target_x) < 0.01, "the shadow is at the target")
	check(absf(player.global_position.x - shadow) < 1.2, "he is standing there (%.2f vs %.2f)" % [player.global_position.x, shadow])
	check(await until(func() -> bool: return dir.landed_count == 1, 120), "the stab landed")
	check(absf(map.get("actor").tip_position.x - shadow) < 0.01, "the pick came down on the shadow")
	await frames(3)
	check_eq(gs.hearts, 13, "a small stab took a half-heart")


func test_a_stab_does_not_hurt_a_떡_that_moved_away() -> void:
	await open_map()
	dir.debug_free()
	dir.force_next_pattern(dir.find_pattern("single_small"))
	check(await _wait_for_lock(), "the shadow locked")
	var target: float = dir.stab.target_x
	teleport(1.0 if target > 6.0 else _free_x(), dir.data.counter_top_y + 0.4)
	check(await until(func() -> bool: return dir.landed_count == 1, 120), "the stab landed")
	await frames(30)
	check_eq(gs.hearts, 14, "he was not there: no damage")
	check_eq(dir.count, 1, "it still counted")


func test_a_big_stab_hurts_a_heart_and_lifts_him_until_he_wiggles_off() -> void:
	await open_map()
	dir.debug_free()
	dir.force_next_pattern(dir.find_pattern("single_big"))
	check(await until(func() -> bool: return dir.state == DirectorScript.State.LIFT, 600), "lifted")
	check_eq(gs.hearts, 12, "a big stab: one heart")
	check(player.get("controlled"), "held on the pick")
	var y0: float = player.global_position.y
	await frames(40)
	check(player.global_position.y > y0 + 0.5, "he rises with the pick")
	await tap_alternating(10)
	check_eq(dir.state, DirectorScript.State.STAB, "wiggled off: the stabbing goes on")
	check(await until(func() -> bool: return player.get("grounded"), 240), "dropped back onto the counter")
	check(not player.get("controlled"), "control is back")


func test_dying_during_the_stabs_restarts_at_the_pick_with_count_zero() -> void:
	await open_map()
	await stand_on_counter()
	dir.debug_set_count(9)
	gs.call("take_damage", 14)
	await frames(100)
	check_eq(dir.state, DirectorScript.State.PICK, "back on the pick")
	check_eq(dir.count, 0, "count 0")
	check_eq(gs.hearts, 14, "hearts 7")
	check(player.get("controlled"), "speared")
	check_eq(map.get("ui").subtitle_text(), "오~~~ 맛있겠다~~~~~", "her opening line")


# --- The counter, her forearm, the gap -------------------------------------------------------------

func _top() -> float:
	return dir.data.counter_top_y


## A spot on her counter clear of every prop, on the right (between the 수저통 and her forearm).
func _free_x() -> float:
	return dir.data.section_max_x - 1.0


func test_he_cannot_leave_her_counter_before_the_exit_opens() -> void:
	await open_map()
	await stand_on_counter()
	hold_stabs_back()
	teleport(_free_x(), _top() + 0.4)
	Input.action_press("move_right")
	var max_x: float = 0.0
	for i: int in 120:
		await tree.physics_frame
		max_x = maxf(max_x, player.global_position.x)
		if i % 25 == 0:
			Input.action_press("jump")
		elif i % 25 == 12:
			Input.action_release("jump")
	check(max_x < dir.data.forearm_left_x, "stopped by her forearm (max x %.2f, forearm at %.2f)" % [max_x, dir.data.forearm_left_x])
	Input.action_release("move_right")
	Input.action_release("jump")
	teleport(1.0, _top() + 0.4)
	Input.action_press("move_left")
	var min_x: float = 99.0
	for i: int in 90:
		await tree.physics_frame
		min_x = minf(min_x, player.global_position.x)
		if i % 25 == 0:
			Input.action_press("jump")
		elif i % 25 == 12:
			Input.action_release("jump")
	check(min_x > -0.1, "stopped by the left wall (min x %.2f)" % min_x)
	check(player.global_position.y > _top() - 0.5, "never fell off: " + describe())


## Runs right and jumps at the end of her counter. Returns whether he got onto the next table.
func _try_the_jump(start_x: float) -> bool:
	teleport(start_x, _top() + 0.4)
	await frames(10)
	Input.action_press("move_right")
	var jumped: bool = false
	var jump_frame: int = 0
	var landed: bool = false
	for i: int in 240:
		await tree.physics_frame
		if not jumped and player.global_position.x >= dir.data.counter_length_m - 0.6:
			Input.action_press("jump")
			jumped = true
			jump_frame = i
		if jumped and i - jump_frame == 26:
			Input.action_release("jump")
		if player.global_position.x >= dir.data.next_table_min_x and player.get("grounded") \
				and player.global_position.y > _top():
			landed = true
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	return landed


func test_he_cannot_cross_to_the_next_table_while_her_forearm_is_there() -> void:
	await open_map()
	await stand_on_counter()
	hold_stabs_back()
	var reached: bool = await _try_the_jump(_free_x() - 0.5)
	check(not reached, "no way across while the forearm lies there")
	check(player.global_position.x < dir.data.forearm_left_x, "he never got past it: " + describe())
	check(map.get("set_node").forearm_blocking(), "and it is still blocking")


# --- The exit -------------------------------------------------------------------------------------

func _open_the_exit() -> void:
	dir.debug_free()
	dir.debug_set_count(29)
	dir.set("_pre_left", 0.0)
	teleport(_free_x(), _top() + 0.4)
	await until(func() -> bool: return dir.state == DirectorScript.State.EXIT_OPEN, 400)
	await frames(30)


func test_the_30th_stab_makes_her_yank_her_forearm_away() -> void:
	await open_map()
	check(map.get("set_node").forearm_blocking(), "the forearm lies across the counter at the start")
	await _open_the_exit()
	check_eq(dir.state, DirectorScript.State.EXIT_OPEN, "exit open")
	check_eq(gs.hearts, 14, "the 30th is a miss")
	check(not map.get("set_node").forearm_blocking(), "the forearm no longer blocks")
	await frames(40)
	check(not map.get("set_node").forearm_visible(), "and it has been yanked out of the way")
	check(not map.get("actor").shadow_visible(), "no shadow left")
	check(room.get_node_or_null("StuckPick") == null, "no stuck pick any more")


func test_he_can_jump_from_her_counter_to_the_next_table_once_the_forearm_is_gone() -> void:
	await open_map()
	await _open_the_exit()
	check_eq(dir.state, DirectorScript.State.EXIT_OPEN, "exit open")
	var reached: bool = await _try_the_jump(_free_x() - 0.5)
	check(reached, "landed on the next table: " + describe())
	await frames(5)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "prologue complete")
	check(player.global_position.x >= dir.data.next_table_min_x, "x on the table: " + describe())
	check(absf(player.global_position.y - (dir.data.next_table_top_y + 0.32)) < 0.15, "same height as her counter: " + describe())
	check(gs.get("prologue_complete"), "prologue complete flag")
	check_eq(gs.get("checkpoint_id"), "map01_tutorial_start", "respawn point set there (the tutorial's start, on the next table)")
	await frames(3)
	check(map.get("flow").get("ui").prompt_visible(), "the tutorial prompt is up (Task 3b-i: it replaced the dev note)")
	check(not map.get("ui").dev_note_visible(), "and the old dev note is gone")


func test_falling_into_the_gap_puts_him_back_on_the_counter_without_a_hit() -> void:
	await open_map()
	await _open_the_exit()
	teleport(dir.data.counter_length_m + 1.0, _top() + 0.4) # in the middle of the gap
	await frames(10)
	check(await until(func() -> bool: return player.global_position.y > _top() - 1.0 and player.global_position.x < dir.data.counter_length_m, 200),
		"he is put back on her counter: " + describe())
	check_eq(gs.hearts, 14, "no damage for falling")


# --- The pick stays inside him -------------------------------------------------------------------------

## True if world point `p` is inside his collision capsule, `margin` metres from its surface.
func _inside_his_capsule(p: Vector3, margin: float) -> bool:
	var shape_node: CollisionShape3D = player.get_node("CollisionShape3D") as CollisionShape3D
	var capsule: CapsuleShape3D = shape_node.shape as CapsuleShape3D
	var local: Vector3 = shape_node.global_transform.affine_inverse() * p
	var half: float = maxf(capsule.height * 0.5 - capsule.radius, 0.0)
	var on_axis: Vector3 = Vector3(0.0, clampf(local.y, -half, half), 0.0)
	return local.distance_to(on_axis) <= capsule.radius - margin


func test_the_pick_tip_stays_inside_his_body_while_he_is_speared() -> void:
	await open_map()
	var actor: Node3D = map.get("actor")
	var margin: float = dir.data.spear_margin_m * 0.5
	for i: int in 6:
		await frames(20)
		check(player.get("controlled"), "still speared")
		check(_inside_his_capsule(actor.get("tip_position"), margin),
			"the tip is inside his collision shape at frame %d (tip %s, he %s)" % [i * 20, str(actor.get("tip_position")), str(player.global_position)])
		var depth_from_top: float = (player.global_position.y + player.body_half_height) - actor.get("tip_position").y
		check(depth_from_top <= 2.0 * player.body_half_height - dir.data.spear_margin_m + 0.001,
			"and not through the far side (depth %.3f of %.3f)" % [depth_from_top, 2.0 * player.body_half_height])
	check(absf(actor.get("tip_position").z - player.global_position.z) < 0.01, "in his plane, so his body hides the part inside him")


func test_the_pick_tip_stays_inside_him_during_a_big_stabs_lift_too() -> void:
	await open_map()
	dir.debug_free()
	dir.force_next_pattern(dir.find_pattern("single_big"))
	check(await until(func() -> bool: return dir.state == DirectorScript.State.LIFT, 600), "lifted")
	var actor: Node3D = map.get("actor")
	for i: int in 4:
		await frames(25)
		check(_inside_his_capsule(actor.get("tip_position"), dir.data.spear_margin_m * 0.5),
			"the tip is inside him during the lift (frame %d)" % (i * 25))


func test_the_spear_depth_is_clamped_to_his_thickness_minus_the_margin() -> void:
	await open_map()
	var actor: Node3D = map.get("actor")
	var thickness: float = 2.0 * player.body_half_height
	check(actor.call("spear_depth") <= thickness - dir.data.spear_margin_m + 0.0001, "the depth is within his thickness")
	dir.data.spear_depth_m = 5.0 # a silly value must still be clamped
	check(actor.call("spear_depth") <= thickness - dir.data.spear_margin_m + 0.0001, "even a huge request is clamped")
	dir.data.spear_depth_m = 0.56


# --- Her mouth ----------------------------------------------------------------------------------------

func test_her_mouth_slides_into_view_as_he_nears_it_and_chomps_when_he_is_eaten() -> void:
	await open_map()
	var actor: Node3D = map.get("actor")
	check(not actor.call("mouth_visible"), "no mouth at the start of the lift")
	await frames(int(dir.data.window_s * 60.0 * 0.8))
	check(actor.call("mouth_visible"), "the lips have come into view as he gets close")
	var mouth: Node3D = actor.call("mouth_node")
	check(mouth.call("gap_m") > mouth.get("open_gap_m"), "and it is open")
	await until(func() -> bool: return dir.state == DirectorScript.State.EATEN, 120)
	var open_gap: float = mouth.call("gap_m")
	await frames(int(dir.data.eaten_chomp_s * 60.0) + 3)
	check(mouth.call("gap_m") < open_gap * 0.5, "the mouth closed on him (%.2f -> %.2f)" % [open_gap, mouth.call("gap_m")])
	await frames(int(dir.data.eaten_total_s * 60.0))
	check_eq(dir.state, DirectorScript.State.PICK, "then the restart")
	check(not actor.call("mouth_visible"), "and no mouth again")


func test_her_hand_comes_down_for_a_stab() -> void:
	await open_map()
	var actor: Node3D = map.get("actor")
	check(actor.call("hand_visible"), "her hand holds the pick")
	dir.debug_free()
	dir.force_next_pattern(dir.find_pattern("single_small"))
	check(await until(func() -> bool: return dir.stab != null and dir.stab.locked, 400), "a stab telegraphs")
	check(actor.call("hand_visible"), "the hand holds the pick during the stab")


# --- Live 만두 -------------------------------------------------------------------------------------------

func test_her_plate_starts_with_three_live_mandu_standing_on_it() -> void:
	await open_map(true, true)
	var live: Array = map.call("live_mandu")
	check_eq(live.size(), 3, "three live 만두")
	await frames(10)
	for mandu: Node3D in live:
		check(absf(mandu.global_position.y - dir.data.counter_top_y) < 1.0, "on the counter / plate (or mid-hop): " + str(mandu.global_position))


func test_a_live_mandu_waddles_along_the_counter() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	var mandu: Node3D = (map.call("live_mandu") as Array)[0]
	await frames(30)
	var x0: float = mandu.global_position.x
	await frames(90)
	check(absf(mandu.global_position.x - x0) > 0.5, "it moved (%.2f -> %.2f)" % [x0, mandu.global_position.x])
	check(mandu.get("alive"), "and it is alive")


func test_a_live_mandu_turns_at_the_edge_of_the_counter_and_does_not_fall() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	map.get("set_node").call("set_exit_open", true) # the forearm is gone: there is an edge now
	await frames(5)
	var mandu: Node3D = (map.call("live_mandu") as Array)[0]
	var edge: float = dir.data.counter_length_m
	mandu.global_position = Vector3(edge - 1.4, _top() + 0.05, 0.0)
	mandu.set("_dir", 1.0)
	mandu.velocity = Vector3.ZERO
	var max_x: float = 0.0
	var turned: bool = false
	for i: int in 240:
		await tree.physics_frame
		max_x = maxf(max_x, mandu.global_position.x)
		if mandu.get("_dir") < 0.0:
			turned = true
	check(turned, "it turned round at the edge")
	check(max_x < edge, "and never left the counter (max x %.2f, edge %.2f)" % [max_x, edge])
	check(mandu.global_position.y > _top() - 0.5, "it did not fall: " + str(mandu.global_position))


func test_a_live_mandu_dies_to_a_stomp_and_costs_him_nothing() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	var mandu: Node3D = (map.call("live_mandu") as Array)[0]
	mandu.set_physics_process(false) # hold it still so he lands on it
	mandu.global_position = Vector3(_free_x() + 0.5, _top() + 0.05, 0.0)
	teleport(_free_x() + 0.5, _top() + 3.0)
	await frames(2)
	await tap("look_down")
	check(await until(func() -> bool: return not mandu.get("alive"), 90), "the stomp killed the 만두")
	check_eq(gs.hearts, 14, "a stomp costs him nothing")
	check_eq((map.call("live_mandu") as Array).size(), 2, "two left on her counter")


func test_stomping_three_mandu_drops_oil_on_the_third_and_it_heals_half_a_heart() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	(map.get("_mandu_respawn") as RefCounted).set("count", 0)
	gs.take_damage(4)
	for n: int in 3:
		var live: Array = map.call("live_mandu")
		var mandu: Node3D = live[0]
		mandu.set_physics_process(false)
		mandu.global_position = Vector3(_free_x() + 0.5, _top() + 0.05, 0.0)
		teleport(_free_x() + 0.5, _top() + 3.0)
		await frames(2)
		await tap("look_down")
		check(await until(func() -> bool: return not mandu.get("alive"), 90), "stomp %d killed a 만두" % (n + 1))
		var kinds: Array[String] = []
		for dropped: Dictionary in mandu.get("last_drops"):
			kinds.append(dropped["kind"])
		check_eq(kinds.has("sesame_oil"), n == 2, "oil after stomp %d only if it is the 3rd" % (n + 1))
		if n < 2:
			await frames(5)
	# The drop falls where the 만두 died, right under him: a hurt 떡 touching it heals ½ heart.
	var hearts_before: int = 14 - 4
	check(await until(func() -> bool: return gs.hearts > hearts_before, 120), "walking into the oil healed him")
	check_eq(gs.hearts, hearts_before + 1, "exactly half a heart")
	await frames(10)
	check_eq(gs.hearts, hearts_before + 1, "and the drop was used up (no second heal)")


func test_touching_a_live_mandu_from_the_side_costs_a_heart() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	var mandu: Node3D = (map.call("live_mandu") as Array)[0]
	mandu.set_physics_process(false)
	mandu.global_position = Vector3(_free_x() + 0.5, _top() + 0.05, 0.0)
	teleport(_free_x() - 1.2, _top() + 0.4)
	await frames(5)
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(gs.hearts <= 12, "contact cost him a heart: %d half-hearts" % gs.hearts)


func test_a_mandu_break_spears_a_live_mandu_and_it_dies() -> void:
	await open_map(true, true)
	dir.debug_free()
	await until(func() -> bool: return dir.state == DirectorScript.State.STAB, 400)
	var all: Array = map.call("live_mandu")
	var mandu: Node3D = all[0]
	for other: Node3D in all:
		if other != mandu:
			other.call("debug_defeat") # only one is left to aim at
	mandu.set_physics_process(false)
	mandu.global_position = Vector3(_free_x(), _top() + 0.05, 0.0)
	var eaten: Array[float] = []
	dir.mandu_eaten.connect(func(x: float) -> void: eaten.append(x))
	var lines: Array[String] = []
	dir.line_shown.connect(func(key: String, _t: String) -> void: lines.append(key))
	dir.force_next_pattern(dir.find_pattern("mandu_break"))
	check(await until(func() -> bool: return not eaten.is_empty(), 600), "she stabbed a live 만두")
	await frames(10)
	check(not mandu.get("alive"), "and it died")
	check(lines.has("mandu_break"), "she said her line")
	check_eq((map.call("live_mandu") as Array).size(), 0, "none left on the plate")
	for p in dir.eligible_patterns(0, 29):
		check(p.kind != "mandu", "no 만두 breaks without a 만두")


func test_a_mandu_walking_into_a_stab_is_hit_by_it() -> void:
	await open_map(true, true)
	dir.debug_free()
	await until(func() -> bool: return dir.state == DirectorScript.State.STAB, 400)
	var mandu: Node3D = (map.call("live_mandu") as Array)[0]
	mandu.set_physics_process(false)
	dir.force_next_pattern(dir.find_pattern("single_small"))
	check(await until(func() -> bool: return dir.stab != null and dir.stab.locked, 400), "the shadow locked")
	mandu.global_position = Vector3(dir.stab.target_x, _top() + 0.05, 0.0)
	teleport(1.0 if dir.stab.target_x > 6.0 else _free_x(), _top() + 0.4)
	check(await until(func() -> bool: return not mandu.get("alive"), 200), "the pick killed the 만두 under it")


func test_the_mandu_come_back_after_a_restart() -> void:
	await open_map(true, true)
	for mandu: Node3D in (map.call("live_mandu") as Array):
		mandu.call("debug_defeat")
	check_eq((map.call("live_mandu") as Array).size(), 0, "all dead")
	dir.restart()
	await frames(3)
	check_eq((map.call("live_mandu") as Array).size(), 3, "three live again after the restart")


## Kills every live 만두 and returns how many frames it takes until new ones are on the plate.
func _frames_until_restocked(max_frames: int) -> int:
	for i: int in max_frames:
		if (map.call("live_mandu") as Array).size() > 0:
			return i
		await tree.physics_frame
	return -1


func test_two_new_mandu_appear_when_the_last_one_is_killed_by_him() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	var all: Array = map.call("live_mandu")
	for i: int in 2:
		(all[i] as Node3D).call("debug_defeat")
	var last: Node3D = all[2]
	last.set_physics_process(false)
	last.global_position = Vector3(_free_x() + 0.5, _top() + 0.05, 0.0)
	teleport(_free_x() + 0.5, _top() + 3.0)
	await frames(2)
	await tap("look_down")
	check(await until(func() -> bool: return not last.get("alive"), 90), "the stomp killed the last one")
	await frames(60)
	check_eq((map.call("live_mandu") as Array).size(), 0, "still none after 1 s (the delay is 1.5 s)")
	var waited: int = await _frames_until_restocked(180)
	check(waited >= 0, "new 만두 appeared")
	check_eq((map.call("live_mandu") as Array).size(), 2, "two, not three")
	await frames(120)
	check_eq((map.call("live_mandu") as Array).size(), 2, "and no more while they live")


func test_two_new_mandu_appear_when_she_eats_the_last_one() -> void:
	await open_map(true, true)
	dir.debug_free()
	await until(func() -> bool: return dir.state == DirectorScript.State.STAB, 400)
	var all: Array = map.call("live_mandu")
	var mandu: Node3D = all[0]
	for other: Node3D in all:
		if other != mandu:
			other.call("debug_defeat")
	mandu.set_physics_process(false)
	mandu.global_position = Vector3(_free_x(), _top() + 0.05, 0.0)
	var eaten: Array[float] = []
	dir.mandu_eaten.connect(func(x: float) -> void: eaten.append(x))
	dir.force_next_pattern(dir.find_pattern("mandu_break"))
	check(await until(func() -> bool: return not eaten.is_empty(), 600), "she ate the last 만두")
	await frames(10)
	check(not mandu.get("alive"), "it is gone")
	var waited: int = await _frames_until_restocked(300)
	check(waited >= 0, "new 만두 appeared")
	check_eq((map.call("live_mandu") as Array).size(), 2, "two appear")


func test_a_restart_puts_three_back_even_while_a_restock_is_counting_down() -> void:
	await open_map(true, true)
	await stand_on_counter()
	hold_stabs_back()
	for mandu: Node3D in (map.call("live_mandu") as Array):
		mandu.call("debug_defeat")
	await frames(30) # the restock is counting down
	dir.restart()
	await frames(3)
	check_eq((map.call("live_mandu") as Array).size(), 3, "three again after the restart")
	await frames(240)
	check_eq((map.call("live_mandu") as Array).size(), 3, "and the old countdown added nothing")


func test_her_reaction_shows_as_a_subtitle_in_the_real_scene() -> void:
	await open_map(true, false)
	dir.debug_free()
	await until(func() -> bool: return dir.state == DirectorScript.State.STAB, 400)
	teleport(_free_x(), _top() + 0.5)
	dir.force_next_pattern(dir.find_pattern("fake_out"))
	check(await until(func() -> bool: return dir.line_key == "reaction", 600), "she reacted")
	await frames(3)
	var ui: CanvasLayer = map.get("ui")
	var pool: Array = dir.data.reactions
	check(ui.call("subtitle_text") in pool, "the subtitle is one of the four: " + str(ui.call("subtitle_text")))


# --- Pause menu in the real map -------------------------------------------------------------------------

func _press(actions: Array[String]) -> void:
	for action: String in actions:
		Input.action_press(action)
	await frames(2)
	for action: String in actions:
		Input.action_release(action)
	await frames(4)


func test_pausing_mid_stab_freezes_the_pick_and_resuming_continues_it() -> void:
	await open_map()
	dir.debug_free()
	dir.force_next_pattern(dir.find_pattern("single_small"))
	check(await until(func() -> bool: return dir.stab != null and dir.stab.phase == DirectorScript.Phase.TELEGRAPH, 400), "a stab is telegraphing")
	await frames(10)
	await _press(["pause"] as Array[String])
	check(tree.paused, "paused")
	await frames(3)
	var t0: float = dir.stab.phase_t
	var tip0: Vector3 = map.get("actor").get("tip_position")
	var ticks0: int = map.get("_ticks")
	await frames(60)
	check_eq(dir.stab.phase_t, t0, "the stab did not advance while paused")
	check_eq(map.get("actor").get("tip_position"), tip0, "the pick did not move")
	check_eq(map.get("_ticks"), ticks0, "the map did not tick")
	await _press(["pause"] as Array[String])
	check(not tree.paused, "resumed")
	await frames(20)
	check(dir.stab == null or dir.stab.phase_t > t0 or dir.stab.phase != DirectorScript.Phase.TELEGRAPH, "the stab carried on from where it was")


func test_pausing_the_cutscene_freezes_it_and_resuming_does_not_skip_it() -> void:
	await open_map(false)
	await frames(30)
	await _press(["pause"] as Array[String])
	check(tree.paused, "paused during the cutscene")
	await frames(3)
	var t0: float = dir.intro_t
	await frames(60)
	check_eq(dir.intro_t, t0, "the cutscene is frozen")
	# Confirm Resume with the south button: that press must not skip the cutscene.
	await _press(["ui_accept"] as Array[String])
	check(not tree.paused, "resumed")
	await frames(10)
	check_eq(dir.state, DirectorScript.State.INTRO, "closing the menu did not skip the cutscene")
	check(dir.intro_t > t0, "and it carries on from where it stopped")


func test_pausing_the_wiggle_freezes_the_clock() -> void:
	await open_map()
	await frames(30)
	await _press(["pause"] as Array[String])
	await frames(3)
	var t0: float = dir.wiggle_t
	await frames(90)
	check_eq(dir.wiggle_t, t0, "the wiggle window did not run down while paused")
	check_eq(dir.state, DirectorScript.State.PICK, "he was not eaten while paused")
	await _press(["pause"] as Array[String])
	await frames(10)
	check(dir.wiggle_t > t0, "the wiggle clock runs again")


func test_restart_from_the_pause_menu_goes_back_to_the_opening_moment() -> void:
	await open_map()
	dir.debug_free()
	dir.debug_set_count(12)
	await until(func() -> bool: return dir.state == DirectorScript.State.STAB, 400)
	gs.call("take_damage", 4)
	await _press(["pause"] as Array[String])
	await _press(["look_down"] as Array[String])
	await _press(["ui_accept"] as Array[String])
	check(not tree.paused, "the menu closed")
	await frames(3)
	check_eq(dir.state, DirectorScript.State.PICK, "back at the 맛있겠다 moment")
	check_eq(dir.count, 0, "count 0")
	check_eq(gs.hearts, 14, "full hearts")
	check(player.get("controlled"), "speared again")


func test_restart_after_the_prologue_goes_to_the_checkpoint_on_the_next_table() -> void:
	await open_map()
	await key_event(KEY_8)
	await frames(60)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "complete")
	await _press(["ui_accept"] as Array[String]) # the tutorial prompt is open (it pauses the game): start it
	teleport(dir.data.next_table_spawn.x + 4.0, dir.data.next_table_top_y + 1.0)
	await _press(["pause"] as Array[String])
	await _press(["look_down"] as Array[String])
	await _press(["ui_accept"] as Array[String])
	await frames(20)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "still complete: no prologue again")
	check(absf(player.global_position.x - dir.data.next_table_spawn.x) < 1.5, "back at the checkpoint on the next table: " + describe())


func test_esc_closes_the_inventory_and_does_not_pause() -> void:
	await open_map()
	await stand_on_counter()
	hold_stabs_back()
	gs.call("try_equip_container", "starter_container")
	await _press(["inventory"] as Array[String])
	check(tree.paused, "the inventory paused the game")
	await _press(["pause", "ui_cancel"] as Array[String]) # Esc
	check(not tree.paused, "Esc closed the inventory and the game runs")
	check(not room.get_node("PauseMenu").call("is_open"), "and the pause menu stayed shut")


# --- Debug ----------------------------------------------------------------------------------------

func test_debug_key_8_finishes_the_prologue() -> void:
	await open_map()
	await key_event(KEY_8)
	await frames(60)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "complete")
	check(absf(player.global_position.x - dir.data.next_table_spawn.x) < 1.0, "at the next table: " + describe())
	check(absf(player.global_position.y - (dir.data.next_table_top_y + 0.32)) < 0.2, "standing on it: " + describe())
	check(map.get("flow").get("ui").prompt_visible(), "the tutorial prompt is up (it replaced the dev note)")
	check(not map.get("actor").shadow_visible(), "no stabbing any more")
	await _press(["ui_accept"] as Array[String]) # start the tutorial: the prompt pauses the game
	check(not tree.paused, "the game runs again")
	# Dying afterwards respawns him there, not at the pick.
	gs.call("take_damage", 14)
	await frames(100)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "still complete")
	check(absf(player.global_position.x - dir.data.next_table_spawn.x) < 1.0, "respawned at the next table: " + describe())
	check_eq(gs.hearts, 14, "full hearts")


func test_the_debug_hud_shows_the_prologue_and_the_old_keys_still_work() -> void:
	await open_map()
	await frames(5)
	var hud_label: Label = room.get_node("DebugHud/Text") as Label
	check(not hud_label.visible, "the debug text is hidden in the game until key 9")
	await key_event(KEY_9)
	check(hud_label.visible, "key 9 shows it")
	await frames(3)
	var text: String = hud_label.text
	check("Stabs: 0 / 30" in text, "stab count: " + text)
	check("Anger stage: 0" in text, "anger stage")
	check("Pattern:" in text, "current pattern")
	check("Wiggle: 0 / 10" in text, "wiggle progress")
	check("8 finish the prologue" in text, "key 8 listed")
	check("1 unlock roll+slam" in text, "the old key list is still there")
	await key_event(KEY_1)
	check(gs.has_skill("roll") and gs.has_skill("slam"), "key 1 still unlocks roll and slam")
	await key_event(KEY_2)
	check(not gs.has_skill("roll"), "key 2 still relocks")
	await key_event(KEY_4)
	check_eq(gs.hearts, 12, "key 4 still takes a heart")


func test_key_8_does_nothing_in_the_test_room() -> void:
	await open_room()
	await key_event(KEY_8)
	await frames(5)
	check_eq(gs.hearts, 14, "nothing happened")


func test_the_subtitle_box_fits_1080p() -> void:
	await open_map()
	await frames(5)
	var ui: CanvasLayer = map.get("ui")
	var label: Label = null
	for node: Node in ui.find_children("*", "Label", true, false):
		if (node as Label).text.begins_with("오~~~"):
			label = node as Label
	check(label != null, "the subtitle label holds her line")
	if label != null:
		check(label.get_theme_font_size("font_size") >= 40, "readable size")
		var box: Control = label.get_parent() as Control
		check(box.visible, "the box is up")
		check(box.position.y + box.size.y <= 1080.0, "inside the screen")
		check(box.position.y > 800.0, "at the bottom")
