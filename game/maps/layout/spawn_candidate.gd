extends Resource
## One spot a thing with a "spawn choice" may stand on (see SpawnEntry.candidates): a platform of the
## layout and how far along it. The id is stable: the save remembers which spot was picked by it.

@export var id: String = ""
@export var platform_id: String = ""
## Metres from the platform's left edge. Negative: from its right edge.
@export var along_m: float = 2.0
## "" = along_m is on platform_id, the usual way. Else along_m is metres from the RIGHT end of this
## platform, or from the middle of this fixture (negative: back from it). platform_id still says what it
## stands on. See LayoutGeometry.item_x.
@export var from_id: String = ""
