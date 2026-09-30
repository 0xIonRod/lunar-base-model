# Medium-gain panel checkpoint

Added a bus-owned flat medium-gain panel and compact mounting block. Shape is
inferred from Astrobotic PUG August 2021 v5.02 pages 20 and 30:
https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf.
Page 20 illustrates Peregrine hardware; page 30 labels Griffin's medium-gain
antenna and describes shared communication specifications. The enclosure,
station and parked orientation are explicit reconstruction assumptions in
GriffinVisualConfiguration, not released Griffin dimensions.

The bracket seats on the outer skin, including its 25 mm extrusion. Fresh
composed scene document 115593119049538, view 11, generation 0, reported the
radome at world (0.792, 1.52, -1.88), dimensions (0.32, 0.28, 0.04) metres.
The paired screenshot is `griffin-medium-gain-review-2026-10-01.png`.
The final GRIFFIN_FLIP_VISUAL fixture passed 117 checks in 8 ticks, seed
6840157149251759617, one thread, zero jitter, 60 Hz. This is static visual
component evidence; mission acceptance remains open.

## Editor readback issue

Native Rhai `assembly_edit::batch` persisted the operations, but composed
readback could remain stale while `projection_ready` was true. At generation
22 the new radome returned 404; at generation 27 the saved antenna parent
translation was (0.792, 0.18, -1.825) while QueryUsdPrim returned the previous
(0.792, 0.18, -1.8). A fresh owned preview resolved the correct saved result.
The final evidence above comes from that fresh composition. Investigate the
native ApplyUsdOps projection path before trusting its ready fence alone.
