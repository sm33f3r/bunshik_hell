class_name DropEntry
extends Resource
## One line of an enemy's drop table: what it may leave behind, how much, and how likely.

const KIND_NATRIUM: String = "natrium"
const KIND_SAUCE_DRIP: String = "sauce_drip"

## KIND_NATRIUM or KIND_SAUCE_DRIP.
@export var kind: String = KIND_NATRIUM
@export var amount: int = 1
## Chance (0..1) that this entry drops on a kill.
@export var chance: float = 0.25
