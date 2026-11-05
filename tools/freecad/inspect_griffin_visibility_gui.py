import FreeCAD as App
import FreeCADGui as Gui


path = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_4_lander.FCStd"
doc = App.openDocument(path)
print("DOCUMENT", doc.Name, flush=True)
for obj in doc.Objects:
    app_vis = "ERR"
    gui_vis = "ERR"
    try:
        app_vis = obj.ViewObject.Visibility
    except Exception as exc:
        app_vis = "ERR:%s" % exc
    try:
        gui_vis = Gui.activeDocument().getObject(obj.Name).Visibility
    except Exception as exc:
        gui_vis = "ERR:%s" % exc
    if obj.Name in ("Griffin2", "Structure", "Egress", "PrimaryBus", "AftRampPanel_01", "ForeRampPanel_01"):
        print("CHECK", obj.Name, obj.TypeId, "APP", app_vis, "GUI", gui_vis, flush=True)
Gui.activeDocument().activeView().viewAxonometric()
Gui.activeDocument().activeView().fitAll()
Gui.activeDocument().activeView().saveImage(
    r"C:\Users\salek\OneDrive\Documents\CAD\griffin_4_visibility_check2.png",
    1600, 1000, "Current")
