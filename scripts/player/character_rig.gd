class_name CharacterRig
extends Node3D
## Animación procedural para personajes armados con primitivas (nigromante, esqueletos):
## balanceo de piernas y brazos al caminar, respiración en reposo, golpe y lanzamiento.
## Las extremidades son pivotes en hombros/caderas; rotar en X las mueve adelante/atrás.
## Todo corre en el paso de física para llevarse bien con la interpolación física.

@export var left_leg: Node3D
@export var right_leg: Node3D
@export var left_arm: Node3D
@export var right_arm: Node3D
## Parte superior del cuerpo; sube y baja con cada paso.
@export var body: Node3D
@export var stride_degrees: float = 32.0
@export var step_frequency: float = 9.0
@export var bob_height: float = 0.05

var _move_amount: float = 0.0
var _phase: float = 0.0
var _right_arm_busy: bool = false
var _action_tween: Tween
var _body_base_y: float = 0.0


func _ready() -> void:
	if body:
		_body_base_y = body.position.y


## 0 = quieto, 1 = caminando a velocidad máxima.
func set_move_amount(amount: float) -> void:
	_move_amount = clampf(amount, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	_phase += delta * step_frequency * (0.25 + _move_amount)
	var swing := sin(_phase) * deg_to_rad(stride_degrees) * _move_amount
	if left_leg:
		left_leg.rotation.x = swing
	if right_leg:
		right_leg.rotation.x = -swing
	if left_arm:
		left_arm.rotation.x = -swing * 0.8
	if right_arm and not _right_arm_busy:
		right_arm.rotation.x = swing * 0.8
	if body:
		var step_bob := absf(sin(_phase)) * bob_height * _move_amount
		var breath := sin(_phase * 0.35) * 0.012 * (1.0 - _move_amount)
		body.position.y = _body_base_y + step_bob + breath


## Golpe por encima de la cabeza hacia adelante. Dura ~0.55 s; el impacto es a ~0.2 s.
func play_melee() -> void:
	_start_right_arm_action()
	_action_tween.tween_property(right_arm, "rotation:x", -2.2, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_action_tween.tween_property(right_arm, "rotation:x", 0.5, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_action_tween.tween_interval(0.1)
	_action_tween.tween_property(right_arm, "rotation:x", 0.0, 0.25)
	_action_tween.tween_callback(func() -> void: _right_arm_busy = false)


## Levanta el arma hacia adelante para lanzar un hechizo.
func play_cast() -> void:
	_start_right_arm_action()
	_action_tween.tween_property(right_arm, "rotation:x", -1.3, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_action_tween.tween_interval(0.15)
	_action_tween.tween_property(right_arm, "rotation:x", 0.0, 0.25)
	_action_tween.tween_callback(func() -> void: _right_arm_busy = false)


func _start_right_arm_action() -> void:
	if _action_tween:
		_action_tween.kill()
	_right_arm_busy = true
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
