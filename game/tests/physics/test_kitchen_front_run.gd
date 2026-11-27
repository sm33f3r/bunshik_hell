extends "res://tests/map1_base.gd"
## Task 3c-i-a, real Map 1 scene, REAL input (nothing here calls receive_attack or a bottle function): the
## 간장 bottle (a roll knocks it over; slams and stomps on the lying bottle squirt five times, +3 나트륨 each,
## then nothing; slam and stomp on the standing one do nothing; dying puts it back upright with five), the
## curtain strips he walks under into the kitchen stub, the walk from the last table to the doorway, and
## reaching, knocking over and squirting the bottle at each candidate spot. The bottle is placed by its spawn choice: a test forces a spot with GameState.debug_spawn_overrides
## and builds the section again (flow.reset_sections()).

const CHOICE: String = "ganjang_bottle"
const SPOTS: Array[String] = ["under_last_table_left", "under_last_table_right"]
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


func blasts() -> int:
	return tree.get_nodes_in_group("ganjang_blasts").size()


# --- The standing bottle ----------------------------------------------------------------------------

func test_a_roll_into_the_standing_bottle_knocks_it_over_and_it_stays_over() -> void:
	await open_dining()
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left")
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
	await force_spot("under_last_table_left") # the floor is clear
	var lane: LayoutGeometryScript.Placed = plat("kitchen_floor")
	var fixture: Resource = flow.layout.section("kitchen_front").fixtures[0]
	var door: Resource = flow.layout.section("kitchen_front").doorways[0]
	var m: float = flow.reach.m_per_cm
	var door_x: float = LayoutGeometryScript.item_x(flow.placed, door, flow.layout)
	var dispenser_x: float = LayoutGeometryScript.item_x(flow.placed, fixture, flow.layout)
	var curtain: Node3D = flow.builder.curtain_nodes.get(door.id)
	check(curtain != null, "the curtain is built")
	# He drops onto the floor under the first new table and walks right.
	teleport(plat("chair_kf_t2_9").right + 1.0, lane.top + 0.5) # past the last stair: the open fight space
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
	await force_spot("under_last_table_left")
	var lane: LayoutGeometryScript.Placed = plat("kitchen_floor")
	var door: Resource = flow.layout.section("kitchen_front").doorways[0]
	var door_x: float = LayoutGeometryScript.item_x(flow.placed, door, flow.layout)
	var half: float = door.width_cm * flow.reach.m_per_cm * 0.5
	teleport(door_x - half - 1.0, lane.top + 0.5)
	await until(func() -> bool: return player.get("grounded"), 90)
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(30)
	Input.action_release("jump")
	await until(func() -> bool: return player.global_position.x > door_x + half + 2.0, 400)
	Input.action_release("move_right")
	check(player.global_position.x > door_x + half + 1.0, "straight through the strips, jumping: " + describe())


# --- Helpers for the long walks ----------------------------------------------------------------------

func on_floor() -> bool:
	return player.get("grounded") and feet_y() < plat("kitchen_floor").top + 0.2


## Jumps over the standing bottle (rightwards) and lands beyond it.
func hop_over_bottle() -> bool:
	var b: Node3D = bottle()
	var beyond: float = b.global_position.x + 1.2
	Input.action_press("move_right")
	var jumped: bool = false
	for i: int in 900:
		await tree.physics_frame
		if not jumped and player.global_position.x >= b.global_position.x - 1.6:
			Input.action_press("jump")
			jumped = true
		if jumped and player.global_position.x > beyond and player.get("grounded"):
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	return player.global_position.x > beyond


## Walks (real input) until he stands about `distance` m from the bottle's middle, on the side he is already on.
## Returns the action that walks from there toward the bottle.
func walk_beside_bottle(distance: float) -> String:
	var b: Node3D = bottle()
	var side: float = -1.0 if player.global_position.x < b.global_position.x else 1.0
	var target: float = b.global_position.x + side * distance
	for i: int in 900:
		var off: float = target - player.global_position.x
		if absf(off) < 0.3:
			break
		Input.action_release("move_left" if off > 0.0 else "move_right")
		Input.action_press("move_right" if off > 0.0 else "move_left")
		await tree.physics_frame
	Input.action_release("move_left")
	Input.action_release("move_right")
	await frames(30)
	var toward: String = "move_right" if side < 0.0 else "move_left"
	# A tap toward it, so he faces it.
	Input.action_press(toward)
	await frames(2)
	Input.action_release(toward)
	await frames(20)
	return toward


## A real jump from beside the lying bottle onto it, with the attack button once he is over it.
func jump_attack(action: String) -> void:
	var b: Node3D = bottle()
	var done: int = b.get("squirts_done")
	var toward: String = await walk_beside_bottle(2.4)
	var side: float = 1.0 if toward == "move_right" else -1.0
	Input.action_press(toward)
	Input.action_press("jump")
	for i: int in 240:
		await tree.physics_frame
		if (b.global_position.x - player.global_position.x) * side <= 0.2:
			break
	Input.action_release(toward)
	await tap(action)
	Input.action_release("jump")
	await until(func() -> bool: return b.get("squirts_done") > done and player.get("grounded"), 180)
	await frames(30)


