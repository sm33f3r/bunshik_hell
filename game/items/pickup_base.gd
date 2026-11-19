extends Area3D
## Shared base for gray-box pickups (health items, containers). Polled, not body_entered,
## so an item that could not be taken is taken as soon as it can be, while still standing on it.
## A taken pickup hides instead of freeing, so debug key 3 can bring it back (reset()).

const GameStateScript := preload("res://systems/game_state.gd")
const Layers := preload("res://systems/layers.gd")

## Seconds after spawning before it can be picked up (used by dropped items).
var pickup_delay: float = 0.0
## Spawned by dropping an item: freed (not restored) on reset().
var dropped: bool = false
## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var consumed: bool = false

var _elapsed: float = 0.0
## The popup was shown (or refused) for this pickup; stays quiet until the 떡 steps off it.
var _popup_suppressed: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	add_to_group("item_pickups")
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state != null:
		game_state.popup_closed.connect(_on_popup_closed)


func _physics_process(delta: float) -> void:
	tick(delta)
	if consumed:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			try_collect()
			return
	_popup_suppressed = false


## When a popup closes, every pickup he is standing on stays quiet until he steps off, so
## overlapping neighbours do not open a chain of popups.
func _on_popup_closed() -> void:
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			_popup_suppressed = true
			return


func tick(delta: float) -> void:
	_elapsed += delta


func can_collect() -> bool:
	return not consumed and game_state != null and _elapsed >= pickup_delay


## True if taken. Subclasses implement _collect().
func try_collect() -> bool:
	if not can_collect():
		return false
	if _collect():
		_consume()
		return true
	return false


func _collect() -> bool:
	return false


func _consume() -> void:
	consumed = true
	visible = false
	set_deferred("monitoring", false)
	if dropped and is_inside_tree():
		queue_free()


## Debug key 3: back where it started, untaken. Dropped copies just disappear.
func reset() -> void:
	if dropped:
		if is_inside_tree():
			queue_free()
		return
	consumed = false
	visible = true
	_elapsed = pickup_delay
	_popup_suppressed = false
	set_deferred("monitoring", true)
