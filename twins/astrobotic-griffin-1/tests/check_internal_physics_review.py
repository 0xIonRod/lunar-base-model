"""Check the open Griffin vehicle's installed tank, panel and mount geometry."""
import argparse
import json
import math
import urllib.request


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Stage:
    def __init__(self, port, doc):
        self.url = f"http://127.0.0.1:{port}/api/commands"
        self.doc = doc
        self.snapshot = None

    def command(self, name, **params):
        body = json.dumps({"type": "ExecuteCommand", "command": name, "params": params}).encode()
        req = urllib.request.Request(self.url, body, {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=90) as response:
            result = json.load(response)
        return result.get("data", result)

    def read(self, paths, attrs, **options):
        records = self.command("QueryUsdPrims", doc_id=self.doc, paths=paths,
                               attrs=attrs, **options)["records"]
        require([r["path"] for r in records] == paths, "Incomplete composed observation")
        for record in records:
            stamp = (record["doc_id"], record["document_generation"], record["stage_generation"])
            if self.snapshot is None:
                self.snapshot = stamp
            require(stamp == self.snapshot, "The vehicle changed during the check")
        return records

    def source(self, expression):
        text = self.command("RunRhai", code=f"print({expression});")["stdout"]
        return json.loads(text)


def check_tanks(stage, root):
    prop = root + "/MainPropulsion/"
    location = "collection:storageLocations:includes"
    status = prop + "PropellantStatus"
    study = "GriffinPropulsionRequirements::GriffinPropellantMassStudy::"
    model = "sysml_requirements::model()"
    keys = ["dryMassKg", "dryComXM", "dryComYM", "dryComZM", "dryInertiaXxKgM2",
            "dryInertiaYyKgM2", "dryInertiaZzKgM2"]
    source = stage.source("[" + ",".join(f'{model}.value("{study}{k}")' for k in keys) + "]")
    loads = [(source[0], source[1:4])]
    stations = []
    expected_inputs = {"inputs:dry_mass_kg": source[0]}
    for i, axis in enumerate("xyz"):
        expected_inputs["inputs:dry_com_" + axis + "_m"] = source[1+i]
        expected_inputs[f"inputs:dry_inertia_{axis}{axis}_kg_m2"] = source[4+i]
    for species in ("fuel", "oxidizer"):
        path = prop + species.capitalize() + "Tank"
        rec, = stage.read([path], ["inputs:initial_mass_kg", "collection:storageLocations:expansionRule"],
                          rels=[location], schemas=True)
        members = rec["relationships"][location]
        assigned = stage.source(f'{model}.value("{study}{species}TankInstances").map(|m| m.literal)')
        require(members == [root + "/" + name for name in assigned] and len(members) == 2, path)
        require({"LunCoProgramAPI", "CollectionAPI:storageLocations"} <= set(rec["api_schemas"])
                and rec["attrs"]["collection:storageLocations:expansionRule"] == "explicitOnly", path)
        mass = rec["attrs"]["inputs:initial_mass_kg"]
        require(mass >= 0, path)
        pts = [r["attrs"]["xformOp:translate"] for r in stage.read(members, ["xformOp:translate"])]
        centroid = [(a+b)/2 for a, b in zip(*pts)]
        for i, axis in enumerate("xyz"):
            spread = sum(sum((p[j]-centroid[j])**2 for j in range(3) if i != j) for p in pts)/2
            expected_inputs[f"inputs:{species}_position_{axis}_m"] = centroid[i]
            expected_inputs[f"inputs:{species}_specific_inertia_{axis}{axis}_m2"] = spread
        loads.extend((mass/2, p) for p in pts)
        stations.extend(members)
    require(len(set(stations)) == 4, "A tank station belongs to both reservoirs")
    pending = stations.copy()
    checked = 0
    while pending:
        batch, pending = pending[:32], pending[32:]
        for r in stage.read(batch, ["physics:mass", "physics:density"], schemas=True, children=True):
            require(all(v is None for v in r["attrs"].values()) and not
                    {"PhysicsMassAPI", "PhysicsRigidBodyAPI"}.intersection(r["api_schemas"]), r["path"])
            pending.extend(r["children"])
            checked += 1
    mass = sum(m for m, _ in loads)
    expected_inputs["inputs:initial_propellant_mass_kg"] = mass-source[0]
    actual, = stage.read([status], list(expected_inputs))
    for name, value in expected_inputs.items():
        require(math.isclose(actual["attrs"][name], value, abs_tol=1e-10), status + "." + name)
    center = [sum(m*p[i] for m, p in loads)/mass for i in range(3)]
    inertia = [source[4+i] + sum(m*sum((p[j]-center[j])**2 for j in range(3) if i != j)
                                 for m, p in loads) for i in range(3)]
    body, = stage.read([root], ["physics:mass", "physics:centerOfMass", "physics:diagonalInertia"])
    for key, expected in [("physics:mass", [mass]), ("physics:centerOfMass", center),
                          ("physics:diagonalInertia", inertia)]:
        value = body["attrs"][key]
        observed = value if isinstance(value, list) else [value]
        require(len(observed) == len(expected) and all(math.isclose(a, b, abs_tol=2e-7, rel_tol=1.2e-7)
                for a, b in zip(observed, expected)), key)
    return {"mass_kg": mass, "center_m": center, "diagonal_inertia_kg_m2": inertia,
            "station_count": len(stations), "tank_prims_checked": checked}


def cell_faces(row):
    """Integrate each upper cap of the independent clipped-cell solids."""
    points = row["points"]
    indices = row["faceVertexIndices"]
    require(points and all(math.isfinite(v) for p in points for v in p), "Invalid cell row")
    top = max(p[1] for p in points)
    faces, offset = [], 0
    for count in row["faceVertexCounts"]:
        face = indices[offset:offset+count]
        require(len(face) == count and count >= 3 and all(0 <= k < len(points) for k in face), "Invalid face")
        offset += count
        if all(points[k][1] == top for k in face):
            faces.append(face)
    require(offset == len(indices) and faces, "Missing collecting surface")
    # Native extrusion may triangulate a cap. Group faces sharing cap vertices.
    parts = []
    for face in faces:
        vertices = set(face)
        area = abs(sum(points[a][0]*points[b][2] - points[b][0]*points[a][2]
                       for a, b in zip(face, face[1:]+face[:1])))/2
        merged = []
        for ids, other_area in parts:
            if ids.intersection(vertices):
                vertices.update(ids)
                area += other_area
            else:
                merged.append((ids, other_area))
        parts = merged + [(vertices, area)]
    result = []
    for ids, area in parts:
        center = [(min(points[k][j] for k in ids)+max(points[k][j] for k in ids))/2 for j in (0, 2)]
        require(area > 0, "Degenerate collecting surface")
        result.append((*center, top, area))
    return sorted(result)


def check_mounts(stage, path, overlap):
    frame, = stage.read([path + "/Frame"], ["points"])
    points = frame["attrs"]["points"]
    require(points and len(points) % 8 == 0, "Unsupported frame stock")
    boxes = [[(min(a), max(a)) for a in zip(*points[i:i+8])] for i in range(0, len(points), 8)]
    for side in ("NegativeX", "PositiveX"):
        bracket, link = stage.read([path+"/MountBracket"+side, path+"/MountLink"+side],
                                   ["xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale"])
        pos = link["attrs"]["xformOp:translate"]
        angle = math.radians(link["attrs"]["xformOp:rotateXYZ"][2])
        half_span = link["attrs"]["xformOp:scale"][1]/2-overlap
        delta = [-math.sin(angle)*half_span, math.cos(angle)*half_span, 0.0]
        lower = [a-b for a, b in zip(pos, delta)]
        upper = [a+b for a, b in zip(pos, delta)]
        require(math.dist(lower, bracket["attrs"]["xformOp:translate"]) < 1e-5, link["path"])
        require(any(all(lo-1e-5 <= v <= hi+1e-5 for (lo, hi), v in zip(box, upper))
                    for box in boxes), link["path"] + " misses frame stock")


def shadow_error(cells, samples):
    """Mean and worst absolute visible-fraction error on 228 straight-edge masks."""
    errors = []
    area = sum(weight for _, _, weight in cells)
    for direction in range(12):
        angle = direction*math.pi/12
        dx, dz = math.cos(angle), math.sin(angle)
        active = [(x*dx+z*dz, weight) for x, z, weight in cells]
        probes = [x*dx+z*dz for x, z in samples]
        lo, hi = min(p for p, _ in active), max(p for p, _ in active)
        for i in range(1, 20):
            edge = lo + (hi-lo)*i/20 + 1e-6
            truth = sum(w for p, w in active if p < edge)/area
            errors.append(abs(sum(p < edge for p in probes)/len(probes)-truth))
    return {"mean": sum(errors)/len(errors), "maximum": max(errors)}


def check_panel(stage, root, name, overlap, offset, tolerance):
    path = root+"/"+name
    rec, = stage.read([path], ["xformOp:scale"], children=True)
    sx, _, sz = rec["attrs"]["xformOp:scale"]
    prefix = path+"/CellRow"
    rows = sorted((p for p in rec["children"] if p.startswith(prefix)), key=lambda p: int(p[len(prefix):]))
    require(rows and rows == [prefix+str(i) for i in range(len(rows))], path + " cell rows")
    cells = []
    for row in stage.read(rows, ["points", "faceVertexCounts", "faceVertexIndices"]):
        cells.extend(cell_faces(row["attrs"]))
    area = abs(sx*sz)*sum(cell[3] for cell in cells)
    pv, = stage.read([root+"/ElectricalPower/"+name], ["parameters:area"])
    require(abs(pv["attrs"]["parameters:area"]-area) <= tolerance, path+" photovoltaic area")
    probe, = stage.read([path+"/PowerEnvironment"], ["points"])
    samples = probe["attrs"]["points"]
    require(len(samples) == 16 and len({tuple(p) for p in samples}) == 16, path+" sample population")
    for x, y, z in samples:
        require(any(abs(cx-x) < 2e-6 and abs(cz-z) < 2e-6 and abs(y-top-offset) < 2e-6
                    for cx, cz, top, _ in cells), path+" probe misses an active cell")
    check_mounts(stage, path, overlap)
    field = [(x*sx, z*sz, weight) for x, z, _, weight in cells]
    previous = [field[int((i+.5)*len(field)/9)][:2] for i in range(9)]
    old_error = shadow_error(field, previous)
    new_error = shadow_error(field, [(x*sx, z*sz) for x, _, z in samples])
    require(new_error["mean"] < old_error["mean"], path+" shadow sampling regression")
    return {"array": name, "cells": len(cells), "area_m2": area, "visibility_samples": len(samples),
            "shadow_fraction_error": new_error, "previous_shadow_fraction_error": old_error}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api-port", type=int, required=True)
    parser.add_argument("--doc-id", type=int, required=True)
    parser.add_argument("--root", default="/Griffin1")
    args = parser.parse_args()
    stage = Stage(args.api_port, args.doc_id)
    root = args.root
    tanks = check_tanks(stage, root)
    names = stage.source("griffin_spec::solar_array_names()")
    overlap = stage.source('griffin_spec::solar_component_number("minimumMountOverlapM")')
    offset, tolerance = stage.source("[griffin_power_builder::configuration().sample_offset,"
                                     "griffin_power_builder::configuration().area_tolerance]")
    require(stage.source("griffin_panel_physics_review::regression().ok"), "Rectangular cell regression")
    panels = [check_panel(stage, root, name, overlap, offset, tolerance) for name in names]
    print(json.dumps({"ok": True, "scope": "initial installed geometry and mass properties",
                      "snapshot": stage.snapshot, "tanks": tanks, "panels": panels}, indent=2))


if __name__ == "__main__":
    main()
