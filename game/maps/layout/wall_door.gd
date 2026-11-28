extends Node3D
## A built wall door (DoorPlacement): the gray-box door on the back wall, the zone mark on the floor in
## front of it, and its behaviour. Standing in the zone highlights it and shows the look_up glyph (as the
## 찜기 and the usable objects do). look_up (W) there asks to go through (`enter_requested`, MapFlow does
## the fade); while locked it shakes and shows a padlock instead. Nothing here has a collider.
## Origin: the floor under the middle of the door, on the plane he walks in (z = 0).

signal enter_requested(door_id: String)
signal locked_tried(door_id: String)

const DoorPlacementScript := preload("res://maps/layout/door_placement.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")
const ActionGlyphsScript := preload("res://systems/action_glyphs.gd")

enum Highlight { NONE, BRIGHT, DIM }

const ACTION: StringName = &"look_up"
## His feet may be this far from the floor and still count as standing in the zone.
const FEET_TOLERANCE_M: float = 0.4
## The "locked" feedback: how long the door shakes, how far, and how long the padlock stays.
const SHAKE_S: float = 0.4
const SHAKE_M: float = 0.09
const LOCK_SHOW_S: float = 1.2
const MAT_COLOR: Color = Color(0.46, 0.37, 0.22)

var def: DoorPlacementScript
var game_state: GameStateScript
## The player; found in the group "player" when not set.
var player: Node3D
var using_pad: bool = false
var near: bool = false
var highlight: Highlight = Highlight.NONE
## Times he tried it while it was locked.
var locked_tries: int = 0

var _body: Node3D
var _prompt: Label3D
var _lock: Node3D
var _lit: Array[StandardMaterial3D] = []
var _shake_left: float = 0.0
var _lock_left: float = 0.0


