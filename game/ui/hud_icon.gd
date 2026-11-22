class_name HudIcon
extends Resource
## One HUD icon (data). Today every icon is a simple vector shape drawn by HudIconView; to use real
## art later, set `texture` on the icon's .tres and nothing in the code changes.

@export var id: String = ""
## heart, drop, crystal, coat, jar, mound, swatch (see HudIconView.shape_points()).
@export var shape: String = "swatch"
@export var color: Color = Color(1, 1, 1, 1)
@export var outline_color: Color = Color(0, 0, 0, 0.85)
## Real art. When set it is drawn instead of the shape.
@export var texture: Texture2D
## Where the icon came from (shown nowhere in the game; kept so no art of unknown origin slips in).
@export var provenance: String = "agent-drawn placeholder"
