class_name SkeletonMinion
extends CharacterBody3D
## Esbirro del nigromante: sigue a su amo en formación y ataca al objetivo que el amo
## marcó (el último enemigo golpeado o clickeado). Si muere, reaparece junto al amo.

@export var move_speed: float = 5.2
@export var acceleration: float = 30.0
@export var turn_speed: float = 12.0
@export var attack_damage: int = 4
@export var attack_range: float = 1.3
@export var attack_cooldown: float = 1.1
@export var teleport_distance: float = 25.0
@export var respawn_time: float = 8.0

var master: Player
var formation_index: int = 0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _attack_timer: float = 0.0
var _last_nav_target: Vector3 = Vector3.INF
var _flicker_time: float = 0.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var visual: Node3D = $Visual
@onready var rig: CharacterRig = $Visual
@onready var health: Health = $Health
@onready var flame: Node3D = get_node_or_null("Visual/Cuerpo/Craneo/Llama")
@onready var flame_light: OmniLight3D = get_node_or_null("Visual/Cuerpo/Craneo/Luz")


func _ready() -> void:
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_flicker(delta)
	if master == null or not is_instance_valid(master):
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)

	var target := _valid_target()
	var destination: Vector3
	var stop_distance: float
	if target:
		destination = target.global_position
		stop_distance = attack_range
	else:
		destination = master.global_position + master.formation_offset(formation_index)
		stop_distance = 0.25
		if global_position.distance_to(master.global_position) > teleport_distance:
			global_position = destination
			reset_physics_interpolation()

	var to_destination := destination - global_position
	to_destination.y = 0.0
	var distance := to_destination.length()

	var direction := Vector3.ZERO
	if distance > stop_distance:
		direction = _path_direction(destination, to_destination)
	elif target and _attack_timer <= 0.0:
		_attack(target)

	direction += _separation()
	var speed := move_speed
	if target == null and distance < 1.5:
		speed *= clampf(distance / 1.5, 0.3, 1.0)
	var target_velocity := direction.limit_length(1.0) * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()

	rig.set_move_amount(Vector2(velocity.x, velocity.z).length() / move_speed)
	var face := to_destination if target and distance <= stop_distance + 0.5 else direction
	if face.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(face.x, face.z), turn_speed * delta)


func _valid_target() -> Node3D:
	var target := master.current_target
	if target == null or not is_instance_valid(target):
		return null
	var target_health := Health.of(target)
	if target_health == null or target_health.is_dead:
		return null
	return target


func _path_direction(destination: Vector3, fallback: Vector3) -> Vector3:
	if destination.distance_to(_last_nav_target) > 0.5:
		agent.target_position = destination
		_last_nav_target = destination
	var to_next := agent.get_next_path_position() - global_position
	to_next.y = 0.0
	# Sin malla de navegación (o ya llegando) se va en línea recta.
	if agent.is_navigation_finished() or to_next.length() < 0.05:
		to_next = fallback
	return to_next.normalized()


## Empuje para que los esbirros no se amontonen unos encima de otros.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	for other in master.minions:
		if other == self or not is_instance_valid(other):
			continue
		var away := global_position - other.global_position
		away.y = 0.0
		var distance := away.length()
		if distance > 0.001 and distance < 0.9:
			push += away / distance * (0.9 - distance) / 0.9
	return push * 1.5


func _attack(target: Node3D) -> void:
	_attack_timer = attack_cooldown
	rig.play_melee()
	await get_tree().create_timer(0.2, false, true).timeout
	if not is_instance_valid(target) or not is_instance_valid(self):
		return
	var target_health := Health.of(target)
	if target_health and global_position.distance_to(target.global_position) <= attack_range + 0.4:
		target_health.take_damage(attack_damage, self)


func _flicker(delta: float) -> void:
	_flicker_time += delta
	var n := sin(_flicker_time * 13.0) * 0.5 + sin(_flicker_time * 29.0 + 1.7) * 0.3
	if flame:
		flame.scale = Vector3(1.0 - n * 0.08, 1.0 + n * 0.18, 1.0 - n * 0.08)
	if flame_light:
		flame_light.light_energy = 0.8 + n * 0.2


func _on_died() -> void:
	visible = false
	set_physics_process(false)
	$Colision.set_deferred("disabled", true)
	await get_tree().create_timer(respawn_time, false, true).timeout
	if master and is_instance_valid(master):
		global_position = master.global_position + master.formation_offset(formation_index)
		reset_physics_interpolation()
	health.reset()
	$Colision.set_deferred("disabled", false)
	visible = true
	set_physics_process(true)
