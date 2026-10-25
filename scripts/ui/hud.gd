class_name Hud
extends CanvasLayer
## HUD mínimo: barra de hechizos (macros) con tiempo de recarga y ayuda de controles.

const SLOT_BG := Color(0.05, 0.06, 0.07, 0.78)
const SLOT_BORDER := Color(0.3, 0.3, 0.32)
const SLOT_SELECTED := Color(0.45, 1.0, 0.35)

@export var player: Player

var _slot_styles: Array[StyleBoxFlat] = []
var _cooldown_bars: Array[ProgressBar] = []


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	for i in player.spells.size():
		bar.add_child(_make_slot(i, player.spells[i]))
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

	var help := Label.new()
	help.text = "WASD mover  ·  Ctrl golpe  ·  1-%d elegir hechizo  ·  Clic izq. lanzar  ·  Rueda zoom" % player.spells.size()
	help.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72, 0.8))
	help.add_theme_font_size_override("font_size", 14)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 12)

	player.spell_selected.connect(_on_spell_selected)
	_on_spell_selected(player.selected_spell)


func _process(_delta: float) -> void:
	for i in _cooldown_bars.size():
		_cooldown_bars[i].value = player.spell_cooldown_ratio(i)


func _make_slot(index: int, spell: SpellData) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.set_border_width_all(2)
	style.border_color = SLOT_BORDER
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_slot_styles.append(style)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(150, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)

	var title := Label.new()
	title.text = "%d  %s" % [index + 1, spell.display_name]
	title.add_theme_color_override("font_color", spell.color.lerp(Color.WHITE, 0.4))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)

	var cooldown := ProgressBar.new()
	cooldown.max_value = 1.0
	cooldown.show_percentage = false
	cooldown.custom_minimum_size = Vector2(0, 4)
	cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cooldown)
	_cooldown_bars.append(cooldown)
	return panel


func _on_spell_selected(index: int) -> void:
	for i in _slot_styles.size():
		_slot_styles[i].border_color = SLOT_SELECTED if i == index else SLOT_BORDER
