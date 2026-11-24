extends "res://tests/base_test.gd"
## Task 3c-i-a, fast checks (no physics): the kitchen front section as layout data (tables, the floor lane
## to the open doorway, the 정수기, the stub and the end wall, the data checkpoint), the 간장 bottle's def
## and rows, its behaviour on a fresh instance (roll, squirts, empty, reset), the spawn choice (same seed,
## same spot; saved and restored; a new game may differ), the save round trip of the new keys, and the
## progress graph + lane rules for the new section. The real-input versions are in
## tests/physics/test_kitchen_front_run.gd.

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const ProgressGraphScript := preload("res://maps/layout/progress_graph.gd")
const SectionBuilderScript := preload("res://maps/layout/section_builder.gd")
const LaneRulesScript := preload("res://maps/layout/lane_rules.gd")
const DoorwayCurtainScript := preload("res://maps/layout/doorway_curtain.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const BottleDefScript := preload("res://items/bottle_def.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const SpawnPickScript := preload("res://systems/spawn_pick.gd")

const LAYOUT_PATH: String = "res://data/maps/ep01/map01_layout.tres"
const BOTTLE_SCENE: String = "res://items/ganjang_bottle.tscn"
const BOTTLE_DEF_PATH: String = "res://data/props/ganjang_bottle.tres"
const TABLE_PATH: String = "res://data/reaction_table.tres"
const TEMP_DIR := "user://test_tmp_kitchen"
const CHOICE: String = "ganjang_bottle"
const SPOTS: Array[String] = ["last_table", "floor_before_dispenser", "floor_mid"]

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


# --- Helpers ----------------------------------------------------------------------------------------

func _layout() -> MapLayoutScript:
	return load(LAYOUT_PATH) as MapLayoutScript


func _data() -> PrologueDataScript:
	return load("res://data/prologue/prologue.tres") as PrologueDataScript


func _wheel() -> EnemyDefScript:
	return load("res://data/enemies/danmuji.tres") as EnemyDefScript


func _reach() -> JumpReachScript:
	return JumpReachScript.new(load("res://data/movement_tuning.tres") as MovementTuningScript, _wheel(), _data().m_per_cm())


func _anchor() -> Dictionary:
	var d: PrologueDataScript = _data()
	return {"left": d.next_table_min_x, "right": d.next_table_max_x, "top": d.next_table_top_y,
		"thickness": d.dims().next_table_thickness_cm * d.m_per_cm()}


func _placed(layout: MapLayoutScript = null) -> Array[LayoutGeometryScript.Placed]:
	return LayoutGeometryScript.resolve(layout if layout != null else _layout(), _reach(), _anchor())


func _with(edit: Callable) -> MapLayoutScript:
	var copy: MapLayoutScript = _layout().duplicate(true) as MapLayoutScript
	edit.call(copy)
	return copy


func _kitchen() -> MapSectionScript:
	return _layout().section("kitchen_front")


func _bottle_entry(layout: MapLayoutScript = null) -> SpawnEntryScript:
	var l: MapLayoutScript = layout if layout != null else _layout()
	return l.section("kitchen_front").spawns[0]


func _mentions(lines: Array[String], needle: String) -> bool:
	for line: String in lines:
		if needle in line:
			return true
	return false


func _lane_depth() -> float:
	return _data().dims().counter_depth_cm * _data().m_per_cm()


## The map built the way the game builds it, in the tree. `state` gives the spawn choices their picks.
func _built(state: GameStateScript = null) -> SectionBuilderScript:
	await tree.process_frame # the root is only really in the tree once the first frame has run (a file run alone)
	var layout: MapLayoutScript = _layout()
	var builder: SectionBuilderScript = SectionBuilderScript.new()
	builder.game_state = state
	tree.root.add_child(builder)
	_nodes.append(builder)
	builder.build(layout, LayoutGeometryScript.resolve(layout, _reach(), _anchor()), _data().m_per_cm(), _lane_depth())
	return builder


func _state() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	return gs


## A bottle that never enters the scene tree (like the other enemy tests), with a GameState of its own.
func _bottle(state: GameStateScript) -> Node3D:
	var bottle: Node3D = (load(BOTTLE_SCENE) as PackedScene).instantiate() as Node3D
	_nodes.append(bottle)
	bottle.set("game_state", state)
	bottle.call("setup")
	return bottle


func _hit(bottle: Node3D, attack: String, dir: float = 1.0) -> Dictionary:
	return bottle.call("receive_attack", attack, dir)


# --- The section as data ----------------------------------------------------------------------------

func test_the_kitchen_front_goes_on_from_the_last_dining_table_and_the_whole_map_validates() -> void:
	var layout: MapLayoutScript = _layout()
	var reach: JumpReachScript = _reach()
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var ids: Array[String] = []
	for section: MapSectionScript in layout.sections:
		ids.append(section.id)
	check_eq(ids.back(), "kitchen_front", "the kitchen front is the last section")
	check_eq(layout.section("dining_room").end_wall_text, "", "the dining room's end wall is gone")
	var first: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kf_t1")
	var last_dining: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "r_t15")
	check_eq(first.prev, last_dining, "its first table is placed against the last dining-room table")
	check_eq(first.section_id, "kitchen_front", "in its own section")
	var problems: Array[String] = LayoutGeometryScript.validate(placed, reach, layout)
	check(problems.is_empty(), "layout problems:\n        " + "\n        ".join(problems))
	var stuck: Array[String] = ProgressGraphScript.problems(layout, placed, reach, _wheel())
	check(stuck.is_empty(), "progress problems (the whole map, kitchen front and stub included):\n        " + "\n        ".join(stuck))
	check(ProgressGraphScript.unreachable(layout, placed, reach, {}).is_empty(), "every table of the way is reachable")


