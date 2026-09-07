"""Complete the study's body frame without changing any Griffin 7 geometry.
Architecture: Astrobotic PUG Aug 2021, p25. All new dimensions are estimated.
The body remains an open spacecraft frame, not an invented sealed bottom pan.
"""
import FreeCAD as App
import Part
from pathlib import Path
import math,json,hashlib,zipfile,traceback
import os
W=Path(os.environ.get('GRIFFIN8_WORK_DIR', str(Path(__file__).resolve().parent)));V=App.Vector
d=App.openDocument(str(W/'griffin_7_lander.FCStd'))
root=d.getObject('Griffin6');root.Label='GRIFFIN 8 | completed body frame; approved rails unchanged'
d.Label='Griffin 8 - body structure completion'
report={'source':'Griffin 7','dimensions':'estimated mm; not flight CAD','added':[],'phases':[]}
def log(s):
 report['phases'].append(s);(W/'griffin_8_body_build.json').write_text(json.dumps(report,indent=2));print(s,flush=True)
def fingerprint(o):
 return {'brep':hashlib.sha256(o.Shape.exportBrepToString().encode()).hexdigest(),'placement':list(o.getGlobalPlacement().Base)+list(o.getGlobalPlacement().Rotation.Q)}
before={o.Name:fingerprint(o) for o in d.Objects if o.TypeId=='Part::Feature'}
expressions={o.Name:list(o.ExpressionEngine) for o in d.Objects if 'Joint' in o.Name}
g=d.addObject('App::Part','BodyCompletion');g.Label='08 | body frame, cones and mounting interfaces';root.addObject(g)
def B(x,y,z,dx,dy,dz):return Part.makeBox(dx,dy,dz,V(x,y,z))
def F(pts):
 vv=[V(*p) for p in pts];return Part.Face(Part.makePolygon(vv+[vv[0]]))
def world(o):
 s=o.Shape.copy();s.Placement=o.getGlobalPlacement();return s
def annulus(r0,r1,z,h):return Part.makeCylinder(r1,h,V(0,0,z)).cut(Part.makeCylinder(r0,h,V(0,0,z)))
def add(n,s,label,color=(0.72,0.76,0.80)):
 assert not s.isNull() and s.isValid(),n
 o=d.addObject('Part::Feature',n);g.addObject(o);o.Shape=s;o.Label=label
 o.addProperty('App::PropertyColor','StudyColor','Presentation');o.StudyColor=color
 o.addProperty('App::PropertyString','ModelBasis','Reference');o.ModelBasis='Reference-informed structural envelope; dimensions and details estimated. Astrobotic PUG 2021 p25; GLAM-like packaging retained.'
 report['added'].append(n);return o
def cut_old(s,names):
 for n in names:
  old=world(d.getObject(n))
  if s.BoundBox.intersect(old.BoundBox):s=s.cut(old)
 return s
xy=[(-1575,-2250),(1575,-2250),(2250,-1575),(2250,1575),(1575,2250),(-1575,2250),(-2250,1575),(-2250,-1575)]
def inset(dist):
 lines=[]
 for a,b in zip(xy,xy[1:]+xy[:1]):
  dx,dy=b[0]-a[0],b[1]-a[1];ll=math.hypot(dx,dy);nx,ny=-dy/ll,dx/ll
  lines.append((nx,ny,nx*a[0]+ny*a[1]+dist))
 pts=[]
 for i in range(8):
  a,b,c=lines[i-1];e,f,k=lines[i];det=a*f-b*e
  pts.append(((c*f-b*k)/det,(a*k-c*e)/det))
 return pts
