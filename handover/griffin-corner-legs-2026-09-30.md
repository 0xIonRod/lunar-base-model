# Griffin corner-leg correction

Supersedes the cardinal planform placements in the preceding under-body mount handover.

Four physical/visual foot stations now sit at X/Z=(+/-1.90,+/-1.90), Y=.90. Their local +X axes point outward along the four chamfer normals. Legacy instance names remain stable IDs. Primary shock upper anchors meet the 3.60 m octagon's chamfer midpoints; sleeve tops still meet the lower body edge. Braces connect to two separate skirt-frame points. Exact coordinates are explicit packaging estimates derived from the existing body profile, skirt stations and selected 4.50 m X/Z footprint. Reference: user-selected Astrobotic rendering, https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ . The diagonal footprint exceeds the X/Z span; the former 1.90 m radial-station rationale no longer applies.

The typed builder now updates suspension-frame orientations when station yaw changes. This was previously missing: the corner roots changed but the joint frames retained the old yaw, and the existing seating gate correctly failed. Both frames now seat the authored leg orientation and retain vertical +Y travel. Foot Y/contact geometry and the derived suspension target are unchanged.

Validation: landing-leg component gate passes (/tmp/griffin-corner-leg-final-gate.log), including joint frame seating, source/composed endpoint closure, and primary mounts at the chamfer/lower-belt datums. Requirement source catalog passes; git diff --check passes. Fresh owned Editor API49746 reopened saved assets for review (/tmp/griffin-corner-review.png). These checks establish geometry consistency, not flight leg kinematics or visual acceptance of the whole lander.

Next visible issue: the square-stock payload support ring and wheel rails dominate the upper silhouette and obscure the COPV domes. Their stock should be reduced as an explicit estimate while keeping the wheel support top at Y2.08 and changing visual/contact geometry together.
