# Griffin and FLIP packaging correction — 2026-10-22

The operator identified three coupled presentation errors: ramps leaning away
from the lander, an inward-fold trial hitting FLIP, and landing gear indexed to
the wrong solar faces. The previous dimensional gates accepted those authored
assumptions; they did not establish photographic fidelity.

The correction increases the bus study from 3.60 m to 4.50 m and reconstructs
the interfaces as one assembly. The 3.60 m choice had been an arbitrary 80%
reduction of a historical overall-envelope label. The wider frame fits the
existing solar-bank proportions much more closely. A 4.50 m **bus** remains a
reconstruction estimate, not a measured current flight dimension.

| Item | Previous study | Revised study | Basis |
| --- | --- | --- | --- |
| Bus lateral span | 3.600 m | 4.500 m | Reconstruction estimate from the integrated bus, array and payload proportions; current flight ICD unavailable. |
| Tire diameter | 0.900 m | 0.930 m | Venturi's published FLEX wheel diameter and Astrolab's statement that FLIP uses the full-size FLEX wheels. Flight tire shape under load remains unqualified. |
| FLIP wheelbase | 1.700 m | 1.300 m | Compact proportions in Astrolab's official drive-out rendering; **image-based estimate**, not supplier metrology. |
| FLIP chassis length | 2.116 m | 1.800 m | Same reconstruction; inner equipment/deck length 1.784 m. |
| FLIP longitudinal wheel envelope | 2.600 m | 2.230 m | Wheelbase plus tire diameter. Consistent with the qualitative “more than 7 feet” manufacturer statement; that statement is not a 2.13 m exact dimension. |
| Landing-gear indexing | Diagonal to broad array faces | Broad-face normals, a relative 45° correction | June 2026 hardware shows a shock emerging through the lower opening in a broad panel. Upper anchors and the reusable bracket now seat at the broad bus face. |
| Root ramp transport angle | 45°, outward | 120°, thirty degrees inward from vertical | The early mockup and public concept establish inward folding. **120° and 125° study travel are packaging choices**, not released flight angles or actuator specifications. |

Solar facet positions, cell contours and collecting normals retain their
existing common owner. Moving only the array bank would also move its faces
toward the ramp exit channels. Correcting the relative leg indexing instead
aligns the photographed opening while retaining those channels. Physical leg
roots, body-owned barrels, sliders and source-linked collision proxies move
together. The root hinge motor target and fixed flight latch match each new
ramp pose. Hosted FLIP height and its fixed dock follow the revised tire radius.

The 4.40 m perimeter deck, 4.30 m lower skirt, collision proxies, rail datums,
array brackets, eight perimeter-deck beam colliders, gear upper anchors,
antenna stations and RCS mounts follow
the wider bus. Twenty-four small radial links bridge the retained inner tank
module to the outer frame; the tank bores and their clearances are retained.
Transition plates increase from 0.90 m to 1.35 m so their inboard edges retain
the previous overlap across the entire tire corridor, including the clipped
payload-deck corners. Their source-derived inertia changes with their length.
Support stock, attachments and load paths are appearance estimates; their
structural strength has not been qualified.

The retained 2.687006 m radial foot reach is an estimate inherited from the
diagonal layout. After rotation, the cardinal pad envelope is approximately
6.074 m, rather than the old advertised 4.50 m X/Z approximation. Neither is
established as current Griffin flight metrology. The historical 4.5 m overall
concept label must not be treated as a bus-face dimension. Absolute bus, foot
reach, panel and payload-interface dimensions still require a current ICD.

The preserved FreeCAD artifact and `FlipCadRequirements` are unchanged.
`FlipRequirements::FlipPackagingStudy` owns the selected Twin reconstruction
separately from that CAD variant. This checkpoint qualifies the authored Twin
geometry only. Native wheel/contact parameters remain study
proxies; the existing optimization-owned loaded-support drift and engine-off
impact findings remain open. No solver dependency, substep, friction, mass,
spring force cap or numerical acceptance tolerance is changed.

References:

- [Venturi wheel press release, 19 June 2023](https://www.venturi.com/wp-content/uploads/2023/06/PR_19_06_2023.pdf): 930 mm wheel diameter.
- [Astrolab FLIP](https://www.astrolab.space/flip-rover/): full-size FLEX tires.
- [Astrolab official drive-out rendering](https://www.astrolab.space/wp-content/uploads/2025/06/07-FLIPv2-DriveOut.4K1-2-2048x1152.jpg): compact chassis and axle-spacing proportions; concept imagery, not calibrated CAD.
- [Astrolab company updates](https://www.linkedin.com/company/astrolabspace): qualitative length statement, accessed 2026-10-22.
- [NASA/Astrobotic hardware photograph, 15 June 2026](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/): broad panel opening and landing-gear relationship.
- [Astrolab LPSC 2026 project update](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf): four-wheel skid steering, VIPER envelope/480 kg launch constraint, current integration photograph; no numerical chassis/wheelbase dimensions.

The saved assembly was reviewed in a fresh production process at 1280 × 720,
High quality, in the Editor. The [review image](evidence/griffin-packaging-2026-10-22.png)
shows the compact rover between inward-folded ramps and the front leg aligned
with the panel opening.

Native f64 static-clearance inspection compared 23,848 ramp/rover part pairs.
Eight conservative world-axis envelopes overlapped; all eight were separated
when refined with the native cooked mesh vertices and oriented bounds, with
minimum separating-axis margin 0.159100249 m for those refined pairs. The other
23,840 coarse comparisons were separated. Across 3,840 solar-panel/leg part
pairs, no conservative envelopes overlapped; the minimum separating-axis
margin was 0.130396206 m. These are stowed-pose geometry checks, not continuous
swept-volume or loaded deployment qualification.

The full mounted SysML source set validates at revision
`17798372683716093098` with no errors and 153 lint warnings. A standalone
per-file CLI attempt cannot resolve this Twin's cross-file SysML names or
`twin://` USD references without its mounted namespace; those diagnostics are
retained with the local logs and are not claimed as passing validation.

At this geometry checkpoint, mounted vehicle USD validation reported nine
solar direction-port and IMU gravity connection findings. The subsequent
[interface and battery review](griffin-interface-validation-2026-10-22.md)
records their repair and current preflight results; the receipt below retains
the original source revision and its validation boundary.

The [production receipt](evidence/griffin-packaging-2026-10-22.json) records
154 source hashes and **16 passing selected cases**: nine assembly/geometry
cases, solar layout, five FLIP component cases, and RCS runtime. The seventeenth
selected case, pilot attitude, is **inconclusive**: the external 240 s wall-clock
harness limit terminated it before an authored verdict. Descent was armed, but
settled touchdown did not qualify before the run ended. This is not the
fixture's own 150 s simulation-time timeout verdict.

An earlier wider/inward source revision (`1816606438305106943`) failed pilot
attitude on ramp relative rate, 4.276409769 rad/s against 0.02 rad/s, while its
peak relative angle remained 0.001426458 rad against 0.035 rad. This belongs to
that earlier source, not a numerical measurement on the final saved geometry.
Both observations are handed to optimization with the prior loaded-support
fixture. No tolerance was relaxed.
The 60 FPS real-time-physics target and full mission acceptance remain open.
