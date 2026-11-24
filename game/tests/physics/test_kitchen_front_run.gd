extends "res://tests/map1_base.gd"
## Task 3c-i-a, real Map 1 scene, REAL input (nothing here calls receive_attack or a bottle function): the
## 간장 bottle (a roll knocks it over; slams and stomps on the lying bottle squirt five times, +3 나트륨 each,
## then nothing; slam and stomp on the standing one do nothing; dying puts it back upright with five), the
## curtain strips he walks under into the kitchen stub, and that he can reach the bottle at every candidate
## spot. The bottle is placed by its spawn choice: a test forces a spot with GameState.debug_spawn_overrides
## and builds the section again (flow.reset_sections()).

const CHOICE: String = "ganjang_bottle"
const SPOTS: Array[String] = ["last_table", "floor_before_dispenser", "floor_mid"]
## Plain tuning facts: a slam / a stomp is made from this high above the bottle's top.
const DROP_HEIGHT_M: float = 3.5

var attacks: Array[String] = []


# --- Helpers ----------------------------------------------------------------------------------------

func bottle() -> Node3D:
	var found: Array[Node3D] = flow.builder.enemies_in_group("kitchen_front", "bottle")
	return found[0] if not found.is_empty() else null


## The bottle stands at this spot (the section is built again) with every other enemy and hazard out of the way.
func force_spot(spot: String) -> void:
	var forced: Dictionary = gs.get("debug_spawn_overrides")
	forced.clear()
	forced[CHOICE] = spot
	flow.reset_sections()
	await frames(3)
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])


func watch_attacks() -> void:
	attacks.clear()
	player.connect("attacked", func(attack: String, reaction: String) -> void:
		attacks.append("%s:%s" % [attack, reaction]))


## Stands on the floor `dx` metres from the bottle's middle (negative: to its left).
func stand_by(dx: float) -> void:
	var b: Node3D = bottle()
	teleport(b.global_position.x + dx, b.global_position.y + 0.5)
	player.set("facing", 1.0 if dx < 0.0 else -1.0)
	await until(func() -> bool: return player.get("grounded"), 90)
	await frames(6)


## A real roll toward the bottle: walk a step toward it, then the roll button.
func roll_into_it() -> void:
	var b: Node3D = bottle()
	var toward: String = "move_right" if b.global_position.x > player.global_position.x else "move_left"
	Input.action_press(toward)
	await frames(2)
	await tap("roll")
	await until(func() -> bool: return b.get("fallen"), 60)
	Input.action_release(toward)
	await frames(30)


func knock_over() -> void:
	await stand_by(-3.0)
	await roll_into_it()


func rise() -> float:
	return float(bottle().get("body_height"))


## Drops onto the bottle from above and slams ("roll" in the air) or stomps ("look_down" in the air), the way a
## player does. Returns after he has landed and settled.
func hit_from_above(how: String) -> void:
	var b: Node3D = bottle()
	teleport(b.global_position.x, b.global_position.y + rise() + DROP_HEIGHT_M)
	await frames(4)
	if how == "slam":
		await tap("roll")
	else:
		await tap("look_down")
	await until(func() -> bool: return player.get("grounded"), 120)
	await frames(8)


func die_and_come_back() -> void:
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 60), "he died")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 400), "and came back with full hearts")
	await frames(6)


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


func blasts() -> int:
	return tree.get_nodes_in_group("ganjang_blasts").size()


# --- The standing bottle ----------------------------------------------------------------------------

func test_a_roll_into_the_standing_bottle_knocks_it_over_and_it_stays_over() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	var b: Node3D = bottle()
	check(b != null and not b.get("fallen"), "it stands")
	watch_attacks()
	var hearts: int = gs.hearts
	await knock_over()
	check(b.get("fallen"), "the roll knocked it over: " + describe())
	check(b.get("alive"), "it is not dead")
	check(attacks.has("roll:knock_over"), "through the reaction table: " + str(attacks))
	check_eq(gs.hearts, hearts, "and it cost him nothing")
	check_eq(b.get("fall_dir"), 1.0, "the nozzle points the way the roll went")
	await frames(300)
	check(b.get("fallen"), "it is still down a few seconds later")
	check_eq(b.get("squirts_left"), 5, "and a roll does not squirt")


