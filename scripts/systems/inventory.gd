class_name Inventory
extends Node
## Casilleros de items del portador. Cada casillero tiene un item y una cantidad
## (los items apilables comparten casillero hasta `max_stack`).

signal changed

@export var size: int = 20
## Items con los que se empieza (repetir un item = más cantidad).
@export var starting_items: Array[ItemData] = []

var _items: Array[ItemData] = []
var _amounts: Array[int] = []


func _ready() -> void:
	_items.resize(size)
	_amounts.resize(size)
	_amounts.fill(0)
	for item in starting_items:
		add_item(item, 1)


func get_item(index: int) -> ItemData:
	return _items[index] if index >= 0 and index < size else null


func get_amount(index: int) -> int:
	return _amounts[index] if index >= 0 and index < size else 0


## Agrega items, primero apilando y después en casilleros vacíos.
## Devuelve cuántos no entraron.
func add_item(item: ItemData, amount: int = 1) -> int:
	var left := amount
	for i in size:
		if left <= 0:
			break
		if _items[i] == item and _amounts[i] < item.max_stack:
			var moved := mini(left, item.max_stack - _amounts[i])
			_amounts[i] += moved
			left -= moved
	for i in size:
		if left <= 0:
			break
		if _items[i] == null:
			var moved := mini(left, item.max_stack)
			_items[i] = item
			_amounts[i] = moved
			left -= moved
	if left != amount:
		changed.emit()
	return left


## Saca `amount` items del casillero `index` (o todos si amount < 0).
func remove_at(index: int, amount: int = -1) -> void:
	if get_item(index) == null:
		return
	_amounts[index] = 0 if amount < 0 else maxi(_amounts[index] - amount, 0)
	if _amounts[index] == 0:
		_items[index] = null
	changed.emit()


## Pone un item en un casillero vacío concreto (por ejemplo, el equipo que se cambió).
func put_at(index: int, item: ItemData, amount: int = 1) -> bool:
	if index < 0 or index >= size or _items[index] != null:
		return false
	_items[index] = item
	_amounts[index] = amount
	changed.emit()
	return true


func has_space_for(item: ItemData) -> bool:
	for i in size:
		if _items[i] == null or (_items[i] == item and _amounts[i] < item.max_stack):
			return true
	return false
