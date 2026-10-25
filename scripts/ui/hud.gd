class_name Hud
extends CanvasLayer
## Interfaz estilo Argentum Online: un panel fijo a la derecha y el juego en el resto.
## Panel, de arriba a abajo:
## - Datos personales: nombre, clase, nivel y experiencia.
## - Pestañas Inventario / Hechizos (hechizos conocidos y macros 1-9).
## - Estado: vida, maná, oro, daño y defensa.
## - Minimapa.
## Sobre la zona de juego quedan la ayuda de controles y el aviso de muerte.

const PANEL_WIDTH := 300.0

@export var player: Player

var _name_label: Label
var _level_label: Label
var _experience_bar: ProgressBar
var _experience_label: Label
var _health_bar: ProgressBar
var _health_label: Label
var _mana_bar: ProgressBar
var _mana_label: Label
var _gold_label: Label
var _combat_label: Label
var _mana_flash: Tween
var _tab_buttons: Array[Button] = []
var _tab_pages: Array[Control] = []
var _death_overlay: ColorRect
var _death_label: Label
var _respawn_left: float = 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var game_area := Control.new()
	game_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_area.offset_right = -PANEL_WIDTH
	game_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(game_area)
	_make_help(game_area)
	_make_death_overlay(game_area)

	root.add_child(_make_panel())

	player.progression.experience_changed.connect(_refresh_personal.unbind(2))
	player.progression.leveled_up.connect(_refresh_personal.unbind(1))
	player.health.damaged.connect(_refresh_health.unbind(2))
	player.health.healed.connect(_refresh_health.unbind(1))
	player.health.died.connect(_refresh_health)
	player.health.max_health_changed.connect(_refresh_health.unbind(1))
	player.equipment.changed.connect(_refresh_combat)
	player.mana.changed.connect(_refresh_mana.unbind(2))
	player.not_enough_mana.connect(_on_not_enough_mana.unbind(1))
	player.gold_changed.connect(_refresh_gold.unbind(1))
	player.died.connect(_on_player_died)
	player.respawned.connect(_on_player_respawned)
	_refresh_personal()
	_refresh_health()
	_refresh_mana()
	_refresh_gold()
	_refresh_combat()

	get_tree().call_group.call_deferred("camara_juego", "set_right_margin", PANEL_WIDTH)


func _process(delta: float) -> void:
	if _death_overlay.visible:
		_respawn_left = maxf(_respawn_left - delta, 0.0)
		_death_label.text = "Has muerto.\nReaparecerás en la plaza en %d…" % ceili(_respawn_left)


func _make_panel() -> Control:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -PANEL_WIDTH
	# Frena los clics para que no lancen hechizos ni muevan el zoom.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := UiStyle.box(UiStyle.WOOD, UiStyle.WOOD_LIGHT, 0, 8.0)
	frame.border_width_left = 4
	frame.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	column.add_child(_make_personal())
	var tabs := _make_tabs()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	column.add_child(_make_stats())

	var minimap := Minimap.new()
	minimap.custom_minimum_size = Vector2(0, 160)
	var minimap_section := UiStyle.section(minimap)
	minimap.setup(player)
	column.add_child(minimap_section)
	return panel


func _make_personal() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	_name_label = UiStyle.label("", 20, UiStyle.GOLD)
	column.add_child(_name_label)
	_level_label = UiStyle.label("", 13, UiStyle.TEXT_DIM)
	column.add_child(_level_label)
	var parts := UiStyle.stat_bar(UiStyle.EXPERIENCE, 16)
	_experience_bar = parts[0]
	_experience_label = parts[1]
	column.add_child(_experience_bar)
	return UiStyle.section(column)


