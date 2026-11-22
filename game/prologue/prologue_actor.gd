extends Node3D
## Gray-box look of her hand and the wooden pick, plus the shadow telegraph on the tabletop.
## Only the hand and the pick are ever shown, coming from above the screen. It draws what the
## PrologueDirector says is happening; it decides nothing.

const DirectorScript := preload("res://prologue/prologue_director.gd")

## How far above the counter the pick rests off-screen, and where it hovers during a telegraph.
const REST_HEIGHT: float = 15.0
const PULL_HEIGHT: float = 5.5
const PULL_BACK: float = 0.9
const SHAFT_LENGTH: float = 4.0
## The pick is drawn a little in front of the 떡's plane so it is never hidden by him.
const FRONT_Z: float = 0.35
const SHADOW_COLOR: Color = Color(0.05, 0.02, 0.02, 0.62)

var counter_y: float = 1.0
## Where the pick tip is now (world space). The 떡 rides on it during the opening and a lift.
var tip_position: Vector3 = Vector3.ZERO
## Where the shadow is (x) and whether it is shown.
var shadow_x: float = 0.0

var _pick: Node3D
var _hand: Node3D
var _shadow: MeshInstance3D
var _column: MeshInstance3D
var _mandu: MeshInstance3D
var _rest_x: float = 0.0
var _hidden_for_exit: bool = false


func _ready() -> void:
	var wood: StandardMaterial3D = _material(Color(0.78, 0.6, 0.35))
	var skin: StandardMaterial3D = _material(Color(0.93, 0.76, 0.66))
	_pick = Node3D.new()
	_pick.name = "Pick"
	add_child(_pick)
	var shaft: MeshInstance3D = MeshInstance3D.new()
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.045
	shaft_mesh.bottom_radius = 0.045
	shaft_mesh.height = SHAFT_LENGTH
	shaft.mesh = shaft_mesh
	shaft.material_override = wood
	shaft.position = Vector3(0.0, SHAFT_LENGTH * 0.5 + 0.4, 0.0)
	_pick.add_child(shaft)
	var point: MeshInstance3D = MeshInstance3D.new()
	var point_mesh: CylinderMesh = CylinderMesh.new()
	point_mesh.top_radius = 0.045
	point_mesh.bottom_radius = 0.0
	point_mesh.height = 0.8
	point.mesh = point_mesh
	point.material_override = wood
	point.position = Vector3(0.0, 0.4, 0.0)
	_pick.add_child(point)
	_hand = Node3D.new()
	_hand.name = "Hand"
	_hand.position = Vector3(0.0, SHAFT_LENGTH + 0.6, 0.0)
	_pick.add_child(_hand)
	var palm: MeshInstance3D = MeshInstance3D.new()
	var palm_mesh: BoxMesh = BoxMesh.new()
	palm_mesh.size = Vector3(0.55, 0.5, 0.4)
	palm.mesh = palm_mesh
	palm.material_override = skin
	_hand.add_child(palm)
	for i: int in 4:
		var finger: MeshInstance3D = MeshInstance3D.new()
		var finger_mesh: BoxMesh = BoxMesh.new()
		finger_mesh.size = Vector3(0.11, 0.42, 0.14)
		finger.mesh = finger_mesh
		finger.material_override = skin
		finger.position = Vector3(-0.2 + 0.133 * i, -0.4, 0.0)
		_hand.add_child(finger)
	_mandu = MeshInstance3D.new()
	var mandu_mesh: SphereMesh = SphereMesh.new()
	mandu_mesh.radius = 0.28
	mandu_mesh.height = 0.4
	_mandu.mesh = mandu_mesh
	_mandu.material_override = _material(Color(0.9, 0.82, 0.55))
	_mandu.position = Vector3(0.0, 0.7, 0.0)
	_mandu.visible = false
	_pick.add_child(_mandu)

	_shadow = MeshInstance3D.new()
	_shadow.name = "Shadow"
	var shadow_mesh: CylinderMesh = CylinderMesh.new()
	shadow_mesh.top_radius = 1.0
	shadow_mesh.bottom_radius = 1.0
	shadow_mesh.height = 0.02
	shadow_mesh.radial_segments = 24
	_shadow.mesh = shadow_mesh
	var shadow_material: StandardMaterial3D = _material(SHADOW_COLOR)
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
	var column_material: StandardMaterial3D = _material(Color(0.9, 0.15, 0.1, 0.16))
	column_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	column_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_column.material_override = column_material
	_column.visible = false
	_column.top_level = true
	add_child(_column)


