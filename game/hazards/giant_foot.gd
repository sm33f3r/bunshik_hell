extends "res://hazards/strike_zone.gd"
## A giant foot. A shadow on the floor warns (about a second), then the foot smooshes down: 1 heart
## and a brief flatten-stun (he is flat, then pops back). Not an instant kill. It also crushes enemies
## under it: a 만두 dies, a 단무지 is knocked over (the reaction table's "foot" row decides). Gray box:
## a box with a shoe marker. Numbers: data/hazards/giant_foot.tres.

const Layers_ := preload("res://systems/layers.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const GiantFootDefScript := preload("res://hazards/giant_foot_def.gd")
const SHOE: Color = Color(0.25, 0.2, 0.3)
const SOLE: Color = Color(0.9, 0.9, 0.85)

## The def as giant-foot data.
var fdef: GiantFootDefScript:
	get: return def as GiantFootDefScript

## How many enemies the last strike crushed (tests).
var crushed: int = 0

var _foot: Node3D
var _tween: Tween


func _on_strike() -> void:
	crushed = 0
	_drop_foot()
	var player: Node3D = _find_player()
	if player != null and under_strike(_xy(player), 0.5):
		player.call("smoosh", def.damage_half_hearts, fdef.stun_s)
	for enemy: Node3D in enemies_under_strike():
		var dir: float = signf(enemy.global_position.x - strike_x)
		enemy.call("receive_attack", ReactionTableScript.ATTACK_FOOT, dir if dir != 0.0 else 1.0, {"by_ddeok": false})
		crushed += 1


func _on_recover() -> void:
	if _foot == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if is_inside_tree():
		_tween = create_tween()
		_tween.tween_property(_foot, "position:y", fdef.drop_from_m, def.recover_s * 0.8)


func _hide_picture() -> void:
	super()
	if _foot != null:
		_foot.visible = false


func _build_picture() -> void:
	super()
	_foot = Node3D.new()
	_foot.name = "Foot"
	add_child(_foot)
	var w: float = strike_width_m()
	var h: float = fdef.foot_height_cm * _scale()
	PrologueSetScript.add_mesh(_foot, "Shoe", PrologueSetScript.box_mesh(Vector3(w, h, 1.2)), SHOE, Vector3(0.0, h * 0.5, 0.0))
	PrologueSetScript.add_mesh(_foot, "Sole", PrologueSetScript.box_mesh(Vector3(w, h * 0.15, 1.25)), SOLE, Vector3(0.0, h * 0.075, 0.0))
	PrologueSetScript.add_mesh(_foot, "Toe", PrologueSetScript.box_mesh(Vector3(w * 0.3, h * 0.5, 1.25)), SHOE.lightened(0.3),
		Vector3(w * 0.35, h * 0.45, 0.0))
	_foot.visible = false


func _drop_foot() -> void:
	if _foot == null or not is_inside_tree():
		return
	_foot.visible = true
	_foot.global_position = Vector3(strike_x, _origin().y + fdef.drop_from_m, _origin().z)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_foot, "global_position:y", _origin().y, minf(0.12, def.strike_hold_s * 0.5)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
