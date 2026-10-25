class_name InventoryTab
extends VBoxContainer
## Pestaña de inventario: arriba el equipo puesto (arma, casco, armadura, escudo) y
## abajo la grilla de items. Clic elige un casillero; doble clic (o U) usa el item o se
## lo pone. Doble clic en el equipo se lo saca.

const COLUMNS := 5
const SLOT_SIZE := 40.0
const EQUIPMENT_LABELS := {
	ItemData.Kind.WEAPON: "Arma",
	ItemData.Kind.HELMET: "Casco",
	ItemData.Kind.ARMOR: "Armadura",
	ItemData.Kind.SHIELD: "Escudo",
}

var player: Player

var _slots: Array[ItemSlot] = []
var _equipment_slots: Dictionary[ItemData.Kind, ItemSlot] = {}


func setup(p_player: Player) -> void:
	player = p_player
	add_theme_constant_override("separation", 6)

	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 4)
	equipment_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(equipment_row)
	for kind: ItemData.Kind in Equipment.SLOTS:
		var slot := ItemSlot.new(SLOT_SIZE + 4.0, EQUIPMENT_LABELS[kind], UiStyle.EQUIP_BORDER)
		slot.double_clicked.connect(player.unequip.bind(kind))
		equipment_row.add_child(slot)
		_equipment_slots[kind] = slot

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(grid)
	for i in player.inventory.size:
		var slot := ItemSlot.new(SLOT_SIZE)
		slot.clicked.connect(player.select_inventory_slot.bind(i))
		slot.double_clicked.connect(func() -> void:
			player.select_inventory_slot(i)
			player.use_item(i))
		grid.add_child(slot)
		_slots.append(slot)

	player.inventory.changed.connect(_refresh_items)
	player.equipment.changed.connect(_refresh_equipment)
	player.inventory_slot_selected.connect(_refresh_selection.unbind(1))
	_refresh_items()
	_refresh_equipment()
	_refresh_selection()


func _refresh_items() -> void:
	for i in _slots.size():
		_slots[i].set_item(player.inventory.get_item(i), player.inventory.get_amount(i))


func _refresh_equipment() -> void:
	for kind: ItemData.Kind in _equipment_slots:
		_equipment_slots[kind].set_item(player.equipment.get_equipped(kind))


func _refresh_selection() -> void:
	for i in _slots.size():
		_slots[i].set_selected(i == player.selected_slot)