def prism(pts,z,h):return F([(x,y,z) for x,y in pts]).extrude(V(0,0,h))
try:
 # Two deep peripheral rings and eight columns complete the skirt's frame.
 for n,z in (('BodyUpperRing',1160),('BodyLowerRing',625)):
  s=prism(inset(12),z,60).cut(prism(inset(92),z-1,62))
  add(n,s,'Octagonal '+('upper' if z>1000 else 'lower')+' body perimeter beam')
 for i,(x,y) in enumerate(inset(55),1):
  add('BodyCornerPost%02d'%i,Part.makeCylinder(35,475,V(x,y,685)),'Corner %d | lower-to-upper body frame post'%i)
 log('Perimeter frame and eight corner posts built')
 # Missing central payload support, flared upward as shown in the guide.
 add('UpperAdapterFoot',annulus(398,450,1258,30),'Upper adapter lower attachment flange')
 upper=Part.makeCone(410,640,1002,V(0,0,1288)).cut(Part.makeCone(398,628,1002,V(0,0,1288)))
 add('UpperAdapterCone',upper,'Flared upper payload-support cone | estimated envelope')
 add('UpperAdapterCrown',annulus(628,680,2290,20),'Upper adapter flange contacting the fixed transverse carrier beam')
 # Lower adapter surrounds the engine cluster. Reliefs clear the existing,
 # already connected engine mounts and crossmembers; none of those are changed.
 cuts=['BaseCrossMembers']+['EngineMount'+str(i) for i in range(1,6)]
 lower=Part.makeCone(1120,430,585,V(0,0,610)).cut(Part.makeCone(1098,408,585,V(0,0,610)))
 add('LowerAdapterCone',cut_old(lower,cuts),'Launch-adapter cone with mount-interface reliefs | estimate')
 add('LowerAdapterCrown',cut_old(annulus(408,500,1195,25),cuts),'Lower adapter upper deck flange')
 add('LowerAdapterClampRing',annulus(1098,1170,585,25),'Launch-interface clamp-band ring | geometry proxy',(0.42,0.46,0.50))
 # Underside load-path webs connect the central deck region to the perimeter.
 webs=[B(-30,500,1160,60,1738,60),B(-30,-2238,1160,60,1738,60),B(1486,-30,1160,752,60,60),B(-2238,-30,1160,752,60,60)]
 for i,s in enumerate(webs,1):add('BodyDeckWeb%d'%i,cut_old(s,cuts),'Underdeck radial load-path web %d'%i)
 log('Upper and lower adapter cones and underdeck webs built')
 # Deck-attached gussets seat against the existing conformal tank cradles.
 for i,(x,y) in enumerate(((-1000,-1000),(1000,-1000),(-1000,1000),(1000,1000)),1):
  for j in range(4):
   s=F([(385,-8,1258),(470,-8,1258),(385,-8,1340)]).extrude(V(0,16,0))
   s.rotate(V(0,0,0),V(0,0,1),90*j);s.translate(V(x,y,0))
   s=s.cut(world(d.getObject('TankMount'+str(i))))
   add('Tank%dGusset%d'%(i,j+1),s,'Tank %d cradle gusset %d'%(i,j+1))
 # Bored root yokes put the large landing-leg pins in a visible load-carrying
 # housing. Existing leg, shock, pin and brace geometry is preserved exactly.
 for i,(sx,sy) in enumerate(((-1,-1),(1,-1),(1,1),(-1,1)),1):
  x,y=sx*1590,sy*1590;ss=[]
  for xo in (-100,80):
   ring=Part.makeCylinder(135,20,V(x+xo,y,1100),V(1,0,0))
   tab=B(x+xo,y-35,1100,20,70,120)
   s=ring.fuse(tab).cut(Part.makeCylinder(95,22,V(x+xo-1,y,1100),V(1,0,0)))
   s=cut_old(s,['Deck','BaseCrossMembers','Leg'+str(i),'Shock'+str(i),'Brace'+str(i),'LegBraceMount'+str(i)])
   ss.append(s)
  add('LegRootYoke%d'%i,Part.makeCompound(ss),'Leg %d | bored structural root yoke'%i,(0.42,0.46,0.50))
 log('Tank cradle gussets and landing-leg root yokes built')
 root.VersionDifference='Added the missing body perimeter frame, central upper/lower adapter cones, radial webs, tank gussets and bored landing-leg root yokes. All 176 Griffin 7 shapes and all 12 rail joint expressions are unchanged.'
 root.Limits='Older GLAM-like study with reference-informed bus architecture. Not flight CAD. Open underside is intentional. Adapter, frame and mounting dimensions estimated; geometry checks are not structural qualification.'
 d.recompute()
 after={n:fingerprint(d.getObject(n)) for n in before}
 report['changed_existing_geometry']=[n for n in before if before[n]!=after[n]]
 report['changed_joint_expressions']=[n for n,v in expressions.items() if list(d.getObject(n).ExpressionEngine)!=v]
 report['invalid']=[o.Name for o in d.Objects if o.TypeId=='Part::Feature' and not o.Shape.isValid()]
 assert not report['changed_existing_geometry']
 assert not report['changed_joint_expressions']
 assert not report['invalid']
 raw=W/'griffin_8_with_inherited_views.FCStd';d.saveAs(str(raw))
 # Publish a geometry-complete FCStd with fresh GUI metadata on first GUI open.
 # The inherited archive is retained, as is Griffin 7, for diagnosis/recovery.
 final=W/'griffin_8_lander.FCStd'
 with zipfile.ZipFile(raw) as src,zipfile.ZipFile(final,'w',zipfile.ZIP_DEFLATED) as dst:
  for entry in src.infolist():
   if entry.filename!='GuiDocument.xml':dst.writestr(entry,src.read(entry.filename))
 with zipfile.ZipFile(final) as z:assert z.testzip() is None
 report['saved']=str(final);report['unchanged_existing_shapes']=len(before);report['status']='BUILT - awaiting body clearance and GUI checks';log('Body iteration saved; all approved geometry preserved')
except Exception:
 report['error']=traceback.format_exc();log('ERROR');raise
