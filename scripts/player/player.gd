class_name Player
extends CharacterBody3D
## Nigromante controlado por el jugador.
## - Movimiento con WASD/flechas en 8 direcciones. La cámara es fija, así que se usan
##   los ejes del mundo: arriba = -Z, derecha = +X.
## - Ctrl: golpe cuerpo a cuerpo hacia donde mira.
## - 1-9: elegir macro de hechizo. Clic izquierdo: lanzarlo hacia el mouse. Los hechizos
##   conocidos se asignan a las macros desde el panel de Hechizos.
## - Los esbirros (esqueletos) lo siguen y atacan al último objetivo que marcó.
## - Los hechizos gastan maná. Vida y maná se regeneran solos. Al morir reaparece
##   en la plaza (`respawn_point`, o donde arrancó si no hay uno asignado).
## - Gana experiencia al matar; cada nivel sube la vida y el maná máximos.
## - Inventario y equipo: doble clic (o U) sobre un item lo usa o se lo pone. El equipo
##   suma daño, defensa, vida y maná.

signal target_changed(target: Node3D)
signal macro_selected(index: int)
signal macros_changed
signal gold_changed(gold: int)
signal inventory_slot_selected(index: int)
## El hechizo no se lanzó porque falta maná.
signal not_enough_mana(spell: SpellData)
signal died
signal respawned

const ENEMY_LAYER := 1 << 3
const CAST_HEIGHT := 1.2
const MACRO_COUNT := 9

@export var character_name: String = "Pitter"
@export var class_title: String = "Nigromante"
@export var move_speed: float = 4.5
@export var acceleration: float = 40.0
@export var turn_speed: float = 14.0

@export_group("Cuerpo a cuerpo")
@export var melee_damage: int = 8
@export var melee_range: float = 1.8
@export var melee_angle_degrees: float = 70.0
@export var melee_cooldown: float = 0.7

@export_group("Hechizos")
## Hechizos que el personaje sabe. Al empezar se asignan en orden a las macros.
@export var known_spells: Array[SpellData] = []
@export var projectile_scene: PackedScene

@export_group("Progresión")
@export var health_per_level: int = 10
@export var mana_per_level: int = 12

@export_group("Muerte")
## Lugar donde reaparece al morir (un Marker3D en la plaza).
@export var respawn_point: Node3D
@export var respawn_time: float = 5.0

@export_group("Esbirros")
@export var minion_scene: PackedScene
@export var minion_count: int = 3
@export var formation_radius: float = 1.7

var current_target: Node3D
var selected_macro: int = 0
## Hechizo de cada macro (1-9); null = macro vacía.
var macros: Array[SpellData] = []
var gold: int = 0
## Casillero del inventario elegido (-1 = ninguno).
var selected_slot: int = -1
var minions: Array[Node3D] = []
var is_dead: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _melee_timer: float = 0.0
## Segundos de recarga restantes por hechizo.
var _cooldowns: Dictionary[SpellData, float] = {}
## Mientras es > 0 el personaje está golpeando o lanzando y no puede moverse.
var _action_lock: float = 0.0
var _spawn_transform: Transform3D
var _base_max_health: int
var _base_max_mana: int

@onready var visual: Node3D = $Visual
@onready var animator: ModelAnimator = $Visual
@onready var health: Health = $Health
@onready var mana: Mana = $Mana
@onready var progression: Progression = $Progression
@onready var inventory: Inventory = $Inventory
@onready var equipment: Equipment = $Equipment


func _ready() -> void:
	_spawn_transform = global_transform
	health.died.connect(_on_died)
	progression.leveled_up.connect(_on_leveled_up)
	_base_max_health = health.max_health
	_base_max_mana = mana.max_mana
	equipment.changed.connect(_recalculate_stats)
	macros.resize(MACRO_COUNT)
	for i in mini(known_spells.size(), MACRO_COUNT):
		macros[i] = known_spells[i]
	_spawn_minions.call_deferred()


func _physics_process(delta: float) -> void:
	_melee_timer = maxf(_melee_timer - delta, 0.0)
	for spell: SpellData in _cooldowns:
		_cooldowns[spell] = maxf(_cooldowns[spell] - delta, 0.0)
	_action_lock = maxf(_action_lock - delta, 0.0)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	if is_dead or _action_lock > 0.0:
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
	if is_dead:
		return
	# Solo para probar la muerte mientras no haya monstruos que peguen.
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo 			and event.keycode == KEY_F9:
		health.take_damage(25, null)
	elif event.is_action_pressed("use_item"):
		use_item(selected_slot)
	elif event.is_action_pressed("melee"):
		_melee()
	elif event.is_action_pressed("cast_spell"):
		_cast_selected_spell()
	else:
		for i in MACRO_COUNT:
			if event.is_action_pressed("spell_%d" % (i + 1)):
				select_macro(i)


func select_macro(index: int) -> void:
	if index < 0 or index >= MACRO_COUNT:
		return
	selected_macro = index
	macro_selected.emit(index)


