# Griffin solar power and cooling study

The three reconstructed array faces supply one 28 V battery bus and a regulated
avionics load. Each face has its own lumped temperature, solar-heat input and
capacity-limited coolant boundary. This is an executable study, not a claim
about Griffin's unpublished cell supplier, battery inventory or cooling hardware.

The current [Astrobotic description](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
establishes triple-junction cells and lithium-ion storage. The historical
[August 2021 user guide, p.28](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
establishes a 28 V rail for that design. Current flight pack capacity, load
schedule, regulator design and array laminate thermal data remain unavailable.

The selected **study reference**, AZUR SPACE 3G30A-Advanced CIC, is defined once
in the typed SysML source. [DB 00010893-01, 11 April 2025, p.2](https://www.azurspace.com/media/uploads/file_links/file/bdb_00010893-01-00_3g30-advanced_6x12_LrDRZvU.pdf)
gives BOL efficiency 28.8% at AM0 1367 W/m² and 28°C, maximum-power voltage
2.400 V, current 1.170 A, and their slopes −6.7 mV/K and +0.57 mA/K. The reduced
relative power coefficient is `(dVmp/dT)/Vmp + (dImp/dT)/Imp`. This linearization
is a reference-cell surrogate, with published coefficient applicability from
28°C to 140°C. The selected absorptivity 0.91 uses the published upper bound
for the 100 µm AR coverglass; it is a conservative study choice, not a measured
Griffin optical property. Shader colors provide no engineering properties.

Active collecting area comes from the actual source-defined cell field,
including omitted cells, inter-cell gaps and clipped corners. A probe mounted
in each panel's local frame samples nine stratified active-cell centers above
the illuminated face. Terrain visibility is an explicit spatial approximation;
vehicle self-shadowing, wiring losses, MPPT, radiation damage and spectral
response are outside this reduced source model.

Shared `SolarPanel`, `ThermalMass`, `HeatLoad`, `LimitedCoolingSink`, `Battery`
and `OnboardComputer` equations own the physics. USD owns the closed electrical
and thermal network. SysML owns the selected material properties and study
parameters. Rhai derives geometry-dependent parameters and checks the result.
Cooling capacity, minimum coolant temperature, conductance and panel heat
capacity are adjustable study inputs. The coolant is an ideal external heat
reservoir; pump power, coolant depletion and radiative exchange are not modeled.

Acceptance must observe real irradiance, framed incidence and visibility,
temperature feedback, radiant/electrical/thermal closure, cooling limits,
storage and load power. Negative tests must reject disconnected temperature
feedback or a broken electrical/thermal connection. GNC power availability
must be wired to the solved avionics supply before claiming powered control.

The first coupled production checkpoint passes GEP-001, GEP-002 and GEP-003 over
45 simulation seconds (270 ten-tick samples). Independent integration of the
rendered collecting faces gives 2.5814605, 2.3283761 and 2.3283761 m². Final
temperatures were 316.7441, 310.7891 and 310.5844 K, with the 200 W per-panel
cooling cap respected. Radiant, thermal, electrical and battery storage/loss
checks passed. Eight affected Griffin control, Sun-pointing, landing, engine-out
and propellant-exhaustion/impact cases also passed. These runs qualify the
declared reduced study; they do not establish flight calibration or FPS.
The shared controller separately passes 108 powered/interrupted/recovery checks.
The coolant boundary remains ideal and unlimited in total energy.

`GEP-004` independently qualifies low-supply protection on the production
vehicle. Its fixture inherits the landing scene, changes only battery capacity
to 0.1 Ah and initial SOC to 0.1, and prescribes zero irradiance at the three
electrical-network boundaries. Those accelerated-depletion inputs are test
conditions, not revised flight or nominal study ratings. A sustained 0.35
thrust request and 0.2 yaw request remain present throughout the eight-second
run. The gate observes a powered interval, solved avionics UVLO, zero computer
draw, suppression of throttle and all three attitude requests within three
fixed intervals, and subsequent main-engine and RCS extinction. The current
run passes with 299 powered and 181 unpowered samples; cutoff occurs at tick
300. Peak main-engine thrust is 7,628.58 N and peak summed RCS thrust is
231.969 N; final values are below 0.001 N. The rapid voltage transition of this
tiny test inventory does not calibrate a real battery OCV or BMS curve.

Run the two positive cases through the normal Twin verification registry:

```sh
luncosim test --scene tests/griffin_power_thermal.usda --verification GriffinPowerThermalRequirements::Verify_GriffinPowerThermal
luncosim test --scene tests/griffin_control_power_loss.usda --verification GriffinPowerThermalRequirements::Verify_GriffinControlPowerLoss
```

For fault qualification, `tools/check_power_failure_rejection.py` forks the
positive document through the existing document API and cuts exactly one
connection per disposable layer: forward-panel temperature feedback, its heat
source-to-mass connector, or its electrical connection to the battery node.
It leaves the positive source and model equations unchanged. Use an owned
windowed authoring session with this Twin open and a separate free test port:

```sh
python3 tools/check_power_failure_rejection.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4292
```

Generated layers use the ignored `tests/_power_failure_*.usda` prefix so the
existing Twin scene index can admit them. Exact typed mutations, source hashes
and production reports are retained under `.cache/power-failure-qualification/`.
A timeout, source-load failure or test-selection error cannot satisfy this
fault gate. A malformed input can be rejected before simulation starts; that
case requires the exact electrical-network `CosimStatus.modelica_error` and
held admission. Other cuts must produce a failing typed requirement verdict.
The script is an external API/CLI coordinator; the existing Rhai observer and Modelica
admission owner supply the rejection evidence.

Qualification on 21 October 2026 confirms all three cuts: the temperature input
is rejected as neither a scalar value nor a connection; the disconnected PV
connector is rejected as outside the generated acausal network; and the heat
source disconnection completes the observation horizon with a failing GEP-002
verdict. The unmodified network passes GEP-001–003 with the strengthened exact
electrical/thermal node checks. Together with the separate GEP-004 pass, these
close the power-loss and broken-wiring acceptance gaps. Raw evidence is in the
engine checkout's `.cache/codex-evidence/griffin-power-loss-20261021/` and this
Twin's `.cache/power-failure-qualification/`. This checkpoint adds verification;
it does not change nominal physical parameters or qualify FPS.
