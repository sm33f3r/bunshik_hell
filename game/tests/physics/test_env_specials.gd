extends "res://tests/physics_base.gd"
## Real test room: 나트륨, the two environment specials (pour water, heavy object), the swell
## and pin reactions, the creeping 라면 and enemy drops. The exercises live on the left-hand
## floor: x -23 (나트륨), -31 (pot over the medium 튀김), -62 to -82 (bottles, table, 라면).

const UsableScript := preload("res://items/usable_object.gd")
const UsableScene: PackedScene = preload("res://items/usable_object.tscn")


## The old dummies and the shooting tube candy out of the way.
func _quiet() -> void:
	park(soft_floor, 16.0)
	park(tall, 17.0)
	park(soft_ledge, 18.0)
	dummy("TubeDummy").set_physics_process(false)
	await frames(3)


func _hud() -> String:
	return (room.get_node("DebugHud/Text") as Label).text


func _bottle1() -> Node3D:
	return room.get_node("Specials/WaterBottle1") as Node3D


func _special_events() -> Dictionary:
	var counts: Dictionary = {"used": 0, "refused": 0}
	player.connect("special_used", func(_o: Node3D) -> void: counts["used"] += 1)
	player.connect("special_refused", func() -> void: counts["refused"] += 1)
	return counts


# --- Pour water -----------------------------------------------------------------------------

func test_pour_water_swells_the_creeping_noodle_it_dies_and_the_flick_unlocks() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 1)
	var noodle: Node3D = dummy("NoodleDummy")
	check(not gs.call("has_skill", "sauce_flick"), "the flick is locked at the start")
	teleport(-61.2, 0.33)
	player.set("facing", -1.0)
	await frames(10)
	check(player.get("special_target") == _bottle1(), "the bottle is the special target: " + describe())
	await tap("special")
	await frames(2)
	check_eq(gs.sodium, 0, "one 나트륨 spent")
	check(_bottle1().get("used"), "the bottle was used")
	check_eq(room.get_tree().get_nodes_in_group("water_sheets").size(), 1, "a water sheet lies on the floor")
	var swelling: bool = await until(func() -> bool: return noodle.get("swelling"), 300)
	check(swelling, "the creeping 라면 walked into the water and started to swell")
	check(noodle.get("alive"), "still alive while swelling")
	var dead: bool = await until(func() -> bool: return not noodle.get("alive"), 400)
	check(dead, "it died of the swell")
	check(gs.call("has_skill", "sauce_flick"), "the first 라면 killed unlocked the flick")
	check_eq(gs.defeated_enemies, ["noodle_dummy"] as Array[String], "one defeat recorded")
	check_eq(gs.hearts, 14, "he was never hurt")


func test_the_sheet_runs_reach_m_along_the_floor_in_the_facing_direction() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 1)
	teleport(-62.8, 0.33)
	player.set("facing", 1.0)
	await frames(10)
	await tap("special")
	await frames(3)
	var sheets: Array[Node] = room.get_tree().get_nodes_in_group("water_sheets")
	check_eq(sheets.size(), 1, "one sheet")
	if sheets.size() == 1:
		var sheet: Node3D = sheets[0] as Node3D
		check(absf(sheet.global_position.x - (-62.0)) < 0.05, "it starts at the bottle")
		check_eq(sheet.get("length"), 3.0, "reach_m = 3 m (data)")
		check_eq(sheet.get("direction"), 1.0, "toward where he faced")


func test_water_makes_a_fried_dummy_deteriorate_and_soft_ones_absorb_it() -> void:
	await open_room()
	await _quiet()
	var small: Node3D = dummy("FriedSmall")
	var big: Node3D = dummy("FriedLarge")
	small.call("receive_attack", "water")
	check_eq(small.get("stage"), 1, "water: fried small -> broken")
	big.call("receive_attack", "water")
	check_eq(big.get("stage"), 0, "large needs 3 hits per stage")
	var soft: Node3D = soft_floor
	var result: Dictionary = soft.call("receive_attack", "water")
	check_eq(result["reaction"], "absorb", "soft food absorbs water")


# --- Heavy object ---------------------------------------------------------------------------

