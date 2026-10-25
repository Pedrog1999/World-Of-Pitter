class_name LootTable
extends Resource
## Qué suelta un monstruo al morir. Cada entrada se tira por separado; el oro aparte.
## Las tablas son .tres en data/loot/.

@export var entries: Array[LootEntry] = []
@export_range(0.0, 1.0) var gold_chance: float = 1.0
@export var gold_min: int = 0
@export var gold_max: int = 0


## Devuelve lo que salió como [[item, cantidad], ...]; el oro va con item = null.
func roll() -> Array:
	var drops: Array = []
	for entry in entries:
		if entry.item and randf() < entry.chance:
			drops.append([entry.item, randi_range(entry.min_amount, entry.max_amount)])
	if gold_max > 0 and randf() < gold_chance:
		drops.append([null, randi_range(gold_min, gold_max)])
	return drops
