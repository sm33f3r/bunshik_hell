extends "res://tests/base_test.gd"
## Task 3c-i-a-fix4, fast checks: the kitchen door on the back wall (data and built meshes), its lock
## flag (default, save, respawn), the progress graph with the door as a transition edge, the kitchen
## stub section, and --start-at=kitchen_start. Fresh instances only. Real input: physics/test_kitchen_door_run.gd.

const MapFlowScript := preload("res://maps/layout/map_flow.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const ProgressGraphScript := preload("res://maps/layout/progress_graph.gd")
const SectionBuilderScript := preload("res://maps/layout/section_builder.gd")
const LaneRulesScript := preload("res://maps/layout/lane_rules.gd")
const WallDoorScript := preload("res://maps/layout/wall_door.gd")
const DebugStartScript := preload("res://systems/debug_start.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")

const FLAG: String = "ramen1_defeated"
const TEMP_DIR := "user://test_tmp_kitchen_door"

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


# --- Helpers ----------------------------------------------------------------------------------------

func _layout() -> MapLayoutScript:
	return load(MapFlowScript.LAYOUT_PATH) as MapLayoutScript


func _with(edit: Callable) -> MapLayoutScript:
	var copy: MapLayoutScript = _layout().duplicate(true) as MapLayoutScript
	edit.call(copy)
	return copy


func _data() -> PrologueDataScript:
	return load("res://data/prologue/prologue.tres") as PrologueDataScript


func _m() -> float:
	return _data().m_per_cm()


func _reach() -> JumpReachScript:
	return JumpReachScript.new(load(MapFlowScript.TUNING_PATH), load(MapFlowScript.WHEEL_DEF_PATH), _m())


func _anchor() -> Dictionary:
	var d: PrologueDataScript = _data()
	return {"left": d.next_table_min_x, "right": d.next_table_max_x, "top": d.next_table_top_y,
		"thickness": d.dims().next_table_thickness_cm * d.m_per_cm()}


func _placed(layout: MapLayoutScript = null) -> Array[LayoutGeometryScript.Placed]:
	return LayoutGeometryScript.resolve(layout if layout != null else _layout(), _reach(), _anchor())


func _door(id: String = "kitchen_door", layout: MapLayoutScript = null) -> Resource:
	return (layout if layout != null else _layout()).find_fixture(id)


func _lane_depth() -> float:
	return _data().dims().counter_depth_cm * _m()


func _built(state: GameStateScript = null) -> SectionBuilderScript:
	await tree.process_frame
	var builder: SectionBuilderScript = SectionBuilderScript.new()
	builder.game_state = state
	tree.root.add_child(builder)
	_nodes.append(builder)
	builder.build(_layout(), _placed(), _m(), _lane_depth())
	return builder


func _state() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	return gs


func _box(node: Node) -> AABB:
	var mesh: MeshInstance3D = node as MeshInstance3D
	return mesh.global_transform * mesh.get_aabb()


## The bounds of every mesh under a node.
func _bounds(node: Node) -> AABB:
	var out: AABB = AABB()
	var first: bool = true
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		out = _box(child) if first else out.merge(_box(child))
		first = false
	return out


func _mentions(lines: Array[String], needle: String) -> bool:
	for line: String in lines:
		if needle in line:
			return true
	return false


# --- The door as data and as built ------------------------------------------------------------------

func test_the_door_is_about_five_times_the_dispenser_unit_and_stands_just_right_of_it() -> void:
	var builder: SectionBuilderScript = await _built()
	var dispenser: Node3D = builder.fixture_nodes.get("water_dispenser_1")
	# The unit itself (body and tank), not its back panel.
	var unit: AABB = _box(dispenser.get_node("Unit")).merge(_box(dispenser.get_node("Tank")))
	for door_id: String in ["kitchen_door", "kitchen_arrival_door"]:
		var def: Resource = _door(door_id)
		var node: Node3D = builder.fixture_nodes.get(door_id)
		check_eq(def.kind, "wall_door", door_id + ": a wall door")
		check_eq(def.size_ref_id, "water_dispenser_1", door_id + ": sized by the dispenser")
		check_eq(def.size_multiple, 5.0, door_id + ": five times")
		check_eq(def.zone_width_m, 2.0, door_id + ": a 2 m zone")
		var width: float = _box(node.get_node("Body/PostRight")).end.x - _box(node.get_node("Body/PostLeft")).position.x
		var height: float = _box(node.get_node("Body/Lintel")).end.y - node.global_position.y
		check(absf(width / unit.size.x - def.size_multiple) <= def.size_tolerance,
			"%s: %.2f x the unit's width (%.2f / %.2f m)" % [door_id, width / unit.size.x, width, unit.size.x])
		check(absf(height / unit.size.y - def.size_multiple) <= def.size_tolerance,
			"%s: %.2f x the unit's height (%.2f / %.2f m)" % [door_id, height / unit.size.y, height, unit.size.y])
		var wall: Node3D = builder.back_wall_nodes[_layout().section_of_fixture(door_id).id][0]
		check(_bounds(wall).end.y >= node.global_position.y + height, door_id + ": the wall goes up past the door")
		check(node.get_node_or_null("Body/Threshold") != null, door_id + ": a threshold")
	var door: Node3D = builder.fixture_nodes.get("kitchen_door")
	var frame_left: float = _box(door.get_node("Body/PostLeft")).position.x
	var gap: float = frame_left - unit.end.x
	check(absf(gap - 1.5) < 0.1, "1.5 m from the unit's right edge (%.2f)" % gap)
	check(frame_left > _box(dispenser.get_node("BackWall")).end.x, "clear of the dispenser's panel")
	var front: float = _box(door.get_node("Body/PostLeft")).end.z
	check(absf(front - _box(dispenser.get_node("BackWall")).end.z) < 0.01, "at the same depth as the 정수기's panel (%.2f)" % front)


## From the floor the camera never shows the lintel, not even panned all the way up.
func test_the_lintel_is_above_the_top_of_the_camera_view() -> void:
	var map: Node = (load("res://maps/ep01/map01_bunsikjip/map01.tscn") as PackedScene).instantiate()
	_nodes.append(map)
	var camera: Camera3D = map.get_node("SideCamera") as Camera3D
	var offset: Vector3 = camera.get("offset")
	var builder: SectionBuilderScript = await _built()
	for door_id: String in ["kitchen_door", "kitchen_arrival_door"]:
		var node: Node3D = builder.fixture_nodes.get(door_id)
		var lintel: AABB = _box(node.get_node("Body/Lintel"))
		# His middle is no more than 1 m over the floor he stands on.
		var view_top: float = node.global_position.y + 1.0 + offset.y + float(camera.get("look_pan")) \
			+ (offset.z - lintel.end.z) * tan(deg_to_rad(camera.fov * 0.5))
		check(lintel.position.y > view_top + 1.0, "%s: lintel from %.1f m, the view ends at %.1f m" % [door_id, lintel.position.y, view_top])


func test_nothing_of_the_door_is_solid_or_in_front_of_the_back_edge_of_the_lane() -> void:
	var builder: SectionBuilderScript = await _built()
	for node: Node3D in builder.door_nodes.values():
		check(node.is_in_group("fixtures"), "a fixture")
		check(node.find_children("*", "CollisionObject3D", true, false).is_empty(), "no body")
		check(node.find_children("*", "CollisionShape3D", true, false).is_empty(), "no collider")
		var body: AABB = _bounds(node.get_node("Body"))
		check(body.end.z <= -_lane_depth() * 0.5 + 0.001, "%s: wholly behind the lane (z up to %.2f)" % [node.name, body.end.z])


func test_the_door_replaces_the_wall_and_the_strips_hang_in_the_walls_plane() -> void:
	var builder: SectionBuilderScript = await _built()
	for door_id: String in ["kitchen_door", "kitchen_arrival_door"]:
		var node: Node3D = builder.fixture_nodes.get(door_id)
		var section: String = _layout().section_of_fixture(door_id).id
		var wall: Node3D = builder.back_wall_nodes[section][0]
		var def: Resource = _door(door_id)
		var half: float = (def.width_cm - def.post_cm * 2.0) * _m() * 0.5
		var x: float = node.global_position.x
		var opening: AABB = AABB(Vector3(x - half, node.global_position.y + 0.2, -50.0), Vector3(half * 2.0, 20.0, 100.0))
		var wall_front: float = 0.0
		for piece: Node in wall.get_children():
			if piece.name == "FloorSkirt":
				continue
			check(not _box(piece).intersects(opening), "%s: no wall in the opening (%s)" % [door_id, piece.name])
			wall_front = _box(piece).end.z
		var strips: int = 0
		for child: Node in node.get_node("Body").get_children():
			if not String(child.name).begins_with("Strip"):
				continue
			strips += 1
			var box: AABB = _box(child)
			check(box.end.z <= wall_front + 0.001 and box.position.z >= wall_front - 0.3, "%s %s: in the wall's plane" % [door_id, child.name])
		check_eq(strips, def.strips, door_id + ": the strips")
		check(_box(node.get_node("Body/Interior")).end.z < wall_front - 0.5, door_id + ": a dark room behind")


## 6 m past the door's right edge, so the end wall never covers the door's right jamb.
func test_the_dining_lane_ends_6_m_past_the_door_in_a_plain_wall() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kitchen_floor")
	var door_x: float = LayoutGeometryScript.item_x(placed, _door(), _layout())
	var after: float = lane.right - (door_x + _door().width_cm * _m() * 0.5)
	check(absf(after - 6.0) < 0.1, "%.2f m of floor after the door" % after)
	var builder: SectionBuilderScript = await _built()
	var wall: Node3D = builder.end_walls.get("kitchen_front")
	check(wall != null, "an end wall")
	check(wall.get_node_or_null("Sign") == null, "with no dev sign")
	# The arrival door is clear of the kitchen's left end, with room to its right.
	var room: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kitchen_room_floor")
	var arrival: Resource = _door("kitchen_arrival_door")
	var arrival_x: float = LayoutGeometryScript.item_x(placed, arrival, _layout())
	var half: float = arrival.width_cm * _m() * 0.5
	check(arrival_x - half - room.left > 2.0, "clear of the left end (%.2f m)" % (arrival_x - half - room.left))
	check(room.right - arrival_x - half > 20.0, "room to its right (%.2f m)" % (room.right - arrival_x - half))


# --- The kitchen stub -------------------------------------------------------------------------------

func test_the_kitchen_section_passes_the_layout_lane_rules_and_progress_graph() -> void:
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var section: Resource = layout.section("kitchen")
	check(section != null, "the section")
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kitchen_room_floor")
	var dining: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "kitchen_floor")
	check_eq(lane.top, dining.top, "the same floor height")
	check(lane.left - dining.right > 40.0, "a room of its own: %.1f m away" % (lane.left - dining.right))
	check(lane.right - lane.left < 50.0, "a short lane")
	check(LayoutGeometryScript.validate(placed, _reach(), layout).is_empty(), "layout: " + str(LayoutGeometryScript.validate(placed, _reach(), layout)))
	var problems: Array[String] = ProgressGraphScript.problems(layout, placed, _reach(), load(MapFlowScript.WHEEL_DEF_PATH))
	check(problems.is_empty(), "progress graph: " + str(problems))
	var builder: SectionBuilderScript = await _built()
	var offenders: Array[String] = LaneRulesScript.offenders(builder, _lane_depth())
	check(offenders.is_empty(), "lane rules:\n        " + "\n        ".join(offenders))
	var end_wall: Node3D = builder.end_walls.get("kitchen")
	check(end_wall != null and end_wall.get_node_or_null("Sign") != null, "a temporary end wall with a dev sign")
	check(absf(end_wall.global_position.x - lane.right - SectionBuilderScript.WALL_THICKNESS_M * 0.5) < 0.01, "at its right end")
	var arrival_x: float = LayoutGeometryScript.item_x(placed, _door("kitchen_arrival_door"), layout)
	check(arrival_x - lane.left < lane.right - arrival_x, "the arrival door is at the left end")
	var checkpoint: Resource = layout.find_checkpoint("kitchen_start")
	check(absf(LayoutGeometryScript.checkpoint_position(placed, checkpoint).x - arrival_x) < 0.01, "kitchen_start is at the arrival")
	# Without its door the room would be a floor with no way off it.
	var no_door: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		l.section("kitchen").fixtures.clear())
	check(_mentions(LayoutGeometryScript.validate(_placed(no_door), _reach(), no_door), "no way back up"), "the exemption is only for door rooms")


