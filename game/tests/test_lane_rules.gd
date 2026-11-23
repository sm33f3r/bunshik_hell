extends "res://tests/base_test.gd"
## Task 3b-ii-fix, item 2: no decor in the character lane. Table legs and chair legs are not colliders,
## so a character that walked past them would walk through them like a ghost: they stand behind the
## lane (PlatformDef.decor_layer). The validator lists every offender in a built scene (Map 1's
## tables and chairs, and the prologue's set).

const LaneRulesScript := preload("res://maps/layout/lane_rules.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const SectionBuilderScript := preload("res://maps/layout/section_builder.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")

const LAYOUT_PATH: String = "res://data/maps/ep01/map01_layout.tres"

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _data() -> PrologueDataScript:
	return load("res://data/prologue/prologue.tres") as PrologueDataScript


func _lane_depth() -> float:
	return _data().dims().counter_depth_cm * _data().m_per_cm()


## Map 1's platforms built the way the game builds them, in the tree.
func _built_map() -> SectionBuilderScript:
	var d: PrologueDataScript = _data()
	var layout: MapLayoutScript = load(LAYOUT_PATH) as MapLayoutScript
	var reach: JumpReachScript = JumpReachScript.new(load("res://data/movement_tuning.tres") as MovementTuningScript,
		load("res://data/enemies/danmuji.tres") as EnemyDefScript, d.m_per_cm())
	var anchor: Dictionary = {"left": d.next_table_min_x, "right": d.next_table_max_x, "top": d.next_table_top_y,
		"thickness": d.dims().next_table_thickness_cm * d.m_per_cm()}
	var builder: SectionBuilderScript = SectionBuilderScript.new()
	tree.root.add_child(builder)
	_nodes.append(builder)
	builder.build(layout, LayoutGeometryScript.resolve(layout, reach, anchor), d.m_per_cm(), _lane_depth())
	return builder


func _built_set() -> PrologueSetScript:
	var set_node: PrologueSetScript = PrologueSetScript.new()
	tree.root.add_child(set_node)
	_nodes.append(set_node)
	set_node.build(_data())
	return set_node


func _mesh_at(parent: Node3D, mesh_name: String, size: Vector3, at: Vector3) -> MeshInstance3D:
	return PrologueSetScript.add_mesh(parent, mesh_name, PrologueSetScript.box_mesh(size), Color.WHITE, at)


# --- The rule ---------------------------------------------------------------------------------------

func test_a_platform_def_names_the_layer_its_decor_stands_in() -> void:
	var def: PlatformDefScript = PlatformDefScript.new()
	check_eq(def.decor_layer, "behind", "decor stands behind the lane unless the data says otherwise")
	check(def.decor_gap_cm >= 0.0 and def.leg_width_cm > 0.0 and def.leg_depth_cm > 0.0, "gap and leg size are data")


func test_decor_z_puts_a_piece_just_outside_the_lane() -> void:
	var z: float = LaneRulesScript.decor_z("behind", 7.0, 0.2, 0.6)
	check(absf(z - -(3.5 + 0.2 + 0.3)) < 0.0001, "behind: centre %.2f" % z)
	check(z + 0.3 <= -3.5, "its front face is behind the lane's back edge")
	check(LaneRulesScript.decor_z("front", 7.0, 0.2, 0.6) > 3.5, "front: past the lane's front edge")


func test_the_validator_lists_a_leg_in_the_lane_and_accepts_one_behind() -> void:
	var root: Node3D = Node3D.new()
	tree.root.add_child(root)
	_nodes.append(root)
	_mesh_at(root, "LegInTheLane", Vector3(0.6, 5.0, 0.6), Vector3(0.0, 0.0, 0.0))
	_mesh_at(root, "LegHalfIn", Vector3(0.6, 5.0, 0.6), Vector3(3.0, 0.0, -3.4))
	_mesh_at(root, "LegBehind", Vector3(0.6, 5.0, 0.6), Vector3(6.0, 0.0, -4.0))
	var found: Array[String] = LaneRulesScript.offenders(root, 7.0)
	check_eq(found.size(), 2, "two offenders: " + str(found))
	var text: String = " ".join(found)
	check("LegInTheLane" in text and "LegHalfIn" in text and "LegBehind" not in text, "the right ones: " + text)
	check(not LaneRulesScript.offenders(root, 7.0, 100.0).is_empty(), "a foreground allowance does not excuse a piece in the lane")


func test_a_foreground_piece_is_allowed_only_in_front_and_low() -> void:
	var root: Node3D = Node3D.new()
	tree.root.add_child(root)
	_nodes.append(root)
	_mesh_at(root, "LowInFront", Vector3(1.0, 1.0, 1.0), Vector3(0.0, 2.0, 5.0))
	_mesh_at(root, "HighInFront", Vector3(1.0, 1.0, 1.0), Vector3(3.0, 20.0, 5.0))
	check_eq(LaneRulesScript.offenders(root, 7.0).size(), 2, "with no foreground allowed both are offenders")
	var found: Array[String] = LaneRulesScript.offenders(root, 7.0, 10.0)
	check_eq(found.size(), 1, "with a limit only the high one is: " + str(found))
	check("HighInFront" in found[0], "the high one: " + found[0])


func test_a_mesh_that_is_a_colliders_picture_is_not_decor() -> void:
	var root: Node3D = Node3D.new()
	tree.root.add_child(root)
	_nodes.append(root)
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.0, 1.0, 7.0)
	shape.shape = box
	body.add_child(shape)
	root.add_child(body)
	_mesh_at(body, "Picture", Vector3(4.0, 1.0, 7.0), Vector3.ZERO)
	check(LaneRulesScript.offenders(root, 7.0).is_empty(), "the table top's own mesh is fine")
	_mesh_at(body, "LegUnderIt", Vector3(0.6, 9.0, 0.6), Vector3(0.0, -5.0, 0.0))
	var found: Array[String] = LaneRulesScript.offenders(root, 7.0)
	check_eq(found.size(), 1, "but a leg under it, in the lane, is: " + str(found))