## `wall_front_z`: the z of the back wall's front face. The frame stands `proud_m` in front of it.
func build(p_def: DoorPlacementScript, m_per_cm: float, wall_front_z: float, proud_m: float, lane_depth_m: float) -> void:
	def = p_def
	# Not while the game is paused: W is also "up" in the menus.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var width: float = def.width_cm * m_per_cm
	var height: float = def.height_cm * m_per_cm
	var post: float = def.post_cm * m_per_cm
	var lintel: float = def.lintel_cm * m_per_cm
	var threshold: float = def.threshold_cm * m_per_cm
	var recess: float = def.recess_cm * m_per_cm
	var opening: float = width - post * 2.0
	var front: float = wall_front_z + proud_m
	var back: float = wall_front_z - 0.3
	var frame_depth: float = front - back
	var frame_z: float = (front + back) * 0.5
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	# The dark room behind the opening.
	var inner_z: float = wall_front_z - recess * 0.5
	_box(_body, "Interior", Vector3(opening + 0.3, height, 0.1), def.interior_color, Vector3(0.0, height * 0.5, wall_front_z - recess))
	for side: int in [-1, 1]:
		_box(_body, "RevealLeft" if side < 0 else "RevealRight", Vector3(0.1, height, recess), def.interior_color.lightened(0.07),
			Vector3(float(side) * (opening * 0.5 + 0.1), height * 0.5, inner_z))
	_box(_body, "RevealTop", Vector3(opening + 0.3, 0.1, recess), def.interior_color, Vector3(0.0, height - lintel * 0.5, inner_z))
	_box(_body, "InteriorFloor", Vector3(opening + 0.3, 0.1, recess), def.interior_color.lightened(0.14), Vector3(0.0, -0.05, inner_z))

	# The curtain: flat rubber strips from the lintel, in the wall's plane.
	var slot: float = opening / float(maxi(def.strips, 1))
	var bottom: float = def.strip_bottom_cm * m_per_cm
	for i: int in maxi(def.strips, 1):
		var end: float = bottom + (def.strip_ragged_cm * m_per_cm if i % 2 == 1 else 0.0)
		var length: float = maxf(height - lintel - end, 0.1)
		var strip: MeshInstance3D = _box(_body, "Strip%d" % i, Vector3(slot * def.strip_fill, length, 0.04), def.strip_color,
			Vector3(-opening * 0.5 + slot * (float(i) + 0.5), end + length * 0.5, wall_front_z - (0.12 if i % 2 == 0 else 0.18)))
		(strip.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# The frame: two posts, the lintel and the threshold.
	var posts_h: float = height - lintel
	for side: int in [-1, 1]:
		_lit_box("PostLeft" if side < 0 else "PostRight", Vector3(post, posts_h, frame_depth), def.color,
			Vector3(float(side) * (width - post) * 0.5, posts_h * 0.5, frame_z))
	_lit_box("Lintel", Vector3(width, lintel, frame_depth + 0.06), def.color.darkened(0.12), Vector3(0.0, height - lintel * 0.5, frame_z + 0.03))
	_box(_body, "Threshold", Vector3(width, threshold, frame_depth + 0.14), def.color.lightened(0.22),
		Vector3(0.0, threshold * 0.5, frame_z + 0.07))

	# The zone on the floor: a mat as wide as the zone.
	var mat: MeshInstance3D = _box(self, "ZoneMat", Vector3(def.zone_width_m, 0.02, lane_depth_m * 0.5), MAT_COLOR, Vector3(0.0, 0.012, 0.0))
	_lit.append(mat.material_override as StandardMaterial3D)

	_prompt = Label3D.new()
	_prompt.name = "Prompt"
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.font_size = 96
	_prompt.pixel_size = 0.006
	_prompt.outline_size = 12
	_prompt.position = Vector3(0.0, 1.9, 0.0)
	_prompt.visible = false
	add_child(_prompt)
	_build_lock()
	_refresh_prompt()


func door_id() -> String:
	return def.id if def != null else ""


## True while its flag is not set.
func is_locked() -> bool:
	if def == null or def.locked_until_flag == "":
		return false
	if game_state != null:
		return not game_state.has_flag(def.locked_until_flag)
	return not bool(GameStateScript.FLAG_DEFAULTS.get(def.locked_until_flag, false))


## Is this x / feet height inside the zone in front of the door?
func zone_contains(x: float, feet_y: float) -> bool:
	var at: Vector3 = global_position if is_inside_tree() else position
	return def != null and absf(x - at.x) <= def.zone_width_m * 0.5 and absf(feet_y - at.y) <= FEET_TOLERANCE_M


func prompt_visible() -> bool:
	return _prompt != null and _prompt.visible


func prompt_text() -> String:
	return _prompt.text if _prompt != null else ""


func lock_visible() -> bool:
	return _lock != null and _lock.visible


func shaking() -> bool:
	return _shake_left > 0.0


## What look_up in the zone does: ask to go through, or, locked, the feedback. True if it asked.
func try_enter() -> bool:
	if is_locked():
		locked_tries += 1
		_shake_left = SHAKE_S
		_lock_left = LOCK_SHOW_S
		_lock.visible = true
		locked_tried.emit(door_id())
		return false
	enter_requested.emit(door_id())
	return true


func _physics_process(delta: float) -> void:
	if def == null:
		return
	_step_feedback(delta)
	var who: Node3D = player
	if who == null and is_inside_tree():
		who = get_tree().get_first_node_in_group("player") as Node3D
	near = false
	if who != null and is_instance_valid(who):
		var half: Variant = who.get("body_half_height")
		var alive: bool = not who.has_method("state_name") or String(who.call("state_name")) != "dead"
		near = alive and not bool(who.get("controlled")) \
			and zone_contains(who.global_position.x, who.global_position.y - (float(half) if half != null else 0.0))
	_set_highlight((Highlight.DIM if is_locked() else Highlight.BRIGHT) if near else Highlight.NONE)
	_refresh_prompt()
	if near and GameplayInputScript.just_pressed(ACTION):
		try_enter()


func _step_feedback(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		_body.position.x = SHAKE_M * sin(_shake_left * 70.0) if _shake_left > 0.0 else 0.0
	if _lock_left > 0.0:
		_lock_left = maxf(_lock_left - delta, 0.0)
		_lock.visible = _lock_left > 0.0


func _refresh_prompt() -> void:
	if _prompt == null:
		return
	_prompt.visible = near
	_prompt.text = "[%s]" % ActionGlyphsScript.glyph(String(ACTION), using_pad)
	_prompt.modulate = Color(0.6, 0.6, 0.65, 0.8) if highlight == Highlight.DIM else Color(1, 1, 1, 1)


func _set_highlight(mode: Highlight) -> void:
	if highlight == mode:
		return
	highlight = mode
	for material: StandardMaterial3D in _lit:
		material.emission_enabled = mode != Highlight.NONE
		material.emission = Color(1.0, 0.82, 0.3) if mode == Highlight.BRIGHT else Color(0.55, 0.55, 0.6)
		material.emission_energy_multiplier = 0.11 if mode == Highlight.BRIGHT else 0.06


## A padlock built from boxes (no font glyph needed), above the prompt.
func _build_lock() -> void:
	_lock = Node3D.new()
	_lock.name = "LockGlyph"
	_lock.position = Vector3(0.0, 2.65, 0.0)
	_lock.visible = false
	add_child(_lock)
	var gold: Color = Color(1.0, 0.82, 0.2)
	var parts: Array[MeshInstance3D] = [
		_box(_lock, "LockBody", Vector3(0.62, 0.46, 0.12), gold, Vector3(0.0, 0.0, 0.0)),
		_box(_lock, "ShackleLeft", Vector3(0.1, 0.36, 0.1), gold, Vector3(-0.19, 0.36, 0.0)),
		_box(_lock, "ShackleRight", Vector3(0.1, 0.36, 0.1), gold, Vector3(0.19, 0.36, 0.0)),
		_box(_lock, "ShackleTop", Vector3(0.48, 0.1, 0.1), gold, Vector3(0.0, 0.56, 0.0)),
		_box(_lock, "Keyhole", Vector3(0.09, 0.2, 0.02), Color(0.15, 0.1, 0.0), Vector3(0.0, -0.02, 0.07)),
	]
	for part: MeshInstance3D in parts:
		var material: StandardMaterial3D = part.material_override as StandardMaterial3D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _box(parent: Node3D, box_name: String, size: Vector3, color: Color, at: Vector3) -> MeshInstance3D:
	return PrologueSetScript.add_mesh(parent, box_name, PrologueSetScript.box_mesh(size), color, at)


## A frame part: it lights up with the highlight.
func _lit_box(box_name: String, size: Vector3, color: Color, at: Vector3) -> void:
	_lit.append(_box(_body, box_name, size, color, at).material_override as StandardMaterial3D)
