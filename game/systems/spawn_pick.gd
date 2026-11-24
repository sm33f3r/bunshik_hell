extends RefCounted
## The random part of a "spawn choice" (a thing that may stand in one of several spots, see SpawnEntry):
## a pick made from the game's seed, so the same seed always gives the same spot, and the debug options
## that force a spot. No state of its own: GameState keeps the seed and the picks (and saves them).

## A debug build can force a spot from the command line: godot --path game -- --spawn-pick=<choice>:<spot>
## (e.g. --spawn-pick=ganjang_bottle:kitchen_table). Not read in an exported release build.
const ARG_PREFIX: String = "--spawn-pick="

const FNV_OFFSET: int = 2166136261
const FNV_PRIME: int = 16777619
const MASK_32: int = 0xFFFFFFFF


## A fresh non-zero seed (0 means "no seed yet").
static func new_seed() -> int:
	return int(randi() % 2147483646) + 1


## Which of `count` spots this seed picks for this choice: deterministic, spread over the spots.
## (FNV-1a over the seed and the choice id, so it does not depend on the engine's string hash.)
static func pick_index(seed_value: int, choice_id: String, count: int) -> int:
	if count <= 1:
		return 0
	var h: int = FNV_OFFSET
	for byte: int in ("%d:%s" % [seed_value, choice_id]).to_utf8_buffer():
		h = ((h ^ byte) * FNV_PRIME) & MASK_32
	h = (h ^ (h >> 15)) & MASK_32 # the low bits of FNV are weak for tiny counts
	return h % count


## The spot a debug option forces for this choice ("" = none).
static func cmdline_override(choice_id: String) -> String:
	if not OS.is_debug_build():
		return ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(ARG_PREFIX):
			var parts: PackedStringArray = arg.trim_prefix(ARG_PREFIX).split(":", false, 1)
			if parts.size() == 2 and parts[0] == choice_id:
				return parts[1]
	return ""
