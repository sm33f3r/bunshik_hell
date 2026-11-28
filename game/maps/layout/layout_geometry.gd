extends RefCounted
## Turns a MapLayout into places: where every platform stands, worked out from the one it is placed
## against and from what the 떡 can do (JumpReach). Also checks that the way through can be walked,
## that the hops to a windowsill are real, and that every point of a floor lane has a way back up.

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const CheckpointDefScript := preload("res://maps/layout/checkpoint_def.gd")
const PromptTriggerScript := preload("res://maps/layout/prompt_trigger.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")

## Used when validate() is not given a layout.
const DEFAULT_HEADROOM_M: float = 0.9
const DEFAULT_CLIMB_SPACING_M: float = 60.0
## Tolerance for "inside" / "touching" comparisons (metres).
const EPS: float = 0.0005
## How often the floor is sampled for the climb-back check (metres).
const FLOOR_SAMPLE_M: float = 1.0


## A platform with a place.
class Placed:
	var def: PlatformDefScript
	var section_id: String = ""
	## Position in the whole map (0 = the first platform of the first built section).
	var index: int = 0
	var left: float = 0.0
	var right: float = 0.0
	var top: float = 0.0
	var thickness: float = 0.0
	## Empty space before it and how much higher it is than its host (0 for the first).
	var gap_m: float = 0.0
	var rise_m: float = 0.0
	## What it is placed against (the one before it on the way through, or its named host).
	var prev: Placed = null
	## Part of the way through the map (the next platform is placed against it).
	var chain: bool = true

	func length() -> float:
		return right - left

	func center_x() -> float:
		return (left + right) * 0.5

	## The floor lane, a chair step: where a fall does not put him back at the checkpoint.
	func is_lane() -> bool:
		return def.kind == "floor" or def.kind == "block"


## `anchor` places the "existing" platform: {"left", "right", "top", "thickness"} in metres.
static func resolve(layout: MapLayoutScript, reach: JumpReachScript, anchor: Dictionary) -> Array[Placed]:
	var out: Array[Placed] = []
	var tail: Placed = null
	var floor_top: float = -INF
	for section: MapSectionScript in layout.sections:
		if section.external:
			continue
		for def: PlatformDefScript in section.platforms:
			if def.kind == "stairs":
				_expand_stairs(out, def, section.id, reach, floor_top)
				continue
			var p: Placed = Placed.new()
			p.def = def
			p.section_id = section.id
			p.index = out.size()
			p.chain = def.chain
			p.prev = find(out, def.host) if def.host != "" else tail
			match def.kind:
				"existing":
					p.left = float(anchor.get("left", 0.0))
					p.right = float(anchor.get("right", 0.0))
					p.top = float(anchor.get("top", 0.0))
					p.thickness = float(anchor.get("thickness", 0.0))
				"floor":
					_place_floor(p, out, reach)
					floor_top = p.top
				_:
					_place_relative(p, reach, anchor, floor_top)
			out.append(p)
			if p.chain and def.kind != "floor":
				tail = p
	return out


static func _place_relative(p: Placed, reach: JumpReachScript, anchor: Dictionary, floor_top: float) -> void:
	var def: PlatformDefScript = p.def
	var host: Placed = p.prev
	var base_left: float = host.right if host != null else float(anchor.get("right", 0.0))
	var base_top: float = host.top if host != null else float(anchor.get("top", 0.0))
	var length: float = def.length_cm * reach.m_per_cm
	p.rise_m = def.rise_cm * reach.m_per_cm if def.rise_basis == "cm" else def.rise_fraction * reach.rise_reference(def.rise_basis)
	p.top = base_top + p.rise_m
	match def.anchor:
		"at":
			p.left = (host.left if host != null else base_left) + def.along_cm * reach.m_per_cm
			p.gap_m = 0.0
		"at_end":
			p.left = (host.right if host != null else base_left) - def.along_cm * reach.m_per_cm - length
			p.gap_m = 0.0
		_:
			p.gap_m = def.gap_fraction * reach.jump_distance
			p.left = base_left + p.gap_m
	p.right = p.left + length
	p.thickness = def.thickness_cm * reach.m_per_cm
	match def.kind:
		"ledge":
			if host != null and p.rise_m > 0.0:
				# A solid block: its wall reaches down to the bottom of the platform before it.
				p.thickness = maxf(p.thickness, p.rise_m + host.thickness)
		"prop":
			p.thickness = maxf(p.rise_m, p.thickness)
		"block":
			if floor_top > -INF:
				p.thickness = p.top - floor_top


