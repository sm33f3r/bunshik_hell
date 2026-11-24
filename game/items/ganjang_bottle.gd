extends "res://enemies/enemy_base.gd"
## 간장 bottle (Task 3c-i-a). Standing, it is a solid, harmless prop he can stand on. A ROLL into it knocks
## it over (reaction table: roll -> knock_over, the same path as the 단무지), and it stays down for the
## rest of that life. Lying on its side, each SLAM or STOMP on it squirts once (table: slam / stomp ->
## squirt): a gray-box 간장 blast from the nozzle and +sodium_per_squirt 나트륨 straight into GameState.
## After squirts_max squirts it is empty: a hit then only makes a small puff.
## Nothing here is saved: when the life starts over the section is built again and the bottle stands
## upright with all its squirts (MapFlow.reset_sections). Which spot it stands on is the layout's
## "spawn choice" (SpawnChoice). Numbers: BottleDef (data/props/ganjang_bottle.tres), the table rows
## "bottle_upright" and "bottle_fallen" (data/reaction_table.tres).

const BottleDefScript := preload("res://items/bottle_def.gd")
const WorldScaleScript := preload("res://systems/world_scale.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")

## It lay down (a roll).
signal knocked_over
## One squirt happened; `left` squirts remain.
signal squirted(left: int)
## A hit landed on the empty bottle.
signal empty_hit

## Game metres per real centimetre; -1 = read the world scale data.
@export var m_per_cm: float = -1.0
## Which way a lying bottle's nozzle points (+1 right, -1 left): the way the roll went.
var fall_dir: float = 1.0

## Lying on its side (stays so until the life starts over).
var fallen: bool = false
## Not the 단무지's "flat" (a platform that may be spent): always false, so the map flow's out-of-reach check,
## which asks every spawned thing for it, finds a bottle that is only ever out of reach by falling off its platform.
var flat: bool = false
var squirts_left: int = 0
## Counters for the picture and for tests.
var squirts_done: int = 0
var empty_hits: int = 0
var sodium_given: int = 0

var _height_m: float = 0.0
var _width_m: float = 0.0
var _shape_node: CollisionShape3D
var _pose: Node3D
var _liquid: MeshInstance3D


func bottle_def() -> BottleDefScript:
	return def as BottleDefScript


func setup() -> void:
	super()
	_size_from_def()
	fallen = false
	squirts_left = bottle_def().squirts_max if bottle_def() != null else 0
	squirts_done = 0
	empty_hits = 0
	sodium_given = 0
	_apply_pose()


func _on_ready() -> void:
	# Both layers: a solid thing in the world (he stands on it, walks into it) that is also something
	# his roll, stomp and slam can hit.
	collision_layer = Layers.ENEMY | Layers.WORLD
	_apply_pose()


func _on_reset() -> void:
	collision_layer = Layers.ENEMY | Layers.WORLD
	_apply_pose()


## Never hurts him; never dies.
func is_harmless() -> bool:
	return true


func debug_defeat() -> void:
	pass # it is a prop: "defeat all enemies" leaves it alone


func material_key() -> String:
	var d: BottleDefScript = bottle_def()
	if d == null:
		return ""
	return d.fallen_material if fallen else d.upright_material


## Half the width of whatever shape it has now (what a mover keeps clear of).
func half_width() -> float:
	return (_height_m if fallen else _width_m) * 0.5


func _size_from_def() -> void:
	var d: BottleDefScript = bottle_def()
	if d == null:
		return
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	_height_m = d.height_cm * scale_m
	_width_m = d.width_cm * scale_m


func _world_m_per_cm() -> float:
	var world: Resource = WorldScaleScript.load_default()
	return (world as WorldScaleScript).game_m_per_real_cm() if world != null else 0.1745


# --- Knocked over -----------------------------------------------------------------------------------

## A roll lays it down, nozzle first toward the way it was hit. It does not die.
func _handle_knock_over(hit_dir: float) -> bool:
	if fallen:
		return true
	fallen = true
	fall_dir = signf(hit_dir) if hit_dir != 0.0 else fall_dir
	_apply_pose()
	knocked_over.emit()
	return true


# --- Squirting --------------------------------------------------------------------------------------

func _handle_squirt(_hit_dir: float) -> void:
	var d: BottleDefScript = bottle_def()
	if not fallen or d == null:
		return # standing: nothing special (the table reads the standing row, so this is a guard only)
	if squirts_left <= 0:
		empty_hits += 1
		_play_empty_puff()
		empty_hit.emit()
		return
	squirts_left -= 1
	squirts_done += 1
	sodium_given += d.sodium_per_squirt
	if game_state != null:
		game_state.add_sodium(d.sodium_per_squirt)
	_update_liquid()
	_play_blast()
	squirted.emit(squirts_left)


## Where the nozzle is (in the bottle's own space) once it lies down.
func nozzle_local() -> Vector3:
	return Vector3(fall_dir * (_height_m * 0.5 + 0.02), _width_m * 0.5, 0.0)


