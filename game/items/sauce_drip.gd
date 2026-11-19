extends Area3D
## Sauce drip pickup (gray box): +drip_amount sauce on touch, then removed.
## At the cap it stays where it is and is picked up later, once there is room.

const GameStateScript := preload("res://systems/game_state.gd")
const SauceTuningScript := preload("res://systems/sauce_tuning.gd")
const Layers := preload("res://systems/layers.gd")

const TUNING_PATH: String = "res://data/sauce_tuning.tres"

@export var tuning: SauceTuningScript

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var consumed: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript


## Polled (not body_entered) so a drip he could not take at 7 sauce is taken as soon as
## he has room, while still standing on it.
func _physics_process(_delta: float) -> void:
	if consumed:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			try_collect()
			return


## True if collected (sauce added, drip removed). False at the cap: nothing changes.
func try_collect() -> bool:
	if consumed or game_state == null:
		return false
	if tuning == null:
		tuning = load(TUNING_PATH) as SauceTuningScript
	if game_state.sauce >= game_state.MAX_SAUCE:
		return false
	game_state.add_sauce(tuning.drip_amount)
	consumed = true
	if is_inside_tree():
		queue_free()
	return true
