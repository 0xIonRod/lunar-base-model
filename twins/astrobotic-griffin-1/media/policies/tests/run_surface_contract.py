#!/usr/bin/env python3
"""Production API orchestration; surface_contract.rhai owns all verdicts."""
from pathlib import Path
import os,sys,json,time,hashlib
root=Path.cwd();p=root/'target/film-policy-contract-evidence';p.mkdir(parents=True,exist_ok=True)
os.environ.setdefault('LUNCOSIM_BIN',str(root/'target/release/luncosim'))
os.environ.update(LUNCOSIM_ISOLATED_RUN='1',LUNCOSIM_EPHEMERAL_SETTINGS='1',LUNCOSIM_CONFIG=str(p/'film-live-config'))
sys.path.insert(0,str(root/'scripts/api'))
import argparse
parser=argparse.ArgumentParser(description='Run authored film policy and inherited-asset consumer gates from a LunCoSim checkout.')
parser.add_argument('--port',type=int,required=True)
args=parser.parse_args()
from runtime import ProductionSession,BINARY,wait_for_ready
from run_editor_scene_test import wait_for_scene,wait_for_scene_time_selection
asset=Path(__file__).resolve().parent.parent/'runtime_surfaces.rhai';tests=asset.parent/'tests/surface_contract.rhai'
scene=asset.parents[2]/'scenes/griffin_1_surface_ops.usda';original=hashlib.sha256(scene.read_bytes()).hexdigest()
with ProductionSession(args.port,windowed=True,extra_args=['--scene',str(scene),'--no-throttle'],log_path=p/'film-live-runtime.log') as s:
 assert Path(f'/proc/{s.process.pid}/cwd').resolve()==root and Path(f'/proc/{s.process.pid}/exe').resolve()==BINARY.resolve()
 print('OWNED',s.process.pid,s.port,flush=True)
 def cmd(command_name,**params):
  r=s.post({'type':'ExecuteCommand','command':command_name,'params':params});assert not r.get('error'),r
  return r.get('data',{})
 library=asset.read_text()+'\n'+tests.read_text()
 def rhai(code):return cmd('RunRhai',code=library+'\n'+code)['stdout'].strip()
 def wait(read,label):
  end=time.monotonic()+60
  while time.monotonic()<end:
   value=read()
   if value:return value
   time.sleep(.1)
  raise RuntimeError('timeout '+label)
 wait_for_scene(s,str(scene),90)
 wait_for_scene_time_selection(s,p/'film-live-runtime.log',90)
 wait_for_ready(s.port,90)
 presentation=rhai('verify_film_surface_contract();');print(presentation,flush=True)
 assert 'TESTS_OK 29' in presentation and 'TESTS_FAIL' not in presentation,presentation
 doc=next(d['doc_id'] for d in cmd('ListOpenDocuments')['open_documents'] if d['kind']=='usd' and d.get('origin',{}).get('path')==str(scene))
 prim='/Griffin1SurfaceOps/FilmSource'
 def attr(name,kind,value):return {'SetAttribute':{'edit_target':'@root@','path':prim,'name':name,'type_name':kind,'value':value}}
 cmd('ApplyUsdOps',doc_id=doc,label='Reference the authored film policy',ops=[
  {'AddPrim':{'edit_target':'@root@','parent_path':'/Griffin1SurfaceOps','name':'FilmSource','type_name':'LunCoPolicy','reference':'twin://astrobotic-griffin-1/media/griffin_flip_v13/scenes/drive.usda','reference_prim_path':'/Griffin1SurfaceOps/DrivePowerProperties'}}])
 entries=[('power_surface','film-motor'),('route_energy_surface','route-short'),('route_drive_surface','energy-blue'),('route_balance_surface','route-long'),('drive_power_surface','drive-power'),('route_dual_surface','energy-amber')]
 for i,(entry,surface) in enumerate(entries):
  def attr(name,kind,value):return {'SetAttribute':{'edit_target':'@root@','path':prim,'name':name,'type_name':kind,'value':value}}
  ops=[attr('lunco:policy:entry','string',entry)]
  cmd('ApplyUsdOps',doc_id=doc,label='Exercise film source entry',ops=ops)
  code='print(film_policy_is_current('+json.dumps(entry)+','+json.dumps(surface)+'));'
  wait(lambda:rhai(code).splitlines()[-1]=='true','file-backed '+entry)
  wait(lambda:(view:=cmd('ReadExposures',surface='camera-status')['surfaces']['camera-status'])['state']=='ready' and view['properties'].get('active_name')!='inline-probe' and 'camera_items' not in view['properties'],'camera consumer decision')
  output=rhai('verify_film_file_policy('+json.dumps(entry)+','+json.dumps(surface)+');');print(output,flush=True);assert 'TESTS_OK 2' in output and 'TESTS_FAIL' not in output,output
 assert 'TESTS_FAIL' not in (p/'film-live-runtime.log').read_text()
assert hashlib.sha256(scene.read_bytes()).hexdigest()==original
print('PASS 29 presentation checks and six file-backed live consumer decisions; source unchanged; API Exit',flush=True)
