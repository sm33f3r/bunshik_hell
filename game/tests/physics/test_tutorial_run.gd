extends "res://tests/physics_base.gd"
## Task 3b-i, real Map 1 scene: the prompt after the prologue exit, the tutorial beats a to e played
## with real input (a run through every beat, and a skip run), the 단무지 bounce and knock-over
## platform, the slam on the 만두 cluster, checkpoints, death, and falling off a table.
## Every wait is counted in physics frames. The wheels and the 만두 are set to stand still
## (speed_scale 0) wherever a test needs them in one place.

const MAP_SCENE := "res://maps/ep01/map01_bunsikjip/map01.tscn"
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")

var map: Node3D
var flow: Node


# --- Helpers ----------------------------------------------------------------------------------------

## Opens Map 1 on a fresh game (cutscene seen) and finishes the prologue with debug key 8, which
## leaves the tutorial prompt open. The old plate 만두 are removed.
func open_prompt() -> void:
	gs = tree.root.get_node_or_null("GameState")
	if gs == null:
		failures.append("GameState autoload missing")
		return
	gs.call("reset")
	gs.set("prologue_intro_seen", true)
	room = (load(MAP_SCENE) as PackedScene).instantiate() as Node3D
	tree.root.add_child(room)
	map = room
	player = room.get_node("Player") as CharacterBody3D
	await frames(3)
	flow = map.get("flow")
	for mandu: Node3D in (map.call("live_mandu") as Array):
		mandu.call("debug_defeat")
	map.get("_mandu_respawn").set("count", 0)
	await key_event(KEY_8)
	await frames(20)


## ... and answers it with the cross (start the tutorial).
func open_tutorial() -> void:
	await open_prompt()
	await tap("ui_accept")
	await frames(6)


func plat(id: String) -> LayoutGeometryScript.Placed:
	return LayoutGeometryScript.find(flow.placed, id)


func put_on(id: String, along: float, lift: float = 0.4) -> void:
	var p: LayoutGeometryScript.Placed = plat(id)
	teleport(LayoutGeometryScript.x_on(p, along), p.top + lift)
	await until(func() -> bool: return player.get("grounded"), 90)


## The enemies of a beat group ("b", "c1", "c2", "d", "dining").
func enemies(group: String) -> Array[Node3D]:
	for section_id: String in ["tutorial", "dining_room_start"]:
		var found: Array[Node3D] = flow.builder.enemies_in_group(section_id, group)
		if not found.is_empty():
			return found
	return [] as Array[Node3D]


## Stand still at `x` on the table `id` (feet on it).
func place(enemy: Node3D, id: String, x: float) -> void:
	enemy.set("speed_scale", 0.0)
	enemy.global_position = Vector3(x, plat(id).top + 0.02, 0.0)
	enemy.set("velocity", Vector3.ZERO)


func feet_y() -> float:
	return player.global_position.y - player.get("body_half_height")


func on_top_of(id: String) -> bool:
	var p: LayoutGeometryScript.Placed = plat(id)
	return player.get("grounded") and player.global_position.x >= p.left and player.global_position.x <= p.right \
		and absf(feet_y() - p.top) < 0.15


## Runs right and jumps at the edge of `from_id` (like the prologue's own jump), until he stands
## on `to_id`. Returns whether he did.
func cross_gap(from_id: String, to_id: String) -> bool:
	var edge: float = plat(from_id).right
	Input.action_press("move_right")
	var jumped: bool = false
	var jump_frame: int = 0
	var landed: bool = false
	for i: int in 240:
		await tree.physics_frame
		if not jumped and player.global_position.x >= edge - 0.6:
			Input.action_press("jump")
			jumped = true
			jump_frame = i
		if jumped and i - jump_frame == 26:
			Input.action_release("jump")
		if on_top_of(to_id):
			landed = true
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	return landed


# --- The prompt -------------------------------------------------------------------------------------

