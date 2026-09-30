# Griffin paired ramp rail lattice

The reusable section now owns four guide rails: both edges of each physical
walking track. Their stations derive from FLIP's 2 m wheel track, the 580 mm
contact plate and 40 mm guard width: outer centres ±1.31 m, inner centres
±0.69 m. Uprights overlap the plate edge by 10 mm instead of floating away
from it. Common hinge shafts shorten to 2.66 m.

Twelve equal truss bays per 1.799 m section replace four long shallow bays.
Web members are 10 mm, uprights 12 mm and lower chords 25 mm. These are
explicit silhouette estimates from the selected Astrobotic rendering, not
supplier stock dimensions or strength verification. The exact image is now
linked through the typed requirement source catalogue:
https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png

The same builder supports bounded base and individual side-lattice plans.
Assembly plans own base interfaces; repeated trusses inherit from the reusable
component. All 672 redundant local truss opinions were removed through typed
Editor operations, including the toe template, preserving composed geometry.
No new CAD language, Rust mechanism or visual walking-plate copy was added.

Owned API session 49746, terrain asset checkout, installed optimization binary.
Final composed vehicle document 115582256791036, generation 0, projection ready,
17 recipe layers. Typed readback confirmed the inner guide at z=.69 m with
PhysicsCollisionAPI/collision enabled and the twelfth inherited diagonal at
x=1.7241222184 m with canonical translate/rotate/scale order.
Rendered evidence: /tmp/griffin-dense-lattice-section.png and
/tmp/griffin-inherited-lattice-front.png. Deployed ramp requirements and flight
stow fixtures passed; final deployed rerun after ownership cleanup is recorded
in /tmp/griffin-inherited-lattice-ramp-gate.log. Source catalogue and diff checks
passed. These component results do not establish landing or rover traversal.

Next rail issue: the legacy two upper-guide pin visuals are still offset from
native pivot axes, despite the old GRR008 wording. Resolve this mismatch and
its observer before claiming complete hinge-fitting conformance. Public
mechanism dimensions remain unavailable; any lug geometry must be labelled
as an estimate.
