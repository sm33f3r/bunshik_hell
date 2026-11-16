extends CharacterBody3D
## Shared enemy base: health, hurt, death, reaction lookup, contact damage.
## Enemies differ by their EnemyDef .tres and, at most, a small behaviour script
## that overrides _ai(). All damage goes through the ReactionTable.
## Origin is at the enemy's feet.

signal hurt(hp: int)
signal died

const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const Layers := preload("res://systems/layers.gd")
const TABLE_PATH: String = "res://data/reaction_table.tres"

@export var def: EnemyDefScript
@export var reaction_table: ReactionTableScript
## Distance from the origin (feet) to the top of the body.
@export var body_height: float = 1.0
@export var gravity: float = 30.0
@export var max_fall_speed: float = 28.0
## Seconds the tip-over animation takes.
@export var tip_over_time: float = 0.5
@export var vanish_time: float = 0.2

var hp: int = 0
var alive: bool = true

var _spawn_transform: Transform3D
var _lock_z: float = 0.0
var _visual: Node3D
var _tween: Tween


func _ready() -> void:
	add_to_group("enemies")
	axis_lock_linear_z = true
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	_spawn_transform = transform
	_lock_z = position.z
	_visual = get_node_or_null("Visual") as Node3D
	setup()
	_on_ready()


## Idempotent. Also what tests call, since they never enter the scene tree.
func setup() -> void:
	if reaction_table == null:
		reaction_table = load(TABLE_PATH) as ReactionTableScript
	if def != null:
		hp = def.max_hp
	alive = true


func contact_damage() -> int:
	return def.contact_damage_half_hearts if def != null else 0


func top_y() -> float:
	return global_position.y + body_height


func center_xy() -> Vector2:
	return Vector2(global_position.x, global_position.y + body_height * 0.5)


## Looks the hit up in the reaction table and applies it.
## Returns {"reaction": String, "damage": int, "killed": bool}.
func receive_attack(attack: String, hit_dir: float = 1.0) -> Dictionary:
	if not alive or def == null or reaction_table == null:
		return {"reaction": ReactionTableScript.REACTION_ABSORB, "damage": 0, "killed": false}
	var result: Dictionary = reaction_table.lookup(attack, def.material)
	var reaction: String = result["reaction"]
	var damage: int = result["damage"]
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
	return {"reaction": reaction, "damage": damage, "killed": not alive}


## Brings a dead or damaged enemy back to its spawn state (debug F3, tests).
func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
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
