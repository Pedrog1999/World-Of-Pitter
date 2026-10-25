class_name Health
extends Node
## Vida reutilizable para cualquier entidad (jugador, esbirros, enemigos, muñecos).
## Se agrega como nodo hijo llamado "Health". Opcionalmente se regenera con el tiempo.

signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 50
## Vida recuperada por segundo (0 = no se regenera).
@export var regen_per_second: float = 0.0
## Segundos sin recibir daño antes de empezar a regenerar.
@export var regen_delay: float = 0.0

var current: int

var is_dead: bool:
	get:
		return current <= 0

var _regen_progress: float = 0.0
var _since_damage: float = 0.0


static func of(node: Node) -> Health:
	if node == null:
		return null
	return node.get_node_or_null("Health") as Health


func _ready() -> void:
	current = max_health
	set_physics_process(regen_per_second > 0.0)


func _physics_process(delta: float) -> void:
	_since_damage += delta
	if is_dead or current >= max_health or _since_damage < regen_delay:
		_regen_progress = 0.0
		return
	_regen_progress += regen_per_second * delta
	if _regen_progress >= 1.0:
		var amount := int(_regen_progress)
		_regen_progress -= amount
		heal(amount)


func take_damage(amount: int, source: Node = null) -> void:
	if is_dead:
		return
	_since_damage = 0.0
	current = maxi(current - amount, 0)
	damaged.emit(amount, source)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var healed_amount := mini(amount, max_health - current)
	if healed_amount <= 0:
		return
	current += healed_amount
	healed.emit(healed_amount)


func reset() -> void:
	var missing := max_health - current
	current = max_health
	healed.emit(missing)