# --- The progress graph -----------------------------------------------------------------------------

func test_the_graph_treats_the_door_as_an_edge_that_needs_its_flag() -> void:
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var blocked: Array[String] = ProgressGraphScript.unreachable(layout, placed, _reach(), {})
	check(ProgressGraphScript.reachable_platforms(layout, placed, blocked).has("kitchen_room_floor"), "flag on: the kitchen is reached")
	check(not ProgressGraphScript.reachable_platforms(layout, placed, blocked, [FLAG] as Array[String]).has("kitchen_room_floor"), "flag off: it is not")
	var shut: Array[String] = ProgressGraphScript.door_problems(layout, placed, _reach(), [] as Array[String], [FLAG] as Array[String])
	check(_mentions(shut, "cannot be reached"), "and it says so: " + str(shut))


func test_a_flag_nothing_can_set_is_a_clear_error_unless_it_is_listed_or_set_by_code() -> void:
	check(_layout().flags_provided_later.has(FLAG), "allowlisted in the data for now")
	var bare: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		l.flags_provided_later = PackedStringArray())
	var problems: Array[String] = ProgressGraphScript.door_problems(bare, _placed(bare), _reach())
	check(_mentions(problems, "no code path can ever set it") and _mentions(problems, FLAG), str(problems))
	check(ProgressGraphScript.door_problems(bare, _placed(bare), _reach(), [FLAG] as Array[String]).is_empty(), "code that sets it is enough")
	check(_mentions(ProgressGraphScript.problems(bare, _placed(bare), _reach(), load(MapFlowScript.WHEEL_DEF_PATH)), "no code path"),
		"and the map's one check reports it")


