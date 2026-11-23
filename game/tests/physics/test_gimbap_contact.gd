extends "res://tests/map1_base.gd"
## Task 3b-ii-fix, item 3: the 김밥 train hit with REAL contact on the real Map 1 scene. The train
## marches as it does in the game (nothing is frozen). He jumps and stomps a slice, rolls into the
## line, slams next to it; nothing here calls receive_attack. Roster: stomp -> damage, landing ->
## spill, roll -> break_line, slam -> kill.
##
## Root cause this guards against: a slice had 2 hp and a stomp does 1, so the first stomp hurt it
## silently (nothing showed), and a plain landing only spills. Slices now have 1 hp (data).

var attacks: Array[String] = []
var hearts_at_stomp: int = -1


func watch_attacks() -> void:
	attacks.clear()
	hearts_at_stomp = -1
	player.connect("attacked", func(attack: String, reaction: String) -> void:
		attacks.append("%s:%s" % [attack, reaction])
		if attack == "stomp" and hearts_at_stomp < 0:
			hearts_at_stomp = gs.hearts)


func alive_slices(train: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for s: Node3D in slices():
		if s.get("train") == train or train.get("broken"):
			if s.get("alive"):
				out.append(s)
	return out


## Stands on the table `gap` metres to the right of the train's leader and waits for it to come.
func wait_in_front(train: Node3D, gap: float) -> Node3D:
	var lead: Node3D = (train.get("slices") as Array)[0]
	teleport(lead.global_position.x + gap, lead.global_position.y + 0.3)
	await until(func() -> bool: return player.get("grounded"), 60)
	return lead


func test_a_stomp_with_real_contact_kills_a_slice_and_nothing_else() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	watch_attacks()
	var before: int = (train.get("slices") as Array).size()
	var lead: Node3D = await wait_in_front(train, 7.0)
	var killed: bool = false
	for i: int in 900:
		var dx: float = lead.global_position.x - player.global_position.x
		if player.get("grounded"):
			Input.action_release("look_down")
			if dx < -0.5 and dx > -1.5:
				Input.action_press("jump")
		else:
			Input.action_press("move_left" if dx < -0.2 else "move_right") if absf(dx) > 0.2 else null
			Input.action_release("move_left" if dx >= -0.2 else "move_right")
			if player.velocity.y < 0.0 and player.global_position.y - player.get("body_half_height") > lead.global_position.y + lead.get("body_height") + 0.1:
				Input.action_press("look_down")
		await tree.physics_frame
		if attacks.has("stomp:damage") and alive_slices(train).size() < before:
			killed = true
			break
	Input.action_release("jump")
	Input.action_release("look_down")
	Input.action_release("move_left")
	Input.action_release("move_right")
	check(killed, "the stomp killed the slice it landed on: %s attacks=%s hearts=%d" % [describe(), str(attacks), gs.hearts])
	check_eq(hearts_at_stomp, 14, "the stomp itself cost him nothing")
	check(not (train.get("broken")), "a stomp does not break the line")
	check_eq(alive_slices(train).size(), before - 1, "exactly one slice is gone")


func test_a_plain_landing_only_spills_and_bounces_him() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	watch_attacks()
	var lead: Node3D = (train.get("slices") as Array)[2]
	var patches: int = tree.get_nodes_in_group("slippery_patches").size()
	teleport(lead.global_position.x - 0.2, lead.global_position.y + 3.0)
	check(await until(func() -> bool: return attacks.size() > 0, 120), "he came down on it: " + describe())
	check_eq(attacks[0], "landing:spill", "landing: spill")
	check(lead.get("alive"), "the slice is fine")
	check(tree.get_nodes_in_group("slippery_patches").size() > patches, "a patch is left")


func test_a_roll_with_real_contact_breaks_the_line_and_the_single_slices_can_be_picked_off() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	watch_attacks()
	var count: int = (train.get("slices") as Array).size()
	var lead: Node3D = await wait_in_front(train, 6.0)
	Input.action_press("move_left")
	var rolled: bool = false
	for i: int in 400:
		await tree.physics_frame
		var dx: float = lead.global_position.x - player.global_position.x
		if dx > -2.2 and dx < 0.0:
			await tap("roll")
			rolled = true
			break
	check(rolled, "the train came to him: " + describe())
	check(await until(func() -> bool: return train.get("broken"), 90), "the roll broke the line: " + describe())
	Input.action_release("move_left")
	check(attacks.has("roll:break_line"), "it was the roll: " + str(attacks))
	for s: Node3D in (train.get("slices") as Array):
		check(s.get("alive"), "%s is alive: a roll only breaks the line" % s.name)
	check_eq(alive_slices(train).size(), count, "all %d are still there" % count)
	for s: Node3D in alive_slices(train):
		check(s.get("train") == null, "%s walks on its own now" % s.name)
	# The slices hop apart and may land on him: breaking the line must not cost him a heart (a short
	# grace after the roll, in the tuning data). This was the flaky part: some runs he was hurt right here.
	await frames(40)
	check_eq(gs.hearts, 14, "the roll that broke the line cost him nothing: " + describe())
	# Pick one off: stand a few metres from a single slice and stomp it. The others are done with and
	# the one picked stands still, so the stomp has exactly one slice to land on (two slices overlapping
	# under him made WHICH one the stomp hit change from run to run).
	var victim: Node3D = alive_slices(train)[0]
	for other: Node3D in alive_slices(train):
		if other != victim:
			other.call("debug_defeat")
	victim.set_physics_process(false)
	attacks.clear()
	gs.set("i_frames_left", 0.0)
	teleport(victim.global_position.x, victim.global_position.y + 3.5)
	await frames(2)
	Input.action_press("look_down")
	var dead_now: bool = await until(func() -> bool: return not victim.get("alive"), 90)
	Input.action_release("look_down")
	check(dead_now, "a single slice dies to a stomp: %s attacks=%s" % [describe(), str(attacks)])
	check(attacks.has("stomp:damage") or attacks.has("slam:kill"), "by the stomp: " + str(attacks))


func test_a_slam_next_to_the_line_kills_the_slices_in_reach_only() -> void:
	await open_dining()
	var train: Node3D = isolate_train()
	watch_attacks()
	var all: Array = train.get("slices")
	var near: Node3D = all[1]
	var radius: float = (player.get("tuning") as Resource).slam_radius
	# Over the gap beside the second slice, so the landing is on the table next to it.
	teleport(near.global_position.x + 0.9, near.global_position.y + 4.0)
	await frames(4)
	await tap("roll") # in the air: slam
	check(await until(func() -> bool: return not near.get("alive"), 120), "the slam killed it: %s %s" % [describe(), str(attacks)])
	check(attacks.has("slam:kill"), "as a slam: " + str(attacks))
	var landing_x: float = player.global_position.x
	for s: Node3D in all:
		if not is_instance_valid(s):
			continue
		var close: bool = Vector2(s.global_position.x, s.global_position.y + s.get("body_height") * 0.5).distance_to(
			Vector2(landing_x, player.global_position.y)) <= radius
		if not close:
			check(s.get("alive"), "%s is out of reach and lives" % s.name)