func _material(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m


func shadow_visible() -> bool:
	return _shadow != null and _shadow.visible


func shadow_node_x() -> float:
	return _shadow.global_position.x if _shadow != null else 0.0


## The pick has become the stuck pick prop: draw nothing of it any more.
func hide_for_exit() -> void:
	_hidden_for_exit = true
	if _pick != null:
		_pick.visible = false
		_shadow.visible = false
		_column.visible = false


func reset_visual() -> void:
	_hidden_for_exit = false
	if _pick != null:
		_pick.visible = true


## Poses everything for the director's current moment. Call once per physics tick.
func apply(d: DirectorScript) -> void:
	if _pick == null:
		return
	var tip: Vector3 = Vector3(_rest_x, counter_y + REST_HEIGHT, FRONT_Z)
	var tilt: float = 0.0
	var show_shadow: bool = false
	var shadow_scale: float = 0.0
	var half: float = 0.3
	var hand_visible: bool = true
	var holding_mandu: bool = false
	match d.state:
		DirectorScript.State.INTRO, DirectorScript.State.NOT_STARTED:
			tip = Vector3(d.data.cup_x, d.data.cup_top_y + 0.05, FRONT_Z)
			hand_visible = false
		DirectorScript.State.PICK, DirectorScript.State.EATEN:
			var rise: float = d.data.pick_rise_m * d.wiggle_time_progress() if d.state == DirectorScript.State.PICK \
				else d.data.pick_rise_m
			tip = Vector3(d.data.cup_x, d.data.cup_top_y + 0.05 + rise, FRONT_Z)
		DirectorScript.State.LIFT:
			tip = Vector3(d.lift_x, counter_y + 0.02 + d.data.lift_rise_m * d.wiggle_time_progress(), FRONT_Z)
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
						show_shadow = s.hazard or s.kind == DirectorScript.KIND_FAKE
						shadow_scale = lerpf(0.35, 1.0, u)
					DirectorScript.Phase.STRIKE:
						var u: float = clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0)
						tip = Vector3(s.target_x, lerpf(pulled, down, u * u), FRONT_Z)
						show_shadow = s.hazard
						shadow_scale = 1.0
					DirectorScript.Phase.HOLD:
						tip = Vector3(s.target_x, down, FRONT_Z)
						holding_mandu = s.kind == DirectorScript.KIND_MANDU
					DirectorScript.Phase.DRAG:
						tip = Vector3(s.tip_x, down, FRONT_Z)
						tilt = -0.9 * signf(s.drag_to - s.drag_from)
					DirectorScript.Phase.RETRACT:
						var u: float = smoothstep(0.0, 1.0, clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0))
						tip = Vector3(s.tip_x, lerpf(down, rest, u), FRONT_Z)
						holding_mandu = s.kind == DirectorScript.KIND_MANDU
					DirectorScript.Phase.FAKE_RETRACT:
						var u: float = smoothstep(0.0, 1.0, clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0))
						tip = Vector3(s.target_x, lerpf(pulled, rest, u), FRONT_Z)
				if s.kind == DirectorScript.KIND_FINAL and s.phase == DirectorScript.Phase.STRIKE:
					show_shadow = false
			_rest_x = tip.x if s != null else _rest_x
	tip_position = tip
	_pick.position = tip
	_pick.rotation.z = tilt
	_pick.visible = not _hidden_for_exit
	_hand.visible = hand_visible
	_mandu.visible = holding_mandu
	show_shadow = show_shadow and not _hidden_for_exit
	_shadow.visible = show_shadow
	_column.visible = show_shadow and d.state == DirectorScript.State.STAB \
		and d.stab != null and d.stab.phase == DirectorScript.Phase.TELEGRAPH
	if show_shadow and d.stab != null:
		shadow_x = d.stab.target_x
		_shadow.global_position = Vector3(shadow_x, counter_y + 0.025, 0.0)
		_shadow.scale = Vector3(maxf(half * 1.7 * shadow_scale, 0.05), 1.0, 0.75 * shadow_scale)
		_column.global_position = Vector3(shadow_x, counter_y + 4.0, 0.0)
		_column.scale = Vector3(maxf(half * 2.0, 0.05), 1.0, 1.0)
