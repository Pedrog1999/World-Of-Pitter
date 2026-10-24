class_name CameraRig
extends Node3D
## Cámara cenital fija estilo Argentum Online: sigue al objetivo con suavidad,
## sin rotar. La rueda del mouse acerca y aleja.

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


func _ready() -> void:
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


func _target_point() -> Vector3:
	return target.get_global_transform_interpolated().origin + Vector3.UP * look_height


func _update_camera_offset() -> void:
	# La cámara mira hacia -Z local; se ubica hacia atrás sobre ese eje.
	camera.position = camera.basis.z * _current_distance
