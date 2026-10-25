class_name UiStyle
extends RefCounted
## Colores y piezas compartidas de la interfaz: marcos de madera oscura, fondos de
## piedra y texto claro, con acentos cálidos (oro) y el verde necrótico para lo elegido.
## Las texturas salen del pack "RPG Inventory" de itsmars (CC0): de la lámina grande se
## recortan la piedra con el marco tallado, los recuadros de línea fina y el pergamino.

const SHEET := preload("res://assets/textures/ui/rpg_inventory/panel_inventario.png")
const SLOT_BORDER := preload("res://assets/textures/ui/rpg_inventory/borde_casillero.png")
const EQUIP_BORDER := preload("res://assets/textures/ui/rpg_inventory/borde_equipo.png")
## Esquina superior izquierda de la lámina: marco tallado + línea fina + piedra lisa.
const REGION_FRAME := Rect2(0, 0, 115, 470)
## Recuadro chico de línea fina (los de debajo del pergamino).
const REGION_BOX := Rect2(21, 496, 166, 32)
const REGION_PARCHMENT := Rect2(124, 30, 322, 448)
## Piedra lisa de la grilla, para el fondo de los casilleros.
const REGION_STONE := Rect2(30, 545, 56, 56)
const INK := Color(0.2, 0.12, 0.06)
const INK_DIM := Color(0.33, 0.24, 0.15)

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


## Recorte de la lámina como StyleBox 9-slice. `margins` = izquierda, arriba, derecha, abajo.
static func textured(region: Rect2, margins: Vector4, content_margin: float, tile: bool = true) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = SHEET
	style.region_rect = region
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.set_content_margin_all(content_margin)
	var mode := StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT if tile else StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_horizontal = mode
	style.axis_stretch_vertical = mode
	return style


## Fondo de todo el panel: piedra oscura con el marco tallado arriba y a la izquierda.
static func panel_frame() -> StyleBoxTexture:
	var style := textured(REGION_FRAME, Vector4(24, 24, 0, 0), 10.0)
	style.content_margin_left = 28.0
	style.content_margin_top = 26.0
	style.content_margin_bottom = 8.0
	return style


## Recuadro de línea fina sobre piedra (secciones, barras, botones).
static func line_box(content_margin: float = 7.0) -> StyleBoxTexture:
	return textured(REGION_BOX, Vector4(4, 4, 4, 4), content_margin, false)


static func parchment(content_margin: float = 14.0) -> StyleBoxTexture:
	var style := textured(REGION_PARCHMENT, Vector4(18, 18, 18, 18), content_margin)
	style.content_margin_left = content_margin + 10.0
	return style


static func stone() -> StyleBoxTexture:
	return textured(REGION_STONE, Vector4.ZERO, 0.0)


## Sección del panel: recuadro de línea fina sobre piedra.
static func section(content: Control = null) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", line_box())
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


## Texto oscuro, sin contorno, para escribir sobre el pergamino.
static func ink_label(text: String, font_size: int = 14, color: Color = INK) -> Label:
	var result := label(text, font_size, color)
	result.add_theme_constant_override("outline_size", 0)
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
