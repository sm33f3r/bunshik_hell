extends "res://hazards/strike_zone.gd"
## A zone on the floor lane where customers above drop metal chopsticks and spoons (Roster hazard,
## Task 3b-ii-fix). Like a strike zone: a shadow on the floor warns (the def's telegraph), then the item
## falls from the top of the view and hurts whoever it lands on while it falls (½ heart for the 떡, no grab;
## the foot's crush rule for enemies). Once it has landed it is a harmless prop: a low solid box he can
## jump over or stand on. A zone keeps at most `cap` props (the oldest goes first); they are children of
## the zone, so they go when the section starts over.
##
## Never over a table: `cover` lists the x ranges of everything above the floor (set by the section
## builder); nothing falls where an item (and the room beside it) would meet one. The table chopsticks
## (hazards/chopsticks.gd) are a different hazard and are not touched.
## Origin: on the floor, in the middle of the zone. Numbers: data/hazards/falling_items.tres.

signal landed(prop: Node3D)

const FallingItemScript := preload("res://hazards/falling_item.gd")
const FallingItemDefScript := preload("res://hazards/falling_item_def.gd")
const FallingZoneDefScript := preload("res://hazards/falling_zone_def.gd")
const Layers_ := preload("res://systems/layers.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")

## Half the 떡's body (metres), for what an item touches.
const BODY_HALF: Vector2 = Vector2(0.3, 0.32)

## 1 = the def's interval; a spawn's params may stretch it (gentle early) or shrink it (denser later).
@export var interval_scale: float = 1.0

## x ranges (left, right) of everything above the floor here.
var cover: Array[Vector2] = []
## The item the next drop will be (picked when the shadow appears).
var current_item: FallingItemDefScript
var falling: Array[Node3D] = []
## Landed props, oldest first.
var props: Array[Node3D] = []
## How many items fell, and how many shadows had nowhere free to drop.
var dropped: int = 0
var skipped: int = 0
## Hurts the 떡 dealt (tests).
var player_hits: int = 0

var _waiting_props: Array[Node3D] = []


func zdef() -> FallingZoneDefScript:
	return def as FallingZoneDefScript


func set_cover(ranges: Array[Vector2]) -> void:
	cover = ranges


func next_cooldown() -> float:
	return super() * maxf(interval_scale, 0.01)


func strike_width_m() -> float:
	if current_item != null:
		return current_item.fall_width_cm * _scale()
	return super()


# --- Picking what falls and where ----------------------------------------------------------------------

## A weighted pick from the def's list (null when the list is empty).
func choose_item() -> FallingItemDefScript:
	var items: Array[FallingItemDefScript] = zdef().items
	var total: float = 0.0
	for item: FallingItemDefScript in items:
		total += maxf(item.weight, 0.0)
	if items.is_empty() or total <= 0.0:
		return null
	var roll: float = rng.randf() * total
	for item: FallingItemDefScript in items:
		roll -= maxf(item.weight, 0.0)
		if roll <= 0.0:
			return item
	return items[items.size() - 1]


## The x ranges where the middle of `item` may fall: inside the zone, and with the item and the room
## beside it (the def's clearance) clear of everything in `cover`.
func free_columns(item: FallingItemDefScript) -> Array[Vector2]:
	var half: float = item.fall_width_cm * _scale() * 0.5 + zdef().clearance_cm * _scale()
	var free: Array[Vector2] = [Vector2(zone_left() + half, zone_right() - half)]
	if free[0].y <= free[0].x:
		return [] as Array[Vector2]
	for blocked: Vector2 in cover:
		var cut_left: float = blocked.x - half
		var cut_right: float = blocked.y + half
		var next: Array[Vector2] = []
		for range_x: Vector2 in free:
			if cut_right <= range_x.x or cut_left >= range_x.y:
				next.append(range_x)
				continue
			if cut_left > range_x.x:
				next.append(Vector2(range_x.x, cut_left))
			if cut_right < range_x.y:
				next.append(Vector2(cut_right, range_x.y))
		free = next
	return free


