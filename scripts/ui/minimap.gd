class_name Minimap
extends Control
## Minimapa: una cámara ortográfica mira el mundo desde arriba (norte = arriba) con su
## propio ambiente iluminado, y encima se dibujan puntos para el jugador, sus esbirros,
## los enemigos y los items del suelo.

const PLAYER_COLOR := Color(0.45, 1.0, 0.35)
const MINION_COLOR := Color(0.86, 0.83, 0.72)
const ENEMY_COLOR := Color(0.9, 0.25, 0.2)
const ITEM_COLOR := Color(0.93, 0.76, 0.38)

## Metros de mundo que entran de arriba a abajo.
@export var view_size: float = 40.0

var player: Player

var _camera: Camera3D
var _overlay: Control


func setup(p_player: Player) -> void:
	player = p_player
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	# Sin world_3d propio: comparte el mundo del juego.
	var viewport := SubViewport.new()
	viewport.positional_shadow_atlas_size = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = view_size
	_camera.far = 150.0
	_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_camera.environment = _make_environment()
	viewport.add_child(_camera)
	_camera.current = true

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_markers)
	add_child(_overlay)


func _process(_delta: float) -> void:
	if player == null:
		return
	_camera.global_position = player.global_position + Vector3.UP * 60.0
	_overlay.queue_redraw()


func _make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.74, 0.66)
	env.ambient_light_energy = 1.1
	return env


func _draw_markers() -> void:
	var center := _overlay.size * 0.5
	var pixels_per_meter := _overlay.size.y / view_size
	for world_item: Node3D in get_tree().get_nodes_in_group(WorldItem.GROUP):
		_draw_dot(world_item.global_position, center, pixels_per_meter, ITEM_COLOR, 1.8)
	for enemy: Node3D in get_tree().get_nodes_in_group("enemigos"):
		var enemy_health := Health.of(enemy)
		if enemy_health and not enemy_health.is_dead:
			_draw_dot(enemy.global_position, center, pixels_per_meter, ENEMY_COLOR, 3.5)
	for minion in player.minions:
		if is_instance_valid(minion) and minion.visible:
			_draw_dot(minion.global_position, center, pixels_per_meter, MINION_COLOR, 2.5)

	# El jugador es una flecha que apunta hacia donde mira.
	var yaw := player.visual.rotation.y
	var forward := Vector2(sin(yaw), cos(yaw))
	var side := Vector2(-forward.y, forward.x)
	var arrow := PackedVector2Array([
		center + forward * 7.0,
		center - forward * 5.0 + side * 5.0,
		center - forward * 2.5,
		center - forward * 5.0 - side * 5.0,
	])
	_overlay.draw_colored_polygon(arrow, PLAYER_COLOR)


func _draw_dot(world_position: Vector3, center: Vector2, pixels_per_meter: float, color: Color, radius: float) -> void:
	var offset := Vector2(world_position.x - player.global_position.x, world_position.z - player.global_position.z)
	var point := center + offset * pixels_per_meter
	if Rect2(Vector2.ZERO, _overlay.size).grow(-radius).has_point(point):
		_overlay.draw_circle(point, radius + 1.0, Color(0.0, 0.0, 0.0, 0.8))
		_overlay.draw_circle(point, radius, color)