func test_the_door_checks_catch_bad_data() -> void:
	var no_target: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_door("kitchen_door", l).target_door_id = "nowhere")
	check(_mentions(ProgressGraphScript.door_problems(no_target, _placed(no_target), _reach()), "is not a door"), "a bad target")
	var small: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_door("kitchen_door", l).height_cm = 37.0)
	check(_mentions(ProgressGraphScript.door_problems(small, _placed(small), _reach()), "the size of"), "a low door")
	var narrow: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_door("kitchen_door", l).width_cm = 19.0)
	check(_mentions(ProgressGraphScript.door_problems(narrow, _placed(narrow), _reach()), "the size of"), "a narrow door")
	var no_ref: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_door("kitchen_door", l).size_ref_id = "nothing")
	check(_mentions(ProgressGraphScript.door_problems(no_ref, _placed(no_ref), _reach()), "to size it by"), "nothing to size it by")
	var wide_zone: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_door("kitchen_door", l).zone_width_m = 8.0)
	check(_mentions(ProgressGraphScript.door_problems(wide_zone, _placed(wide_zone), _reach()), "zone"), "a huge zone")


# --- The flag ---------------------------------------------------------------------------------------

func test_the_lock_flag_is_true_by_default_from_one_place() -> void:
	check_eq(_door().locked_until_flag, FLAG, "the data names the flag")
	check_eq(_door("kitchen_arrival_door").locked_until_flag, "", "the way back is never locked")
	check_eq(GameStateScript.FLAG_DEFAULTS.get(FLAG), true, "true until the 라면 exists")
	var gs: GameStateScript = _state()
	check(gs.has_flag(FLAG), "a new game: set")
	check(not gs.has_flag("no_such_flag"), "an unknown flag is not")
	gs.set_flag(FLAG, false)
	check(not gs.has_flag(FLAG), "it can be set off")
	gs.reset()
	check(gs.has_flag(FLAG), "a new game starts over")
	gs.debug_flag_overrides[FLAG] = false
	check(not gs.has_flag(FLAG), "the debug override")
	check(not gs.to_dict()["flags"].has(FLAG), "which is never saved")