func test_the_prologue_exit_opens_the_tutorial_prompt() -> void:
	await open_prompt()
	check_eq(flow.phase, MapFlowScript.Phase.PROMPT, "the prompt is open")
	check(tree.paused, "gameplay is closed behind it")
	check(flow.ui.prompt_visible(), "and shown")
	var text: String = flow.ui.prompt_text()
	check("튜토리얼 하기" in text and "건너뛰기" in text, "in Korean: " + text)
	check_eq(gs.checkpoint_id, "map01_tutorial_start", "the tutorial's checkpoint is set")
	check(gs.get("tutorial_prompt_shown"), "and it will not ask again")
	check(not gs.has_skill("roll") and not gs.has_skill("slam"), "roll and slam are still locked")
	var at: Vector3 = player.global_position
	await tap("jump")
	await tap("roll")
	await frames(10)
	check_eq(player.global_position, at, "pressing jump or roll does nothing while it is open")
	check_eq(flow.phase, MapFlowScript.Phase.PROMPT, "still open")


func test_the_prompt_shows_the_controller_buttons_when_the_controller_was_last_used() -> void:
	var press: InputEventJoypadButton = InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_X # any pad button counts as "the controller was used" (A would answer the prompt)
	press.pressed = true
	await open_prompt()
	Input.parse_input_event(press)
	await frames(3)
	check("✕ (A) = 튜토리얼 하기" in flow.ui.prompt_text(), "controller: " + flow.ui.prompt_text())
	check("○ (B) = 건너뛰기" in flow.ui.prompt_text(), "and the circle for skipping")
	await key_event(KEY_B)
	check(not ("✕" in flow.ui.prompt_text()), "back to the keyboard's names: " + flow.ui.prompt_text())


func test_the_cross_starts_the_tutorial() -> void:
	await open_tutorial()
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "the prompt is gone")
	check(not tree.paused, "the game runs")
	check(not flow.ui.prompt_visible(), "and it is hidden")
	check_eq(flow.enabled_sections, ["tutorial", "dining_room_start", "dining_room", "kitchen_front"] as Array[String], "the tutorial and what follows are live")
	check_eq(flow.builder.enemies_of("tutorial").size(), 6, "the tutorial's enemies are out")
	check_eq(flow.builder.enemies_of("dining_room_start").size(), 1, "and the second 단무지")
	check(flow.ui.hint_visible() and "이동" in flow.ui.hint_text(), "the first hint (move and jump): " + flow.ui.hint_text())
	check(not gs.has_skill("roll") and not gs.has_skill("slam"), "nothing is granted yet")
	check_eq(gs.checkpoint_id, "map01_tutorial_start", "checkpoint: the tutorial's start")
	check_eq(gs.hearts, 14, "full hearts")


func test_the_closing_press_does_not_jump_or_roll() -> void:
	await open_prompt()
	var y0: float = player.global_position.y
	Input.action_press("ui_accept")
	Input.action_press("jump") # Space is both
	await frames(6)
	Input.action_release("ui_accept")
	Input.action_release("jump")
	await frames(4)
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "it closed")
	check(player.global_position.y < y0 + 0.5, "and he did not jump out of the prompt: " + describe())


func test_the_circle_skips_with_a_fade_and_lands_him_in_the_dining_room_with_roll_and_slam() -> void:
	await open_prompt()
	var start_x: float = player.global_position.x
	var dining: LayoutGeometryScript.Placed = plat("dining_1")
	Input.action_press("ui_cancel")
	await frames(2)
	Input.action_release("ui_cancel")
	var jumped_at_alpha: float = -1.0
	var max_alpha: float = 0.0
	for i: int in 120:
		await tree.physics_frame
		max_alpha = maxf(max_alpha, flow.ui.fade_alpha())
		if jumped_at_alpha < 0.0 and absf(player.global_position.x - start_x) > 5.0:
			jumped_at_alpha = flow.ui.fade_alpha()
		if flow.phase == MapFlowScript.Phase.IDLE and i > 10:
			break
	check(jumped_at_alpha >= 0.99, "he moved only behind a black screen, no pop (alpha %.2f)" % jumped_at_alpha)
	check(max_alpha >= 0.99, "the screen went fully dark")
	check_eq(flow.ui.fade_alpha(), 0.0, "and it is clear again")
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "finished")
	check(not tree.paused, "the game runs")
	await frames(40)
	check(on_top_of("dining_1"), "standing on the dining room's first table: " + describe())
	check(absf(player.global_position.x - (dining.left + 2.0)) < 1.5, "at its checkpoint")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "roll and slam are his")
	check_eq(gs.skill_sources.get("roll"), "tutorial", "from the tutorial")
	check(flow.ui.toast_visible() and "새 기술" in flow.ui.toast_text(), "the new skill toast: " + flow.ui.toast_text())
	check_eq(gs.checkpoint_id, "map01_dining_start", "the checkpoint is the dining room's")
	check_eq(flow.builder.enemies_of("tutorial").size(), 0, "no tutorial enemies")
	check_eq(flow.builder.enemies_of("dining_room_start").size(), 1, "the dining room's 단무지 is there")
	check(not flow.ui.hint_visible(), "no tutorial hints")
	var camera: Camera3D = room.get_node("SideCamera") as Camera3D
	check(absf(camera.global_position.x - player.global_position.x) < 3.0, "the camera is with him")


