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
	check_eq(flow.enabled_sections, ["tutorial", "dining_room_start"] as Array[String], "the tutorial and what follows are live")
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

func test_a_run_through_every_beat_in_order() -> void:
	await open_tutorial()
	var seen: Array[String] = []
	var watch: Callable = func() -> void:
		var text: String = flow.ui.hint_text()
		if flow.ui.hint_visible() and (seen.is_empty() or seen[-1] != text):
			seen.append(text)
	# a) move and jump over a small gap (the hint is up from the start).
	watch.call()
	await put_on("prologue_exit_table", plat("prologue_exit_table").length() - 3.0)
	check(await cross_gap("prologue_exit_table", "tut_t1"), "a) he jumped the gap onto the first table: " + describe())
	# b) one 만두: stomp it (a landing works too, tested below).
	await frames(3)
	watch.call()
	var mandu: Node3D = enemies("b")[0]
	place(mandu, "tut_t1", plat("tut_t1").left + 6.0)
	teleport(mandu.global_position.x, mandu.global_position.y + 3.5)
	await frames(2)
	await tap("look_down")
	check(await until(func() -> bool: return not mandu.get("alive"), 60), "b) the stomp killed the 만두")
	await frames(30)
	# c) the first 단무지: roll arrives with the beat, and a bounce reaches the ledge.
	check(not gs.has_skill("roll"), "roll is not granted before beat c")
	await put_on("tut_t2", 1.0)
	await frames(3)
	watch.call()
	check(gs.has_skill("roll") and not gs.has_skill("slam"), "c) roll arrives when the beat begins, slam not yet")
	check_eq(gs.skill_sources.get("roll"), "tutorial", "from the tutorial")
	check(flow.ui.toast_visible() and "구르기" in flow.ui.toast_text(), "with its toast: " + flow.ui.toast_text())
	var wheel1: Node3D = enemies("c1")[0]
	var ledge1: LayoutGeometryScript.Placed = plat("tut_ledge1")
	place(wheel1, "tut_t2", ledge1.left - 3.0)
	teleport(wheel1.global_position.x - 0.4, wheel1.global_position.y + wheel1.get("diameter_m") + 2.0)
	await until(func() -> bool: return player.velocity.y > 9.0, 90)
	var launch: float = player.velocity.y
	var tuning: Resource = player.get("tuning")
	check(launch > tuning.bounce_velocity * 1.5, "the 단무지 threw him higher than a plain bounce (%.1f m/s)" % launch)
	Input.action_press("move_right")
	check(await until(func() -> bool: return on_top_of("tut_ledge1"), 150), "c) the bounce took him up onto the high ledge: " + describe())
	Input.action_release("move_right")
	check(wheel1.get("alive"), "the wheel is unharmed by being bounced on")
	# ... then down to the third table: the second 단무지, rolled over, becomes a platform.
	await put_on("tut_t3", 1.0)
	await frames(3)
	watch.call()
	check(" 구르기 " in " " + flow.ui.hint_text() or "구르기" in flow.ui.hint_text(), "the roll hint: " + flow.ui.hint_text())
	var wheel2: Node3D = enemies("c2")[0]
	var ledge2: LayoutGeometryScript.Placed = plat("tut_ledge2")
	place(wheel2, "tut_t3", plat("tut_t3").left + 4.0)
	teleport(plat("tut_t3").left + 1.2, plat("tut_t3").top + 0.4)
	await frames(10)
	Input.action_press("move_right")
	await tap("roll")
	Input.action_release("move_right")
	check(await until(func() -> bool: return wheel2.get("flat"), 60), "the roll knocked the 단무지 over")
	check(await until(func() -> bool: return wheel2.get("is_static"), 240), "and it settled as a static platform")
	check(not wheel2.get("alive"), "it no longer counts as an enemy")
	var wheel_right: float = wheel2.global_position.x + wheel2.get("diameter_m") * 0.5
	check(absf(wheel_right - ledge2.left) < 0.4, "against the ledge's wall (%.2f vs %.2f)" % [wheel_right, ledge2.left])
	# Standing on it, the ledge is within a jump.
	teleport(wheel2.global_position.x, plat("tut_t3").top + wheel2.get("flat_height_m") + 0.6)
	await frames(40) # fall onto it and settle
	check(absf(feet_y() - (plat("tut_t3").top + wheel2.get("flat_height_m"))) < 0.15, "he stands on the flat wheel: %s feet=%.2f expected=%.2f wheel=%s" % [describe(), feet_y(), plat("tut_t3").top + wheel2.get("flat_height_m"), wheel2.global_position])
	Input.action_press("move_right")
	Input.action_press("jump")
	var top_y: float = player.global_position.y
	for i: int in 30:
		await tree.physics_frame
		top_y = maxf(top_y, player.global_position.y)
	Input.action_release("jump")
	check(await until(func() -> bool: return on_top_of("tut_ledge2"), 120), "he climbed from the wheel onto the second ledge: " + describe())
	Input.action_release("move_right")
	# d) the cluster of three: slam arrives with the beat and kills them.
	await put_on("tut_t4", 0.8)
	await frames(3)
	watch.call()
	check(gs.has_skill("slam"), "d) slam arrives when the beat begins")
	check(flow.ui.toast_visible() and "내려찍기" in flow.ui.toast_text(), "with its toast: " + flow.ui.toast_text())
	var cluster: Array[Node3D] = enemies("d")
	check_eq(cluster.size(), 3, "three 만두")
	var middle: float = plat("tut_t4").left + 3.9
	for i: int in cluster.size():
		place(cluster[i], "tut_t4", middle + (float(i) - 1.0) * 0.9)
	teleport(middle, plat("tut_t4").top + 4.5)
	await frames(3)
	await tap("roll")
	check(await until(func() -> bool: return not cluster[0].get("alive") and not cluster[1].get("alive") and not cluster[2].get("alive"), 90),
		"the slam killed the whole cluster")
	await frames(20)
	# e) the exit gap to the dining room start counts as finishing.
	check(not flow.tutorial_done, "not finished before the last jump")
	await put_on("tut_t4", plat("tut_t4").length() - 1.8) # inside the exit hint's zone
	await frames(3)
	watch.call()
	check(await cross_gap("tut_t4", "dining_1"), "e) he jumped the exit gap onto the dining room's first table: " + describe())
	await frames(5)
	check_eq(gs.checkpoint_id, "map01_dining_start", "the dining room's checkpoint")
	check(flow.tutorial_done, "that counts as finishing the tutorial")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "roll and slam are his")
	# The hints came in beat order, each once.
	check(seen.size() >= 5, "five hints were shown: " + str(seen))
	var order: Array[String] = ["이동", "만두", "단무지", "구르기", "내려찍기", "건너편"]
	var last: int = -1
	for word: String in order:
		var index: int = -1
		for i: int in seen.size():
			if word in seen[i]:
				index = i
				break
		check(index > last, "hint '%s' comes after the one before it (%s)" % [word, str(seen)])
		last = maxi(index, last)


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


func test_the_dining_room_start_ends_in_a_marked_wall() -> void:
	await open_tutorial()
	var last: LayoutGeometryScript.Placed = plat("dining_3")
	var wall: Node3D = flow.builder.end_walls.get("dining_room_start")
	check(wall != null, "an end wall exists")
	check("Map 1 continues here" in (wall.get_node("Sign") as Label3D).text, "with a sign saying so")
	await put_on("dining_3", last.length() - 3.0)
	Input.action_press("move_right")
	await frames(90)
	Input.action_release("move_right")
	check(player.global_position.x < last.right, "he cannot go past it: " + describe())
	check(on_top_of("dining_3"), "still on the table")
