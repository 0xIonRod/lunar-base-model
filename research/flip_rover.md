> Updated 2026-09-17: current CAD specifications and side-hinge behavior are in [FLIP requirements](../requirements/flip-rover.md). The runtime representation below is historical and has not been promoted to CAD v3.

# Astrolab FLIP rover — Griffin-1 engineering reference

**Checked:** 2026-08-30  
**Use:** source-backed project context and explicit LunCoSim proxy boundary

## Public facts

Astrolab presents FLIP as the FLEX Lunar Innovation Platform and the first
Astrolab lunar rover. The supplied [FLIP design video](https://www.youtube.com/watch?v=UFEMOrg27KE)
is an artist's-rendering overview of the current Griffin-1 design. Astrolab's
public pages describe full-size batteries, tires, avionics, sensors, software,
lunar-dust mitigation, hyper-deformable airless tires, and a collapsible solar
array. The Griffin-1 announcement gives a public rover mass of nearly half a
metric ton and 30 kg payload capacity. The 2026 mission announcement describes
small-payload and autonomous-operations work, with direct egress from the top
of the lander after touchdown.

Astrolab LPSC 2026 confirms four wheels and skid steering, with a 480 kg launch-mass constraint (https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf). Exact wheelbase, dimensions, tire stiffness, wheel torque,
battery energy, thermal limits, detailed steering dynamics, and payload ICD are not present
in the reviewed primary sources. The related FLEX architecture page is useful
only as a family-level design proxy; it must not be cited as FLIP-specific
flight data.

## LunCoSim representation

The active Twin is
`luncosim-griffin-1/twins/astrobotic-griffin-1/vehicles/flip.usda`. It contains:

- four wheel contact/suspension elements with all-wheel-steer inputs;
- four motor, torque-source, gearbox, and shaft chains;
- finite battery state-of-charge and solar input;
- two-node motor heat transfer and radiator model;
- camera, sensor mast, payload deck, telemetry, and battery-drained event;
- a Griffin-local BTXML route whose waypoint paths resolve in the active scene.

The active numbers are explicit study assumptions: 450 kg total mass, 2.4 m ×
1.8 m × 0.7 m envelope, 0.45 m wheel radius, 28 V / 83.33 Ah battery, 3 m²
solar array, and 400 N·m gearbox output limit. They are intended for Modelica
co-simulation and sensitivity analysis, not for flight performance claims.

## Sources

- [Astrolab FLIP rover](https://www.astrolab.space/flip-rover/)
- [Astrolab FLIP joins Griffin-1](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/)
- [Astrolab 2026 NASA payload announcement](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/)
- [Astrolab FLIP design video](https://www.youtube.com/watch?v=UFEMOrg27KE)
- [Astrolab FLEX architecture](https://www.astrolab.space/flex-rover/)
- [FLEX Payload Interface Guide](https://www.astrolab.space/wp-content/uploads/2024/08/Payload_Interface_Guide.pdf)
