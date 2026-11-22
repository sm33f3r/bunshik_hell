extends Node3D
## Map 1 (lunch 분식집), gray box, at real scale. The prologue lives here: the opening cutscene, the
## pick and the wiggle, the 30 stabs at the window counter, and the exit to the next table. All the
## rules are in PrologueDirector; this node moves things and draws them. The set (counter, props, her
## forearm, the next table) is built by PrologueSet from the real-size table. After the exit the map
## goes on from data: MapFlow builds the optional tutorial and the start of the dining room from
## data/maps/ep01/map01_layout.tres and runs them.

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const ActorScript := preload("res://prologue/prologue_actor.gd")
const UiScript := preload("res://prologue/prologue_ui.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const ManduRespawnScript := preload("res://prologue/mandu_respawn.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")
const MANDU_SCENE: PackedScene = preload("res://enemies/mandu.tscn")

## Physics ticks at the start during which the skip button is ignored.
const SKIP_GUARD_TICKS: int = 8
const SQUIRM_ANGLE: float = 0.5
const SQUIRM_DECAY: float = 3.5
const SHAKE_AMOUNT: float = 0.35

@export var player: DdeokScript
@export var camera: Camera3D
## The real-size set, built from data when the map starts.
@export var set_node: PrologueSetScript
@export var data: PrologueDataScript

var director: DirectorScript
var actor: ActorScript
var ui: UiScript
var game_state: GameStateScript
## Everything after the prologue (see MapFlow).
var flow: MapFlowScript

var _ticks: int = 0
var _squirm: float = 0.0
var _squirm_phase: float = 0.0
var _facing_pivot: Node3D
var _was_controlled: bool = false
var _mandu: Array[EnemyBaseScript] = []
var _mandu_respawn: ManduRespawnScript


func _ready() -> void:
	add_to_group("prologue_map")
	game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state == null or player == null:
		return
	if data == null:
		data = load(DirectorScript.DATA_PATH) as PrologueDataScript
	_facing_pivot = player.get_node_or_null("FacingPivot") as Node3D
	if set_node != null:
		set_node.build(data)
	player.global_position = data.start_spawn
	player.reset_physics_interpolation()
	if camera != null:
		camera.near = data.camera_near
		camera.far = data.camera_far
		camera.set("offset", data.stab_camera_offset)

	_mandu_respawn = ManduRespawnScript.new(data.mandu_respawn_count, data.mandu_respawn_delay_s)
	director = DirectorScript.new(data, game_state)
	director.apply_damage = Callable(self, "_hurt_player")
	director.restarted.connect(_on_restarted)
	director.exit_opened.connect(_on_exit_opened)
	director.completed.connect(_on_completed)
	director.wiggle_pressed.connect(_on_wiggle_pressed)
	player.respawned.connect(director.on_player_respawned)
	var pause_menu: Node = get_node_or_null("PauseMenu")
	if pause_menu != null and pause_menu.has_signal("restart_requested"):
		pause_menu.connect("restart_requested", _on_restart_requested)

	actor = ActorScript.new()
	actor.name = "PrologueActor"
	add_child(actor)
	actor.build(data)
	actor.body_half_height = player.body_half_height
	ui = UiScript.new()
	ui.name = "PrologueUi"
	add_child(ui)

	flow = MapFlowScript.new()
	flow.name = "MapFlow"
	add_child(flow)
	flow.setup(player, camera, game_state, data)
	player.respawned.connect(flow.on_player_respawned)

	_set_world_open(false)
	director.begin()
	if director.state == DirectorScript.State.COMPLETE:
		# Loaded after the prologue was done: no stabbing, the way on is open.
		_set_world_open(true)
		flow.resume()
		player.global_position = game_state.checkpoint_position
		player.reset_physics_interpolation()
		return
	if _mandu.is_empty():
		_respawn_mandu() # in the cutscene they are already on her plate
	_sync_control()
	_pin_player()


func _physics_process(delta: float) -> void:
	if director == null:
		return
	_ticks += 1
	_read_inputs()
	director.player_x = player.global_position.x
	director.player_bottom_y = player.global_position.y - player.body_half_height
	director.mandu_xs = _live_mandu_xs()
	_restock_plate(delta)
	director.step(delta)
	_sync_control()
	actor.apply(director)
	_pin_player()
	_stab_hits_mandu()
	_check_next_table()
	_catch_fall()


func _process(delta: float) -> void:
	if director == null:
		return
	_update_squirm(delta)
	_update_camera(delta)
	ui.set_subtitle(director.line_text)
	var wiggling: bool = director.state == DirectorScript.State.PICK or director.state == DirectorScript.State.LIFT
	ui.set_wiggle(wiggling, director.wiggle_progress(), director.wiggle_time_progress())
	if director.state == DirectorScript.State.EATEN:
		var p: float = clampf((director.eaten_t - data.eaten_shake_s * 0.5) / maxf(data.eaten_blackout_s, 0.01), 0.0, 1.0)
		ui.set_blackout(p, data.game_over_text)
	else:
		ui.set_blackout(0.0)


# --- Input ------------------------------------------------------------------------------------

func _read_inputs() -> void:
	match director.state:
		DirectorScript.State.INTRO:
			if _ticks > SKIP_GUARD_TICKS and (GameplayInputScript.just_pressed(&"jump") \
					or GameplayInputScript.just_pressed(&"ui_accept")):
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
	var release_x: float = clampf(from.x + data.slide_off_m, data.section_min_x + 0.3, data.section_max_x - 0.3)
	if director.state == DirectorScript.State.DEAD:
		release_x = player.global_position.x
	else:
		player.global_position = Vector3(release_x, maxf(from.y, data.counter_top_y + 0.4), 0.0)
		player.reset_physics_interpolation()
	player.set_controlled(false)
	_set_squirm_pose(0.0)


## While speared, he rides the pick tip: the tip stays INSIDE his body, never out of its far side.
func _pin_player() -> void:
	if not _was_controlled:
		return
	var tip: Vector3 = actor.tip_position
	player.global_position = Vector3(tip.x, tip.y + actor.spear_centre_above_tip(), 0.0)


func _on_restarted() -> void:
	_set_world_open(false)
	actor.reset_visual()
	_squirm = 0.0
	_respawn_mandu()
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
		camera.global_position = data.pick_camera_pos
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
			var focus_x: float = data.cup_x
			if director.state == DirectorScript.State.LIFT:
				focus_x = director.lift_x
			elif director.state == DirectorScript.State.EATEN:
				focus_x = director.eaten_x
			var pick_cam: Vector3 = data.pick_camera_pos
			var aim: Vector3 = Vector3(focus_x, pick_cam.y, pick_cam.z)
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


# --- World: the forearm, the next table, falling ----------------------------------------------------

func _on_exit_opened() -> void:
	_set_world_open(true)


## The prologue is over: the map goes on from data (the tutorial prompt, then the tutorial).
func _on_completed() -> void:
	flow.on_prologue_complete()


## true: she has yanked her forearm away and the way on is open. false: it lies across the counter.
func _set_world_open(open: bool) -> void:
	if set_node != null:
		set_node.set_exit_open(open)
	if not open and ui != null:
		ui.set_dev_note(false)


func _check_next_table() -> void:
	if director.state != DirectorScript.State.EXIT_OPEN or not player.grounded:
		return
	var x: float = player.global_position.x
	var feet: float = player.global_position.y - player.body_half_height
	if x >= data.next_table_min_x and x <= data.next_table_max_x \
			and absf(feet - data.next_table_top_y) < 0.2:
		director.reach_next_table()


## The floor is a long way below the counter: a fall is not death, he is put back (no damage).
## After the prologue that is the last checkpoint, and the section starts over.
func _catch_fall() -> void:
	var limit: float = data.fall_catch_y
	if director.state == DirectorScript.State.COMPLETE and flow != null:
		limit = flow.fall_y
	if player.controlled or player.global_position.y >= limit:
		return
	if director.state == DirectorScript.State.COMPLETE:
		player.global_position = game_state.checkpoint_position
		flow.on_fell()
	else:
		player.global_position = Vector3(data.fall_return_x, data.counter_top_y + 0.6, 0.0)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


# --- Pause menu "Restart" ---------------------------------------------------------------------------

## From the last checkpoint: in the prologue that is the 맛있겠다 moment; after it, the next table.
func _on_restart_requested() -> void:
	if director == null:
		return
	if director.state == DirectorScript.State.COMPLETE:
		game_state.respawn()
		player.respawn()
		return
	director.restart()


# --- Live 만두 ---------------------------------------------------------------------------------------

## Her plate starts with live 만두 again (on every restart).
func _respawn_mandu() -> void:
	for mandu: EnemyBaseScript in _mandu:
		if is_instance_valid(mandu):
			mandu.queue_free()
	_mandu.clear()
	if _mandu_respawn != null:
		_mandu_respawn.reset()
	_spawn_mandu(data.plate_mandu_count)


## The last live 만두 died (the 떡 stomped it, or she ate it): new ones appear after the delay.
func _restock_plate(delta: float) -> void:
	var active: bool = director.state in [DirectorScript.State.PRE_STAB, DirectorScript.State.STAB,
			DirectorScript.State.LIFT]
	var n: int = _mandu_respawn.update(director.mandu_xs.size(), delta, active)
	if n > 0:
		_spawn_mandu(n)


func _spawn_mandu(how_many: int) -> void:
	if set_node == null or how_many <= 0:
		return
	var width: float = data.dims().mandu_width_cm * data.m_per_cm()
	var points: Array[Vector3] = set_node.plate_spawn_points(how_many)
	var kept: Array[EnemyBaseScript] = []
	for old: EnemyBaseScript in _mandu:
		if is_instance_valid(old):
			kept.append(old)
	_mandu = kept
	var start_index: int = _mandu.size()
	for i: int in points.size():
		var node: EnemyBaseScript = MANDU_SCENE.instantiate() as EnemyBaseScript
		node.set("width_m", width)
		node.set("height_fraction", data.dims().mandu_height_fraction)
		node.name = "Mandu%d" % (start_index + i + 1)
		add_child(node)
		node.global_position = points[i]
		node.set("start_dir", -1.0 if i % 2 == 1 else 1.0)
		_mandu.append(node)


func live_mandu() -> Array[EnemyBaseScript]:
	var out: Array[EnemyBaseScript] = []
	for mandu: EnemyBaseScript in _mandu:
		if is_instance_valid(mandu) and mandu.alive:
			out.append(mandu)
	return out


func _live_mandu_xs() -> Array[float]:
	var xs: Array[float] = []
	for mandu: EnemyBaseScript in live_mandu():
		xs.append(mandu.global_position.x)
	return xs


## The pick spears any 만두 that is in its column once it lands (and while it drags).
func _stab_hits_mandu() -> void:
	var s: DirectorScript.Stab = director.stab
	if s == null:
		return
	if not (s.hazard or s.kind == DirectorScript.KIND_MANDU or s.kind == DirectorScript.KIND_FINAL):
		return
	if s.phase != DirectorScript.Phase.HOLD and s.phase != DirectorScript.Phase.DRAG:
		return
	for mandu: EnemyBaseScript in live_mandu():
		if absf(mandu.global_position.x - s.tip_x) < s.half_width + data.mandu_half_width_m:
			mandu.receive_attack(ReactionTableScript.ATTACK_HEAVY_OBJECT, 1.0, {"by_ddeok": false})


# --- Debug ------------------------------------------------------------------------------------

## Debug key 8: finish the prologue instantly (land on the next table).
func debug_finish() -> void:
	if director == null or director.state == DirectorScript.State.COMPLETE:
		return
	director.debug_finish()
	_sync_control()
	_set_world_open(true)
	player.set_controlled(false)
	_was_controlled = false
	_set_squirm_pose(0.0)
	player.global_position = data.next_table_spawn
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()


## Lines for the debug HUD (see maps/test/debug_hud.gd).
func debug_lines() -> Array[String]:
	return director.debug_lines() if director != null else ([] as Array[String])
