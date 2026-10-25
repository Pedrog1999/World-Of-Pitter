class_name ItemData
extends Resource
## Datos de un item. Cada item es un .tres en data/items/.
## El equipo suma sus bonificaciones a los stats del portador mientras está puesto;
## los consumibles se gastan al usarlos.

enum Kind { MISC, CONSUMABLE, WEAPON, HELMET, ARMOR, SHIELD }

const KIND_NAMES := {
	Kind.MISC: "Objeto",
	Kind.CONSUMABLE: "Consumible",
	Kind.WEAPON: "Arma",
	Kind.HELMET: "Casco",
	Kind.ARMOR: "Armadura",
	Kind.SHIELD: "Escudo",
}

@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.MISC
## Ícono del inventario. Sin ícono se dibuja un cuadro de `color` con las iniciales.
@export var icon: Texture2D
@export var color: Color = Color(0.6, 0.55, 0.45)
@export var max_stack: int = 1
## Precio base en oro.
@export var value: int = 1

@export_group("Equipo")
@export var melee_damage_bonus: int = 0
@export var spell_damage_bonus: int = 0
@export var armor: int = 0
@export var max_health_bonus: int = 0
@export var max_mana_bonus: int = 0

@export_group("Consumible")
@export var heal_amount: int = 0
@export var mana_amount: int = 0


func is_equipment() -> bool:
	return kind in [Kind.WEAPON, Kind.HELMET, Kind.ARMOR, Kind.SHIELD]


## Iniciales para el ícono provisorio ("Poción roja" -> "PR").
func initials() -> String:
	var result := ""
	for word in display_name.split(" ", false):
		if word.length() > 2 or result.is_empty():
			result += word[0].to_upper()
	return result.substr(0, 2)


## Texto para el tooltip: nombre, tipo, efectos y descripción.
func tooltip() -> String:
	var lines: Array[String] = ["%s  (%s)" % [display_name, KIND_NAMES[kind]]]
	var effects := {
		"Golpe": melee_damage_bonus,
		"Hechizos": spell_damage_bonus,
		"Defensa": armor,
		"Vida máx.": max_health_bonus,
		"Maná máx.": max_mana_bonus,
		"Cura": heal_amount,
		"Maná": mana_amount,
	}
	for effect: String in effects:
		if effects[effect] != 0:
			lines.append("%s %+d" % [effect, effects[effect]])
	if not description.is_empty():
		lines.append(description)
	lines.append("Valor: %d oro" % value)
	return "\n".join(lines)