func test_the_floor_lane_runs_on_to_the_doorway_and_a_stub_beyond_it() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var dining_lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_floor")
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kitchen_floor")
	check(lane != null and lane.def.kind == "floor", "a second floor lane")
	check_eq(lane.top, dining_lane.top, "at the same height as the dining floor")
	check(lane.left <= dining_lane.right and lane.right > dining_lane.right, "overlapping it, so he walks from one onto the other")
	var table: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kf_t2")
	var door: Resource = _kitchen().doorways[0]
	var door_x: float = LayoutGeometryScript.x_on(lane, door.along_m)
	var half: float = door.width_cm * _data().m_per_cm() * 0.5
	check(door_x - half > table.right, "the doorway is beyond the last table")
	check(lane.right > door_x + half + 5.0, "and a stub of floor goes on beyond it (%.1f m)" % (lane.right - door_x - half))
	var wall_after: String = _kitchen().end_wall_after
	check_eq(wall_after, "kitchen_floor", "the temporary end wall stands at the end of the stub")
	var builder: SectionBuilderScript = await _built()
	var wall: Node3D = builder.end_walls.get("kitchen_front")
	check(wall != null, "it is built")
	check(absf(wall.global_position.x - (lane.right + SectionBuilderScript.WALL_THICKNESS_M * 0.5)) < 0.01, "right at the end of the lane")
	check(builder.end_walls.get("dining_room") == null, "and the dining room has none")


func test_the_last_table_has_the_same_chair_route_down_as_the_others() -> void:
	var layout: MapLayoutScript = _layout()
	var mine: Resource = null
	var theirs: Resource = null
	for def: Resource in _kitchen().platforms:
		if def.id == "chair_kf_t2":
			mine = def
	for def: Resource in layout.section("dining_room").platforms:
		if def.id == "chair_r_t13":
			theirs = def
	check(mine != null, "stairs at the last table")
	check_eq(mine.host, "kf_t2", "against the last dining table")
	for property: String in ["kind", "steps", "length_cm", "side", "top_drop_cm", "bottom_rise_cm", "thickness_cm", "along_cm"]:
		check_eq(mine.get(property), theirs.get(property), "chair stairs: same " + property)
	# And the validation reaches the table from the floor.
	var problems: Array[String] = LayoutGeometryScript.validate(_placed(), _reach(), layout)
	check(not _mentions(problems, "floor lane"), "the climb-back graph is fine for both lanes: " + str(problems))


