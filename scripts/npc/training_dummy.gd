class_name TrainingDummy
extends StaticBody3D
## Muñeco de práctica: recibe daño, se tambalea, muestra números de daño,
## se rompe al llegar a 0 y se vuelve a armar después de un rato.

@export var respawn_time: float = 5.0

@onready var health: Health = $Health
@onready var visual: Node3D = $Visual
@onready var health_bar: HealthBar3D = $BarraVida

var _wobble: Tween


func _ready() -> void:
	add_to_group("enemigos")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health_bar.track(health)


func _on_damaged(amount: int, source: Node) -> void:
	DamageNumber.spawn(get_parent(), global_position + Vector3.UP * 2.1, amount)

	var push := Vector3.FORWARD
	if source is Node3D:
		push = global_position - (source as Node3D).global_position
		push.y = 0.0
		push = push.normalized() if push.length_squared() > 0.001 else Vector3.FORWARD
	if _wobble:
		_wobble.kill()
	_wobble = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var tilt := Vector3(push.z, 0.0, -push.x) * 0.3
	_wobble.tween_property(visual, "rotation", tilt, 0.06)
	_wobble.tween_property(visual, "rotation", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_died() -> void:
	$Colision.set_deferred("disabled", true)
	if _wobble:
		_wobble.kill()
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(visual, "rotation:x", -1.4, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "scale", Vector3.ONE * 0.01, 0.25)
	await get_tree().create_timer(respawn_time, false, true).timeout
	visual.rotation = Vector3.ZERO
	health.reset()
	$Colision.set_deferred("disabled", false)
	var back := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	back.tween_property(visual, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
