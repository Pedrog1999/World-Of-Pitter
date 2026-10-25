class_name HealthBar3D
extends Node3D
## Barra de vida sobre la cabeza de una entidad. Siempre mira a la cámara
## (la cámara del juego no rota, así que alcanza con copiar su orientación).

@export var width: float = 1.0
@export var hide_when_full: bool = true

var _health: Health

@onready var fill: MeshInstance3D = $Relleno


func track(health: Health) -> void:
	_health = health
	health.damaged.connect(_refresh.unbind(2))
	health.healed.connect(_refresh.unbind(1))
	health.died.connect(_refresh)
	_refresh()


func _physics_process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_basis = camera.global_basis


func _refresh() -> void:
	var ratio := float(_health.current) / float(_health.max_health)
	fill.scale.x = maxf(ratio, 0.001)
	fill.position.x = -width * 0.5 * (1.0 - ratio)
	visible = ratio > 0.0 and not (hide_when_full and ratio >= 1.0)
