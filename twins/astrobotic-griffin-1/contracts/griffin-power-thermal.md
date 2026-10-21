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
Production low-battery and disconnected-network negative cases remain to be
qualified. The coolant boundary remains ideal and unlimited in total energy.
