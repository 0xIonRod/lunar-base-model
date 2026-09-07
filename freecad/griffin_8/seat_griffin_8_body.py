"""Seat only newly added body features; preserve every Griffin 7 feature."""
import FreeCAD as App
from pathlib import Path
import json,zipfile,hashlib
import os
W=Path(os.environ.get('GRIFFIN8_WORK_DIR', str(Path(__file__).resolve().parent)))
d=App.openDocument(str(W/'griffin_8_lander.FCStd'))
added=json.loads((W/'griffin_8_body_build.json').read_text())['added']
def fingerprint(o):
 return [hashlib.sha256(o.Shape.exportBrepToString().encode()).hexdigest(),list(o.getGlobalPlacement().Base),list(o.getGlobalPlacement().Rotation.Q)]
old={o.Name:fingerprint(o) for o in d.Objects if o.TypeId=='Part::Feature' and o.Name not in added}
def world(o):
 s=o.Shape.copy();s.Placement=o.getGlobalPlacement();return s
ring=d.getObject('BodyUpperRing');ring.Shape=ring.Shape.cut(world(d.getObject('RadiatorMounts')))
for i in range(1,5):
 o=d.getObject('BodyDeckWeb%d'%i);o.Shape=o.Shape.cut(world(ring))
d.recompute()
assert all(fingerprint(d.getObject(n))==v for n,v in old.items())
assert all(d.getObject(n).Shape.isValid() for n in added)
raw=W/'griffin_8_seated_native.FCStd';d.saveAs(str(raw))
with zipfile.ZipFile(raw) as src,zipfile.ZipFile(W/'griffin_8_lander.FCStd','w',zipfile.ZIP_DEFLATED) as dst:
 for entry in src.infolist():
  if entry.filename!='GuiDocument.xml':dst.writestr(entry,src.read(entry.filename))
(W/'griffin_8_body_seating.json').write_text(json.dumps({'status':'PASS','trimmed':['BodyUpperRing']+['BodyDeckWeb%d'%i for i in range(1,5)],'unchanged_existing_shapes':len(old)},indent=2))
App.closeDocument(d.Name)
exec(compile((W/'validate_griffin_8_body.py').read_text(),str(W/'validate_griffin_8_body.py'),'exec'))
