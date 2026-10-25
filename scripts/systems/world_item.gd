class_name WorldItem
extends Node3D
## Item tirado en el suelo (o una pila de oro si `item` es null). El jugador lo junta
## estando cerca. Brilla un poco para que se vea de noche y muestra su nombre.

# Se carga al tirar (y no con preload) porque la escena usa este mismo script.
const SCENE_PATH := "res://scenes/props/item_suelo.tscn"
const GROUP := &"items_suelo"

var item: ItemData
var amount: int = 1

@onready var mesh: MeshInstance3D = $Malla
@onready var label: Label3D = $Nombre


## Tira `amount` de `item` (null = oro) en `pos`, con un pequeño desparramo.
static func drop(parent: Node, pos: Vector3, p_item: ItemData, p_amount: int, scatter: float = 0.0) -> WorldItem:
	var world_item: WorldItem = load(SCENE_PATH).instantiate()
	world_item.item = p_item
	world_item.amount = p_amount
	parent.add_child(world_item)
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, scatter)
	world_item.global_position = Vector3(pos.x + offset.x, pos.y, pos.z + offset.y)
	world_item.rotation.y = randf() * TAU
	return world_item


func _ready() -> void:
	add_to_group(GROUP)
	var color := UiStyle.GOLD if item == null else item.color
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.35
	material.roughness = 0.7
	mesh.mesh = _make_mesh()
	mesh.material_override = material
	label.modulate = color.lerp(Color.WHITE, 0.5)
	refresh_label()


func display_name() -> String:
	return "Oro" if item == null else item.display_name


func refresh_label() -> void:
	label.text = display_name() if amount <= 1 else "%s (%d)" % [display_name(), amount]


## Forma low-poly según el tipo: monedas, frasco o bulto.
func _make_mesh() -> Mesh:
	if item == null:
		var coins := CylinderMesh.new()
		coins.top_radius = 0.16
		coins.bottom_radius = 0.2
		coins.height = 0.1
		coins.radial_segments = 8
		coins.rings = 1
		mesh.position.y = 0.05 * mesh.scale.y
		return coins
	if item.kind == ItemData.Kind.CONSUMABLE:
		var flask := SphereMesh.new()
		flask.radius = 0.13
		flask.height = 0.3
		flask.radial_segments = 8
		flask.rings = 4
		mesh.position.y = 0.15 * mesh.scale.y
		return flask
	var bundle := BoxMesh.new()
	bundle.size = Vector3(0.4, 0.12, 0.28) if item.is_equipment() else Vector3(0.3, 0.08, 0.12)
	mesh.position.y = bundle.size.y * 0.5 * mesh.scale.y
	return bundle
