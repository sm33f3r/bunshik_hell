extends "res://tests/map1_base.gd"
## Task 3b-ii-fix2: a plain player for the real Map 1 tutorial, played with real input only (no
## teleports, no direct calls on the wheels): it runs, jumps with the button held, stomps with the down
## press, bounces on the 단무지, rolls into one, climbs a flat one, slams and jumps the exit gap.
## The suites that play the tutorial (the soft-lock tests) share these steps. Each step returns "" when
## it worked, else the name of what failed. Every wait is counted in physics frames.

const BEAT_FRAMES: int = 1500


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


## The enemies of a beat group ("b", "c1", "c2", "d", "dining").
func enemies(group: String) -> Array[Node3D]:
	for section_id: String in ["tutorial", "dining_room_start"]:
		var found: Array[Node3D] = flow.builder.enemies_in_group(section_id, group)
		if not found.is_empty():
			return found
	return [] as Array[Node3D]


func living(group: String) -> Node3D:
	var found: Array[Node3D] = enemies(group)
	return found[0] if not found.is_empty() and found[0].get("alive") else null


## The wheel of a group as it stands now (alive, flat or dead), null when there is none.
func wheel(group: String) -> Node3D:
	var found: Array[Node3D] = enemies(group)
	return found[0] if not found.is_empty() else null


## One line about a wheel: what state it is in and where (metres from the left end of its table).
func wheel_line(group: String, table_id: String) -> String:
	var w: Node3D = wheel(group)
	if w == null:
		return "%s: none" % group
	return "%s: alive=%s flat=%s static=%s visible=%s x_on_table=%.2f y_above_table=%.2f" % [
		group, w.get("alive"), w.get("flat"), w.get("is_static"), w.visible,
		w.global_position.x - plat(table_id).left, w.global_position.y - plat(table_id).top]


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


## Runs right and jumps (button held 26 frames) at `edge_x`; true once he stands on `to_id`.
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


## Waits at wait_x on the table; when the enemy walks up he jumps on it with the down press (a stomp).
func stomp_walker(enemy: Node3D, wait_x: float) -> bool:
	if not await run_to(wait_x):
		return false
	for i: int in BEAT_FRAMES:
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


# --- The beats ----------------------------------------------------------------------------------------

## a) the first gap onto the first table, b) stomp the 만두, the gap onto the second table.
func play_a_and_b() -> String:
	var exit_table: LayoutGeometryScript.Placed = plat("prologue_exit_table")
	if not await jump_to(exit_table.right - 0.6, "tut_t1"):
		return "a: the first gap"
	var t1: LayoutGeometryScript.Placed = plat("tut_t1")
	var mandu: Node3D = living("b")
	if mandu != null and not await stomp_walker(mandu, t1.left + 2.0):
		return "b: stomp the 만두"
	if not await jump_to(t1.right - 0.6, "tut_t2"):
		return "b: the gap to the second table"
	return ""


## c1, the bounce route: wait at the wall of the first ledge, jump on the first wheel when it comes, drift
## onto the ledge. Needs the wheel upright and rolling.
func play_c1_bounce() -> String:
	var t2: LayoutGeometryScript.Placed = plat("tut_t2")
	if not await run_to(t2.right - 2.5):
		return "c1: walking to the ledge's wall"
	var wheel1: Node3D = living("c1")
	if wheel1 == null:
		return "c1: no upright wheel to bounce on"
	for i: int in BEAT_FRAMES:
		if dead():
			release_all()
			return "c1: died"
		if on_top_of("tut_ledge1"):
			release_all()
			return ""
		if not is_instance_valid(wheel1) or not wheel1.get("alive"):
			wheel1 = living("c1")
			if wheel1 == null:
				release_all()
				return "c1: the wheel went away"
		var dx: float = wheel1.global_position.x - player.global_position.x
		if player.get("grounded"):
			Input.action_release("move_right")
			# The wheel comes from the left: jump when it is close enough to be under him on the way down.
			if dx < 0.0 and dx > -1.6:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
		else:
			hold("move_right", player.velocity.y > 9.0 or player.global_position.y - player.get("body_half_height") > t2.top + 2.0)
			if player.velocity.y <= 0.0:
				Input.action_release("jump")
		await tree.physics_frame
	release_all()
	return "c1: the bounce onto the ledge: " + describe()


