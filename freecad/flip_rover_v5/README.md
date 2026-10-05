# FLIP rover v5 visual CAD study

This folder contains the newest native FreeCAD delivery file, its input snapshot, the parameter ledger, source imagery, build/presentation scripts, and verification evidence for the 2026-09-30 public-source iteration.

## Open the model

Open [`FLIP_rover_v5.FCStd`](FLIP_rover_v5.FCStd) in FreeCAD 1.1 or later. It opens in the deployed **82° presentation pose**. The 0° stowed pose and other samples are available through the CAD study motion object. Neither pose is a published FLIP flight-hinge limit.

![Deployed v5 FreeCAD study](deployed.png)

## Rebuild and audit

From this directory in PowerShell, using FreeCAD 1.1:

```powershell
& 'C:\Program Files\FreeCAD 1.1\bin\FreeCADCmd.exe' .\build_v5.py
& 'C:\Program Files\FreeCAD 1.1\bin\FreeCAD.exe' .\present_v5.FCMacro
& 'C:\Program Files\FreeCAD 1.1\bin\FreeCADCmd.exe' .\audit_v5.py
```

The build script regenerates `FLIP_rover_v5_geometry.FCStd` from the frozen `FLIP_rover_v4_input.FCStd` source snapshot. The presentation macro creates/reopens the delivery file and writes named renders. The audit reads the saved delivery and writes `audit_v5.json`. A successful B-rep or sampled pose check is not physical performance or continuous collision proof.

## Export USD

`FLIP_rover_v5.usdc` is the self-contained, binary USD visual export in this
folder. It contains the 195 named colored CAD feature meshes in the saved 82°
pose. The export uses Y-up, metres, and the saved FreeCAD global placements;
global transforms are baked into the mesh points once. It is visual-only and
contains no colliders, mass properties, physics joints, or live solar motion.

The exporter uses FreeCAD 1.1 and Pixar OpenUSD's `usd-core` Python package.
From this folder in PowerShell, install the USD module into a temporary package
directory and run the script:

```powershell
$usdPythonPath = Join-Path $env:TEMP 'flip-usd-core-26.8'
& 'C:\Program Files\FreeCAD 1.1\bin\python.exe' -m pip install --target $usdPythonPath usd-core==26.8
$env:FLIP_USD_PXR_PATH = $usdPythonPath
& 'C:\Program Files\FreeCAD 1.1\bin\freecadcmd.exe' .\export_v5_usd.py
```

The script rewrites `FLIP_rover_v5.usdc` and `usd_export_report.json` from the
saved `FLIP_rover_v5.FCStd`. It uses 1 mm tessellation for general geometry and
2 mm for visual cable/spring details to keep the detailed wheel assembly
practical to serialize. The USD mesh remains a tessellated approximation; the
FCStd file is the editable source.

## Simulation study delivery

Register this folder as Twin `flip_rover_v5` in LunCoSim and open the default
scene `FLIP_simulation.usda` from `twin.toml`. The five `FLIP_visual_*.usda`
layers preserve CAD geometry; hidden physics proxies provide rigid bodies,
wheel contacts and the panel hinge. This scene also requires LunCoSim's bundled
`skid_rover.usda` and `lunar_surface.usda`; it is not standalone OpenUSD.

See [`DELIVERY_REPORT.md`](DELIVERY_REPORT.md) for tested evidence, known engine
limitations, excluded scratch files and blocked authoring helpers. The delivered
saved scenes are usable study artifacts, not a qualified rebuild workflow or
flight mechanics model. Local engine fixes are not included in this repository.

## Delivered evidence

- [`parameters_v5.json`](parameters_v5.json): public facts, study choices, unknowns and units/status.
- [`LUNCO_SIM_RECREATION.md`](LUNCO_SIM_RECREATION.md): USD, Modelica, generic Rust and Twin-local Rhai implementation sequence and verification gates.
- [`FLIP_rover_v5.usdc`](FLIP_rover_v5.usdc): named, colored, visual-only USD snapshot.
- [`export_v5_usd.py`](export_v5_usd.py) and [`usd_export_report.json`](usd_export_report.json): reproducible USD export and measured frame/mesh evidence.
- [`REFERENCES.md`](REFERENCES.md): source/claim boundaries and local visual references.
- [`REVIEW.md`](REVIEW.md): measured dimensions, model hash, integrity results, limitations and requirement status.
- `deployed.png`, `stowed.png`, `front.png`, `side.png`, `top.png`, `wheel_face.png`, `wheel_oblique.png`, `hinge.png`, `equipment_cutaway.png`: native FreeCAD presentation views.
- [`build_v5_report.json`](build_v5_report.json), [`presentation.json`](presentation.json), and [`audit_v5.json`](audit_v5.json): rebuild/presentation/audit evidence when generated.

The CAD uses a public 930 mm family wheel diameter and public wheel-detail counts, but all other layout sizes remain visibly labeled study choices unless sourced. It does not claim exact as-built resemblance because no dimensioned FLIP GA, source CAD or released flight ICD was found publicly. No mass or inertia is assigned from visual solids; spring coil solids are render-only.
