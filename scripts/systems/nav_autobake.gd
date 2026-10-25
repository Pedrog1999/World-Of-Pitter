extends NavigationRegion3D
## Hornea la malla de navegación al cargar el mapa, así no hay que acordarse de
## re-hornearla en el editor cada vez que se mueve un edificio.
## La geometría sale de los nodos del grupo "navegacion".


func _ready() -> void:
	bake_navigation_mesh.call_deferred(true)