func test_the_prompt_is_never_shown_twice_in_one_run_but_a_new_game_asks_again() -> void:
	await open_tutorial()
	map.call("_on_completed") # the prologue finishing again
	await frames(5)
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "no second prompt")
	check(not tree.paused, "no pause")
	gs.call("reset")
	check_eq(gs.get("tutorial_prompt_shown"), false, "a new game forgets it")
	map.call("_on_completed")
	await frames(5)
	check_eq(flow.phase, MapFlowScript.Phase.PROMPT, "and asks again")


func test_the_hint_names_the_buttons_of_the_device_in_use() -> void:
	var press: InputEventJoypadButton = InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	await open_prompt()
	Input.parse_input_event(press) # A is the cross: it answers the prompt (start the tutorial)
	await frames(8)
	var text: String = flow.ui.hint_text()
	check("✕ (A)" in text, "jump shows the controller's name: " + text)
	check("Left stick left" in text, "and the stick: " + text)
	check("Space" not in text, "not the keyboard's")


# --- Skills are gated until the tutorial grants them -------------------------------------------------

func test_roll_and_slam_do_nothing_before_the_tutorial_grants_them() -> void:
	await open_tutorial()
	await put_on("prologue_exit_table", 3.0)
	Input.action_press("move_right")
	await tap("roll")
	check(state() != "roll", "no roll yet: " + describe())
	Input.action_release("move_right")
	await frames(20)
	teleport(player.global_position.x, player.global_position.y + 4.0)
	await frames(3)
	await tap("roll")
	check(state() != "slam", "no slam in the air either: " + describe())


# --- Beats a to e, played start to finish -----------------------------------------------------------

## The real path: from the tutorial's start to the dining room's first table with real input only (no
## teleports, no direct calls). The bot is a plain player: it runs, jumps with the button held, stomps with
## the down press, bounces on the wheel, rolls into the second wheel, climbs, slams, and jumps the exit gap.
## Every enemy walks as it does in the game. It may die (a real player does); it then starts over from the
## checkpoint, up to RUN_ATTEMPTS times.
const RUN_ATTEMPTS: int = 5
const RUN_BEAT_FRAMES: int = 1500