func test_a_data_checkpoint_at_the_section_start_comes_after_the_dining_steamer() -> void:
	var layout: MapLayoutScript = _layout()
	var cp: Resource = layout.find_checkpoint("kitchen_front_start")
	check(cp != null, "the checkpoint exists")
	check_eq(layout.section_of_checkpoint("kitchen_front_start").id, "kitchen_front", "in the kitchen front")
	check_eq(cp.platform_id, "kf_t1", "on the section's first table")
	var order: Array[String] = []
	for section: MapSectionScript in layout.sections:
		order.append(section.id)
	check(order.find(layout.section_of_respawn("kitchen_front_start").id) > order.find(layout.section_of_respawn("map01_dining_mid").id),
		"later than the 찜기 map01_dining_mid, so the respawn order stays right")
	check(layout.find_jjigi("map01_dining_mid") != null and layout.find_checkpoint("map01_dining_mid") == null, "which is still a 찜기")


func test_the_dispenser_is_a_gray_box_prop_with_an_id_that_is_not_solid() -> void:
	var fixture: Resource = _kitchen().fixtures[0]
	check_eq(fixture.id, "water_dispenser_1", "an id")
	check_eq(fixture.kind, "water_dispenser", "a data placement type a later task can extend")
	check(fixture.params is Dictionary, "with room for params")
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, fixture.platform_id)
	check_eq(lane.def.kind, "floor", "on the floor")
	var door: Resource = _kitchen().doorways[0]
	var dispenser_x: float = LayoutGeometryScript.x_on(lane, fixture.along_m)
	var door_x: float = LayoutGeometryScript.x_on(lane, door.along_m)
	var m: float = _data().m_per_cm()
	check(dispenser_x + fixture.width_cm * m * 0.5 < door_x - door.width_cm * m * 0.5, "directly in front of the doorway (before it, not in it)")
	check(door_x - dispenser_x < 12.0 * 1.745 * 2.0, "close to it (%.1f m)" % (door_x - dispenser_x))
	var builder: SectionBuilderScript = await _built()
	var node: Node3D = builder.fixture_nodes.get(fixture.id)
	check(node != null and node.name == "Fixture_water_dispenser_1", "built as a node named after its id")
	check(node.is_in_group("fixtures"), "a fixture")
	check(_collision_objects(node).is_empty(), "no collider: nothing to bump into")
	var meshes: int = 0
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			meshes += 1
	check(meshes >= 2, "gray-box meshes (%d)" % meshes)
	check(node.get_script() == null, "no behaviour yet (the pour comes in 3c-i-b)")