func test_walking_into_the_standing_bottle_is_harmless_and_he_can_hop_onto_it() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	var b: Node3D = bottle()
	var hearts: int = gs.hearts
	await stand_by(-2.0)
	Input.action_press("move_right")
	await frames(90)
	Input.action_release("move_right")
	check_eq(gs.hearts, hearts, "walking into its side costs nothing")
	check(state() != "hurt" and state() != "dead", "and does not knock him back: " + describe())
	check(player.global_position.x < b.global_position.x, "it is solid: he is still on its left (" + describe() + ")")
	check(not b.get("fallen"), "walking does not knock it over")
	# He stands on top of it: a landing on it is not a bounce.
	var top: float = b.global_position.y + float(b.get("body_height"))
	teleport(b.global_position.x, top + 1.0)
	check(await until(func() -> bool: return player.get("grounded"), 90), "he lands on it")
	await frames(20)
	check(player.get("grounded") and absf(feet_y() - top) < 0.15, "and stands on top (feet %.2f, top %.2f)" % [feet_y(), top])
	check_eq(gs.hearts, hearts, "still no damage")


func test_slam_and_stomp_on_the_standing_bottle_do_nothing() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	var b: Node3D = bottle()
	watch_attacks()
	var hearts: int = gs.hearts
	var sodium: int = gs.sodium
	await hit_from_above("slam")
	await hit_from_above("stomp")
	check(not b.get("fallen"), "it still stands")
	check_eq(b.get("squirts_done"), 0, "no squirt")
	check_eq(gs.sodium, sodium, "no 나트륨")
	check_eq(blasts(), 0, "no blast")
	check_eq(gs.hearts, hearts, "no damage")
	check(not attacks.has("slam:squirt") and not attacks.has("stomp:squirt"), "the table said nothing special: " + str(attacks))
	check_eq(b.get("squirts_left"), 5, "five squirts left for when it lies down")


# --- The lying bottle -------------------------------------------------------------------------------

func test_five_slams_and_stomps_squirt_fifteen_sodium_and_the_sixth_does_nothing() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	var b: Node3D = bottle()
	await knock_over()
	check(b.get("fallen"), "it lies down first: " + describe())
	watch_attacks()
	var hearts: int = gs.hearts
	var hits: Array[String] = ["slam", "stomp", "slam", "stomp", "slam"]
	for i: int in 5:
		gs.set("sodium", 0) # so the cap of the bar does not hide a squirt
		await hit_from_above(hits[i])
		check_eq(b.get("squirts_done"), i + 1, "%s %d: one squirt" % [hits[i], i + 1])
		check_eq(b.get("squirts_left"), 4 - i, "%s %d: squirts left" % [hits[i], i + 1])
		check_eq(gs.sodium, 3, "%s %d: +3 나트륨" % [hits[i], i + 1])
	check_eq(b.get("sodium_given"), 15, "+15 in all")
	check(attacks.has("slam:squirt") and attacks.has("stomp:squirt"), "both attacks squirt: " + str(attacks))
	# The blast of a squirt is visible right after the hit (and gone again a moment later).
	gs.set("sodium", 0)
	var squirts_before: int = b.get("squirts_done")
	# 6th: nothing. A small puff, no blast, no 나트륨.
	await hit_from_above("slam")
	check_eq(b.get("squirts_done"), squirts_before, "the 6th hit does not squirt")
	check_eq(gs.sodium, 0, "and gives nothing")
	check_eq(b.get("sodium_given"), 15, "still 15 in all")
	check_eq(b.get("empty_hits"), 1, "it was noticed as an empty hit (the puff)")
	await hit_from_above("stomp")
	check_eq(gs.sodium, 0, "a stomp on the empty bottle gives nothing either")
	check_eq(gs.hearts, hearts, "and none of it hurt him")


func test_a_squirt_shows_a_blast_from_the_nozzle() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	var b: Node3D = bottle()
	await knock_over()
	var b_x: float = b.global_position.x
	var blast_seen: bool = false
	var blast_x: float = 0.0
	var teleported: bool = false
	teleport(b_x, b.global_position.y + rise() + DROP_HEIGHT_M)
	await frames(4)
	await tap("roll")
	for i: int in 60:
		await tree.physics_frame
		var found: Array[Node] = tree.get_nodes_in_group("ganjang_blasts")
		if not found.is_empty():
			blast_seen = true
			blast_x = (found[0] as Node3D).global_position.x
			break
	check(blast_seen, "a blast is there right after the hit")
	check(blast_x > b_x, "on the nozzle's side (blast x %.2f, bottle x %.2f, nozzle toward +x)" % [blast_x, b_x])
	await frames(90)
	check_eq(blasts(), 0, "and it is gone again a moment later")
	check(not teleported, "(sanity)")


