class_name UiStyle
extends RefCounted
## Colores y piezas compartidas de la interfaz: marcos de madera oscura, fondos de
## piedra y texto claro, con acentos cálidos (oro) y el verde necrótico para lo elegido.

const WOOD := Color(0.15, 0.1, 0.065)
const WOOD_LIGHT := Color(0.4, 0.28, 0.15)
const WOOD_HIGHLIGHT := Color(0.58, 0.42, 0.22)
const STONE := Color(0.065, 0.065, 0.075)
const STONE_LIGHT := Color(0.12, 0.115, 0.12)
const TEXT := Color(0.86, 0.83, 0.76)
const TEXT_DIM := Color(0.58, 0.55, 0.49)
const GOLD := Color(0.93, 0.76, 0.38)
const SELECTED := Color(0.45, 1.0, 0.35)
const HEALTH := Color(0.62, 0.12, 0.1)
const MANA := Color(0.18, 0.32, 0.72)
const EXPERIENCE := Color(0.42, 0.55, 0.22)


static func box(bg: Color, border: Color, border_width: int = 2, margin: float = 8.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(margin)
	return style


## Sección del panel: fondo de piedra con marco de madera.
static func section(content: Control = null) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(STONE, WOOD_LIGHT, 2, 7.0))
	if content:
		panel.add_child(content)
	return panel


static func label(text: String, font_size: int = 14, color: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	result.add_theme_constant_override("outline_size", 3)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## Barra con texto centrado encima. Devuelve [barra, etiqueta].
static func stat_bar(color: Color, height: float = 20.0) -> Array:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	var background := box(Color(0.03, 0.03, 0.035), Color(0.24, 0.18, 0.11), 1, 0.0)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var text := label("", 13)
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(text)
	return [bar, text]
