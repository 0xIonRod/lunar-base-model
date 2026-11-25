import "lunco://scripting/tools/assembly_builder" as builder;
import "griffin_bus_detail" as harness;
import "griffin_tank_finish" as finish;

// Pure geometry plans for the photo-derived insulation study. Each plan is
// committed by the caller through the generation-checked document owner.
fn settings() {
    let model = sysml_model("twin://astrobotic-griffin-1/requirements/griffin_photo_wrapping.sysml");
    let values = #{};
    for name in ["BusColumns", "BusRows", "AftHemDropM", "AftPleatDepthM", "BusOutsetM", "BusLowerOverhangM",
                 "BusFoldDepthM", "BusEdgeGatherM", "ShellThicknessM",
                 "UpperCoverAllowanceM", "UpperCoverEndAllowanceM",
                 "UpperCoverSegments", "UpperCoverFoldDepthM", "FoilCrinklePerM",
                 "FoilFacetSlope", "FoilSheen", "FoilMicroSlope", "TapeStations", "TapeRows"] {
        let value = model.value("GriffinPhotoWrapping::VisualStudy::" + name);
        if value == () { throw("Missing photo-wrapping source parameter " + name); }
        values[name] = value;
    }
    values
}

fn mesh_plan(parent, name, points, counts, indices, material) {
    let ops = harness::append([], builder::mesh_shape_plan(
        "@root@", parent, name, points, counts, indices, [0.76, 0.79, 0.82], false));
    let path = parent + "/" + name;
    ops.push(#{SetApiSchemas: #{edit_target: "@root@", path: path, schemas: ["MaterialBindingAPI"]}});
    ops.push(finish::binding(path, material));
    ops
}

fn fold_offset(u, v, phase, study) {
    let envelope = sin(acos(-1.0) * u);
    let fold = abs(sin(u * 17.0 + v * 4.0 + phase));
    let diagonal = abs(sin(u * 8.0 - v * 7.0 + phase));
    study.BusFoldDepthM * envelope * (0.25 + 0.50 * fold + 0.25 * diagonal)
}

fn bus_surface(width, bottom, top, phase, study) {
    let columns = study.BusColumns.to_int();
    let rows = study.BusRows.to_int();
    if columns < 2 || rows < 2 || top <= bottom || width <= 0.0 {
        throw("Invalid blanket surface envelope");
    }
    let points = [];
    for j in 0..rows + 1 {
        let v = j.to_float() / rows.to_float();
        for i in 0..columns + 1 {
            let u = i.to_float() / columns.to_float();
            let gather = study.BusEdgeGatherM * sin(u * 19.0 + phase);
            let y = bottom + (top - bottom) * v + gather * (2.0 * v - 1.0);
            points.push([width * (u - 0.5), y, fold_offset(u, v, phase, study)]);
        }
    }
    let front_count = points.len();
    for i in 0..front_count {
        let p = points[i];
        points.push([p[0], p[1], p[2] - study.ShellThicknessM]);
    }
    let topology = #{counts: [], indices: []};
    for j in 0..rows {
        for i in 0..columns {
            let a = j * (columns + 1) + i;
            let b = a + 1;
            let c = a + columns + 2;
            let d = c - 1;
            for vertex in [a, b, c] {topology.indices.push(vertex);}
            topology.counts.push(3);
            for vertex in [a, c, d] {topology.indices.push(vertex);}
            topology.counts.push(3);
            for vertex in [a + front_count, c + front_count, b + front_count] {topology.indices.push(vertex);}
            topology.counts.push(3);
            for vertex in [a + front_count, d + front_count, c + front_count] {topology.indices.push(vertex);}
            topology.counts.push(3);
        }
    }
    let boundary = [];
    for i in 0..columns { boundary.push(i); }
    for j in 0..rows { boundary.push(j * (columns + 1) + columns); }
    for i in 0..columns { boundary.push(rows * (columns + 1) + columns - i); }
    for j in 0..rows { boundary.push((rows - j) * (columns + 1)); }
    for i in 0..boundary.len() {
        let a = boundary[i];
        let b = boundary[(i + 1) % boundary.len()];
        for vertex in [a, a + front_count, b + front_count] {topology.indices.push(vertex);}
            topology.counts.push(3);
        for vertex in [a, b + front_count, b] {topology.indices.push(vertex);}
            topology.counts.push(3);
    }
    #{points: points, counts: topology.counts, indices: topology.indices}
}

fn upper_surface(radius, half_length, study) {
    let segments = study.UpperCoverSegments.to_int();
    let stations = [-1.0, -0.94, -0.78, -0.56, -0.28, 0.0, 0.27, 0.55, 0.79, 0.94, 1.0];
    let radii = [0.22, 0.66, 0.96, 1.0, 1.02, 1.0, 1.01, 1.0, 0.96, 0.66, 0.22];
    let points = [[-half_length, 0.0, 0.0]];
    for j in 0..stations.len() {
        for i in 0..segments {
            let angle = 2.0 * acos(-1.0) * i.to_float() / segments.to_float();
            let ripple = study.UpperCoverFoldDepthM * sin(angle * 5.0 + j.to_float() * 1.7);
            let r = radius * radii[j] + ripple * radii[j];
            points.push([half_length * stations[j], r * cos(angle), r * sin(angle)]);
        }
    }
    let end = points.len();
    points.push([half_length, 0.0, 0.0]);
    let topology = #{counts: [], indices: []};
    for i in 0..segments {
        let next = (i + 1) % segments;
        for vertex in [0, 1 + next, 1 + i] {topology.indices.push(vertex);}
            topology.counts.push(3);
        for j in 0..stations.len() - 1 {
            let a = 1 + j * segments + i;
            let b = 1 + j * segments + next;
            let c = b + segments;
            let d = a + segments;
            for vertex in [a, b, c] {topology.indices.push(vertex);}
            topology.counts.push(3);
            for vertex in [a, c, d] {topology.indices.push(vertex);}
            topology.counts.push(3);
        }
        let last = 1 + (stations.len() - 1) * segments;
        for vertex in [end, last + i, last + next] {topology.indices.push(vertex);}
            topology.counts.push(3);
    }
    #{points: points, counts: topology.counts, indices: topology.indices}
}

fn foil_ops(shader, study) {
    let ops = [];
    for row in [["crinkle", "FoilCrinklePerM"], ["facet_depth", "FoilFacetSlope"],
                ["sheen", "FoilSheen"], ["micro_strength", "FoilMicroSlope"]] {
        ops.push(finish::attr(shader, "inputs:" + row[0], "float", study[row[1]].to_string()));
    }
    ops
}