func hold(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func release_all() -> void:
	for action: String in ["move_left", "move_right", "jump", "look_down", "roll"]:
		Input.action_release(action)


func dead() -> bool:
	return state() == "dead" or gs.hearts <= 0


## Runs toward x on the current platform until within `near`.
func run_to(x: float, near: float = 0.25, max_frames: int = 900) -> bool:
	for i: int in max_frames:
		if dead():
			release_all()
			return false
		var dx: float = x - player.global_position.x
		if absf(dx) <= near:
			release_all()
			return true
		hold("move_right", dx > 0.0)
		hold("move_left", dx < 0.0)
		await tree.physics_frame
	release_all()
	return false


## Runs right from where he is and jumps (button held 26 frames) at `edge_x`; true once he stands on `to_id`.
func jump_to(edge_x: float, to_id: String, max_frames: int = 300) -> bool:
	Input.action_press("move_right")
	var jumped: bool = false
	var jump_frame: int = 0
	for i: int in max_frames:
		await tree.physics_frame
		if dead():
			release_all()
			return false
		if not jumped and player.global_position.x >= edge_x and player.get("grounded"):
			Input.action_press("jump")
			jumped = true
			jump_frame = i
		if jumped and i - jump_frame == 26:
			Input.action_release("jump")
		if on_top_of(to_id):
			release_all()
			return true
	release_all()
	return false


func living(group: String) -> Node3D:
	var found: Array[Node3D] = enemies(group)
	return found[0] if not found.is_empty() and found[0].get("alive") else null


## Waits at wait_x on the table; when the enemy walks up he jumps on it with the down press (a stomp).
func stomp_walker(enemy: Node3D, wait_x: float) -> bool:
	if not await run_to(wait_x):
		return false
	for i: int in RUN_BEAT_FRAMES:
		if dead():
			release_all()
			return false
		if not enemy.get("alive"):
			release_all()
			return true
		var dx: float = enemy.global_position.x - player.global_position.x
		var grounded: bool = player.get("grounded")
		if grounded and absf(dx) < 2.6 and dx > 0.0:
			Input.action_press("jump")
			hold("move_right", dx > 1.2)
		elif not grounded:
			var above: bool = player.global_position.y - player.get("body_half_height") > enemy.global_position.y + enemy.get("body_height") + 0.2
			hold("look_down", above and absf(dx) < 0.9)
			hold("move_right", dx > 0.3)
			hold("move_left", dx < -0.3)
			if player.velocity.y < 0.0:
				Input.action_release("jump")
		else:
			release_all()
		await tree.physics_frame
	release_all()
	return false


## The beats, in order, from the tutorial start. Returns the name of the step that failed ("" = he made it).
func play_tutorial() -> String:
	# a) the first gap, onto the first table.
	var exit_table: LayoutGeometryScript.Placed = plat("prologue_exit_table")
	if not await jump_to(exit_table.right - 0.6, "tut_t1"):
		return "a: the first gap"
	# b) the 만두: wait for it, stomp it, go on.
	var t1: LayoutGeometryScript.Placed = plat("tut_t1")
	var mandu: Node3D = living("b")
	if mandu != null and not await stomp_walker(mandu, t1.left + 2.0):
		return "b: stomp the 만두"
	if not await jump_to(t1.right - 0.6, "tut_t2"):
		return "b: the gap to the second table"
	# c1) the first 단무지: wait at the ledge's wall, jump on it when it comes, drift onto the ledge.
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	var ledge1: LayoutGeometryScript.Placed = plat("tut_ledge1")
	if not await run_to(t2.right - 2.5):
		return "c1: walking to the ledge's wall"
	var wheel1: Node3D = living("c1")
	var up: bool = false
	for i: int in RUN_BEAT_FRAMES:
		if dead():
			release_all()
			return "c1: died"
		if on_top_of("tut_ledge1"):
			up = true
			break
		var dx: float = wheel1.global_position.x - player.global_position.x
		if player.get("grounded"):
			Input.action_release("move_right")
			# The wheel comes from the left: jump when it is close enough to be under him on the way down.
			if dx < 0.0 and dx > -1.6:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
		else:
			hold("move_right", player.velocity.y > 9.0 or player.global_position.y - player.get("body_half_height") > plat("tut_t2").top + 2.0)
			if player.velocity.y <= 0.0:
				Input.action_release("jump")
		await tree.physics_frame
	release_all()
	if not up:
		return "c1: the bounce onto the ledge: " + describe()
	# ... then off the ledge down to the third table.
	var t3: LayoutGeometryScript.Placed = plat("tut_t3")
	Input.action_press("move_right")
	var t3_ok: bool = await until(func() -> bool: return on_top_of("tut_t3"), 240)
	release_all()
	if not t3_ok:
		return "c2: down to the third table"
	# c2) the second 단무지: roll into it when it comes, then up onto the flat wheel and the ledge.
	var wheel2: Node3D = living("c2")
	if not await run_to(t3.left + 1.0, 0.4):
		return "c2: waiting place"
	var knocked: bool = false
	for i: int in RUN_BEAT_FRAMES:
		if dead():
			release_all()
			return "c2: died"
		if not is_instance_valid(wheel2) or wheel2.get("flat"):
			knocked = true
			break
		var dx: float = wheel2.global_position.x - player.global_position.x
		if player.get("grounded") and dx > 0.2 and dx < 2.0:
			Input.action_press("move_right")
			await tap("roll")
		await tree.physics_frame
		release_all()
	release_all()
	if not knocked:
		return "c2: knocking the 단무지 over"
	await until(func() -> bool: return not is_instance_valid(wheel2) or wheel2.get("is_static"), 400)
	if not is_instance_valid(wheel2):
		return "c2: the flat wheel vanished"
	# up onto the flat wheel, then the ledge: jumps toward the wall.
	var on_ledge: bool = false
	Input.action_press("move_right")
	for i: int in 900:
		await tree.physics_frame
		if dead():
			release_all()
			return "c2: died climbing"
		if on_top_of("tut_ledge2"):
			on_ledge = true
			break
		if player.get("grounded"):
			Input.action_press("jump")
		elif player.velocity.y <= 0.0:
			Input.action_release("jump")
	release_all()
	if not on_ledge:
		return "c2: up the flat 단무지 onto the second ledge: " + describe()
	# off the ledge onto the fourth table.
	Input.action_press("move_right")
	var t4_ok: bool = await until(func() -> bool: return on_top_of("tut_t4"), 240)
	release_all()
	if not t4_ok:
		return "d: down to the fourth table"
	# d) the cluster: jump toward it and slam in the air.
	var t4: LayoutGeometryScript.Placed = plat("tut_t4")
	var cluster: Array[Node3D] = enemies("d")
	var slammed: bool = false
	for i: int in RUN_BEAT_FRAMES:
		if dead():
			release_all()
			return "d: died"
		var nearest: float = INF
		for m: Node3D in cluster:
			if m.get("alive"):
				nearest = minf(nearest, m.global_position.x - player.global_position.x)
		if nearest == INF:
			slammed = true
			break
		if player.get("grounded"):
			Input.action_press("move_right")
			if nearest < 3.3:
				Input.action_press("jump")
		else:
			if player.velocity.y <= 0.0:
				Input.action_release("jump")
				if player.global_position.y - player.get("body_half_height") > t4.top + 1.2 and nearest < 2.6:
					await tap("roll")
		await tree.physics_frame
	release_all()
	if not slammed:
		return "d: slamming the cluster"
	await until(func() -> bool: return player.get("grounded"), 120)
	# e) the exit gap to the dining room.
	if not on_top_of("tut_t4"):
		return "e: not on the fourth table: " + describe()
	if not await run_to(t4.right - 3.5, 0.4):
		return "e: run-up"
	if not await jump_to(t4.right - 0.6, "dining_1"):
		return "e: the exit gap: " + describe()
	return ""


func test_a_real_run_from_the_tutorial_start_to_the_dining_room() -> void:
	await open_tutorial()
	var last: String = ""
	for attempt: int in RUN_ATTEMPTS:
		last = await play_tutorial()
		if last == "":
			break
		print("   attempt %d failed at %s" % [attempt + 1, last])
		release_all()
		if dead():
			await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400)
		else:
			# walked off or stuck: the way a player would, by falling or dying back to the checkpoint
			gs.call("take_damage", 14)
			await until(func() -> bool: return state() == "dead", 60)
			await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400)
		await frames(30)
	check_eq(last, "", "he walked it: " + last + " " + describe())
	await frames(60)
	check(on_top_of("dining_1"), "standing on the dining room's first table: " + describe())
	check_eq(gs.checkpoint_id, "map01_dining_start", "the dining room's checkpoint")
	check(flow.tutorial_done, "the tutorial counts as finished")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "roll and slam are his")


