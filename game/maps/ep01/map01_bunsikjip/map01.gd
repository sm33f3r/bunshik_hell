extends Node3D
## Map 1 (lunch 분식집), gray box. For now only the prologue lives here (Task 3a): the opening
## cutscene, the pick and the wiggle, the 30 stabs at the window counter, and the exit to the
## next table. All the rules are in PrologueDirector; this node moves things and draws them.

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const ActorScript := preload("res://prologue/prologue_actor.gd")
const UiScript := preload("res://prologue/prologue_ui.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

## Physics ticks at the start during which the skip button is ignored.
const SKIP_GUARD_TICKS: int = 8
## The 떡's centre sits this far above the pick tip while he is speared.
const SPEAR_OFFSET: float = 0.3
## He slides off the pick this far to the side.
const SLIDE_OFF_X: float = 0.6
const SQUIRM_ANGLE: float = 0.5
const SQUIRM_DECAY: float = 3.5
const SHAKE_AMOUNT: float = 0.35
## Below this height the 떡 has fallen out of the world.
@export var kill_y: float = -12.0

@export var player: DdeokScript
@export var camera: Camera3D
## Invisible walls: StaticBody3D children, each with a CollisionShape3D.
@export var walls: Node3D
## The pick the 30th stab leaves in the counter (a StaticBody3D with a CollisionShape3D).
@export var stuck_pick: StaticBody3D
## The 만두 props on her plate (MeshInstance3D children).
@export var plate: Node3D
@export var data: PrologueDataScript

var director: DirectorScript
var actor: ActorScript
var ui: UiScript
var game_state: GameStateScript

var _ticks: int = 0
var _squirm: float = 0.0
var _squirm_phase: float = 0.0
var _facing_pivot: Node3D
var _was_controlled: bool = false


func _ready() -> void:
	add_to_group("prologue_map")
	game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state == null or player == null:
		return
	if data == null:
		data = load(DirectorScript.DATA_PATH) as PrologueDataScript
	_facing_pivot = player.get_node_or_null("FacingPivot") as Node3D

	director = DirectorScript.new(data, game_state)
	director.apply_damage = Callable(self, "_hurt_player")
	director.restarted.connect(_on_restarted)
	director.exit_opened.connect(_on_exit_opened)
	director.completed.connect(_on_completed)
	director.wiggle_pressed.connect(_on_wiggle_pressed)
	player.respawned.connect(director.on_player_respawned)

	actor = ActorScript.new()
	actor.name = "PrologueActor"
	actor.counter_y = data.counter_top_y
	add_child(actor)
	ui = UiScript.new()
	ui.name = "PrologueUi"
	add_child(ui)

	_set_world_open(false)
	director.begin()
	if director.state == DirectorScript.State.COMPLETE:
		# Loaded after the prologue was done: no stabbing, the way on is open.
		_set_world_open(true)
		player.global_position = game_state.checkpoint_position
		player.reset_physics_interpolation()
		return
	_sync_control()
	_pin_player()
	_refresh_plate()


func _physics_process(delta: float) -> void:
	if director == null:
		return
	_ticks += 1
	_read_inputs()
	director.player_x = player.global_position.x
	director.player_bottom_y = player.global_position.y - player.body_half_height
	director.step(delta)
	_sync_control()
	actor.apply(director)
	_pin_player()
	_refresh_plate()
	_check_next_table()
	if player.global_position.y < kill_y:
		player.kill()


func _process(delta: float) -> void:
	if director == null:
		return
	_update_squirm(delta)
	_update_camera(delta)
	ui.set_subtitle(director.line_text)
	var wiggling: bool = director.state == DirectorScript.State.PICK or director.state == DirectorScript.State.LIFT
	ui.set_wiggle(wiggling, director.wiggle_progress(), director.wiggle_time_progress())
	ui.set_skip_hint(director.state == DirectorScript.State.INTRO)
	if director.state == DirectorScript.State.EATEN:
		var p: float = clampf((director.eaten_t - data.eaten_shake_s * 0.5) / maxf(data.eaten_blackout_s, 0.01), 0.0, 1.0)
		ui.set_blackout(p, data.game_over_text)
	else:
		ui.set_blackout(0.0)


# --- Input ------------------------------------------------------------------------------------

func _read_inputs() -> void:
	match director.state:
		DirectorScript.State.INTRO:
			if _ticks > SKIP_GUARD_TICKS and (Input.is_action_just_pressed("jump") \
					or Input.is_action_just_pressed("ui_accept")):
				director.skip_intro()
		DirectorScript.State.PICK, DirectorScript.State.LIFT:
			if GameplayInputScript.just_pressed(&"move_left"):
				director.wiggle_press(-1)
			if GameplayInputScript.just_pressed(&"move_right"):
				director.wiggle_press(1)


## Damage goes through the 떡's own hurt(), so i-frames and knockback apply.
func _hurt_player(half_hearts: int, source_x: float) -> bool:
	return player.hurt(half_hearts, source_x)


# --- The 떡 and the pick -----------------------------------------------------------------------

func _should_control() -> bool:
	match director.state:
		DirectorScript.State.INTRO, DirectorScript.State.PICK, DirectorScript.State.LIFT, \
		DirectorScript.State.EATEN:
			return true
	return false


func _sync_control() -> void:
	var want: bool = _should_control()
	if want == _was_controlled:
		return
	if want:
		_was_controlled = true
		player.set_controlled(true)
		return
	# Released: he slides off the pick and drops.
	_was_controlled = false
	var from: Vector3 = actor.tip_position
	var release_x: float = clampf(from.x + SLIDE_OFF_X, data.section_min_x + 0.3, data.section_max_x - 0.3)
	if director.state == DirectorScript.State.DEAD:
		release_x = player.global_position.x
	else:
		player.global_position = Vector3(release_x, maxf(from.y, data.counter_top_y + 0.4), 0.0)
		player.reset_physics_interpolation()
	player.set_controlled(false)
	_set_squirm_pose(0.0)


## While speared, he rides the pick tip.
func _pin_player() -> void:
	if not _was_controlled:
		return
	var tip: Vector3 = actor.tip_position
	player.global_position = Vector3(tip.x, tip.y + SPEAR_OFFSET, 0.0)


func _on_restarted() -> void:
	_set_world_open(false)
	actor.reset_visual()
	_squirm = 0.0
	if player.state == DdeokScript.State.DEAD:
		player.respawn()
	_was_controlled = false
	_sync_control()
	actor.apply(director)
	_pin_player()
	player.reset_physics_interpolation()
	ui.set_blackout(0.0)
	if camera != null:
		camera.set("target", null)
		camera.global_position = Vector3(data.cup_x, data.pick_camera_pos.y, data.pick_camera_pos.z)
		camera.basis = Basis.IDENTITY
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func _on_wiggle_pressed(dir: int) -> void:
	_squirm = 1.0
	_squirm_phase = 0.0
	if _facing_pivot != null:
		player.facing = float(dir)


func _update_squirm(delta: float) -> void:
	if _facing_pivot == null:
		return
	if not _was_controlled:
		if not is_zero_approx(_facing_pivot.rotation.z):
			_set_squirm_pose(0.0)
		return
	_squirm = move_toward(_squirm, 0.0, SQUIRM_DECAY * delta)
	_squirm_phase += delta * 48.0
	# He always writhes a little on the pick, and a lot right after a press.
	_set_squirm_pose((0.12 + 0.88 * _squirm) * SQUIRM_ANGLE * sin(_squirm_phase))


func _set_squirm_pose(angle: float) -> void:
	if _facing_pivot != null:
		_facing_pivot.rotation.z = angle


# --- Camera -----------------------------------------------------------------------------------

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var blend: float = 1.0 - exp(-5.0 * delta)
	match director.state:
		DirectorScript.State.INTRO:
			var pose: Dictionary = director.camera_pose()
			camera.set("target", null)
			camera.global_position = pose["pos"]
			camera.look_at(pose["look"], Vector3.UP)
		DirectorScript.State.PICK, DirectorScript.State.EATEN, DirectorScript.State.LIFT:
			camera.set("target", null)
			var focus_x: float = director.lift_x if director.state == DirectorScript.State.LIFT else data.cup_x
			var aim: Vector3 = Vector3(focus_x, data.pick_camera_pos.y, data.pick_camera_pos.z)
			camera.global_position = camera.global_position.lerp(aim, blend)
			camera.basis = camera.basis.slerp(Basis.IDENTITY, blend)
			_shake(delta)
		_:
			camera.set("target", player)
			camera.basis = camera.basis.slerp(Basis.IDENTITY, blend)
			camera.h_offset = 0.0
			camera.v_offset = 0.0


func _shake(_delta: float) -> void:
	var amount: float = 0.0
	if director.state == DirectorScript.State.EATEN and director.eaten_t < data.eaten_shake_s:
		amount = SHAKE_AMOUNT * (1.0 - director.eaten_t / maxf(data.eaten_shake_s, 0.01))
	camera.h_offset = randf_range(-amount, amount)
	camera.v_offset = randf_range(-amount, amount)


# --- World: walls, the stuck pick, the next table ---------------------------------------------------

func _on_exit_opened() -> void:
	actor.hide_for_exit()
	# Do not let the pick appear inside him.
	if absf(player.global_position.x - data.final_x) < 1.0 and player.global_position.y < data.pick_top_y:
		player.global_position.x = data.final_x - 1.0
		player.velocity.x = 0.0
		player.reset_physics_interpolation()
	_set_world_open(true)


func _on_completed() -> void:
	ui.set_dev_note(true)


## true: the walls are down and the stuck pick stands in the counter. false: the opposite.
func _set_world_open(open: bool) -> void:
	if walls != null:
		for wall: Node in walls.get_children():
			for child: Node in wall.get_children():
				var shape: CollisionShape3D = child as CollisionShape3D
				if shape != null:
					shape.set_deferred("disabled", open)
	if stuck_pick != null:
		stuck_pick.visible = open
		for child: Node in stuck_pick.get_children():
			var shape: CollisionShape3D = child as CollisionShape3D
			if shape != null:
				shape.set_deferred("disabled", not open)
	if not open and ui != null:
		ui.set_dev_note(false)


## Test hook: only the walls down, no pick (to prove the gap is too wide without it).
func debug_drop_walls_only() -> void:
	if walls != null:
		for wall: Node in walls.get_children():
			for child: Node in wall.get_children():
				var shape: CollisionShape3D = child as CollisionShape3D
				if shape != null:
					shape.disabled = true


func _refresh_plate() -> void:
	if plate == null or director == null:
		return
	var index: int = 0
	for child: Node in plate.get_children():
		var item: Node3D = child as Node3D
		if item != null and item.name.begins_with("Mandu"):
			item.visible = index < director.plate_mandu
			index += 1


func _check_next_table() -> void:
	if director.state != DirectorScript.State.EXIT_OPEN or not player.grounded:
		return
	var x: float = player.global_position.x
	var feet: float = player.global_position.y - player.body_half_height
	if x >= data.next_table_min_x and x <= data.next_table_max_x \
			and absf(feet - data.next_table_top_y) < 0.2:
		director.reach_next_table()


# --- Debug ------------------------------------------------------------------------------------

## Debug key 8: finish the prologue instantly (land on the next table).
func debug_finish() -> void:
	if director == null or director.state == DirectorScript.State.COMPLETE:
		return
	director.debug_finish()
	_sync_control()
	_set_world_open(true)
	actor.hide_for_exit()
	player.set_controlled(false)
	_was_controlled = false
	_set_squirm_pose(0.0)
	player.global_position = data.next_table_spawn
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


## Lines for the debug HUD (see maps/test/debug_hud.gd).
func debug_lines() -> Array[String]:
	return director.debug_lines() if director != null else ([] as Array[String])
