import FreeCAD as App, Part, hashlib,json
from pathlib import Path
W=Path(__file__).resolve().parent
d=App.openDocument(str(W/'FLIP_rover_v2_recovered.FCStd'))
V=App.Vector
def fingerprint(o):
 return [hashlib.sha256(o.Shape.exportBrepToString().encode()).hexdigest(),str(o.getGlobalPlacement()),list(o.ExpressionEngine)]
unchanged=[o for o in d.Objects if 'StudyColor' in o.PropertiesList and d.Power not in o.InListRecursive]
before={o.Name:fingerprint(o) for o in unchanged}
d.Motion.SolarAngle=0
p=d.SolarArrayPanelBody
p.setExpression('Placement.Rotation.Angle','-min(90, max(0, Motion.SolarAngle)) * 1 deg')
d.Motion.Instructions='SolarAngle requests degrees; effective panel angle clamps to 0-90 even for scripted input. Independent wheel roll; kinematic CAD, not dynamics.'
p.Placement.Base=V(0,690,950)
d.Power.Placement=App.Placement(V(0,0,0),App.Rotation(V(0,0,1),90))
back=Part.makeBox(1800,1380,20,V(-900,-1380,0))
for x in [-610,610]:
 for r,h,xx in [(21,120,x-60),(52,82,x-41),(40,20,x-60)]:
  back=back.cut(Part.makeCylinder(r,h,V(xx,0,0),V(1,0,0)))
d.SolarBackplate.Shape=back
d.SolarFrameFront.Placement.Base.y=-1400
for n in ['SolarFrameL','SolarFrameR']:
 o=d.getObject(n);o.Placement.Base.y=-1380;o.Width=1380
for r in range(12):
 for c in range(10):
  o=d.getObject('Cell%02d_%02d'%(r,c));o.Placement.Base.y*=1380/1850;o.Width=o.Width.Value*1380/1850
for n in ['SensorBar','SensorFootL','SensorFootR','CameraL','CameraR','LensL','LensR']:
 o=d.getObject(n);o.Placement.Base.y+=470
for side in ['L','R']:
 for stem in ['HingeSupport','HingePin']:
  o=d.getObject(stem+side);o.Placement.Base.y-=210
 o=d.getObject('StowRest'+side);o.Placement.Base.y= -710
for c in range(10):d.getObject('Cell11_%02d'%c).Width=80
p.Joint='Side hinge: world Y axis at (-690,0,950) mm; 0 closed, 82 study deployment, 90 maximum.'
d.FLIP.Coordinates='Millimetres; X lateral, Y longitudinal (front -Y), Z up. Wheel axes X; panel hinge Y.'
d.FLIP.Source='https://www.astrolab.space/wp-content/uploads/2025/06/Picture1-1.jpg'
d.Label='FLIP v3 | corrected side-hinged solar array'
d.recompute()
after={o.Name:fingerprint(o) for o in unchanged}
assert before==after,'Unrelated subsystem changed'
out=W/'FLIP_rover_v3_side_hinge.FCStd'
d.saveAs(str(out))
(W/'v3_change_report.json').write_text(json.dumps({'preserved_components':len(before),'preserved_exactly':before==after,'panel_mm':[1800,1380,20],'hinge_world_mm':[-690,0,950],'hinge_axis':'Y','baseline':'FLIP_rover_v2_recovered.FCStd'},indent=2))
App.closeDocument(d.Name)
print('CORRECTION SAVED',flush=True)
