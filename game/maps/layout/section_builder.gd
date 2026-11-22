extends Node3D
## Builds the gray-box platforms of a MapLayout (tables, ledges, the end wall) and puts the
## sections' enemies on them. Everything it makes comes from the layout data and the resolved places
## (LayoutGeometry); nothing here is a typed-in coordinate.
##
## Node names (tests look things up by them):
##   Platform_<id>   StaticBody3D, solid (world layer)
##   EndWall_<section>   StaticBody3D, a tall wall after the last platform of a section, with a sign

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const Layers := preload("res://systems/layers.gd")

const WALL_HEIGHT_M: float = 40.0
const WALL_THICKNESS_M: float = 0.6
const END_WALL_COLOR: Color = Color(0.95, 0.75, 0.15)

var layout: MapLayoutScript
var placed: Array[LayoutGeometryScript.Placed] = []
## Game metres per real centimetre, and the depth (z) of a table.
var m_per_cm: float = 0.0
var depth_m: float = 0.0
## Platform id -> its node (the "existing" prologue table is not built here).
var platform_nodes: Dictionary = {}
var end_walls: Dictionary = {}

var _spawned: Dictionary = {}


func build(p_layout: MapLayoutScript, p_placed: Array[LayoutGeometryScript.Placed], p_m_per_cm: float, p_depth_m: float) -> void:
	layout = p_layout
	placed = p_placed
	m_per_cm = p_m_per_cm
	depth_m = p_depth_m
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "existing":
			continue
		platform_nodes[p.def.id] = _build_platform(p)
	for section: MapSectionScript in layout.sections:
		if section.external or section.end_wall_text == "":
			continue
		var last: LayoutGeometryScript.Placed = null
		for p: LayoutGeometryScript.Placed in placed:
			if p.section_id == section.id:
				last = p
		if last != null:
			end_walls[section.id] = _build_end_wall(section, last)


func _build_platform(p: LayoutGeometryScript.Placed) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Platform_%s" % p.def.id
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = Vector3(p.center_x(), p.top - p.thickness * 0.5, 0.0)
	var size: Vector3 = Vector3(p.length(), p.thickness, depth_m)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	PrologueSetScript.add_mesh(body, "Mesh", PrologueSetScript.box_mesh(size), p.def.color, Vector3.ZERO)
	if p.def.kind == "table":
		# Legs (decor): from the underside down to the floor.
		var leg_h: float = maxf(p.top - p.thickness, 0.1)
		for i: int in 2:
			var leg_x: float = (-0.5 + 0.06 + 0.88 * float(i)) * p.length()
			PrologueSetScript.add_mesh(body, "Leg%d" % i, PrologueSetScript.box_mesh(Vector3(0.6, leg_h, 0.6)),
				p.def.color.darkened(0.35), Vector3(leg_x, -p.thickness * 0.5 - leg_h * 0.5, 0.0))
	add_child(body)
	return body


func _build_end_wall(section: MapSectionScript, last: LayoutGeometryScript.Placed) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "EndWall_%s" % section.id
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = Vector3(last.right + WALL_THICKNESS_M * 0.5, last.top + WALL_HEIGHT_M * 0.5, 0.0)
	var size: Vector3 = Vector3(WALL_THICKNESS_M, WALL_HEIGHT_M, depth_m + 4.0)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	# A bright, low band so the wall cannot be missed, and the sign.
	PrologueSetScript.add_mesh(body, "Band", PrologueSetScript.box_mesh(Vector3(WALL_THICKNESS_M, 12.0, depth_m)),
		END_WALL_COLOR, Vector3(0.0, -WALL_HEIGHT_M * 0.5 + 6.0, 0.0))
	var sign_label: Label3D = Label3D.new()
	sign_label.name = "Sign"
	sign_label.text = section.end_wall_text
	sign_label.pixel_size = 0.025
	sign_label.font_size = 64
	sign_label.modulate = Color(0.15, 0.1, 0.0)
	sign_label.outline_modulate = Color(1.0, 0.95, 0.6)
	sign_label.outline_size = 16
	sign_label.position = Vector3(-WALL_THICKNESS_M * 0.5 - 0.1, -WALL_HEIGHT_M * 0.5 + 4.0, 0.0)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(sign_label)
	add_child(body)
	return body


# --- Enemies ----------------------------------------------------------------------------------------

## Puts every enemy of the section on its platform (first removing the ones from an earlier call).
## Returns the new nodes.
func spawn_section(section_id: String) -> Array[Node3D]:
	clear_section(section_id)
	var out: Array[Node3D] = []
	var section: MapSectionScript = layout.section(section_id)
	if section == null:
		return out
	var index: int = 0
	for entry: SpawnEntryScript in section.spawns:
		if entry.scene == null:
			continue
		var node: Node3D = entry.scene.instantiate() as Node3D
		if node == null:
			continue
		index += 1
		node.name = "%s%d" % [entry.group.to_upper() if entry.group != "" else "E", index]
		if entry.size_cm > 0.0:
			node.set("width_m", entry.size_cm * m_per_cm)
		if "m_per_cm" in node:
			node.set("m_per_cm", m_per_cm)
		node.set("start_dir", entry.start_dir)
		for key: Variant in entry.params:
			node.set(String(key), entry.params[key])
		add_child(node)
		node.global_position = LayoutGeometryScript.spawn_position(placed, entry)
		node.set_meta("section_id", section_id)
		node.set_meta("group", entry.group)
		out.append(node)
	_spawned[section_id] = out
	return out


func clear_section(section_id: String) -> void:
	for node: Node3D in _spawned.get(section_id, []):
		if is_instance_valid(node):
			if node.get_parent() == self:
				remove_child(node) # out of the tree now, so its name is free for the new one
			node.queue_free()
	_spawned[section_id] = [] as Array[Node3D]


## The enemies placed for a section (those still in the tree).
func enemies_of(section_id: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node: Node3D in _spawned.get(section_id, []):
		if is_instance_valid(node):
			out.append(node)
	return out


func enemies_in_group(section_id: String, group: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node: Node3D in enemies_of(section_id):
		if String(node.get_meta("group", "")) == group:
			out.append(node)
	return out
