# Astrolab FLIP rover — source-backed recreation baseline

**Checked:** 2026-09-30. This supersedes the incomplete 2026-08-30 parameter
summary below; public claims, CAD choices and unresolved values are separated.

## Configuration supported by current public evidence

- Astrolab identifies FLIP as its FLEX Lunar Innovation Platform and Griffin-1
  lunar technology demonstrator. Its current concept includes a collapsible
  solar array, Venturi battery, full-size FLEX-family wheels/battery, and shared
  communications, sensors, software and avionics. The family link does not
  transfer FLEX vehicle dimensions or payload ratings to FLIP.
- LPSC 2026 paper #1874 says FLIP is a four-wheel skid-steer rover constrained
  by the Griffin/VIPER geometry and a **480 kg launch-mass envelope**. Venturi's
  current FLIP listing gives **450 kg total mass**, **30 kg max payload**,
  electric propulsion, solar recharge and **20 km/h max speed**. These are
  separate statements; the mass inclusion/baseline and the launch allocation
  must not be conflated.
- Astrolab states FLIP uses the same full-size wheels as FLEX. Venturi publishes
  **930 mm wheel diameter**, **192 sprung cables**, **96 springs**, and an
  unusually flexible tread/crown design for its wheel family. Wheel width,
  installed tread construction, unloaded/loaded radius, wheel load and
  force-deflection data are not public for FLIP. The public wheel page quotes
  15 km/h for a generic rover; this differs from the current FLIP product
  listing's 20 km/h and is not adopted as a control limit.
- Venturi's 2025 media kit says FLIP has **two battery packs behind the solar
  panels**. It also describes a battery cell test/procurement campaign; its
  total campaign cell count is not an installed pack configuration. FLIP pack
  dimensions, voltage, usable Wh, cell layout, mass, BMS limits and thermal
  paths remain undisclosed.
- Canadensys says the vehicle has **two solar-mast cameras pointing in opposite
  directions**. Astrolab's 2026 payload release names NASA METAL, LRA, LDES and
  Lunar LiDAR. METAL is mounted downward on a payload rail; the LRA is passive;
  LDES measures dust effects; the LiDAR supports surface mapping/perception.
  The public release does not provide payload dimensions or a complete mounting
  ICD. LPSC 2026 reports 13 payloads in total, while only four NASA payloads are
  named in the cited Astrolab announcement.
- The 2025 Astrolab Griffin announcement says direct egress is from the lander's
  top deck; ramps are not a prerequisite. The 2026 project update describes the
  mission at Mons Mouton, while the early announcement used the Nobile region.
  Treat the newer mission configuration as current and retain the discrepancy
  in old renders as revision context.

## Values still unavailable publicly

No dimensioned FLIP general-arrangement drawing, native CAD, or released flight
ICD was located. Do not state that the v5 model is identical to flight hardware.
Chassis overall dimensions; wheelbase/track; tire width and loaded contour;
spring and cable dimensions, stiffness/damping/material details; suspension
travel; motor torque/speed/gearing; wheel load; mass distribution, CG and
inertia; exact array sizes/cell topology/power; panel hinge mechanism; battery
electrical ratings; payload envelopes, mounts and bus interfaces; and Griffin
adapter/release dimensions all remain TBD unless marked as a study choice.

## Current v5 study boundary

The native FreeCAD study uses X lateral, Y up, Z longitudinal, forward +Z, mm;
USD uses a right-handed Y-up metre frame. It selects the public 930 mm wheel
diameter while retaining these explicitly non-flight values: 280 mm tire width,
1.70 m wheelbase, 2.00 m track, 65 mm axial inset of each inner rim face, a
12-spoke-per-face study hub, and one CAD panel controlled between 0 and 90 deg
with an 82 deg deployed view. It draws 192 cable details and 96 spring details
per wheel; their layout/diameter is visual-only. No CAD material density or
component mass has been assigned.

The model and handoff guide are under
[`freecad/flip_rover_v5/`](../freecad/flip_rover_v5/). The SysML baseline is
[`requirements/flip-recreation.sysml`](../requirements/flip-recreation.sysml).
The LunCoSim implementation and verification sequence is in
[`LUNCO_SIM_RECREATION.md`](../freecad/flip_rover_v5/LUNCO_SIM_RECREATION.md).

## Sources checked 2026-09-30

- [Astrolab FLIP rover](https://www.astrolab.space/flip-rover/)
- [Astrolab FLIP joins Griffin-1, 5 Feb 2025](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/)
- [Astrolab NASA payload announcement, 18 May 2026](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/)
- [Venturi current FLIP listing](https://venturi.space/rovers/)
- [Venturi hyper-deformable wheel technical page](https://venturi.space/en/wheel/)
- [Venturi 2025 media kit, battery packs (printed p.8)](https://venturi.space/wp-content/uploads/2025/06/en-venturi-space-media-kit.pdf)
- [LPSC 2026 FLIP project update #1874](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf)
- [Canadensys FLIP camera update](https://www.linkedin.com/posts/canadensys-aerospace-corporation_we-are-excited-to-work-with-our-partners-activity-7456288136374087680-pb-O)
- [Astrolab Lunar LiDAR announcement](https://www.linkedin.com/posts/astrolabspace_nasa-lunarrover-astrolab-activity-7463274130654793730-DpYR)
- [Astrolab FLIP design overview video](https://www.youtube.com/watch?v=UFEMOrg27KE) — imagery only, not dimensional evidence