func test_a_landing_on_a_만두_works_too() -> void:
	await open_tutorial()
	var mandu: Node3D = enemies("b")[0]
	place(mandu, "tut_t1", plat("tut_t1").left + 6.0)
	teleport(mandu.global_position.x, mandu.global_position.y + 3.0)
	check(await until(func() -> bool: return not mandu.get("alive"), 90), "falling on it is enough: " + describe())
	check_eq(gs.hearts, 14, "and it did not hurt him")


# --- The 단무지 -------------------------------------------------------------------------------------

func test_the_first_wheel_is_out_of_reach_without_the_bounce() -> void:
	await open_tutorial()
	var ledge1: LayoutGeometryScript.Placed = plat("tut_ledge1")
	var wheel1: Node3D = enemies("c1")[0]
	place(wheel1, "tut_t2", plat("tut_t2").left + 1.0) # far away from the wall
	await put_on("tut_t2", plat("tut_t2").length() - 1.5)
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(60)
	Input.action_release("jump")
	await frames(40)
	Input.action_release("move_right")
	check(not on_top_of("tut_ledge1"), "a plain jump cannot get up (the ledge is %.2f m high): %s" % [ledge1.rise_m, describe()])


func test_the_second_wheel_is_out_of_reach_without_knocking_it_over() -> void:
	await open_tutorial()
	var wheel2: Node3D = enemies("c2")[0]
	place(wheel2, "tut_t3", plat("tut_t3").left + 1.0)
	await put_on("tut_t3", plat("tut_t3").length() - 1.5)
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(60)
	Input.action_release("jump")
	await frames(40)
	Input.action_release("move_right")
	check(not on_top_of("tut_ledge2"), "a plain jump cannot get up: " + describe())


