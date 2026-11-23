extends Node3D
## The Map 1 prologue set at real size: her window counter, the props on it, the next table, her
## forearm and the shop around it. Every size comes from the real-centimetre table
## (SetDimensions) times the world scale, via PrologueData; nothing here is a hand-typed
## game-metre number. Gray box. Built in code from data, so there is no scene to keep in step.
##
## Node names are part of the contract (the tests and the map script look things up by name):
##   Level/Floor, Level/Counter, Level/NextTable   StaticBody3D (solid, layer WORLD)
##   Props/Cup, Props/Plate, Props/NapkinBox, Props/SpoonHolder   StaticBody3D (solid)
##   Exit/WallLeft   invisible wall at the left end of her counter (always there)
##   Exit/Forearm    her other forearm: a tall invisible wall plus the arm; gone once the exit opens

const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const SetDimensionsScript := preload("res://prologue/set_dimensions.gd")
const Layers := preload("res://systems/layers.gd")
const LaneRulesScript := preload("res://maps/layout/lane_rules.gd")

const WALL_HEIGHT_M: float = 40.0
const WALL_THICKNESS_M: float = 0.6
## The forearm lies this far (metres) in front of the counter middle, so it covers the 떡's plane.
const FOREARM_Z_CENTER: float = 0.75

var data: PrologueDataScript
var m: float = 0.0

var _forearm: StaticBody3D
var _forearm_shape: CollisionShape3D
var _forearm_arm: Node3D
var _forearm_rest: Vector3
var _yank_t: float = -1.0
var _exit_open: bool = false
var _built: bool = false


func build(p_data: PrologueDataScript) -> void:
	if _built:
		return
	_built = true
	data = p_data
	m = data.m_per_cm()
	var level: Node3D = _group("Level")
	var props: Node3D = _group("Props")
	var exit: Node3D = _group("Exit")
	_build_shop(level)
	_build_counter(level)
	_build_props(props)
	_build_exit(level, exit)
	_build_lights()


func _group(group_name: String) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = group_name
	add_child(node)
	return node


# --- Small builders -------------------------------------------------------------------------------

static func material(color: Color, emissive: float = 0.0) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emissive > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emissive
	return mat


static func add_mesh(parent: Node3D, mesh_name: String, mesh: Mesh, color: Color, at: Vector3) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	parent.add_child(instance)
	return instance


static func box_mesh(size: Vector3) -> BoxMesh:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return mesh


## A box with a mesh, and a solid StaticBody3D around it when `solid`.
func _box(parent: Node3D, box_name: String, size: Vector3, at: Vector3, color: Color, solid: bool) -> Node3D:
	var root: Node3D
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.name = "CollisionShape3D"
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		root = body
	else:
		root = Node3D.new()
	root.name = box_name
	root.position = at
	add_mesh(root, "Mesh", box_mesh(size), color, Vector3.ZERO)
	parent.add_child(root)
	return root