func _play_blast() -> void:
	if not is_inside_tree():
		return
	var d: BottleDefScript = bottle_def()
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	var length: float = d.blast_length_cm * scale_m
	var thick: float = d.blast_thickness_cm * scale_m
	var blast: MeshInstance3D = PrologueSetScript.add_mesh(self, "Blast", PrologueSetScript.box_mesh(Vector3(length, thick, thick)),
		d.blast_color, nozzle_local() + Vector3(fall_dir * length * 0.5, 0.0, 0.0))
	blast.add_to_group("ganjang_blasts")
	blast.add_to_group("section_decor")
	var mat: StandardMaterial3D = blast.material_override as StandardMaterial3D
	if mat != null:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast.scale = Vector3(0.1, 1.0, 1.0)
	blast.position = nozzle_local() + Vector3(fall_dir * length * 0.05, 0.0, 0.0)
	var tween: Tween = blast.create_tween()
	tween.set_parallel(true)
	tween.tween_property(blast, "scale:x", 1.0, d.blast_time_s * 0.3)
	tween.tween_property(blast, "position:x", nozzle_local().x + fall_dir * length * 0.5, d.blast_time_s * 0.3)
	if mat != null:
		tween.tween_property(mat, "albedo_color:a", 0.0, d.blast_time_s).set_delay(d.blast_time_s * 0.3)
	tween.chain().tween_callback(blast.queue_free)


func _play_empty_puff() -> void:
	_play_slurp() # the usual flash of a hit that does nothing
	if not is_inside_tree():
		return
	var d: BottleDefScript = bottle_def()
	var scale_m: float = m_per_cm if m_per_cm > 0.0 else _world_m_per_cm()
	var size: float = d.blast_thickness_cm * scale_m * 1.4
	var puff: MeshInstance3D = PrologueSetScript.add_mesh(self, "EmptyPuff", PrologueSetScript.box_mesh(Vector3(size, size, size)),
		d.empty_puff_color, nozzle_local() + Vector3(fall_dir * size, 0.0, 0.0))
	puff.add_to_group("ganjang_puffs")
	puff.add_to_group("section_decor")
	var mat: StandardMaterial3D = puff.material_override as StandardMaterial3D
	if mat != null:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween: Tween = puff.create_tween()
	tween.set_parallel(true)
	tween.tween_property(puff, "scale", Vector3(1.8, 1.8, 1.8), d.empty_puff_time_s)
	tween.tween_property(puff, "position:y", puff.position.y + size, d.empty_puff_time_s)
	if mat != null:
		tween.tween_property(mat, "albedo_color:a", 0.0, d.empty_puff_time_s)
	tween.chain().tween_callback(puff.queue_free)


# --- The shape and the gray-box picture -------------------------------------------------------------

## Standing: a square-footed box. Lying: a box on its side, as long as the bottle is tall, nozzle toward
## fall_dir. The solid shape and the shape the attacks see are the same body.
func _apply_pose() -> void:
	if _height_m <= 0.0:
		return
	_shape_node = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _shape_node != null:
		var box: BoxShape3D = BoxShape3D.new()
		if fallen:
			box.size = Vector3(_height_m, _width_m, _width_m)
			_shape_node.position = Vector3(0.0, _width_m * 0.5, 0.0)
		else:
			box.size = Vector3(_width_m, _height_m, _width_m)
			_shape_node.position = Vector3(0.0, _height_m * 0.5, 0.0)
		_shape_node.shape = box
	body_height = _width_m if fallen else _height_m
	_build_picture()
	if _pose != null:
		if fallen:
			_pose.rotation = Vector3(0.0, 0.0, -fall_dir * PI * 0.5)
			_pose.position = Vector3(-fall_dir * _height_m * 0.5, _width_m * 0.5, 0.0)
		else:
			_pose.rotation = Vector3.ZERO
			_pose.position = Vector3.ZERO
	_update_liquid()


## The bottle is drawn once, standing, under "Visual/Pose"; lying is the same picture turned on its side.
func _build_picture() -> void:
	if _pose != null and is_instance_valid(_pose):
		return
	_visual = get_node_or_null("Visual") as Node3D
	var d: BottleDefScript = bottle_def()
	if _visual == null or d == null:
		return
	_pose = Node3D.new()
	_pose.name = "Pose"
	_visual.add_child(_pose)
	var neck_w: float = _width_m * 0.4
	var neck_h: float = _height_m * 0.2
	var body_h: float = _height_m - neck_h
	PrologueSetScript.add_mesh(_pose, "Body", PrologueSetScript.box_mesh(Vector3(_width_m, body_h, _width_m)),
		d.body_color, Vector3(0.0, body_h * 0.5, 0.0))
	_liquid = PrologueSetScript.add_mesh(_pose, "Liquid", PrologueSetScript.box_mesh(Vector3(_width_m * 0.8, body_h * 0.9, _width_m * 1.02)),
		d.liquid_color, Vector3(0.0, body_h * 0.5, 0.0))
	PrologueSetScript.add_mesh(_pose, "Neck", PrologueSetScript.box_mesh(Vector3(neck_w, neck_h, neck_w)),
		d.body_color, Vector3(0.0, body_h + neck_h * 0.5, 0.0))
	PrologueSetScript.add_mesh(_pose, "Cap", PrologueSetScript.box_mesh(Vector3(neck_w * 1.2, neck_h * 0.4, neck_w * 1.2)),
		d.cap_color, Vector3(0.0, _height_m - neck_h * 0.2, 0.0))
	_make_overlay()


## The liquid level shows how many squirts are left.
func _update_liquid() -> void:
	var d: BottleDefScript = bottle_def()
	if _liquid == null or d == null:
		return
	var fraction: float = float(squirts_left) / float(maxi(d.squirts_max, 1))
	var body_h: float = _height_m * 0.8
	_liquid.scale = Vector3(1.0, maxf(fraction, 0.001), 1.0)
	_liquid.position = Vector3(0.0, body_h * 0.05 + body_h * 0.45 * fraction, 0.0)
	_liquid.visible = squirts_left > 0
