extends Node3D
## Placeholder look and squiggle for the 떡. ONLY this node deforms; the collision
## shape on the player never changes. Origin of this node is at the 떡's feet, so
## squash and stretch stay planted on the ground.

## Squiggle cycles per second at full run speed. Scales down with speed.
@export var squiggle_frequency: float = 2.5
@export var squiggle_amount: float = 0.16
@export var squiggle_lean_degrees: float = 9.0
## Stretch (taller, thinner) at full vertical speed in the air.
@export var air_stretch: float = 0.22
@export var landing_squash: float = 0.4
## How fast the landing squash recovers, per second.
@export var landing_recovery: float = 14.0
## How fast the shown scale chases its target, per second.
@export var blend_speed: float = 28.0
@export var roll_spin_speed: float = 16.0
## Vertical speed that counts as "full" stretch.
@export var reference_air_speed: float = 12.0

var _phase: float = 0.0
var _squash: float = 0.0
var _spin: float = 0.0
var _body_material: StandardMaterial3D
var _body_mesh: MeshInstance3D
var _coat_material: StandardMaterial3D
var _rig: Node3D


func _ready() -> void:
	_rig = get_node_or_null("Rig") as Node3D
	var body: MeshInstance3D = get_node_or_null("Rig/Body") as MeshInstance3D
	_body_mesh = body
	if body != null and body.material_override is StandardMaterial3D:
		_body_material = (body.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		body.material_override = _body_material


## Pure: the deformation for a given moment. Returns {"scale": Vector3, "lean": float (radians)}.
func compute_deform(state_name: String, phase: float, speed_ratio: float, vy: float, squash: float) -> Dictionary:
	var scl: Vector3 = Vector3.ONE
	var lean: float = 0.0
	match state_name:
		"squiggle":
			var wave: float = sin(phase)
			var amount: float = squiggle_amount * clampf(speed_ratio, 0.3, 1.0)
			scl = Vector3(1.0 + amount * wave, 1.0 - amount * 0.7 * wave, 1.0 - amount * 0.3 * wave)
			lean = deg_to_rad(squiggle_lean_degrees) * cos(phase) * clampf(speed_ratio, 0.3, 1.0)
		"jump", "fall":
			var s: float = clampf(absf(vy) / reference_air_speed, 0.0, 1.0)
			scl = Vector3(1.0 - air_stretch * 0.5 * s, 1.0 + air_stretch * s, 1.0 - air_stretch * 0.3 * s)
		"stomp", "slam":
			scl = Vector3(0.8, 1.35, 0.9)
		"hurt":
			scl = Vector3(1.15, 0.85, 1.05)
		"dead":
			scl = Vector3(1.3, 0.25, 1.1)
		_:
			# idle: a tiny breathing wobble so he never looks frozen
			scl = Vector3(1.0, 1.0 + 0.02 * sin(phase), 1.0)
	if squash > 0.0:
		scl += Vector3(landing_squash * squash, -landing_squash * 1.1 * squash, landing_squash * 0.3 * squash)
	return {"scale": scl, "lean": lean}


func update_visual(delta: float, state_name: String, speed_ratio: float, vy: float, facing: float) -> void:
	var pivot: Node3D = get_parent() as Node3D
	if pivot != null:
		pivot.scale.x = signf(facing) if not is_zero_approx(facing) else pivot.scale.x

	var rate: float = squiggle_frequency * clampf(speed_ratio, 0.0, 1.0) if state_name == "squiggle" else 1.0
	_phase = fposmod(_phase + TAU * rate * delta, TAU)
	_squash = lerpf(_squash, 0.0, 1.0 - exp(-landing_recovery * delta))

	var target: Dictionary = compute_deform(state_name, _phase, speed_ratio, vy, _squash)
	var t: float = 1.0 - exp(-blend_speed * delta)
	scale = scale.lerp(target["scale"], t)

	if _rig == null:
		return
	if state_name == "roll":
		_spin -= roll_spin_speed * delta
		_rig.rotation.z = _spin
	else:
		_spin = 0.0
		_rig.rotation.z = lerp_angle(_rig.rotation.z, target["lean"], t)


func on_landed(impact_speed: float) -> void:
	_squash = clampf(impact_speed / reference_air_speed, 0.3, 1.0)


func set_flash(on: bool) -> void:
	if _body_material == null:
		return
	_body_material.emission_enabled = on
	_body_material.emission = Color.WHITE
	_body_material.emission_energy_multiplier = 1.5


## Gray-box coat (from 콩고물): a sandy translucent shell over the body while it is on.
func set_coat(on: bool) -> void:
	if _body_mesh == null:
		return
	if not on:
		_body_mesh.material_overlay = null
		return
	if _coat_material == null:
		_coat_material = StandardMaterial3D.new()
		_coat_material.albedo_color = Color(0.95, 0.85, 0.5, 0.55)
		_coat_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_coat_material.emission_enabled = true
		_coat_material.emission = Color(0.9, 0.7, 0.2)
		_coat_material.emission_energy_multiplier = 0.4
	_body_mesh.material_overlay = _coat_material
