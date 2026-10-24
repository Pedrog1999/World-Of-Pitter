class_name Player
extends CharacterBody3D
## Jugador controlado con WASD/flechas en 8 direcciones.
## La cámara es fija (sin rotación), así que el movimiento usa los ejes del mundo:
## arriba = -Z, derecha = +X.

@export var move_speed: float = 4.5
@export var acceleration: float = 40.0
@export var turn_speed: float = 14.0

@onready var visual: Node3D = $Visual

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)

	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()

	if direction.length_squared() > 0.01:
		var target_yaw := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, turn_speed * delta)
