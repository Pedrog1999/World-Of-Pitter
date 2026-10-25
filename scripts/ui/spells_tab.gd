class_name SpellsTab
extends VBoxContainer
## Pestaña de hechizos: lista de hechizos conocidos y las 9 macros (teclas 1-9).
## Elegí un hechizo de la lista y hacé clic en una macro para asignarlo. Doble clic en
## la lista lo asigna a la macro seleccionada; clic derecho en una macro la vacía.

var player: Player

var _list: ItemList
var _slot_highlights: Array[Control] = []
var _slot_panels: Array[Control] = []
var _slot_names: Array[Label] = []
var _cooldown_bars: Array[ProgressBar] = []


func setup(p_player: Player) -> void:
	player = p_player
	add_theme_constant_override("separation", 6)

	_list = ItemList.new()
	_list.focus_mode = Control.FOCUS_NONE
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0, 60)
	_list.add_theme_stylebox_override("panel", UiStyle.line_box(4.0))
	_list.add_theme_stylebox_override("selected", UiStyle.box(UiStyle.STONE_LIGHT, UiStyle.SELECTED, 1, 2.0))
	_list.add_theme_stylebox_override("selected_focus", UiStyle.box(UiStyle.STONE_LIGHT, UiStyle.SELECTED, 1, 2.0))
	_list.add_theme_font_size_override("font_size", 13)
	for spell in player.known_spells:
		var index := _list.add_item("%s  ·  %d maná" % [spell.display_name, spell.mana_cost])
		_list.set_item_custom_fg_color(index, spell.color.lerp(Color.WHITE, 0.45))
		_list.set_item_tooltip(index, "Daño %d  ·  Recarga %.1f s  ·  Alcance %d m" % [spell.damage, spell.cooldown, int(spell.max_range)])
	_list.item_activated.connect(func(index: int) -> void:
		player.set_macro(player.selected_macro, player.known_spells[index])
		_list.deselect_all())
	add_child(_list)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	add_child(grid)
	for i in Player.MACRO_COUNT:
		grid.add_child(_make_slot(i))

	var hint := UiStyle.label("Elegí un hechizo y hacé clic en una macro", 11, UiStyle.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)

	player.macro_selected.connect(_refresh_selection.unbind(1))
	player.macros_changed.connect(_refresh_macros)
	player.mana.changed.connect(_refresh_mana.unbind(2))
	_refresh_macros()
	_refresh_selection()


func _process(_delta: float) -> void:
	if player == null:
		return
	for i in _cooldown_bars.size():
		_cooldown_bars[i].value = player.spell_cooldown_ratio(player.macros[i])


func _make_slot(index: int) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.line_box(4.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 34)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_slot_input.bind(index))
	_slot_panels.append(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	row.add_child(UiStyle.label(str(index + 1), 11, UiStyle.TEXT_DIM))
	var spell_name := UiStyle.label("", 12)
	spell_name.clip_text = true
	spell_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	spell_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spell_name)
	_slot_names.append(spell_name)

	var cooldown := ProgressBar.new()
	cooldown.max_value = 1.0
	cooldown.show_percentage = false
	cooldown.custom_minimum_size = Vector2(0, 3)
	cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cooldown)
	_cooldown_bars.append(cooldown)

	# Marco verde encima cuando es la macro elegida; se estira hasta el borde del casillero.
	var highlight := Panel.new()
	var glow := UiStyle.box(Color.TRANSPARENT, UiStyle.SELECTED, 2, 0.0)
	glow.draw_center = false
	glow.set_expand_margin_all(4.0)
	highlight.add_theme_stylebox_override("panel", glow)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(highlight)
	_slot_highlights.append(highlight)
	return panel


func _on_slot_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		var chosen := _list.get_selected_items()
		if chosen.is_empty():
			player.select_macro(index)
		else:
			player.set_macro(index, player.known_spells[chosen[0]])
			_list.deselect_all()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		player.set_macro(index, null)


func _refresh_macros() -> void:
	for i in _slot_names.size():
		var spell := player.macros[i]
		_slot_names[i].text = spell.display_name if spell else "—"
		_slot_names[i].add_theme_color_override("font_color", spell.color.lerp(Color.WHITE, 0.45) if spell else UiStyle.TEXT_DIM)
		_slot_panels[i].tooltip_text = "%s (%d maná)" % [spell.display_name, spell.mana_cost] if spell else ""
	_refresh_mana()


func _refresh_selection() -> void:
	for i in _slot_highlights.size():
		_slot_highlights[i].visible = i == player.selected_macro


func _refresh_mana() -> void:
	for i in _slot_panels.size():
		var spell := player.macros[i]
		var castable := spell == null or player.mana.has(spell.mana_cost)
		_slot_panels[i].modulate.a = 1.0 if castable else 0.45