func test_the_bottle_gives_nothing_to_a_hit_that_is_not_a_slam_or_a_stomp() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	var b: Node3D = bottle()
	await knock_over()
	var sodium: int = gs.sodium
	await stand_by(-3.0)
	Input.action_press("move_right")
	await frames(2)
	await tap("roll") # a second roll into the lying bottle
	Input.action_release("move_right")
	await frames(40)
	check_eq(b.get("squirts_done"), 0, "a roll into the lying bottle does not squirt")
	check_eq(gs.sodium, sodium, "no 나트륨")
	teleport(b.global_position.x, b.global_position.y + rise() + 1.5) # a plain landing on it
	await until(func() -> bool: return player.get("grounded"), 90)
	await frames(10)
	check_eq(b.get("squirts_done"), 0, "nor does a plain landing")


# --- Starting over ----------------------------------------------------------------------------------

func test_dying_and_respawning_puts_the_bottle_back_upright_with_five_squirts_on_the_same_spot() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	# He reaches the section's checkpoint, so he comes back there (not at the dining room start).
	await put_on("kf_t1", 2.0)
	check(await until(func() -> bool: return gs.checkpoint_id == "kitchen_front_start", 60), "the data checkpoint is reached: " + gs.checkpoint_id)
	var first: Node3D = bottle()
	var spot: Vector3 = first.global_position
	await knock_over()
	await hit_from_above("slam")
	await hit_from_above("stomp")
	check_eq(first.get("squirts_left"), 3, "two squirts used")
	check(first.get("fallen"), "and it lies down")
	await die_and_come_back()
	var second: Node3D = bottle()
	check(second != first, "the section was built again")
	check(not second.get("fallen"), "the bottle stands again")
	check_eq(second.get("squirts_left"), 5, "with all five squirts")
	check(second.global_position.distance_to(spot) < 0.05, "on the same spot (%s vs %s)" % [str(second.global_position), str(spot)])
	check_eq(bottle().get_meta("entry").platform_id, "kitchen_floor", "still the forced spot")
	check_eq(gs.checkpoint_id, "kitchen_front_start", "he came back at the checkpoint")
	# And it works again as new: knocked over, a slam squirts.
	gs.set("sodium", 0)
	await knock_over()
	await hit_from_above("slam")
	check_eq(second.get("squirts_done"), 1, "the new bottle squirts")
	check_eq(gs.sodium, 3, "+3")


func test_the_spot_is_the_picked_one_and_stays_after_a_respawn_without_a_forced_option() -> void:
	await open_dining()
	var picked: String = gs.spawn_picks.get(CHOICE, "")
	check(SPOTS.has(picked), "a spot was picked when the section was built: '%s'" % picked)
	var spot: Vector3 = bottle().global_position
	await die_and_come_back()
	check_eq(gs.spawn_picks.get(CHOICE), picked, "the same pick after a respawn")
	check(bottle().global_position.distance_to(spot) < 0.05, "and the bottle is on the same spot")


# --- The curtain and the kitchen stub ---------------------------------------------------------------

func test_he_walks_the_floor_under_the_curtain_strips_into_the_kitchen_stub() -> void:
	await open_dining()
	await force_spot("last_table") # the floor is clear
	var lane: LayoutGeometryScript.Placed = plat("kitchen_floor")
	var fixture: Resource = flow.layout.section("kitchen_front").fixtures[0]
	var door: Resource = flow.layout.section("kitchen_front").doorways[0]
	var m: float = flow.reach.m_per_cm
	var door_x: float = LayoutGeometryScript.x_on(lane, door.along_m)
	var dispenser_x: float = LayoutGeometryScript.x_on(lane, fixture.along_m)
	var curtain: Node3D = flow.builder.curtain_nodes.get(door.id)
	check(curtain != null, "the curtain is built")
	# He drops onto the floor under the first new table and walks right.
	teleport(lane.left + 26.0, lane.top + 0.5)
	await until(func() -> bool: return player.get("grounded"), 90)
	var hearts: int = gs.hearts
	check(feet_y() < lane.top + 0.2, "on the floor: " + describe())
	var swayed: float = 0.0
	var passed_dispenser: bool = false
	Input.action_press("move_right")
	for i: int in 1500:
		await tree.physics_frame
		swayed = maxf(swayed, float(curtain.call("sway_amount")))
		if player.global_position.x > dispenser_x + 3.0:
			passed_dispenser = true
		if player.global_position.x > door_x + door.width_cm * m * 0.5 + 3.0:
			break
	Input.action_release("move_right")
	check(passed_dispenser, "he walks past the 정수기: nothing solid is there")
	check(player.global_position.x > door_x + door.width_cm * m * 0.5 + 2.0, "and through the doorway: it is open (x %.1f, door %.1f): %s" % [player.global_position.x, door_x, describe()])
	check(swayed > 0.1, "the strips swayed as he passed (%.2f rad)" % swayed)
	check_eq(gs.hearts, hearts, "no damage on the way")
	# He is in the stub; the wall stops him at its end.
	Input.action_press("move_right")
	await frames(240)
	Input.action_release("move_right")
	check(player.global_position.x < lane.right + 0.01, "the temporary end wall stops him: " + describe())
	check(player.global_position.x > lane.right - 3.0, "at the end of the stub (x %.1f of %.1f)" % [player.global_position.x, lane.right])
	await frames(200)
	check(float(curtain.call("sway_amount")) < 0.1, "the strips settle (%.3f rad)" % float(curtain.call("sway_amount")))


