class_name Hud
extends CanvasLayer
## HUD mínimo: barras de vida y maná, barra de hechizos (macros) con tiempo de recarga,
## aviso de muerte y ayuda de controles. Se reemplaza por los paneles fijos en el paso 2.

const SLOT_BG := Color(0.05, 0.06, 0.07, 0.78)
const SLOT_BORDER := Color(0.3, 0.3, 0.32)
const SLOT_SELECTED := Color(0.45, 1.0, 0.35)
const HEALTH_COLOR := Color(0.62, 0.12, 0.1)
const MANA_COLOR := Color(0.18, 0.32, 0.72)
const TEXT_COLOR := Color(0.85, 0.83, 0.78)

@export var player: Player

var _slot_styles: Array[StyleBoxFlat] = []
var _cooldown_bars: Array[ProgressBar] = []
var _slot_panels: Array[Control] = []
var _health_bar: ProgressBar
var _health_label: Label
var _mana_bar: ProgressBar
var _mana_label: Label
var _mana_flash: Tween
var _death_overlay: ColorRect
var _death_label: Label
var _respawn_left: float = 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(stats)
	var health_parts := _make_stat_bar(HEALTH_COLOR)
	_health_bar = health_parts[0]
	_health_label = health_parts[1]
	stats.add_child(_health_bar)
	var mana_parts := _make_stat_bar(MANA_COLOR)
	_mana_bar = mana_parts[0]
	_mana_label = mana_parts[1]
	stats.add_child(_mana_bar)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(bar)
	for i in player.spells.size():
		bar.add_child(_make_slot(i, player.spells[i]))
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)

	_make_death_overlay(root)

	var help := Label.new()
	help.text = "WASD mover  ·  Ctrl golpe  ·  1-%d elegir hechizo  ·  Clic izq. lanzar  ·  Rueda zoom" % player.spells.size()
	if OS.is_debug_build():
		help.text += "  ·  F9 recibir daño (prueba)"
	help.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72, 0.8))
	help.add_theme_font_size_override("font_size", 14)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 12)

	player.spell_selected.connect(_on_spell_selected)
	_on_spell_selected(player.selected_spell)
	player.health.damaged.connect(_refresh_health.unbind(2))
	player.health.healed.connect(_refresh_health.unbind(1))
	player.health.died.connect(_refresh_health)
	player.mana.changed.connect(_refresh_mana.unbind(2))
	player.not_enough_mana.connect(_on_not_enough_mana.unbind(1))
	player.died.connect(_on_player_died)
	player.respawned.connect(_on_player_respawned)
	_refresh_health()
	_refresh_mana()


func _process(delta: float) -> void:
	for i in _cooldown_bars.size():
		_cooldown_bars[i].value = player.spell_cooldown_ratio(i)
	if _death_overlay.visible:
		_respawn_left = maxf(_respawn_left - delta, 0.0)
		_death_label.text = "Has muerto.
Reaparecerás en la plaza en %d…" % ceili(_respawn_left)


## Devuelve [barra, etiqueta]; la etiqueta va centrada sobre la barra.
func _make_stat_bar(color: Color) -> Array:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var background := StyleBoxFlat.new()
	background.bg_color = SLOT_BG
	background.set_border_width_all(2)
	background.border_color = SLOT_BORDER
	background.set_corner_radius_all(4)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(150, 22)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 14)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)
	return [bar, label]


func _make_death_overlay(root: Control) -> void:
	_death_overlay = ColorRect.new()
	_death_overlay.color = Color(0.05, 0.0, 0.0, 0.55)
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	root.add_child(_death_overlay)

	_death_label = Label.new()
	_death_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.25))
	_death_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_death_label.add_theme_constant_override("outline_size", 6)
	_death_label.add_theme_font_size_override("font_size", 32)
	_death_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(_death_label)


func _refresh_health() -> void:
	var health := player.health
	_health_bar.max_value = health.max_health
	_health_bar.value = health.current
	_health_label.text = "Vida %d / %d" % [health.current, health.max_health]


func _refresh_mana() -> void:
	var mana := player.mana
	_mana_bar.max_value = mana.max_mana
	_mana_bar.value = mana.current
	_mana_label.text = "Maná %d / %d" % [mana.current, mana.max_mana]
	for i in _slot_panels.size():
		_slot_panels[i].modulate.a = 1.0 if mana.has(player.spells[i].mana_cost) else 0.45


func _on_not_enough_mana() -> void:
	if _mana_flash:
		_mana_flash.kill()
	_mana_bar.modulate = Color(2.0, 2.0, 2.0)
	_mana_flash = create_tween()
	_mana_flash.tween_property(_mana_bar, "modulate", Color.WHITE, 0.35)


func _on_player_died() -> void:
	_respawn_left = player.respawn_time
	_death_overlay.visible = true


func _on_player_respawned() -> void:
	_death_overlay.visible = false


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
	title.text = "%d  %s  (%d)" % [index + 1, spell.display_name, spell.mana_cost]
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
	_slot_panels.append(panel)
	return panel


func _on_spell_selected(index: int) -> void:
	for i in _slot_styles.size():
		_slot_styles[i].border_color = SLOT_SELECTED if i == index else SLOT_BORDER
