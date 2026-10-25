class_name Mana
extends Node
## Maná reutilizable (jugador, más adelante NPCs magos). Se agrega como nodo hijo
## llamado "Mana". Se regenera solo con el tiempo.

signal changed(current: int, max_mana: int)

@export var max_mana: int = 100
## Maná recuperado por segundo.
@export var regen_per_second: float = 4.0

var current: int

var _regen_progress: float = 0.0


static func of(node: Node) -> Mana:
	if node == null:
		return null
	return node.get_node_or_null("Mana") as Mana


func _ready() -> void:
	current = max_mana


func _physics_process(delta: float) -> void:
	if current >= max_mana or regen_per_second <= 0.0:
		_regen_progress = 0.0
		return
	_regen_progress += regen_per_second * delta
	if _regen_progress >= 1.0:
		var amount := int(_regen_progress)
		_regen_progress -= amount
		_set_current(current + amount)


func has(amount: int) -> bool:
	return current >= amount


## Gasta `amount` si alcanza. Devuelve false (sin gastar nada) si no alcanza.
func spend(amount: int) -> bool:
	if not has(amount):
		return false
	_set_current(current - amount)
	return true


func refill() -> void:
	_set_current(max_mana)


func _set_current(value: int) -> void:
	current = clampi(value, 0, max_mana)
	changed.emit(current, max_mana)
