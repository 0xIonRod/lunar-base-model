"""Read-only USD geometry checks against the CAD tessellation cache."""
import json
from pathlib import Path
import numpy as np
from pxr import Usd, UsdGeom
HERE=Path(__file__).resolve().parent
parts={p['name']:p for p in json.loads((HERE/'simulation_meshes.json').read_text())}
centers={'Body':[0,.7,0],'FL':[-1,.465,-.85],'FR':[1,.465,-.85],'RL':[-1,.465,.85],'RR':[1,.465,.85]}
seen=set(); total=0; size=0; error=0
for group,center in centers.items():
    path=HERE/('FLIP_visual_'+group+'.usda'); stage=Usd.Stage.Open(str(path)); count=0
    for prim in stage.Traverse():
        if not prim.IsA(UsdGeom.Mesh): continue
        name=prim.GetName(); raw,chunk=(name.rsplit('_Chunk',1) if '_Chunk' in name else (name,'0'))
        source=parts[raw]; start=int(chunk)*5000
        faces=np.array(source['faces'])[start:start+5000]
        # Early body exports were unchunked and smaller than 5000 faces.
        ids,indices=np.unique(faces,return_inverse=True)
        expected=np.array(source['points'])[ids]; expected[:,[0,2]]*=-1; expected-=center
        mesh=UsdGeom.Mesh(prim); actual=np.array(mesh.GetPointsAttr().Get())
        assert actual.shape==expected.shape, name
        delta=float(np.max(np.abs(actual-expected))); error=max(error,delta)
        assert delta<1e-6,(name,delta)
        assert np.array_equal(mesh.GetFaceVertexIndicesAttr().Get(),indices.ravel()), name
        assert np.all(np.array(mesh.GetFaceVertexCountsAttr().Get())==3), name
        assert mesh.GetPrim().GetAttribute('physics:collisionEnabled').Get()==False
        count+=len(faces); seen.add(raw)
    print(group,count,'triangles',path.stat().st_size,'bytes')
    total+=count; size+=path.stat().st_size
assert seen==set(parts),('missing',set(parts)-seen)
assert total==sum(len(p['faces']) for p in parts.values())
assert size<256*1024*1024
print('PASS',len(seen),'CAD components;',total,'triangles;',size,'bytes; max point error',error,'m')
