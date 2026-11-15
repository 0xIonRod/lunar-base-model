# Griffin solar power and cooling study

The three reconstructed array faces supply one 28 V battery bus and a regulated
avionics load and winch converter. Each face has its own lumped temperature, solar-heat input,
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

Temperature acceptance observes change in either direction: a shaded face can
cool while illuminated faces warm. `temperature_k` remains the actual thermal
state. `curve_temperature_k` is the temperature used by the selected electrical
coefficient, with `curve_limited` and `curve_in_range` exposing the distinction.
Griffin authors the selected reference interval, 301.15–413.15 K. Below its cold
end the coefficient is held at the reference as an explicit study assumption;
this does not label the colder physical temperature as calibrated. Exceeding
the upper bound rejects the Modelica step. Cooling, radiant balance, battery
storage and electrical-node conservation remain independently required.

`GEP-005` asks whether the exact USD-generated electrical network closes its
radiative and thermal balances throughout a 3600-second transient under a held
snapshot of its public inputs. Its members must match the authored component
collection. The actual one-hour end temperatures and rates are retained even
when the network has not settled. A false `one_hour_settled_window` is reported
as an observation; it does not turn a physically valid transient into a failed
equilibrium claim.

`GEP-006` asks a separate bounded equilibrium question. It uses the same
unchanged generated network and held-forcing procedure over the source-owned
7200-second horizon. It requires every `GEP-005` closure and coefficient-range
condition, plus `GEP006_StableRateWindow`: each panel's absolute
`mass_heat_flow_w / panelHeatCapacity` must remain at or below the unchanged
`0.001 K/s` threshold throughout at least the final 300-second sampled window.
Every returned point in that window is checked, rather than only the last row.
If the window start lies between requested grid points, the preceding point is
also checked so the observed interval covers the full duration. A non-settling
network fails this case. The 7200-second horizon and 300-second dwell are
computational study parameters, not flight limits; they do not alter heat
capacity, radiation, cooling, geometry or Sun inputs.

Both cases are subsystem experiments, not replays of changing flight attitude,
shadows or terrain. The gate requires the actual linked Modelica document to
match the projected source and retain its generation. `RunModelicaSolve`
receives finite constant input bindings and tolerance `1e-8`; no equations are
copied into the observer. Every requested ten-second grid point and any
additional event samples are checked without downsampling. The gate checks
radiating area, material and environment parameters, exact thermal connectors,
the T⁴ law, full heat balance and bounded coefficient evaluation. Both modes
retain the real one-hour checkpoint, final temperatures and rates, cold
off-calibration rows, maximum window rates and window sample counts. The
explicit `inputs:equilibrium_study` Boolean on the `SustainedThermal` program
selects the case; a missing or malformed mode is rejected. The two thin fixtures reference the same production scene and install the
same observer; their explicit mode selects the transient or equilibrium horizon.

`GEP-004` independently qualifies low-supply protection on the production
vehicle. Its fixture inherits the landing scene, changes only battery capacity
to 0.1 Ah and initial SOC to 0.1, and prescribes zero irradiance at the three
electrical-network boundaries. Those accelerated-depletion inputs are test
conditions, not revised flight or nominal study ratings. A sustained 0.35
thrust request and 0.2 yaw request remain present throughout the eight-second
run. The gate observes a powered interval, solved avionics UVLO, zero computer
draw, suppression of throttle and all three attitude requests within three
fixed intervals, and subsequent main-engine and RCS extinction. The voltage
crossing latch retains converter state through battery rebound after a load
disconnects; algebraic denominator regularization does not own switching. The
rapid voltage transition of this tiny test inventory does not calibrate a real
battery OCV or BMS curve.

Run the positive cases through the normal Twin verification registry:

```sh
luncosim test --scene tests/griffin_power_thermal.usda --verification GriffinPowerThermalRequirements::Verify_GriffinPowerThermal
luncosim test --scene tests/griffin_control_power_loss.usda --verification GriffinPowerThermalRequirements::Verify_GriffinControlPowerLoss
luncosim test --scene tests/griffin_sustained_thermal.usda --verification GriffinPowerThermalRequirements::Verify_GriffinSustainedThermal
luncosim test --scene tests/griffin_equilibrium_thermal.usda --verification GriffinPowerThermalRequirements::Verify_GriffinEquilibriumThermal
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

The current qualification procedure is defined in repository
`tools/qualification.toml`. It requires native source validation and registered
production verdicts, with reports tied to the admitted source revision. Historical
checkpoint temperatures and cached binary hashes do not qualify a changed model.