func test_the_flag_survives_death_a_save_and_a_load_and_the_version_stays_1() -> void:
	var s: SaveSystemScript = SaveSystemScript.new()
	_nodes.append(s)
	s.save_path = TEMP_DIR + "/slot.json"
	var a: GameStateScript = _state()
	a.set_flag(FLAG, false) # the value that differs from the default
	a.set_flag("other", true)
	a.take_damage(GameStateScript.MAX_HEARTS)
	a.respawn()
	check(not a.has_flag(FLAG) and a.has_flag("other"), "respawn keeps the flags")
	check(s.save_game(a), "saved: " + s.last_error)
	check_eq(SaveSystemScript.SAVE_VERSION, 1, "save_version stays 1")
	var b: GameStateScript = _state()
	check(s.load_game(b), "loaded: " + s.last_error)
	check(not b.has_flag(FLAG) and b.has_flag("other"), "and so does a save")
	b.from_dict({})
	check(b.has_flag(FLAG), "an older save without the key: the default")
	b.from_dict({"flags": {FLAG: "no", "x": 1, "": true}})
	check_eq(b.flags.size(), 0, "bad values are dropped")
	DirAccess.remove_absolute(s.save_path)
	DirAccess.remove_absolute(TEMP_DIR)


# --- The built door's behaviour ---------------------------------------------------------------------

