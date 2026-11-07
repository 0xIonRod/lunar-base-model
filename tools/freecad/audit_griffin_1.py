"""Read-only engineering audit for the Griffin-1 FreeCAD study document."""

import FreeCAD as App


PATH = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_1_lander.FCStd"
TOLERANCE_VOLUME = 1.0  # mm^3; ignores coincident faces and numerical noise


def direct_group_map(doc):
    mapping = {}
    for obj in doc.Objects:
        if hasattr(obj, "Group"):
            for child in obj.Group:
                mapping[child.Name] = obj.Label
    return mapping


def overlaps(a, b):
    aa, bb = a.BoundBox, b.BoundBox
    return not (aa.XMax <= bb.XMin or bb.XMax <= aa.XMin or
                aa.YMax <= bb.YMin or bb.YMax <= aa.YMin or
                aa.ZMax <= bb.ZMin or bb.ZMax <= aa.ZMin)


doc = App.openDocument(PATH)
doc.recompute()
group_map = direct_group_map(doc)
features = [o for o in doc.Objects if o.TypeId == "Part::Feature"]

invalid = []
for obj in features:
    shape = obj.Shape
    if shape.isNull() or not shape.isValid():
        invalid.append((obj.Name, obj.Label, "null/invalid shape"))
    elif shape.Volume <= 0:
        invalid.append((obj.Name, obj.Label, "non-positive volume"))

collisions = []
for i, left in enumerate(features):
    for right in features[i + 1:]:
        if not overlaps(left.Shape, right.Shape):
            continue
        common = left.Shape.common(right.Shape)
        if common.Volume > TOLERANCE_VOLUME:
            collisions.append({
                "left": left.Label,
                "right": right.Label,
                "volume_mm3": round(common.Volume, 2),
                "left_group": group_map.get(left.Name, "unassigned"),
                "right_group": group_map.get(right.Name, "unassigned"),
            })

print("DOCUMENT", doc.Label)
print("FEATURES", len(features))
print("INVALID", len(invalid))
for item in invalid:
    print("INVALID_ITEM", item)
print("INTERFERENCES", len(collisions))
for item in sorted(collisions, key=lambda x: x["volume_mm3"], reverse=True)[:80]:
    print("INTERFERENCE", item)

expected_groups = [
    "01 Main bus and structure",
    "02 Wraparound solar-panel walls",
    "03 Gold-wrapped upper tanks",
    "04 Central payload and egress",
    "05 Corner avionics / sensor pods",
    "06 Splayed landing gear",
    "07 Thrusters and service hardware",
]
present_groups = [o.Label for o in doc.Objects if o.TypeId == "App::Part"]
for name in expected_groups:
    print("GROUP", name, "OK" if name in present_groups else "MISSING")

joint_names = [o.Name for o in doc.Objects if "Joint" in o.Name or "Hinge" in o.Name]
print("JOINT_LIKE_OBJECTS", joint_names)

doc.close()