static func _place_floor(p: Placed, out: Array[Placed], reach: JumpReachScript) -> void:
	var def: PlatformDefScript = p.def
	if def.span_from == "":
		_place_room_floor(p, out, reach)
		return
	var from_p: Placed = find(out, def.span_from)
	var to_p: Placed = find(out, def.span_to)
	var drop_p: Placed = find(out, def.drop_from)
	if from_p == null or to_p == null or drop_p == null:
		push_warning("floor '%s': span_from / span_to / drop_from must be platforms placed before it" % def.id)
		return
	p.left = from_p.left - def.span_margin_cm * reach.m_per_cm
	p.right = to_p.right + (def.span_margin_cm + def.span_extra_right_cm) * reach.m_per_cm
	p.top = drop_p.top - def.drop_cm * reach.m_per_cm
	p.thickness = def.thickness_cm * reach.m_per_cm
	p.chain = false
	p.prev = null


## A floor of its own room, off to the right of its host floor (see PlatformDef.after_gap_cm).
static func _place_room_floor(p: Placed, out: Array[Placed], reach: JumpReachScript) -> void:
	var def: PlatformDefScript = p.def
	var host: Placed = find(out, def.host)
	if host == null:
		push_warning("floor '%s': without span_from it needs a host floor placed before it" % def.id)
		return
	p.left = host.right + def.after_gap_cm * reach.m_per_cm
	p.right = p.left + def.length_cm * reach.m_per_cm
	p.top = host.top
	p.thickness = def.thickness_cm * reach.m_per_cm
	p.chain = false
	p.prev = null


## True for a floor lane of a room: no table over it and a wall door on it. It is entered and left by
## the door, so it needs no way up to a table.
static func is_door_room(lane: Placed, placed: Array[Placed], layout: MapLayoutScript) -> bool:
	if layout == null:
		return false
	for p: Placed in placed:
		if p.def.kind == "table" and p.right > lane.left and p.left < lane.right:
			return false
	for section: MapSectionScript in layout.sections:
		for fixture: Resource in section.fixtures:
			if fixture.kind == "wall_door" and fixture.platform_id == lane.def.id:
				return true
	return false


## The staircase of a "stairs" def: blocks next to the host table, from just under its top down to
## just over the floor. Each block is a Placed with a generated def "<id>_<n>" (kind "block").
static func _expand_stairs(out: Array[Placed], def: PlatformDefScript, section_id: String, reach: JumpReachScript, floor_top: float) -> void:
	var host: Placed = find(out, def.host)
	if host == null or floor_top == -INF or def.steps < 2:
		push_warning("stairs '%s': needs a host placed before it, a floor before it and at least 2 steps" % def.id)
		return
	var width: float = def.length_cm * reach.m_per_cm
	var top_first: float = host.top - def.top_drop_cm * reach.m_per_cm
	var top_last: float = floor_top + def.bottom_rise_cm * reach.m_per_cm
	var previous: Placed = host
	for j: int in def.steps:
		var step_def: PlatformDefScript = PlatformDefScript.new()
		step_def.id = "%s_%d" % [def.id, j + 1]
		step_def.kind = "block"
		step_def.length_cm = def.length_cm
		step_def.chain = false
		step_def.main_path = false
		step_def.color = def.color
		var p: Placed = Placed.new()
		p.def = step_def
		p.section_id = section_id
		p.index = out.size()
		p.chain = false
		p.prev = previous
		p.top = lerpf(top_first, top_last, float(j) / float(def.steps - 1))
		p.thickness = def.thickness_cm * reach.m_per_cm # a seat, not a wall: the floor lane runs under it
		if def.side == "left":
			p.right = host.left - def.along_cm * reach.m_per_cm - float(j) * width
			p.left = p.right - width
		else:
			p.left = host.right + def.along_cm * reach.m_per_cm + float(j) * width
			p.right = p.left + width
		p.rise_m = p.top - previous.top
		out.append(p)
		previous = p


static func find(placed: Array[Placed], platform_id: String) -> Placed:
	for p: Placed in placed:
		if p.def.id == platform_id:
			return p
	return null


## Metres along a platform (negative: from its right end) as an x in the world.
static func x_on(p: Placed, along_m: float) -> float:
	return p.left + along_m if along_m >= 0.0 else p.right + along_m


