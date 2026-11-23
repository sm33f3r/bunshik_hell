extends RefCounted
## Id -> HudIcon lookup. Only ids listed here are loaded (an item id from a save never becomes a
## file path). An unknown item id gets the generic icon, tinted with the item's own colour.

const HudIconScript := preload("res://ui/hud_icon.gd")
const ItemCatalogScript := preload("res://systems/item_catalog.gd")

const ICON_PATHS: Dictionary[String, String] = {
	"heart": "res://data/hud/icons/heart.tres",
	"sauce_drop": "res://data/hud/icons/sauce_drop.tres",
	"salt_crystal": "res://data/hud/icons/salt_crystal.tres",
	"coat": "res://data/hud/icons/coat.tres",
	"sauce_type": "res://data/hud/icons/sauce_type.tres",
	"save_disk": "res://data/hud/icons/save_disk.tres",
	"kongomul": "res://data/hud/icons/kongomul.tres",
	"jocheong": "res://data/hud/icons/jocheong.tres",
	"ggul": "res://data/hud/icons/ggul.tres",
	"item_generic": "res://data/hud/icons/item_generic.tres",
}


## Null for an id without an icon.
static func icon(id: String) -> HudIconScript:
	if not ICON_PATHS.has(id):
		return null
	return load(ICON_PATHS[id]) as HudIconScript


## The icon of a carried item: its own, else the generic one.
static func item_icon(item_id: String) -> HudIconScript:
	var own: HudIconScript = icon(item_id) if ItemCatalogScript.is_health_item(item_id) else null
	return own if own != null else icon("item_generic")
