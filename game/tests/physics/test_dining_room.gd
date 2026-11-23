extends "res://tests/physics_base.gd"
## Task 3b-ii, real Map 1 scene: the dining room played with real input. A scripted run along the
## tables to the end wall (over the required windowsill), a run along the floor lane, falling onto the
## floor with no damage and climbing back to a table, the napkin-box to windowsill hop, the 김밥 train
## (landing spills, roll breaks the line, slam kills), the gum (stuck, then free by wiggling or by
## enemy hits), the chopsticks (grab and release) and the giant foot (telegraph, smoosh), and wheel 2
## coming back to its spot. Every wait is counted in physics frames.

const MAP_SCENE := "res://maps/ep01/map01_bunsikjip/map01.tscn"
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")

var map: Node3D
var flow: Node


# --- Helpers ----------------------------------------------------------------------------------------

## Map 1 with the tutorial skipped: he stands on the dining room's first table with roll and slam.
func open_dining() -> void:
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
	Input.action_press("ui_cancel")
	await frames(2)
	Input.action_release("ui_cancel")
	await until(func() -> bool: return flow.phase == MapFlowScript.Phase.IDLE and on_top_of("dining_1"), 240)
	await frames(10)


func plat(id: String) -> LayoutGeometryScript.Placed:
	return LayoutGeometryScript.find(flow.placed, id)


func put_on(id: String, along: float, lift: float = 0.4) -> void:
	var p: LayoutGeometryScript.Placed = plat(id)
	teleport(LayoutGeometryScript.x_on(p, along), p.top + lift)
	await until(func() -> bool: return player.get("grounded"), 90)


## The napkin box standing on a table, if any.
func box_on(table: LayoutGeometryScript.Placed) -> LayoutGeometryScript.Placed:
	for p: LayoutGeometryScript.Placed in flow.placed:
		if p.def.kind == "prop" and p.prev == table:
			return p
	return null


func feet_y() -> float:
	return player.global_position.y - player.get("body_half_height")


func on_top_of(id: String) -> bool:
	var p: LayoutGeometryScript.Placed = plat(id)
	return player.get("grounded") and player.global_position.x >= p.left and player.global_position.x <= p.right \
		and absf(feet_y() - p.top) < 0.15


## Takes every enemy out of the way (defeated, no fuss) and, when asked, switches the hazards off.
func clear_enemies() -> void:
	for node: Node in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node.get("alive"):
			node.call("debug_defeat")


func hazards_off(kinds: Array[String]) -> void:
	for node: Node in tree.get_nodes_in_group("hazards"):
		var file: String = (node.get_script() as Script).resource_path.get_file()
		if kinds.has(file) or file == "falling_zone.gd": # the falling items only ever have their own tests
			node.call("set_enabled", false)


