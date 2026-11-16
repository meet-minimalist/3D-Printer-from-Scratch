"""Move each STL so that it sits on Z = 0, centred on X = Y = 0 (for print files). Reads ASCII or binary STL.
Usage: python -I center_stl.py <file.stl> [...]
"""
import re, struct, sys

def read(f):
    d = open(f, 'rb').read()
    if d[:5] == b'solid' and b'facet' in d[:400]:
        v = [tuple(map(float, m)) for m in re.findall(rb'vertex\s+(\S+)\s+(\S+)\s+(\S+)', d)]
        return [v[i:i + 3] for i in range(0, len(v), 3)]
    n = struct.unpack_from('<I', d, 80)[0]
    return [[struct.unpack_from('<3f', d, 84 + 50 * i + 12 + 12 * k) for k in range(3)] for i in range(n)]

for f in sys.argv[1:]:
    t = read(f)
    lo = [min(p[k] for q in t for p in q) for k in range(3)]; hi = [max(p[k] for q in t for p in q) for k in range(3)]
    off = [-(lo[0] + hi[0]) / 2, -(lo[1] + hi[1]) / 2, -lo[2]]
    with open(f, 'wb') as o:
        o.write(b'print file, centred'.ljust(80, b' ')); o.write(struct.pack('<I', len(t)))
        for q in t:
            o.write(struct.pack('<12fH', 0, 0, 0, *[p[k] + off[k] for p in q for k in range(3)], 0))
    print(f'{f.split("/")[-1]:36s} {hi[0]-lo[0]:6.1f} x {hi[1]-lo[1]:6.1f} x {hi[2]-lo[2]:5.1f} mm')
