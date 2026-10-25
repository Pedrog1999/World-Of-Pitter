class_name ModelAnimator
extends Node3D
## Anima un modelo con esqueleto (animaciones de Mixamo): idle o caminar según la
## velocidad, y golpe/hechizo como acciones que se reproducen completas salvo que el
## personaje empiece a moverse. Al morir usa `death_animation` si el modelo la tiene;
## si no, el personaje cae de espaldas.

@export var animation_player: AnimationPlayer
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"caminar"
@export var melee_animation: StringName = &"golpe"
@export var melee_speed: float = 1.6
## Segundo de la animación de golpe (a velocidad normal) en que el arma impacta.
@export var melee_impact_time: float = 0.8
## Velocidad (m/s) a la que la animación de caminar no patina.
@export var walk_natural_speed: float = 1.15
@export var max_walk_speed_scale: float = 2.6
@export var blend_time: float = 0.15
@export var death_animation: StringName = &"muerte"

var _speed: float = 0.0
var _action_left: float = 0.0
var _dead: bool = false
var _death_tween: Tween


func _ready() -> void:
	for anim_name in [idle_animation, walk_animation, &"idle_mago"]:
		if animation_player.has_animation(anim_name):
			animation_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	animation_player.play(idle_animation)


## Velocidad horizontal actual del personaje en m/s.
func set_move_speed(speed: float) -> void:
	_speed = speed


func is_busy() -> bool:
	return _action_left > 0.0


## Corta la acción en curso (por ejemplo, si el jugador empieza a caminar).
func cancel_action() -> void:
	_action_left = 0.0


## Reproduce el golpe y devuelve cuántos segundos faltan para el impacto.
func play_melee() -> float:
	_play_action(melee_animation, melee_speed)
	return melee_impact_time / melee_speed


## Reproduce la animación del hechizo y devuelve cuántos segundos faltan para lanzarlo.
func play_cast(spell: SpellData) -> float:
	_play_action(spell.animation, spell.animation_speed)
	return spell.release_time / spell.animation_speed


func play_death() -> void:
	_dead = true
	_action_left = 0.0
	if animation_player.has_animation(death_animation):
		animation_player.speed_scale = 1.0
		animation_player.play(death_animation, blend_time)
		return
	animation_player.pause()
	_kill_death_tween()
	_death_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_death_tween.tween_property(self, "rotation:x", -PI * 0.5, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Vuelve a dejar al personaje de pie (al reaparecer).
func revive() -> void:
	_dead = false
	_kill_death_tween()
	rotation.x = 0.0
	animation_player.speed_scale = 1.0
	animation_player.play(idle_animation)


func _kill_death_tween() -> void:
	if _death_tween:
		_death_tween.kill()
		_death_tween = null


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _action_left > 0.0:
		_action_left -= delta
		return
	if _speed > 0.2:
		_play_loop(walk_animation)
		animation_player.speed_scale = clampf(_speed / walk_natural_speed, 0.5, max_walk_speed_scale)
	else:
		_play_loop(idle_animation)
		animation_player.speed_scale = 1.0


func _play_loop(anim_name: StringName) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, blend_time)


func _play_action(anim_name: StringName, speed: float) -> void:
	if not animation_player.has_animation(anim_name):
		push_warning("Falta la animación '%s'" % anim_name)
		return
	animation_player.speed_scale = speed
	animation_player.play(anim_name, blend_time)
	animation_player.seek(0.0, true)
	_action_left = animation_player.get_animation(anim_name).length / speed
