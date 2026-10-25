class_name Health
extends Node
## Vida reutilizable para cualquier entidad (jugador, esbirros, enemigos, muñecos).
## Se agrega como nodo hijo llamado "Health". Opcionalmente se regenera con el tiempo.
## La defensa (`armor`) resta daño a cada golpe, pero siempre entra al menos 1.

signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died
signal max_health_changed(max_health: int)

@export var max_health: int = 50
## Vida recuperada por segundo (0 = no se regenera).
@export var regen_per_second: float = 0.0
## Segundos sin recibir daño antes de empezar a regenerar.
@export var regen_delay: float = 0.0
@export var armor: int = 0

var current: int
## Quién hizo el último daño (para dar experiencia o botín a quien lo mató).
var last_source: Node

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
	amount = maxi(amount - armor, 1)
	_since_damage = 0.0
	last_source = source
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


## Cambia la vida máxima sin curar (la actual se recorta si queda por encima).
func set_max_health(value: int) -> void:
	max_health = maxi(value, 1)
	current = mini(current, max_health)
	max_health_changed.emit(max_health)


func reset() -> void:
	var missing := max_health - current
	current = max_health
	healed.emit(missing)
