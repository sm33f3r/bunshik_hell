extends Node3D
## Gray-box look of her hand, the wooden pick, her mouth, and the shadow telegraph on the tabletop.
## Only the hand and the pick come from above the screen; her mouth shows only at the top of the
## screen when the pick is lifted to it. Her face and body are never drawn. It draws what the
## PrologueDirector says is happening; it decides nothing. Sizes come from the real-size table.

const DirectorScript := preload("res://prologue/prologue_director.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const PrologueSetScript := preload("res://prologue/prologue_set.gd")
const SetDimensionsScript := preload("res://prologue/set_dimensions.gd")
const HandScript := preload("res://prologue/prologue_hand.gd")
const MouthScript := preload("res://prologue/prologue_mouth.gd")

## How far above the counter the pick rests off-screen, and where it hovers during a telegraph.
const REST_HEIGHT: float = 15.0
const PULL_HEIGHT: float = 5.5
const PULL_BACK: float = 0.9
## The pick is drawn a little in front of the 떡's plane while she stabs, so he never hides it.
## While he is speared on it, it is drawn IN his plane, so the part inside him is hidden by him.
const FRONT_Z: float = 0.35
const MOUTH_Z: float = 0.55
const SHADOW_COLOR: Color = Color(0.05, 0.02, 0.02, 0.62)
const WOOD: Color = Color(0.78, 0.6, 0.35)

var counter_y: float = 1.0
## Half his thickness (the 떡 lies on his side): set by the map from the player.
var body_half_height: float = 0.32
## Where the pick tip is now (world space). The 떡 rides on it during the opening and a lift.
var tip_position: Vector3 = Vector3.ZERO
## Where the shadow is (x) and whether it is shown.
var shadow_x: float = 0.0
var pick_length_m: float = 0.0

var _data: PrologueDataScript
var _rig: Node3D
var _pick: Node3D
var _hand: HandScript
var _mouth: MouthScript
var _shadow: MeshInstance3D
var _column: MeshInstance3D
var _mandu: MeshInstance3D
var _rest_x: float = 0.0
var _built: bool = false


func _ready() -> void:
	if not _built:
		build(null)


## Builds from the prologue data (null = the default data). Safe to call without a scene tree.
func build(prologue_data: PrologueDataScript) -> void:
	if _built:
		return
	_built = true
	_data = prologue_data if prologue_data != null else load(DirectorScript.DATA_PATH) as PrologueDataScript
	counter_y = _data.counter_top_y
	var d: SetDimensionsScript = _data.dims()
	var m: float = _data.m_per_cm()
	pick_length_m = d.pick_length_cm * m
	var thickness: float = d.pick_thickness_cm * m
	var point_len: float = minf(pick_length_m * 0.2, 0.3)

	_rig = Node3D.new()
	_rig.name = "PickRig"
	add_child(_rig)
	_pick = Node3D.new()
	_pick.name = "Pick"
	_rig.add_child(_pick)
	var shaft_len: float = pick_length_m - point_len
	PrologueSetScript.add_mesh(_pick, "Shaft", PrologueSetScript.cylinder_mesh(thickness * 0.5, thickness * 0.5, shaft_len),
		WOOD, Vector3(0.0, point_len + shaft_len * 0.5, 0.0))
	# The point: the tip is the origin of the rig.
	PrologueSetScript.add_mesh(_pick, "Point", PrologueSetScript.cylinder_mesh(thickness * 0.5, 0.0, point_len),
		WOOD, Vector3(0.0, point_len * 0.5, 0.0))
	_hand = HandScript.new()
	_hand.name = "Hand"
	_rig.add_child(_hand)
	_hand.build(pick_length_m, d.hand_length_cm * m)

	var mandu_w: float = d.mandu_width_cm * m
	var mandu_mesh: SphereMesh = SphereMesh.new()
	mandu_mesh.radius = mandu_w * 0.5
	mandu_mesh.height = mandu_w * d.mandu_height_fraction
	_mandu = PrologueSetScript.add_mesh(_rig, "Mandu", mandu_mesh, Color(0.9, 0.82, 0.55), Vector3(0.0, mandu_w * 0.3, 0.0))
	_mandu.visible = false

	_mouth = MouthScript.new()
	_mouth.name = "Mouth"
	add_child(_mouth)
	_mouth.build(d.mouth_width_cm * m, d.mouth_open_cm * m)
	_mouth.visible = false

	_shadow = MeshInstance3D.new()
	_shadow.name = "Shadow"
	var shadow_mesh: CylinderMesh = CylinderMesh.new()
	shadow_mesh.top_radius = 1.0
	shadow_mesh.bottom_radius = 1.0
	shadow_mesh.height = 0.02
	shadow_mesh.radial_segments = 24
	_shadow.mesh = shadow_mesh
	var shadow_material: StandardMaterial3D = PrologueSetScript.material(SHADOW_COLOR)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_material
	_shadow.visible = false
	_shadow.top_level = true
	add_child(_shadow)
	# A faint vertical column so the telegraph also reads from the side camera's shallow angle.
	_column = MeshInstance3D.new()
	_column.name = "Column"
	var column_mesh: BoxMesh = BoxMesh.new()
	column_mesh.size = Vector3(1.0, 8.0, 0.02)
	_column.mesh = column_mesh
	var column_material: StandardMaterial3D = PrologueSetScript.material(Color(0.9, 0.15, 0.1, 0.16))
	column_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	column_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_column.material_override = column_material
	_column.visible = false
	_column.top_level = true
	add_child(_column)


# --- Measuring (tests) ---------------------------------------------------------------------------------

## Length and thickness of the pick, from its meshes: Vector2(length, thickness).
func pick_size() -> Vector2:
	var size: Vector3 = PrologueSetScript.mesh_size(_pick)
	return Vector2(size.y, size.x)


func hand_length_m() -> float:
	return _hand.measured_length_m()


func mouth_node() -> MouthScript:
	return _mouth


func mouth_visible() -> bool:
	return _mouth != null and _mouth.visible


func hand_visible() -> bool:
	return _hand != null and _hand.visible


func shadow_visible() -> bool:
	return _shadow != null and _shadow.visible


func shadow_node_x() -> float:
	return _shadow.global_position.x if _shadow != null else 0.0


func pick_visible() -> bool:
	return _rig != null and _rig.visible


## While he is speared, his centre is this far ABOVE the pick tip (the tip is inside him).
func spear_centre_above_tip() -> float:
	return spear_depth() - body_half_height


## How far the pick goes into him from his top, clamped to his thickness minus a margin.
func spear_depth() -> float:
	return clampf(_data.spear_depth_m, 0.0, maxf(2.0 * body_half_height - _data.spear_margin_m, 0.0))


func reset_visual() -> void:
	if _rig != null:
		_rig.visible = true


## Poses everything for the director's current moment. Call once per physics tick.
func apply(d: DirectorScript) -> void:
	if _pick == null:
		return
	var tip: Vector3 = Vector3(_rest_x, counter_y + REST_HEIGHT, FRONT_Z)
	var tilt: float = 0.0
	var show_shadow: bool = false
	var shadow_scale: float = 0.0
	var half: float = 0.3
	var hand_shown: bool = true
	var holding_mandu: bool = false
	var mouth_open: float = -1.0 # < 0: mouth not shown
	var mouth_pos: Vector3 = Vector3.ZERO
	match d.state:
		DirectorScript.State.INTRO, DirectorScript.State.NOT_STARTED:
			tip = Vector3(d.data.cup_x, d.data.cup_top_y + 0.05, 0.0)
			hand_shown = false
		DirectorScript.State.PICK:
			var p: float = d.wiggle_time_progress()
			tip = Vector3(d.data.cup_x, d.data.cup_top_y + 0.05 + d.data.pick_rise_m * p, 0.0)
			mouth_pos = _mouth_at(tip, p)
			mouth_open = _mouth_open_amount(d, p)
		DirectorScript.State.EATEN:
			tip = Vector3(d.eaten_x, counter_y + d.data.pick_final_height_m, 0.0)
			mouth_pos = _mouth_at(tip, 1.0)
			mouth_open = _mouth_open_amount(d, 1.0)
		DirectorScript.State.LIFT:
			var p: float = d.wiggle_time_progress()
			tip = Vector3(d.lift_x, counter_y + 0.02 + d.data.lift_rise_m * p, 0.0)
			mouth_pos = _mouth_at(tip, p)
			mouth_open = _mouth_open_amount(d, p)
		_:
			var s: DirectorScript.Stab = d.stab
			if s != null:
				half = s.half_width
				var rest: float = counter_y + REST_HEIGHT
				var down: float = counter_y + 0.02
				var pulled: float = counter_y + PULL_HEIGHT + PULL_BACK
				match s.phase:
					DirectorScript.Phase.TELEGRAPH:
						var u: float = clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0)
						var come: float = smoothstep(0.0, 0.35, u)
						var pull: float = smoothstep(0.7, 1.0, u)
						tip = Vector3(lerpf(_rest_x, s.target_x, come),
							lerpf(rest, counter_y + PULL_HEIGHT, come) + PULL_BACK * pull, FRONT_Z)
						show_shadow = s.hazard or s.kind == DirectorScript.KIND_FAKE or s.kind == DirectorScript.KIND_MANDU
						shadow_scale = lerpf(0.35, 1.0, u)
					DirectorScript.Phase.STRIKE:
						var u: float = clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0)
						tip = Vector3(s.target_x, lerpf(pulled, down, u * u), FRONT_Z)
						show_shadow = s.hazard
						shadow_scale = 1.0
					DirectorScript.Phase.HOLD:
						tip = Vector3(s.target_x, down, FRONT_Z)
						holding_mandu = s.kind == DirectorScript.KIND_MANDU and s.mandu_hit
					DirectorScript.Phase.DRAG:
						tip = Vector3(s.tip_x, down, FRONT_Z)
						tilt = -0.9 * signf(s.drag_to - s.drag_from)
					DirectorScript.Phase.RETRACT:
						var u: float = smoothstep(0.0, 1.0, clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0))
						tip = Vector3(s.tip_x, lerpf(down, rest, u), FRONT_Z)
						holding_mandu = s.kind == DirectorScript.KIND_MANDU and s.mandu_hit
					DirectorScript.Phase.FAKE_RETRACT:
						var u: float = smoothstep(0.0, 1.0, clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0))
						tip = Vector3(s.target_x, lerpf(pulled, rest, u), FRONT_Z)
				if s.kind == DirectorScript.KIND_FINAL and s.phase == DirectorScript.Phase.STRIKE:
					show_shadow = false
			_rest_x = tip.x if s != null else _rest_x
	tip_position = tip
	_rig.position = tip
	_rig.rotation.z = tilt
	_hand.visible = hand_shown
	_mandu.visible = holding_mandu
	_mouth.visible = mouth_open >= 0.0
	if mouth_open >= 0.0:
		_mouth.position = mouth_pos
		_mouth.set_open(mouth_open)
	_shadow.visible = show_shadow
	_column.visible = show_shadow and d.state == DirectorScript.State.STAB \
		and d.stab != null and d.stab.phase == DirectorScript.Phase.TELEGRAPH
	if show_shadow and d.stab != null:
		shadow_x = d.stab.target_x
		_shadow.global_position = Vector3(shadow_x, counter_y + 0.025, 0.0)
		_shadow.scale = Vector3(maxf(half * 1.7 * shadow_scale, 0.05), 1.0, 0.75 * shadow_scale)
		_column.global_position = Vector3(shadow_x, counter_y + 4.0, 0.0)
		_column.scale = Vector3(maxf(half * 2.0, 0.05), 1.0, 1.0)


## Where the middle of her mouth is while the pick is p (0..1) of the way up: it slides down from
## above the screen to frame him at the end of the lift.
func _mouth_at(tip: Vector3, p: float) -> Vector3:
	var final_y: float = counter_y + _data.pick_final_height_m + spear_centre_above_tip()
	var u: float = smoothstep(_data.mouth_appear_from, 1.0, p)
	var y: float = lerpf(counter_y + _data.mouth_start_height_m, final_y, u)
	return Vector3(tip.x, y, MOUTH_Z)


## 1 = open. While he is being lifted the mouth is open; in the eaten beat it chomps shut.
## Below 0 (hidden) until it has slid into view.
func _mouth_open_amount(d: DirectorScript, p: float) -> float:
	if d.state == DirectorScript.State.EATEN:
		return clampf(1.0 - d.eaten_t / maxf(_data.eaten_chomp_s, 0.01), 0.0, 1.0)
	if p <= _data.mouth_appear_from:
		return -1.0
	return 1.0
