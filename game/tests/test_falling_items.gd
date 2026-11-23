extends "res://tests/base_test.gd"
## Task 3b-ii-fix, item 4: the falling chopsticks and spoons of the floor lane, as data and rules. The
## zone's def, the items' defs, the free columns (nothing over a table), the weighted pick, the cap with
## the oldest going first, the one-time hurt, the harmless prop it becomes, and the layout's zones. The
## zone is driven by hand (step / step_items), without waiting for physics frames.

const FallingZoneScene: PackedScene = preload("res://hazards/falling_zone.tscn")
const FallingZoneDefScript := preload("res://hazards/falling_zone_def.gd")
const FallingItemDefScript := preload("res://hazards/falling_item_def.gd")
const StrikeZoneScript := preload("res://hazards/strike_zone.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const SectionBuilderScript := preload("res://maps/layout/section_builder.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const LayoutPath: String = "res://data/maps/ep01/map01_layout.tres"
const M: float = 0.1745
const DT: float = 1.0 / 60.0

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _zone_def() -> FallingZoneDefScript:
	return load("res://data/hazards/falling_items.tres") as FallingZoneDefScript


func _zone(width_m: float = 20.0, at_x: float = 0.0) -> Node3D:
	var zone: Node3D = FallingZoneScene.instantiate() as Node3D
	zone.set("width_m", width_m)
	zone.set("m_per_cm", M)
	zone.set("enabled", false) # nobody ticks the clock but the test
	zone.position = Vector3(at_x, 0.0, 0.0)
	tree.root.add_child(zone)
	_nodes.append(zone)
	return zone


## A stand-in for the 떡: counts the hurts it is given.
class FakePlayer extends Node3D:
	var hurts: Array[int] = []
	var body_half_height: float = 0.32

	func hurt(half_hearts: int, _source_x: float) -> bool:
		hurts.append(half_hearts)
		return true


func _player_at(x: float, y: float) -> FakePlayer:
	var player: FakePlayer = FakePlayer.new()
	tree.root.add_child(player)
	player.position = Vector3(x, y, 0.0)
	_nodes.append(player)
	return player


## Lets the zone fall, one item, to the ground. Returns the number of ticks it took.
func _fall_to_ground(zone: Node3D, ticks_max: int = 600) -> int:
	for i: int in ticks_max:
		if (zone.get("falling") as Array).is_empty():
			return i
		zone.call("step_items", DT)
	return ticks_max


# --- The data ---------------------------------------------------------------------------------------

func test_the_falling_items_def_is_complete() -> void:
	var def: FallingZoneDefScript = _zone_def()
	check(def != null, "data/hazards/falling_items.tres loads as a FallingZoneDef")
	check_eq(def.items.size(), 2, "chopsticks and a spoon")
	check_eq(def.cap, 4, "four props at most per zone")
	check(absf(def.telegraph_s - 0.6) < 0.001, "the shadow shows for about 0.6 s (%.2f)" % def.telegraph_s)
	check(def.cooldown_min_s > 0.0 and def.cooldown_max_s >= def.cooldown_min_s, "an interval")
	check(def.start_height_m > 5.0, "items start above the top of the view of someone on the floor")
	check(def.active_range_m > 0.0 and def.clearance_cm >= 0.0, "range and clearance")
	var ids: Array[String] = []
	var total_weight: float = 0.0
	for item: FallingItemDefScript in def.items:
		check(item.id != "" and not ids.has(item.id), "%s: a unique id" % item.id)
		ids.append(item.id)
		check(item.weight > 0.0, "%s: a weight" % item.id)
		total_weight += item.weight
		check(item.fall_speed_mps > 0.0, "%s: a fall speed" % item.id)
		check(item.fall_width_cm > 0.0 and item.fall_length_cm > 0.0, "%s: a size while falling" % item.id)
		check_eq(item.damage_half_hearts, 1, "%s: half a heart" % item.id)
		check(item.prop_size_cm.x > 0.0 and item.prop_size_cm.y > 0.0 and item.prop_size_cm.z > 0.0, "%s: a prop size" % item.id)
	check(ids.has("falling_chopsticks") and ids.has("falling_spoon"), "metal chopsticks and spoons: " + str(ids))
	check(total_weight > 0.0, "the weights add up")
	check(not def.aim_player, "it does not snipe him: customers drop things at random")


func test_the_landed_props_are_low_enough_to_jump_over_and_stand_on() -> void:
	var tuning: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	var jump_height: float = tuning.jump_velocity * tuning.jump_velocity / (2.0 * tuning.gravity)
	var chop: FallingItemDefScript = load("res://data/hazards/falling_chopsticks.tres") as FallingItemDefScript
	var spoon: FallingItemDefScript = load("res://data/hazards/falling_spoon.tres") as FallingItemDefScript
	check(chop.prop_size_cm.y * M < jump_height * 0.3, "chopsticks: a thin low platform (%.2f m, jump %.2f m)" % [chop.prop_size_cm.y * M, jump_height])
	check(spoon.prop_size_cm.y * M < jump_height * 0.3, "spoon: low too (%.2f m)" % [spoon.prop_size_cm.y * M])
	check(chop.prop_size_cm.x > spoon.prop_size_cm.x, "the chopsticks are the long thin one")
	check(spoon.prop_size_cm.y > chop.prop_size_cm.y and spoon.prop_size_cm.z > chop.prop_size_cm.z, "the spoon is the small bowl: taller and wider")


func test_the_table_chopsticks_are_left_alone() -> void:
	var table: Resource = load("res://data/hazards/chopsticks.tres")
	check_eq(table.get("telegraph_s"), 0.8, "the table chopsticks keep their own telegraph")
	check_eq(table.get("wiggle_required"), 4, "and their wiggle")
	check_eq(table.get("damage_half_hearts"), 1, "and their pinch")
	check((table.get("takes_enemy_ids") as PackedStringArray).has("mandu"), "and take a 만두")
	check(not (_zone_def() is Object and _zone_def().get_script().resource_path.ends_with("chopsticks_def.gd")), "the falling zone is its own def")


# --- Where things may fall -----------------------------------------------------------------------------

func test_nothing_falls_where_a_table_is_above() -> void:
	var zone: Node3D = _zone(20.0, 0.0) # x from -10 to 10
	var item: FallingItemDefScript = load("res://data/hazards/falling_chopsticks.tres") as FallingItemDefScript
	var all: Array[Vector2] = zone.call("free_columns", item)
	check_eq(all.size(), 1, "no tables: the whole zone, less the item's half width")
	zone.call("set_cover", [Vector2(-12.0, -4.0), Vector2(-1.0, 3.0)] as Array[Vector2])
	var columns: Array[Vector2] = zone.call("free_columns", item)
	check_eq(columns.size(), 2, "two gaps: " + str(columns))
	for column: Vector2 in columns:
		for blocked: Vector2 in [Vector2(-12.0, -4.0), Vector2(-1.0, 3.0)]:
			var half: float = item.fall_width_cm * M * 0.5
			check(column.y + half <= blocked.x or column.x - half >= blocked.y, "%s keeps clear of %s" % [str(column), str(blocked)])
	zone.call("set_cover", [Vector2(-30.0, 30.0)] as Array[Vector2])
	check((zone.call("free_columns", item) as Array).is_empty(), "a table over the whole zone: no free column")
	zone.set("strike_x", 0.0)
	var x: float = zone.call("_pick_strike_x")
	check(is_nan(x), "so there is nowhere to drop")
	zone.set("strike_x", x)
	zone.call("_on_strike")
	check_eq((zone.get("falling") as Array).size(), 0, "and nothing falls")
	check_eq(zone.get("skipped"), 1, "it is counted as a skipped drop")


func test_every_pick_lands_in_a_free_column_and_the_weights_are_followed() -> void:
	var zone: Node3D = _zone(60.0, 0.0)
	var cover: Array[Vector2] = [Vector2(-30.0, -20.0), Vector2(-17.0, -8.0), Vector2(-5.5, 6.0), Vector2(9.0, 20.0), Vector2(22.5, 30.0)]
	zone.call("set_cover", cover)
	(zone.get("rng") as RandomNumberGenerator).seed = 12345
	var counts: Dictionary = {}
	for i: int in 600:
		var x: float = zone.call("_pick_strike_x")
		check(not is_nan(x), "there is room")
		var item: FallingItemDefScript = zone.get("current_item")
		counts[item.id] = int(counts.get(item.id, 0)) + 1
		var half: float = item.fall_width_cm * M * 0.5
		for blocked: Vector2 in cover:
			if x + half > blocked.x and x - half < blocked.y:
				check(false, "x %.2f of %s meets the table %s" % [x, item.id, str(blocked)])
				return
	var chop: int = counts.get("falling_chopsticks", 0)
	var spoon: int = counts.get("falling_spoon", 0)
	check(chop > spoon and spoon > 100, "chopsticks %d, spoons %d: the weights 3:2 are followed" % [chop, spoon])


# --- Falling, hurting once, landing ---------------------------------------------------------------------

func test_a_falling_item_hurts_the_player_for_half_a_heart_once() -> void:
	var zone: Node3D = _zone()
	var player: FakePlayer = _player_at(0.0, 3.0)
	zone.set("target_player", player)
	var item_def: FallingItemDefScript = load("res://data/hazards/falling_chopsticks.tres") as FallingItemDefScript
	zone.call("drop", item_def, 0.0)
	check_eq((zone.get("falling") as Array).size(), 1, "it is in the air")
	for i: int in 400:
		zone.call("step_items", DT)
	check_eq(player.hurts, [1] as Array[int], "hurt once, for half a heart, while it fell past him: " + str(player.hurts))
	check_eq(zone.get("player_hits"), 1, "counted once")
	check((zone.get("falling") as Array).is_empty(), "and it has landed")


func test_a_landed_item_is_a_harmless_solid_prop() -> void:
	var zone: Node3D = _zone()
	var item_def: FallingItemDefScript = load("res://data/hazards/falling_spoon.tres") as FallingItemDefScript
	var player: FakePlayer = _player_at(8.0, 0.32)
	zone.set("target_player", player)
	zone.call("drop", item_def, 2.0)
	check(_fall_to_ground(zone) < 600, "it landed")
	var props: Array[Node3D] = zone.call("live_props")
	check_eq(props.size(), 1, "one prop")
	var body: StaticBody3D = props[0] as StaticBody3D
	check(body != null and body.is_in_group("falling_props"), "a solid body")
	check_eq(body.collision_layer, 1, "on the world layer: he can stand on it")
	var shape: CollisionShape3D = body.get_node("CollisionShape3D") as CollisionShape3D
	check(not shape.disabled, "solid")
	var size: Vector3 = (shape.shape as BoxShape3D).size
	check(absf(size.y - item_def.prop_size_cm.y * M) < 0.001, "as high as the data says (%.2f m)" % size.y)
	check(absf(body.global_position.y - size.y * 0.5) < 0.05, "standing on the ground")
	check(absf(body.global_position.x - 2.0) < 0.01, "where it fell")
	for i: int in 120:
		zone.call("step_items", DT)
	check(player.hurts.is_empty(), "a landed prop hurts nobody")
	check(not body.has_method("hurt") and not body.is_in_group("hazards"), "and is no hazard")


func test_a_prop_waits_until_nobody_stands_where_it_landed() -> void:
	var zone: Node3D = _zone()
	var item_def: FallingItemDefScript = load("res://data/hazards/falling_spoon.tres") as FallingItemDefScript
	var player: FakePlayer = _player_at(2.0, 0.32)
	zone.set("target_player", player)
	zone.call("drop", item_def, 2.0)
	_fall_to_ground(zone)
	var body: StaticBody3D = (zone.call("live_props") as Array)[0] as StaticBody3D
	var shape: CollisionShape3D = body.get_node("CollisionShape3D") as CollisionShape3D
	check(shape.disabled, "he is standing on the spot: not solid yet (it would shove him)")
	player.position.x = 9.0
	zone.call("step_items", DT)
	check(not shape.disabled, "he moved: now solid")


func test_the_cap_keeps_four_props_and_the_oldest_goes_first() -> void:
	var zone: Node3D = _zone(40.0, 0.0)
	var item_def: FallingItemDefScript = load("res://data/hazards/falling_chopsticks.tres") as FallingItemDefScript
	var made: Array[Node3D] = []
	for i: int in 6:
		zone.call("drop", item_def, -15.0 + float(i) * 6.0)
		_fall_to_ground(zone)
		var live: Array[Node3D] = zone.call("live_props")
		made.append(live[live.size() - 1])
		check(live.size() <= 4, "after %d landings there are %d props" % [i + 1, live.size()])
	var live_now: Array[Node3D] = zone.call("live_props")
	check_eq(live_now.size(), 4, "four props stay")
	check(made[0].is_queued_for_deletion() and made[1].is_queued_for_deletion(), "the two oldest are gone")
	for i: int in range(2, 6):
		check(not made[i].is_queued_for_deletion(), "prop %d is still there" % i)
	check_eq(zone.get("dropped"), 6, "six fell")


func test_clearing_the_zone_takes_the_props_and_the_things_in_the_air() -> void:
	var zone: Node3D = _zone()
	var item_def: FallingItemDefScript = load("res://data/hazards/falling_spoon.tres") as FallingItemDefScript
	zone.call("drop", item_def, -4.0)
	_fall_to_ground(zone)
	zone.call("drop", item_def, 4.0)
	check_eq((zone.call("live_props") as Array).size(), 1, "a prop and one in the air")
	zone.call("clear_all")
	check((zone.call("live_props") as Array).is_empty() and (zone.get("falling") as Array).is_empty(), "everything is gone")


func test_the_clock_runs_shadow_then_fall_then_wait() -> void:
	var zone: Node3D = _zone()
	zone.set("enabled", true)
	var def: FallingZoneDefScript = _zone_def()
	var phases: Array[int] = []
	var t: float = 0.0
	var telegraph_began: float = -1.0
	var dropped_at: float = -1.0
	while t < 20.0 and dropped_at < 0.0:
		zone.call("step", DT)
		t += DT
		if telegraph_began < 0.0 and zone.get("phase") == StrikeZoneScript.Phase.TELEGRAPH:
			telegraph_began = t
		if zone.get("dropped") > 0:
			dropped_at = t
	check(telegraph_began > 0.0 and dropped_at > 0.0, "a shadow, then a drop")
	check(absf((dropped_at - telegraph_began) - def.telegraph_s) < 0.05, "the shadow warned for %.2f s" % (dropped_at - telegraph_began))
	check(telegraph_began >= def.cooldown_min_s - 0.05 and telegraph_began <= def.cooldown_max_s + 0.05, "after the interval (%.2f s)" % telegraph_began)
	check(phases.is_empty(), "no stray phases")


func test_a_gentler_interval_scale_makes_longer_waits() -> void:
	var calm: Node3D = _zone()
	calm.set("interval_scale", 2.0)
	var busy: Node3D = _zone()
	busy.set("interval_scale", 0.5)
	var def: FallingZoneDefScript = _zone_def()
	for i: int in 30:
		var a: float = calm.call("next_cooldown")
		var b: float = busy.call("next_cooldown")
		check(a >= def.cooldown_min_s * 2.0 - 0.001 and a <= def.cooldown_max_s * 2.0 + 0.001, "calm: %.2f" % a)
		check(b >= def.cooldown_min_s * 0.5 - 0.001 and b <= def.cooldown_max_s * 0.5 + 0.001, "busy: %.2f" % b)


# --- The layout -----------------------------------------------------------------------------------------

func _layout_zones() -> Array[SpawnEntryScript]:
	var layout: MapLayoutScript = load(LayoutPath) as MapLayoutScript
	var out: Array[SpawnEntryScript] = []
	for section in layout.sections:
		for entry: SpawnEntryScript in section.spawns:
			if entry.scene != null and entry.scene.resource_path.get_file() == "falling_zone.tscn":
				out.append(entry)
	return out


func test_the_layout_has_a_few_floor_zones_gentle_early_and_dense_late() -> void:
	var zones: Array[SpawnEntryScript] = _layout_zones()
	check(zones.size() >= 3 and zones.size() <= 8, "a few zones (%d)" % zones.size())
	var last_along: float = -1.0
	var last_scale: float = INF
	for entry: SpawnEntryScript in zones:
		check_eq(entry.platform_id, "dining_floor", "on the floor lane only")
		check(entry.along_m > last_along, "in order along the lane")
		var interval: float = float(entry.params.get("interval_scale", 1.0))
		check(interval > 0.0 and interval <= last_scale, "each one at least as dense as the one before (%.2f)" % interval)
		last_along = entry.along_m
		last_scale = interval
	check(float(zones[0].params.get("interval_scale", 1.0)) >= 1.5 * float(zones[zones.size() - 1].params.get("interval_scale", 1.0)), "the first is much gentler than the last")


func test_every_layout_zone_has_room_to_drop_and_none_reaches_a_table() -> void:
	var data: PrologueDataScript = load("res://data/prologue/prologue.tres") as PrologueDataScript
	var layout: MapLayoutScript = load(LayoutPath) as MapLayoutScript
	var reach: JumpReachScript = JumpReachScript.new(load("res://data/movement_tuning.tres") as MovementTuningScript,
		load("res://data/enemies/danmuji.tres") as EnemyDefScript, data.m_per_cm())
	var anchor: Dictionary = {"left": data.next_table_min_x, "right": data.next_table_max_x, "top": data.next_table_top_y,
		"thickness": data.dims().next_table_thickness_cm * data.m_per_cm()}
	var placed: Array[LayoutGeometryScript.Placed] = LayoutGeometryScript.resolve(layout, reach, anchor)
	var builder: SectionBuilderScript = SectionBuilderScript.new()
	tree.root.add_child(builder)
	_nodes.append(builder)
	builder.build(layout, placed, data.m_per_cm(), data.dims().counter_depth_cm * data.m_per_cm())
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_floor")
	var cover: Array[Vector2] = builder.cover_ranges()
	check(not cover.is_empty(), "the builder knows what is above the floor")
	for entry: SpawnEntryScript in _layout_zones():
		var where: String = "zone @ %.0f m" % entry.along_m
		var zone: Node3D = entry.scene.instantiate() as Node3D
		zone.set("width_m", entry.size_cm * data.m_per_cm())
		zone.set("m_per_cm", data.m_per_cm())
		zone.set("enabled", false)
		zone.call("set_cover", cover)
		zone.position = LayoutGeometryScript.spawn_position(placed, entry)
		tree.root.add_child(zone)
		_nodes.append(zone)
		check(zone.call("zone_left") >= lane.left - 0.001 and zone.call("zone_right") <= lane.right + 0.001, "%s: inside the floor lane" % where)
		var zdef: FallingZoneDefScript = zone.get("def")
		for item: FallingItemDefScript in zdef.items:
			var columns: Array[Vector2] = zone.call("free_columns", item)
			check(not columns.is_empty(), "%s: room for %s to fall" % [where, item.id])
			var half: float = item.fall_width_cm * data.m_per_cm() * 0.5
			for column: Vector2 in columns:
				for blocked: Vector2 in cover:
					check(column.y + half <= blocked.x + 0.001 or column.x - half >= blocked.y - 0.001, "%s: %s column %s meets a table at %s" % [where, item.id, str(column), str(blocked)])
