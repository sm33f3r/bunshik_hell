extends Node3D
## Gray-box test room: places the 떡 at the checkpoint (the start 찜기 on first run)
## and sends him back through the normal death path if he falls out of the world.

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const SteamerScript := preload("res://items/steamer.gd")

## The id this map has in MapCatalog and in the save.
const MAP_ID: String = "test_room"

@export var player: DdeokScript
@export var start_steamer: SteamerScript
## Below this height the 떡 has fallen into the gap.
@export var kill_y: float = -12.0


func _ready() -> void:
	var game_state: GameStateScript = get_node_or_null("/root/GameState") as GameStateScript
	if game_state == null or player == null:
		return
	game_state.current_map = MAP_ID
	if game_state.checkpoint_id == "" and start_steamer != null:
		game_state.set_checkpoint(start_steamer.steamer_id, start_steamer.spawn_point())
	player.global_position = game_state.checkpoint_position


func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y < kill_y:
		player.kill()
