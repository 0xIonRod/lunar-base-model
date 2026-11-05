import time

import FreeCAD as App
import FreeCADGui as Gui


path = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_4_lander.FCStd"
doc = App.openDocument(path)
gui_doc = Gui.activeDocument()

for obj in doc.Objects:
    try:
        obj.ViewObject.Visibility = True
    except Exception:
        pass
    try:
        gui_doc.getObject(obj.Name).Visibility = True
    except Exception:
        pass

doc.recompute()
gui_doc.activeView().viewAxonometric()
gui_doc.activeView().fitAll()
Gui.updateGui()
time.sleep(3.0)
doc.recompute()
doc.saveAs(path)
Gui.updateGui()
time.sleep(1.0)
gui_doc.activeView().saveImage(
    r"C:\Users\salek\OneDrive\Documents\CAD\griffin_4_visibility_check4.png",
    1600, 1000, "Current")
print("GUI visibility repair 3 saved: %s" % path, flush=True)
