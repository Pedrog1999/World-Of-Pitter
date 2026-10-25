class_name InventoryTab
extends VBoxContainer
## Pestaña de inventario: grilla de casilleros de items.

const COLUMNS := 5
const SLOT_COUNT := 20
const SLOT_SIZE := 44.0

var player: Player


func setup(p_player: Player) -> void:
	player = p_player
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(grid)
	for i in SLOT_COUNT:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.STONE_LIGHT, Color(0.24, 0.18, 0.11), 1, 0.0))
		grid.add_child(slot)
