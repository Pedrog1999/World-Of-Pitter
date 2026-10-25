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
- **Controles**: Ctrl = golpe cuerpo a cuerpo; 1-9 = elegir macro de hechizo; clic izquierdo =
  lanzar el hechizo elegido hacia el mouse; clic derecho = interactuar (tiendas, NPCs, etc.);
  U = usar el item elegido del inventario (o doble clic); E = juntar del suelo; T = tirar uno
  (Shift+T = todo el casillero). F9 hace daño al jugador solo en builds de debug (para pruebas).
- **Personaje principal: nigromante** (`assets/models/personajes/nigromante/nigromante.glb`).
  Pipeline: imagen de referencia → TRELLIS (IA imagen a 3D, licencia MIT) → Mixamo (esqueleto y
  animaciones) → `tools/blender/nigromante_mixamo_a_glb.py` (separa el bastón y lo ata a la mano,
  deja "caminar" en el lugar, junta todo en un GLB con huesos sin el prefijo `mixamorig:`).
  `ModelAnimator` elige idle/caminar por velocidad y reproduce golpe/hechizos; cada `SpellData`
  dice qué animación usa y en qué segundo sale el proyectil. Más adelante el equipo (armas,
  cascos) se engancha a huesos con `BoneAttachment3D`.
- **No simplificar (decimate) modelos generados por IA después de exportarlos**: vienen cortados
  en las costuras de textura y se agrietan. Si hace falta menos polígonos, pedirlo al extraer en TRELLIS.
- **Esbirros**: por ahora 3 esqueletos permanentes que siguen al nigromante y atacan al último
  objetivo que él golpeó o clickeó. Más adelante un hechizo invocará más o los cambiará (ej. lobos)
  vía `Player.set_minions()`.
- **Capas de física**: 1 mundo, 2 jugador, 3 esbirros, 4 enemigos. Lo atacable va en el grupo
  `enemigos` y tiene un nodo hijo `Health`.
- **Navegación**: el mapa hornea la navmesh al cargar a partir de los nodos del grupo `navegacion`.
- **Terreno medianamente llano**: pendientes suaves (< 25–30°) que se suben caminando. Los cambios de
  altura van por rampas o escaleras (con una rampa de colisión invisible debajo de los escalones).
  Barrancos, rocas o agua funcionan como bordes naturales en lugar de paredes invisibles.
- **Interiores visibles** (como en AO): al entrar a un edificio, el techo y los pisos superiores se
  desvanecen y las paredes del lado de la cámara quedan traslúcidas.
- **Oclusión**: si un edificio tapa al jugador desde la cámara, ese edificio se vuelve traslúcido.
- Assets base: Quaternius Medieval Village MegaKit (CC0) en `assets/models/medieval_village/`,
  piezas modulares en grilla de 2 m (paredes de 2×3 m).

## Próximos pasos (plan acordado)

Hacer en este orden; cada paso jugable, con commit + push al terminar:

1. ✅ **Vida y maná del jugador**: los hechizos gastan maná (agregar `mana_cost` a `SpellData`),
   regeneración, muerte y reaparición en la plaza.
2. ✅ **Interfaz estilo AO con paneles fijos a la derecha** de la pantalla (el juego ocupa el resto;
   la cámara se corre con `set_right_margin` para centrar al personaje en la zona visible):
   - Arriba de todo: **datos personales** (nombre, clase, nivel y experiencia).
   - Debajo: pestañas **Inventario / Hechizos**. En Hechizos, la lista de hechizos conocidos que se
     asignan a las macros 1-9.
   - Medio: **stats** (vida, maná, oro).
   - Abajo: **minimapa**.
   - Mantener la estética oscura medieval (marcos de madera/piedra, texto claro). La barra de
     hechizos actual (`scripts/ui/hud.gd`) se integra a este panel.
3. ✅ **Inventario y equipo**: grilla de items, oro, slots de equipo (arma, casco, armadura, escudo)
   que modifican stats. Items como `Resource` en `data/items/`.
4. ✅ **Items en el mundo**: monstruos/muñecos que sueltan items, juntar con una tecla, tirar.

**Pendiente: pulir el diseño de la interfaz.** Ya usa las texturas del pack RPG Inventory
(`assets/textures/ui/rpg_inventory/`). Faltan una fuente con carácter, íconos de items y hechizos,
y más jerarquía visual en el panel derecho.

### Ideas para la próxima sesión (anotadas el 2026-10-25)

- **Macros de hechizos**: que el jugador elija en qué macro numérica (1-9) pone cada hechizo de
  forma más directa. Hoy se hace con clic en el hechizo y después en la macro; mejorar ese flujo
  (por ejemplo arrastrar, o elegir el hechizo y apretar el número).
- **Maná**: acortar la regeneración pasiva de maná y agregar el comando **/meditar**: el personaje
  se sienta a meditar (sin poder moverse ni atacar) y recarga maná mucho más rápido. Hace falta
  una consola o caja de chat para escribir comandos.
- **Imágenes de items**: íconos de verdad para el inventario (y hechizos) en lugar del cuadro de
  color con iniciales; cada `ItemData` ya tiene el campo `icon`.
- **Nivel y experiencia**: revisar la curva de experiencia, qué da cada nivel (vida, maná,
  daño...), y fuentes de experiencia además de los muñecos.
- **Terminar el pueblo principal** (Villa Pitter): casas, calles, plaza, taberna, herrería,
  templo, cementerio, muralla y bosque alrededor.
- **Templo de reaparición**: al morir, el personaje reaparece en el templo (asignar un
  `Marker3D` del templo a `respawn_point`) y se muestra un **toast** (aviso que aparece y se va
  solo) avisando que fue resucitado / que se está regenerando.

Después: la ciudad (Villa Pitter completa, faltan packs de props/naturaleza) y monstruos reales.

## Estructura de carpetas

```
scenes/       Escenas .tscn
  world/        Mapas y zonas (Villa Pitter, dungeons...)
  characters/   Jugador, NPCs, enemigos
  props/        Objetos del mundo (casas, árboles, antorchas, cofres)
  ui/           HUD, menús, inventario, diálogos
  effects/      Proyectiles y efectos
data/         Datos de juego como Resources .tres (hechizos, items, clases...)
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
