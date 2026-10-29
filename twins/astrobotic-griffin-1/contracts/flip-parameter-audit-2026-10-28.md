# FLIP mission-model parameters

The public hardware description sets the envelope. Unreleased equipment data
remain estimates; the model is useful for comparing operating choices, but its
energy totals are not a flight prediction. Read the composed scene, not only
the component defaults: variants and references change which parts run.

## Published anchors

- [Astrolab power specification](https://www.linkedin.com/posts/astrolabspace_our-flip-rover-is-equipped-with-a-622-kwh-activity-7508563602279309312-W5Le): 6.22 kWh battery, nearly 270 W peak deployable solar panel. The model retains 6.22 kWh and a rounded 270 W ceiling.
- [Astrolab mission overview, LEAG 2025](https://www.hou.usra.edu/meetings/leag2025/pdf/5034.pdf): four-wheel skid steer, 480 kg launch-mass allocation, steep ramps and fabric-tether egress. 480 kg is an allocation, not a measured as-built mass.
- [Venturi wheel release](https://venturi.space/en/article/world-premiere-venturi-hyper-deformable-lunar-wheel/): 930 mm diameter, 192 cables. [Astrolab](https://www.astrolab.space/flip-rover/) says FLIP uses full-size FLEX wheels. The reference describes the wheel family, not a current FLIP supplier drawing.
- [Camera manufacturer description](https://www.linkedin.com/posts/canadensys-aerospace-corporation_we-are-excited-to-work-with-our-partners-activity-7456288136374087680-pb-O): two cameras on the solar-panel mast pointing in opposite directions. Native mounted views follow that arrangement. Lens calibration is not public.

## Explicit estimates and checks

| Item | Model value | What the value means |
|---|---|---|
| Battery | 28 V, 222.142852783 Ah | Product is 6.219999878 kWh. Voltage is an estimate, not a public FLIP pack rating. |
| Battery internal resistance | 0.01 ohm | Reduced series-loss model; no supplier discharge/temperature curves available. |
| Starting charge | 85% | Same experiment condition for both copies, not a launch specification. |
| PV reference area/efficiency | 0.7 m² / 35% | Optical/conversion estimates, capped by the public 270 W reference rating. |
| PV temperature | 298.15 K | Prescribed experiment temperature. Generic silicon temperature coefficient is not calibrated to FLIP cells. |
| Solar converter | 48 V PV operating point, 95% efficiency | Reduced converter estimate. Replaces the unintended direct 48 V panel to 28 V bus mismatch. Not a supplier MPPT/BMS model. |
| Other equipment | 50 W aggregate | Explicit avionics/communications/instrument allowance. No claim that this is the actual FLIP duty cycle; use 20–100 W sensitivity. Night heaters and survival are not qualified. |
| Dynamic assembly | 450 kg | Live native readback: 343 kg chassis + four 5 kg carriers + four 18 kg wheels + 15 kg moving panel. Motor/gearbox render component masses are not additional rigid bodies. Within the 480 kg public allocation. |
| Chassis COM/inertia | Authored reconstruction | Not supplier mass properties. Moving panel remains a separate rigid body. |
| Wheel | radius 0.465 m, width 0.28 m, 18 kg | Diameter follows published wheel family; width, mass and inertia remain estimates. Rigid collision shape does not reproduce cable deformation or soil sinkage. |
| Wheel inertia | 1.946025 kg m² about axle | Solid-cylinder proxy, not a measured flexible-wheel inertia. |
| Motors | 0.9 N m stall; 2400 rad/s no-load; 28 V; 500 W rating | Generic DC-drive estimates. Four independent solved motors; no published FLIP torque/speed/current curves found. |
| Reduction | 200:1, 85%, 400 N m output limit | Estimated drivetrain. Ideal stall output about 153 N m before contact limits. |
| Brake | 1500 N m per wheel limit | Existing conservative brake allowance, not measured FLIP hardware. Contact and axle equations must hold at zero speed without freezing the body. |
| Soil contact | nominal friction 0.6; sensitivity 0.4–0.8 | Simplified wheel/soil coefficient, not the soil's internal friction angle. Must not be raised to hide a braking error. |
| Body drag | zero external linear/angular damping | Lunar vacuum. Bearing losses, gearbox losses, tire slip and motor losses own resistance. |
| Suspension | 15 kN/m, 3 kN s/m, 0.7 m travel | Reconstruction estimates, not a verified flexible-wheel load/deflection curve. |
| Cameras | opposed panel-mast views, 24 mm / 36 mm aperture | Rendering calibration estimate. Actual optics, distortion, resolution and exact mount metrology are unreleased. |

Native evidence is retained with the film: `flip-composed-parameter-audit.json`,
`rigid-assembly-mass-audit.json`, braking logs and subsequent energy receipts.
The old 158 W bus delivery arose from a generic 48 V photovoltaic current plateau
connected directly to the 28 V battery. The former route totals must be replaced
when the converter/equipment path, friction or drag changes.

Required acceptance before using revised numbers: cold-load and finite native
solver outputs; electrical power/heat closure; same initial conditions; native
braked slope test; route completion/contact checks; parameter sensitivity; and
visual review of actual camera views. A passing internal equation check is not
manufacturer validation.
