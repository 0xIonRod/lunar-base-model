import json,re,csv,sys
from pathlib import Path
src=Path(sys.argv[1]);dst=Path(sys.argv[2]);dst.mkdir(parents=True,exist_ok=True)
rows=[];evidence=[]
def unpack(x):
 if isinstance(x,list):return [unpack(v) for v in x]
 if isinstance(x,dict):
  if len(x)==1 and next(iter(x)) in ['Map','Array','String','F64','I64','U64','Bool']:return unpack(next(iter(x.values())))
  return {k:unpack(v) for k,v in x.items()}
 return x
for line in src.read_text().splitlines():
 if 'name=griffin_tether_descent_trace,' in line:
  row={k:float(v) for k,v in re.findall(r'"([a-zA-Z0-9_]+)": F64\(([^)]+)\)',line)}
  row.update({k:int(v) for k,v in re.findall(r'"([a-zA-Z0-9_]+)": I64\(([^)]+)\)',line)})
  row['stage']=re.search(r'"stage": String\("([^"]+)"\)',line)[1]
  row['sim_secs']=float(re.search(r'sim_secs=([0-9.]+)',line)[1]);rows.append(row)
 if line.startswith('LUNCO_SCENE_TEST_EVIDENCE '):evidence.append(unpack(json.loads(line.split(' ',1)[1])))
if rows:
 fields=list(dict.fromkeys(k for row in rows for k in row))
 with (dst/'trajectory.csv').open('w') as f:
  w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
(dst/'scene-test-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
print('samples',len(rows),'terminal evidence',len(evidence),'last',rows[-1] if rows else None)