func test_a_heavy_object_dropped_on_the_medium_fried_kills_it_in_one_hit() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 1)
	var fried: Node3D = dummy("FriedMedium")
	var pot: Node3D = room.get_node("Specials/PotLedge") as Node3D
	teleport(-29.2, 2.5)
	await frames(40)
	check(player.is_on_floor(), "he stands on the ledge: " + describe())
	check(absf(player.global_position.y - 2.12) < 0.1, "on top of the ledge: " + describe())
	player.set("facing", -1.0)
	check(player.get("special_target") == pot, "the pot is his target")
	await tap("special")
	var killed: bool = await until(func() -> bool: return not fried.get("alive"), 120)
	check(killed, "the pot fell on the 튀김 and killed it")
	check_eq(fried.get("stage"), 0, "in one hit: it never deteriorated")
	check_eq(gs.sodium, 0, "one 나트륨 spent")
	check(pot.get("used"), "the pot is used up")
	await frames(40)
	check(absf(pot.global_position.y - 0.0) < 0.05, "and it lies on the floor: y=%.2f" % pot.global_position.y)


func test_a_heavy_object_pins_the_noodle_under_the_table_and_it_stays_put_for_pin_s() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 1)
	var noodle: Node3D = dummy("NoodleTable")
	noodle.global_position = Vector3(-79.0, 0.0, 0.0)
	teleport(-74.0, 1.5)
	await frames(40)
	check(absf(player.global_position.y - 1.32) < 0.1, "he stands on the tabletop: " + describe())
	Input.action_press("move_left")
	await until(func() -> bool: return player.global_position.x < -76.2, 120)
	Input.action_release("move_left")
	await frames(10)
	player.set("facing", -1.0)
	var arrived: bool = await until(func() -> bool: return noodle.global_position.x > -77.8, 300)
	check(arrived, "the 라면 crept up to the table leg: x=%.2f" % noodle.global_position.x)
	check(absf(noodle.global_position.x - (-77.7)) < 0.15, "and the leg stopped it: x=%.2f" % noodle.global_position.x)
	await tap("special")
	var pinned: bool = await until(func() -> bool: return noodle.call("is_pinned"), 120)
	check(pinned, "the pot pinned it")
	check(noodle.get("alive"), "a pin does not kill")
	check(noodle.get("pin_left") > 2.7 and noodle.get("pin_left") <= 3.0, "small pot: about 3 s: %.2f" % noodle.get("pin_left"))
	var pinned_x: float = noodle.global_position.x
	var frames_pinned: int = 0
	while noodle.call("is_pinned") and frames_pinned < 400:
		frames_pinned += 1
		await tree.physics_frame
		check(absf(noodle.global_position.x - pinned_x) < 0.02, "no movement while pinned")
	check(frames_pinned > 160 and frames_pinned < 200, "free after about 3 s (180 frames): %d" % frames_pinned)
	check(noodle.get("alive"), "and it resumes, alive")


func test_pot_then_water_on_the_pinned_noodle_swells_and_kills_it() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 2)
	var noodle: Node3D = dummy("NoodleTable")
	noodle.global_position = Vector3(-77.7, 0.0, 0.0)
	teleport(-76.3, 1.5)
	await frames(40)
	player.set("facing", -1.0)
	await tap("special")
	var pinned: bool = await until(func() -> bool: return noodle.call("is_pinned"), 120)
	check(pinned, "pinned by the small 뚝배기")
	teleport(-73.9, 0.4) # down off the table and under it, next to the second bottle
	await frames(20)
	player.set("facing", -1.0)
	check(room.get_node("Specials/WaterBottle2") == player.get("special_target"), "the second bottle is his target: " + describe())
	await tap("special")
	await frames(5)
	check(noodle.get("swelling"), "water on a pinned 라면 still swells it")
	check(noodle.call("is_pinned"), "while it is still pinned")
	var dead: bool = await until(func() -> bool: return not noodle.get("alive"), 300)
	check(dead, "it swelled and died")
	check(gs.call("has_skill", "sauce_flick"), "the flick unlocked")
	check_eq(gs.sodium, 0, "two 나트륨 spent")


func test_contact_still_hurts_while_the_noodle_is_pinned() -> void:
	await open_room()
	await _quiet()
	var noodle: Node3D = dummy("NoodleDummy")
	noodle.call("receive_attack", "heavy_object", 1.0, {"pin_s": 8.0})
	var x0: float = noodle.global_position.x
	teleport(x0 + 2.0, 0.33)
	await frames(10)
	Input.action_press("move_left")
	var hurt: bool = await until(func() -> bool: return gs.hearts < 14, 200)
	Input.action_release("move_left")
	check(hurt, "he touched it and it hurt: " + describe())
	check_eq(gs.hearts, 12, "1 heart")
	check(absf(noodle.global_position.x - x0) < 0.01, "and it never moved")
	check(noodle.call("is_pinned"), "still pinned")


