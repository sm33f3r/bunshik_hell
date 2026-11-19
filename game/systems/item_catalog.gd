extends RefCounted
## Id -> definition lookup for health items and containers. Only ids listed here are ever
## loaded, so an id that arrives from a save (JSON) can never become a file path.

const HealthItemDefScript := preload("res://items/health_item_def.gd")
const ContainerDefScript := preload("res://items/container_def.gd")

const HEALTH_ITEM_PATHS: Dictionary[String, String] = {
	"kongomul": "res://data/items/kongomul.tres",
	"jocheong": "res://data/items/jocheong.tres",
	"ggul": "res://data/items/ggul.tres",
}
const CONTAINER_PATHS: Dictionary[String, String] = {
	"starter_container": "res://data/containers/starter_container.tres",
}


## Null for an unknown id.
static func health_item(id: String) -> HealthItemDefScript:
	if not HEALTH_ITEM_PATHS.has(id):
		return null
	return load(HEALTH_ITEM_PATHS[id]) as HealthItemDefScript


## Null for an unknown id.
static func container(id: String) -> ContainerDefScript:
	if not CONTAINER_PATHS.has(id):
		return null
	return load(CONTAINER_PATHS[id]) as ContainerDefScript


static func is_health_item(id: String) -> bool:
	return HEALTH_ITEM_PATHS.has(id)


static func is_container(id: String) -> bool:
	return CONTAINER_PATHS.has(id)
