"""Lay MK2 parts flat for printing: pick the axis-aligned orientation with the largest face on the bed.

Usage: python -I prep_print.py <placed dir> <out dir>
Reads ASCII STL meshes (assembly position), writes binary STL with the part on Z = 0, centred in X/Y.
"""
import os, re, struct, sys

# placed mesh, output name, quantity, forced bed-face direction (None = automatic)
HERE = os.path.dirname(os.path.abspath(__file__))
PARTS = [
    (os.path.join(HERE, 'x_end_motor_4screw'), 'x_end_motor', 1, '-z'),   # MK2 part + 4th motor screw
    ('X-END-IDLER_1', 'x_end_idler', 1, '-z'),
    ('Assembly_1_1___X-CARRIAGE_1', 'x_carriage', 1, None),
    ('Assembly_1_1___EXTRUDER-BODY_1', 'extruder_body', 1, '-y'),
    ('Assembly_1_1___EXTRUDER-COVER_1', 'extruder_cover', 1, None),
    ('Assembly_1_1___EXTRUDER-IDLER_1', 'extruder_idler', 1, None),
    ('Assembly_1_1___FAN-NOZZLE_1', 'fan_nozzle', 1, None),
    ('Z-AXIS-BOTTOM-LEFT-M_1', 'z_bottom_left', 1, '+z'),
    ('Z-AXIS-BOTTOM-RIGHT-M_1', 'z_bottom_right', 1, '+z'),
    ('Z-AXIS-TOP_RIGHT-M_1', 'z_top', 2, None),
    ('Part6_1', 'y_idler_holder', 1, None),
    ('Y-BELT-HOLDER_1', 'y_belt_holder', 1, None),
    ('y_bearing_holder_1', 'y_bearing_holder', 3, None),
    ('UchyceniTyce8mm_v30-4ks_1', 'y_rod_clamp', 4, None),
    ('Part_1_2', 'frame_foot', 4, None),
    ('Part_1_3', 'frame_base_corner', 4, None),
    ('Part_1_12', 'frame_top_gusset', 2, None),
    ('Part_1_22', 'frame_top_corner_left', 1, None),
    ('Part_1_15', 'frame_top_corner_right', 1, None),
    ('Part_1_8', 'frame_z_adapter_left', 1, None),
    ('Part_1_9', 'frame_z_adapter_right', 1, None),
]

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
DIRS = {'-z': (2, -1), '+z': (2, 1), '-x': (0, -1), '+x': (0, 1), '-y': (1, -1), '+y': (1, 1)}

def read(f):
    t = open(f).read()
    v = [tuple(map(float, m.groups())) for m in re.finditer(r'vertex\s+(\S+)\s+(\S+)\s+(\S+)', t)]
    return [v[i:i + 3] for i in range(0, len(v), 3)]

def area(t):
    a = [t[1][k] - t[0][k] for k in range(3)]; b = [t[2][k] - t[0][k] for k in range(3)]
    c = (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
    return (c[0]**2 + c[1]**2 + c[2]**2) ** 0.5 / 2

def contact(tris, ax, sgn):
    ext = (min if sgn < 0 else max)(p[ax] for t in tris for p in t)
    return sum(area(t) for t in tris if all(abs(p[ax] - ext) < 0.05 for p in t))

def to_bed(p, ax, sgn):
    """Rotate so that direction (ax, sgn) points to -Z."""
    x, y, z = p
    return {('z', -1): (x, y, z), ('z', 1): (x, -y, -z), ('x', -1): (-z, y, x), ('x', 1): (z, y, -x),
            ('y', -1): (x, -z, y), ('y', 1): (x, z, -y)}['xyz'[ax], sgn]

report = []
for name, oname, qty, force in PARTS:
    tris = read(os.path.join(src, name + '.stl'))
    if force:
        ax, sgn = DIRS[force]
    else:
        ax, sgn = max(DIRS.values(), key=lambda d: contact(tris, *d))
    tris = [[to_bed(p, ax, sgn) for p in t] for t in tris]
    lo = [min(p[k] for t in tris for p in t) for k in range(3)]; hi = [max(p[k] for t in tris for p in t) for k in range(3)]
    off = [-(lo[0] + hi[0]) / 2, -(lo[1] + hi[1]) / 2, -lo[2]]
    with open(os.path.join(out, oname + '.stl'), 'wb') as f:
        f.write(b'MK2-2020 part, laid flat'.ljust(80, b' ')); f.write(struct.pack('<I', len(tris)))
        for t in tris:
            q = [[p[k] + off[k] for k in range(3)] for p in t]
            f.write(struct.pack('<12fH', 0, 0, 0, *q[0], *q[1], *q[2], 0))
    report.append(f'{oname:24s} x{qty}  {hi[0]-lo[0]:5.1f} x {hi[1]-lo[1]:5.1f} x {hi[2]-lo[2]:5.1f} mm')
print('\n'.join(report))