func hazards_of(file: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node: Node in tree.get_nodes_in_group("hazards"):
		if (node.get_script() as Script).resource_path.get_file() == file:
			out.append(node as Node3D)
	return out


## Runs right and jumps at `edge_x`, until he stands on `to_id`. Returns whether he did.
func hop_to(edge_x: float, to_id: String, max_frames: int = 240) -> bool:
	Input.action_press("move_right")
	var jumped: bool = false
	var jump_frame: int = 0
	var landed: bool = false
	for i: int in max_frames:
		await tree.physics_frame
		if not jumped and player.global_position.x >= edge_x:
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


## Walks right along the platform he stands on until x >= `x` (no jumping).
func walk_to(x: float, max_frames: int = 600) -> void:
	Input.action_press("move_right")
	await until(func() -> bool: return player.global_position.x >= x, max_frames)
	Input.action_release("move_right")
	await frames(6)


func wiggle(count: int) -> void:
	for i: int in count:
		var action: String = "move_right" if i % 2 == 0 else "move_left"
		Input.action_press(action)
		await frames(3)
		Input.action_release(action)
		await frames(2)


# --- The tables -------------------------------------------------------------------------------------

func test_a_scripted_run_along_the_tables_reaches_the_end_wall_over_the_required_sill() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	var tables: Array[LayoutGeometryScript.Placed] = []
	for p: LayoutGeometryScript.Placed in flow.placed:
		if p.section_id == "dining_room" and p.def.kind == "table":
			tables.append(p)
	check(tables.size() >= 12, "a long run of tables")
	await put_on("r_t1", 2.0)
	var required: LayoutGeometryScript.Placed = null
	for p: LayoutGeometryScript.Placed in flow.placed:
		if p.def.kind == "sill" and p.def.main_path:
			required = p
	var reached: int = 0
	for i: int in tables.size():
		var table: LayoutGeometryScript.Placed = tables[i]
		if not on_top_of(table.def.id):
			check(false, "%s: he is not on it: %s" % [table.def.id, describe()])
			break
		reached += 1
		if i == tables.size() - 1:
			break
		var next_table: LayoutGeometryScript.Placed = tables[i + 1]
		var box: LayoutGeometryScript.Placed = box_on(table)
		if box != null:
			# A napkin box stands at the end of the table: he goes over it (and over the required sill).
			var up: bool = await hop_to(box.left - 0.6, box.def.id)
			check(up, "%s: onto the napkin box: %s" % [table.def.id, describe()])
			if not up:
				break
			if required != null and required.prev == box:
				check(await hop_to(box.right - 0.3, required.def.id), "the sill from the box: %s" % describe())
				check(await hop_to(required.right - 0.3, next_table.def.id), "%s: down from the sill: %s" % [next_table.def.id, describe()])
			else:
				check(await hop_to(box.right - 0.3, next_table.def.id), "%s: off the box: %s" % [next_table.def.id, describe()])
		else:
			var ok: bool = await hop_to(table.right - 0.6, next_table.def.id)
			check(ok, "%s -> %s: %s" % [table.def.id, next_table.def.id, describe()])
			if not ok:
				break
	check_eq(reached, tables.size(), "he stood on every table")
	if reached == tables.size():
		var last: LayoutGeometryScript.Placed = tables[tables.size() - 1]
		await walk_to(last.right + 2.0, 300)
		check(player.global_position.x < last.right + 0.01, "the end wall stops him: " + describe())
		check(on_top_of(last.def.id), "on the last table")
		check_eq(gs.hearts, 14, "and he took no damage on the way")
	check_eq(gs.checkpoint_id, "map01_dining_start", "walking past the 찜기 does not use it: the respawn point is still the start")
	check(not gs.is_jjigi_used("map01_dining_mid"), "it is still unused")


func test_the_napkin_box_hop_reaches_an_optional_sill() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	var sill: LayoutGeometryScript.Placed = plat("sill_a")
	var box: LayoutGeometryScript.Placed = sill.prev
	var table: LayoutGeometryScript.Placed = box.prev
	await put_on(table.def.id, maxf(0.5, box.left - table.left - 4.0))
	check(on_top_of(table.def.id), "on the table with the box")
	# From the table alone the sill is too high: a jump falls short.
	Input.action_press("move_right")
	await until(func() -> bool: return player.global_position.x >= box.left - 3.0, 200)
	Input.action_release("move_right")
	await frames(4)
	check(await hop_to(box.left - 0.6, box.def.id), "onto the napkin box: " + describe())
	var toward: float = box.right - 0.3 if sill.center_x() > box.center_x() else box.left + 0.3
	if sill.center_x() > box.center_x():
		check(await hop_to(toward, sill.def.id), "and from the box onto the windowsill: " + describe())
	else:
		Input.action_press("move_left")
		await until(func() -> bool: return player.global_position.x <= toward, 120)
		Input.action_press("jump")
		await frames(26)
		Input.action_release("jump")
		await until(func() -> bool: return on_top_of(sill.def.id), 120)
		Input.action_release("move_left")
		check(on_top_of(sill.def.id), "and from the box onto the windowsill: " + describe())


func test_a_jump_from_the_table_cannot_reach_the_sill_without_the_box() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	var sill: LayoutGeometryScript.Placed = plat("sill_a")
	var table: LayoutGeometryScript.Placed = sill.prev.prev
	var from_x: float = sill.left - 1.0
	await put_on(table.def.id, clampf(from_x - table.left, 0.5, table.length() - 0.5))
	var top: float = player.global_position.y
	Input.action_press("jump")
	await frames(30)
	Input.action_release("jump")
	check(player.global_position.y - top < plat("sill_a").top - table.top, "a full jump does not get high enough")


# --- The floor lane ---------------------------------------------------------------------------------

func lane() -> LayoutGeometryScript.Placed:
	return plat("dining_floor")


func on_floor() -> bool:
	return player.get("grounded") and absf(feet_y() - lane().top) < 0.15


func test_falling_off_a_table_lands_on_the_floor_with_no_damage() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	var t: LayoutGeometryScript.Placed = plat("r_t2")
	await put_on("r_t2", t.length() - 0.7)
	teleport(t.right + 1.0, t.top - 0.5) # into the gap
	check(await until(func() -> bool: return on_floor(), 240), "he lands on the floor lane: " + describe())
	await frames(5)
	check_eq(gs.hearts, 14, "no damage for the fall")
	check_eq(gs.checkpoint_id, "map01_dining_start", "no checkpoint was taken")
	check(state() != "dead" and player.global_position.y < t.top - 8.0, "and he was not put back on a table")


func test_a_floor_lane_run_with_the_foot_and_chopsticks_disabled() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	teleport(lane().left + 2.0, lane().top + 0.4)
	await until(func() -> bool: return on_floor(), 90)
	var from_x: float = player.global_position.x
	Input.action_press("move_right")
	var done: bool = await until(func() -> bool: return player.global_position.x >= lane().right - 3.0, 3000)
	Input.action_release("move_right")
	check(done, "he ran the length of the lane: " + describe())
	check(on_floor(), "still on the floor, never caught and put back: " + describe())
	check(player.global_position.x - from_x > 250.0, "%.0f m" % (player.global_position.x - from_x))
	check_eq(gs.hearts, 14, "unharmed")


func test_from_the_floor_he_can_climb_back_to_a_table_by_the_chair() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	var steps: Array[LayoutGeometryScript.Placed] = []
	for j: int in range(1, 10):
		steps.append(plat("chair_r_t5_%d" % j))
	var bottom: LayoutGeometryScript.Placed = steps[8]
	teleport(bottom.right + 2.5, lane().top + 0.4)
	await until(func() -> bool: return on_floor(), 90)
	var ahead: Array[LayoutGeometryScript.Placed] = steps.duplicate()
	ahead.append(plat("r_t5"))
	var jump_left: int = 0
	for i: int in 1200:
		await tree.physics_frame
		if on_top_of("r_t5"):
			break
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release("jump")
		if jump_left > 0 or not player.get("grounded"):
			continue
		# like a player: find the next step up, back off if too close to its edge, then run and jump
		var next_step: LayoutGeometryScript.Placed = null
		for s: LayoutGeometryScript.Placed in ahead:
			var rise: float = s.top - feet_y()
			if rise > 0.3 and rise < 2.0 and s.right < player.global_position.x:
				if next_step == null or s.right > next_step.right:
					next_step = s
		if next_step == null:
			Input.action_press("move_left")
			continue
		var d: float = player.global_position.x - next_step.right
		if d < 1.2:
			Input.action_release("move_left")
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
			Input.action_press("move_left")
			if d < 1.7:
				Input.action_press("jump")
				jump_left = 26
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	check(on_top_of("r_t5"), "he hopped up the chair and onto the table: " + describe())


# --- The 김밥 train ---------------------------------------------------------------------------------

func slices() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node: Node in tree.get_nodes_in_group("enemies"):
		if (node.get_script() as Script).resource_path.get_file() == "gimbap_slice.gd":
			out.append(node as Node3D)
	return out


## Everything but one train is taken away, hazards are off, and its slices stand still.
func isolate_train() -> Node3D:
	var all: Array[Node3D] = slices()
	var train: Node3D = all[0].get("train")
	for node: Node in tree.get_nodes_in_group("enemies"):
		var keep: bool = node in all and node.get("train") == train
		if not keep and node.get("alive"):
			node.call("debug_defeat")
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	for s: Node3D in train.get("slices"):
		s.set("speed_scale", 0.0)
	return train


func test_landing_on_a_gimbap_slice_spills_and_the_patch_makes_him_slide() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	var lead: Node3D = (train.get("slices") as Array)[1]
	var before: int = tree.get_nodes_in_group("slippery_patches").size()
	teleport(lead.global_position.x, lead.global_position.y + 3.5)
	var spilled: bool = await until(func() -> bool: return tree.get_nodes_in_group("slippery_patches").size() > before, 120)
	check(spilled, "the landing spilled something: " + describe())
	check(lead.get("alive"), "the slice is not killed by it")
	if spilled:
		var patches: Array[Node] = tree.get_nodes_in_group("slippery_patches")
		var patch: Node3D = patches[patches.size() - 1] as Node3D
		teleport(patch.global_position.x - 0.5, patch.global_position.y + 0.5)
		await frames(3)
		check(await until(func() -> bool: return player.get("slip_left") > 0.0, 60), "standing in the patch he slips: " + describe())


func test_a_roll_into_the_train_breaks_the_line() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	var tail: Node3D = (train.get("slices") as Array).back()
	teleport(tail.global_position.x - 1.3, tail.global_position.y + 0.3)
	await until(func() -> bool: return player.get("grounded"), 60)
	Input.action_press("move_right")
	await frames(2)
	Input.action_release("move_right")
	await tap("roll")
	check(await until(func() -> bool: return train.get("broken"), 90), "the roll broke the line: " + describe())
	for s: Node3D in train.get("slices"):
		check(s.get("alive"), "%s is alive: only the line broke" % s.name)


func test_a_slam_kills_a_slice() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	var victim: Node3D = (train.get("slices") as Array)[3]
	teleport(victim.global_position.x, victim.global_position.y + 4.0)
	await frames(8)
	await tap("roll") # in the air: slam
	check(await until(func() -> bool: return not victim.get("alive"), 120), "the slam killed it: " + describe())


# --- The gum ----------------------------------------------------------------------------------------

func gum() -> Node3D:
	return hazards_of("gum_patch.gd")[0]


func stand_in_gum() -> void:
	var g: Node3D = gum()
	teleport(g.global_position.x, lane().top + 0.4)
	await until(func() -> bool: return player.call("is_stuck"), 60)


func test_gum_sticks_him_and_a_wiggle_frees_him() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd"])
	await stand_in_gum()
	check(player.call("is_stuck"), "stuck: " + describe())
	check_eq(gs.hearts, 14, "touching is not damage")
	var x: float = player.global_position.x
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(absf(player.global_position.x - x) < 0.2, "no walking")
	await tap("jump")
	await frames(10)
	check(player.get("grounded"), "no jumping: " + describe())
	await wiggle(14)
	check(await until(func() -> bool: return not player.call("is_stuck"), 60), "a wiggle frees him: " + describe())
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	check(player.global_position.x > x + 1.0, "he walks on: " + describe())


func test_gum_is_shaken_off_by_three_hits_from_enemies() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd"])
	await stand_in_gum()
	check(player.call("is_stuck"), "stuck")
	for hit: int in 3:
		player.set("_invuln_timer", 0.0)
		player.call("hurt", 1, 0.0)
		await frames(3)
		check_eq(player.call("is_stuck"), hit < 2, "after %d hits" % (hit + 1))
	check(gs.hearts > 0, "alive")


func test_gum_lets_go_by_itself_after_ten_seconds() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd"])
	await stand_in_gum()
	await frames(9 * 60)
	check(player.call("is_stuck"), "still stuck after 9 s")
	await frames(2 * 60)
	check(not player.call("is_stuck"), "free after about 10 s: " + describe())


func test_jumping_over_the_gum_avoids_it() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd"])
	var g: Node3D = gum()
	var half: float = float(g.get("width_m")) * 0.5
	teleport(g.global_position.x - half - 3.0, lane().top + 0.4)
	await until(func() -> bool: return on_floor(), 60)
	Input.action_press("move_right")
	var jumped: bool = false
	var jump_frame: int = 0
	for i: int in 240:
		await tree.physics_frame
		if not jumped and player.global_position.x >= g.global_position.x - half - 0.9:
			Input.action_press("jump")
			jumped = true
			jump_frame = i
		if jumped and i - jump_frame == 26:
			Input.action_release("jump")
		if player.global_position.x > g.global_position.x + half + 0.5:
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	check(player.global_position.x > g.global_position.x + half, "he is past the gum: " + describe())
	check(not player.call("is_stuck"), "never stuck")


# --- The chopsticks ---------------------------------------------------------------------------------

func test_the_chopsticks_telegraph_then_grab_and_he_wiggles_free() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["giant_foot.gd", "gum_patch.gd"])
	var zones: Array[Node3D] = hazards_of("chopsticks.gd")
	var zone: Node3D = null
	for z: Node3D in zones:
		if z.global_position.y > 5.0: # a table's, not the floor's
			zone = z
	for z: Node3D in zones:
		if z != zone:
			z.call("set_enabled", false)
	var table: LayoutGeometryScript.Placed = plat(String(zone.get_meta("platform", "r_t1")))
	await put_on(table.def.id, table.length() * 0.5)
	zone.global_position.x = player.global_position.x
	zone.global_position.y = table.top
	var saw_telegraph: bool = false
	var hearts_at_telegraph: int = 14
	var grabbed: bool = false
	for i: int in 900:
		await tree.physics_frame
		if int(zone.get("phase")) == 1 and not saw_telegraph:
			saw_telegraph = true
			hearts_at_telegraph = gs.hearts
		if player.get("held_by") != null:
			grabbed = true
			break
	check(saw_telegraph, "a shadow first")
	check_eq(hearts_at_telegraph, 14, "and no damage while it only warns")
	check(grabbed, "then it grabbed him: " + describe())
	check_eq(gs.hearts, 13, "half a heart")
	var y: float = player.global_position.y
	await frames(30)
	check(player.global_position.y > y, "it lifts him")
	check_eq(gs.hearts, 13, "no damage while held")
	await wiggle(4)
	check(await until(func() -> bool: return player.get("held_by") == null, 60), "four wiggles and he is free: " + describe())
	await frames(60)
	check(not player.get("controlled"), "his own again")


