extends Node3D
## A zone on a table or the floor where something strikes from above on a timer: a shadow warns first
## (telegraph), then the strike, then it goes back up, then it waits a random while. The timings and
## sizes are the def's (hazards/strike_def.gd and its children). Chopsticks and the giant foot extend
## this and say what a strike does (_on_strike). The origin is on the surface (feet level) in the
## middle of the zone. `step(delta)` is the whole clock: tests drive it without a scene.

signal telegraph_started(x: float)
signal struck(x: float)

enum Phase { COOLDOWN, TELEGRAPH, STRIKE, RECOVER }

const StrikeDefScript := preload("res://hazards/strike_def.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")

const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
## How far above and below the surface something still counts as under the strike.
const BELOW_M: float = 0.4

@export var def: StrikeDefScript
## Width of the zone in game metres (a spawn's size_cm sets it).
@export var width_m: float = 6.0
## Game metres per real centimetre; -1 = read the world scale data.
@export var m_per_cm: float = -1.0
## false: it stays quiet (tests; the floor-lane run).
@export var enabled: bool = true

var phase: Phase = Phase.COOLDOWN
## Seconds left in the phase.
var timer: float = 0.0
## World x of the strike (set when the shadow appears).
var strike_x: float = 0.0
var strikes: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Tests set this; in a scene the first node of group "player" is used.
var target_player: Node3D = null

var _shadow: MeshInstance3D


func _ready() -> void:
	add_to_group("hazards")
	rng.randomize()
	_build_picture()
	start()


## Begins the wait before the first strike.
func start() -> void:
	phase = Phase.COOLDOWN
	timer = next_cooldown()


func next_cooldown() -> float:
	return rng.randf_range(def.cooldown_min_s, maxf(def.cooldown_max_s, def.cooldown_min_s))


func strike_width_m() -> float:
	return def.strike_width_cm * _scale()


func _scale() -> float:
	if m_per_cm > 0.0:
		return m_per_cm
	var world: Resource = WorldScaleScript.load_default()
	return (world as WorldScaleScript).game_m_per_real_cm() if world != null else 0.1745


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		start()
		_hide_picture()


func _physics_process(delta: float) -> void:
	step(delta)


## One tick of the clock.
func step(delta: float) -> void:
	if not enabled or def == null or _busy():
		return
	timer -= delta
	if timer > 0.0:
		return
	match phase:
		Phase.COOLDOWN:
			strike_x = _pick_strike_x()
			phase = Phase.TELEGRAPH
			timer = def.telegraph_s
			_show_shadow()
			telegraph_started.emit(strike_x)
		Phase.TELEGRAPH:
			phase = Phase.STRIKE
			timer = def.strike_hold_s
			strikes += 1
			_hide_shadow()
			_on_strike()
			struck.emit(strike_x)
		Phase.STRIKE:
			phase = Phase.RECOVER
			timer = def.recover_s
			_on_recover()
		Phase.RECOVER:
			phase = Phase.COOLDOWN
			timer = next_cooldown()
			_hide_picture()


## Override: true while the hazard is busy with something (chopsticks holding him): the clock waits.
func _busy() -> bool:
	return false


## Override: what the strike does.
func _on_strike() -> void:
	pass


## Override: the strike is over; it goes back up.
func _on_recover() -> void:
	pass


func _hide_picture() -> void:
	_hide_shadow()


func _find_player() -> Node3D:
	if target_player != null and is_instance_valid(target_player):
		return target_player
	if is_inside_tree():
		return get_tree().get_first_node_in_group("player") as Node3D
	return null


func _origin() -> Vector3:
	return global_position if is_inside_tree() else position


func zone_left() -> float:
	return _origin().x - width_m * 0.5


func zone_right() -> float:
	return _origin().x + width_m * 0.5


## Where this strike lands: on him when he is in the zone (if the def aims), else somewhere in it.
func _pick_strike_x() -> float:
	var half: float = strike_width_m() * 0.5
	var low: float = zone_left() + half
	var high: float = zone_right() - half
	if high <= low:
		return _origin().x
	if def.aim_player:
		var player: Node3D = _find_player()
		if player != null and in_zone(_xy(player)):
			return clampf(_xy(player).x, low, high)
	return rng.randf_range(low, high)


func _xy(node: Node3D) -> Vector2:
	var p: Vector3 = node.global_position if node.is_inside_tree() else node.position
	return Vector2(p.x, p.y)


## A point (the middle of a body) is inside the zone's column.
func in_zone(at: Vector2) -> bool:
	var y: float = _origin().y
	return at.x >= zone_left() and at.x <= zone_right() and at.y >= y - BELOW_M and at.y <= y + def.strike_height_m


## A body at `at` (its middle) with this half-length is under the strike.
func under_strike(at: Vector2, half_extent: float) -> bool:
	var y: float = _origin().y
	var half: float = strike_width_m() * 0.5 + half_extent
	return absf(at.x - strike_x) <= half and at.y >= y - BELOW_M and at.y <= y + def.strike_height_m


## Living enemies under the strike.
func enemies_under_strike() -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not is_inside_tree():
		return out
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Node3D = node as Node3D
		if enemy == null or not bool(enemy.get("alive")):
			continue
		var middle: Vector2 = Vector2(enemy.global_position.x, enemy.global_position.y + float(enemy.get("body_height")) * 0.5)
		if under_strike(middle, float(enemy.get("body_height")) * 0.5):
			out.append(enemy)
	return out


# --- The gray-box picture ---------------------------------------------------------------------

func _build_picture() -> void:
	_shadow = PrologueSetScript.add_mesh(self, "Shadow", PrologueSetScript.box_mesh(Vector3(strike_width_m(), 0.04, 1.4)),
		SHADOW_COLOR, Vector3(0.0, 0.05, 0.0))
	_shadow.visible = false


func _show_shadow() -> void:
	if _shadow == null:
		return
	_shadow.visible = true
	_shadow.global_position = Vector3(strike_x, _origin().y + 0.05, _origin().z)


func _hide_shadow() -> void:
	if _shadow != null:
		_shadow.visible = false
