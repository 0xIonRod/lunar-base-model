"""Read-only native checks against the published CAD SysML numeric contract.
Run with FreeCADCmd; reports do not constitute a SysML parser/conformance test.
"""
import FreeCAD as App, Part
from pathlib import Path
import re,json,hashlib,datetime,traceback,math
W=Path(__file__).resolve().parent
contract=W.parents[1]/'twins/astrobotic-griffin-1/requirements/flip_cad_requirements.sysml'
values={n:float(v) for n,v in re.findall(r'attribute\s+(\w+)\s*:\s*(?:Real|Integer)\s*=\s*(-?[\d.]+)',contract.read_text(encoding='utf-8'))}
checks=[]
def check(name,ok,actual=None):
 checks.append({'check':name,'passed':bool(ok),'actual':actual})
def near(name,a,b):check(name,abs(a-b)<=.01,float(a))
def world(o):
 s=o.Shape.copy();s.Placement=o.getGlobalPlacement();return s
def placement(o):return list(o.getGlobalPlacement().Base)+list(o.getGlobalPlacement().Rotation.Q)
report={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'checks':checks,'contract':contract.name}
try:
 file=W/'FLIP_rover_v3_corrected.FCStd'
 report['model_sha256']=hashlib.sha256(file.read_bytes()).hexdigest()
 d=App.openDocument(str(file));d.recompute()
 near('saved closed',float(d.Motion.SolarAngle),values['solarMinDeg'])
 for name in ['Chassis','Exterior','Equipment','Mobility','Power','PayloadDeck','BatteryEnclosure','PowerControllerEnclosure','SolarArrayPanelBody']:
  check('named subject '+name,d.getObject(name) is not None)
 wheels=[d.getObject('Wheel'+tag) for tag in ['LF','LR','RF','RR']]
 near('wheel count',len(wheels),values['wheelCount'])
 for tag in ['LF','LR','RF','RR']:
  o=d.getObject('Wheel'+tag);q=o.getGlobalPlacement()
  near(tag+' lateral center',abs(q.Base.x),values['trackMm']/2)
  near(tag+' longitudinal center',abs(q.Base.y),values['wheelbaseMm']/2)
  near(tag+' center height',q.Base.z,values['wheelCenterHeightMm'])
  axis=q.Rotation.multVec(App.Vector(1,0,0))
  check(tag+' roll axis X',(axis-App.Vector(1,0,0)).Length<1e-8)
  tire=d.getObject('Tire'+tag).Shape
  radii=sorted(set(round(f.Surface.Radius,6) for f in tire.Faces if hasattr(f.Surface,'Radius')))
  check(tag+' band radius',values['wheelBandRadiusMm'] in radii,radii)
  check(tag+' rib radius',values['wheelRibRadiusMm'] in radii)
  near(tag+' tire width',tire.BoundBox.XLength,values['wheelWidthMm'])
 for prop,key in [('Length','baseplateWidthMm'),('Width','baseplateLengthMm'),('Height','baseplateThicknessMm')]:
  near(prop+' baseplate',getattr(d.Baseplate,prop).Value,values[key])
 skins=Part.makeCompound([world(d.Baseplate)]+[world(o) for o in d.Exterior.Group])
 for prop,key in [('XLength','bodyWidthMm'),('YLength','bodyLengthMm'),('ZLength','bodyHeightMm')]:
  near('body '+prop,getattr(skins.BoundBox,prop),values[key])
 b=d.SolarBackplate.Shape.BoundBox
 for prop,key in [('XLength','panelAlongHingeMm'),('YLength','panelFoldSpanMm'),('ZLength','panelThicknessMm')]:
  near('panel '+prop,getattr(b,prop),values[key])
 p=d.SolarArrayPanelBody
 for name in ['SolarBackplate','SolarFrameFront','SolarFrameRear','SolarFrameL','SolarFrameR','MovingHingeL','MovingHingeR','SensorBar','CameraL','CameraR']:
  check('moving member '+name,p in d.getObject(name).InListRecursive)
 near('cell count',len([o for o in p.Group if re.fullmatch(r'Cell\d\d_\d\d',o.Name)]),120)
 fixed={o.Name:placement(o) for o in d.Objects if 'StudyColor' in o.PropertiesList and p not in o.InListRecursive}
 camera_before={n:placement(d.getObject(n)) for n in ['CameraL','CameraR']}
 for angle in [0,values['solarExampleDeg'],values['solarMaxDeg'],0]:
  d.Motion.SolarAngle=angle;d.recompute();q=p.getGlobalPlacement()
  for coord,key in [('x','hingeXmm'),('y','hingeYmm'),('z','hingeZmm')]:
   near(str(angle)+' hinge '+coord,getattr(q.Base,coord),values[key])
  axis=q.Rotation.multVec(App.Vector(1,0,0))
  check(str(angle)+' hinge axis global Y',(axis-App.Vector(0,1,0)).Length<1e-8)
  tip=q.multVec(App.Vector(0,-values['panelFoldSpanMm'],0))
  near(str(angle)+' tip X',tip.x,values['hingeXmm']+values['panelFoldSpanMm']*math.cos(math.radians(angle)))
  near(str(angle)+' tip Z',tip.z,values['hingeZmm']+values['panelFoldSpanMm']*math.sin(math.radians(angle)))
  check(str(angle)+' all fixed parts unchanged',fixed=={n:placement(d.getObject(n)) for n in fixed})
  if angle==values['solarExampleDeg']:
   check('cameras follow panel',all(placement(d.getObject(n))!=camera_before[n] for n in camera_before))
 for request,expected in [(-1,0),(91,90)]:
  d.Motion.SolarAngle=request;d.recompute();tip=p.getGlobalPlacement().multVec(App.Vector(0,-values['panelFoldSpanMm'],0)); near('effective bounded input '+str(request),tip.z,values['hingeZmm']+values['panelFoldSpanMm']*math.sin(math.radians(expected)))
 d.Motion.SolarAngle=0
 d.Motion.LeftWheelRoll=30;d.Motion.RightWheelRoll=-30;d.recompute()
 for tag in ['LF','LR','RF','RR']:
  angle=30 if tag[0]=='L' else -30
  actual=d.getObject('Wheel'+tag).getGlobalPlacement().Rotation.multVec(App.Vector(0,1,0))
  expected=App.Rotation(App.Vector(1,0,0),angle).multVec(App.Vector(0,1,0))
  check(tag+' independent side roll',(actual-expected).Length<1e-8)
 d.Motion.LeftWheelRoll=0;d.Motion.RightWheelRoll=0;d.recompute()
 report['passed']=all(x['passed'] for x in checks)
 App.closeDocument(d.Name)
except Exception:
 report['error']=traceback.format_exc();report['passed']=False
(W/'requirements_check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({'passed':report['passed'],'failed':[q for q in checks if not q['passed']],'error':report.get('error')},indent=2))