func test_hazards_and_enemies_are_not_decor() -> void:
	var root: Node3D = Node3D.new()
	tree.root.add_child(root)
	_nodes.append(root)
	var hazard: Node3D = Node3D.new()
	hazard.add_to_group("hazards")
	root.add_child(hazard)
	_mesh_at(hazard, "Foot", Vector3(1.0, 1.0, 1.0), Vector3.ZERO)
	check(LaneRulesScript.offenders(root, 7.0).is_empty(), "a thing he interacts with is allowed in the lane")


# --- The real scenes -----------------------------------------------------------------------------------

func test_no_table_or_chair_leg_of_map_1_is_in_the_lane() -> void:
	var builder: SectionBuilderScript = _built_map()
	var found: Array[String] = LaneRulesScript.offenders(builder, _lane_depth())
	check(found.is_empty(), "offenders: " + "\n".join(found))
	var legs: int = 0
	for node_name: Variant in builder.platform_nodes:
		var body: Node = builder.platform_nodes[node_name]
		for child: Node in body.get_children():
			if child.name.begins_with("Leg"):
				legs += 1
				var box: AABB = (child as MeshInstance3D).global_transform * (child as MeshInstance3D).get_aabb()
				check(box.end.z <= -_lane_depth() * 0.5 + 0.001, "%s of %s is behind the lane (z up to %.2f)" % [child.name, node_name, box.end.z])
	check(legs >= 40, "there are legs to check (%d)" % legs)


func test_every_table_has_two_legs_and_every_chair_step_one_all_behind() -> void:
	var builder: SectionBuilderScript = _built_map()
	var tables: int = 0
	var seats: int = 0
	for p: LayoutGeometryScript.Placed in builder.placed:
		var body: Node = builder.platform_nodes.get(p.def.id)
		if body == null:
			continue
		if p.def.kind == "table":
			tables += 1
			check(body.get_node_or_null("Leg0") != null and body.get_node_or_null("Leg1") != null, "%s has two legs" % p.def.id)
		elif p.def.kind == "block":
			seats += 1
			check(body.get_node_or_null("Leg0") != null, "%s has a leg" % p.def.id)
	check(tables > 20 and seats > 20, "tables %d, chair steps %d" % [tables, seats])


func test_the_legs_do_not_change_what_is_solid() -> void:
	var builder: SectionBuilderScript = _built_map()
	for node_name: Variant in builder.platform_nodes:
		var body: StaticBody3D = builder.platform_nodes[node_name] as StaticBody3D
		var shapes: int = 0
		for child: Node in body.get_children():
			if child is CollisionShape3D:
				shapes += 1
		check_eq(shapes, 1, "%s: exactly its own collision box, the legs are pictures only" % node_name)


func test_the_prologue_set_has_nothing_in_the_lane_that_is_not_solid() -> void:
	var set_node: PrologueSetScript = _built_set()
	var limit: float = _data().counter_top_y - LaneRulesScript.FRONT_CLEARANCE_M
	var found: Array[String] = LaneRulesScript.offenders(set_node, _lane_depth(), limit)
	check(found.is_empty(), "offenders: " + "\n".join(found))
	for leg_name: String in ["NextTableLeg0", "NextTableLeg1"]:
		var leg: Node3D = set_node.get_node("Level/" + leg_name) as Node3D
		check(leg.global_position.z < -_lane_depth() * 0.5, "%s is behind the lane" % leg_name)
	var stool: Node3D = set_node.get_node("Level/Stool_0") as Node3D
	check(stool.global_position.z > _lane_depth() * 0.5, "the stools are a foreground layer in front of it")
