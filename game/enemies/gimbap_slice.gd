extends "res://enemies/enemy_base.gd"
## One 김밥 slice (segmented). It is a small enemy body of its own: it follows the train it belongs to,
## or, once the line is broken (a roll), it walks on its own and turns at edges and walls. Touching it
## costs 1 heart. Landing on it spills a slippery patch; a stomp, sauce hurts it; a slam or a heavy
## object kills it; a roll breaks the line. Death: it falls apart into small pieces (no collisions).
## All numbers: data/enemies/gimbap.tres. Roster §5. The picture is a gray box (the cut face is a
## marker; FRONTEND later).

const Layers_ := preload("res://systems/layers.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const SlipperyPatchScript := preload("res://hazards/slippery_patch.gd")
const TuningScript := preload("res://player/movement_tuning.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")

const EDGE_DROP_M: float = 0.7
const EDGE_LOOKAHEAD_M: float = 0.15
const RICE_COLOR: Color = Color(0.96, 0.95, 0.9)
const NORI_COLOR: Color = Color(0.1, 0.16, 0.1)
const FILLING_COLORS: Array[Color] = [Color(0.3, 0.65, 0.25), Color(0.95, 0.8, 0.2), Color(0.9, 0.45, 0.45), Color(0.98, 0.85, 0.15)]
const END_PIECE_COLOR: Color = Color(0.2, 0.3, 0.2)
## Pieces a dying slice falls apart into, and how long they fall.
const PIECES: int = 5
const PIECE_LIFE_S: float = 0.8

## Game metres per real centimetre; -1 = read the world scale data.
@export var m_per_cm: float = -1.0
## Walking speed multiplier (a spawn's params may change it).
@export var speed_scale: float = 1.0
@export var start_dir: float = 1.0
## The uncut end piece (꼬다리) leads the train.
@export var is_end_piece: bool = false

## The train this slice is part of (null = on its own: broken off, or never in one).
var train: Node = null
var slice_index: int = 0
var diameter_m: float = 0.0
var thickness_m: float = 0.0
## Seconds before this slice may spill again.
var spill_cooldown: float = 0.0
## How many patches it spilled (tests).
var spills: int = 0

var _dir: float = 1.0
var _shape_node: CollisionShape3D


## Sizes the body from the EnemyDef.
func configure() -> void:
	if def == null:
		return
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	diameter_m = def.slice_size_cm * scale_m
	thickness_m = def.slice_thickness_cm * scale_m
	body_height = diameter_m
	_shape_node = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _shape_node != null:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(diameter_m, diameter_m, maxf(thickness_m, diameter_m * 0.7))
		_shape_node.shape = box
		_shape_node.position = Vector3(0.0, diameter_m * 0.5, 0.0)
	_build_picture()


func _world_m_per_cm() -> float:
	var world: Resource = WorldScaleScript.load_default()
	return (world as WorldScaleScript).game_m_per_real_cm() if world != null else 0.1745


func half_width() -> float:
	return diameter_m * 0.5


func _build_picture() -> void:
	var visual: Node3D = get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	for child: Node in visual.get_children():
		child.queue_free()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = diameter_m * 0.5
	disc.bottom_radius = diameter_m * 0.5
	disc.height = thickness_m
	disc.radial_segments = 24
	var body: MeshInstance3D = PrologueSetScript.add_mesh(visual, "Rice", disc, END_PIECE_COLOR if is_end_piece else NORI_COLOR,
		Vector3(0.0, diameter_m * 0.5, 0.0))
	body.rotation.x = PI * 0.5 # the cut face looks at the camera
	# The cross-section "face": a marker only (rice disc with a filling dot), FRONTEND later.
	var face: CylinderMesh = CylinderMesh.new()
	face.top_radius = diameter_m * 0.38
	face.bottom_radius = diameter_m * 0.38
	face.height = thickness_m * 1.05
	var rice: MeshInstance3D = PrologueSetScript.add_mesh(visual, "Face", face, RICE_COLOR, Vector3(0.0, diameter_m * 0.5, 0.0))
	rice.rotation.x = PI * 0.5
	var dot: BoxMesh = BoxMesh.new()
	dot.size = Vector3(diameter_m * 0.2, diameter_m * 0.2, thickness_m * 1.15)
	PrologueSetScript.add_mesh(visual, "Filling", dot, FILLING_COLORS[slice_index % FILLING_COLORS.size()],
		Vector3(0.0, diameter_m * 0.5, 0.0))


func _on_ready() -> void:
	configure()
	_dir = start_dir


func _on_reset() -> void:
	_dir = start_dir
	spill_cooldown = 0.0


## Walks on its own from now on (the line broke): out of the train, hopping away.
func scatter(direction: float) -> void:
	train = null
	_dir = direction if direction != 0.0 else _dir
	velocity.y = def.scatter_hop_mps if def != null else 0.0


func _ai(delta: float) -> void:
	spill_cooldown = maxf(spill_cooldown - delta, 0.0)
	if train != null and is_instance_valid(train):
		train.call("drive", self, delta)
		return
	var speed: float = (def.scatter_speed_mps if def != null else 0.0) * speed_factor() * speed_scale
	if is_on_wall() and signf(get_wall_normal().x) == -_dir:
		_dir = -_dir
	elif is_on_floor() and edge_ahead(_dir):
		_dir = -_dir
	velocity.x = _dir * speed


## No floor just ahead of the slice's front (within EDGE_DROP_M below the feet).
func edge_ahead(direction: float) -> bool:
	if not is_inside_tree():
		return false
	var from: Vector3 = global_position + Vector3(direction * (half_width() + EDGE_LOOKAHEAD_M), 0.1, 0.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, from + Vector3(0.0, -(EDGE_DROP_M + 0.1), 0.0), Layers_.WORLD)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# --- Reactions ----------------------------------------------------------------------------------

## Landing on it: it spills and leaves a slippery patch (once per spill_cooldown_s).
func _handle_spill() -> void:
	if spill_cooldown > 0.0 or def == null:
		return
	spill_cooldown = def.spill_cooldown_s
	spills += 1
	if not is_inside_tree() or get_parent() == null:
		return
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	var tuning: TuningScript = load("res://data/movement_tuning.tres") as TuningScript
	SlipperyPatchScript.make(get_parent(), global_position, def.spill_patch_width_cm * scale_m,
		def.spill_patch_lifetime_s, tuning.slip_linger_s)


## A roll: the whole train scatters into single slices.
func _handle_break_line(hit_dir: float) -> void:
	if train != null and is_instance_valid(train):
		train.call("break_line", hit_dir)


## Falls apart: small pieces scatter and fall (no collisions), the slice itself is gone.
func _play_death(_tip_over: bool, hit_dir: float) -> bool:
	if train != null and is_instance_valid(train):
		train.call("slice_died", self)
	_scatter_pieces(hit_dir)
	_finish_death()
	return true


func _scatter_pieces(hit_dir: float) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	for i: int in PIECES:
		var piece: MeshInstance3D = MeshInstance3D.new()
		piece.mesh = PrologueSetScript.box_mesh(Vector3.ONE * diameter_m * 0.18)
		piece.material_override = PrologueSetScript.material(FILLING_COLORS[i % FILLING_COLORS.size()])
		piece.add_to_group("section_decor")
		parent.add_child(piece)
		piece.global_position = global_position + Vector3(0.0, diameter_m * 0.5, 0.0)
		var out: float = (float(i) - float(PIECES - 1) * 0.5) * 0.7 + hit_dir * 0.4
		var tween: Tween = piece.create_tween().set_parallel(true)
		tween.tween_property(piece, "global_position", piece.global_position + Vector3(out, -diameter_m * 0.5 - 0.3 * float(i % 2), 0.0), PIECE_LIFE_S) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "scale", Vector3.ZERO, PIECE_LIFE_S).set_delay(PIECE_LIFE_S * 0.6)
		tween.chain().tween_callback(piece.queue_free)
