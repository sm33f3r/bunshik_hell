extends Area3D
## A static 참기름 smudge placed on a surface in the level. Same heal on touch (only if hurt),
## used up once, and it does not come back (only debug key 3 restores it).

const GameStateScript := preload("res://systems/game_state.gd")
const SesameOilTuningScript := preload("res://items/sesame_oil_tuning.gd")
const Layers := preload("res://systems/layers.gd")

const TUNING_PATH: String = "res://data/sesame_oil.tres"

@export var tuning: SesameOilTuningScript

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var used: bool = false

var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	add_to_group("oil_smudges")
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


func _physics_process(_delta: float) -> void:
	if used:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			try_use()
			return


## True if it healed (and is now used up). At full hearts nothing happens.
func try_use() -> bool:
	if used or game_state == null:
		return false
	_ensure_tuning()
	if not game_state.heal_if_hurt(tuning.heal_half_hearts):
		return false
	used = true
	visible = false
	set_deferred("monitoring", false)
	return true


func reset() -> void:
	used = false
	visible = true
	set_deferred("monitoring", true)


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = load(TUNING_PATH) as SesameOilTuningScript
