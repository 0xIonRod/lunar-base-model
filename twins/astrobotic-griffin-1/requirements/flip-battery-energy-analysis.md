# FLIP battery energy model review

The [Astrolab power post](https://www.linkedin.com/posts/astrolabspace_our-flip-rover-is-equipped-with-a-622-kwh-activity-7508563602279309312-W5Le),
checked 2026-10-20, states a 6.22 kWh battery. It does not identify pack voltage,
cell chemistry, an open-circuit voltage curve, discharge limits, temperature,
current rate or measured usable bus energy. The Twin's 28 V bus and 0.01 ohm
series resistance are study settings, not vendor specifications.

## Reproduced discrepancy

The previous shared `LunCo.Electrical.Battery` multiplied its voltage setting by
state of charge. With charge-based SOC, its ideal full-range energy was half
of `capacity * voltage_nom`, before series losses. A native synthetic C/10
experiment used the composed FLIP capacity 222.14285278320312 Ah and voltage
28 V. Over nine hours, SOC fell from 1 to 0.1 and the ideal model delivered
3.079 kWh, compared with a 5.598 kWh constant-voltage nominal budget. The same
run with the authored 0.009999999776482582 ohm ESR added 0.044413 kWh of heat;
it retained the same 2.5191 kWh internal-model discrepancy. This was a
production experiment, not a flight-representative duty cycle.

FSP-007's passing authored-parameter check did not expose this difference.
Scaling the Ah setting to hide it would retain an unsupported voltage-collapse
law. The [Modelica Standard Library battery parameterization](https://doc.modelica.org/Modelica%204.0.0/Resources/helpWSM/Modelica/Modelica.Electrical.Batteries.UsersGuide.Parameterization.html)
separates nominal charge, series resistance and the OCV/SOC characteristic.
Its linear approximation requires both endpoint voltages; a measured table is
another option. Neither an endpoint nor a measured OCV table is available for
FLIP in the cited public source.

## Explicit mission-level storage approximation

The repaired shared model uses a nearly flat internal voltage with a linear
falloff only inside the existing empty reserve `r = soc_empty_threshold`.
For bounded charge fraction `s` and `Q = 3600 * capacity` coulombs:

```
Vp = voltage_nom / (1 - r/2)
Voc(s) = Vp * min(1, s/r)
E(s) = Q * Vp * { s^2/(2r), if s < r; s-r/2, otherwise }
```

Consequently `E(1) = capacity * voltage_nom` Wh. With the default 0.1% charge
reserve the plateau is 28.014007 V for a 28 V average. The normalization keeps
the complete nominal energy budget without inventing a measured cell curve.
The reserve is a modeling assumption, not an inferred FLIP discharge knee.

The circuit keeps the signed resistor relation `Vbus = Voc + I*R`. Storage
current equals terminal current in the interior and rejects outward storage
flux at empty/full. `dE/dt = Voc * Istore`; all remaining terminal power is
explicit `heat_w = I^2*R + Voc*(I-Istore)`. Full-charge surplus is an ideal
shunt loss. An externally forced reverse bus at empty absorbs resistor power.
This is a finite, energy-consistent mission study model, not a calibrated BMS,
charge controller, cell chemistry or thermal pack. The component exports heat;
the current FLIP thermal network does not yet receive this new battery-loss
signal, so this repair does not qualify battery temperature or full-charge
thermal management.

## Production acceptance

The generic bench is `assets/models/tests/BatteryEnergyContracts.mo` in the
`tutorials` simulator checkout. Its Rhai gate checks complete native
trajectories, charge conservation, stored/terminal/thermal energy conservation,
full nominal energy, series loss, empty/full saturation, recharge, connected
motor regeneration, passive empty loads and seven invalid parameter cases.
All 38 checks pass. A separate normal USD rover gate passes all four
empty-battery actuator checks.

`scripts/api/test_battery_energy.py` launches its own headful production session,
waits for the exact source preview's composition/projection, reads parameters
from its explicit document ID, and compiles source-bound ideal/lossy benches.
The full-discharge run starts with 22,391,999.560546875 J (6.219999878 kWh).
The ideal run supplies 22,391,999.5210135 J and ends empty. The ESR run supplies
22,214,348.731923215 J net to the bus, with 177,650.80538277034 J series heat.
Maximum energy residuals are 0.039534 J and 0.023241 J respectively. The
complete discharge/recharge/shunt cycle closes within 1.77e-7 J; connected
motor regeneration closes within 3.70e-11 J. The native solver tolerance is
1e-9; the gate's energy allowance is 1 microjoule plus 1e-7 of initial energy.

For reproduction from `tutorials`:

```sh
python3 scripts/api/test_battery_energy.py --port 4291 --output /tmp/battery-energy \
  --scene /home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1/tests/flip_sensor_power_requirements.usda \
  --battery-path /World/FLIP/Battery
```

Hardware validation remains open until pack-level data supplies the missing
operating conditions and curve. FSP-007 remains explicitly a source-configuration
check; its SysML status alone must not be presented as hardware energy qualification.
