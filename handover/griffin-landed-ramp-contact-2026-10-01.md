# Griffin landed ramp contact checkpoint

The authorized optimization Cargo cache clean removed 32.1 GiB without source
changes. The terrain default build now succeeds; core `24dd835fa` is the
current owned runtime, not the removed optimization binary.

Core `5079c4b58` preserves USD-authored joint motor models and limits during
position commands. Core `24dd835fa` maps native unbounded limit sentinels to
absent port bounds. Both boundary unit tests passed. Production revolute and
prismatic fixtures passed respectively 6 and 5 checks over 600 ticks. These
are component checks, not Griffin or rendered acceptance.

The current core / Twin `fec3026` replay terminated FAIL at tick 19196 in
`ramp-root-deployment-settle`. Touchdown was tick 17102; middle and toe stages
settled at 17277 and 17397. Thrust reached zero. At final root settlement,
port/starboard toe rates were −0.0593704 / −0.0358057 rad/s, above the retained
0.02 rad/s limit; release correctly remained blocked. Logs and native decoded
evidence are `/tmp/griffin-preserved-drive-replay.log` and
`/tmp/griffin-preserved-drive-evidence.json`.

The recorded lander tilt and toe corners agree with different elevations in
the retained DEM outside the 12 m pad. Fixed nominal targets therefore cannot
be treated as general terrain-contact targets. See the explicit geometry,
assumption and source notes in `griffin-size-evidence.md` and the SysML ramp
requirement comments. The new Rhai planner reads landed root frames and the
existing track/miter datums, solves each target within its source travel, and
records eight terrain clearances per ramp. It reserves half the source 20 mm
contact tolerance as a study allowance. It retains all angle/rate/dwell gates.

The generic GroundHeight query returned origin-distance-zero anonymous hits
for these probes; those results were not used as surface heights. Retained
TerrainHeight samples were used instead, with the authored pad footprint/top.
This does not resolve the generic raycast diagnostic or prove all contact
colliders match the DEM.

The fresh terrain-derived replay passed middle/toe deployment and the final
all-six-hinge dwell gate, then released FLIP. Planned port/starboard targets
were −0.4312765551 / +0.4273772443 rad. At tick 16704 all six instantaneous
rates were below 0.007 rad/s. This is current component/phase evidence, not
full mission acceptance. Log: `/tmp/griffin-landed-ramp-replay.log`.

The replay ended NO-VERDICT exit2 at 20000 ticks because route diagnostics
read WheelRaycast tire forces without declaring the four wheel entities as
read dependencies. The declaration is now corrected without changing the
physics or acceptance policy. A fresh replay follows. Egress, repeatable
landing, and owned rendered acceptance remain open.
