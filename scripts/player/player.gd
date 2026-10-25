class_name Player
extends CharacterBody3D
## Nigromante controlado por el jugador.
## - Movimiento con WASD/flechas en 8 direcciones. La cámara es fija, así que se usan
##   los ejes del mundo: arriba = -Z, derecha = +X.
## - Ctrl: golpe cuerpo a cuerpo hacia donde mira.
## - 1-4: elegir hechizo (macros). Clic izquierdo: lanzarlo hacia el mouse.
## - Los esbirros (esqueletos) lo siguen y atacan al último objetivo que marcó.

signal target_changed(target: Node3D)
signal spell_selected(index: int)

const ENEMY_LAYER := 1 << 3
const CAST_HEIGHT := 1.2

@export var move_speed: float = 4.5
@export var acceleration: float = 40.0
@export var turn_speed: float = 14.0

@export_group("Cuerpo a cuerpo")
@export var melee_damage: int = 8
@export var melee_range: float = 1.8
@export var melee_angle_degrees: float = 70.0
@export var melee_cooldown: float = 0.7

@export_group("Hechizos")
@export var spells: Array[SpellData] = []
@export var projectile_scene: PackedScene

@export_group("Esbirros")
@export var minion_scene: PackedScene
@export var minion_count: int = 3
@export var formation_radius: float = 1.7

var current_target: Node3D
var selected_spell: int = 0
var minions: Array[Node3D] = []

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _melee_timer: float = 0.0
var _spell_timers: Array[float] = []
## Mientras es > 0 el personaje está golpeando o lanzando y no puede moverse.
var _action_lock: float = 0.0

@onready var visual: Node3D = $Visual
@onready var animator: ModelAnimator = $Visual
@onready var health: Health = $Health


func _ready() -> void:
	_spell_timers.resize(spells.size())
	_spell_timers.fill(0.0)
	_spawn_minions.call_deferred()


func _physics_process(delta: float) -> void:
	_melee_timer = maxf(_melee_timer - delta, 0.0)
	for i in _spell_timers.size():
		_spell_timers[i] = maxf(_spell_timers[i] - delta, 0.0)
	_action_lock = maxf(_action_lock - delta, 0.0)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	if _action_lock > 0.0:
		direction = Vector3.ZERO
	elif direction.length_squared() > 0.01 and animator.is_busy():
		animator.cancel_action()

	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()

	animator.set_move_speed(Vector2(velocity.x, velocity.z).length())
	if direction.length_squared() > 0.01:
		var target_yaw := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, turn_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("melee"):
		_melee()
	elif event.is_action_pressed("cast_spell"):
		_cast_selected_spell()
	else:
		for i in spells.size():
			if event.is_action_pressed("spell_%d" % (i + 1)):
				select_spell(i)


func select_spell(index: int) -> void:
	if index < 0 or index >= spells.size():
		return
	selected_spell = index
	spell_selected.emit(index)


## 0 = listo para lanzar, 1 = recién lanzado.
func spell_cooldown_ratio(index: int) -> float:
	var cooldown := spells[index].cooldown
	return _spell_timers[index] / cooldown if cooldown > 0.0 else 0.0


func set_target(target: Node3D) -> void:
	if target == current_target:
		return
	var old_health := Health.of(current_target) if is_instance_valid(current_target) else null
	if old_health and old_health.died.is_connected(_on_target_died):
		old_health.died.disconnect(_on_target_died)
	current_target = target
	var new_health := Health.of(target)
	if new_health:
		new_health.died.connect(_on_target_died)
	target_changed.emit(target)


func _on_target_died() -> void:
	set_target(null)


## Posición que ocupa el esbirro `index` detrás del nigromante, en abanico.
func formation_offset(index: int) -> Vector3:
	var count := maxi(minion_count, 1)
	var t := 0.5 if count == 1 else float(index) / float(count - 1)
	var angle := deg_to_rad(lerpf(-55.0, 55.0, t))
	var local := Vector3(sin(angle), 0.0, -cos(angle)) * formation_radius
	return visual.global_basis * local


## Reemplaza los esbirros actuales (por ejemplo, esqueletos por lobos).
func set_minions(scene: PackedScene, count: int) -> void:
	for minion in minions:
		if is_instance_valid(minion):
			minion.queue_free()
	minions.clear()
	minion_scene = scene
	minion_count = count
	_spawn_minions()


func _spawn_minions() -> void:
	if minion_scene == null:
		return
	for i in minion_count:
		var minion := minion_scene.instantiate()
		minion.master = self
		minion.formation_index = i
		get_parent().add_child(minion)
		minion.global_position = global_position + formation_offset(i)
		minions.append(minion)


func _melee() -> void:
	if _melee_timer > 0.0 or _action_lock > 0.0:
		return
	_melee_timer = melee_cooldown
	var impact_delay := animator.play_melee()
	_action_lock = impact_delay + 0.1
	await get_tree().create_timer(impact_delay, false, true).timeout

	var forward := visual.global_basis.z
	var best: Node3D
	var best_distance := INF
	for enemy: Node3D in get_tree().get_nodes_in_group("enemigos"):
		var enemy_health := Health.of(enemy)
		if enemy_health == null or enemy_health.is_dead:
			continue
		var to_enemy := enemy.global_position - global_position
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > melee_range:
			continue
		if distance > 0.01 and rad_to_deg(forward.angle_to(to_enemy / distance)) > melee_angle_degrees:
			continue
		if distance < best_distance:
			best = enemy
			best_distance = distance

	if best:
		Health.of(best).take_damage(melee_damage, self)
		set_target(best)


func _cast_selected_spell() -> void:
	if spells.is_empty() or projectile_scene == null:
		return
	if _spell_timers[selected_spell] > 0.0 or _action_lock > 0.0:
		return
	var aim := _mouse_aim()
	if aim.is_empty():
		return

	var spell := spells[selected_spell]
	var direction: Vector3 = aim.point - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	visual.rotation.y = atan2(direction.x, direction.z)

	_spell_timers[selected_spell] = spell.cooldown
	var release_delay := animator.play_cast(spell)
	_action_lock = release_delay + 0.1
	if aim.target:
		set_target(aim.target)
	await get_tree().create_timer(release_delay, false, true).timeout

	var projectile: SpellProjectile = projectile_scene.instantiate()
	projectile.setup(spell, self, direction)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * 0.6 + Vector3.UP * CAST_HEIGHT


## Punto al que apunta el mouse. Si está sobre un enemigo, devuelve ese enemigo.
func _mouse_aim() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {}
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var ray := camera.project_ray_normal(mouse)

	var query := PhysicsRayQueryParameters3D.create(from, from + ray * 200.0, ENEMY_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and Health.of(hit.collider) and not Health.of(hit.collider).is_dead:
		return {"point": hit.collider.global_position, "target": hit.collider}

	var point = Plane(Vector3.UP, CAST_HEIGHT).intersects_ray(from, ray)
	if point == null:
		return {}
	return {"point": point, "target": null}
