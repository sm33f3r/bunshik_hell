extends CharacterBody3D
## The 떡. A CharacterBody3D locked to the X/Y plane with a fixed collision shape.
## All numbers come from MovementTuning (res://data/movement_tuning.tres).
## Only the child visual deforms (ddeok_visual.gd); the collision never does.

signal state_changed(old_state: int, new_state: int)
signal landed(impact_speed: float)
signal attacked(attack: String, reaction: String)
signal respawned

enum State { IDLE, SQUIGGLE, JUMP, FALL, STOMP, ROLL, SLAM, HURT, DEAD }

const STATE_NAMES: Array[String] = [
	"idle", "squiggle", "jump", "fall", "stomp", "roll", "slam", "hurt", "dead",
]

const GameStateScript := preload("res://systems/game_state.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const DdeokVisualScript := preload("res://player/ddeok_visual.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const Layers := preload("res://systems/layers.gd")

const TUNING_PATH: String = "res://data/movement_tuning.tres"

const ACTION_LEFT: StringName = &"move_left"
const ACTION_RIGHT: StringName = &"move_right"
const ACTION_DOWN: StringName = &"look_down"
const ACTION_JUMP: StringName = &"jump"
const ACTION_ROLL: StringName = &"roll"

const SKILL_JUMP: String = "jump"
const SKILL_LANDING: String = "landing"
const SKILL_STOMP: String = "stomp"
const SKILL_ROLL: String = "roll"
const SKILL_SLAM: String = "slam"

@export var tuning: MovementTuningScript
## Half the body's height. Matches the capsule radius (he lies on his side).
@export var body_half_height: float = 0.32

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var state: State = State.IDLE
## +1 faces right, -1 faces left.
var facing: float = 1.0
## Updated after every move; tests may set it directly.
var grounded: bool = false

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _invuln_timer: float = 0.0
var _hurt_timer: float = 0.0
var _roll_timer: float = 0.0
var _roll_cooldown: float = 0.0
var _roll_dir: float = 1.0
var _drop_timer: float = 0.0
var _dead_timer: float = 0.0
var _prev_bottom: float = 0.0
var _last_vy: float = 0.0
var _on_one_way: bool = false
var _lock_z: float = 0.0
var _roll_hits: Array[int] = []
## Enemies just hit from above. Ignored until the contact ends, so the frame after a
## bounce (feet still inside) is not mistaken for a side hit.
var _above_hits: Array[int] = []

var _visual: DdeokVisualScript
var _contact_area: Area3D
var _one_way_sensor: Area3D


func _ready() -> void:
	_ensure_tuning()
	add_to_group("player")
	axis_lock_linear_z = true
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	collision_layer = Layers.PLAYER
	collision_mask = Layers.WORLD | Layers.ONE_WAY
	_lock_z = global_position.z
	_prev_bottom = global_position.y - body_half_height

	_visual = get_node_or_null("FacingPivot/Visual") as DdeokVisualScript
	_contact_area = get_node_or_null("ContactArea") as Area3D
	if _contact_area != null:
		_contact_area.collision_layer = 0
		_contact_area.collision_mask = Layers.ENEMY
	_one_way_sensor = get_node_or_null("OneWaySensor") as Area3D
	if _one_way_sensor != null:
		_one_way_sensor.collision_layer = 0
		_one_way_sensor.collision_mask = Layers.ONE_WAY

	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state != null and not game_state.died.is_connected(_on_died):
		game_state.died.connect(_on_died)
	if _visual != null:
		landed.connect(_visual.on_landed)


# --- Requests (also what the tests drive; they return whether anything started) ----------

## Down in the air: stomp. Needs the "stomp" skill.
func request_stomp() -> bool:
	_ensure_tuning()
	if grounded or not _can_act() or state == State.STOMP or state == State.SLAM or state == State.ROLL:
		return false
	if not _has_skill(SKILL_STOMP):
		return false
	velocity = Vector3(0.0, -tuning.stomp_speed, 0.0)
	_set_state(State.STOMP)
	return true


## Roll button. On the ground: roll (needs "roll"). In the air: slam (needs "slam").
func request_roll() -> bool:
	_ensure_tuning()
	if not _can_act() or state == State.ROLL or state == State.STOMP or state == State.SLAM:
		return false
	if grounded:
		if not _has_skill(SKILL_ROLL) or _roll_cooldown > 0.0:
			return false
		var dir: float = signf(Input.get_axis(ACTION_LEFT, ACTION_RIGHT))
		_roll_dir = dir if dir != 0.0 else facing
		facing = _roll_dir
		_roll_timer = tuning.roll_duration
		_roll_hits.clear()
		velocity.x = _roll_dir * tuning.roll_speed
		_set_state(State.ROLL)
		return true
	if not _has_skill(SKILL_SLAM):
		return false
	velocity = Vector3(0.0, -tuning.slam_speed, 0.0)
	_set_state(State.SLAM)
	return true


## Takes contact or hazard damage (half-hearts). False if ignored (invulnerable or dead).
func hurt(half_hearts: int, source_x: float) -> bool:
	_ensure_tuning()
	if game_state == null or state == State.DEAD or _invuln_timer > 0.0:
		return false
	game_state.take_damage(half_hearts)
	if state == State.DEAD:
		return true # the died signal got there first
	_invuln_timer = tuning.i_frame_time
	_hurt_timer = tuning.hurt_stun_time
	var away: float = signf(global_position.x - source_x) if is_inside_tree() else 0.0
	if away == 0.0:
		away = -facing
	velocity = Vector3(away * tuning.knockback_horizontal, tuning.knockback_vertical, 0.0)
	grounded = false
	_set_state(State.HURT)
	return true


## Falling out of the world: always lethal, ignores invulnerability.
func kill() -> void:
	if game_state != null and not game_state.is_dead():
		game_state.take_damage(game_state.hearts)


func respawn() -> void:
	_ensure_tuning()
	if game_state == null:
		return
	global_position = game_state.respawn()
	velocity = Vector3.ZERO
	grounded = false
	_prev_bottom = global_position.y - body_half_height
	_invuln_timer = tuning.i_frame_time
	_hurt_timer = 0.0
	_roll_timer = 0.0
	_drop_timer = 0.0
	_above_hits.clear()
	_set_state(State.IDLE)
	respawned.emit()


func is_invulnerable() -> bool:
	return _invuln_timer > 0.0


func state_name() -> String:
	return STATE_NAMES[state]


# --- Frame loop --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_ensure_tuning()
	_tick_timers(delta)

	# Overlaps reflect last frame's move; _prev_bottom is where the feet were before it.
	var bottom_now: float = global_position.y - body_half_height
	_resolve_enemy_contacts()
	_prev_bottom = bottom_now

	match state:
		State.DEAD:
			_step_dead(delta)
		State.HURT:
			_step_hurt(delta)
		State.ROLL:
			_step_roll(delta)
		State.STOMP, State.SLAM:
			_step_dive()
		_:
			_step_free(delta, Input.get_axis(ACTION_LEFT, ACTION_RIGHT))

	_update_one_way_mask()
	velocity.z = 0.0
	_last_vy = velocity.y
	move_and_slide()
	if not is_equal_approx(global_position.z, _lock_z):
		global_position.z = _lock_z
	_after_move()


func _process(delta: float) -> void:
	if _visual == null or tuning == null:
		return
	var speed_ratio: float = absf(velocity.x) / tuning.max_speed
	_visual.update_visual(delta, state_name(), speed_ratio, velocity.y, facing)
	var flashing: bool = _invuln_timer > 0.0 and state != State.DEAD \
		and int(_invuln_timer / tuning.flash_interval) % 2 == 0
	_visual.set_flash(flashing)


func _tick_timers(delta: float) -> void:
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_buffer_timer = maxf(_buffer_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	_roll_timer = maxf(_roll_timer - delta, 0.0)
	_roll_cooldown = maxf(_roll_cooldown - delta, 0.0)
	_drop_timer = maxf(_drop_timer - delta, 0.0)
	_dead_timer = maxf(_dead_timer - delta, 0.0)


# --- State steps -------------------------------------------------------------------------

## Idle / squiggle / jump / fall.
func _step_free(delta: float, input_x: float) -> void:
	var pushing: bool = not is_zero_approx(input_x)
	if pushing:
		facing = signf(input_x)
	var accel: float
	if grounded:
		accel = tuning.acceleration if pushing else tuning.friction
	else:
		accel = tuning.air_acceleration if pushing else tuning.air_friction
	# Input strength scales the target speed: a light push is a slow squiggle.
	velocity.x = move_toward(velocity.x, input_x * tuning.max_speed, accel * delta)
	_apply_gravity(delta)

	if Input.is_action_just_pressed(ACTION_JUMP):
		_buffer_timer = tuning.buffer_time
	if _buffer_timer > 0.0 and (grounded or _coyote_timer > 0.0) and _has_skill(SKILL_JUMP):
		_start_jump()
	if Input.is_action_just_released(ACTION_JUMP) and velocity.y > 0.0 and state == State.JUMP:
		velocity.y *= tuning.short_hop_cut

	if Input.is_action_just_pressed(ACTION_DOWN):
		if not grounded:
			request_stomp()
		elif _on_one_way:
			_start_drop_through()
	if Input.is_action_just_pressed(ACTION_ROLL):
		request_roll()

	if state == State.STOMP or state == State.SLAM or state == State.ROLL:
		return
	if grounded:
		_set_state(State.SQUIGGLE if pushing or not is_zero_approx(velocity.x) else State.IDLE)
	else:
		_set_state(State.JUMP if velocity.y > 0.0 else State.FALL)


func _step_roll(delta: float) -> void:
	velocity.x = _roll_dir * tuning.roll_speed
	_apply_gravity(delta)
	if _roll_timer <= 0.0:
		_roll_cooldown = tuning.roll_cooldown
		_roll_hits.clear()
		_set_state(State.IDLE if grounded else State.FALL)


func _step_dive() -> void:
	velocity.x = 0.0
	velocity.y = -(tuning.stomp_speed if state == State.STOMP else tuning.slam_speed)


func _step_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, tuning.air_friction * delta)
	_apply_gravity(delta)
	if _hurt_timer <= 0.0:
		_set_state(State.IDLE if grounded else State.FALL)


func _step_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, tuning.friction * delta)
	_apply_gravity(delta)
	if _dead_timer <= 0.0:
		respawn()


