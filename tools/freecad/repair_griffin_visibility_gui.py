import FreeCAD as App
import FreeCADGui as Gui


path = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_4_lander.FCStd"
doc = App.openDocument(path)
Gui.activeDocument().activeView().setAnimationEnabled(False)

# FreeCADCmd has no GUI ViewObject state.  This repair intentionally runs in
# the full GUI and sets both the document objects and their GUI wrappers.
for obj in doc.Objects:
    try:
        obj.ViewObject.Visibility = True
    except Exception:
        pass
    try:
        Gui.activeDocument().getObject(obj.Name).Visibility = True
    except Exception:
        pass

doc.recompute()
Gui.activeDocument().activeView().viewAxonometric()
Gui.activeDocument().activeView().fitAll()
doc.recompute()
doc.save()
Gui.activeDocument().activeView().saveImage(
    r"C:\\Users\\salek\\OneDrive\\Documents\\CAD\\griffin_4_visibility_check.png",
    1600, 1000, "Current")
print("GUI visibility repair saved: %s" % path)
