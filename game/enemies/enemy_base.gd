extends CharacterBody3D
## Shared enemy base: health, hurt, death, reaction lookup, contact damage.
## Enemies differ by their EnemyDef .tres and, at most, a small behaviour script
## that overrides _ai(). All damage goes through the ReactionTable.
## Origin is at the enemy's feet.

signal hurt(hp: int)
signal died

const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const Layers := preload("res://systems/layers.gd")
const TABLE_PATH: String = "res://data/reaction_table.tres"

## "deteriorate" stages. Soggy is the last one and means dead.
const STAGE_NAMES: Array[String] = ["fresh", "broken", "crumbling", "soggy"]
const STAGE_SOGGY: int = 3
## Hits needed to reach soggy = DETERIORATE_STEPS * def.hits_per_stage (three steps:
## fresh -> broken -> crumbling -> soggy).
const DETERIORATE_STEPS: int = 3
## Gray-box tints: [stage] -> overlay colour (alpha = strength).
const STAGE_TINTS: Array[Color] = [
	Color(0.0, 0.0, 0.0, 0.0),
	Color(0.45, 0.28, 0.08, 0.35),
	Color(0.25, 0.14, 0.04, 0.55),
	Color(0.38, 0.38, 0.34, 0.75),
]
const JAM_TINT: Color = Color(0.1, 0.1, 0.12, 0.55)
const SLURP_TINT: Color = Color(1.0, 0.95, 0.4, 0.85)
## Visual sag per stage (scale.y shrinks, scale.x grows a little).
const SAG_PER_STAGE: float = 0.1

@export var def: EnemyDefScript
@export var reaction_table: ReactionTableScript
## Distance from the origin (feet) to the top of the body.
@export var body_height: float = 1.0
@export var gravity: float = 30.0
@export var max_fall_speed: float = 28.0
## Seconds the tip-over animation takes.
@export var tip_over_time: float = 0.5
@export var vanish_time: float = 0.2
## Seconds the "slurp" flash of an absorbed hit lasts.
@export var slurp_time: float = 0.25

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var hp: int = 0
var alive: bool = true
## 0 fresh .. 3 soggy (dead). Only "deteriorate" moves it.
var stage: int = 0
## True once a "jam" hit landed: the ranged attack stays off until reset().
var jammed: bool = false

var _stage_hits: int = 0
var _spawn_transform: Transform3D
var _lock_z: float = 0.0
var _visual: Node3D
var _tween: Tween
var _flash_tween: Tween
var _overlay: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemies")
	axis_lock_linear_z = true
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	_spawn_transform = transform
	_lock_z = position.z
	_visual = get_node_or_null("Visual") as Node3D
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	_make_overlay()
	setup()
	_on_ready()


## Idempotent. Also what tests call, since they never enter the scene tree.
func setup() -> void:
	if reaction_table == null:
		reaction_table = load(TABLE_PATH) as ReactionTableScript
	if def != null:
		hp = def.max_hp
	alive = true
	stage = 0
	_stage_hits = 0
	jammed = false
	_refresh_visual()


func stage_name() -> String:
	return STAGE_NAMES[clampi(stage, 0, STAGE_SOGGY)]


func contact_damage() -> int:
	return def.contact_damage_half_hearts if def != null else 0


func top_y() -> float:
	return global_position.y + body_height


func center_xy() -> Vector2:
	return Vector2(global_position.x, global_position.y + body_height * 0.5)


## Looks the hit up in the reaction table and applies every reaction of the cell in order.
## Returns {"reaction": String (the first), "reactions": Array[String], "damage": int
## (of the first), "killed": bool}. hurt_player and bounce_off have no effect on the enemy:
## the caller (the 떡) acts on them.
func receive_attack(attack: String, hit_dir: float = 1.0) -> Dictionary:
	if not alive or def == null or reaction_table == null:
		return {"reaction": ReactionTableScript.REACTION_ABSORB, "reactions": [ReactionTableScript.REACTION_ABSORB],
			"damage": 0, "killed": false}
	var cell: Array[Dictionary] = reaction_table.lookup_all(attack, def.material)
	var names: Array[String] = []
	for result: Dictionary in cell:
		var reaction: String = result["reaction"]
		names.append(reaction)
		if alive:
			_apply_reaction(reaction, result["damage"], hit_dir)
	return {"reaction": names[0], "reactions": names, "damage": cell[0]["damage"], "killed": not alive}


