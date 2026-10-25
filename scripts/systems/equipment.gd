class_name Equipment
extends Node
## Equipo puesto: un item por slot (arma, casco, armadura, escudo). Sus bonificaciones
## se suman con `total()`.

signal changed

const SLOTS: Array[ItemData.Kind] = [
	ItemData.Kind.WEAPON,
	ItemData.Kind.HELMET,
	ItemData.Kind.ARMOR,
	ItemData.Kind.SHIELD,
]

var _equipped: Dictionary[ItemData.Kind, ItemData] = {}


func get_equipped(slot: ItemData.Kind) -> ItemData:
	return _equipped.get(slot)


## Se pone el item y devuelve el que estaba en ese slot (o null).
func equip(item: ItemData) -> ItemData:
	if item == null or not item.is_equipment():
		return null
	var previous: ItemData = _equipped.get(item.kind)
	_equipped[item.kind] = item
	changed.emit()
	return previous


## Se saca el item del slot y lo devuelve.
func unequip(slot: ItemData.Kind) -> ItemData:
	var previous: ItemData = _equipped.get(slot)
	if previous:
		_equipped.erase(slot)
		changed.emit()
	return previous


## Suma de una bonificación (`armor`, `melee_damage_bonus`...) de todo lo puesto.
func total(stat: StringName) -> int:
	var sum := 0
	for item: ItemData in _equipped.values():
		sum += int(item.get(stat))
	return sum