func test_a_wheel_hurts_from_the_side_and_the_roll_knocks_it_over_from_the_left() -> void:
	await open_tutorial()
	var wheel: Node3D = enemies("c1")[0]
	place(wheel, "tut_t2", plat("tut_t2").left + 5.0)
	await put_on("tut_t2", 2.5)
	Input.action_press("move_right")
	await until(func() -> bool: return gs.hearts < 14, 120)
	Input.action_release("move_right")
	check_eq(gs.hearts, 12, "touching it from the side costs a heart")


func test_a_knocked_over_wheel_stays_until_the_section_resets() -> void:
	await open_tutorial()
	gs.call("unlock_skill", "roll", "tutorial")
	var wheel2: Node3D = enemies("c2")[0]
	place(wheel2, "tut_t3", plat("tut_t3").left + 4.0)
	await put_on("tut_t3", 1.2)
	Input.action_press("move_right")
	await tap("roll")
	Input.action_release("move_right")
	check(await until(func() -> bool: return wheel2.get("is_static"), 240), "knocked over and settled")
	var at: Vector3 = wheel2.global_position
	await frames(120)
	check_eq(wheel2.global_position, at, "it has not moved")
	check(wheel2.get("flat") and is_instance_valid(wheel2), "still a platform a couple of seconds later")
	gs.call("take_damage", 14) # dying starts the section over
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 240), "he came back")
	await frames(10)
	var fresh: Node3D = enemies("c2")[0]
	check(not is_instance_valid(wheel2) or wheel2 != fresh, "a new wheel stands there")
	check(fresh.get("alive") and not fresh.get("flat"), "rolling again")


func test_a_slam_hurts_a_wheel_and_a_second_one_breaks_it_into_halves_and_a_puddle() -> void:
	await open_tutorial()
	gs.call("unlock_skill", "slam", "tutorial")
	var wheel: Node3D = enemies("c1")[0]
	place(wheel, "tut_t2", plat("tut_t2").left + 4.0)
	for i: int in 2:
		teleport(wheel.global_position.x + 1.2, plat("tut_t2").top + 4.0)
		await frames(3)
		await tap("roll")
		await until(func() -> bool: return player.get("grounded"), 90)
		await frames(40)
	check(not wheel.get("alive"), "two slams broke it")
	var decor: Array[Node] = tree.get_nodes_in_group("section_decor")
	check(decor.size() >= 3, "two halves and a puddle were left (%d)" % decor.size())


# --- Death, falling, checkpoints ----------------------------------------------------------------------

func test_dying_in_the_tutorial_respawns_at_its_start_with_full_hearts_and_the_section_reset() -> void:
	await open_tutorial()
	var mandu: Node3D = enemies("b")[0]
	mandu.call("debug_defeat")
	gs.call("add_sodium", 3) # picked up after the checkpoint: gone again after dying
	await put_on("tut_t2", 3.0)
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 30), "he died")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 240), "and came back with full hearts")
	await frames(10)
	var start: Vector3 = gs.checkpoint_position
	check_eq(gs.checkpoint_id, "map01_tutorial_start", "at the tutorial's checkpoint")
	check(absf(player.global_position.x - start.x) < 1.0, "on its table: " + describe())
	check_eq(gs.sodium, 0, "with the 나트륨 he had at the checkpoint")
	var again: Node3D = enemies("b")[0]
	check(again.get("alive"), "the 만두 is back (the section started over)")
	check(again != mandu, "a new one")


func test_hints_show_once_per_life_and_again_after_a_death() -> void:
	await open_tutorial()
	flow.ui.clear_hint()
	await put_on("tut_t1", 1.0)
	await frames(3)
	check(flow.ui.hint_visible() and "만두" in flow.ui.hint_text(), "the 만두 hint shows: " + flow.ui.hint_text())
	flow.ui.clear_hint()
	await put_on("tut_t1", 8.0)
	await put_on("tut_t1", 1.0)
	await frames(3)
	check(not flow.ui.hint_visible(), "not a second time in the same life")
	gs.call("take_damage", 14)
	await until(func() -> bool: return state() == "dead", 30)
	await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 240)
	flow.ui.clear_hint()
	await put_on("tut_t1", 1.0)
	await frames(3)
	check(flow.ui.hint_visible() and "만두" in flow.ui.hint_text(), "after dying it may show again")


