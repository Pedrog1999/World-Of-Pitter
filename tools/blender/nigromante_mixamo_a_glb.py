import bpy, sys, os, time
from mathutils import Vector

T0 = time.time()
def log(*a):
    print("[%.1fs]" % (time.time() - T0), *a, flush=True)

argv = sys.argv[sys.argv.index("--") + 1:]
char_fbx, out_glb, pack_dir, loose_dir = argv

# nombre en el juego -> archivo
ANIMS = {
    "idle": (loose_dir, "Mutant Idle.fbx"),
    "caminar": (loose_dir, "Mutant Walking.fbx"),
    "golpe": (loose_dir, "Standing Torch Melee Attack 01.fbx"),
    "idle_mago": (pack_dir, "standing idle.fbx"),
}
for f in sorted(os.listdir(pack_dir)):
    if f.lower().startswith("standing") and f != "standing idle.fbx":
        name = f[:-4].lower().replace("standing ", "").replace(" ", "_")
        ANIMS["hechizo_" + name] = (pack_dir, f)


def fcurves_of(action):
    if hasattr(action, "fcurves") and len(action.fcurves):
        return list(action.fcurves)
    out = []
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                out += list(bag.fcurves)
    return out


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=char_fbx)
arm = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
arm.name = "Nigromante"
for img in bpy.data.images:
    log("imagen", img.name, tuple(img.size), "packed" if img.packed_file else img.filepath)
if arm.animation_data and arm.animation_data.action:
    arm.animation_data.action = None
log("personaje importado")

# El bastón vino fusionado al cuerpo y Mixamo lo repartió entre mano, cadera y pierna.
# Se detectan sus vértices por geometría (palo vertical al costado + calavera y cristal
# arriba) y se atan 100% a la mano que lo sostiene.
mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
mw = mesh.matrix_world
co = [mw @ v.co for v in mesh.data.vertices]
def mean(pts):
    return sum(pts, Vector()) / len(pts)
def axis_dist(c, a, b):
    ax = (b - a).normalized()
    d = c - a
    return (d - ax * d.dot(ax)).length
# Eje = punta de abajo del bastón (al costado de la bota) -> cristal (punto más alto).
top_z = max(c.z for c in co)
tip = [c for c in co if 0.15 < c.z < 0.3 and c.x > 0.2 and -0.14 < c.y < -0.05]
crystal = [c for c in co if c.z > top_z - 0.12]
p0, p1 = mean(tip), mean(crystal)
lower = [c for c in co if 0.1 < c.z < 0.3 and axis_dist(c, p0, p1) < 0.06]
log("eje del baston", tuple(round(v, 3) for v in p0), "->", tuple(round(v, 3) for v in p1), "puntos", len(tip), len(crystal), len(lower))
# Radio real del palo: percentil 90 de las distancias en el tramo bajo.
radii = sorted(axis_dist(c, p0, p1) for c in lower)
pole_r = radii[int(len(radii) * 0.9)] + 0.004
log("radio del palo", round(pole_r, 3))
STAFF_BONE = os.environ.get("STAFF_BONE", "mixamorig:LeftHand")
# Caras completamente dentro del palo (o de la calavera/cristal arriba) = bastón.
inside = [axis_dist(c, p0, p1) < pole_r or (c.z > 1.4 and axis_dist(c, p0, p1) < 0.16) for c in co]
for v in mesh.data.vertices:
    v.select = False
for e in mesh.data.edges:
    e.select = False
count = 0
for p in mesh.data.polygons:
    p.select = all(inside[i] for i in p.vertices)
    count += p.select
log("caras del baston", count)
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.context.tool_settings.mesh_select_mode = (False, False, True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.separate(type='SELECTED')
bpy.ops.object.mode_set(mode='OBJECT')
staff_obj = next(o for o in bpy.context.scene.objects if o.type == 'MESH' and o != mesh)
staff_obj.name = "Baston"
all_idx = [v.index for v in staff_obj.data.vertices]
hand_group = staff_obj.vertex_groups.get(STAFF_BONE)
for g in staff_obj.vertex_groups:
    if g != hand_group:
        g.remove(all_idx)
hand_group.add(all_idx, 1.0, 'REPLACE')
log("baston separado y atado a", STAFF_BONE, ":", len(all_idx), "vertices")

actions = {}
for name, (d, f) in ANIMS.items():
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(d, f))
    new = set(bpy.context.scene.objects) - before
    src_arm = next(o for o in new if o.type == 'ARMATURE')
    act = src_arm.animation_data.action
    act.name = name
    act.use_fake_user = True
    actions[name] = act
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)

# Caminar en el lugar: quitar el avance lineal de la cadera conservando el balanceo.
for c in fcurves_of(actions["caminar"]):
    if c.data_path == 'pose.bones["mixamorig:Hips"].location':
        k = c.keyframe_points
        v0, v1 = k[0].co[1], k[-1].co[1]
        f0, f1 = k[0].co[0], k[-1].co[0]
        if abs(v1 - v0) > 20:
            for p in k:
                t = (p.co[0] - f0) / (f1 - f0)
                p.co[1] -= (v1 - v0) * t
                p.handle_left[1] -= (v1 - v0) * t
                p.handle_right[1] -= (v1 - v0) * t
            log("caminar: avance quitado en eje", c.array_index, round(v1 - v0, 1))

# Medir momentos clave: impacto del golpe y salida de cada hechizo.
ad = arm.animation_data_create()
scene = bpy.context.scene
def bone_world(b):
    return arm.matrix_world @ arm.pose.bones[b].head

for name, act in actions.items():
    ad.action = act
    if hasattr(ad, "action_slot") and act.slots:
        ad.action_slot = act.slots[0]
    f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
    best_f, best_v = f0, -1.0
    prev = None
    for fr in range(f0, f1 + 1):
        scene.frame_set(fr)
        hips = bone_world("mixamorig:Hips")
        hand = bone_world("mixamorig:RightHand")
        if name == "golpe":
            # impacto = momento de mayor velocidad de la mano hacia abajo
            if prev is not None:
                v = prev.z - hand.z
                if v > best_v:
                    best_v, best_f = v, fr
            prev = hand.copy()
        elif name.startswith("hechizo"):
            # salida = mano más extendida lejos de la cadera
            dist = (hand - hips).length
            left = bone_world("mixamorig:LeftHand")
            dist = max(dist, (left - hips).length) if "2h" in name else dist
            if dist > best_v:
                best_v, best_f = dist, fr
    log("ANIM %-32s frames %d-%d dur=%.2fs  momento_clave=%.2fs" % (name, f0, f1, (f1 - f0) / 30.0, (best_f - f0) / 30.0))

ad.action = None
for name, act in actions.items():
    track = ad.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(act.frame_range[0]), act)
    track.mute = True

# Nombres de huesos sin "mixamorig:" (los dos puntos confunden a las rutas de Godot).
for b in arm.data.bones:
    b.name = b.name.replace("mixamorig:", "")
log("huesos renombrados")

bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB', export_animation_mode='ACTIONS',
                          export_force_sampling=True, export_frame_range=False)
log("glb exportado")