func _collision_objects(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	if node is CollisionObject3D or node is CollisionShape3D:
		out.append(node)
	for child: Node in node.get_children():
		out.append_array(_collision_objects(child))
	return out


# --- The doorway and its curtain --------------------------------------------------------------------

func test_the_doorway_is_open_and_its_curtain_hangs_above_his_head_by_default() -> void:
	var door: Resource = _kitchen().doorways[0]
	var m: float = _data().m_per_cm()
	var head: float = 0.96 # his capsule (player/ddeok.tscn); body_half_height * 2
	check(door.bottom_edge_cm * m > head, "the bottom edge (%.2f m) is above his head (%.2f m)" % [door.bottom_edge_cm * m, head])
	check(load("res://maps/layout/doorway_def.gd").new().bottom_edge_cm * m > head, "the def's own default too")
	check(door.height_cm > door.bottom_edge_cm, "the strips hang from the top, down to the bottom edge")
	var builder: SectionBuilderScript = await _built()
	var frame: Node3D = builder.doorway_nodes.get(door.id)
	var curtain: Node3D = builder.curtain_nodes.get(door.id)
	check(frame != null and curtain != null, "both are built")
	check(_collision_objects(frame).is_empty(), "no collider anywhere in the doorway: it is open, never locked")
	check_eq(curtain.call("strip_count"), door.strips, "the strips")
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(_placed(), door.platform_id)
	check(absf(float(curtain.call("bottom_edge_y")) - (lane.top + door.bottom_edge_cm * m)) < 0.001, "its bottom edge is the data's")
	var offenders: Array[String] = LaneRulesScript.offenders(builder, _lane_depth())
	check(offenders.is_empty(), "the lane rules are fine with the frame, the curtain and the dispenser:\n        " + "\n        ".join(offenders))


func test_the_curtain_sways_when_he_passes_and_settles_again() -> void:
	var builder: SectionBuilderScript = await _built()
	var door: Resource = _kitchen().doorways[0]
	var curtain: DoorwayCurtainScript = builder.curtain_nodes.get(door.id) as DoorwayCurtainScript
	var walker: CharacterBody3D = CharacterBody3D.new()
	tree.root.add_child(walker)
	_nodes.append(walker)
	curtain.player = walker
	for i: int in 5:
		curtain._physics_process(1.0 / 60.0)
	check(curtain.sway_amount() < 0.001, "still while nobody is near")
	walker.global_position = curtain.global_position + Vector3(0.0, 0.5, 0.0)
	walker.velocity = Vector3(5.5, 0.0, 0.0)
	var peak: float = 0.0
	for i: int in 30:
		curtain._physics_process(1.0 / 60.0)
		peak = maxf(peak, curtain.sway_amount())
	check(peak > 0.1, "the strips swing as he passes (%.2f rad)" % peak)
	check(peak <= door.sway_max_rad + 0.0001, "but not past their limit")
	walker.global_position = curtain.global_position + Vector3(40.0, 0.5, 0.0)
	walker.velocity = Vector3.ZERO
	for i: int in 240:
		curtain._physics_process(1.0 / 60.0)
	check(curtain.sway_amount() < 0.02, "and they settle (%.3f rad)" % curtain.sway_amount())


func test_the_doorway_check_fails_when_something_solid_is_in_the_opening() -> void:
	var layout: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		# The doorway moved to where the last chair step is, and people need more room to get by.
		l.section("kitchen_front").doorways[0].along_m = -30.0
		l.headroom_m = 1.5)
	var problems: Array[String] = ProgressGraphScript.scenery_problems(layout, _placed(layout), _reach())
	check(_mentions(problems, "not open"), "a chair step in the opening is found: " + str(problems))


# --- The bottle: def and table rows -----------------------------------------------------------------

func test_the_bottle_def_is_data_and_matches_its_placement() -> void:
	var def: BottleDefScript = load(BOTTLE_DEF_PATH) as BottleDefScript
	check(def != null, "the def loads")
	check_eq(def.squirts_max, 5, "squirts_max = 5")
	check_eq(def.sodium_per_squirt, 3, "sodium_per_squirt = 3")
	check_eq(def.contact_damage_half_hearts, 0, "harmless")
	check_eq(def.upright_material, "bottle_upright", "reads the standing row")
	check_eq(def.fallen_material, "bottle_fallen", "and the lying row")
	var entry: SpawnEntryScript = _bottle_entry()
	check_eq(entry.choice_width_cm, def.width_cm, "the placement's footprint is the def's width")
	check_eq(entry.choice_height_cm, def.height_cm, "and its height")
	check(entry.required_for_progress, "required_for_progress: it is the 나트륨 source for the 라면")
	check(entry.respawn_delay_s > 0.0, "with a respawn delay")
	check(def.height_cm * _data().m_per_cm() <= _reach().max_rise("jump"), "he can hop over it")
	var scene_def: Resource = (load(BOTTLE_SCENE) as PackedScene).instantiate().get("def")
	check_eq(scene_def, def, "the scene uses that def")


func test_the_table_rows_make_the_bottle_a_roll_to_knock_over_and_a_slam_or_stomp_to_squirt() -> void:
	var table: ReactionTableScript = load(TABLE_PATH) as ReactionTableScript
	check_eq(table.lookup("roll", "bottle_upright")["reaction"], "knock_over", "a roll knocks the standing bottle over (the 단무지's reaction)")
	check_eq(table.lookup("roll", "crunchy")["reaction"], "knock_over", "the same reaction as the 단무지")
	for attack: String in ["slam", "stomp", "landing", "sauce", "water", "heavy_object", "foot"]:
		check_eq(table.lookup(attack, "bottle_upright")["reaction"], "absorb", "standing: %s does nothing special" % attack)
	check_eq(table.lookup("slam", "bottle_fallen")["reaction"], "squirt", "lying: a slam squirts")
	check_eq(table.lookup("stomp", "bottle_fallen")["reaction"], "squirt", "lying: a stomp squirts")
	for attack: String in ["roll", "landing", "sauce", "water", "heavy_object", "foot"]:
		check_eq(table.lookup(attack, "bottle_fallen")["reaction"], "absorb", "lying: %s does nothing" % attack)