# --- From the last table to the doorway --------------------------------------------------------------

## All real input: off the last table to the floor, past the bottle, across the open fight space, through
## the pour zone under the spout and under the curtains.
func test_he_walks_from_the_last_table_across_the_fight_space_past_the_spout_and_under_the_curtains() -> void:
	await open_dining()
	await force_spot("under_last_table_right")
	var door: Resource = flow.layout.section("kitchen_front").doorways[0]
	var door_x: float = LayoutGeometryScript.item_x(flow.placed, door, flow.layout)
	var spout_x: float = flow.builder.fixture_nodes.get("water_dispenser_1").get_meta("spout_x")
	var stairs_end: float = plat("chair_kf_t2_9").right
	var curtain: Node3D = flow.builder.curtain_nodes.get(door.id)
	await put_on("kf_t2", 3.0)
	var hearts: int = gs.hearts
	# Off the left end of the table, down to the floor under it.
	Input.action_press("move_left")
	await until(func() -> bool: return player.global_position.x < plat("kf_t2").left - 0.3, 600)
	Input.action_release("move_left")
	check(await until(on_floor, 300), "down on the floor: " + describe())
	check(await hop_over_bottle(), "over the bottle under the table: " + describe())
	var in_zone: bool = false
	var airborne: int = 0
	var swayed: float = 0.0
	var behind_curtain: bool = false
	var strip: Node3D = curtain.get_node("Strip%d/Mesh" % (door.strips / 2)) as Node3D # a middle one
	var door_half: float = door.width_cm * flow.reach.m_per_cm * 0.5
	Input.action_press("move_right")
	for i: int in 1800:
		await tree.physics_frame
		var x: float = player.global_position.x
		if absf(x - door_x) < 0.5 and strip.global_position.z > player.global_position.z \
				and float(curtain.call("bottom_edge_y")) < player.global_position.y:
			behind_curtain = true
		if x > stairs_end and x < door_x and not player.get("grounded"):
			airborne += 1
		if absf(x - spout_x) < 1.0 and on_floor():
			in_zone = true
		swayed = maxf(swayed, float(curtain.call("sway_amount")))
		if x > door_x + door_half + 3.0:
			break
	Input.action_release("move_right")
	check(in_zone, "he walks through the pour zone, on the floor")
	check_eq(airborne, 0, "open floor: never off the ground between the stairs and the doorway")
	check(behind_curtain, "in the doorway the strips hang in front of him, down past his middle")
	check(player.global_position.x > door_x + door_half + 2.0, "through the whole doorway into the stub: " + describe())
	check(swayed > 0.1, "the strips swayed (%.2f rad)" % swayed)
	check_eq(gs.hearts, hearts, "no damage")


# --- Reaching, knocking over and squirting the bottle at each spot -----------------------------------

## From the section's first table with real input: down to the floor, along it to the bottle, roll into it,
## then a jump with a slam and a jump with a stomp.
func reach_knock_over_and_squirt(spot: String) -> void:
	await open_dining()
	await force_spot(spot)
	var b: Node3D = bottle()
	await put_on("kf_t1", 1.0)
	Input.action_press("move_right")
	await until(on_floor, 900)
	Input.action_release("move_right")
	await frames(6)
	check(on_floor(), spot + ": on the floor: " + describe())
	# (Off the end of the first table he may land beyond the left spot: then he walks back to it.)
	await walk_beside_bottle(2.0)
	check(on_floor(), spot + ": still on the floor: " + describe())
	check(absf(player.global_position.x - b.global_position.x) < 2.5, spot + ": next to it: " + describe())
	check(not b.get("fallen"), spot + ": walking up to it leaves it standing")
	await roll_into_it()
	check(b.get("fallen"), spot + ": the roll knocked it over: " + describe())
	gs.set("sodium", 0)
	await jump_attack("roll") # the roll button in the air: a slam
	check_eq(b.get("squirts_done"), 1, spot + ": a jump and a slam squirts: " + describe())
	check_eq(gs.sodium, 3, spot + ": +3")
	await jump_attack("look_down") # a stomp
	check_eq(b.get("squirts_done"), 2, spot + ": a jump and a stomp squirts: " + describe())
	check_eq(gs.sodium, 6, spot + ": +3 more")


func test_he_reaches_knocks_over_and_squirts_the_bottle_at_the_left_spot() -> void:
	await reach_knock_over_and_squirt("under_last_table_left")


func test_he_reaches_knocks_over_and_squirts_the_bottle_at_the_right_spot() -> void:
	await reach_knock_over_and_squirt("under_last_table_right")