func _apply_gravity(delta: float) -> void:
	var g: float = tuning.gravity * (tuning.fall_gravity_scale if velocity.y < 0.0 else 1.0)
	velocity.y = maxf(velocity.y - g * delta, -tuning.max_fall_speed)


func _start_jump() -> void:
	velocity.y = tuning.jump_velocity
	_buffer_timer = 0.0
	_coyote_timer = 0.0
	grounded = false
	_set_state(State.JUMP)


func _start_drop_through() -> void:
	_drop_timer = tuning.drop_through_time
	_coyote_timer = 0.0
	_on_one_way = false
	grounded = false


func _after_move() -> void:
	var was_grounded: bool = grounded
	grounded = is_on_floor()
	_on_one_way = false
	if grounded:
		_coyote_timer = tuning.coyote_time
		for i: int in get_slide_collision_count():
			var hit: KinematicCollision3D = get_slide_collision(i)
			var collider: Node = hit.get_collider() as Node
			if collider != null and collider.is_in_group("one_way") and hit.get_normal().y > 0.5:
				_on_one_way = true
	if grounded and not was_grounded:
		landed.emit(absf(_last_vy))
		if state == State.STOMP:
			_set_state(State.IDLE)
		elif state == State.SLAM:
			_slam_impact()


## One-way platforms live on their own layer. The player collides with it only while
## moving down (or still), not dropping through, and with his feet at or above the top.
func _update_one_way_mask() -> void:
	var allow: bool = velocity.y <= 0.0 and _drop_timer <= 0.0
	if allow and _one_way_sensor != null:
		var feet: float = global_position.y - body_half_height
		for body: Node3D in _one_way_sensor.get_overlapping_bodies():
			if body.has_method("top_y") and feet < float(body.call("top_y")) - tuning.one_way_tolerance:
				allow = false
				break
	collision_mask = Layers.WORLD | (Layers.ONE_WAY if allow else 0)