# --- The bottle on a fresh instance -----------------------------------------------------------------

func test_a_standing_bottle_is_a_harmless_solid_prop_nothing_but_a_roll_changes() -> void:
	var gs: GameStateScript = _state()
	var bottle: Node3D = _bottle(gs)
	check(bottle.call("is_harmless"), "harmless")
	check(not bottle.get("fallen"), "standing")
	check_eq(bottle.get("squirts_left"), 5, "five squirts")
	for attack: String in ["slam", "stomp", "landing"]:
		var result: Dictionary = _hit(bottle, attack)
		check_eq(result["reaction"], "absorb", "%s on the standing bottle does nothing special" % attack)
		check(not bottle.get("fallen"), "still standing after a %s" % attack)
	check_eq(bottle.get("squirts_done"), 0, "no squirt")
	check_eq(gs.sodium, 0, "no 나트륨")
	var shape: BoxShape3D = (bottle.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	var def: BottleDefScript = load(BOTTLE_DEF_PATH) as BottleDefScript
	var m: float = _data().m_per_cm()
	check(absf(shape.size.y - def.height_cm * m) < 0.001 and absf(shape.size.x - def.width_cm * m) < 0.001, "a box as tall as the def says")
	check(bottle.call("debug_defeat") == null and bottle.get("alive"), "'defeat all enemies' leaves it alone")


func test_a_roll_knocks_it_over_and_it_stays_over() -> void:
	var bottle: Node3D = _bottle(_state())
	var result: Dictionary = _hit(bottle, "roll", 1.0)
	check_eq(result["reaction"], "knock_over", "the roll's reaction")
	check(bottle.get("fallen") and bottle.get("alive"), "lying, not dead")
	check_eq(bottle.get("fall_dir"), 1.0, "nozzle toward the way the roll went")
	var def: BottleDefScript = load(BOTTLE_DEF_PATH) as BottleDefScript
	var m: float = _data().m_per_cm()
	var shape: BoxShape3D = (bottle.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	check(absf(shape.size.x - def.height_cm * m) < 0.001 and absf(shape.size.y - def.width_cm * m) < 0.001, "its body lies down: as long as it was tall")
	check(absf(float(bottle.get("body_height")) - def.width_cm * m) < 0.001, "and as high as it is wide")
	_hit(bottle, "roll", -1.0)
	_hit(bottle, "landing")
	check(bottle.get("fallen"), "nothing stands it up again")
	check_eq(bottle.get("squirts_left"), 5, "and a roll does not squirt")
	var other: Node3D = _bottle(_state())
	_hit(other, "roll", -1.0)
	check_eq(other.get("fall_dir"), -1.0, "rolled the other way, the nozzle points the other way")


func test_five_hits_squirt_three_each_and_the_sixth_does_nothing() -> void:
	var gs: GameStateScript = _state()
	var bottle: Node3D = _bottle(gs)
	_hit(bottle, "roll")
	var attacks: Array[String] = ["slam", "stomp", "slam", "stomp", "slam"]
	for i: int in 5:
		gs.sodium = 0
		var result: Dictionary = _hit(bottle, attacks[i])
		check_eq(result["reaction"], "squirt", "hit %d: squirt" % (i + 1))
		check_eq(gs.sodium, 3, "hit %d: +3 straight into GameState" % (i + 1))
		check_eq(bottle.get("squirts_left"), 4 - i, "hit %d: squirts left" % (i + 1))
	check_eq(bottle.get("sodium_given"), 15, "+15 in all")
	check_eq(bottle.get("squirts_done"), 5, "five squirts")
	gs.sodium = 0
	_hit(bottle, "slam")
	_hit(bottle, "stomp")
	check_eq(gs.sodium, 0, "empty: more hits give nothing")
	check_eq(bottle.get("sodium_given"), 15, "still 15")
	check_eq(bottle.get("squirts_done"), 5, "still five")
	check_eq(bottle.get("empty_hits"), 2, "the empty hits are counted (feedback)")


func test_the_sodium_cap_still_holds() -> void:
	var gs: GameStateScript = _state()
	var bottle: Node3D = _bottle(gs)
	_hit(bottle, "roll")
	for i: int in 5:
		_hit(bottle, "slam")
	check_eq(gs.sodium, GameStateScript.MAX_SODIUM, "without spending any, the bar is full at its cap (%d)" % GameStateScript.MAX_SODIUM)
	check_eq(bottle.get("sodium_given"), 15, "while the bottle gave all 15")


func test_starting_the_life_over_stands_the_bottle_up_with_five_squirts() -> void:
	var gs: GameStateScript = _state()
	var bottle: Node3D = _bottle(gs)
	_hit(bottle, "roll")
	_hit(bottle, "slam")
	_hit(bottle, "slam")
	bottle.call("reset") # what the debug key does; a respawn builds the section again (physics test)
	check(not bottle.get("fallen"), "upright again")
	check_eq(bottle.get("squirts_left"), 5, "with five squirts")
	check_eq(bottle.get("squirts_done"), 0, "and a clean count")
	check_eq(_hit(bottle, "slam")["reaction"], "absorb", "and a slam on it does nothing special again")


func test_nothing_of_the_bottle_is_saved() -> void:
	var gs: GameStateScript = _state()
	var bottle: Node3D = _bottle(gs)
	_hit(bottle, "roll")
	_hit(bottle, "slam")
	var saved: Dictionary = gs.to_dict()
	for key: String in saved:
		check(not ("squirt" in key or "bottle" in key or "fallen" in key), "no key for the bottle's state: " + key)


# --- The spawn choice -------------------------------------------------------------------------------

func test_the_bottle_has_at_least_the_table_and_the_floor_before_the_dispenser() -> void:
	var entry: SpawnEntryScript = _bottle_entry()
	check_eq(entry.choice_id, CHOICE, "the choice id")
	check_eq(entry.candidate_ids(), SPOTS, "the candidate spots, by stable id")
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var last_table: LayoutGeometryScript.Placed = null
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "table":
			last_table = p
	check_eq(entry.candidate("last_table").platform_id, last_table.def.id, "(a) on the last dining table")
	var before: Resource = entry.candidate("floor_before_dispenser")
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, before.platform_id)
	check_eq(lane.def.kind, "floor", "(b) on the floor lane")
	var dispenser: Resource = _kitchen().fixtures[0]
	check(LayoutGeometryScript.x_on(lane, before.along_m) < LayoutGeometryScript.x_on(lane, dispenser.along_m), "before the 정수기")
	var resolved: SpawnEntryScript = entry.resolved("floor_mid") as SpawnEntryScript
	check_eq(resolved.platform_id, "kitchen_floor", "a resolved copy names the spot's platform")
	check_eq(entry.platform_id, "", "and the data entry itself is left alone")


func test_every_candidate_is_reachable_and_legal() -> void:
	var problems: Array[String] = ProgressGraphScript.scenery_problems(_layout(), _placed(), _reach())
	check(problems.is_empty(), "scenery problems:\n        " + "\n        ".join(problems))
	# The check is not asleep: break each rule on a copy.
	var under_stairs: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_bottle_entry(l).candidate("floor_before_dispenser").along_m = -31.0) # under the bottom chair step
	check(_mentions(ProgressGraphScript.scenery_problems(under_stairs, _placed(under_stairs), _reach()), "too close over it"),
		"a spot under the chair steps is found")
	var off_table: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_bottle_entry(l).candidate("last_table").along_m = 20.0)
	check(_mentions(ProgressGraphScript.scenery_problems(off_table, _placed(off_table), _reach()), "does not fit"),
		"a spot off its table is found")
	var in_dispenser: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_bottle_entry(l).candidate("floor_before_dispenser").along_m = -22.0)
	check(_mentions(ProgressGraphScript.scenery_problems(in_dispenser, _placed(in_dispenser), _reach()), "inside fixture"),
		"a spot inside the 정수기 is found")
	var too_tall: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_bottle_entry(l).choice_height_cm = 30.0)
	check(_mentions(ProgressGraphScript.scenery_problems(too_tall, _placed(too_tall), _reach()), "hop over"),
		"a bottle he could not hop over is found")
	var lonely: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		var entry: SpawnEntryScript = _bottle_entry(l)
		entry.candidates.resize(1))
	check(_mentions(ProgressGraphScript.scenery_problems(lonely, _placed(lonely), _reach()), "at least two"),
		"a choice of one is found")
	var nowhere: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_bottle_entry(l).candidate("floor_mid").platform_id = "no_such")
	check(_mentions(ProgressGraphScript.scenery_problems(nowhere, _placed(nowhere), _reach()), "no platform"),
		"a spot on a platform that is not there is found")


