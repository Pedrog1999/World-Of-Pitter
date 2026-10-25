class_name CameraRig
extends Node3D
## Cámara cenital fija estilo Argentum Online: sigue al objetivo con suavidad,
## sin rotar. La rueda del mouse acerca y aleja. Si la interfaz tapa una franja a la
## derecha (`set_right_margin`), la cámara se corre para centrar al personaje en el resto.

@export var target: Node3D
@export_range(20.0, 85.0) var pitch_degrees: float = 50.0
@export var distance: float = 22.0
@export var min_distance: float = 12.0
@export var max_distance: float = 32.0
@export var zoom_step: float = 2.0
@export var follow_speed: float = 8.0
@export var zoom_speed: float = 10.0
## Punto del objetivo al que mira la cámara (más o menos el pecho del personaje).
@export var look_height: float = 1.0

@onready var camera: Camera3D = $Camera3D

var _current_distance: float
## Ancho (en píxeles de la interfaz) tapado por los paneles de la derecha.
var _right_margin: float = 0.0


func _ready() -> void:
	add_to_group("camara_juego")
	# La cámara se mueve en _process; la interpolación física la haría temblar.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.rotation = Vector3(-deg_to_rad(pitch_degrees), 0.0, 0.0)
	_current_distance = distance
	if target:
		global_position = _target_point()
	_update_camera_offset()


func _process(delta: float) -> void:
	if target:
		var weight := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(_target_point(), weight)
	_current_distance = lerpf(_current_distance, distance, 1.0 - exp(-zoom_speed * delta))
	_update_camera_offset()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_step, min_distance, max_distance)


func set_right_margin(pixels: float) -> void:
	_right_margin = pixels


func _target_point() -> Vector3:
	return target.get_global_transform_interpolated().origin + Vector3.UP * look_height


func _update_camera_offset() -> void:
	# La cámara mira hacia -Z local; se ubica hacia atrás sobre ese eje.
	camera.position = camera.basis.z * _current_distance
	# Correr la cámara a la derecha deja al objetivo centrado en la parte visible.
	var screen := get_viewport().get_visible_rect().size
	if _right_margin <= 0.0 or screen.x <= 0.0:
		camera.h_offset = 0.0
		return
	var view_height := 2.0 * _current_distance * tan(deg_to_rad(camera.fov) * 0.5)
	var view_width := view_height * screen.x / screen.y
	camera.h_offset = view_width * (_right_margin / screen.x) * 0.5
