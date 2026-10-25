class_name LootEntry
extends Resource
## Una línea de una tabla de botín: qué item puede caer, con qué probabilidad y cuántos.

@export var item: ItemData
@export_range(0.0, 1.0) var chance: float = 0.5
@export var min_amount: int = 1
@export var max_amount: int = 1
