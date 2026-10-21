# Griffin solar power and cooling study

The three reconstructed array faces supply one 28 V battery bus and a regulated
avionics load. Each face has its own lumped temperature, solar-heat input,
capacity-limited coolant boundary and signed infrared exchange with prescribed
sky and ground baths. This is an executable study, not a claim
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

Shared `SolarPanel`, `ThermalMass`, `HeatLoad`, `LimitedCoolingSink`, `Radiator`, `Battery`
and `OnboardComputer` equations own the physics. USD owns the closed electrical
and thermal network. SysML owns the selected material properties and study
parameters. Rhai derives geometry-dependent parameters and checks the result.
Cooling capacity, minimum coolant temperature, conductance and panel heat
capacity are adjustable study inputs. The coolant is an ideal external heat
reservoir; pump power and coolant depletion are not modeled.

The AZUR datasheet does not supply infrared emissivity. The selected 0.87 is
a **study surrogate** from NASA's [IMAGE failure-review presentation,
21 April 2006, p.99](https://image.gsfc.nasa.gov/publication/document/IMAGE_FRB_Presentation_4-21-06.pdf).
It reports that value for IMAGE's dual-junction solar cells, not Griffin or
AZUR 3G30A. The typed material selection keeps that distinction explicit.
[NASA's thermal-control overview](https://www.nasa.gov/smallsat-institute/sst-soa/thermal-control/)
distinguishes solar absorptivity from infrared emissivity; shader colors and
the selected 0.91 solar absorptivity cannot establish infrared behavior.

Only the active outward cell-face area emits. Equal 0.5 sky/ground view factors
approximate unobstructed vertical faces on a level vehicle. The 3 K sky and
250 K ground are prescribed study environments, not measured Nobile fields.
Rear/frame emission, mutual vehicle view factors, plume heating and a dynamic
terrain thermal solution are excluded. Two instances of the shared grey-body
`Radiator` per panel apply `epsilon * area * sigma * (T^4 - T_environment^4)`.
The signed heat flow permits a warmer environment to heat the panel. Griffin
explicitly selects `5.670374419e-8 W/(m² K⁴)`, the displayed ten-significant-digit
rounding of the [NIST CODATA constant](https://physics.nist.gov/cuu/pdf/all_2018.pdf).
The existing 200 W per-panel coolant cap, 301.15 K minimum coolant temperature,
40 W/K conductance and 6000 J/K thermal capacitance remain study assumptions.

Acceptance must observe real irradiance, framed incidence and visibility,
temperature feedback, radiant/electrical/thermal closure, cooling limits,
storage and load power. Negative tests must reject disconnected temperature
feedback or a broken electrical/thermal connection. GNC power availability
must be wired to the solved avionics supply before claiming powered control.

The radiative network passes GEP-001, GEP-002 and GEP-003 over
45 simulation seconds (270 ten-tick samples). Independent integration of the
rendered collecting faces gives 2.5814605, 2.3283761 and 2.3283761 m². Final
temperatures are 310.3207, 305.5662 and 305.3774 K, with the 200 W per-panel
cooling cap respected. Radiant, thermal, electrical and battery storage/loss
checks pass. The earlier coupled-power checkpoint also covered eight Griffin
control, Sun-pointing, landing, engine-out and propellant-exhaustion/impact cases.
Those mission results precede the radiative addition. These runs qualify the
declared reduced study; they do not establish flight calibration or FPS.
The shared controller separately passes 108 powered/interrupted/recovery checks.
The coolant boundary remains ideal and unlimited in total energy.

`GEP-005` runs the **exact USD-generated 20-member network** for 3600 seconds
under a held snapshot of its 15 physical Sun input values. It is a subsystem
experiment, not a one-hour replay of changing flight attitude, shadows or
terrain. The gate requires the actual linked Modelica document to match the
projected source and retain its document generation. `RunModelicaSolve`
receives finite constant input bindings and tolerance `1e-8`; no equations
are copied into the observer. All 361 requested ten-second grid points and
two additional event samples are checked without downsampling.

The passing run ends at 373.2437, 338.4129 and 338.4253 K for the forward,
front-starboard and front-port faces. Every sample stays in the reference
cell's 301.15–413.15 K coefficient range. Final temperature rates are
`2.12e-7`, `6.80e-6` and `6.79e-6 K/s`, below the typed `0.001 K/s` settling
criterion. The gate also checks radiating area, material and environment
parameters, exact thermal connector topology, the T⁴ law and full heat
balance. The shared radiator separately passes 17 cooling, warming,
equilibrium, zero-emissivity and invalid-emissivity checks. These results
qualify the declared reduced study, not Griffin's flight thermal design.

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

Run the positive cases through the normal Twin verification registry:

```sh
luncosim test --scene tests/griffin_power_thermal.usda --verification GriffinPowerThermalRequirements::Verify_GriffinPowerThermal
luncosim test --scene tests/griffin_control_power_loss.usda --verification GriffinPowerThermalRequirements::Verify_GriffinControlPowerLoss
luncosim test --scene tests/griffin_sustained_thermal.usda --verification GriffinPowerThermalRequirements::Verify_GriffinSustainedThermal
```

For fault qualification, `tests/check_power_failure_rejection.py` forks the
positive document through the existing document API and cuts exactly one
connection per disposable layer: forward-panel temperature feedback, its heat
source-to-mass connector, its sky-radiation connector, or its electrical
connection to the battery node.
It leaves the positive source and model equations unchanged. Use an owned
windowed authoring session with this Twin open and a separate free test port:

```sh
python3 tests/check_power_failure_rejection.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4292
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

Qualification on 21 October 2026 confirms all four cuts: the temperature input
is rejected as neither a scalar value nor a connection; the disconnected PV
connector is rejected as outside the generated acausal network; and the heat
source and sky-radiation disconnections complete the observation horizon with
failing GEP-002 verdicts. A broken thermal topology disproves node closure;
the observer continues independent measurements without reading removed
radiation outputs or substituting a zero heat flow. The unmodified network
passes GEP-001–003 with the strengthened exact
electrical/thermal node checks. Together with the separate GEP-004 pass, these
close the power-loss and broken-wiring acceptance gaps. Raw evidence is in the
engine checkout's `.cache/codex-evidence/griffin-radiation-20261021/` and this
Twin's `.cache/power-failure-qualification/`. These faults do not alter the
positive source or nominal study ratings and do not qualify FPS.

The one-hour evidence and current positive power/control reports are under the
engine checkout's `.cache/codex-evidence/griffin-radiation-20261021/`.
`sustained-final.log` retains the typed GEP-005 verdict, exact experiment
identity, source CID, held forcing, temperatures and rates. The subsystem
source CID is `bafkreihxufarbfkjqwzm7ljautqgkbytqt6d5iohjt3fclm7x2chuww3ke`.
The native binary SHA-256 is
`39f60840b5ea0412f5eb3aabc0769d1ceb57e671050ad563f3674ec62962834c`.
This thermal checkpoint does not qualify native one-hour mission behavior or FPS.