func test_dying_after_the_dining_room_checkpoint_respawns_there() -> void:
	await open_tutorial()
	await put_on("dining_1", 6.0)
	await frames(5)
	check_eq(gs.checkpoint_id, "map01_dining_start", "the dining room's checkpoint is reached by standing on its table")
	check(flow.tutorial_done and gs.has_skill("roll") and gs.has_skill("slam"), "reaching it finishes the tutorial")
	var kept_sauce: int = gs.sauce
	gs.call("spend_sauce", 2)
	gs.call("add_sodium", 2)
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 30), "he died")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 240), "and came back")
	await frames(10)
	var dining: LayoutGeometryScript.Placed = plat("dining_1")
	check(absf(player.global_position.x - (dining.left + 2.0)) < 1.0 and on_top_of("dining_1"), "at the dining room start, not the tutorial's: " + describe())
	check_eq(gs.sauce, kept_sauce, "with the sauce he had when he got there")
	check_eq(gs.sodium, 0, "and the 나트륨")


func test_falling_off_a_table_puts_him_back_at_the_checkpoint_without_damage() -> void:
	await open_tutorial()
	var wheel: Node3D = enemies("c1")[0]
	await put_on("tut_t1", plat("tut_t1").length() - 1.0)
	var t1: LayoutGeometryScript.Placed = plat("tut_t1")
	teleport(t1.right + 1.0, t1.top - 1.0) # into the gap
	check(await until(func() -> bool: return player.global_position.y > t1.top - 1.5 and player.global_position.x < t1.left, 240),
		"he is put back at the tutorial's checkpoint: " + describe())
	await frames(3)
	check_eq(gs.hearts, 14, "no damage for falling")
	check_eq(gs.checkpoint_id, "map01_tutorial_start", "same checkpoint")
	check(state() != "dead", "alive")
	check(enemies("c1")[0] != wheel, "and the section started over")


func test_the_dining_room_start_goes_on_and_the_kitchen_front_ends_in_a_marked_wall() -> void:
	await open_tutorial()
	check(flow.builder.end_walls.get("dining_room_start") == null, "no wall at the dining room start any more")
	check(flow.builder.end_walls.get("dining_room") == null, "nor at the dining room's end: the kitchen front goes on (Task 3c-i-a)")
	var wall: Node3D = flow.builder.end_walls.get("kitchen_front")
	check(wall != null, "the kitchen front ends in a wall")
	check("Map 1 continues here" in (wall.get_node("Sign") as Label3D).text, "with a sign saying so")
	var lane: LayoutGeometryScript.Placed = plat("kitchen_floor")
	await put_on("kitchen_floor", lane.length() - 3.0)
	Input.action_press("move_right")
	await frames(90)
	Input.action_release("move_right")
	check(player.global_position.x < lane.right + 0.01, "he cannot go past it: " + describe())


# --- The end of the tutorial ---------------------------------------------------------------------------

func test_reaching_the_dining_room_fades_out_and_in_and_leaves_the_tutorial_behind() -> void:
	await open_tutorial()
	check(flow.builder.enemies_of("tutorial").size() > 0, "the tutorial's enemies are out")
	await put_on("tut_t4", plat("tut_t4").length() - 1.0)
	await frames(3)
	check(flow.ui.hint_visible(), "the exit hint is up")
	# He steps (is put) on the first dining table: that is the exit.
	var dining: LayoutGeometryScript.Placed = plat("dining_1")
	teleport(dining.left + 5.0, dining.top + 0.4)
	var max_alpha: float = 0.0
	var moved_at_alpha: float = -1.0
	for i: int in 120:
		await tree.physics_frame
		max_alpha = maxf(max_alpha, flow.ui.fade_alpha())
		if moved_at_alpha < 0.0 and absf(player.global_position.x - (dining.left + 5.0)) > 1.0:
			moved_at_alpha = flow.ui.fade_alpha()
		if flow.phase == MapFlowScript.Phase.IDLE and i > 10:
			break
	check(max_alpha >= 0.99, "the screen went fully dark")
	check(moved_at_alpha >= 0.99, "he was moved to the checkpoint only behind it (alpha %.2f)" % moved_at_alpha)
	check_eq(flow.ui.fade_alpha(), 0.0, "and it is clear again")
	await frames(30)
	check(on_top_of("dining_1") and absf(player.global_position.x - (dining.left + 2.0)) < 1.5, "at the dining room's checkpoint: " + describe())
	check_eq(gs.checkpoint_id, "map01_dining_start", "that is the checkpoint")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "roll and slam are his")
	check(flow.tutorial_done, "the tutorial is done")
	check_eq(flow.builder.enemies_of("tutorial").size(), 0, "its enemies are gone")
	check(not flow.ui.hint_visible(), "and its hint")
	check(not flow.enabled_sections.has("tutorial"), "the section is off")
	check(flow.enabled_sections.has("dining_room_start"), "the dining room's is on")
	check(not tree.paused, "the game runs")


