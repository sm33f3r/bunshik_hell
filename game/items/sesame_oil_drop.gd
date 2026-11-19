extends Area3D
## One 참기름 drop. Falls under gravity in the game plane; on landing it becomes a small puddle
## that lasts puddle_lifetime_s, then soaks away. Touching a drop or a puddle heals ½ heart IF
## the 떡 is hurt and uses it up; at full hearts it is left alone.

const GameStateScript := preload("res://systems/game_state.gd")
const SesameOilTuningScript := preload("res://items/sesame_oil_tuning.gd")
const Layers := preload("res://systems/layers.gd")

const TUNING_PATH: String = "res://data/sesame_oil.tres"
const PUDDLE_FLATTEN: Vector3 = Vector3(1.8, 0.2, 1.8)

@export var tuning: SesameOilTuningScript
@export var puddle_lifetime_s: float = 8.0

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var landed: bool = false
## Healed (used up) or soaked away.
var gone: bool = false

var _fall_speed: float = 0.0
var _fall_time: float = 0.0
var _puddle_left: float = 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	_ensure_tuning()
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	if _mesh != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = tuning.color
		mat.roughness = 0.15
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mesh.material_override = mat
	if landed:
		_become_puddle()


func _physics_process(delta: float) -> void:
	if gone:
		return
	if not landed:
		_fall(delta)
	if gone:
		return
	var touching: bool = false
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			touching = true
			break
	step(delta, touching)


## Heal / puddle timing for one tick (no movement). Returns true if it healed.
func step(delta: float, touching_player: bool) -> bool:
	if gone or game_state == null:
		return false
	_ensure_tuning()
	if touching_player and game_state.heal_if_hurt(tuning.heal_half_hearts):
		_remove()
		return true
	if landed:
		_puddle_left -= delta
		if _puddle_left <= 0.0:
			_remove()
	return false


## Called when the drop reaches a surface: starts the puddle's lifetime.
func land() -> void:
	if landed and _puddle_left > 0.0:
		return
	landed = true
	_become_puddle()


func _become_puddle() -> void:
	_puddle_left = puddle_lifetime_s
	_fall_speed = 0.0
	if _mesh != null:
		_mesh.scale = PUDDLE_FLATTEN


func _fall(delta: float) -> void:
	_ensure_tuning()
	_fall_time += delta
	if _fall_time > tuning.max_fall_time_s:
		_remove()
		return
	_fall_speed = minf(_fall_speed + tuning.gravity * delta, tuning.max_fall_speed)
	var from: Vector3 = global_position
	var to: Vector3 = from + Vector3.DOWN * (_fall_speed * delta + 0.05)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, Layers.WORLD | Layers.ONE_WAY)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = from + Vector3.DOWN * (_fall_speed * delta)
		return
	global_position = (hit["position"] as Vector3) + Vector3.UP * 0.03
	land()


func _remove() -> void:
	gone = true
	visible = false
	set_deferred("monitoring", false)
	if is_inside_tree():
		queue_free()


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = load(TUNING_PATH) as SesameOilTuningScript