func test_the_same_seed_gives_the_same_spot_and_every_spot_can_come_up() -> void:
	var seen: Dictionary = {}
	for seed_value: int in range(1, 200):
		var a: int = SpawnPickScript.pick_index(seed_value, CHOICE, 3)
		check_eq(SpawnPickScript.pick_index(seed_value, CHOICE, 3), a, "seed %d: same seed, same index" % seed_value)
		seen[a] = int(seen.get(a, 0)) + 1
	check_eq(seen.size(), 3, "all three spots come up over many seeds: " + str(seen))
	for count: int in seen.values():
		check(count > 30, "and none is rare (%d of 199)" % count)
	check_eq(SpawnPickScript.pick_index(5, CHOICE, 1), 0, "one spot: index 0")
	var first: GameStateScript = _state()
	first.game_seed = 4242
	var second: GameStateScript = _state()
	second.game_seed = 4242
	check_eq(first.spawn_pick(CHOICE, SPOTS), second.spawn_pick(CHOICE, SPOTS), "two games with one seed pick one spot")


func test_the_pick_is_made_once_kept_and_a_new_game_may_differ() -> void:
	var gs: GameStateScript = _state()
	check_eq(gs.game_seed, 0, "no seed until the first pick")
	var first: String = gs.spawn_pick(CHOICE, SPOTS)
	check(gs.game_seed != 0, "the first pick makes the seed")
	check(SPOTS.has(first), "a real spot: " + first)
	var seed_value: int = gs.game_seed
	for i: int in 10:
		check_eq(gs.spawn_pick(CHOICE, SPOTS), first, "asked again (a respawn, a rebuilt section): the same spot")
	check_eq(gs.game_seed, seed_value, "and the seed stays")
	check_eq(gs.spawn_picks, {CHOICE: first}, "the pick is on the books")
	var spots: Dictionary = {}
	for i: int in 40:
		gs.reset() # a new game
		check_eq(gs.spawn_picks.size(), 0, "a new game has no pick")
		check_eq(gs.game_seed, 0, "and no seed")
		spots[gs.spawn_pick(CHOICE, SPOTS)] = true
	check(spots.size() >= 2, "new games differ (%s)" % str(spots.keys()))


