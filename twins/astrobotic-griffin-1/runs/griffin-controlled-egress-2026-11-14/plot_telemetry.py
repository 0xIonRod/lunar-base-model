import csv,math
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
p=Path(__file__).resolve().parent
r=list(csv.DictReader((p/'trajectory.csv').open()))
t=[float(x['sim_secs']) for x in r]
fig,axs=plt.subplots(4,1,figsize=(11,9),sharex=True,layout='constrained')
for name,label in [('tension0_n','Left line'),('tension1_n','Right line')]:axs[0].plot(t,[float(x[name]) for x in r],label=label)
axs[0].axhline(2000,color='firebrick',ls='--',label='Operating gate');axs[0].set_ylabel('Tension (N)');axs[0].legend(loc='upper left',ncol=3)
axs[1].plot(t,[float(x['speed_mps']) for x in r],label='Body speed');axs[1].axhline(.35,color='firebrick',ls='--',label='Descent gate');axs[1].set_ylabel('Speed (m/s)');axs[1].legend(loc='upper left',ncol=2)
axs[2].plot(t,[math.degrees(math.acos(max(-1,min(1,float(x['upright_cos']))))) for x in r]);axs[2].axhline(95,color='firebrick',ls='--');axs[2].set_ylabel('Tilt from upright (°)')
axs[3].step(t,[int(x['fixed_count']) for x in r],where='post',label='Loaded fixed-world wheels');axs[3].step(t,[int(x['rear_supported_count']) for x in r],where='post',label='Loaded rear wheels (any support)');axs[3].set_ylabel('Wheel count');axs[3].set_yticks(range(5));axs[3].legend(loc='upper left',ncol=2);axs[3].set_xlabel('Simulation time (s)')
manual=[float(x['sim_secs']) for x in r if x['stage'] in ('drive_proof','finish')]
if manual:
 for ax in axs:ax.axvspan(min(manual),max(t),color='gold',alpha=.22)
 axs[1].text(min(manual)-.5,.41,'Manual proof →',ha='right',fontsize=9)
for ax in axs:ax.grid(alpha=.2)
fig.suptitle('FLIP controlled egress — final 7/7 acceptance\nReduced balanced bridles and ideal powered winches; engineering study')
fig.savefig(p/'egress-telemetry.png',dpi=160)
