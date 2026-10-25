class_name Progression
extends Node
## Nivel y experiencia. Se agrega como nodo hijo llamado "Progression".
## La experiencia necesaria para el próximo nivel crece con cada nivel.

signal experience_changed(current: int, needed: int)
signal leveled_up(level: int)

@export var level: int = 1
@export var max_level: int = 50
## Experiencia para pasar de nivel 1 a 2.
@export var base_experience: int = 100
## Cuánto crece la experiencia necesaria por nivel (1.0 = siempre igual).
@export var growth: float = 1.35

var experience: int = 0


static func of(node: Node) -> Progression:
	if node == null:
		return null
	return node.get_node_or_null("Progression") as Progression


func experience_to_next() -> int:
	return int(round(base_experience * pow(growth, level - 1)))


func is_max_level() -> bool:
	return level >= max_level


func add_experience(amount: int) -> void:
	if amount <= 0 or is_max_level():
		return
	experience += amount
	while not is_max_level() and experience >= experience_to_next():
		experience -= experience_to_next()
		level += 1
		leveled_up.emit(level)
	if is_max_level():
		experience = 0
	experience_changed.emit(experience, experience_to_next())
