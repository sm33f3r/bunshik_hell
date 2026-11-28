extends Node3D
## 찜기 (steamer). Press look_up (W) while standing in its zone: ONE full heal and ONE auto-save,
## once. It becomes the respawn point, its steam stops and it looks used. After that it does nothing
## (no heal, no save, no prompt). The kind is data (JjigiDef); the unique id and the place come from
## the map layout (JjigiPlacement). The test room's 찜기 use def.debug_unlimited: usable again and again.
##
## It saves through SaveSystem (the autoload, or `save_system` when a test injects one).

const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const JjigiDefScript := preload("res://items/jjigi_def.gd")
const Layers := preload("res://systems/layers.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

## Unique and stable: the save remembers "used" by this id.
@export var steamer_id: String = ""
@export var def: JjigiDefScript
## Where the 떡 appears on respawn, relative to this node.
@export var spawn_offset: Vector3 = Vector3(1.6, 0.5, 0.0)

var game_state: GameStateScript
var save_system: SaveSystemScript

var _zone: Area3D
var _base: StaticBody3D
var _box_material: StandardMaterial3D
var _top_material: StandardMaterial3D
var _puff: MeshInstance3D
var _puff_material: StandardMaterial3D
var _prompt: Label3D
var _steam: CPUParticles3D
var _tween: Tween


func _ready() -> void:
	# Not while the game is paused: W is also "up" in the menus. (The map builds it under MapFlow,
	# which always runs.)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("jjigi")
	if def == null:
		def = JjigiDefScript.new()
	_zone = get_node_or_null("UseZone") as Area3D
	if _zone != null:
		_zone.collision_layer = 0
		_zone.collision_mask = Layers.PLAYER
	_prompt = get_node_or_null("Prompt") as Label3D
	if _prompt != null:
		_prompt.text = def.prompt_text
	_base = get_node_or_null("Base") as StaticBody3D
	if _base != null and not def.solid:
		_base.collision_layer = 0
	_puff = get_node_or_null("Puff") as MeshInstance3D
	if _puff != null and _puff.material_override is StandardMaterial3D:
		_puff_material = (_puff.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		_puff.material_override = _puff_material
		_puff.visible = false
	var box: MeshInstance3D = get_node_or_null("Base/Box") as MeshInstance3D
	if box != null and box.material_override is StandardMaterial3D:
		_box_material = (box.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		box.material_override = _box_material
	var top: MeshInstance3D = get_node_or_null("SteamTop") as MeshInstance3D
	if top != null and top.material_override is StandardMaterial3D:
		_top_material = (top.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		top.material_override = _top_material
	_build_steam()
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state != null:
		game_state.checkpoint_changed.connect(_on_state_changed)
		game_state.jjigi_used.connect(_on_state_changed)
	_refresh_look()


func _physics_process(_delta: float) -> void:
	if _zone == null or game_state == null:
		return
	var near: bool = false
	for body: Node3D in _zone.get_overlapping_bodies():
		if body.is_in_group("player"):
			near = true
			break
	if _prompt != null:
		_prompt.visible = near and not is_spent()
	if near and GameplayInputScript.just_pressed(&"look_up"):
		activate(game_state)


func spawn_point() -> Vector3:
	return (global_position if is_inside_tree() else position) + spawn_offset


func _def() -> JjigiDefScript:
	if def == null:
		def = JjigiDefScript.new()
	return def


## True once it has given its heal and save and will not give them again (never for a debug_unlimited one).
func is_spent() -> bool:
	return game_state != null and game_state.is_jjigi_used(steamer_id) and not _def().provides(true)


## True while the steam is rising.
func steam_on() -> bool:
	return _steam != null and _steam.emitting


## Full heal + auto-save + respawn point, the first time only. False (nothing happened) if refused:
## the 떡 is dead, or it was used already.
func activate(state: GameStateScript) -> bool:
	if state == null or state.is_dead():
		return false
	var again: bool = _def().provides(true) # what a second use would be allowed to do
	if state.is_jjigi_used(steamer_id) and not again:
		return false
	if not state.use_jjigi(steamer_id, spawn_point(), again):
		return false
	if _def().saves:
		_save(state)
	_play_feedback()
	_refresh_look()
	return true


func _save(state: GameStateScript) -> void:
	var system: SaveSystemScript = save_system
	if system == null and is_inside_tree():
		system = get_node_or_null("/root/SaveSystem") as SaveSystemScript
	if system == null:
		return
	if not system.save_game(state):
		push_warning("찜기 %s: the save failed (%s)" % [steamer_id, system.last_error])


func _on_state_changed(_id: String) -> void:
	_refresh_look()


# --- Look ---------------------------------------------------------------------------------------------

func _build_steam() -> void:
	_steam = CPUParticles3D.new()
	_steam.name = "Steam"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = _def().steam_puff_size_m * 0.5
	sphere.height = _def().steam_puff_size_m
	sphere.radial_segments = 8
	sphere.rings = 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = _def().steam_color
	sphere.material = material
	_steam.mesh = sphere
	_steam.amount = maxi(_def().steam_amount, 1)
	_steam.lifetime = maxf(_def().steam_lifetime_s, 0.1)
	_steam.direction = Vector3.UP
	_steam.spread = 12.0
	_steam.gravity = Vector3.ZERO
	_steam.initial_velocity_min = _def().steam_rise_mps * 0.7
	_steam.initial_velocity_max = _def().steam_rise_mps
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_steam.emission_box_extents = Vector3(0.35, 0.02, 0.25)
	_steam.position = Vector3(0.0, 0.98, 0.0)
	_steam.emitting = true
	add_child(_steam)


## Unused: steam, a lit lid and the prompt. Used: no steam, a dull lid and a dark body.
func _refresh_look() -> void:
	var spent: bool = is_spent()
	if _steam != null:
		_steam.emitting = not spent
		_steam.visible = not spent
	if _prompt != null and spent:
		_prompt.visible = false
	var d: JjigiDefScript = _def()
	if _box_material != null:
		_box_material.albedo_color = d.used_body_color if spent else d.body_color
	if _top_material != null:
		var lid: Color = d.used_lid_color if spent else d.lid_color
		_top_material.albedo_color = lid
		_top_material.emission = lid
		_top_material.emission_enabled = true
		var is_point: bool = game_state != null and game_state.checkpoint_id == steamer_id
		_top_material.emission_energy_multiplier = d.used_glow if spent else (d.active_glow if is_point else d.idle_glow)


func _play_feedback() -> void:
	if not is_inside_tree() or _puff == null or _puff_material == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_puff.visible = true
	_puff.scale = Vector3.ONE * 0.3
	_puff_material.albedo_color.a = 0.8
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_puff, "scale", Vector3.ONE * 1.8, _def().feedback_time)
	_tween.tween_property(_puff_material, "albedo_color:a", 0.0, _def().feedback_time)
	_tween.chain().tween_callback(func() -> void: _puff.visible = false)
