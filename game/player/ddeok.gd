extends CharacterBody3D
## The 떡. A CharacterBody3D locked to the X/Y plane with a fixed collision shape.
## All numbers come from MovementTuning (res://data/movement_tuning.tres).
## Only the child visual deforms (ddeok_visual.gd); the collision never does.

signal state_changed(old_state: int, new_state: int)
signal landed(impact_speed: float)
signal attacked(attack: String, reaction: String)
signal respawned
## He got free of a `stick` (reason: "wiggle" | "enemy_hits" | "timeout").
signal stick_released(reason: String)
## A sauce attack was fired.
signal sauce_fired
## Flick unlocked but not enough sauce. (A locked flick emits nothing, on purpose.)
signal sauce_refused
## An environment object was set off (the special action).
signal special_used(object: Node3D)
## `special` pressed on a target with too little 나트륨.
signal special_refused

enum State { IDLE, SQUIGGLE, JUMP, FALL, STOMP, ROLL, SLAM, HURT, DEAD }

const STATE_NAMES: Array[String] = [
	"idle", "squiggle", "jump", "fall", "stomp", "roll", "slam", "hurt", "dead",
]

const GameStateScript := preload("res://systems/game_state.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const DdeokVisualScript := preload("res://player/ddeok_visual.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const SauceTuningScript := preload("res://systems/sauce_tuning.gd")
const SauceFlickScript := preload("res://projectiles/sauce_flick.gd")
const Layers := preload("res://systems/layers.gd")
const SettingsScript := preload("res://systems/settings.gd")
const HealthPickupScene: PackedScene = preload("res://items/health_pickup.tscn")
const UsableObjectScript := preload("res://items/usable_object.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")
const StuckStatusScript := preload("res://systems/stuck_status.gd")
const StickDefScript := preload("res://hazards/stick_def.gd")

## A dropped item cannot be picked up again for this long (seconds).
const DROP_REPICK_DELAY_S: float = 1.0

const TUNING_PATH: String = "res://data/movement_tuning.tres"
const SAUCE_TUNING_PATH: String = "res://data/sauce_tuning.tres"

const ACTION_LEFT: StringName = &"move_left"
const ACTION_RIGHT: StringName = &"move_right"
const ACTION_DOWN: StringName = &"look_down"
const ACTION_JUMP: StringName = &"jump"
const ACTION_ROLL: StringName = &"roll"
const ACTION_SAUCE: StringName = &"sauce_attack"
const ACTION_SAUCE_NEXT: StringName = &"sauce_next"
const ACTION_SAUCE_PREV: StringName = &"sauce_prev"
const ACTION_HEAL: StringName = &"heal"
const ACTION_SPECIAL: StringName = &"special"

const SKILL_JUMP: String = "jump"
const SKILL_LANDING: String = "landing"
const SKILL_STOMP: String = "stomp"
const SKILL_ROLL: String = "roll"
const SKILL_SLAM: String = "slam"
const SKILL_SAUCE_FLICK: String = "sauce_flick"

@export var tuning: MovementTuningScript
@export var sauce_tuning: SauceTuningScript
## Half the body's height. Matches the capsule radius (he lies on his side).
@export var body_half_height: float = 0.32

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
## Injected by tests; falls back to the Settings autoload (the heal-default item).
var settings: SettingsScript
var state: State = State.IDLE
## See set_controlled().
var controlled: bool = false
## +1 faces right, -1 faces left.
var facing: float = 1.0
## Updated after every move; tests may set it directly.
var grounded: bool = false
## The usable object the special action would set off right now (null = none in range), and
## how many were in range. The nearest one wins.
var special_target: UsableObjectScript = null
var special_candidates: int = 0
## The `stick` status (gum): null = not stuck. While stuck he cannot walk, jump or roll.
var stuck: StuckStatusScript = null
## Whoever holds him (a pair of chopsticks): null = free. Held: no input, no physics, no damage.
var held_by: Node = null
## Seconds the slippery-floor effect is still on (a spilled 김밥 keeps refreshing it).
var slip_left: float = 0.0
## Seconds he is still flattened (a giant foot): no input, then he pops back.
var flat_left: float = 0.0

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _invuln_timer: float = 0.0
var _hurt_timer: float = 0.0
var _roll_timer: float = 0.0
## Letting go of jump cuts the rise only of a jump he made himself, never a bounce off an enemy.
var _jump_cut_allowed: bool = true
var _roll_cooldown: float = 0.0
var _sauce_cooldown: float = 0.0
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
	if settings == null:
		settings = get_node_or_null("/root/Settings") as SettingsScript
	if game_state != null and not game_state.item_dropped.is_connected(_on_item_dropped):
		game_state.item_dropped.connect(_on_item_dropped)
	if _visual != null:
		landed.connect(_visual.on_landed)
		if game_state != null:
			game_state.coat_changed.connect(_visual.set_coat)
			_visual.set_coat(game_state.coat)


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
	if stuck != null or not _can_act() or state == State.ROLL or state == State.STOMP or state == State.SLAM:
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


## Sauce attack button. Needs the "sauce_flick" skill: while locked it does nothing at all
## (no signal, no feedback). Unlocked but short of sauce: no shot, sauce_refused fires.
## Otherwise spends the cost and fires a flick straight ahead. Returns whether it fired.
func request_sauce_attack() -> bool:
	_ensure_sauce_tuning()
	if not _can_act() or not _has_skill(SKILL_SAUCE_FLICK) or game_state == null:
		return false
	if game_state.sauce < sauce_tuning.flick_cost:
		sauce_refused.emit()
		return false
	if _sauce_cooldown > 0.0:
		return false
	if not game_state.spend_sauce(sauce_tuning.flick_cost):
		return false
	_sauce_cooldown = sauce_tuning.flick_cooldown_s
	_spawn_flick()
	sauce_fired.emit()
	return true


## Environment special (right mouse / Y). Sets off the nearest usable object in range, spending its
## 나트륨. Too little 나트륨: nothing happens and special_refused fires. Returns whether it went off.
func request_special() -> bool:
	if not _can_act() or game_state == null:
		return false
	_update_special_target()
	if special_target == null:
		return false
	var target: UsableObjectScript = special_target
	if not target.try_use(game_state, facing):
		if game_state.sodium < target.cost():
			special_refused.emit()
		return false
	special_used.emit(target)
	_update_special_target()
	return true


## Finds the nearest usable object in range and highlights it: bright if he can pay for it, dim
## if not. Everything else is un-highlighted.
func _update_special_target() -> void:
	var best: UsableObjectScript = null
	var best_distance: float = INF
	var count: int = 0
	if is_inside_tree():
		for node: Node in get_tree().get_nodes_in_group("usable_objects"):
			var obj: UsableObjectScript = node as UsableObjectScript
			if obj == null or not obj.in_range_of(global_position):
				continue
			count += 1
			var d: float = obj.distance_to(global_position)
			if d < best_distance:
				best_distance = d
				best = obj
	special_candidates = count
	if special_target != best and is_instance_valid(special_target):
		special_target.set_highlight(UsableObjectScript.Highlight.NONE)
	special_target = best
	if best != null and game_state != null:
		best.set_highlight(UsableObjectScript.Highlight.BRIGHT 
			if game_state.sodium >= best.cost() else UsableObjectScript.Highlight.DIM)


## Seconds until the next flick may fire (0 = ready).
func sauce_cooldown_left() -> float:
	return _sauce_cooldown


## Heal button: uses the least-healing carried item first (or the Settings default item
## when held). At full hearts it does nothing. Returns whether an item was used.
func request_heal() -> bool:
	if game_state == null or state == State.DEAD:
		return false
	var preferred: String = settings.heal_default if settings != null else "lowest"
	return game_state.heal_button(preferred) != ""


## Takes contact or hazard damage (half-hearts). False if ignored (invulnerable or dead).
## A coat blocks the damage of this hit; knockback and invulnerability still happen.
func hurt(half_hearts: int, source_x: float) -> bool:
	_ensure_tuning()
	if game_state == null or state == State.DEAD or _invuln_timer > 0.0 or held_by != null:
		return false
	game_state.take_hit(half_hearts)
	if stuck != null:
		stuck.enemy_hit() # a hit on him shakes him loose, a bit at a time
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
	if is_inside_tree():
		reset_physics_interpolation() # teleport: do not blend from the death spot
	velocity = Vector3.ZERO
	grounded = false
	_prev_bottom = global_position.y - body_half_height
	_invuln_timer = tuning.i_frame_time
	_hurt_timer = 0.0
	_roll_timer = 0.0
	_drop_timer = 0.0
	_above_hits.clear()
	stuck = null
	held_by = null
	controlled = false
	slip_left = 0.0
	flat_left = 0.0
	_set_state(State.IDLE)
	respawned.emit()


## While true a scripted sequence owns him: no input, no physics, no gravity (timers still run).
## Whoever sets it moves global_position itself. Releasing him lets him fall.
func set_controlled(on: bool) -> void:
	if controlled == on:
		return
	controlled = on
	velocity = Vector3.ZERO
	if not on:
		grounded = false
		_coyote_timer = 0.0
		_buffer_timer = 0.0
		_prev_bottom = global_position.y - body_half_height
		_set_state(State.FALL)


# --- Hazard statuses (gum, chopsticks, a giant foot, a slippery floor) -----------------------

## Gum: he is stuck until the wiggle, enemy hits or the fallback timer frees him. Returns false when
## he already is, is dead or is held.
func apply_stick(def: StickDefScript, source: Object = null) -> bool:
	if stuck != null or state == State.DEAD or held_by != null:
		return false
	stuck = StuckStatusScript.new(def, source)
	velocity.x = 0.0
	return true


func is_stuck() -> bool:
	return stuck != null


## True while this very thing (a gum patch) is what holds him.
func is_stuck_by(source: Object) -> bool:
	return stuck != null and stuck.source == source


## Chopsticks pick him up: scripted, and no damage until he is let go. Returns false if he cannot be held.
func grab(by: Node) -> bool:
	if held_by != null or state == State.DEAD:
		return false
	held_by = by
	stuck = null
	set_controlled(true)
	return true


func release_grab() -> void:
	if held_by == null:
		return
	held_by = null
	set_controlled(false)
	_ensure_tuning()
	_invuln_timer = maxf(_invuln_timer, tuning.i_frame_time * 0.5)


## A giant foot: damage and a short flat stun, no knockback. False if he is invulnerable, held or dead.
func smoosh(half_hearts: int, stun_s: float) -> bool:
	_ensure_tuning()
	if game_state == null or state == State.DEAD or _invuln_timer > 0.0 or held_by != null:
		return false
	game_state.take_hit(half_hearts)
	if state == State.DEAD:
		return true
	_invuln_timer = tuning.i_frame_time
	flat_left = stun_s
	velocity = Vector3.ZERO
	return true


## The floor under him is slippery for this many more seconds (a patch refreshes it every tick).
func apply_slip(seconds: float) -> void:
	slip_left = maxf(slip_left, seconds)


func is_invulnerable() -> bool:
	return _invuln_timer > 0.0


func state_name() -> String:
	return STATE_NAMES[state]


# --- Frame loop --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_ensure_tuning()
	_tick_timers(delta)
	if controlled:
		velocity = Vector3.ZERO # a scripted sequence moves him (the prologue's pick)
		return
	_handle_sauce_input()
	_update_special_target()
	if GameplayInputScript.just_pressed(ACTION_SPECIAL):
		request_special()
	if GameplayInputScript.just_pressed(ACTION_HEAL):
		request_heal()

	# Overlaps reflect last frame's move; _prev_bottom is where the feet were before it.
	var bottom_now: float = global_position.y - body_half_height
	_resolve_enemy_contacts()
	_prev_bottom = bottom_now

	_step_stick(delta)
	match state:
		State.DEAD:
			_step_dead(delta)
		_ when flat_left > 0.0:
			_step_flat(delta)
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
	if flat_left > 0.0:
		_visual.scale = Vector3(1.3, 0.3, 1.0) # flattened by a foot (gray box); the visual eases back afterwards


func _tick_timers(delta: float) -> void:
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_buffer_timer = maxf(_buffer_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	_roll_timer = maxf(_roll_timer - delta, 0.0)
	_roll_cooldown = maxf(_roll_cooldown - delta, 0.0)
	_sauce_cooldown = maxf(_sauce_cooldown - delta, 0.0)
	slip_left = maxf(slip_left - delta, 0.0)
	flat_left = maxf(flat_left - delta, 0.0)
	_drop_timer = maxf(_drop_timer - delta, 0.0)
	_dead_timer = maxf(_dead_timer - delta, 0.0)


# --- Dropped items -----------------------------------------------------------------------

## An item dropped from the inventory appears at the 떡's feet, and cannot be re-picked up
## for DROP_REPICK_DELAY_S.
func _on_item_dropped(item_id: String) -> void:
	var parent: Node = get_parent()
	if not is_inside_tree() or parent == null:
		return
	var pickup: Node3D = HealthPickupScene.instantiate() as Node3D
	pickup.set("item_id", item_id)
	pickup.set("pickup_delay", DROP_REPICK_DELAY_S)
	pickup.set("dropped", true)
	parent.add_child(pickup)
	pickup.global_position = global_position + Vector3(0.0, 0.3 - body_half_height, 0.0)


# --- Sauce -------------------------------------------------------------------------------

func _handle_sauce_input() -> void:
	if GameplayInputScript.just_pressed(ACTION_SAUCE):
		request_sauce_attack()
	# Cycling is part of the sauce skill: locked = nothing, same as the attack.
	if game_state != null and _has_skill(SKILL_SAUCE_FLICK):
		if GameplayInputScript.just_pressed(ACTION_SAUCE_NEXT):
			game_state.cycle_sauce_type(1)
		if GameplayInputScript.just_pressed(ACTION_SAUCE_PREV):
			game_state.cycle_sauce_type(-1)


## A flick straight ahead (facing), horizontal, in the 떡's own plane.
func _spawn_flick() -> void:
	var parent: Node = get_parent()
	if not is_inside_tree() or parent == null:
		return
	var flick: SauceFlickScript = SauceFlickScript.new()
	var sauce_type: Variant = game_state.current_sauce_type()
	if sauce_type != null:
		flick.color = sauce_type.color
	flick.launch(Vector2(facing, 0.0), sauce_tuning.flick_speed_mps, sauce_tuning.flick_range_m)
	parent.add_child(flick)
	flick.global_position = global_position + Vector3(facing * 0.55, 0.0, 0.0)


# --- State steps -------------------------------------------------------------------------

## Idle / squiggle / jump / fall.
func _step_free(delta: float, input_x: float) -> void:
	var pushing: bool = not is_zero_approx(input_x)
	if pushing:
		facing = signf(input_x)
	var accel: float
	if grounded:
		accel = tuning.acceleration if pushing else tuning.friction
		if slip_left > 0.0:
			accel *= tuning.slip_acceleration_scale if pushing else tuning.slip_friction_scale
	else:
		accel = tuning.air_acceleration if pushing else tuning.air_friction
	# Input strength scales the target speed: a light push is a slow squiggle.
	velocity.x = move_toward(velocity.x, input_x * tuning.max_speed, accel * delta)
	if stuck != null:
		velocity.x = 0.0 # stuck: no walking
	_apply_gravity(delta)

	if GameplayInputScript.just_pressed(ACTION_JUMP):
		_buffer_timer = tuning.buffer_time
	if stuck != null:
		_buffer_timer = 0.0 # nor jumping
	if _buffer_timer > 0.0 and (grounded or _coyote_timer > 0.0) and _has_skill(SKILL_JUMP):
		_start_jump()
	if Input.is_action_just_released(ACTION_JUMP) and velocity.y > 0.0 and state == State.JUMP and _jump_cut_allowed:
		velocity.y *= tuning.short_hop_cut

	if GameplayInputScript.just_pressed(ACTION_DOWN):
		if not grounded:
			request_stomp()
		elif _on_one_way:
			_start_drop_through()
	if GameplayInputScript.just_pressed(ACTION_ROLL):
		request_roll()

	if state == State.STOMP or state == State.SLAM or state == State.ROLL:
		return
	if grounded:
		_set_state(State.SQUIGGLE if pushing or not is_zero_approx(velocity.x) else State.IDLE)
	else:
		_set_state(State.JUMP if velocity.y > 0.0 else State.FALL)


## The stick status: the wiggle presses and the fallback timer; he is free when one of them says so.
func _step_stick(delta: float) -> void:
	if held_by != null and not is_instance_valid(held_by):
		release_grab() # whatever held him is gone (section reset): never stay held
	if stuck == null:
		return
	if GameplayInputScript.just_pressed(ACTION_LEFT):
		stuck.press(-1)
	if GameplayInputScript.just_pressed(ACTION_RIGHT):
		stuck.press(1)
	stuck.tick(delta)
	if stuck.released:
		var why: String = stuck.reason
		stuck = null
		stick_released.emit(why)


## Flattened by a foot: he cannot move for a moment, then he pops back.
func _step_flat(delta: float) -> void:
	velocity.x = 0.0
	_apply_gravity(delta)
	if flat_left <= 0.0:
		_set_state(State.IDLE if grounded else State.FALL)


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
	_jump_cut_allowed = true
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
	if (result["reactions"] as Array).has(ReactionTableScript.REACTION_HURT_PLAYER):
		hurt(enemy.contact_damage(), enemy.global_position.x)
	elif attack == ReactionTableScript.ATTACK_LANDING or attack == ReactionTableScript.ATTACK_STOMP:
		velocity.y = tuning.bounce_velocity
		_jump_cut_allowed = false # letting go of the button must not cut a bounce (the 단무지's throw to the ledge)
		if (result["reactions"] as Array).has(ReactionTableScript.REACTION_BOUNCE_BOOST):
			velocity.y *= tuning.bounce_boost_multiplier * enemy.bounce_multiplier()
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
				if (result["reactions"] as Array).has(ReactionTableScript.REACTION_HURT_PLAYER):
					hurt(enemy.contact_damage(), enemy.global_position.x)
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


func _ensure_sauce_tuning() -> void:
	if sauce_tuning == null:
		sauce_tuning = load(SAUCE_TUNING_PATH) as SauceTuningScript