# --- Combat ------------------------------------------------------------------------------

func _resolve_enemy_contacts() -> void:
	if _contact_area == null or state == State.DEAD:
		return
	var overlapping: Array[int] = []
	for body: Node3D in _contact_area.get_overlapping_bodies():
		var enemy: EnemyBaseScript = body as EnemyBaseScript
		if enemy == null or not enemy.alive:
			continue
		overlapping.append(enemy.get_instance_id())
		if not _above_hits.has(enemy.get_instance_id()):
			_handle_contact(enemy)
	var still: Array[int] = []
	for id: int in _above_hits:
		if overlapping.has(id):
			still.append(id)
	_above_hits = still


func _handle_contact(enemy: EnemyBaseScript) -> void:
	var was_above: bool = _prev_bottom >= enemy.top_y() - tuning.above_tolerance
	if was_above:
		if velocity.y > 0.0:
			return # rising away from it
		if state == State.SLAM:
			_above_hits.append(enemy.get_instance_id())
			_slam_impact()
		elif state == State.STOMP:
			_above_hits.append(enemy.get_instance_id())
			_hit_enemy(enemy, ReactionTableScript.ATTACK_STOMP)
		elif _has_skill(SKILL_LANDING):
			_above_hits.append(enemy.get_instance_id())
			_hit_enemy(enemy, ReactionTableScript.ATTACK_LANDING)
		return
	if state == State.ROLL:
		var id: int = enemy.get_instance_id()
		if not _roll_hits.has(id):
			_roll_hits.append(id)
			_hit_enemy(enemy, ReactionTableScript.ATTACK_ROLL)
		return
	hurt(enemy.contact_damage(), enemy.global_position.x)