## The x of anything placed with platform_id / along_m / from_id (a fixture, a marker, a spawn
## or a spawn candidate). Without from_id: along its platform. With it: along_m metres from the right end
## of that platform, or from the middle of that fixture (which needs `layout`). NAN when what it names is
## not there.
static func item_x(placed: Array[Placed], item: Resource, layout: MapLayoutScript = null) -> float:
	var from_id: String = item.from_id
	if from_id == "":
		var own: Placed = find(placed, item.platform_id)
		return x_on(own, item.along_m) if own != null else NAN
	var anchor: Placed = find(placed, from_id)
	if anchor != null:
		return anchor.right + item.along_m
	var fixture: Resource = layout.find_fixture(from_id) if layout != null else null
	if fixture == null or fixture == item or fixture.from_id == fixture.id:
		return NAN
	return item_x(placed, fixture, layout) + item.along_m


## ... and as a position: on its platform's top, `lift_m` above it.
static func item_position(placed: Array[Placed], item: Resource, layout: MapLayoutScript = null, lift_m: float = 0.0) -> Vector3:
	var p: Placed = find(placed, item.platform_id)
	var x: float = item_x(placed, item, layout)
	if p == null or is_nan(x):
		return Vector3.ZERO
	return Vector3(x, p.top + lift_m, 0.0)


## Where a 찜기 stands: on its platform's top (plus its lift).
static func jjigi_position(placed: Array[Placed], placement: Resource) -> Vector3:
	var p: Placed = find(placed, placement.platform_id)
	if p == null:
		return Vector3.ZERO
	return Vector3(x_on(p, placement.along_m), p.top + placement.lift_m, 0.0)


## Where something placed on a platform by id stands: x along it, `lift_m` above its top.
static func place_on(placed: Array[Placed], platform_id: String, along_m: float, lift_m: float = 0.0) -> Vector3:
	var p: Placed = find(placed, platform_id)
	if p == null:
		return Vector3.ZERO
	return Vector3(x_on(p, along_m), p.top + lift_m, 0.0)


static func checkpoint_position(placed: Array[Placed], checkpoint: CheckpointDefScript) -> Vector3:
	var p: Placed = find(placed, checkpoint.platform_id)
	if p == null:
		return Vector3.ZERO
	return Vector3(x_on(p, checkpoint.along_m), p.top + checkpoint.lift_m, 0.0)


## The feet position of a spawn (the enemy's origin is at its feet).
static func spawn_position(placed: Array[Placed], entry: SpawnEntryScript) -> Vector3:
	var p: Placed = find(placed, entry.platform_id)
	if p == null:
		return Vector3.ZERO
	return Vector3(item_x(placed, entry), p.top + 0.02, 0.0)


## The world rectangle of a trigger: position = (left x, bottom y).
static func trigger_rect(placed: Array[Placed], trigger: PromptTriggerScript) -> Rect2:
	var p: Placed = find(placed, trigger.platform_id)
	if p == null:
		return Rect2()
	return Rect2(p.left + trigger.rect.position.x, p.top + trigger.rect.position.y,
		trigger.rect.size.x, trigger.rect.size.y)


## The lowest top among the tables and ledges of the way through (the floor lane and the chair steps
## do not count): falling this far below it puts him back at the checkpoint, where no floor catches him.
static func lowest_top(placed: Array[Placed]) -> float:
	var low: float = INF
	for p: Placed in placed:
		if not p.is_lane():
			low = minf(low, p.top)
	return low


## The floor lane under x (null where there is none).
static func floor_at(placed: Array[Placed], x: float) -> Placed:
	for p: Placed in placed:
		if p.def.kind == "floor" and x >= p.left - EPS and x <= p.right + EPS:
			return p
	return null


## Where a fall is caught at x: below the floor lane where there is one (he lands on it first, no
## damage), else below the lowest table (put back at the checkpoint).
static func catch_y_at(placed: Array[Placed], x: float, depth: float) -> float:
	var lane: Placed = floor_at(placed, x)
	if lane != null:
		return lane.top - depth
	return lowest_top(placed) - depth


## The longest hop (horizontal gap) from `a` to `b` at the safety margin; false when `b` is out of reach.
static func can_hop(a: Placed, b: Placed, reach: JumpReachScript) -> bool:
	var gap: float = maxf(0.0, maxf(b.left - a.right, a.left - b.right))
	var rise: float = b.top - a.top
	if rise > reach.max_rise("jump") + EPS:
		return false
	if rise > 0.0:
		return gap <= JumpReachScript.SAFETY * reach.distance_for_rise(rise) + EPS
	return gap <= reach.max_gap() + EPS


