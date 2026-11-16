"""Read a B-rep STEP assembly; print the product tree and export each unique part to STL.

Usage: python step_tree.py <in.stp> <out_dir>
Writes <out_dir>/parts/<name>.stl (part in its own frame) and <out_dir>/placed/<path>.stl (in assembly frame).
"""
import os, re, sys
from OCP.STEPCAFControl import STEPCAFControl_Reader
from OCP.TDocStd import TDocStd_Document
from OCP.TCollection import TCollection_ExtendedString
from OCP.XCAFDoc import XCAFDoc_DocumentTool
from OCP.TDF import TDF_Label
from OCP.collections import Sequence_TDF_Label as TDF_LabelSequence
from OCP.TDataStd import TDataStd_Name
from OCP.TopLoc import TopLoc_Location
from OCP.BRepMesh import BRepMesh_IncrementalMesh
from OCP.StlAPI import StlAPI_Writer
from OCP.Bnd import Bnd_Box
from OCP.BRepBndLib import BRepBndLib

src, out = sys.argv[1], sys.argv[2]
os.makedirs(os.path.join(out, 'parts'), exist_ok=True)
os.makedirs(os.path.join(out, 'placed'), exist_ok=True)

doc = TDocStd_Document(TCollection_ExtendedString('doc'))
r = STEPCAFControl_Reader()
r.SetNameMode(True)
assert r.ReadFile(src) == 1
r.Transfer(doc)
st = XCAFDoc_DocumentTool.ShapeTool_s(doc.Main())

def name(lab):
    a = TDataStd_Name()
    return a.Get().ToExtString() if lab.FindAttribute(TDataStd_Name.GetID_s(), a) else '?'

def safe(s): return re.sub(r'[^\w.-]+', '_', s).strip('_')

def bbox(shape):
    b = Bnd_Box(); BRepBndLib.Add_s(shape, b)
    (x0, y0, z0), (x1, y1, z1) = [(q.X(), q.Y(), q.Z()) for q in (b.CornerMin(), b.CornerMax())]
    return f'[{x0:.0f},{y0:.0f},{z0:.0f}]..[{x1:.0f},{y1:.0f},{z1:.0f}] size {x1-x0:.1f} x {y1-y0:.1f} x {z1-z0:.1f}'

done, count = set(), {}
w = StlAPI_Writer()

def walk(lab, loc, depth, path):
    nm = name(lab)
    if st.IsAssembly_s(lab):
        print('  ' * depth + f'+ {nm}')
        comps = TDF_LabelSequence(); st.GetComponents_s(lab, comps)
        for i in range(1, comps.Length() + 1):
            c = comps.Value(i)
            ref = TDF_Label(); st.GetReferredShape_s(c, ref)
            walk(ref, loc.Multiplied(st.GetLocation_s(c)), depth + 1, path + [nm])
        return
    shape = st.GetShape_s(lab)
    placed = shape.Moved(loc)
    count[nm] = count.get(nm, 0) + 1
    print('  ' * depth + f'- {nm}   {bbox(placed)}')
    BRepMesh_IncrementalMesh(shape, 0.05, False, 0.3, True)   # parts may share a name: mesh every one
    if nm not in done:
        done.add(nm)
        w.Write(shape, os.path.join(out, 'parts', safe(nm) + '.stl'))
    w.Write(placed, os.path.join(out, 'placed', safe('__'.join(path[1:] + [nm])) + f'_{count[nm]}.stl'))

roots = TDF_LabelSequence(); st.GetFreeShapes(roots)
for i in range(1, roots.Length() + 1):
    walk(roots.Value(i), TopLoc_Location(), 0, [])
print('unique parts:', len(done))
