# World of Pitter

RPG 3D low-poly inspirado en **Argentum Online**, hecho en **Godot 4.7** (Forward+, física Jolt, GDScript).
El juego arranca en **Villa Pitter**, un pueblo medieval oscuro.

## Visión y estilo

- **Inspiración**: Argentum Online — cámara cenital/isométrica fija sobre el personaje, mundo abierto
  con ciudades, dungeons y zonas salvajes, combate cuerpo a cuerpo y magia, clases, NPCs comerciantes,
  inventario, oro y progresión por niveles.
- **Estética**: low-poly, pocos polígonos, colores planos o texturas de paleta chica (sin texturas realistas).
- **Tono**: medieval oscuro. Paleta desaturada (grises, marrones, verdes musgo, azules fríos) con acentos
  cálidos de antorchas, faroles y fuego. Niebla, noche y luz tenue son parte de la identidad visual.
- **Villa Pitter**: casas de madera y piedra, calles de tierra/adoquín, taberna, herrería, templo, plaza
  central, cementerio en las afueras, muralla o empalizada y bosque oscuro alrededor.

## Decisiones de jugabilidad

- Movimiento con **WASD/flechas en 8 direcciones**, relativo a los ejes del mundo (arriba = -Z).
- **Cámara fija**: ángulo cenital sin rotación, solo zoom con la rueda del mouse.
- **Sin salto y sin correr**: una sola velocidad de caminata.
- **Terreno medianamente llano**: pendientes suaves (< 25–30°) que se suben caminando. Los cambios de
  altura van por rampas o escaleras (con una rampa de colisión invisible debajo de los escalones).
  Barrancos, rocas o agua funcionan como bordes naturales en lugar de paredes invisibles.
- **Interiores visibles** (como en AO): al entrar a un edificio, el techo y los pisos superiores se
  desvanecen y las paredes del lado de la cámara quedan traslúcidas.
- **Oclusión**: si un edificio tapa al jugador desde la cámara, ese edificio se vuelve traslúcido.
- Assets base: Quaternius Medieval Village MegaKit (CC0) en `assets/models/medieval_village/`,
  piezas modulares en grilla de 2 m (paredes de 2×3 m).

## Estructura de carpetas

```
scenes/       Escenas .tscn
  world/        Mapas y zonas (Villa Pitter, dungeons...)
  characters/   Jugador, NPCs, enemigos
  props/        Objetos del mundo (casas, árboles, antorchas, cofres)
  ui/           HUD, menús, inventario, diálogos
scripts/      Scripts .gd (espejan la organización de scenes cuando aplica)
  player/       Movimiento, cámara, input, stats del jugador
  npc/          IA, diálogos, comerciantes, enemigos
  systems/      Combate, inventario, items, hechizos, guardado
  ui/           Lógica de interfaz
  autoload/     Singletons globales (GameState, EventBus, etc.)
assets/       Recursos importados
  models/  textures/  materials/  shaders/  fonts/
  audio/music/  audio/sfx/
```

## Convenciones de código (GDScript)

- Seguir la guía de estilo oficial de GDScript: tabs para indentar, `snake_case` para variables,
  funciones y archivos; `PascalCase` para `class_name` y nodos; `CONSTANTES_EN_MAYUSCULA`.
- Tipado estático siempre que se pueda (`var vida: int = 100`, `func atacar(objetivo: Node3D) -> void:`).
- Usar `class_name` en scripts reutilizables y `@export` para valores ajustables desde el editor.
- Comunicación entre sistemas con **señales** (o un `EventBus` autoload) en lugar de referencias rígidas.
- Datos de juego (items, hechizos, clases, NPCs) como `Resource` personalizados (`.tres`), no hardcodeados.
- Un script por escena principal; nombre del script igual al de la escena (`player.tscn` ↔ `player.gd`).
- Rutas con `res://` y nombres de archivo en minúscula sin espacios.

## Notas para Claude

- Idioma: hablar en español (rioplatense) con el usuario. Nombres de código pueden ir en inglés o
  español, pero mantener consistencia con lo que ya exista en el archivo.
- Respetar siempre la estética low-poly medieval oscura al proponer escenas, materiales, iluminación o UI.
- `project.godot` y los `.tscn` los maneja principalmente el editor: editarlos a mano solo cuando sea
  necesario y con cuidado.
- `.godot/` es caché del editor y no se versiona.