## Problems with the map, one readable line each (empty = fine).
## Way through: every step is checked at JumpReach.SAFETY of what he can do: a gap against his
## longest jump, a ledge against his jump height, and for a step he cannot jump (a 단무지 bounce or a
## knocked-over 단무지) against that help instead. Such a step must also really need that help.
## Napkin boxes and windowsills are checked wherever they are (on the way or not): a box is a climb,
## a sill is a hop from its box, and that hop is the only way up there. A sill on the way is a
## required hop: the tables on both sides are too far apart to jump.
## Floor lane: a chair step must not touch a table or leave no headroom, every step of the way back
## up is a real hop, a table can be reached from the floor, and every point of the floor is within
## `climb_spacing_max_m` of a way up.
static func validate(placed: Array[Placed], reach: JumpReachScript, layout: MapLayoutScript = null) -> Array[String]:
	var problems: Array[String] = []
	for p: Placed in placed:
		var kind: String = p.def.kind
		if p.prev == null or kind == "existing" or kind == "floor" or kind == "block":
			continue
		if not (p.def.main_path or kind == "prop" or kind == "sill"):
			continue
		_validate_step(p, reach, problems)
	_validate_sills(placed, reach, problems)
	_validate_lane(placed, reach, layout, problems)
	return problems


static func _label(p: Placed) -> String:
	return "step %d '%s' (section %s)" % [p.index, p.def.id, p.section_id]


static func _validate_step(p: Placed, reach: JumpReachScript, problems: Array[String]) -> void:
	var label: String = _label(p)
	var basis: String = "jump" if p.def.rise_basis == "cm" else p.def.rise_basis
	if p.gap_m > reach.max_gap() + 0.0001:
		problems.append("%s: gap %.2f m is more than %.2f m (%.0f%% of the longest jump, %.2f m)" % [
			label, p.gap_m, reach.max_gap(), JumpReachScript.SAFETY * 100.0, reach.jump_distance])
	if p.rise_m > reach.max_rise(basis) + 0.0001:
		problems.append("%s: ledge %.2f m is more than %.2f m (%.0f%% of the %s reach, %.2f m)" % [
			label, p.rise_m, reach.max_rise(basis), JumpReachScript.SAFETY * 100.0, basis, reach.rise_reference(basis)])
	if basis == "jump" and p.rise_m > 0.0 \
			and p.gap_m > JumpReachScript.SAFETY * reach.distance_for_rise(p.rise_m) + 0.0001:
		problems.append("%s: gap %.2f m is too wide for a jump up %.2f m (only %.2f m)" % [
			label, p.gap_m, p.rise_m, JumpReachScript.SAFETY * reach.distance_for_rise(p.rise_m)])
	if basis != "jump" and p.rise_m > 0.0 and p.rise_m <= reach.jump_height:
		problems.append("%s: a %s step of %.2f m can be jumped without the help (jump height %.2f m)" % [
			label, basis, p.rise_m, reach.jump_height])
	if basis != "jump" and p.rise_m > 0.0 and p.gap_m > 0.0001:
		problems.append("%s: a %s step must be a wall (gap 0), not %.2f m" % [label, basis, p.gap_m])
	if p.def.anchor != "after" and p.prev != null:
		if p.left < p.prev.left - EPS or p.right > p.prev.right + EPS:
			problems.append("%s: does not fit on '%s' (%.2f..%.2f m is outside %.2f..%.2f m)" % [
				label, p.prev.def.id, p.left, p.right, p.prev.left, p.prev.right])


static func _validate_sills(placed: Array[Placed], reach: JumpReachScript, problems: Array[String]) -> void:
	for p: Placed in placed:
		if p.def.kind != "sill":
			continue
		var label: String = _label(p)
		var box: Placed = p.prev
		if box == null or box.def.kind != "prop":
			problems.append("%s: a windowsill is reached from a napkin box (host must be a prop)" % label)
			continue
		var table: Placed = box.prev
		if table != null and p.top - table.top <= reach.jump_height:
			problems.append("%s: only %.2f m above the table '%s': he could jump up without the box (jump height %.2f m)" % [
				label, p.top - table.top, table.def.id, reach.jump_height])
		if not can_hop(box, p, reach):
			problems.append("%s: the hop from the box '%s' is too far" % [label, box.def.id])
		if p.def.main_path and table != null:
			for after: Placed in placed:
				if after.prev == p and after.def.main_path:
					var direct: float = after.left - table.right
					if direct <= reach.jump_distance:
						problems.append("%s: not a required hop: '%s' is only %.2f m from '%s' (longest jump %.2f m)" % [
							label, after.def.id, direct, table.def.id, reach.jump_distance])


