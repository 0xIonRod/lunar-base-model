"""Independent BRep audit of generated FLIP. Does not overwrite the model."""
import FreeCAD as App
from pathlib import Path
import json,datetime,traceback,time,hashlib
W=Path(__file__).resolve().parent
prior=json.loads((W/'v3_audit_latest.json').read_text()) if (W/'v3_audit_latest.json').exists() else {}
R={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'gap_tolerance_mm':0.01,'penetration_tolerance_mm3':1.0}
out=W/('v3_audit_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'.json')
def log(phase):
 R['phase']=phase;out.write_text(json.dumps(R,indent=2));(W/'v3_audit_latest.json').write_text(json.dumps(R,indent=2));print(phase,flush=True)
def world(o):
 s=o.Shape.copy();s.Placement=o.getGlobalPlacement();return s
def overlaps(a,b):
 a,b=a.BoundBox,b.BoundBox
 return min(a.XMax,b.XMax)-max(a.XMin,b.XMin)>1e-6 and min(a.YMax,b.YMax)-max(a.YMin,b.YMin)>1e-6 and min(a.ZMax,b.ZMax)-max(a.ZMin,b.ZMin)>1e-6
try:
 p=W/'FLIP_rover_v3_corrected.FCStd';R['model_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
 d=App.openDocument(str(p));d.recompute()
 leaves=[o for o in d.Objects if 'StudyColor' in o.PropertiesList]
 R['shape_count']=len(leaves)
 R['invalid']=[o.Name for o in leaves if o.Shape.isNull() or not o.Shape.isValid()]
 R['multi_solid_objects']={o.Name:len(o.Shape.Solids) for o in leaves if len(o.Shape.Solids)!=1}
 R['expressions']={o.Name:list(o.ExpressionEngine) for o in d.Objects if o.ExpressionEngine}
 log('Geometry validity checked')
 ss={o.Name:world(o) for o in leaves}
 resume=prior.get('model_sha256')==R['model_sha256'] and prior.get('shape_count')==len(leaves) and 'static_intersections' in prior
 if resume:
  for key in ['interfaces','failed_interfaces','ungrounded_features','static_intersections']:R[key]=prior[key]
  R['reused_checks_from_utc']=prior['started_utc']
  log('Resumed identical-file attachment and stowed checks')
 else:
  interfaces=json.loads((W/'build_report.json').read_text())['interfaces']
  R['interfaces']=[];bad=[]
  for a,b in interfaces:
   for i,solid in enumerate(ss[a].Solids):
    gap=solid.distToShape(ss[b])[0]
    v={'part':a,'solid':i,'mate':b,'gap_mm':gap};R['interfaces'].append(v)
    if gap>0.01:bad.append(v)
  R['failed_interfaces']=bad
  # Graph uses intended, measured interfaces only; a contact chain is not structural qualification.
  edges={}
  for q in R['interfaces']:
   if q['gap_mm']<=.01:
    a,b=q['part'],q['mate'];edges.setdefault(a,set()).add(b);edges.setdefault(b,set()).add(a)
  seen={'Baseplate'};todo=['Baseplate']
  while todo:
   for n in edges.get(todo.pop(),set())-seen:seen.add(n);todo.append(n)
  R['ungrounded_features']=sorted(set(ss)-seen)
  log('Named attachments and grounded contact graph checked')
  R['static_intersections']=[];names=list(ss)
  for i,a in enumerate(names):
   for b in names[i+1:]:
    if overlaps(ss[a],ss[b]):
     v=ss[a].common(ss[b]).Volume
     if v>1:R['static_intersections'].append({'a':a,'b':b,'mm3':v})
  log('All stowed leaf-pair penetrations checked')
 panel=d.getObject('SolarArrayPanelBody')
 moving=[o for o in leaves if panel in o.InListRecursive]
 fixed=[o for o in leaves if o not in moving]
 fixed_shapes={o.Name:world(o) for o in fixed}
 R['panel_samples']=prior.get('panel_samples',[]) if resume else []
 for angle in [0,5,10,20,30,40,50,60,70,82,90]:
  if any(q['degrees']==angle for q in R['panel_samples']):continue
  d.Motion.SolarAngle=angle;d.recompute()
  hits=[]
  for a in moving:
   sa=world(a)
   for b in fixed:
    sb=fixed_shapes[b.Name]
    if overlaps(sa,sb):
     v=sa.common(sb).Volume
     if v>1:hits.append({'a':a.Name,'b':b.Name,'mm3':v})
  # Point at panel front-centre: expected rotation about X in world Z-up frame.
  q=panel.getGlobalPlacement().multVec(App.Vector(0,-1380,0))
  R['panel_samples'].append({'degrees':angle,'front_point_mm':list(q),'penetrations':hits})
  log('Panel sample '+str(angle))
 d.Motion.SolarAngle=0;d.recompute()
 R['wheel_samples']=[]
 for angle in [0,15,45,90,180,270]:
  d.Motion.LeftWheelRoll=angle;d.Motion.RightWheelRoll=-angle;d.recompute()
  pose_shapes={o.Name:world(o) for o in leaves}
  hits=[]
  for tag in ['LF','LR','RF','RR']:
   wg=d.getObject('Wheel'+tag)
   ww=[o for o in leaves if wg in o.InListRecursive]
   others=[o for o in leaves if o not in ww]
   for a in ww:
    sa=pose_shapes[a.Name]
    for b in others:
     sb=world(b)
     if overlaps(sa,sb):
      v=sa.common(sb).Volume
      if v>1:hits.append({'a':a.Name,'b':b.Name,'mm3':v})
  R['wheel_samples'].append({'degrees':angle,'penetrations':hits})
  log('Wheel sample '+str(angle))
 d.Motion.LeftWheelRoll=0;d.Motion.RightWheelRoll=0;d.recompute()
 R['passed']=not(R['invalid'] or R['failed_interfaces'] or R['ungrounded_features'] or R['static_intersections'] or any(x['penetrations'] for x in R['panel_samples']+R['wheel_samples']))
 log('COMPLETE')
 App.closeDocument(d.Name)
except Exception:
 R['error']=traceback.format_exc();log('ERROR');raise
