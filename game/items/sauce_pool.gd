extends Area3D
## Sauce pool (gray box): while the 떡 stands in it, +1 sauce every pool_refill_interval_s,
## up to the cap.

const GameStateScript := preload("res://systems/game_state.gd")
const SauceTuningScript := preload("res://systems/sauce_tuning.gd")
const Layers := preload("res://systems/layers.gd")

const TUNING_PATH: String = "res://data/sauce_tuning.tres"

@export var tuning: SauceTuningScript

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript

var _timer: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript


func _physics_process(delta: float) -> void:
	var inside: bool = false
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			inside = true
			break
	step(delta, inside)


## One tick. Returns the sauce added. The timer restarts whenever the 떡 is outside or the
## bar is already full, so the first +1 comes one full interval after he starts refilling.
func step(delta: float, player_inside: bool) -> int:
	if tuning == null:
		tuning = load(TUNING_PATH) as SauceTuningScript
	if game_state == null or tuning.pool_refill_interval_s <= 0.0:
		return 0
	if not player_inside or game_state.sauce >= game_state.MAX_SAUCE:
		_timer = 0.0
		return 0
	_timer += delta
	var added: int = 0
	while _timer >= tuning.pool_refill_interval_s and game_state.sauce < game_state.MAX_SAUCE:
		_timer -= tuning.pool_refill_interval_s
		var before: int = game_state.sauce
		game_state.add_sauce(1)
		added += game_state.sauce - before
	return added
