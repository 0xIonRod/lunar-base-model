"""Validate only added body structure; approved Griffin 7 geometry is immutable."""
import FreeCAD as App
import Part,json,time,math,traceback
from pathlib import Path
import os
W=Path(os.environ.get('GRIFFIN8_WORK_DIR', str(Path(__file__).resolve().parent)))
d=App.openDocument(str(W/'griffin_8_lander.FCStd'))
added=json.loads((W/'griffin_8_body_build.json').read_text())['added']
def world(o):
 s=o.Shape.copy();s.Placement=o.getGlobalPlacement();return s
def near(a,b,t=0):
 return all(getattr(a,k+'Min')<getattr(b,k+'Max')+t and getattr(b,k+'Min')<getattr(a,k+'Max')+t for k in 'XYZ')
features=[o for o in d.Objects if o.TypeId=='Part::Feature' and o.Shape.Volume>0.001]
sh={o.Name:world(o) for o in features}
out={'units':'mm and cubic mm','body_collisions':[],'connections':{},'motion_samples':[],'invalid':[]}
def save():(W/'griffin_8_body_audit.json').write_text(json.dumps(out,indent=2))
try:
 out['invalid']=[o.Name for o in features if not o.Shape.isValid()]
 old=[o.Name for o in features if o.Name not in added]
 for i,a in enumerate(added):
  sa=sh[a]
  for b in old+added[:i]:
   sb=sh[b]
   if not near(sa.BoundBox,sb.BoundBox):continue
   vol=sa.common(sb).Volume
   if vol>1:out['body_collisions'].append({'a':a,'b':b,'volume':round(vol,3)})
  out['last_component_checked']=a;save();print('Checked',a,flush=True)
 pairs=[('BodyUpperRing','Deck'),('BodyLowerRing','Skirt00'),('UpperAdapterFoot','Deck'),('UpperAdapterCone','UpperAdapterFoot'),('UpperAdapterCrown','UpperAdapterCone'),('UpperAdapterCrown','ConnectingMainBeams'),('LowerAdapterCone','LowerAdapterCrown'),('LowerAdapterCrown','Deck'),('LowerAdapterClampRing','LowerAdapterCone')]
 for i in range(1,9):pairs.extend([('BodyCornerPost%02d'%i,'BodyUpperRing'),('BodyCornerPost%02d'%i,'BodyLowerRing')])
 for i in range(1,5):
  pairs.extend([('BodyDeckWeb%d'%i,'Deck'),('LegRootYoke%d'%i,'Deck'),('LegRootYoke%d'%i,'LegPin%d'%i)])
  for j in range(1,5):pairs.extend([('Tank%dGusset%d'%(i,j),'Deck'),('Tank%dGusset%d'%(i,j),'TankMount%d'%i)])
 for a,b in pairs:
  # Each new solid is checked against its specified interface; avoid slow
  # whole-compound face-distance operations used by the earlier general audit.
  dist=max(min(sa.distToShape(sb)[0] for sb in sh[b].Solids) for sa in sh[a].Solids)
  out['connections'][a+' / '+b]=round(dist,6)
 save();print('Connections checked',flush=True)
 p=d.getObject('RampSettings')
 for t in (0,5,10,15,20,30,40,50,60,70,80,85,90,95,100):
  p.ForeDeployment=t;p.AftDeployment=t;d.recompute();hits=[]
  for o in features:
   if not o.Name.startswith(('Fore','Aft')):continue
   ss=world(o)
   for a in added:
    if near(ss.BoundBox,sh[a].BoundBox):
     vol=ss.common(sh[a]).Volume
     if vol>1:hits.append([o.Name,a,round(vol,3)])
  out['motion_samples'].append({'percent':t,'collisions':hits});save()
 out['status']='PASS' if not out['invalid'] and not out['body_collisions'] and not any(v>0.01 for v in out['connections'].values()) and not any(p['collisions'] for p in out['motion_samples']) else 'REVIEW'
 save();print('BODY AUDIT',out['status'],flush=True)
except Exception:
 out['error']=traceback.format_exc();save();raise