func _make_tabs() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)

	# Las páginas se apilan en el mismo marco; solo se ve la de la pestaña elegida.
	var pages := UiStyle.section()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(pages)

	var inventory := InventoryTab.new()
	inventory.setup(player)
	var spells := SpellsTab.new()
	spells.setup(player)
	for page: Control in [inventory, spells]:
		pages.add_child(page)
		_tab_pages.append(page)

	var group := ButtonGroup.new()
	for title in ["Inventario", "Hechizos"]:
		var button := Button.new()
		button.text = title
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", UiStyle.TEXT_DIM)
		button.add_theme_color_override("font_hover_color", UiStyle.TEXT)
		button.add_theme_color_override("font_pressed_color", UiStyle.GOLD)
		button.add_theme_color_override("font_hover_pressed_color", UiStyle.GOLD)
		button.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.WOOD, UiStyle.WOOD_LIGHT, 1, 4.0))
		button.add_theme_stylebox_override("hover", UiStyle.box(UiStyle.STONE_LIGHT, UiStyle.WOOD_LIGHT, 1, 4.0))
		button.add_theme_stylebox_override("pressed", UiStyle.box(UiStyle.STONE, UiStyle.WOOD_HIGHLIGHT, 2, 4.0))
		button.add_theme_stylebox_override("hover_pressed", UiStyle.box(UiStyle.STONE, UiStyle.WOOD_HIGHLIGHT, 2, 4.0))
		var index := _tab_buttons.size()
		button.toggled.connect(func(on: bool) -> void:
			if on:
				_show_tab(index))
		header.add_child(button)
		_tab_buttons.append(button)
	_tab_buttons[0].button_pressed = true
	_show_tab(0)
	return column


func _show_tab(index: int) -> void:
	for i in _tab_pages.size():
		_tab_pages[i].visible = i == index


func _make_stats() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var health_parts := UiStyle.stat_bar(UiStyle.HEALTH)
	_health_bar = health_parts[0]
	_health_label = health_parts[1]
	column.add_child(_health_bar)
	var mana_parts := UiStyle.stat_bar(UiStyle.MANA)
	_mana_bar = mana_parts[0]
	_mana_label = mana_parts[1]
	column.add_child(_mana_bar)
	var row := HBoxContainer.new()
	column.add_child(row)
	_gold_label = UiStyle.label("", 14, UiStyle.GOLD)
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_gold_label)
	_combat_label = UiStyle.label("", 13, UiStyle.TEXT_DIM)
	row.add_child(_combat_label)
	return UiStyle.section(column)


func _make_help(game_area: Control) -> void:
	var help := UiStyle.label("WASD mover  ·  Ctrl golpe  ·  1-9 macro  ·  Clic izq. lanzar  ·  U usar  ·  E juntar  ·  T tirar  ·  Rueda zoom", 13, Color(0.75, 0.75, 0.72, 0.8))
	if OS.is_debug_build():
		help.text += "  ·  F9 recibir daño (prueba)"
	game_area.add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 12)


func _make_death_overlay(game_area: Control) -> void:
	_death_overlay = ColorRect.new()
	_death_overlay.color = Color(0.05, 0.0, 0.0, 0.55)
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	game_area.add_child(_death_overlay)

	_death_label = UiStyle.label("", 32, Color(0.85, 0.3, 0.25))
	_death_label.add_theme_constant_override("outline_size", 6)
	_death_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_overlay.add_child(_death_label)


func _refresh_personal() -> void:
	var progression := player.progression
	_name_label.text = player.character_name
	_level_label.text = "%s  ·  Nivel %d" % [player.class_title, progression.level]
	if progression.is_max_level():
		_experience_bar.max_value = 1.0
		_experience_bar.value = 1.0
		_experience_label.text = "Nivel máximo"
	else:
		_experience_bar.max_value = progression.experience_to_next()
		_experience_bar.value = progression.experience
		_experience_label.text = "Exp %d / %d" % [progression.experience, progression.experience_to_next()]


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


func _refresh_gold() -> void:
	_gold_label.text = "Oro: %d" % player.gold


func _refresh_combat() -> void:
	var spell_bonus := player.equipment.total(&"spell_damage_bonus")
	_combat_label.text = "Golpe %d  ·  Magia +%d  ·  Def %d" % [player.melee_damage_total(), spell_bonus, player.health.armor]


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