func test_a_locked_door_shakes_and_shows_a_lock_and_an_open_one_asks_to_be_entered() -> void:
	var gs: GameStateScript = _state()
	var builder: SectionBuilderScript = await _built(gs)
	var door: WallDoorScript = builder.door_nodes["kitchen_door"]
	var asked: Array[String] = []
	door.enter_requested.connect(func(id: String) -> void: asked.append(id))
	check(not door.is_locked(), "open by default")
	check(door.try_enter(), "it asks")
	check_eq(asked, ["kitchen_door"] as Array[String], "with its id")
	gs.set_flag(FLAG, false)
	check(door.is_locked(), "locked with the flag off")
	check(not door.try_enter(), "it does not ask")
	check_eq(asked.size(), 1, "no second request")
	check(door.shaking() and door.lock_visible(), "feedback: shake and padlock")
	check(door.zone_contains(door.global_position.x + 0.9, door.global_position.y), "inside the zone")
	check(not door.zone_contains(door.global_position.x + 1.1, door.global_position.y), "outside it")
	check(not door.zone_contains(door.global_position.x, door.global_position.y + 2.0), "not from up in the air")
	check_eq(door.process_mode, Node.PROCESS_MODE_PAUSABLE, "not while a menu is open")


# --- --start-at -------------------------------------------------------------------------------------

func test_start_at_kitchen_start_is_a_new_game_in_the_kitchen() -> void:
	var got: Dictionary = DebugStartScript.parse(PackedStringArray(["--start-at=kitchen_start"]), _layout(), true)
	check_eq(got["id"], "kitchen_start", "accepted")
	var flow: MapFlowScript = MapFlowScript.new()
	_nodes.append(flow)
	flow.layout = _layout()
	flow.reach = _reach()
	flow.index_layout(_anchor())
	var gs: GameStateScript = _state()
	DebugStartScript.apply(gs, flow, "kitchen_start")
	check_eq(gs.checkpoint_id, "kitchen_start", "the respawn point")
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "kitchen_room_floor")
	check(gs.checkpoint_position.x > lane.left and gs.checkpoint_position.x < lane.right, "in the kitchen")
	check(gs.reached_checkpoints.has("kitchen_front_start"), "what is before it counts as reached")
	check(gs.has_skill("roll") and gs.tutorial_done, "past the tutorial")
