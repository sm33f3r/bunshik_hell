extends Node3D
## A usable environment object (gray box): a water bottle or a heavy pot. The 떡 near it makes
## it highlight; the `special` action spends 나트륨 and sets it off, once.
##   pour_water:   tips over toward the 떡 facing and spills a water sheet along the floor.
##   heavy_object: slides off its support toward the facing, falls, and hits what is under it.
## Origin: the middle of the object base. All numbers come from the EnvSpecialDef.

signal used_up(object: Node3D)

const EnvSpecialDefScript := preload("res://systems/env_special_def.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const EnvQueryScript := preload("res://items/env_query.gd")
const WaterSheetScript := preload("res://items/water_sheet.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")

enum Highlight { NONE, BRIGHT, DIM }
enum Phase { READY, MOVING, SPENT }

## The pot never falls faster than this (m/s).
const MAX_FALL_SPEED: float = 25.0
## How far above/below its feet a sliding pot looks for the surface it rests on.
const SUPPORT_REACH: float = 0.12
const TIP_TIME: float = 0.3

@export var def: EnvSpecialDefScript

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var used: bool = false
var highlight: Highlight = Highlight.NONE
var phase: Phase = Phase.READY
## Enemy ids this pot already hit (each once).
var hit_ids: Array[int] = []
## What the last use hit: the enemies, in order. For tests and the HUD.
var last_hits: Array[Node3D] = []

var _facing: float = 1.0
var _velocity: Vector2 = Vector2.ZERO
var _supported: bool = true
var _home: Transform3D
var _visual: Node3D
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _label: Label3D
var _sheet: Node3D
var _tween: Tween


func _ready() -> void:
	add_to_group("usable_objects")
	_home = transform
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	_build_visual()
	set_highlight(Highlight.NONE)


func display_name() -> String:
	return def.display_name if def != null and def.display_name != "" else String(name)


func cost() -> int:
	return def.natrium_cost if def != null else 0


func can_use() -> bool:
	return def != null and not used and phase == Phase.READY


## The middle of the object body, in world space.
func use_center() -> Vector3:
	var size: Vector3 = def.body_size() if def != null else Vector3.ONE
	var base: Vector3 = global_position if is_inside_tree() else position
	return base + Vector3(0.0, size.y * 0.5, 0.0)


## Distance in the game plane from a point (the 떡 position) to the middle of the object.
func distance_to(point: Vector3) -> float:
	var c: Vector3 = use_center()
	return Vector2(point.x - c.x, point.y - c.y).length()


func in_range_of(point: Vector3) -> bool:
	return can_use() and distance_to(point) <= def.use_range_m


## Uses the object toward `facing` (+1 right, -1 left). Spends the 나트륨 first; with too little
## nothing happens and false comes back. Single use. True if it went off.
func try_use(state: GameStateScript, facing: float) -> bool:
	if not can_use() or state == null:
		return false
	if not state.spend_sodium(def.natrium_cost):
		return false
	used = true
	_facing = signf(facing) if facing != 0.0 else 1.0
	set_highlight(Highlight.NONE)
	if def.is_pour_water():
		_pour()
	else:
		_start_fall()
	used_up.emit(self)
	return true


## Debug key 3 and tests: back to its start, unused.
func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = null
	used = false
	phase = Phase.READY
	hit_ids.clear()
	last_hits.clear()
	_velocity = Vector2.ZERO
	_supported = true
	transform = _home
	if _visual != null:
		_visual.rotation = Vector3.ZERO
	set_highlight(Highlight.NONE)


func set_highlight(mode: Highlight) -> void:
	highlight = mode
	if _mat != null:
		match mode:
			Highlight.BRIGHT:
				_mat.emission_enabled = true
				_mat.emission = Color(1.0, 0.95, 0.35)
				_mat.emission_energy_multiplier = 1.4
			Highlight.DIM:
				_mat.emission_enabled = true
				_mat.emission = Color(0.55, 0.55, 0.6)
				_mat.emission_energy_multiplier = 0.25
			_:
				_mat.emission_enabled = false
	if _label != null:
		_label.visible = mode != Highlight.NONE
		_label.modulate = Color(1, 1, 1, 1) if mode == Highlight.BRIGHT else Color(0.6, 0.6, 0.65, 0.8)


func _physics_process(delta: float) -> void:
	if phase == Phase.MOVING:
		step_fall(delta)


# --- Pour water ---------------------------------------------------------------------------

func _pour() -> void:
	phase = Phase.SPENT
	if _visual != null and is_inside_tree():
		_tween = create_tween()
		_tween.tween_property(_visual, "rotation:z", -_facing * PI * 0.5, TIP_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if not is_inside_tree() or get_parent() == null:
		return
	var sheet: Node3D = WaterSheetScript.new()
	sheet.setup(def.reach_m, _facing, def.sheet_lifetime_s)
	get_parent().add_child(sheet)
	sheet.global_position = global_position
	_sheet = sheet


# --- Heavy object -------------------------------------------------------------------------

func _start_fall() -> void:
	phase = Phase.MOVING
	_velocity = Vector2(_facing * def.knock_speed_mps, 0.0)
	_supported = true


## One tick of the knocked-off pot. It slides along what it rests on until it is past the
## edge, then falls under gravity, hitting every enemy it overlaps on the way (once each),
## and comes to rest on the first surface below. Public so tests can drive it.
func step_fall(delta: float) -> void:
	if phase != Phase.MOVING:
		return
	var pos: Vector3 = global_position
	var world: World3D = get_world_3d() if is_inside_tree() else null
	pos.x += _velocity.x * delta
	if _supported:
		var ground: float = EnvQueryScript.surface_below(world, pos.x, pos.z, pos.y + SUPPORT_REACH, pos.y - SUPPORT_REACH)
		if is_nan(ground):
			_supported = false
			_velocity.y = 0.0
		else:
			pos.y = ground
	if not _supported:
		_velocity.y = maxf(_velocity.y - def.fall_gravity * delta, -MAX_FALL_SPEED)
		var next_y: float = pos.y + _velocity.y * delta
		var landing: float = EnvQueryScript.surface_below(world, pos.x, pos.z, pos.y + 0.05, next_y)
		if is_nan(landing):
			pos.y = next_y
		else:
			pos.y = landing
			phase = Phase.SPENT
	global_position = pos
	_hit_enemies(world)
	if phase == Phase.SPENT:
		_velocity = Vector2.ZERO


## Every living enemy overlapping the box of the pot takes attack "heavy_object" (once each).
func _hit_enemies(world: World3D) -> void:
	if world == null:
		return
	for enemy in EnvQueryScript.enemies_in_box(world, use_center(), def.body_size()):
		var id: int = enemy.get_instance_id()
		if hit_ids.has(id):
			continue
		hit_ids.append(id)
		last_hits.append(enemy)
		enemy.receive_attack(ReactionTableScript.ATTACK_HEAVY_OBJECT, _facing, {"pin_s": def.pin_s()})


# --- Gray-box look ------------------------------------------------------------------------

func _build_visual() -> void:
	if def == null:
		return
	_visual = get_node_or_null("Visual") as Node3D
	if _visual == null:
		_visual = Node3D.new()
		_visual.name = "Visual"
		add_child(_visual)
	var size: Vector3 = def.body_size()
	_mesh = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.height = size.y
	cyl.top_radius = size.x * (0.35 if def.is_pour_water() else 0.5)
	cyl.bottom_radius = size.x * 0.5
	cyl.radial_segments = 16
	_mesh.mesh = cyl
	_mesh.position = Vector3(0.0, size.y * 0.5, 0.0)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = def.tint
	_mat.roughness = 0.5
	_mesh.material_override = _mat
	_visual.add_child(_mesh)
	# The label stays upright and out of the tipping visual.
	_label = Label3D.new()
	_label.text = "%s\n[special: %d 나트륨]" % [def.display_name, def.natrium_cost]
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.pixel_size = 0.006
	_label.outline_size = 8
	_label.position = Vector3(0.0, size.y + 0.45, 0.0)
	add_child(_label)