func _hit_enemy(enemy: EnemyBaseScript, attack: String) -> void:
	var dir: float = signf(enemy.global_position.x - global_position.x)
	var result: Dictionary = enemy.receive_attack(attack, dir if dir != 0.0 else facing)
	var reaction: String = result["reaction"]
	attacked.emit(attack, reaction)
	if reaction == ReactionTableScript.REACTION_HURT_PLAYER:
		hurt(enemy.contact_damage(), enemy.global_position.x)
	elif attack == ReactionTableScript.ATTACK_LANDING or attack == ReactionTableScript.ATTACK_STOMP:
		velocity.y = tuning.bounce_velocity
		grounded = false
		_set_state(State.JUMP)


## Slam landing: hits every living enemy within slam_radius of the landing point.
func _slam_impact() -> void:
	if is_inside_tree():
		var origin: Vector2 = Vector2(global_position.x, global_position.y)
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			var enemy: EnemyBaseScript = node as EnemyBaseScript
			if enemy == null or not enemy.alive:
				continue
			if origin.distance_to(enemy.center_xy()) <= tuning.slam_radius:
				var dir: float = signf(enemy.global_position.x - global_position.x)
				var result: Dictionary = enemy.receive_attack(
					ReactionTableScript.ATTACK_SLAM, dir if dir != 0.0 else facing)
				attacked.emit(ReactionTableScript.ATTACK_SLAM, result["reaction"])
	_set_state(State.IDLE if grounded else State.FALL)


# --- Helpers -----------------------------------------------------------------------------

func _on_died() -> void:
	_ensure_tuning()
	_dead_timer = tuning.respawn_delay
	_roll_hits.clear()
	_set_state(State.DEAD)


func _can_act() -> bool:
	return state != State.DEAD and state != State.HURT


func _has_skill(skill_id: String) -> bool:
	return game_state != null and game_state.has_skill(skill_id)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old_state: State = state
	state = new_state
	state_changed.emit(old_state, new_state)


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = load(TUNING_PATH) as MovementTuningScript
