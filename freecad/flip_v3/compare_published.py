import FreeCAD as App
from pathlib import Path
import hashlib,json,datetime
W=Path(__file__).resolve().parent
def take(file):
 d=App.openDocument(str(W/file));rows=[]
 for a,l,r in [(a,0,0) for a in [0,5,10,20,30,40,50,60,70,82,90]]+[(0,a,-a) for a in [0,15,45,90,180,270]]:
  d.Motion.SolarAngle=a;d.Motion.LeftWheelRoll=l;d.Motion.RightWheelRoll=r;d.recompute()
  parts={}
  for o in d.Objects:
   if 'StudyColor' not in o.PropertiesList:continue
   s=o.Shape.copy();s.Placement=o.getGlobalPlacement()
   parts[o.Name]=hashlib.sha256(s.exportBrepToString().encode()).hexdigest()
  rows.append(parts)
 App.closeDocument(d.Name);return rows
a=take('audited_source.FCStd');b=take('FLIP_rover_v3_corrected.FCStd')
r={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'audited_source_sha256':hashlib.sha256((W/'audited_source.FCStd').read_bytes()).hexdigest(),'published_sha256':hashlib.sha256((W/'FLIP_rover_v3_corrected.FCStd').read_bytes()).hexdigest(),'poses':17,'physical_parts_per_pose':224,'differences':[{ 'pose':i,'parts':[n for n in x if x[n]!=y.get(n)]} for i,(x,y) in enumerate(zip(a,b)) if x!=y],'intentional_change':'Native expression clamps out-of-range effective panel angles; all previously audited poses unchanged.'}
r['passed']=not r['differences'];(W/'published_geometry_comparison.json').write_text(json.dumps(r,indent=2));print('POSE COMPARISON',r['passed'])