static func _validate_lane(placed: Array[Placed], reach: JumpReachScript, layout: MapLayoutScript, problems: Array[String]) -> void:
	for lane: Placed in placed:
		if lane.def.kind == "floor":
			_validate_one_lane(lane, placed, reach, layout, problems)


static func _validate_one_lane(lane: Placed, placed: Array[Placed], reach: JumpReachScript, layout: MapLayoutScript, problems: Array[String]) -> void:
	var headroom: float = layout.headroom_m if layout != null else DEFAULT_HEADROOM_M
	var spacing: float = layout.climb_spacing_max_m if layout != null else DEFAULT_CLIMB_SPACING_M
	# Tables above the lane must be over it.
	for p: Placed in placed:
		if p.def.kind == "table" and p.section_id == lane.section_id:
			if p.left < lane.left - EPS or p.right > lane.right + EPS:
				problems.append("%s: a table that is not over the floor lane (%.2f..%.2f m, the lane is %.2f..%.2f m)" % [
					_label(p), p.left, p.right, lane.left, lane.right])
	# Chair steps: not inside anything, room to stand, and each hop real.
	for b: Placed in placed:
		if b.def.kind != "block":
			continue
		var label: String = _label(b)
		if b.top - b.thickness - lane.top < headroom:
			problems.append("%s: only %.2f m between this step and the floor lane (needs %.2f m): the lane is blocked" % [label, b.top - b.thickness - lane.top, headroom])
		if b.prev != null and not can_hop(b, b.prev, reach) and not can_hop(b.prev, b, reach):
			problems.append("%s: no hop between this step and '%s'" % [label, b.prev.def.id])
		for other: Placed in placed:
			if other == b or other.def.kind == "floor" or other.def.kind == "block":
				continue
			if other.right <= b.left + EPS or other.left >= b.right - EPS:
				continue
			var underside: float = other.top - other.thickness
			if b.top > underside - EPS:
				# The step reaches up into the other (a block is solid down to the floor).
				problems.append("%s: the step runs into '%s'" % [label, other.def.id])
			elif underside - b.top < headroom:
				problems.append("%s: only %.2f m under '%s' (needs %.2f m)" % [label, underside - b.top, other.def.id, headroom])
	if is_door_room(lane, placed, layout):
		return
	# The way back up: BFS over hops from the floor to a table.
	var reached: Array[Placed] = [lane]
	var queue: Array[Placed] = [lane]
	var from_floor: Array[Placed] = []
	while not queue.is_empty():
		var a: Placed = queue.pop_front()
		for b: Placed in placed:
			if reached.has(b) or b.def.kind == "floor":
				continue # another floor lane is not a way up
			if can_hop(a, b, reach):
				reached.append(b)
				queue.append(b)
				if a == lane:
					from_floor.append(b)
	var table_reached: bool = false
	for p: Placed in reached:
		if p.def.kind == "table":
			table_reached = true
	if not table_reached:
		problems.append("floor lane '%s': no way back up to a table (nothing reachable from the floor leads to one)" % lane.def.id)
		return
	# Entry points: what he can hop to from the floor and from which a table is reachable without the floor.
	var entries: Array[Placed] = []
	for e: Placed in from_floor:
		if _reaches_table(e, placed, reach, lane):
			entries.append(e)
	var x: float = lane.left
	while x <= lane.right + EPS:
		var nearest: float = INF
		for e: Placed in entries:
			var d: float = 0.0 if x >= e.left and x <= e.right else minf(absf(x - e.left), absf(x - e.right))
			nearest = minf(nearest, d)
		if nearest > spacing + EPS:
			problems.append("floor lane '%s': at x=%.1f m the nearest way back up is %.1f m away (at most %.1f m)" % [
				lane.def.id, x, nearest, spacing])
			break
		x += FLOOR_SAMPLE_M


static func _reaches_table(start: Placed, placed: Array[Placed], reach: JumpReachScript, lane: Placed) -> bool:
	var seen: Array[Placed] = [start, lane]
	var queue: Array[Placed] = [start]
	while not queue.is_empty():
		var a: Placed = queue.pop_front()
		if a.def.kind == "table":
			return true
		for b: Placed in placed:
			if seen.has(b):
				continue
			if can_hop(a, b, reach):
				seen.append(b)
				queue.append(b)
	return false
