class_name SpellProjectile
extends Area3D
## Proyectil de hechizo: vuela en línea recta, daña al primer enemigo que toca
## y se deshace al chocar contra el mundo o al llegar a su alcance máximo.

var spell: SpellData
var caster: Node3D
var direction: Vector3 = Vector3.FORWARD

var _traveled: float = 0.0

@onready var mesh: MeshInstance3D = $Malla
@onready var light: OmniLight3D = $Luz


func setup(p_spell: SpellData, p_caster: Node3D, p_direction: Vector3) -> void:
	spell = p_spell
	caster = p_caster
	direction = p_direction.normalized()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = spell.color
	mat.emission_enabled = true
	mat.emission = spell.color
	mat.emission_energy_multiplier = 4.0
	mesh.material_override = mat
	light.light_color = spell.color
	scale = Vector3.ONE * spell.projectile_scale


func _physics_process(delta: float) -> void:
	var step := direction * spell.speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= spell.max_range:
		_vanish()


func _on_body_entered(body: Node3D) -> void:
	if body == caster:
		return
	var health := Health.of(body)
	if health and not health.is_dead:
		health.take_damage(spell.damage, caster)
		if is_instance_valid(caster) and caster.has_method("set_target"):
			caster.set_target(body)
	_vanish()


func _vanish() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.12)
	tween.tween_callback(queue_free)
