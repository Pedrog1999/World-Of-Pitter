class_name SpellData
extends Resource
## Datos de un hechizo de proyectil. Cada hechizo es un .tres en data/hechizos/.

@export var display_name: String = "Hechizo"
@export var damage: int = 5
@export var mana_cost: int = 5
@export var cooldown: float = 0.6
@export var speed: float = 16.0
@export var max_range: float = 18.0
@export var color: Color = Color(0.45, 1.0, 0.35)
@export var projectile_scale: float = 1.0

@export_group("Animación")
## Animación del lanzador (nombre dentro del modelo).
@export var animation: StringName = &"hechizo_1h_cast_spell_01"
@export var animation_speed: float = 1.0
## Segundo de la animación (a velocidad normal) en que sale el proyectil.
@export var release_time: float = 0.8
