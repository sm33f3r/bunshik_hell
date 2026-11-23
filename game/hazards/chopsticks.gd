extends "res://hazards/strike_zone.gd"
## Other customers' metal chopsticks (Roster §5 hazard). A shadow, then a pinch from above: ½ heart.
## If it catches him it GRABS and lifts him; he wiggles left/right to get free (easy: a few presses,
## the same alternation rule as the prologue's pick, see systems/wiggle.gd), and while he is held
## nothing else can hurt him. It also picks up enemies in the strike (a 만두 is lifted off-screen and
## is gone). Cannot be destroyed. Numbers: data/hazards/chopsticks.tres.

signal grabbed
signal released(reason: String)

const WiggleScript := preload("res://systems/wiggle.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")
const ChopsticksDefScript := preload("res://hazards/chopsticks_def.gd")
const STEEL: Color = Color(0.72, 0.74, 0.78)

## The def as chopsticks data.
var cdef: ChopsticksDefScript:
	get: return def as ChopsticksDefScript

var held: bool = false
var hold_time: float = 0.0
var wiggle: WiggleScript = null

var _held_player: Node3D = null
var _tool: Node3D
var _lift_target_y: float = 0.0


func _busy() -> bool:
	return held


func _physics_process(delta: float) -> void:
	super(delta)
	if held:
		step_hold(delta)


## The hold: lift him, count his wiggles, let go after hold_max_s. Public so tests can drive it.
func step_hold(delta: float) -> void:
	if not held:
		return
	if _held_player == null or not is_instance_valid(_held_player) or _held_player.get("held_by") != self:
		release("lost")
		return
	hold_time += delta
	var y: float = _held_player.global_position.y
	_held_player.global_position.y = move_toward(y, _lift_target_y, cdef.lift_speed_mps * delta)
	if GameplayInputScript.just_pressed(&"move_left"):
		wiggle_press(-1)
	if GameplayInputScript.just_pressed(&"move_right"):
		wiggle_press(1)
	if held and hold_time >= cdef.hold_max_s:
		release("timeout")


func wiggle_press(dir: int) -> void:
	if held and wiggle.press(dir):
		release("wiggle")


func _on_strike() -> void:
	_show_tool()
	var player: Node3D = _find_player()
	if player != null and under_strike(_xy(player), 0.5):
		if bool(player.call("hurt", def.damage_half_hearts, strike_x)) and int(player.get("state")) != 8 \
				and bool(player.call("grab", self)):
			held = true
			hold_time = 0.0
			wiggle = WiggleScript.new(cdef.wiggle_required)
			_held_player = player
			_lift_target_y = player.global_position.y + cdef.lift_m
			grabbed.emit()
	for enemy: Node3D in enemies_under_strike():
		if cdef.takes_enemy_ids.has(String((enemy.get("def") as Resource).get("id"))):
			enemy.call("take_away", cdef.enemy_lift_m, cdef.enemy_lift_s)


## Lets go of him (he falls) and the chopsticks go back up.
func release(reason: String) -> void:
	if not held:
		return
	held = false
	if _held_player != null and is_instance_valid(_held_player):
		_held_player.call("release_grab")
	_held_player = null
	_hide_tool()
	released.emit(reason)


func _on_recover() -> void:
	if not held:
		_hide_tool()


func _hide_picture() -> void:
	super()
	if not held:
		_hide_tool()


func _build_picture() -> void:
	super()
	_tool = Node3D.new()
	_tool.name = "Tool"
	add_child(_tool)
	var length: float = def.strike_height_m + 6.0
	for i: int in 2:
		PrologueSetScript.add_mesh(_tool, "Stick%d" % i, PrologueSetScript.box_mesh(Vector3(0.12, length, 0.12)), STEEL,
			Vector3((float(i) - 0.5) * strike_width_m() * 0.5, length * 0.5, 0.0))
	_tool.visible = false


func _show_tool() -> void:
	if _tool != null:
		_tool.visible = true
		_tool.global_position = Vector3(strike_x, _origin().y, _origin().z)


func _hide_tool() -> void:
	if _tool != null:
		_tool.visible = false
