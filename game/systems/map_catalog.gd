extends RefCounted
## Map id -> scene lookup. A save stores the id of the map he is in; only ids listed here ever become
## a scene path, so a save from outside can never name a file.

const MAP_PATHS: Dictionary[String, String] = {
	"map01": "res://maps/ep01/map01_bunsikjip/map01.tscn",
	"test_room": "res://maps/test/test_room.tscn",
}
## What an old save without a map id means (the only real map there is).
const DEFAULT_MAP: String = "map01"


## "" for an unknown id.
static func scene_path(map_id: String) -> String:
	return MAP_PATHS.get(map_id, "")


static func is_map(map_id: String) -> bool:
	return MAP_PATHS.has(map_id)
