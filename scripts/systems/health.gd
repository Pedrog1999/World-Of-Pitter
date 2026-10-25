class_name Health
extends Node
## Vida reutilizable para cualquier entidad (jugador, esbirros, enemigos, muñecos).
## Se agrega como nodo hijo llamado "Health".

signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 50

var current: int

var is_dead: bool:
	get:
		return current <= 0


static func of(node: Node) -> Health:
	if node == null:
		return null
	return node.get_node_or_null("Health") as Health


func _ready() -> void:
	current = max_health


func take_damage(amount: int, source: Node = null) -> void:
	if is_dead:
		return
	current = maxi(current - amount, 0)
	damaged.emit(amount, source)
	if current == 0:
		died.emit()


func reset() -> void:
	var missing := max_health - current
	current = max_health
	healed.emit(missing)