func test_a_saved_pick_that_is_not_a_candidate_any_more_is_picked_again() -> void:
	var gs: GameStateScript = _state()
	gs.spawn_picks = {CHOICE: "a_spot_that_was_removed"}
	gs.game_seed = 77
	var spot: String = gs.spawn_pick(CHOICE, SPOTS)
	check(SPOTS.has(spot), "picked from what exists: " + spot)
	check_eq(gs.spawn_picks[CHOICE], spot, "and kept")
	check_eq(gs.spawn_pick(CHOICE, [] as Array[String]), "", "no candidates, no spot")


func test_the_debug_override_forces_a_spot_and_is_never_saved() -> void:
	var gs: GameStateScript = _state()
	for spot: String in SPOTS:
		gs.debug_spawn_overrides = {CHOICE: spot}
		check_eq(gs.spawn_pick(CHOICE, SPOTS), spot, "forced: " + spot)
	check(not gs.to_dict().has("debug_spawn_overrides"), "not in the save")
	gs.debug_spawn_overrides = {CHOICE: "no_such_spot"}
	check(SPOTS.has(gs.spawn_pick(CHOICE, SPOTS)), "an unknown spot is ignored")
	check_eq(SpawnPickScript.cmdline_override(CHOICE), "", "no command line option given: none")


