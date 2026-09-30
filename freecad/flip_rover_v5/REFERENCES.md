# FLIP v5 reference and source register

Checked 2026-09-30. Every visual reference and public claim has a limited scope. This register does not contain a dimensioned FLIP GA drawing, native flight CAD or complete ICD.

## Primary FLIP configuration and dimensions

| Source | Supports | Does not establish |
|---|---|---|
| [Astrolab FLIP rover page](https://www.astrolab.space/flip-rover/) | Current FLIP/FLEX concept, collapsible solar array, full-size FLEX family wheel/battery relationship, lunar-night intent and appearance | Chassis/wheelbase/track dimensions, exact array mechanism, battery electrical values, as-built geometry |
| [Astrolab Griffin-1 / FLIP announcement, 2025-02-05](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/) | FLIP is the Griffin rover; approx. half-tonne vehicle wording, 30 kg max payload, dust mitigation and mission context | Exact mass-property state, payload inclusion, component breakdown, CAD dimensions |
| [Venturi current rover listing](https://venturi.space/rovers/) | FLIP listing gives 450 kg, 30 kg payload, four-wheel/remote/autonomy/power/speed claims as published on that page | Mass definition, CG/inertia, rated terrain speed test conditions, full performance envelope |
| [LPSC 2026 paper #1874: “The FLIP Mission to Mons Mouton: Project Update”](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf) | Four-wheel skid steer; 480 kg geometry/launch constraint originally set for VIPER; mobility work and mission update | A second rover mass measurement, chassis GA, tire constitutive parameters |
| [Venturi flexible wheel](https://venturi.space/en/wheel/) | Nominal 930 mm wheel-family diameter; 192 sprung cables; 96 springs; construction intent | Exact FLIP tire width/profile, installed wire paths, materials/sections, wheel load and stiffness, loaded radius |
| [Venturi 2025 media kit PDF](https://venturi.space/wp-content/uploads/2025/06/en-venturi-space-media-kit.pdf), p.8 | Two FLIP battery packs described as mounted behind solar panels | Pack geometry, exact mounting frame/motion owner, voltage/Wh/cell arrangement/mass |
| [Astrolab NASA payload announcement, 2026-05-18](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/) | Public NASA payload identities METAL, LRA, LDES and Lunar LiDAR; broad intended purpose | Complete 13-payload manifest, envelope/mass/interfaces/loads |
| [Canadensys FLIP camera post](https://www.linkedin.com/posts/canadensys-aerospace-corporation_we-are-excited-to-work-with-our-partners-activity-7456288136374087680-pb-O) | Two opposing cameras associated with solar mast; array deployment activity | Camera geometry, exact poses/FOV, flight drawings |
| [Astrolab LiDAR post](https://www.linkedin.com/posts/astrolabspace_nasa-lunarrover-astrolab-activity-7463274130654793730-DpYR) | LiDAR for high-resolution 3D mapping/navigation/hazard avoidance | Unit volume/pose, point cloud interface/accuracy |

The listed FLIP speed values are not normalized: Venturi's current FLIP listing says 20 km/h, while its general wheel-family material mentions 15 km/h. Do not treat either as a simulator or mission limit until the configuration owner resolves its applicability. Likewise, keep the 450 kg vehicle listing distinct from the LPSC 480 kg payload/launch envelope.

## SysML notation used for the requirements baseline

- [OMG Systems Modeling Language v2.0](https://www.omg.org/spec/SysML/2.0) is the normative language reference.
- [Official SysML v2 Vehicle Example](https://github.com/Systems-Modeling/SysML-v2-Release/blob/master/sysml/src/examples/Vehicle%20Example/SysML%20v2%20Spec%20Annex%20A%20SimpleVehicleModel.sysml) demonstrates quantity-typed values such as `ISQ::mass` and unit-bearing literals such as `[SI::kg]`.
- [Official SysML v2 verification-case example](https://github.com/Systems-Modeling/SysML-v2-Release/blob/master/sysml/src/training/34.%20Verification/Verification%20Case%20Definition%20Example.sysml) demonstrates `verification def`, an `objective`, and `verify` usages.

The FLIP baseline uses the standard ISQ/SI quantity and unit notation for physical dimensions; a project SysML parser/compiler was not present in this checkout, so syntax was checked against the official examples but the package is **not reported as parser-compiled**.

## Appearance references

| File | Provenance and allowed use |
|---|---|
| [`references/reference_astrolab_driveout.jpg`](references/reference_astrolab_driveout.jpg) | Astrolab primary public render/photo reference; use for overall upright-array/low-body/open-wheel appearance only |
| [`references/reference_astrolab_detail.jpg`](references/reference_astrolab_detail.jpg) | Astrolab primary detail reference; appearance only, no scale/dimension inference |
| [`references/reference_venturi_iac2024.jpg`](references/reference_venturi_iac2024.jpg) | Venturi IAC 2024 development prototype; supports open wheel-web appearance, not flight finish, array segmentation, or dimensions |
| [`references/reference_venturi_flip.jpg`](references/reference_venturi_flip.jpg) | Additional supplier concept imagery; secondary comparison and not a simultaneous configuration target |
| [`references/user_render.png`](references/user_render.png) | User-supplied image from this conversation; direct visual reference for white panel frame/cells, wheels, equipment box and wheel-face inset; not a dimensioned drawing |
| [`references/user_wheel_photo.png`](references/user_wheel_photo.png) | User-supplied close view; visual clue for recessed inner rim face; cannot determine eccentricity or actual offset magnitude |

## CAD choices not attributed to the rover

The 280 mm wheel width, 1,700 mm wheelbase, 2,000 mm track, 65 mm inner-face inset, hub/spoke outlines, 80 graphic solar cells, 1,800 × 1,380 mm backplate, 0–90° presentation motion and 82° deployed pose are labeled study choices. The CAD recess is axial/concentric; the source photograph cannot distinguish an inset face from a perspective or an eccentric/offset hub. No eccentric axle is invented. The fine coil placement and dimensions do not reproduce proprietary spring geometry.