# --- The giant foot ---------------------------------------------------------------------------------

func test_the_foot_warns_then_smooshes_for_a_heart_and_he_pops_back() -> void:
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "gum_patch.gd"])
	var zone: Node3D = hazards_of("giant_foot.gd")[0]
	for z: Node3D in hazards_of("giant_foot.gd"):
		if z != zone:
			z.call("set_enabled", false)
	teleport(zone.global_position.x, lane().top + 0.4)
	await until(func() -> bool: return on_floor(), 60)
	var telegraph_frames: int = 0
	var smooshed: bool = false
	var flat_frames: int = 0
	for i: int in 1200:
		await tree.physics_frame
		if int(zone.get("phase")) == 1:
			telegraph_frames += 1
			check_eq(gs.hearts, 14, "no damage during the telegraph")
			var strike_x: float = zone.get("strike_x")
			if absf(player.global_position.x - strike_x) > 0.2:
				player.global_position.x = strike_x # stand where the shadow is
		if player.get("flat_left") > 0.0:
			smooshed = true
			flat_frames += 1
		elif smooshed:
			break
	check(telegraph_frames > 40, "a telegraph of %d frames" % telegraph_frames)
	check(smooshed, "the foot came down on him: " + describe())
	check_eq(gs.hearts, 12, "one heart")
	check(flat_frames >= 30 and flat_frames <= 50, "flat for about 0.6 s (%d frames)" % flat_frames)
	await frames(10)
	check(player.get("flat_left") == 0.0 and state() != "dead", "he popped back: " + describe())


