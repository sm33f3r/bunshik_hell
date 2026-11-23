extends Resource
## One kind of 찜기 (steamer), as data. A 찜기 gives ONE full heal and ONE auto-save, once; after that
## it provides nothing (no heal, no save). Where one stands, and its unique id, are the map layout's
## business (see JjigiPlacement). All visual numbers are 🟡 (gray box).

@export var id: String = ""
## The heal and the save happen only the first time it is used.
@export var heals_once: bool = true
## Using it writes the save file.
@export var saves: bool = true
## DEBUG ONLY (the test room): may be used again and again. Map 1 never sets this.
@export var debug_unlimited: bool = false
## He bumps into it (the test room's). A 찜기 on a map table is decor he walks through.
@export var solid: bool = true

@export_group("Look")
@export var body_color: Color = Color(0.55, 0.38, 0.22, 1)
@export var used_body_color: Color = Color(0.26, 0.24, 0.23, 1)
@export var lid_color: Color = Color(0.88, 0.95, 1, 1)
@export var used_lid_color: Color = Color(0.3, 0.3, 0.32, 1)
@export var idle_glow: float = 0.3
## Glow while it is the respawn point.
@export var active_glow: float = 1.6
@export var used_glow: float = 0.0
@export var feedback_time: float = 0.7
@export_group("Steam")
@export var steam_color: Color = Color(1, 1, 1, 0.55)
@export var steam_amount: int = 14
@export var steam_lifetime_s: float = 1.6
@export var steam_rise_mps: float = 0.9
@export var steam_puff_size_m: float = 0.28
## The prompt that shows when he is in the zone. Not text: a key hint glyph (kept as it was).
@export var prompt_text: String = "[W]"


## True when using it now would give its heal and save: never used, or not a once-only kind, or the
## debug flag.
func provides(already_used: bool) -> bool:
	return debug_unlimited or not heals_once or not already_used