func test_a_player_who_finished_the_tutorial_cannot_be_sent_back_into_it() -> void:
	await open_tutorial()
	var dining: LayoutGeometryScript.Placed = plat("dining_1")
	teleport(dining.left + 2.0, dining.top + 0.4)
	await until(func() -> bool: return flow.tutorial_done and flow.phase == MapFlowScript.Phase.IDLE, 120)
	await frames(30)
	map.call("_on_completed") # the prologue reporting complete again must not undo it
	await frames(10)
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "no prompt")
	check_eq(gs.checkpoint_id, "map01_dining_start", "the checkpoint stays the dining room's")
	check(not flow.enabled_sections.has("tutorial"), "the tutorial stays off")
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 30), "he died")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 240), "and came back")
	await frames(10)
	check(on_top_of("dining_1"), "at the dining room, not the tutorial: " + describe())
	check_eq(flow.builder.enemies_of("tutorial").size(), 0, "no tutorial enemies came back")
	# Walking back across the gap (if he can) and falling does not change it either.
	teleport(plat("tut_t4").right - 1.0, plat("tut_t4").top + 0.4)
	await frames(30)
	teleport(plat("tut_t1").right + 1.0, plat("tut_t1").top - 1.0) # into a gap of the tutorial
	await frames(120)
	check_eq(gs.checkpoint_id, "map01_dining_start", "a fall in the tutorial's tables still returns to the dining room's checkpoint")
	check(player.global_position.x > dining.left - 1.0, "he is back at the dining room: " + describe())


func test_dying_mid_tutorial_respawns_and_the_end_is_still_reachable() -> void:
	await open_tutorial()
	check(await jump_to(plat("prologue_exit_table").right - 0.6, "tut_t1"), "a) onto the first table")
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 30), "he died on the first table")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400), "and came back")
	await frames(30)
	check_eq(gs.checkpoint_id, "map01_tutorial_start", "at the tutorial's start")
	check(on_top_of("prologue_exit_table"), "on its table: " + describe())
	var last: String = ""
	for attempt: int in RUN_ATTEMPTS:
		last = await play_tutorial()
		if last == "":
			break
		release_all()
		gs.call("take_damage", 14)
		await until(func() -> bool: return state() == "dead", 60)
		await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400)
		await frames(30)
	check_eq(last, "", "after the death he still walked to the end: " + last)
	await frames(60)
	check(flow.tutorial_done and on_top_of("dining_1"), "and reached the dining room: " + describe())


func test_letting_go_of_jump_does_not_cut_a_bounce() -> void:
	await open_tutorial()
	var wheel: Node3D = enemies("c1")[0]
	place(wheel, "tut_t2", plat("tut_t2").left + 4.0)
	await put_on("tut_t2", 1.0)
	teleport(wheel.global_position.x, wheel.global_position.y + 3.0)
	Input.action_press("jump") # held through the fall, as a player does
	var peak: float = 0.0
	for i: int in 120:
		await tree.physics_frame
		if player.velocity.y > 0.0 and i > 5:
			Input.action_release("jump") # let go right after the bounce
		peak = maxf(peak, player.velocity.y)
	Input.action_release("jump")
	var tuning: Resource = player.get("tuning")
	check(peak > tuning.bounce_velocity * 1.5, "the bounce kept its full speed (%.1f m/s) after the button was released" % peak)
