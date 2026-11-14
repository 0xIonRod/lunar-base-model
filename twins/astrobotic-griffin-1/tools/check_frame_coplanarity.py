#!/usr/bin/env python3
"""Check composed Griffin frame surfaces through the native USD API (read only)."""

import argparse
import json
import math
from pathlib import Path
import urllib.request


def sub(a, b):
    return [x - y for x, y in zip(a, b)]


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0]]


def normal(points):
    for i in range(1, len(points) - 1):
        n = cross(sub(points[i], points[0]), sub(points[i + 1], points[0]))
        length = math.sqrt(dot(n, n))
        if length > 1e-12:
            return [v / length for v in n]
    raise ValueError("Degenerate frame face")


def area(points):
    return abs(sum(a[0] * b[1] - a[1] * b[0]
                   for a, b in zip(points, points[1:] + points[:1]))) / 2


def intersection(subject, polygon):
    signed = sum(a[0] * b[1] - a[1] * b[0]
                 for a, b in zip(polygon, polygon[1:] + polygon[:1]))
    if signed < 0:
        polygon = polygon[::-1]
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        def distance(p):
            return ((b[0] - a[0]) * (p[1] - a[1])
                    - (b[1] - a[1]) * (p[0] - a[0]))
        previous, subject = subject, []
        for p, q in zip(previous, previous[1:] + previous[:1]):
            d, e = distance(p), distance(q)
            if d >= -1e-10:
                subject.append(p)
            if d * e < 0:
                subject.append([p[i] + (q[i] - p[i]) * d / (d - e) for i in range(2)])
        if not subject:
            break
    return subject


def audit(records):
    faces, bounds = [], {}
    for record in records:
        a, path = record["attrs"], record["path"]
        for key, identity in [("xformOp:translate", [0, 0, 0]),
                              ("xformOp:rotateXYZ", [0, 0, 0]),
                              ("xformOp:scale", [1, 1, 1])]:
            if a.get(key) not in (None, identity):
                raise ValueError(f"Frame audit requires a shared local frame: {path}: {key}")
        points, indices, offset = a["points"], a["faceVertexIndices"], 0
        bounds[path] = [[min(p[i] for p in points), max(p[i] for p in points)]
                        for i in range(3)]
        for face, count in enumerate(a["faceVertexCounts"]):
            polygon = [points[i] for i in indices[offset:offset + count]]
            offset += count
            n = normal(polygon)
            axis = max(range(3), key=lambda i: abs(n[i]))
            projected = [[v for i, v in enumerate(p) if i != axis] for p in polygon]
            faces.append((path, face, polygon, n, axis, projected))
    overlaps = []
    for i, a in enumerate(faces):
        for b in faces[i + 1:]:
            if a[0] == b[0] or a[4] != b[4] or dot(a[3], b[3]) < .99999999:
                continue
            gap = max(abs(dot(sub(p, a[2][0]), a[3])) for p in b[2])
            if gap > .00005:
                continue
            overlap = area(intersection(a[5], b[5]))
            if overlap > .00001:
                overlaps.append(dict(a=a[0], face_a=a[1], b=b[0], face_b=b[1],
                                     gap_m=gap, projected_overlap_m2=overlap))
    return dict(ok=not overlaps, meshes=len(records), faces=len(faces),
                overlaps=overlaps, bounds=bounds,
                scope="Same-facing coplanar faces on distinct tank-opening frames; 50 um plane and 10 mm2 area tolerances")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=4189)
    parser.add_argument("--doc-id", type=int)
    parser.add_argument("--root", default="/Griffin1SurfaceOps/Lander/Bus/TankSupportPlate")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    names = ["OpeningTank" + side + suffix for suffix in ["", "Upper", "Lower"]
             for side in ["PX", "NX", "PZ", "NZ"]]
    params = dict(paths=[args.root + "/" + n for n in names], attrs=[
        "points", "faceVertexCounts", "faceVertexIndices", "xformOp:translate",
        "xformOp:rotateXYZ", "xformOp:scale"])
    if args.doc_id is not None:
        params["doc_id"] = args.doc_id
    request = urllib.request.Request(
        f"http://127.0.0.1:{args.port}/api/commands",
        data=json.dumps(dict(type="ExecuteCommand", command="QueryUsdPrims", params=params)).encode(),
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=60) as response:
        records = json.load(response)["data"]["records"]
    if len(records) != 12 or any(r.get("type_name") != "Mesh" for r in records):
        raise ValueError("All twelve composed frame meshes are required")
    result = audit(records)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("PASS" if result["ok"] else "FAIL", result["meshes"], "meshes,",
          len(result["overlaps"]), "coplanar surface overlaps")
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