func test_the_builder_puts_the_bottle_on_the_picked_spot_each_time() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var entry: SpawnEntryScript = _bottle_entry()
	for spot: String in SPOTS:
		var gs: GameStateScript = _state()
		gs.debug_spawn_overrides = {CHOICE: spot}
		var builder: SectionBuilderScript = await _built(gs)
		var nodes: Array[Node3D] = builder.spawn_section("kitchen_front")
		check_eq(nodes.size(), 1, "%s: one bottle" % spot)
		var c: Resource = entry.candidate(spot)
		var want: Vector3 = LayoutGeometryScript.place_on(placed, c.platform_id, c.along_m, 0.02)
		check(nodes[0].global_position.distance_to(want) < 0.01, "%s: at its spot (%s, wanted %s)" % [spot, str(nodes[0].global_position), str(want)])
		check_eq((nodes[0].get_meta("entry") as SpawnEntryScript).platform_id, c.platform_id, "%s: the entry it carries is the resolved one" % spot)
		var again: Array[Node3D] = builder.spawn_section("kitchen_front")
		check(again[0].global_position.distance_to(want) < 0.01, "%s: built again (a respawn): the same spot" % spot)
		builder.queue_free()
	var plain: SectionBuilderScript = await _built(null)
	check_eq(plain.spawn_section("kitchen_front").size(), 1, "without a GameState the first spot is used")


# --- Saving the new keys ----------------------------------------------------------------------------

func _save() -> SaveSystemScript:
	var s: SaveSystemScript = SaveSystemScript.new()
	s.save_path = TEMP_DIR + "/slot_kitchen.json"
	_nodes.append(s)
	return s


func _clean(s: SaveSystemScript) -> void:
	DirAccess.remove_absolute(s.save_path)
	DirAccess.remove_absolute(TEMP_DIR)


func test_the_seed_and_the_pick_survive_a_save_and_a_load_and_the_version_stays_1() -> void:
	var s: SaveSystemScript = _save()
	var a: GameStateScript = _state()
	var spot: String = a.spawn_pick(CHOICE, SPOTS)
	var seed_value: int = a.game_seed
	check(s.save_game(a), "saved: " + s.last_error)
	check_eq(SaveSystemScript.SAVE_VERSION, 1, "save_version stays 1")
	var text: String = FileAccess.get_file_as_string(s.save_path)
	var root: Dictionary = JSON.parse_string(text)
	check_eq(int(root["save_version"]), 1, "in the file too")
	check(root["game"].has("game_seed") and root["game"].has("spawn_picks"), "additive keys")
	var b: GameStateScript = _state()
	check(s.load_game(b), "loaded: " + s.last_error)
	check_eq(b.game_seed, seed_value, "the seed is back")
	check_eq(b.spawn_picks, {CHOICE: spot}, "and the pick")
	check_eq(b.spawn_pick(CHOICE, SPOTS), spot, "so the reload keeps the spot")
	_clean(s)


func test_an_older_save_without_the_keys_loads_and_picks_a_spot() -> void:
	var s: SaveSystemScript = _save()
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	var f: FileAccess = FileAccess.open(s.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"save_version": 1, "game": {"hearts": 10}}))
	f.close()
	var gs: GameStateScript = _state()
	gs.spawn_picks = {CHOICE: "last_table"}
	gs.game_seed = 9
	check(s.load_game(gs), "loaded")
	check_eq(gs.hearts, 10, "the rest is read")
	check_eq(gs.game_seed, 0, "no seed: a default")
	check_eq(gs.spawn_picks.size(), 0, "no picks")
	check(SPOTS.has(gs.spawn_pick(CHOICE, SPOTS)), "and the choice is simply made now")
	_clean(s)


func test_bad_values_in_the_new_keys_fall_back_to_defaults() -> void:
	var gs: GameStateScript = _state()
	gs.from_dict({"game_seed": "oops", "spawn_picks": {"a": 5, "": "x", "b": "", "ok": "fine"}})
	check_eq(gs.game_seed, 0, "a wrong-typed seed")
	check_eq(gs.spawn_picks, {"ok": "fine"}, "only well-formed picks survive")
	gs.from_dict({"game_seed": -5, "spawn_picks": [1, 2]})
	check_eq(gs.game_seed, 0, "a negative seed")
	check_eq(gs.spawn_picks.size(), 0, "a list instead of a table of picks")