## Where this drop lands: a random spot of the free columns (weighted by their length); NAN when there is
## none (a table side overlaps the whole zone): then nothing falls this time.
func _pick_strike_x() -> float:
	current_item = choose_item()
	if current_item == null:
		return NAN
	var columns: Array[Vector2] = free_columns(current_item)
	var total: float = 0.0
	for range_x: Vector2 in columns:
		total += range_x.y - range_x.x
	if columns.is_empty() or total <= 0.0:
		return NAN
	var at: float = rng.randf() * total
	for range_x: Vector2 in columns:
		var span: float = range_x.y - range_x.x
		if at <= span:
			return range_x.x + at
		at -= span
	return columns[columns.size() - 1].y


## He is close enough for it to matter (or no one is looking: tests).
func _busy() -> bool:
	var player: Node3D = _find_player()
	return player != null and absf(_xy(player).x - _origin().x) > zdef().active_range_m + width_m * 0.5


# --- The drop -----------------------------------------------------------------------------------------

func _show_shadow() -> void:
	if is_nan(strike_x):
		return
	if _shadow != null:
		_shadow.mesh = PrologueSetScript.box_mesh(Vector3(strike_width_m() * 1.6, 0.04, 1.4))
	super()


func _on_strike() -> void:
	if is_nan(strike_x) or current_item == null:
		skipped += 1
		return
	drop(current_item, strike_x)


## Lets an item go from the top of the view.
func drop(item_def: FallingItemDefScript, x: float) -> Node3D:
	var item: Node3D = FallingItemScript.new() as Node3D
	item.call("setup", item_def, _scale())
	add_child(item)
	var origin: Vector3 = _origin()
	var start: Vector3 = Vector3(x, origin.y + zdef().start_height_m, origin.z)
	if item.is_inside_tree():
		item.global_position = start
	else:
		item.position = start - origin
	falling.append(item)
	dropped += 1
	return item


func _physics_process(delta: float) -> void:
	step(delta)
	step_items(delta)


## One tick of everything in the air and of the props waiting for a clear spot.
func step_items(delta: float) -> void:
	for item: Node3D in falling.duplicate():
		var ground: float = ground_y_at(item.call("x"), item.call("bottom_y"))
		var reached: bool = item.call("fall", delta, ground)
		_hit_things(item)
		if reached:
			_land(item, ground)
	_release_waiting_props()


## The top of whatever is under x (the floor, or a prop that landed there).
func ground_y_at(x: float, from_y: float) -> float:
	var floor_y: float = _origin().y
	if not is_inside_tree():
		return floor_y
	var from: Vector3 = Vector3(x, from_y + 0.05, _origin().z)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, Vector3(x, floor_y - 2.0, _origin().z), Layers_.WORLD)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit["position"].y) if not hit.is_empty() else floor_y


func _hit_things(item: Node3D) -> void:
	var player: Node3D = _find_player()
	# Only the floor lane is his to be hit on: someone up on the tables is above where items start.
	if player != null and not bool(item.get("hit_player")) and _xy(player).y <= _origin().y + zdef().start_height_m:
		var body: Vector2 = _xy(player)
		var half: Vector2 = Vector2(BODY_HALF.x, _half_height(player, BODY_HALF.y))
		if item.call("touches", body, half):
			item.set("hit_player", true)
			player_hits += 1
			player.call("hurt", current_damage(item), float(item.call("x")))
	if not zdef().hits_enemies or not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Node3D = node as Node3D
		if enemy == null or not bool(enemy.get("alive")):
			continue
		var id: int = enemy.get_instance_id()
		if (item.get("hit_enemy_ids") as Array).has(id):
			continue
		var half_h: float = float(enemy.get("body_height")) * 0.5
		var middle: Vector2 = Vector2(enemy.global_position.x, enemy.global_position.y + half_h)
		if item.call("touches", middle, Vector2(half_h, half_h)):
			(item.get("hit_enemy_ids") as Array).append(id)
			var dir: float = signf(enemy.global_position.x - float(item.call("x")))
			enemy.call("receive_attack", ReactionTableScript.ATTACK_FOOT, dir if dir != 0.0 else 1.0, {"by_ddeok": false})