## Asigna un hechizo conocido a una macro (null la vacía).
func set_macro(index: int, spell: SpellData) -> void:
	if index < 0 or index >= MACRO_COUNT:
		return
	if spell and not known_spells.has(spell):
		return
	macros[index] = spell
	macros_changed.emit()


## 0 = listo para lanzar, 1 = recién lanzado.
func spell_cooldown_ratio(spell: SpellData) -> float:
	if spell == null or spell.cooldown <= 0.0:
		return 0.0
	return _cooldowns.get(spell, 0.0) / spell.cooldown


func select_inventory_slot(index: int) -> void:
	selected_slot = index
	inventory_slot_selected.emit(index)


## Usa el item del casillero: los consumibles se gastan y el equipo se pone
## (lo que estaba puesto vuelve a ese mismo casillero).
func use_item(index: int) -> void:
	var item := inventory.get_item(index)
	if is_dead or item == null:
		return
	if item.kind == ItemData.Kind.CONSUMABLE:
		if item.heal_amount > 0:
			health.heal(item.heal_amount)
		if item.mana_amount > 0:
			mana.restore(item.mana_amount)
		inventory.remove_at(index, 1)
	elif item.is_equipment():
		inventory.remove_at(index)
		var previous := equipment.equip(item)
		if previous:
			inventory.put_at(index, previous)


## Se saca el equipo del slot y lo guarda en el inventario (si hay lugar).
func unequip(slot: ItemData.Kind) -> void:
	var item := equipment.get_equipped(slot)
	if is_dead or item == null or not inventory.has_space_for(item):
		return
	equipment.unequip(slot)
	inventory.add_item(item)


func melee_damage_total() -> int:
	return melee_damage + equipment.total(&"melee_damage_bonus")


func spell_damage_total(spell: SpellData) -> int:
	return spell.damage + equipment.total(&"spell_damage_bonus")


func gain_experience(amount: int) -> void:
	progression.add_experience(amount)
	DamageNumber.spawn_text(get_parent(), global_position + Vector3.UP * 2.3, "+%d exp" % amount, Color(0.62, 0.85, 0.4))


func add_gold(amount: int) -> void:
	gold = maxi(gold + amount, 0)
	gold_changed.emit(gold)


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


func _on_leveled_up(level: int) -> void:
	DamageNumber.spawn_text(get_parent(), global_position + Vector3.UP * 2.8, "¡Nivel %d!" % level, UiStyle.GOLD)
	_recalculate_stats()
	health.reset()
	mana.refill()


## Vida y maná máximos = base + niveles + equipo. La defensa sale del equipo.
func _recalculate_stats() -> void:
	var levels := progression.level - 1
	health.set_max_health(_base_max_health + levels * health_per_level + equipment.total(&"max_health_bonus"))
	mana.set_max_mana(_base_max_mana + levels * mana_per_level + equipment.total(&"max_mana_bonus"))
	health.armor = equipment.total(&"armor")


func _on_died() -> void:
	is_dead = true
	_action_lock = 0.0
	velocity = Vector3.ZERO
	set_target(null)
	animator.play_death()
	died.emit()
	await get_tree().create_timer(respawn_time, false, true).timeout
	_respawn()


func _respawn() -> void:
	var spawn := respawn_point.global_transform if respawn_point else _spawn_transform
	global_position = spawn.origin
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	for i in minions.size():
		var minion := minions[i]
		if is_instance_valid(minion):
			minion.global_position = global_position + formation_offset(i)
			minion.reset_physics_interpolation()
	animator.revive()
	health.reset()
	mana.refill()
	is_dead = false
	respawned.emit()


func _melee() -> void:
	if is_dead or _melee_timer > 0.0 or _action_lock > 0.0:
		return
	_melee_timer = melee_cooldown
	var impact_delay := animator.play_melee()
	_action_lock = impact_delay + 0.1
	await get_tree().create_timer(impact_delay, false, true).timeout
	if is_dead:
		return

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
		Health.of(best).take_damage(melee_damage_total(), self)
		set_target(best)


func _cast_selected_spell() -> void:
	var spell := macros[selected_macro]
	if is_dead or spell == null or projectile_scene == null:
		return
	if _cooldowns.get(spell, 0.0) > 0.0 or _action_lock > 0.0:
		return
	var aim := _mouse_aim()
	if aim.is_empty():
		return

	var direction: Vector3 = aim.point - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	# Como en AO, el maná se gasta al empezar a lanzar.
	if not mana.spend(spell.mana_cost):
		not_enough_mana.emit(spell)
		return
	direction = direction.normalized()
	visual.rotation.y = atan2(direction.x, direction.z)

	_cooldowns[spell] = spell.cooldown
	var release_delay := animator.play_cast(spell)
	_action_lock = release_delay + 0.1
	if aim.target:
		set_target(aim.target)
	await get_tree().create_timer(release_delay, false, true).timeout
	if is_dead:
		return

	var projectile: SpellProjectile = projectile_scene.instantiate()
	projectile.setup(spell, self, direction, spell_damage_total(spell))
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
