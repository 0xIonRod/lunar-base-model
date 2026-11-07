import time

import FreeCAD as App
import FreeCADGui as Gui


path = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_4_lander.FCStd"
doc = App.openDocument(path)
App.setActiveDocument(doc.Name)
Gui.setActiveDocument(doc.Name)
gui_doc = Gui.activeDocument()

# Set the container first, then all descendants through the GUI view
# providers.  This is the state FreeCAD uses for the tree eye icons.
for obj_name in ("Griffin2", "Structure", "Propulsion", "LandingGear", "PayloadDeck",
                  "Power", "Egress", "Avionics", "Documentation"):
    try:
        gui_doc.getObject(obj_name).Visibility = True
    except Exception:
        pass
for obj in doc.Objects:
    try:
        gui_doc.getObject(obj.Name).Visibility = True
    except Exception:
        pass

doc.recompute()
gui_doc.activeView().viewAxonometric()
gui_doc.activeView().fitAll()
Gui.updateGui()
time.sleep(2.0)
doc.recompute()
doc.saveAs(path)
Gui.updateGui()
time.sleep(1.0)
gui_doc.activeView().saveImage(
    r"C:\Users\salek\OneDrive\Documents\CAD\griffin_4_visibility_check3.png",
    1600, 1000, "Current")
print("GUI visibility repair 2 saved: %s" % path, flush=True)
