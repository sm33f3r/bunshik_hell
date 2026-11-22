extends "res://tests/physics_base.gd"
## Task 3a, real Map 1 scene: the cutscene gate, the pick, a stab and its shadow, the walls,
## the gap, the stuck pick and the next table. Every wait is counted in physics frames.

const MAP_SCENE := "res://maps/ep01/map01_bunsikjip/map01.tscn"
const DirectorScript := preload("res://prologue/prologue_director.gd")

var map: Node3D
var dir: DirectorScript


## Opens Map 1 on a fresh game. skip_cutscene = pretend the cutscene was already seen.
func open_map(skip_cutscene: bool = true) -> void:
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
	check(player.global_position.y > y0 + 1.0, "the pick is rising with him on it")
	await tap_alternating(10)
	check_eq(dir.state, DirectorScript.State.PRE_STAB, "10 alternations freed him")
	check(await until(func() -> bool: return player.get("grounded"), 180), "he dropped onto the counter: " + describe())
	check(absf(player.global_position.y - (1.0 + 0.32)) < 0.1, "standing on the counter: " + describe())
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
	check(absf(player.global_position.x - shadow) < 0.8, "he is standing there (%.2f vs %.2f)" % [player.global_position.x, shadow])
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
	teleport(target + 4.0 if target < 8.0 else target - 4.0, 1.4)
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


# --- The counter, the walls, the gap --------------------------------------------------------------

func test_he_cannot_leave_her_counter_before_the_exit_opens() -> void:
	await open_map()
	await stand_on_counter()
	hold_stabs_back()
	teleport(13.0, 1.4)
	Input.action_press("move_right")
	var max_x: float = 0.0
	for i: int in 90:
		await tree.physics_frame
		max_x = maxf(max_x, player.global_position.x)
		if i % 25 == 0:
			Input.action_press("jump")
		elif i % 25 == 12:
			Input.action_release("jump")
	check(max_x < 14.0, "stopped by the right wall (max x %.2f)" % max_x)
	Input.action_release("move_right")
	teleport(1.0, 1.4)
	Input.action_press("move_left")
	var min_x: float = 99.0
	for i: int in 90:
		await tree.physics_frame
		min_x = minf(min_x, player.global_position.x)
		if i % 25 == 0:
			Input.action_press("jump")
		elif i % 25 == 12:
			Input.action_release("jump")
	check(min_x > -0.5, "stopped by the left wall (min x %.2f)" % min_x)
	check(player.global_position.y > 0.9, "never fell off: " + describe())


func test_the_gap_is_too_wide_to_cross_without_the_pick() -> void:
	await open_map()
	await stand_on_counter()
	hold_stabs_back()
	map.call("debug_drop_walls_only")
	await frames(3)
	var table_min: float = dir.data.next_table_min_x
	var reached: bool = false
	for start_x: float in [10.0, 11.5, 12.8, 13.5]:
		teleport(start_x, 1.34)
		await frames(10)
		Input.action_press("move_right")
		await frames(4)
		for i: int in 120:
			if i == 6 or i == 62:
				Input.action_press("jump")
			elif i == 40 or i == 90:
				Input.action_release("jump")
			await tree.physics_frame
			if player.global_position.x >= table_min and player.global_position.y > dir.data.next_table_top_y:
				reached = true
		Input.action_release("move_right")
		Input.action_release("jump")
	check(not reached, "no way across with a full-speed running jump from the counter")


# --- The exit -------------------------------------------------------------------------------------

func _open_the_exit() -> void:
	dir.debug_free()
	dir.debug_set_count(29)
	dir.set("_pre_left", 0.0)
	teleport(8.0, 1.4)
	await until(func() -> bool: return dir.state == DirectorScript.State.EXIT_OPEN, 400)
	await frames(10)


func test_the_30th_stab_sticks_the_pick_in_the_counter_and_drops_the_walls() -> void:
	await open_map()
	await _open_the_exit()
	check_eq(dir.state, DirectorScript.State.EXIT_OPEN, "exit open")
	check_eq(gs.hearts, 14, "the 30th is a miss")
	var stuck: StaticBody3D = room.get_node("StuckPick") as StaticBody3D
	check(stuck.visible, "the pick stands in the counter")
	check(absf(stuck.global_position.x - dir.data.final_x) < 0.01, "at the end nearest the next table")
	check(not (stuck.get_node("HeadShape") as CollisionShape3D).disabled, "and it is solid")
	for wall: Node in room.get_node("Walls").get_children():
		check((wall.get_node("CollisionShape3D") as CollisionShape3D).disabled, "wall dropped: " + String(wall.name))
	check(not map.get("actor").shadow_visible(), "no shadow left")


func test_he_can_stand_on_the_stuck_pick_and_jump_across_to_the_next_table() -> void:
	await open_map()
	await _open_the_exit()
	check_eq(dir.state, DirectorScript.State.EXIT_OPEN, "exit open")
	# Run at it from the counter and jump onto its flat head.
	teleport(9.0, 1.34)
	await frames(5)
	Input.action_press("move_right")
	var jumped: bool = false
	var jump_frame: int = 0
	for i: int in 120:
		await tree.physics_frame
		if not jumped and player.global_position.x >= 10.5:
			Input.action_press("jump")
			jumped = true
			jump_frame = i
		if jumped and i - jump_frame == 28: # past the apex: a full jump
			Input.action_release("jump")
		if jumped and player.get("grounded") and player.global_position.y > 2.0:
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	check(player.get("grounded") and absf(player.global_position.y - (dir.data.pick_top_y + 0.32)) < 0.1,
		"standing on the pick's head: " + describe())
	check(absf(player.global_position.x - dir.data.final_x) < 0.7, "on top of it, not beside it: " + describe())
	await frames(20)
	# And from there across.
	Input.action_press("move_right")
	var crossed: bool = false
	var jumped_again: bool = false
	for i: int in 150:
		await tree.physics_frame
		if not jumped_again and player.global_position.x >= 13.55:
			Input.action_press("jump")
			jumped_again = true
		if dir.state == DirectorScript.State.COMPLETE:
			crossed = true
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	check(crossed, "landed on the next table: " + describe())
	check(player.global_position.x >= dir.data.next_table_min_x, "x on the table: " + describe())
	check(gs.get("prologue_complete"), "prologue complete")
	check_eq(gs.get("checkpoint_id"), "map01_next_table", "respawn point set there")
	await frames(3)
	check(map.get("ui").dev_note_visible(), "the plain dev note is up")


# --- Debug ----------------------------------------------------------------------------------------

func test_debug_key_8_finishes_the_prologue() -> void:
	await open_map()
	await key_event(KEY_8)
	await frames(60)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "complete")
	check(absf(player.global_position.x - dir.data.next_table_spawn.x) < 1.0, "at the next table: " + describe())
	check(absf(player.global_position.y - (dir.data.next_table_top_y + 0.32)) < 0.15, "standing on it: " + describe())
	check(map.get("ui").dev_note_visible(), "dev note")
	check(not map.get("actor").shadow_visible(), "no stabbing any more")
	# Dying afterwards respawns him there, not at the pick.
	gs.call("take_damage", 14)
	await frames(100)
	check_eq(dir.state, DirectorScript.State.COMPLETE, "still complete")
	check(absf(player.global_position.x - dir.data.next_table_spawn.x) < 1.0, "respawned at the next table: " + describe())
	check_eq(gs.hearts, 14, "full hearts")


func test_the_debug_hud_shows_the_prologue_and_the_old_keys_still_work() -> void:
	await open_map()
	await frames(5)
	var text: String = (room.get_node("DebugHud/Text") as Label).text
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