# --- The creeping 라면 -----------------------------------------------------------------------

func test_the_noodle_creeps_toward_him_within_6_m_and_stands_still_beyond() -> void:
	await open_room()
	await _quiet()
	var noodle: Node3D = dummy("NoodleDummy")
	var x0: float = noodle.global_position.x
	teleport(x0 + 7.0, 0.33)
	await frames(60)
	check(absf(noodle.global_position.x - x0) < 0.01, "7 m away: it stands still")
	teleport(x0 + 5.0, 0.33)
	await frames(60)
	var moved: float = noodle.global_position.x - x0
	check(moved > 0.5 and moved < 1.1, "5 m away: it crept about 0.8 m toward him in 1 s: %.2f" % moved)


func test_touching_the_creeping_noodle_costs_one_heart() -> void:
	await open_room()
	await _quiet()
	var noodle: Node3D = dummy("NoodleDummy")
	teleport(noodle.global_position.x + 2.0, 0.33)
	await frames(10)
	var hurt: bool = await until(func() -> bool: return gs.hearts < 14, 400)
	check(hurt, "it crept into him and hurt: " + describe())
	check_eq(gs.hearts, 12, "exactly 1 heart (2 half-hearts)")


# --- Highlight, refusal, nearest -----------------------------------------------------------

func test_too_little_natrium_dims_the_highlight_and_flashes_the_readout() -> void:
	await open_room()
	await _quiet()
	var counts: Dictionary = _special_events()
	teleport(-61.2, 0.33)
	player.set("facing", -1.0)
	await frames(10)
	check_eq(_bottle1().get("highlight"), UsableScript.Highlight.DIM, "dim with 0 나트륨")
	check("NOT ENOUGH 나트륨" not in _hud(), "no flash before pressing")
	await tap("special")
	await frames(3)
	check(not _bottle1().get("used"), "nothing happened")
	check_eq(gs.sodium, 0, "nothing spent")
	check_eq(counts["refused"], 1, "special_refused fired once")
	check("NOT ENOUGH 나트륨" in _hud(), "the 나트륨 readout flashes: " + _hud())
	await frames(45)
	check("NOT ENOUGH 나트륨" not in _hud(), "and the flash goes away")
	gs.call("add_sodium", 1)
	await frames(3)
	check_eq(_bottle1().get("highlight"), UsableScript.Highlight.BRIGHT, "bright once he can pay")
	teleport(-50.0, 0.33)
	await frames(5)
	check_eq(_bottle1().get("highlight"), UsableScript.Highlight.NONE, "no highlight out of range")
	check("Sodium (나트륨): 1 / 7" in _hud(), "the readout: " + _hud())


func test_with_two_objects_in_range_the_nearest_is_used_and_the_hud_says_so() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 2)
	var bottle: UsableScript = UsableScene.instantiate() as UsableScript
	bottle.def = load("res://data/env_specials/water_bottle.tres")
	var pot: UsableScript = UsableScene.instantiate() as UsableScript
	pot.def = load("res://data/env_specials/pot_small.tres")
	room.add_child(bottle)
	room.add_child(pot)
	bottle.global_position = Vector3(-90.0, 0.0, 0.0)
	pot.global_position = Vector3(-89.2, 0.0, 0.0)
	teleport(-89.5, 0.33)
	player.set("facing", 1.0)
	await frames(10)
	check_eq(player.get("special_candidates"), 2, "two in range")
	check(player.get("special_target") == pot, "the pot is nearer")
	check("nearest of 2 in range" in _hud(), "the HUD says so: " + _hud())
	check("Small 뚝배기" in _hud(), "and names the target")
	check_eq(pot.highlight, UsableScript.Highlight.BRIGHT, "the target is highlighted")
	check_eq(bottle.highlight, UsableScript.Highlight.NONE, "the other one is not")
	await tap("special")
	await frames(2)
	check(pot.used and not bottle.used, "only the nearest was used")
	check_eq(gs.sodium, 1, "one 나트륨 spent")
	await frames(5)
	check(player.get("special_target") == bottle, "now the bottle is the only one left")


