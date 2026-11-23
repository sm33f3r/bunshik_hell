extends RefCounted
## The soft-lock check. Can he always get from the start of the map to every platform of the way
## through, whatever happened to the things the way depends on? It uses the same hop rules as the
## layout validation (LayoutGeometry.can_hop, from JumpReach), and adds the help a 단무지 gives:
##   - a wheel standing upright on a table lets him bounce up a "bounce" step on that table (the wall
##     of the ledge next to it), and lets him knock it flat and climb a "platform" step;
##   - a wheel lying flat on a table, inside the stretch of the table the data calls useful, lets him
##     climb a "platform" step on that table.
## Every spawn entry of a 단무지 is then wasted in turn (killed, knocked flat toward either end, fallen off
## its table). If that leaves no way on, the entry must say `required_for_progress`, and then the way
## must be back after its respawn_delay_s. Nothing here is a typed-in number: it all comes from the layout
## data, the movement tuning and the 단무지's EnemyDef.

const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")

## A spawn entry of this scene file is a 단무지 wheel.
const WHEEL_SCENE_FILE: String = "danmuji.tscn"

## The ways a wheel is wasted.
const KILLED: String = "killed"
const FLAT_LEFT: String = "knocked flat toward the left end of its table"
const FLAT_RIGHT: String = "knocked flat toward the right end of its table"
const FELL_OFF: String = "fallen off its table"
const MODES: Array[String] = [KILLED, FLAT_LEFT, FLAT_RIGHT, FELL_OFF]

## What a wheel is, as far as the way on is concerned.
const UPRIGHT: String = "upright"
const FLAT_USEFUL: String = "flat (in its useful stretch)"
const GONE: String = "gone"


static func is_wheel(entry: SpawnEntryScript) -> bool:
	return entry.scene != null and entry.scene.resource_path.get_file() == WHEEL_SCENE_FILE


## Every 단무지 spawn entry of the map, section by section.
static func wheel_entries(layout: MapLayoutScript) -> Array[SpawnEntryScript]:
	var out: Array[SpawnEntryScript] = []
	for section: MapSectionScript in layout.sections:
		for entry: SpawnEntryScript in section.spawns:
			if is_wheel(entry):
				out.append(entry)
	return out


## Every spawn entry the data marks required_for_progress.
static func required_entries(layout: MapLayoutScript) -> Array[SpawnEntryScript]:
	var out: Array[SpawnEntryScript] = []
	for section: MapSectionScript in layout.sections:
		for entry: SpawnEntryScript in section.spawns:
			if entry.required_for_progress:
				out.append(entry)
	return out


# --- Where a flat wheel ends up ---------------------------------------------------------------------

## The x of the centre of a wheel knocked flat toward `direction` (+1 right, -1 left): it slides at most
## the EnemyDef's knock_slide_m and stops at the end of its table or at something standing on the table
## (a napkin box), keeping its own half width off it.
static func flat_end_x(placed: Array[LayoutGeometryScript.Placed], reach: JumpReachScript,
		wheel: EnemyDefScript, entry: SpawnEntryScript, direction: float) -> float:
	var p: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, entry.platform_id)
	var start: float = LayoutGeometryScript.x_on(p, entry.along_m)
	var half: float = reach.wheel_diameter * 0.5
	var left_limit: float = p.left
	var right_limit: float = p.right
	for q: LayoutGeometryScript.Placed in placed:
		if q.def.kind == "prop" and q.def.host == p.def.id:
			if q.left >= start:
				right_limit = minf(right_limit, q.left)
			elif q.right <= start:
				left_limit = maxf(left_limit, q.right)
	if direction > 0.0:
		return minf(start + wheel.knock_slide_m, right_limit - half)
	return maxf(start - wheel.knock_slide_m, left_limit + half)


## True when a wheel lying flat at x on its table is where the data says it is any use.
static func flat_is_useful_at(placed: Array[LayoutGeometryScript.Placed], entry: SpawnEntryScript, x: float) -> bool:
	if entry.useful_from_m == entry.useful_to_m:
		return true
	var p: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, entry.platform_id)
	var a: float = LayoutGeometryScript.x_on(p, entry.useful_from_m)
	var b: float = LayoutGeometryScript.x_on(p, entry.useful_to_m)
	return x >= minf(a, b) and x <= maxf(a, b)


## What is left of a wasted wheel the instant it is wasted (before any respawn).
static func state_after(placed: Array[LayoutGeometryScript.Placed], reach: JumpReachScript, wheel: EnemyDefScript,
		entry: SpawnEntryScript, mode: String) -> String:
	if mode == FLAT_LEFT or mode == FLAT_RIGHT:
		var x: float = flat_end_x(placed, reach, wheel, entry, 1.0 if mode == FLAT_RIGHT else -1.0)
		return FLAT_USEFUL if flat_is_useful_at(placed, entry, x) else GONE
	return GONE


## What a wasted wheel is once its respawn delay is over. A required entry is put back upright, unless it
## lies flat where it is useful and the entry says a flat wheel there is fine (usable_when_flat).
static func state_after_respawn(entry: SpawnEntryScript, wasted: String) -> String:
	if not entry.required_for_progress:
		return wasted
	if wasted == FLAT_USEFUL and entry.usable_when_flat:
		return FLAT_USEFUL
	return UPRIGHT


