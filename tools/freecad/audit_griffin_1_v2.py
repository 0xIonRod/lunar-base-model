"""Reproducible clearance audit for the corrected Griffin-1 study model."""

import FreeCAD as App

PATH = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_1_lander.FCStd"
TOLERANCE_VOLUME = 1.0


def overlaps(a, b):
    aa, bb = a.BoundBox, b.BoundBox
    return not (aa.XMax <= bb.XMin or bb.XMax <= aa.XMin or
                aa.YMax <= bb.YMin or bb.YMax <= aa.YMin or
                aa.ZMax <= bb.ZMin or bb.ZMax <= aa.ZMin)


doc = App.openDocument(PATH)
doc.recompute()
all_solids = [o for o in doc.Objects if o.TypeId == "Part::Feature"]
active = [o for o in all_solids if getattr(o, "CollisionEnabled", True)]
invalid = []
for obj in all_solids:
    if obj.Shape.isNull() or not obj.Shape.isValid() or obj.Shape.Volume <= 0:
        invalid.append(obj.Label)

collisions = []
for i, left in enumerate(active):
    for right in active[i + 1:]:
        if overlaps(left.Shape, right.Shape):
            volume = left.Shape.common(right.Shape).Volume
            if volume > TOLERANCE_VOLUME:
                collisions.append((left.Label, right.Label, round(volume, 2)))

print("DOCUMENT", doc.Label)
print("ALL_SOLIDS", len(all_solids))
print("COLLISION_ENABLED_SOLIDS", len(active))
print("INVALID", len(invalid))
print("INTERFERENCES", len(collisions))
for item in sorted(collisions, key=lambda x: x[2], reverse=True):
    print("INTERFERENCE", item)
print("JOINTS", [o.Name for o in doc.Objects if "Joint" in o.Name])
meta = doc.getObject("EngineeringAudit")
print("STATUS", getattr(meta, "Status", "missing"))
App.closeDocument(doc.Name)