## Waits at `wait_x` on the table and rolls into the wheel of `group` when it comes from the right (the
## roll goes to the right). True once it lies flat (or is gone).
func roll_into(group: String, wait_x: float) -> bool:
	if not await run_to(wait_x, 0.4):
		return false
	for i: int in BEAT_FRAMES:
		if dead():
			release_all()
			return false
		var w: Node3D = wheel(group)
		if w == null or not is_instance_valid(w) or w.get("flat") or not w.get("alive"):
			release_all()
			return true
		var dx: float = w.global_position.x - player.global_position.x
		if player.get("grounded") and dx > 0.2 and dx < 2.0:
			Input.action_press("move_right")
			await tap("roll")
		await tree.physics_frame
		release_all()
	release_all()
	return false


## Walks right and jumps whenever he is on the ground, until he stands on `target_id` (climbing up a
## flat wheel, a box, a ledge). True when he does.
func climb_right_to(target_id: String, max_frames: int = 900) -> bool:
	Input.action_press("move_right")
	for i: int in max_frames:
		await tree.physics_frame
		if dead():
			release_all()
			return false
		if on_top_of(target_id):
			release_all()
			return true
		if player.get("grounded"):
			Input.action_press("jump")
		elif player.velocity.y <= 0.0:
			Input.action_release("jump")
	release_all()
	return false


## From the first ledge on: down to the third table, c2 (roll into the wheel, climb it), down to the
## fourth table, d (the slam) and e (the exit gap) to the dining room's first table.
func play_from_ledge1() -> String:
	var down: String = await walk_down_to_t3()
	if down != "":
		return down
	return await play_c2_to_end()


## Off the first ledge, down onto the third table.
func walk_down_to_t3() -> String:
	Input.action_press("move_right")
	var t3_ok: bool = await until(func() -> bool: return on_top_of("tut_t3"), 240)
	release_all()
	return "" if t3_ok else "c2: down to the third table"


## On the third table: c2 (roll into the wheel, climb it), d (the slam), e (the exit gap).
func play_c2_to_end() -> String:
	var t3: LayoutGeometryScript.Placed = plat("tut_t3")
	var wheel2: Node3D = wheel("c2")
	if wheel2 == null:
		return "c2: no wheel"
	if not await roll_into("c2", t3.left + 1.0):
		return "c2: knocking the 단무지 over"
	await until(func() -> bool: return not is_instance_valid(wheel2) or wheel2.get("is_static"), 400)
	if not is_instance_valid(wheel2):
		return "c2: the flat wheel vanished"
	if not await climb_right_to("tut_ledge2"):
		return "c2: up the flat 단무지 onto the second ledge: " + describe()
	Input.action_press("move_right")
	var t4_ok: bool = await until(func() -> bool: return on_top_of("tut_t4"), 240)
	release_all()
	if not t4_ok:
		return "d: down to the fourth table"
	# d) the cluster: jump toward it and slam in the air.
	var t4: LayoutGeometryScript.Placed = plat("tut_t4")
	var cluster: Array[Node3D] = enemies("d")
	var slammed: bool = false
	for i: int in BEAT_FRAMES:
		if dead():
			release_all()
			return "d: died"
		var nearest: float = INF
		for m: Node3D in cluster:
			if is_instance_valid(m) and m.get("alive"):
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
	if not on_top_of("tut_t4"):
		return "e: not on the fourth table: " + describe()
	if not await run_to(t4.right - 3.5, 0.4):
		return "e: run-up"
	if not await jump_to(t4.right - 0.6, "dining_1"):
		return "e: the exit gap: " + describe()
	return ""


## He is dead or hurt past help: the way a player gets going again, by dying back to the checkpoint.
func die_and_come_back() -> void:
	release_all()
	if not dead():
		gs.call("take_damage", 14)
		await until(func() -> bool: return state() == "dead", 60)
	await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400)
	await frames(30)