func test_each_object_is_single_use_and_key_3_resets_it() -> void:
	await open_room()
	await _quiet()
	gs.call("add_sodium", 3)
	teleport(-61.2, 0.33)
	player.set("facing", -1.0)
	await frames(10)
	await tap("special")
	await frames(3)
	check(_bottle1().get("used"), "used")
	check_eq(gs.sodium, 2, "one spent")
	await tap("special")
	await frames(3)
	check_eq(gs.sodium, 2, "a second press does nothing: single use")
	check_eq(room.get_tree().get_nodes_in_group("water_sheets").size(), 1, "still one sheet")
	await key_event(KEY_3)
	await frames(3)
	check(not _bottle1().get("used"), "key 3 reset the bottle")
	check_eq(room.get_tree().get_nodes_in_group("water_sheets").size(), 0, "and cleared the water")
	await tap("special")
	await frames(3)
	check(_bottle1().get("used"), "usable again")
	check_eq(gs.sodium, 1, "spent again")


# --- 나트륨 pickups and drops ---------------------------------------------------------------

func test_walking_into_the_four_natrium_pickups_gives_four() -> void:
	await open_room()
	await _quiet()
	dummy("FriedSmall").set_physics_process(false)
	teleport(-22.9, 0.33)
	await frames(10)
	Input.action_press("move_left")
	await until(func() -> bool: return player.global_position.x < -26.6, 240)
	Input.action_release("move_left")
	check_eq(gs.sodium, 4, "four pickups, +1 each: " + describe())
	check_eq(room.get_tree().get_nodes_in_group("natrium_pickups").filter(
		func(n: Node) -> bool: return n.get("consumed")).size(), 4, "all four taken")
	await key_event(KEY_3)
	await frames(3)
	check_eq(room.get_tree().get_nodes_in_group("natrium_pickups").filter(
		func(n: Node) -> bool: return not n.get("consumed")).size(), 4, "key 3 puts them back")


func test_the_hud_shows_natrium_pinned_and_swell_timers() -> void:
	await open_room()
	await _quiet()
	await frames(3)
	check("Sodium (나트륨): 0 / 7" in _hud(), "readout x/7: " + _hud())
	check("Special: - (nothing in range)" in _hud(), "no target")
	check("Pinned: -    Swelling: -" in _hud(), "no timers")
	var noodle: Node3D = dummy("NoodleDummy")
	var table_noodle: Node3D = dummy("NoodleTable")
	noodle.call("receive_attack", "water")
	table_noodle.call("receive_attack", "heavy_object", 1.0, {"pin_s": 6.0})
	await frames(30)
	var text: String = _hud()
	check("Swelling: NoodleDummy 1." in text, "swell timer: " + text)
	check("Pinned: NoodleTable 5." in text, "pin timer: " + text)


func test_a_dead_noodle_drops_its_spu_where_it_died_and_the_pickup_gives_two() -> void:
	await open_room()
	await _quiet()
	var noodle: Node3D = dummy("NoodleDummy")
	var at: Vector3 = noodle.global_position
	gs.drops._dry_kills["noodle_dummy"] = 4 # the protection makes this kill drop for sure
	noodle.call("debug_defeat")
	await frames(3)
	var loot: Array[Node] = room.get_tree().get_nodes_in_group("natrium_pickups").filter(
		func(n: Node) -> bool: return n.get("dropped") == true)
	check_eq(loot.size(), 1, "one drop on the floor")
	if loot.size() == 1:
		var pick: Node3D = loot[0] as Node3D
		check(absf(pick.global_position.x - at.x) < 0.05, "right where it died")
		check_eq(pick.get("amount"), 2, "the 스프: 나트륨 x2")
		teleport(at.x, 0.33)
		await frames(10)
		check_eq(gs.sodium, 2, "picked up: +2")
	await key_event(KEY_3)
	await frames(3)
	check_eq(room.get_tree().get_nodes_in_group("dropped_loot").size(), 0, "key 3 sweeps dropped loot away")


func test_a_dead_fried_dummy_may_leave_a_sauce_drip() -> void:
	await open_room()
	await _quiet()
	var fried: Node3D = dummy("FriedSmall")
	gs.drops._dry_kills["fried_small"] = 4
	fried.call("debug_defeat")
	await frames(3)
	var drips: Array[Node] = room.get_tree().get_nodes_in_group("dropped_loot")
	check_eq(drips.size(), 1, "one sauce drip")
	if drips.size() == 1:
		check(drips[0].get_script().resource_path == "res://items/sauce_drip.gd", "it is a sauce drip")
