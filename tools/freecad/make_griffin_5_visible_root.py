import math

import FreeCAD as App
import Part


source = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_4_lander.FCStd"
output = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_5_lander.FCStd"

doc = App.openDocument(source)
old = doc.getObject("VisibleLander")
if old is not None:
    doc.removeObject(old.Name)

leaf_shapes = []
for obj in doc.Objects:
    if obj.TypeId != "Part::Feature" or obj.Name in ("VisibleLander", "RampDeployment", "RampJointPackagingNote"):
        continue
    try:
        if not obj.Shape.isNull():
            bounds = obj.Shape.BoundBox
            values = (bounds.XMin, bounds.XMax, bounds.YMin, bounds.YMax, bounds.ZMin, bounds.ZMax)
            lengths = (bounds.XLength, bounds.YLength, bounds.ZLength)
            if (all(math.isfinite(float(value)) for value in values) and
                    all(0.0 <= float(length) < 100000.0 for length in lengths) and
                    max(abs(float(value)) for value in values) < 100000.0):
                leaf_shapes.append(obj.Shape)
    except Exception:
        pass

visible = doc.addObject("Part::Feature", "VisibleLander")
visible.Label = "Griffin-4 lander assembly - visible root"
visible.Shape = Part.makeCompound(leaf_shapes)
visible.addProperty("App::PropertyString", "VisibilityNote", "Display")
visible.VisibilityNote = "Top-level native shape intentionally independent of the hidden source assembly container."
visible.addProperty("App::PropertyString", "Contents", "Display")
visible.Contents = "Lander bus, propulsion, landing gear, power, avionics, and jointed three-section fore/aft ramps."

doc.recompute()
doc.saveAs(output)
print("Griffin-1 iteration 5 saved to: %s" % output)
