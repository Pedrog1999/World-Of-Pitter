class_name ItemSlot
extends Panel
## Casillero de item (inventario o equipo). Muestra el ícono del item, o un cuadro de
## su color con las iniciales si no tiene ícono, y la cantidad si es más de uno.

signal clicked
signal double_clicked

var _style: StyleBoxFlat
var _swatch: ColorRect
var _icon: TextureRect
var _initials: Label
var _amount: Label
var _placeholder: Label


## `placeholder`: texto tenue cuando está vacío (por ejemplo "Arma").
func _init(slot_size: float, placeholder: String = "") -> void:
	custom_minimum_size = Vector2(slot_size, slot_size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style = UiStyle.box(UiStyle.STONE_LIGHT, Color(0.24, 0.18, 0.11), 1, 0.0)
	add_theme_stylebox_override("panel", _style)

	_placeholder = UiStyle.label(placeholder, 10, Color(UiStyle.TEXT_DIM, 0.6))
	_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_placeholder)

	_swatch = ColorRect.new()
	_swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
	_swatch.offset_left = 5
	_swatch.offset_top = 5
	_swatch.offset_right = -5
	_swatch.offset_bottom = -5
	_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_swatch)
	_initials = UiStyle.label("", 13)
	_initials.set_anchors_preset(Control.PRESET_FULL_RECT)
	_initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_swatch.add_child(_initials)

	_icon = TextureRect.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	_amount = UiStyle.label("", 11)
	_amount.set_anchors_preset(Control.PRESET_FULL_RECT)
	_amount.offset_right = -3
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_amount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_amount)
	set_item(null)


func set_item(item: ItemData, amount: int = 1) -> void:
	_placeholder.visible = item == null
	_icon.texture = item.icon if item else null
	_swatch.visible = item != null and item.icon == null
	if item:
		_swatch.color = item.color.darkened(0.15)
		_initials.text = item.initials()
	_amount.text = str(amount) if item and amount > 1 else ""
	tooltip_text = item.tooltip() if item else ""


func set_selected(selected: bool) -> void:
	_style.border_color = UiStyle.SELECTED if selected else Color(0.24, 0.18, 0.11)
	_style.set_border_width_all(2 if selected else 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			double_clicked.emit()
		else:
			clicked.emit()
