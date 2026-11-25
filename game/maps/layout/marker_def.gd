extends Resource
## A named spot of the map, as data only: nothing is built for it. A later task puts something there
## (e.g. "ramen_start_1", where the first 라면 will stand).

@export var id: String = ""
@export var platform_id: String = ""
## Metres from the platform's left edge. Negative: from its right edge.
@export var along_m: float = 0.0
## "" = along_m is on platform_id, the usual way. Else along_m is metres from the RIGHT end of this
## platform, or from the middle of this fixture (negative: back from it). platform_id still says what it
## stands on. See LayoutGeometry.item_x.
@export var from_id: String = ""