## Debug / tests only: kills the enemy whatever the reaction table says.
func debug_defeat() -> void:
	if alive:
		hp = 0
		_die(false, 1.0)


func _apply_reaction(reaction: String, damage: int, hit_dir: float) -> void:
	match reaction:
		ReactionTableScript.REACTION_DAMAGE:
			hp = maxi(hp - damage, 0)
			if hp == 0:
				_die(false, hit_dir)
			else:
				hurt.emit(hp)
		ReactionTableScript.REACTION_KILL:
			hp = 0
			_die(false, hit_dir)
		ReactionTableScript.REACTION_KNOCK_OVER:
			hp = 0
			_die(true, hit_dir)
		ReactionTableScript.REACTION_ABSORB:
			_play_slurp()
		ReactionTableScript.REACTION_DETERIORATE:
			_deteriorate(hit_dir)
		ReactionTableScript.REACTION_JAM:
			jammed = true
			_refresh_visual()


## One hit toward the next stage; def.hits_per_stage hits per stage. Soggy = dead.
func _deteriorate(hit_dir: float) -> void:
	_stage_hits += 1
	if _stage_hits < maxi(def.hits_per_stage, 1):
		return
	_stage_hits = 0
	stage = mini(stage + 1, STAGE_SOGGY)
	_refresh_visual()
	if stage >= STAGE_SOGGY:
		hp = 0
		_die(false, hit_dir)
	else:
		hurt.emit(hp)


## Brings a dead or damaged enemy back to its spawn state (debug F3, tests).
func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	if is_inside_tree():
		transform = _spawn_transform
	velocity = Vector3.ZERO
	collision_layer = Layers.ENEMY
	visible = true
	set_physics_process(true)
	if _visual != null:
		_visual.rotation = Vector3.ZERO
		_visual.scale = Vector3.ONE
	setup()
	_on_reset()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_ai(delta)
	velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)
	velocity.z = 0.0
	move_and_slide()
	if not is_equal_approx(position.z, _lock_z):
		position.z = _lock_z


## Override for behaviour. Set velocity.x here.
func _ai(_delta: float) -> void:
	pass


func _on_ready() -> void:
	pass


func _on_reset() -> void:
	pass


func _die(tip_over: bool, hit_dir: float) -> void:
	alive = false
	hp = 0
	velocity = Vector3.ZERO
	if game_state != null and def != null:
		game_state.register_defeat(def.id, String(def.unlocks_skill_on_first_defeat))
	died.emit()
	if not is_inside_tree():
		return
	collision_layer = 0
	if _visual == null:
		_finish_death()
		return
	_tween = create_tween()
	if tip_over:
		_tween.tween_property(_visual, "rotation:z", -signf(hit_dir) * PI * 0.5, tip_over_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		_tween.tween_property(_visual, "scale", Vector3(1.3, 0.1, 1.3), vanish_time)
	_tween.tween_callback(_finish_death)


func _finish_death() -> void:
	visible = false
	set_physics_process(false)


# --- Gray-box feedback: a tint overlay on every mesh, plus a sag per stage ---------------

func _make_overlay() -> void:
	if _visual == null:
		return
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = Color(0, 0, 0, 0)
	_assign_overlay(_visual)


func _assign_overlay(node: Node) -> void:
	var mesh: MeshInstance3D = node as MeshInstance3D
	if mesh != null:
		mesh.material_overlay = _overlay
	for child: Node in node.get_children():
		_assign_overlay(child)


## The resting tint: the stage colour, or the jam colour for a jammed fresh enemy.
func _rest_tint() -> Color:
	if stage > 0:
		return STAGE_TINTS[clampi(stage, 0, STAGE_SOGGY)]
	return JAM_TINT if jammed else STAGE_TINTS[0]


## Applies the resting tint and the sag. Safe without a scene (tests).
func _refresh_visual() -> void:
	if _visual == null or _overlay == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_overlay.albedo_color = _rest_tint()
	_visual.scale = Vector3(1.0 + SAG_PER_STAGE * 0.5 * stage, 1.0 - SAG_PER_STAGE * stage, 1.0)


## A short yellow flash: the enemy slurped the hit up.
func _play_slurp() -> void:
	if _overlay == null or not is_inside_tree():
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_overlay.albedo_color = SLURP_TINT
	_flash_tween = create_tween()
	_flash_tween.tween_property(_overlay, "albedo_color", _rest_tint(), slurp_time)
