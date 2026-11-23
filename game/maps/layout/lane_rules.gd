extends RefCounted
## The character lane: the strip of depth (z) the 떡 and the enemies walk in, as deep as the tables
## (the lane's half depth is half the tables' depth). Anything in the lane that is not a collider would
## be walked through like a ghost, so decor that is not a collider must stand entirely behind the lane (or,
## as a foreground layer, entirely in front of it and low enough that the camera never lets it overlap
## the characters). This script places such decor and checks a built scene for offenders.

## Decor in front of the lane must top out at least this far below where characters stand, so the camera
## (14 m away, looking level) never shows it over them. 🟡
const FRONT_CLEARANCE_M: float = 4.0
## A mesh that sits on a collider (its picture) may stick out of it by this much (metres).
const BACKING_TOLERANCE_M: float = 0.3
## Touching the lane's edge is not inside it.
const EPS: float = 0.001


## The z of a decor piece's centre for a layer: "behind" = just past the back edge of the lane.
static func decor_z(layer: String, lane_depth_m: float, gap_m: float, piece_depth_m: float) -> float:
	var edge: float = lane_depth_m * 0.5 + gap_m + piece_depth_m * 0.5
	return edge if layer == "front" else -edge


## Every decor piece (a mesh that is not the picture of a collider and not part of an enemy, a hazard
## or a pickup) under `root` that is inside the lane or that is in front of it too high up. One readable
## line each; empty = fine. `front_top_limit_y`: the highest a foreground piece may reach (-INF = no
## foreground decor allowed). Needs `root` in the scene tree.
static func offenders(root: Node, lane_depth_m: float, front_top_limit_y: float = -INF) -> Array[String]:
	var out: Array[String] = []
	var half: float = lane_depth_m * 0.5
	for mesh: MeshInstance3D in _meshes(root):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		if _is_picture_of_collider(mesh, box):
			continue
		var z_min: float = box.position.z
		var z_max: float = box.end.z
		if z_max <= -half + EPS:
			continue # behind the lane
		if z_min >= half - EPS and box.end.y <= front_top_limit_y:
			continue # a low foreground piece
		out.append("%s: z %.2f..%.2f m, y up to %.2f m (the lane is -%.2f..%.2f m)" % [
			root.get_path_to(mesh), z_min, z_max, box.end.y, half, half])
	return out


static func _meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	# A 찜기 is a prop he uses on purpose, like a pickup: it stands in the lane.
	if node.is_in_group("enemies") or node.is_in_group("hazards") or node.is_in_group("dropped_loot") 			or node.is_in_group("jjigi") or node is CharacterBody3D:
		return out
	var mesh: MeshInstance3D = node as MeshInstance3D
	if mesh != null and mesh.visible and mesh.mesh != null:
		out.append(mesh)
	for child: Node in node.get_children():
		out.append_array(_meshes(child))
	return out


## A mesh below a collider body whose picture it is: inside the collision shapes' bounds (give or take).
static func _is_picture_of_collider(mesh: MeshInstance3D, box: AABB) -> bool:
	var parent: Node = mesh.get_parent()
	while parent != null:
		if parent is CollisionObject3D:
			var bounds: AABB = collision_bounds(parent as CollisionObject3D)
			return bounds.size != Vector3.ZERO and bounds.grow(BACKING_TOLERANCE_M).encloses(box)
		parent = parent.get_parent()
	return false


## The world bounds of every shape of a collision object.
static func collision_bounds(body: CollisionObject3D) -> AABB:
	var out: AABB = AABB()
	var first: bool = true
	for child: Node in body.get_children():
		var shape_node: CollisionShape3D = child as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			continue
		var local: AABB
		if shape_node.shape is BoxShape3D:
			var size: Vector3 = (shape_node.shape as BoxShape3D).size
			local = AABB(-size * 0.5, size)
		elif shape_node.shape is CylinderShape3D:
			var cyl: CylinderShape3D = shape_node.shape as CylinderShape3D
			var size: Vector3 = Vector3(cyl.radius * 2.0, cyl.height, cyl.radius * 2.0)
			local = AABB(-size * 0.5, size)
		else:
			continue
		var world: AABB = shape_node.global_transform * local
		out = world if first else out.merge(world)
		first = false
	return out