func _half_height(body: Node3D, fallback: float) -> float:
	var value: Variant = body.get("body_half_height")
	return float(value) if value != null else fallback


func current_damage(item: Node3D) -> int:
	return (item.get("idef") as FallingItemDefScript).damage_half_hearts


# --- Landed: a harmless prop --------------------------------------------------------------------------

func _land(item: Node3D, ground: float) -> void:
	falling.erase(item)
	var item_def: FallingItemDefScript = item.get("idef") as FallingItemDefScript
	var x: float = item.call("x")
	item.queue_free()
	var prop: StaticBody3D = make_prop(item_def, x, ground)
	props.append(prop)
	while props.size() > maxi(zdef().cap, 1):
		var oldest: Node3D = props.pop_front()
		_waiting_props.erase(oldest)
		if is_instance_valid(oldest):
			oldest.queue_free()
	landed.emit(prop)


## The solid box a landed item becomes: low, on the ground, he can jump over it or stand on it. It is
## not solid while someone stands where it lands (it would shove them): it becomes solid when they have moved.
func make_prop(item_def: FallingItemDefScript, x: float, ground: float) -> StaticBody3D:
	var size: Vector3 = item_def.prop_size_cm * _scale()
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Prop_%s" % item_def.id
	body.collision_layer = Layers_.WORLD
	body.collision_mask = 0
	body.add_to_group("falling_props")
	body.add_to_group("section_decor")
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	PrologueSetScript.add_mesh(body, "Mesh", PrologueSetScript.box_mesh(size), item_def.color.darkened(0.15), Vector3.ZERO)
	add_child(body)
	var origin: Vector3 = _origin()
	var at: Vector3 = Vector3(x, ground + size.y * 0.5, origin.z)
	if body.is_inside_tree():
		body.global_position = at
	else:
		body.position = at - origin
	if _occupied(at, size):
		shape.disabled = true
		_waiting_props.append(body)
	return body


func _occupied(at: Vector3, size: Vector3) -> bool:
	var bodies: Array[Node3D] = []
	var player: Node3D = _find_player()
	if player != null:
		bodies.append(player)
	if is_inside_tree():
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			if node is Node3D and bool(node.get("alive")):
				bodies.append(node as Node3D)
	for body: Node3D in bodies:
		var p: Vector3 = body.global_position if body.is_inside_tree() else body.position
		var is_enemy: bool = body.get("body_height") != null
		var half_h: float = float(body.get("body_height")) * 0.5 if is_enemy else _half_height(body, BODY_HALF.y)
		var middle_y: float = p.y + (half_h if is_enemy else 0.0)
		if absf(p.x - at.x) < size.x * 0.5 + BODY_HALF.x and absf(middle_y - at.y) < size.y * 0.5 + half_h + 0.05:
			return true
	return false


func _release_waiting_props() -> void:
	for body: Node3D in _waiting_props.duplicate():
		if not is_instance_valid(body):
			_waiting_props.erase(body)
			continue
		var shape: CollisionShape3D = body.get_node("CollisionShape3D") as CollisionShape3D
		var size: Vector3 = (shape.shape as BoxShape3D).size
		var at: Vector3 = body.global_position if body.is_inside_tree() else body.position + _origin()
		if not _occupied(at, size):
			shape.disabled = false
			_waiting_props.erase(body)


## Takes every prop and everything in the air away (the section starts over).
func clear_all() -> void:
	for item: Node3D in falling:
		if is_instance_valid(item):
			item.queue_free()
	falling.clear()
	for prop: Node3D in props:
		if is_instance_valid(prop):
			prop.queue_free()
	props.clear()
	_waiting_props.clear()


## Props still in the world (not freed, not about to be).
func live_props() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for prop: Node3D in props:
		if is_instance_valid(prop) and not prop.is_queued_for_deletion():
			out.append(prop)
	return out