func test_he_can_also_jump_through_the_curtain_without_it_stopping_him() -> void:
	await open_dining()
	await force_spot("last_table")
	var lane: LayoutGeometryScript.Placed = plat("kitchen_floor")
	var door: Resource = flow.layout.section("kitchen_front").doorways[0]
	var door_x: float = LayoutGeometryScript.x_on(lane, door.along_m)
	teleport(door_x - 3.0, lane.top + 0.5)
	await until(func() -> bool: return player.get("grounded"), 90)
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(30)
	Input.action_release("jump")
	await until(func() -> bool: return player.global_position.x > door_x + 3.0, 200)
	Input.action_release("move_right")
	check(player.global_position.x > door_x + 3.0, "straight through the strips, jumping: " + describe())


# --- Reaching the bottle at every candidate spot -----------------------------------------------------

## From the section's first table, with real input, to a spot next to the bottle. Floor spots: walks off the
## table onto the floor and along it. The table spot: hops to the last table and walks to the bottle.
func walk_to_bottle(spot: String) -> void:
	var b: Node3D = bottle()
	if spot == "floor_mid":
		await put_on("r_t15", plat("r_t15").length() - 2.0) # off the end of the last dining-room table, onto the floor
	else:
		await put_on("kf_t1", 1.0)
	if spot == "last_table":
		check(await hop_to(plat("kf_t1").right - 0.6, "kf_t2"), "to the last table: " + describe())
		var target: float = b.global_position.x - 1.5
		Input.action_press("move_right")
		await until(func() -> bool: return player.global_position.x >= target, 300)
		Input.action_release("move_right")
	else:
		# Off the end of the table he is on, down onto the floor, and along it.
		var target: float = b.global_position.x - 1.5
		Input.action_press("move_right")
		await until(func() -> bool: return player.get("grounded") and feet_y() < 1.0 and player.global_position.x >= target, 1500)
		Input.action_release("move_right")
	await frames(10)


## Jumps over the standing bottle (right) and lands beyond it.
func hop_over_bottle() -> bool:
	var b: Node3D = bottle()
	var beyond: float = b.global_position.x + 1.2
	Input.action_press("move_right")
	var jumped: bool = false
	for i: int in 240:
		await tree.physics_frame
		if not jumped and player.global_position.x >= b.global_position.x - 1.6:
			Input.action_press("jump")
			jumped = true
		if jumped and player.global_position.x > beyond and player.get("grounded"):
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	return player.global_position.x > beyond


func test_he_reaches_the_bottle_at_the_last_table() -> void:
	await open_dining()
	await force_spot("last_table")
	await walk_to_bottle("last_table")
	var b: Node3D = bottle()
	check(absf(player.global_position.x - b.global_position.x) < 2.2, "next to it: " + describe())
	check(on_top_of("kf_t2"), "on its table")
	check(await hop_over_bottle(), "and over it: " + describe())
	check(on_top_of("kf_t2"), "still on the table (it does not fall off): " + describe())


func test_he_reaches_the_bottle_on_the_floor_before_the_dispenser() -> void:
	await open_dining()
	await force_spot("floor_before_dispenser")
	await walk_to_bottle("floor_before_dispenser")
	var b: Node3D = bottle()
	check(absf(player.global_position.x - b.global_position.x) < 2.2, "next to it: " + describe())
	check(feet_y() < 1.0, "on the floor: " + describe())
	check(await hop_over_bottle(), "and over it, on toward the 정수기: " + describe())


func test_he_reaches_the_bottle_on_the_floor_under_the_first_table() -> void:
	await open_dining()
	await force_spot("floor_mid")
	await walk_to_bottle("floor_mid")
	var b: Node3D = bottle()
	check(absf(player.global_position.x - b.global_position.x) < 2.2, "next to it: " + describe())
	check(feet_y() < 1.0, "on the floor: " + describe())
	check(await hop_over_bottle(), "and over it: " + describe())
