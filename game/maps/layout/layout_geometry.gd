extends RefCounted
## Turns a MapLayout into places: where every platform stands, worked out from the one before it
## and from what the 떡 can do (JumpReach). Also checks that the main path can be walked.

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const CheckpointDefScript := preload("res://maps/layout/checkpoint_def.gd")
const PromptTriggerScript := preload("res://maps/layout/prompt_trigger.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")


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
	## Empty space before it and how much higher it is than the one before (0 for the first).
	var gap_m: float = 0.0
	var rise_m: float = 0.0
	var prev: Placed = null

	func length() -> float:
		return right - left

	func center_x() -> float:
		return (left + right) * 0.5


## `anchor` places the "existing" platform: {"left", "right", "top", "thickness"} in metres.
static func resolve(layout: MapLayoutScript, reach: JumpReachScript, anchor: Dictionary) -> Array[Placed]:
	var out: Array[Placed] = []
	var prev: Placed = null
	for section: MapSectionScript in layout.sections:
		if section.external:
			continue
		for def: PlatformDefScript in section.platforms:
			var p: Placed = Placed.new()
			p.def = def
			p.section_id = section.id
			p.index = out.size()
			p.prev = prev
			if def.kind == "existing":
				p.left = float(anchor.get("left", 0.0))
				p.right = float(anchor.get("right", 0.0))
				p.top = float(anchor.get("top", 0.0))
				p.thickness = float(anchor.get("thickness", 0.0))
			else:
				var base_left: float = prev.right if prev != null else float(anchor.get("right", 0.0))
				var base_top: float = prev.top if prev != null else float(anchor.get("top", 0.0))
				p.gap_m = def.gap_fraction * reach.jump_distance
				p.rise_m = def.rise_fraction * reach.rise_reference(def.rise_basis)
				p.left = base_left + p.gap_m
				p.right = p.left + def.length_cm * reach.m_per_cm
				p.top = base_top + p.rise_m
				p.thickness = def.thickness_cm * reach.m_per_cm
				if def.kind == "ledge" and prev != null and p.rise_m > 0.0:
					# A solid block: its wall reaches down to the bottom of the platform before it.
					p.thickness = maxf(p.thickness, p.rise_m + prev.thickness)
			out.append(p)
			prev = p
	return out


static func find(placed: Array[Placed], platform_id: String) -> Placed:
	for p: Placed in placed:
		if p.def.id == platform_id:
			return p
	return null


## Metres along a platform (negative: from its right end) as an x in the world.
static func x_on(p: Placed, along_m: float) -> float:
	return p.left + along_m if along_m >= 0.0 else p.right + along_m


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
	return Vector3(x_on(p, entry.along_m), p.top + 0.02, 0.0)


## The world rectangle of a trigger: position = (left x, bottom y).
static func trigger_rect(placed: Array[Placed], trigger: PromptTriggerScript) -> Rect2:
	var p: Placed = find(placed, trigger.platform_id)
	if p == null:
		return Rect2()
	return Rect2(p.left + trigger.rect.position.x, p.top + trigger.rect.position.y,
		trigger.rect.size.x, trigger.rect.size.y)


## The lowest platform top of the map; falling this far below it puts him back.
static func lowest_top(placed: Array[Placed]) -> float:
	var low: float = INF
	for p: Placed in placed:
		low = minf(low, p.top)
	return low


## Problems with the main path, one readable line each (empty = fine). Every step is checked at
## JumpReach.SAFETY of what he can do: a gap against his longest jump, a ledge against his jump
## height, and for a step he cannot jump (a 단무지 bounce or a knocked-over 단무지) against that
## help instead. Such a step must also really need that help.
static func validate(placed: Array[Placed], reach: JumpReachScript) -> Array[String]:
	var problems: Array[String] = []
	var prev: Placed = null
	for p: Placed in placed:
		if not p.def.main_path:
			continue
		if prev == null or p.def.kind == "existing":
			prev = p
			continue
		var label: String = "step %d '%s' (section %s)" % [p.index, p.def.id, p.section_id]
		if p.gap_m > reach.max_gap() + 0.0001:
			problems.append("%s: gap %.2f m is more than %.2f m (%.0f%% of the longest jump, %.2f m)" % [
				label, p.gap_m, reach.max_gap(), JumpReachScript.SAFETY * 100.0, reach.jump_distance])
		var basis: String = p.def.rise_basis
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
		prev = p
	return problems