# --- The graph --------------------------------------------------------------------------------------

## `states`: entry -> UPRIGHT / FLAT_USEFUL / GONE. Entries not in it are upright.
static func _helps(layout: MapLayoutScript, states: Dictionary) -> Dictionary:
	var upright: Array[String] = []
	var flat: Array[String] = []
	for entry: SpawnEntryScript in wheel_entries(layout):
		var state: String = String(states.get(entry, UPRIGHT))
		if state == UPRIGHT:
			upright.append(entry.platform_id)
		elif state == FLAT_USEFUL:
			flat.append(entry.platform_id)
	return {"upright": upright, "flat": flat}


## Can he get from `a` to `b` in one step: a plain hop, or a step up a wall that a wheel on `a` helps with.
static func can_step(a: LayoutGeometryScript.Placed, b: LayoutGeometryScript.Placed, reach: JumpReachScript, helps: Dictionary) -> bool:
	if LayoutGeometryScript.can_hop(a, b, reach):
		return true
	var rise: float = b.top - a.top
	var gap: float = maxf(0.0, maxf(b.left - a.right, a.left - b.right))
	if rise <= 0.0 or gap > LayoutGeometryScript.EPS:
		return false # only a wall can be helped
	var upright: Array = helps["upright"]
	var flat: Array = helps["flat"]
	match b.def.rise_basis:
		"bounce":
			return upright.has(a.def.id) and rise <= reach.max_rise("bounce") + LayoutGeometryScript.EPS
		"platform":
			# A flat wheel is a step; an upright one can be knocked flat (the roll is his by then).
			return (flat.has(a.def.id) or upright.has(a.def.id)) and rise <= reach.max_rise("platform") + LayoutGeometryScript.EPS
	return false


## The platforms of the way through that cannot be reached from `start_id` (default: the map's first
## platform). Empty = all reachable. `only_sections` limits which sections' platforms have to be
## reachable (default: all). The floor lane and the chair steps do not count: falling to them is no
## progress.
static func unreachable(layout: MapLayoutScript, placed: Array[LayoutGeometryScript.Placed], reach: JumpReachScript,
		states: Dictionary, start_id: String = "", only_sections: Array[String] = []) -> Array[String]:
	var helps: Dictionary = _helps(layout, states)
	var nodes: Array[LayoutGeometryScript.Placed] = []
	for p: LayoutGeometryScript.Placed in placed:
		if not p.is_lane():
			nodes.append(p)
	var out: Array[String] = []
	if nodes.is_empty():
		return out
	var first: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, start_id) if start_id != "" else nodes[0]
	if first == null:
		return ["(no platform '%s')" % start_id]
	var seen: Array[LayoutGeometryScript.Placed] = [first]
	var queue: Array[LayoutGeometryScript.Placed] = [first]
	while not queue.is_empty():
		var a: LayoutGeometryScript.Placed = queue.pop_front()
		for b: LayoutGeometryScript.Placed in nodes:
			if not seen.has(b) and can_step(a, b, reach, helps):
				seen.append(b)
				queue.append(b)
	for p: LayoutGeometryScript.Placed in nodes:
		if not (p.chain and p.def.main_path) or seen.has(p):
			continue
		if only_sections.is_empty() or only_sections.has(p.section_id):
			out.append(p.def.id)
	return out


# --- The check ---------------------------------------------------------------------------------------

## One readable line per soft-lock (empty = none): for every 단무지 entry and every way of wasting it, the
## way on must still exist, or the entry must be required_for_progress and the way must be back after its
## respawn_delay_s. A required entry must also have a delay.
static func problems(layout: MapLayoutScript, placed: Array[LayoutGeometryScript.Placed], reach: JumpReachScript,
		wheel: EnemyDefScript) -> Array[String]:
	var out: Array[String] = []
	var blocked: Array[String] = unreachable(layout, placed, reach, {})
	if not blocked.is_empty():
		out.append("even with every wheel in place the way on is cut: %s" % ", ".join(blocked))
	for entry: SpawnEntryScript in required_entries(layout):
		if entry.respawn_delay_s <= 0.0:
			out.append("%s on '%s': required_for_progress needs a respawn_delay_s above 0" % [_name(entry), entry.platform_id])
	for entry: SpawnEntryScript in wheel_entries(layout):
		for mode: String in MODES:
			var wasted: String = state_after(placed, reach, wheel, entry, mode)
			var now: Array[String] = unreachable(layout, placed, reach, {entry: wasted})
			if now.is_empty():
				continue
			var label: String = "%s on '%s' %s" % [_name(entry), entry.platform_id, mode]
			if not entry.required_for_progress:
				out.append("%s: no way on to %s, and it is not required_for_progress (it would never come back)" % [label, ", ".join(now)])
				continue
			var later: Array[String] = unreachable(layout, placed, reach, {entry: state_after_respawn(entry, wasted)})
			if not later.is_empty():
				out.append("%s: still no way on to %s after its respawn of %.1f s" % [label, ", ".join(later), entry.respawn_delay_s])
	return out


static func _name(entry: SpawnEntryScript) -> String:
	return "wheel '%s'" % entry.group if entry.group != "" else "wheel"