func _solid_cylinder(parent: Node3D, cyl_name: String, radius: float, height: float, at: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = cyl_name
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = at
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	parent.add_child(body)
	return body


static func cylinder_mesh(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 24
	return mesh


# --- The shop ----------------------------------------------------------------------------------------

func _build_shop(level: Node3D) -> void:
	var d: SetDimensionsScript = data.dims()
	var min_x: float = d.shop_floor_min_x_cm * m
	var max_x: float = d.shop_floor_max_x_cm * m
	var depth: float = 400.0 * m
	var floor_node: Node3D = _box(level, "Floor", Vector3(max_x - min_x, 1.0, depth),
		Vector3((min_x + max_x) * 0.5, -0.5, 0.0), Color(0.78, 0.74, 0.68), true)
	floor_node.name = "Floor"
	var wall_z: float = d.back_wall_z_cm * m
	_box(level, "BackWall", Vector3(max_x - min_x, 220.0 * m, 0.4), Vector3((min_x + max_x) * 0.5, 110.0 * m, wall_z - 0.2),
		Color(0.92, 0.88, 0.8), false)
	# The window behind her counter.
	var counter_len: float = data.counter_length_m
	_box(level, "Window", Vector3(counter_len + 20.0 * m, 70.0 * m, 0.2), Vector3(counter_len * 0.5, 130.0 * m, wall_z + 0.1),
		Color(0.74, 0.88, 0.98), false)
	for i: int in 4:
		_box(level, "WindowBar%d" % i, Vector3(0.5, 70.0 * m, 0.25), Vector3(counter_len * float(i) / 3.0, 130.0 * m, wall_z + 0.15),
			Color(0.35, 0.3, 0.28), false)
	# The menu board and the kitchen pass-through (only seen in the cutscene).
	var board: Node3D = _box(level, "MenuBoard", Vector3(150.0 * m, 45.0 * m, 0.2), Vector3(d.menu_board_x_cm * m, 140.0 * m, wall_z + 0.1),
		Color(0.18, 0.22, 0.2), false)
	var label: Label3D = Label3D.new()
	label.name = "Label3D"
	label.text = "메뉴   김밥   떡볶이   라면   만두   순대"
	label.pixel_size = 0.04
	label.font_size = 64
	label.modulate = Color(0.95, 0.92, 0.8)
	label.position = Vector3(0.0, 0.0, 0.15)
	board.add_child(label)
	_box(level, "KitchenWall", Vector3(220.0 * m, 220.0 * m, 0.4), Vector3(d.kitchen_x_cm * m, 110.0 * m, wall_z - 0.1),
		Color(0.75, 0.75, 0.72), false)
	_box(level, "PassThrough", Vector3(120.0 * m, 40.0 * m, 0.2), Vector3(d.kitchen_x_cm * m, 125.0 * m, wall_z + 0.15),
		Color(1.0, 0.7, 0.35), false)
	_box(level, "PassCounter", Vector3(130.0 * m, 4.0 * m, 25.0 * m), Vector3(d.kitchen_x_cm * m, 105.0 * m, wall_z + 25.0 * m * 0.5),
		Color(0.6, 0.6, 0.62), false)
	# Dining tables (decor).
	for i: int in d.dining_table_x_cm.size():
		var x: float = d.dining_table_x_cm[i] * m
		var table: Node3D = Node3D.new()
		table.name = "DiningTable_%d" % i
		table.position = Vector3(x, 0.0, d.dining_table_z_cm * m)
		level.add_child(table)
		add_mesh(table, "Top", box_mesh(Vector3(d.dining_table_width_cm * m, 3.0 * m, d.dining_table_depth_cm * m)),
			Color(0.62, 0.45, 0.28), Vector3(0.0, (d.counter_top_height_cm - 1.5) * m, 0.0))
		add_mesh(table, "Leg", box_mesh(Vector3(4.0 * m, (d.counter_top_height_cm - 3.0) * m, 4.0 * m)),
			Color(0.5, 0.5, 0.55), Vector3(0.0, (d.counter_top_height_cm - 3.0) * m * 0.5, 0.0))


func _build_counter(level: Node3D) -> void:
	var d: SetDimensionsScript = data.dims()
	var top: float = data.counter_top_y
	var length: float = data.counter_length_m
	var depth: float = d.counter_depth_cm * m
	var counter: Node3D = _box(level, "Counter", Vector3(length, top, depth), Vector3(length * 0.5, top * 0.5, 0.0),
		Color(0.6, 0.4, 0.25), true)
	# The lighter top strip is part of the counter's own picture (a child of its collider), not a separate prop.
	add_mesh(counter, "CounterEdge", box_mesh(Vector3(length, 0.04, depth + 0.02)), Color(0.8, 0.62, 0.4), Vector3(0.0, top * 0.5 - 0.01, 0.0))
	# Stools in front of the counter (decor): seat width is the real 35 cm.
	var seat_w: float = d.stool_seat_width_cm * m
	var seat_h: float = d.stool_seat_height_cm * m
	var stool_z: float = depth * 0.5 + seat_w * 0.5 + 8.0 * m
	for i: int in 3:
		var stool: Node3D = Node3D.new()
		stool.name = "Stool_%d" % i
		stool.position = Vector3(length * (0.18 + 0.32 * float(i)), 0.0, stool_z)
		level.add_child(stool)
		add_mesh(stool, "Seat", cylinder_mesh(seat_w * 0.5, seat_w * 0.5, 4.0 * m), Color(0.7, 0.2, 0.18), Vector3(0.0, seat_h - 2.0 * m, 0.0))
		add_mesh(stool, "Leg", cylinder_mesh(1.2 * m, 1.2 * m, seat_h - 4.0 * m), Color(0.55, 0.55, 0.6), Vector3(0.0, (seat_h - 4.0 * m) * 0.5, 0.0))


# --- Props on her counter -------------------------------------------------------------------------------

func _build_props(props: Node3D) -> void:
	var d: SetDimensionsScript = data.dims()
	var top: float = data.counter_top_y
	# The paper cup with the 떡볶이 sauce on top.
	var cup_h: float = d.cup_height_cm * m
	var cup_r: float = d.cup_width_cm * m * 0.5
	var cup: StaticBody3D = _solid_cylinder(props, "Cup", cup_r * 0.875, cup_h, Vector3(data.cup_x, top + cup_h * 0.5, 0.0))
	add_mesh(cup, "Body", cylinder_mesh(cup_r, cup_r * 0.75, cup_h), Color(0.97, 0.95, 0.92), Vector3.ZERO)
	add_mesh(cup, "Sauce", cylinder_mesh(cup_r * 0.93, cup_r * 0.93, 0.03), Color(0.85, 0.2, 0.1), Vector3(0.0, cup_h * 0.5 - 0.015, 0.0))
	add_mesh(cup, "Stripe", cylinder_mesh(cup_r * 0.88, cup_r * 0.82, cup_h * 0.2), Color(0.85, 0.15, 0.1), Vector3(0.0, -cup_h * 0.2, 0.0))
	# The plate the 만두 start on.
	var plate_h: float = d.plate_height_cm * m
	var plate_r: float = d.plate_width_cm * m * 0.5
	var plate: StaticBody3D = _solid_cylinder(props, "Plate", plate_r, plate_h, Vector3(data.plate_x, top + plate_h * 0.5, 0.0))
	add_mesh(plate, "Dish", cylinder_mesh(plate_r, plate_r * 0.92, plate_h), Color(0.96, 0.96, 0.98), Vector3.ZERO)
	# The napkin box: 12 x 10 x 8 cm, standing in her plane so it can be bumped into and climbed.
	var napkin: Vector3 = d.napkin_box_cm * m
	var napkin_node: Node3D = _box(props, "NapkinBox", napkin, Vector3(d.napkin_x_cm * m, top + napkin.y * 0.5, 0.0),
		Color(0.85, 0.85, 0.88), true)
	add_mesh(napkin_node, "Slot", box_mesh(Vector3(napkin.x * 0.7, 0.04, napkin.z * 0.15)), Color(0.4, 0.4, 0.45), Vector3(0.0, napkin.y * 0.5 + 0.0, 0.0))
	# The spoon-and-chopstick holder: 12 cm tall.
	var holder_h: float = d.spoon_holder_height_cm * m
	var holder_r: float = d.spoon_holder_width_cm * m * 0.5
	var holder: StaticBody3D = _solid_cylinder(props, "SpoonHolder", holder_r, holder_h, Vector3(d.spoon_holder_x_cm * m, top + holder_h * 0.5, 0.0))
	add_mesh(holder, "Can", cylinder_mesh(holder_r, holder_r, holder_h), Color(0.7, 0.72, 0.76), Vector3.ZERO)
	for i: int in 3:
		var u: float = float(i - 1)
		# Inside the can's own bounds: a utensil sticking out of it would be decor standing in the lane.
		add_mesh(holder, "Utensil%d" % i, box_mesh(Vector3(0.16, holder_h * 0.35, 0.1)), Color(0.85, 0.66, 0.38),
			Vector3(u * holder_r * 0.5, holder_h * 0.5 - holder_h * 0.175, 0.0))


## Where the live 만두 start: spread over her plate, standing on it.
func plate_spawn_points(count: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var plate_h: float = data.dims().plate_height_cm * m
	var plate_r: float = data.dims().plate_width_cm * m * 0.5
	var mandu_w: float = data.dims().mandu_width_cm * m
	var span: float = maxf(plate_r * 2.0 - mandu_w * 1.2, 0.0)
	for i: int in count:
		var u: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		out.append(Vector3(data.plate_x - span * 0.5 + span * u, data.counter_top_y + plate_h + 0.02, 0.0))
	return out


# --- Exit: the forearm, the left wall and the next table ---------------------------------------------

func _build_exit(level: Node3D, exit: Node3D) -> void:
	var d: SetDimensionsScript = data.dims()
	var top: float = data.counter_top_y
	var depth: float = d.counter_depth_cm * m
	# The invisible wall at the left end of her counter (always there).
	var wall: StaticBody3D = StaticBody3D.new()
	wall.name = "WallLeft"
	wall.collision_layer = Layers.WORLD
	wall.collision_mask = 0
	wall.position = Vector3(-WALL_THICKNESS_M * 0.5, top + WALL_HEIGHT_M * 0.5, 0.0)
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	wall_shape.name = "CollisionShape3D"
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(WALL_THICKNESS_M, WALL_HEIGHT_M, depth + 4.0)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	exit.add_child(wall)
	# Her forearm: a solid, tall wall (so he cannot jump it) with the arm drawn on it.
	var width: float = d.forearm_width_cm * m
	var center_x: float = (data.forearm_left_x + data.forearm_right_x) * 0.5
	_forearm = StaticBody3D.new()
	_forearm.name = "Forearm"
	_forearm.collision_layer = Layers.WORLD
	_forearm.collision_mask = 0
	_forearm.position = Vector3(center_x, top, 0.0)
	_forearm_shape = CollisionShape3D.new()
	_forearm_shape.name = "CollisionShape3D"
	var arm_box: BoxShape3D = BoxShape3D.new()
	arm_box.size = Vector3(width, WALL_HEIGHT_M, depth + 4.0)
	_forearm_shape.shape = arm_box
	_forearm_shape.position = Vector3(0.0, WALL_HEIGHT_M * 0.5, 0.0)
	_forearm.add_child(_forearm_shape)
	_forearm_arm = Node3D.new()
	_forearm_arm.name = "Arm"
	_forearm.add_child(_forearm_arm)
	_forearm_rest = Vector3(0.0, width * 0.5, FOREARM_Z_CENTER)
	_forearm_arm.position = _forearm_rest
	var arm_mesh: CapsuleMesh = CapsuleMesh.new()
	arm_mesh.radius = width * 0.5
	arm_mesh.height = d.forearm_length_cm * m
	var skin: MeshInstance3D = add_mesh(_forearm_arm, "Skin", arm_mesh, Color(0.93, 0.76, 0.66), Vector3.ZERO)
	skin.rotation.x = PI * 0.5 # lying along z, across the counter
	var sleeve: MeshInstance3D = add_mesh(_forearm_arm, "Sleeve", cylinder_mesh(width * 0.56, width * 0.56, 0.9), Color(0.35, 0.4, 0.6), Vector3(0.0, 0.0, d.forearm_length_cm * m * 0.4))
	sleeve.rotation.x = PI * 0.5
	exit.add_child(_forearm)
	# The next table: the same height as her counter, a short jump away.
	var len: float = d.next_table_length_cm * m
	var thick: float = d.next_table_thickness_cm * m
	var table_depth: float = depth
	_box(level, "NextTable", Vector3(len, thick, table_depth), Vector3(data.next_table_min_x + len * 0.5, top - thick * 0.5, 0.0),
		Color(0.45, 0.6, 0.45), true)
	for i: int in 2:
		var leg_x: float = data.next_table_min_x + (0.06 + 0.88 * float(i)) * len
		# Decor, so behind the character lane (the table's depth), never in it.
		var leg_z: float = LaneRulesScript.decor_z("behind", table_depth, 1.0 * m, 0.6)
		_box(level, "NextTableLeg%d" % i, Vector3(0.6, top - thick, 0.6), Vector3(leg_x, (top - thick) * 0.5, leg_z),
			Color(0.4, 0.5, 0.4), false)


## true: she yanks her forearm away and the way opens. false: the forearm lies there again.
func set_exit_open(open: bool) -> void:
	_exit_open = open
	if _forearm_shape == null:
		return
	if _forearm_shape.is_inside_tree():
		_forearm_shape.set_deferred("disabled", open)
	else:
		_forearm_shape.disabled = open
	if open:
		_yank_t = 0.0
	else:
		_yank_t = -1.0
		_forearm_arm.position = _forearm_rest
		_forearm_arm.visible = true


## While true the forearm blocks the way (the wall is solid).
func forearm_blocking() -> bool:
	return _forearm_shape != null and not _forearm_shape.disabled


func forearm_visible() -> bool:
	return _forearm_arm != null and _forearm_arm.visible


func _process(delta: float) -> void:
	if _yank_t < 0.0:
		return
	_yank_t += delta
	var u: float = clampf(_yank_t / maxf(data.forearm_yank_s, 0.01), 0.0, 1.0)
	# Yanked back toward her (toward the camera) and up.
	_forearm_arm.position = _forearm_rest + Vector3(0.0, 3.0 * u, 9.0 * u * u)
	if u >= 1.0:
		_forearm_arm.visible = false
		_yank_t = -1.0


func _build_lights() -> void:
	var count: int = 6
	for i: int in count:
		var lamp: OmniLight3D = OmniLight3D.new()
		lamp.name = "Lamp%d" % i
		lamp.position = Vector3((-420.0 + 120.0 * float(i)) * m, 175.0 * m, 120.0 * m)
		lamp.light_color = Color(1.0, 0.93, 0.8)
		lamp.light_energy = 0.7
		lamp.omni_range = 90.0
		add_child(lamp)


# --- Measuring (tests) ------------------------------------------------------------------------------------

## The size of all the meshes under `node` (skipping any child named in `skip`), in game metres,
## in the node's own frame. Works without a scene tree.
static func mesh_size(node: Node3D, skip: Array[String] = []) -> Vector3:
	var boxes: Array[AABB] = []
	_collect(node, Transform3D.IDENTITY, skip, boxes)
	if boxes.is_empty():
		return Vector3.ZERO
	var total: AABB = boxes[0]
	for box: AABB in boxes:
		total = total.merge(box)
	return total.size


static func _collect(node: Node, to_root: Transform3D, skip: Array[String], boxes: Array[AABB]) -> void:
	for child: Node in node.get_children():
		if String(child.name) in skip:
			continue
		var spatial: Node3D = child as Node3D
		if spatial == null:
			continue
		var xf: Transform3D = to_root * spatial.transform
		var mesh_node: MeshInstance3D = child as MeshInstance3D
		if mesh_node != null and mesh_node.mesh != null:
			boxes.append(xf * mesh_node.mesh.get_aabb())
		_collect(child, xf, skip, boxes)