# --- Wheel 2 ----------------------------------------------------------------------------------------

func test_wheel_2_comes_back_to_its_spot_when_it_is_knocked_the_wrong_way() -> void:
	gs = tree.root.get_node_or_null("GameState")
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
	await key_event(KEY_8)
	await frames(20)
	await tap("ui_accept")
	await frames(6)
	var wheel: Node3D = flow.builder.enemies_in_group("tutorial", "c2")[0]
	var start: Vector3 = wheel.global_position
	var t3: LayoutGeometryScript.Placed = plat("tut_t3")
	await put_on("tut_t3", 1.0)
	# knocked the wrong way: flat at the far end, away from the ledge he needs
	wheel.call("receive_attack", "roll", -1.0)
	wheel.global_position = Vector3(t3.left + 0.8, t3.top + 0.02, 0.0)
	await frames(10)
	var replacement: Node3D = null
	for i: int in 60 * 6:
		await tree.physics_frame
		var now: Array[Node3D] = flow.builder.enemies_in_group("tutorial", "c2")
		if not now.is_empty() and now[0] != wheel:
			replacement = now[0]
			break
	check(replacement != null, "after the delay a new wheel stands at its start")
	if replacement != null:
		check(replacement.global_position.distance_to(start) < 1.0, "on its spot: %s vs %s" % [str(replacement.global_position), str(start)])
		check(replacement.get("alive") and not replacement.get("flat"), "upright")
