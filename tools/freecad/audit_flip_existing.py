"""Read-only audit of an existing FLIP document using FreeCAD's geometry kernel.

Run with FreeCAD's bundled python.exe, optionally --gui for native view captures.
Never saves or rebuilds the source document.
"""
import argparse
import hashlib
import itertools
import json
from pathlib import Path

import FreeCAD as App
import Part


def bounds(shape):
    b = shape.BoundBox
    return dict(min_mm=[b.XMin, b.YMin, b.ZMin], max_mm=[b.XMax, b.YMax, b.ZMax],
                size_mm=[b.XLength, b.YLength, b.ZLength])


def world_shape(obj):
    shape = obj.Shape.copy()
    shape.Placement = obj.getGlobalPlacement()
    return shape


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--gui', action='store_true')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    before = hashlib.sha256(args.source.read_bytes()).hexdigest()
    if args.gui:
        import FreeCADGui as Gui
        Gui.showMainWindow()
    doc = App.openDocument(str(args.source))
    objects = [o for o in doc.Objects if o.TypeId == 'Part::Feature' and not o.Shape.isNull()]
    shapes = {o.Name: world_shape(o) for o in objects}
    report = dict(source=str(args.source.resolve()), sha256=before, freecad=App.Version(),
                  units='mm; mm^3 for volumes', label=doc.Label,
                  object_count=len(doc.Objects), objects=[], intersections=[], suspension_connectivity=[])
    for obj in doc.Objects:
        row = dict(name=obj.Name, label=obj.Label, type=obj.TypeId,
                   parents=[p.Name for p in obj.InList], properties={})
        for prop in obj.PropertiesList:
            if obj.getGroupOfProperty(prop) in ('Documentation', 'Provenance', 'Engineering', 'Dimensions', 'Mobility', 'Joint', 'Physics study', 'Design', 'Payload', 'Power'):
                try:
                    row['properties'][prop] = str(getattr(obj, prop))
                except Exception as exc:
                    row['properties'][prop] = str(exc)
        if obj.Name in shapes:
            s = shapes[obj.Name]
            row.update(bounds(s))
            row.update(valid=s.isValid(), solids=len(s.Solids), volume_mm3=s.Volume)
        report['objects'].append(row)
    report['overall'] = bounds(Part.makeCompound(list(shapes.values())))
    sheet = doc.getObject('Parameters')
    report['parameters'] = []
    if sheet:
        for i in range(1, 20):
            row = []
            for column in 'ABC':
                try:
                    row.append(str(sheet.get(column + str(i))))
                except Exception:
                    row.append('')
            if any(row):
                report['parameters'].append(row)
    for a, b in itertools.combinations(objects, 2):
        sa, sb = shapes[a.Name], shapes[b.Name]
        if not sa.BoundBox.intersect(sb.BoundBox):
            continue
        try:
            volume = sa.common(sb).Volume
            if volume > 1.0:
                report['intersections'].append(dict(a=a.Name, b=b.Name, volume_mm3=volume))
        except Exception as exc:
            report['intersections'].append(dict(a=a.Name, b=b.Name, error=str(exc)))
    for obj in objects:
        if obj.Name.startswith('Suspension_'):
            solids = shapes[obj.Name].Solids
            report['suspension_connectivity'].append(dict(name=obj.Name, solids=len(solids),
                pair_distances_mm=[a.distToShape(b)[0] for a,b in itertools.combinations(solids,2)]))
    report['solar_joint_present'] = doc.getObject('SolarArrayJoint') is not None
    report['solar_child_body_present'] = doc.getObject('SolarArrayPanelBody') is not None
    report['mass_property_objects'] = [o.Name for o in doc.Objects if any(p.lower() in ('mass','density','inertia','centerofmass') for p in o.PropertiesList)]
    if args.gui:
        view = Gui.activeDocument().activeView()
        from PySide import QtCore
        def settle():
            loop = QtCore.QEventLoop()
            QtCore.QTimer.singleShot(800, loop.quit)
            loop.exec_()
            Gui.updateGui()
        view.setCameraType('Orthographic')
        # The document is Y-up; FreeCAD's standard isometric is Z-up.
        # Compose a display-only rotation to show lunar up vertically.
        view.viewAxonometric()
        standard = view.getCameraOrientation()
        view.setCameraOrientation((App.Rotation(App.Vector(1,0,0),-90).multiply(standard)).Q)
        view.fitAll()
        settle()
        view.saveImage(str(args.output/'cad_isometric.png'),1600,1200,'White')
        for name, direction, up in [('front',(0,0,1),(0,1,0)),('side',(1,0,0),(0,1,0)),('top',(0,1,0),(0,0,-1))]:
            orientation=App.Rotation(App.Vector(1,0,0),App.Vector(*up),App.Vector(*direction),'ZYX')
            view.setCameraOrientation(orientation.Q)
            settle()
            view.fitAll()
            settle()
            view.saveImage(str(args.output/('cad_'+name+'.png')),1600,1200,'White')
        view.viewAxonometric()
        view.setCameraOrientation((App.Rotation(App.Vector(1,0,0),-90).multiply(standard)).Q)
        view.fitAll()
        Gui.updateGui()
    after = hashlib.sha256(args.source.read_bytes()).hexdigest()
    report['source_unchanged'] = before == after
    (args.output/'cad_audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(dict(source=report['source'],sha256=before,overall=report['overall'],
                         shape_count=len(objects),intersections=len(report['intersections']),
                         solar_joint_present=report['solar_joint_present'],source_unchanged=before==after)))
    App.closeDocument(doc.Name)


if __name__ == '__main__':
    main()
