import "lunco://scripting/tools/assembly_builder" as assembly_builder;
import "lunco://scripting/tools/assembly_edit" as assembly_edit;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "lunco://scripting/tools/mechanical_relations" as mechanical_relations;
import "griffin_geometry" as griffin_geometry;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;

// Twin-local runtime visual assembly builder.
//
// This is deliberately a thin policy layer over LunCoSim's generic
// assembly_builder and assembly_edit tools. It emits typed AddPrim and
// transform operations that are journaled by ApplyUsdOps; it never writes
// USDA text and it never starts or reloads the Editor. Component identities
// and placement are kept here because they are presentation policy, while
// dimensions and geometry remain in the referenced USD component assets.

fn query_ok(record) {
    record != () && record.ok != false
}

fn remove_legacy_semantic_string_ops(doc, edit_target, path) {
    let record = assembly_builder::composed_query(doc, #{path: path,
        attrs: ["lunco:collider:geometrySource", "lunco:requirement",
            "lunco:component_role", "lunco:mechanism",
            "lunco:mass_properties_status"],
        children: false});
    let ops = [];
    if query_ok(record) && record.attrs != () {
        for name in ["lunco:collider:geometrySource", "lunco:requirement",
            "lunco:component_role", "lunco:mechanism",
            "lunco:mass_properties_status"] {
            if record.attrs[name] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: path, name: name}});
            }
        }
    }
    ops
}

// Use the shared composed query for both source-component documents and
// referenced children in an assembly.  The Editor inspection facade is
// selection-oriented and can return an empty type for a composed descendant;
// that made a valid referenced Cube look like a malformed component to the
// visual builder.  The composed query is the authoritative typed readback at
// this planning boundary and remains generation-addressed by the document id.
fn _component_query(doc, path) {
    let record = assembly_builder::composed_query(doc, #{path: path, children: false});
    if !query_ok(record) {
        return #{ok: false, error: path + ": component prim is missing"};
    }
    #{ok: true, type_name: record.type_name, path: path}
}

fn plan_error(message) {
    #{ ok: false, kind: "griffin_visual_component_assembly", error: message, ops: [] }
}

fn absolute_root(root) {
    root != () && string_is(root) && root != ""
        && root.starts_with("/") && !(root.ends_with("/") && root != "/")
}

fn component_asset(relative) {
    "twin://" + twin_name() + "/components/" + relative
}

fn _sysml_number(report, name) {
    // A full Twin audit can be incomplete for unrelated requirement or source
    // registry issues while the revision-pinned SysML model still resolves
    // this engineering datum. Read the typed model first; only use a clean,
    // explicitly supplied source projection as a fallback.
    let value = griffin_spec::_sysml_attribute(name);
    if value != () { return value; }
    if report == () || report.ok != true { return (); }
    sysml_requirements::number(report, griffin_spec::qualified_attribute_name(name))
}

fn _ramp_number(name) {
    _sysml_number(sysml_requirements::source(), name)
}

fn _ramp_angle_deg(side) {
    let angle = _ramp_number(if side == "port" {
        "rampPortDeploymentAngleRad"
    } else {
        "rampStarboardDeploymentAngleRad"
    });
    if angle == () { return (); }
    angle * 180.0 / 3.141592653589793
}

fn _skirt_number(source, name) {
    if source == () || source.ok != true { return (); }
    sysml_requirements::number(source,
        "GriffinPropulsionRequirements::GriffinEngineSkirtComponent::" + name)
}

fn visual_component_specs(root) {
    let griffin = griffin_spec::visual_review_griffin_station();
    let flip = griffin_spec::visual_review_flip_station();
    if !vec3_is_native(griffin) || !vec3_is_native(flip) { return []; }
    [
        #{parent: root, name: "Griffin1", type_name: "Xform",
          asset: "twin://" + twin_name() + "/vehicles/griffin_1.usda",
          translation: vec3_array(griffin), rotation: (), scale: ()},
        #{parent: root, name: "FLIP", type_name: "Xform",
          asset: "twin://" + twin_name() + "/vehicles/flip.usda",
          translation: vec3_array(flip), rotation: (), scale: ()}
    ]
}

fn _color_literal(color) {
    "[(" + color[0].to_string() + ", " + color[1].to_string()
        + ", " + color[2].to_string() + ")]"
}

fn _detail_ops(edit_target, detail) {
    let path = detail.parent + "/" + detail.name;
    if detail.shape == "cube" {
        let plan = assembly_builder::cube_shape_plan(edit_target, detail.parent,
            detail.name, 1.0, detail.scale, false);
        if !plan.ok { return plan; }
        let ops = [];
        for op in plan.ops { ops.push(op); }
        ops.push(#{SetTranslate: #{edit_target: edit_target, path: path, value: detail.translation}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: "purpose", type_name: "token", value: "\"render\""}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: "primvars:displayColor", type_name: "color3f[]",
            value: _color_literal(detail.color)}});
        return #{ok: true, path: path, ops: ops};
    }
    let plan = assembly_builder::cylinder_shape_plan(edit_target, detail.parent,
        detail.name, detail.radius, detail.height, detail.translation, (), (), false);
    if !plan.ok { return plan; }
    let ops = [];
    for op in plan.ops { ops.push(op); }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "axis", type_name: "token", value: "\"" + detail.axis + "\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(detail.color)}});
    #{ok: true, path: path, ops: ops}
}

// Author named mounting datums and their relationships.  Numeric transforms
// are derived once by ; the durable contract is the
// socket/frame relationship, so a later component replacement can be snapped
// by the generic frame-alignment tool without hand-editing USDA.
fn _mount_frame_specs(root) {
    let bus = root + "/Griffin1/Bus";
    let port = root + "/Griffin1/EgressRampPort";
    let starboard = root + "/Griffin1/EgressRampStarboard";
    let socket_x = _ramp_number("rampSocketX");
    let socket_y = _ramp_number("rampSocketY");
    let socket_z = _ramp_number("rampSocketZ");
    let hinge_x = _ramp_number("rampHingeOffsetX");
    let hinge_y = _ramp_number("rampHingeOffsetY");
    let hinge_z = _ramp_number("rampHingeOffsetZ");
    let port_angle = _ramp_angle_deg("port");
    let starboard_angle = _ramp_angle_deg("starboard");
    if socket_x == () || socket_y == () || socket_z == ()
        || hinge_x == () || hinge_y == () || hinge_z == ()
        || port_angle == () || starboard_angle == () {
        return [];
    }
    [
        #{parent: bus, name: "RampSocketPort", translation: [socket_x, socket_y, socket_z], rotation: (), socket: true},
        #{parent: bus, name: "RampSocketStarboard", translation: [-socket_x, socket_y, socket_z], rotation: (), socket: true},
        #{parent: port, name: "MountFrame", translation: [hinge_x, hinge_y, hinge_z], rotation: [0.0, 0.0, port_angle], socket: false},
        #{parent: starboard, name: "MountFrame", translation: [hinge_x, hinge_y, hinge_z], rotation: [0.0, 180.0, starboard_angle], socket: false},
    ]
}

fn _mount_frame_ops(doc, edit_target, spec, root) {
    let path = spec.parent + "/" + spec.name;
    let existing = assembly_builder::composed_query(doc, #{path: path, children: false});
    let ops = [];
    if !query_ok(existing) {
        let frame = assembly_builder::frame_plan(edit_target, spec.parent,
            spec.name, spec.translation, spec.rotation, ());
        if !frame.ok { return frame; }
        for op in frame.ops { ops.push(op); }
    } else {
        // Existing datums are updated idempotently as the component recipe
        // evolves.  This keeps the relationship authoritative while ensuring
        // the saved transform cannot retain a stale hinge offset.
        let placement = assembly_builder::place_plan(edit_target, path,
            spec.translation, spec.rotation, ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    if spec.socket {
        ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: path,
            schemas: ["LunCoMountSocketAPI"]}});
        for field in [
            #{name: "lunco:mount:socket", value: "\"egress_ramp\""},
            #{name: "lunco:mount:joint", value: "\"revolute\""},
            #{name: "lunco:mount:axis", value: "\"Z\""},
            #{name: "lunco:mount:asset", value: "\"twin://" + twin_name() + "/components/lander/griffin_ramp_visual.usda\""},
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
                name: field.name, type_name: "token", value: field.value}});
        }
    }
    #{ok: true, path: path, ops: ops}
}

fn mount_frame_ops(doc, edit_target, root) {
    let specs = _mount_frame_specs(root);
    let ops = [];
    let sockets = [];
    for spec in specs {
        let plan = _mount_frame_ops(doc, edit_target, spec, root);
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
        if spec.socket { sockets.push(plan.path); }
        if !spec.socket {
            ops.push(#{SetRelationship: #{edit_target: edit_target,
                path: spec.parent, name: "lunco:mount:frame", targets: [plan.path]}});
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: spec.parent,
                name: "lunco:mount:plug", type_name: "token", value: "\"egress_ramp\""}});
        }
    }
    // Advertise occupancy explicitly so the same authored datum can be
    // consumed by the generic mount-audit/realignment tools later.
    ops.push(#{SetRelationship: #{edit_target: edit_target,
        path: root + "/Griffin1/Bus/RampSocketPort", name: "lunco:mount:part",
        targets: [root + "/Griffin1/EgressRampPort"]}});
    ops.push(#{SetRelationship: #{edit_target: edit_target,
        path: root + "/Griffin1/Bus/RampSocketStarboard", name: "lunco:mount:part",
        targets: [root + "/Griffin1/EgressRampStarboard"]}});
    let bus = root + "/Griffin1/Bus";
    ops.push(#{SetRelationship: #{edit_target: edit_target, path: bus,
        name: "lunco:mount:sockets", targets: sockets}});
    #{ok: true, kind: "griffin_mount_datums", sockets: sockets, ops: ops}
}

// Resolve both ramp transforms from the authored socket/frame relationships.
// The returned batch is still generic SetTranslate/SetRotate operations; the
// Twin never guesses a component-local offset or writes raw USD text.
fn align_visual_mounts(doc, edit_target, root, parent_gen) {
    let lander = root + "/Griffin1";
    let bus = lander + "/Bus";
    let ops = [];
    for pair in [
        #{part: lander + "/EgressRampPort", socket: bus + "/RampSocketPort"},
        #{part: lander + "/EgressRampStarboard", socket: bus + "/RampSocketStarboard"},
    ] {
        let plan = assembly_builder::align_frames_plan(doc, edit_target,
            pair.part, pair.part + "/MountFrame", bus, pair.socket);
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    if ops.len() == 0 {
        return #{ok: true, kind: "griffin_mount_alignment", no_op: true, ops: []};
    }
    let result = assembly_edit::batch(doc, "Align Griffin egress ramps to sockets", ops, parent_gen);
    #{ok: result.ok != false, kind: "griffin_mount_alignment", command: result, ops: ops}
}

fn _component_plan(doc, edit_target, spec) {
    let path = spec.parent + "/" + spec.name;
    let existing = assembly_builder::composed_query(doc, #{path: path, children: false});
    if query_ok(existing) {
        if existing.type_name != spec.type_name {
            return plan_error(path + ": existing visual component has type "
                + existing.type_name + ", expected " + spec.type_name);
        }
        let placement = #{ok: true, ops: []};
        if spec.translation != () || spec.rotation != () || spec.scale != () {
            placement = assembly_builder::place_plan(edit_target, path,
                spec.translation, spec.rotation, spec.scale);
            if !placement.ok { return placement; }
        }
        return #{ok: true, path: path, existing: true, updated: placement.ops.len() > 0,
            ops: placement.ops};
    }
    let plan = assembly_builder::referenced_instance_targeted_plan(
        doc, edit_target, spec.parent, spec.name, spec.type_name, spec.asset, (),
        spec.translation, spec.rotation, spec.scale, (), ());
    if !plan.ok { return plan; }
    #{ok: true, path: path, existing: false, ops: plan.ops}
}

/// Reference each maintained vehicle once. Child component geometry belongs
/// to the vehicle source assets, never to this combined review scene.
fn visual_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("visual_component_plan requires a document, edit target, and absolute root");
    }
    let specs = visual_component_specs(root);
    if specs.len() != 2 { return plan_error("typed visual review stations are missing"); }
    let ops = [];
    let paths = [];
    let existing = [];
    let added = [];
    for spec in specs {
        let result = _component_plan(doc, edit_target, spec);
        if !result.ok { return result; }
        paths.push(result.path);
        for op in result.ops { ops.push(op); }
        if result.existing == true {
            existing.push(result.path);
        } else {
            added.push(result.path);
        }
    }
    #{ok: true, kind: "griffin_visual_component_assembly", root: root,
      component_count: specs.len(), paths: paths, existing: existing, added: added,
      no_op: ops.len() == 0, ops: ops}
}

/// Apply one dry plan through LunCoSim's journaled USD command. The command
/// remains asynchronous; callers should poll its acknowledgement and then
/// query the same document generation for visual acceptance.
fn apply_visual_components(doc, edit_target, root, parent_gen) {
    let plan = visual_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Reference Griffin and FLIP visual assemblies",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: root,
      component_count: plan.component_count, added: plan.added,
      command: command}
}

/// Derive the battery model's Ah input from the SysML energy rating and
/// nominal bus voltage, and project the rated solar output limit from its
/// source-owned value. This is the explicit boundary between energy/power
/// requirements and the generic storage/PV component interfaces.
fn flip_electrical_model_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("flip_electrical_model_plan requires a document, edit target, and absolute root");
    }
    let energy_kwh = griffin_spec::rover_battery_energy_kwh();
    let nominal_voltage_v = griffin_spec::rover_battery_nominal_voltage_v();
    let capacity_ah = griffin_spec::rover_battery_capacity_ah();
    let peak_power_w = griffin_spec::rover_solar_peak_power_w();
    if energy_kwh == () || nominal_voltage_v == () || capacity_ah == () || peak_power_w == ()
        || nominal_voltage_v <= 0.0 || energy_kwh <= 0.0 || peak_power_w <= 0.0 {
        return plan_error("FLIP electrical requirement values are missing or invalid");
    }
    for path in [root + "/Battery", root + "/SolarArray"] {
        if !_component_query(doc, path).ok {
            return plan_error("FLIP electrical component is missing at " + path);
        }
    }
    let battery = root + "/Battery";
    let solar = root + "/SolarArray";
    let ops = [
        #{SetAttribute: #{edit_target: edit_target, path: battery,
            name: "inputs:voltage_nom", type_name: "float",
            value: nominal_voltage_v.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: battery,
            name: "inputs:capacity", type_name: "float",
            value: capacity_ah.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: solar,
            name: "inputs:peak_power_rating_w", type_name: "float",
            value: peak_power_w.to_string()}}
    ];
    #{ok: true, kind: "flip_electrical_model", root: root,
      battery_energy_kwh: energy_kwh, battery_nominal_voltage_v: nominal_voltage_v,
      battery_capacity_ah: capacity_ah, solar_peak_power_w: peak_power_w,
      paths: [battery, solar], ops: ops, no_op: false}
}

fn apply_flip_electrical_model(doc, edit_target, root, parent_gen) {
    let plan = flip_electrical_model_plan(doc, edit_target, root);
    if !plan.ok { return plan; }
    let command = assembly_edit::batch(doc, "Realize FLIP source-owned electrical ratings",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: root,
      battery_energy_kwh: plan.battery_energy_kwh,
      battery_capacity_ah: plan.battery_capacity_ah,
      solar_peak_power_w: plan.solar_peak_power_w, command: command}
}

// Route markers are part of the mission interface, not a second navigation
// implementation. Their ordered names and XYZ datums come from the primary
// Griffin SysML package; this Editor plan only projects those values into the
// existing marker Xforms and journals the result in the scene layer.
fn surface_route_marker_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("surface_route_marker_plan requires a document, edit target, and absolute root");
    }
    let names = griffin_spec::surface_route_marker_names();
    let xs = griffin_spec::surface_route_marker_x();
    let ys = griffin_spec::surface_route_marker_y();
    let zs = griffin_spec::surface_route_marker_z();
    if names.len() == 0 || xs.len() != names.len() || ys.len() != names.len()
        || zs.len() != names.len() {
        return plan_error("surface route marker SysML arrays must have equal non-zero cardinality");
    }
    let ops = [];
    let paths = [];
    for index in 0..names.len() {
        let path = root + "/" + names[index];
        let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
        if !query_ok(prim) || prim.type_name != "Xform" {
            return plan_error(path + ": route marker must already be an existing Xform");
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            [xs[index], ys[index], zs[index]], (), ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        paths.push(path);
    }
    #{ok: true, kind: "griffin_surface_route_markers", root: root,
      names: names, paths: paths, positions_x: xs, positions_y: ys,
      positions_z: zs, ops: ops, no_op: ops.len() == 0}
}

fn apply_surface_route_markers(doc, edit_target, root, parent_gen) {
    let plan = surface_route_marker_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Author Griffin surface route markers", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: root,
      paths: plan.paths, positions_x: plan.positions_x,
      positions_y: plan.positions_y, positions_z: plan.positions_z,
      command: command}
}

// The physical ramp ends before the original landing pad.  Author the
// prepared egress surface as a named scene component so the route can prove
// four-wheel support after the ramp instead of relying on a route-coordinate
// exception or a rover teleport. All geometry datums cross the typed SysML bridge;
// requirement provenance remains in the requirement source model rather than
// being copied into scene string metadata. This function only projects them
// into the active scene through the journaled Editor command.
fn egress_apron_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("egress_apron_plan requires a document, edit target, and absolute root");
    }
    let name = griffin_spec::egress_apron_name();
    let cx = griffin_spec::egress_apron_center_x_m();
    let cy = griffin_spec::egress_apron_center_y_m();
    let cz = griffin_spec::egress_apron_center_z_m();
    let length = griffin_spec::egress_apron_length_m();
    let width = griffin_spec::egress_apron_width_m();
    let thickness = griffin_spec::egress_apron_thickness_m();
    let surface_y = griffin_spec::egress_apron_surface_y_m();
    if name == () || name == ""
        || cx == () || cy == () || cz == ()
        || length == () || width == () || thickness == () || surface_y == ()
        || length <= 0.0 || width <= 0.0 || thickness <= 0.0 {
        return plan_error("typed EgressApron datums are incomplete or non-positive");
    }
    let path = root + "/" + name;
    let existing = assembly_builder::composed_query(doc,
        #{path: path, children: false, attrs: ["physics:collisionEnabled"]});
    let ops = [];
    if !query_ok(existing) {
        let shape = assembly_builder::cube_shape_plan(edit_target, root, name, 1.0,
            [length, thickness, width], true);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
        let placement = assembly_builder::place_plan(edit_target, path,
            [cx, cy, cz], (), [length, thickness, width]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    } else {
        if existing.type_name != "Cube" {
            return plan_error(path + ": expected Cube, got " + existing.type_name);
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            [cx, cy, cz], (), [length, thickness, width]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: path,
        schemas: ["PhysicsCollisionAPI", "MaterialBindingAPI"]}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "true"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal([0.22, 0.24, 0.28])}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "lunco:component", type_name: "token", value: "\"Griffin" + name + "\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "lunco:source_status", type_name: "string", value: "\"study assumption\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "lunco:egress:surfaceY", type_name: "double",
        value: surface_y.to_string()}});
    ops.push(#{SetRelationship: #{edit_target: edit_target, path: path,
        name: "material:binding:physics",
        targets: [root + "/PhysicsMaterials/Friction_1_0"]}});
    #{ok: true, kind: "griffin_egress_apron", path: path, name: name,
      center: [cx, cy, cz], length_m: length, width_m: width,
      thickness_m: thickness, surface_y: surface_y, ops: ops,
      no_op: ops.len() == 0}
}

fn apply_egress_apron(doc, edit_target, root, parent_gen) {
    let plan = egress_apron_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Author Griffin physical egress apron",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, path: plan.path,
      center: plan.center, length_m: plan.length_m, width_m: plan.width_m,
      thickness_m: plan.thickness_m, surface_y: plan.surface_y,
      command: command}
}

// Isolated Editor plans -----------------------------------------------------
//
// The combined review scene above remains useful as a regression fixture, but
// authoring must also work on each vehicle's own document.  These helpers keep
// the same typed component recipes while taking the vehicle root itself
// ( or ).  No path in an isolated plan crosses into the other
// vehicle, which makes visual review and saved authored layers independently
// repeatable.

fn _isolated_component_plan(doc, edit_target, spec) {
    _component_plan(doc, edit_target, spec)
}

fn _isolated_griffin_specs(root) {
    let records = griffin_spec::visual_component_transform_plan();
    let specs = [];
    for record in records {
        if record.parent_role == "lander" || record.parent_role == "engine_cluster" {
            let parent = if record.parent_role == "engine_cluster" {
                root + "/Nozzle/MainEngineCluster"
            } else {
                root
            };
            let scale = if record.scale_enabled { vec3_array(record.pose.scale) } else { () };
            specs.push(#{parent: parent, name: record.name, type_name: "Xform",
                asset: component_asset(record.asset),
                translation: vec3_array(record.pose.translation),
                rotation: vec3_array(quat_to_euler_xyz_deg(record.pose.rotation)), scale: scale});
        }
    }
    specs
}

fn _isolated_griffin_detail_specs(root) {
    let bus = root + "/Bus";
    let details = [];
    for rail in griffin_spec::visual_rail_station_plan() {
        details.push(#{parent: bus, name: rail.name, shape: "cube",
            translation: vec3_array(rail.pose.translation), scale: vec3_array(rail.pose.scale),
            color: griffin_spec::visual_rail_display_color()});
    }
    details
}

fn _isolated_mount_ops(doc, edit_target, root) {
    let bus = root + "/Bus";
    let socket_x = _ramp_number("rampSocketX");
    let socket_y = _ramp_number("rampSocketY");
    let socket_z = _ramp_number("rampSocketZ");
    let hinge_x = _ramp_number("rampHingeOffsetX");
    let hinge_y = _ramp_number("rampHingeOffsetY");
    let hinge_z = _ramp_number("rampHingeOffsetZ");
    let port_angle = _ramp_angle_deg("port");
    let starboard_angle = _ramp_angle_deg("starboard");
    if socket_x == () || socket_y == () || socket_z == ()
        || hinge_x == () || hinge_y == () || hinge_z == ()
        || port_angle == () || starboard_angle == () {
        return plan_error("ramp SysML mount datums are missing");
    }
    let specs = [
        #{parent: bus, name: "RampSocketPort", translation: [socket_x, socket_y, socket_z], rotation: (), socket: true},
        #{parent: bus, name: "RampSocketStarboard", translation: [-socket_x, socket_y, socket_z], rotation: (), socket: true},
        #{parent: root + "/EgressRampPort", name: "MountFrame", translation: [hinge_x, hinge_y, hinge_z], rotation: [0.0, 0.0, port_angle], socket: false},
        #{parent: root + "/EgressRampStarboard", name: "MountFrame", translation: [hinge_x, hinge_y, hinge_z], rotation: [0.0, 180.0, starboard_angle], socket: false},
    ];
    let ops = [];
    let sockets = [];
    for spec in specs {
        let result = _mount_frame_ops(doc, edit_target,
            #{parent: spec.parent, name: spec.name, translation: spec.translation,
              rotation: spec.rotation, socket: spec.socket}, root + "/Griffin1");
        //  only uses the spec's parent/name and is otherwise
        // root agnostic; avoid its combined-scene path by emitting the frame
        // plan locally when the datum does not exist.
        if !result.ok { return result; }
        for op in result.ops { ops.push(op); }
        let path = spec.parent + "/" + spec.name;
        if spec.socket {
            sockets.push(path);
            let target = if spec.name == "RampSocketPort" {
                root + "/EgressRampPort"
            } else {
                root + "/EgressRampStarboard"
            };
            ops.push(#{SetRelationship: #{edit_target: edit_target,
                path: path, name: "lunco:mount:part",
                targets: [target]}});
        } else {
            ops.push(#{SetRelationship: #{edit_target: edit_target,
                path: spec.parent, name: "lunco:mount:frame", targets: [path]}});
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: spec.parent,
                name: "lunco:mount:plug", type_name: "token", value: "\"egress_ramp\""}});
        }
    }
    ops.push(#{SetRelationship: #{edit_target: edit_target, path: bus,
        name: "lunco:mount:sockets", targets: sockets}});
    #{ok: true, kind: "griffin_isolated_mount_datums", ops: ops}
}

fn isolated_griffin_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("isolated_griffin_component_plan requires a document, edit target, and absolute root");
    }
    let specs = _isolated_griffin_specs(root);
    if specs.len() == 0 { return plan_error("SysML Griffin visual parameters are missing"); }
    let ops = [];
    let paths = [];
    for spec in specs {
        let result = _isolated_component_plan(doc, edit_target, spec);
        if !result.ok { return result; }
        paths.push(result.path);
        for op in result.ops { ops.push(op); }
    }
    for detail in _isolated_griffin_detail_specs(root) {
        let path = detail.parent + "/" + detail.name;
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) { continue; }
        let result = _detail_ops(edit_target, detail);
        if !result.ok { return result; }
        for op in result.ops { ops.push(op); }
    }
    let mount = _isolated_mount_ops(doc, edit_target, root);
    if !mount.ok { return mount; }
    for op in mount.ops { ops.push(op); }
    for side in ["port", "starboard"] {
        let ramp_path = root + "/EgressRamp" + (if side == "port" { "Port" } else { "Starboard" });
        for op in _isolated_ramp_contract_ops(edit_target, ramp_path, side) {
            ops.push(op);
        }
        let geometry = _isolated_ramp_visual_geometry_ops(doc, edit_target, ramp_path, side);
        if !geometry.ok { return geometry; }
        for op in geometry.ops { ops.push(op); }
    }
    #{ok: true, kind: "griffin_isolated_visual_assembly", root: root,
      component_count: specs.len(), paths: paths, ops: ops, no_op: ops.len() == 0}
}

// Component-scoped authoring ------------------------------------------------
//
// These entry points are intentionally narrower than the aggregate plans
// above.  They let an Editor session make one reviewable change, inspect the
// projection, and run one component gate before continuing.  Group names are
// explicit task boundaries; they are not a license to apply the whole vehicle.

fn _griffin_task_match(name, task) {
    if name == task { return true; }
    if task == "PropellantTanks" { return name.starts_with("Tank"); }
    if task == "LandingLegs" { return name.starts_with("Leg"); }
    if task == "SolarArrays" { return name.starts_with("SolarPanel"); }
    if task == "MainEngineCluster" { return name.starts_with("Engine"); }
    false
}

fn _detail_matches_task(detail, task) {
    let parent = detail.parent;
    if task == "Bus" { return false; }
    if task == "MainEngineCluster" {
        return parent.ends_with("/MainEngineCluster") || parent.contains("/MainEngineCluster/");
    }
    if task == "EgressRampPort" { return parent.ends_with("/EgressRampPort"); }
    if task == "EgressRampStarboard" { return parent.ends_with("/EgressRampStarboard"); }
    false
}

fn isolated_griffin_component_plan_for(doc, edit_target, root, task) {
    if doc == () || edit_target == () || !absolute_root(root) || task == () || task == "" {
        return plan_error("isolated_griffin_component_plan_for requires a document, edit target, root, and task");
    }
    // Ramps own a hinge frame, mount relation, and deployment contract.  Keep
    // that behavior in the dedicated one-ramp planner instead of partially
    // applying it from a generic component selector.
    if task == "EgressRampPort" || task == "EgressRampStarboard" {
        return isolated_griffin_ramp_plan(doc, edit_target, root,
            if task == "EgressRampPort" { "port" } else { "starboard" });
    }
    let specs = _isolated_griffin_specs(root);
    if specs.len() == 0 { return plan_error("SysML Griffin visual parameters are missing"); }
    let selected = [];
    for spec in specs {
        if _griffin_task_match(spec.name, task) { selected.push(spec); }
    }
    if selected.len() == 0 {
        return plan_error("unknown Griffin visual component task ");
    }
    let ops = [];
    let paths = [];
    for spec in selected {
        let result = _isolated_component_plan(doc, edit_target, spec);
        if !result.ok { return result; }
        paths.push(result.path);
        for op in result.ops { ops.push(op); }
    }
    for detail in _isolated_griffin_detail_specs(root) {
        if !_detail_matches_task(detail, task) { continue; }
        let path = detail.parent + "/" + detail.name;
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) { continue; }
        let detail_plan = _detail_ops(edit_target, detail);
        if !detail_plan.ok { return detail_plan; }
        for op in detail_plan.ops { ops.push(op); }
    }
    #{ok: true, kind: "griffin_component_task", root: root, component: task,
      component_count: selected.len(), paths: paths, ops: ops, no_op: ops.len() == 0}
}

fn apply_isolated_griffin_component(doc, edit_target, root, task, parent_gen) {
    let plan = isolated_griffin_component_plan_for(doc, edit_target, root, task);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build Griffin component " + task,
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      component: task, component_count: plan.component_count, root: root}
}

// Use the source-owned normalized Cartesian profile and a shared Rust
// extrusion. The only serialization below is the typed USD point/index
// literal emitted at the authoring boundary.
fn _outer_body_prism_geometry(width, depth, height) {
    let source_profile = griffin_spec::visual_outer_body_profile_coordinates();
    if source_profile.len() != 8 || width <= 0.0 || depth <= 0.0 || height <= 0.0 {
        return plan_error("outer-body prism requires eight typed SysML profile points and positive dimensions");
    }
    let profile = [];
    for point in source_profile {
        if !vec2_is_native(point) || !vec2_is_finite(point) {
            return plan_error("outer-body profile coordinates must project as finite native Vec2 values");
        }
        profile.push(vec2(point.x * width / 2.0, point.y * depth / 2.0));
    }
    let mesh = extrude_profile(profile, height, profile_plane_xz());
    let points = [];
    for point in mesh.points { points.push(vec3_array(point)); }
    #{ok: true, points: points, face_counts: mesh.face_vertex_counts,
      face_indices: mesh.face_vertex_indices, vertex_count: mesh.vertex_count,
      face_count: mesh.face_count}
}

// Resize an existing component-owned profile mesh in place. The operation is
// deliberately a typed SetAttribute plan: the bus remains one replaceable
// component, while its dimensions stay visible in the SysML-backed builder
// rather than being hidden in a hand-edited USDA layer.
fn _mesh_scalar_literal(value) {
    let scaled = if value >= 0.0 { (value * 1000000.0 + 0.5).to_int() }
        else { (value * 1000000.0 - 0.5).to_int() };
    (f64_from(scaled) / 1000000.0).to_string()
}

fn _mesh_points_literal(points) {
    let literal = "[";
    for index in 0..points.len() {
        if index > 0 { literal += ", "; }
        literal += "(" + _mesh_scalar_literal(points[index][0]) + ", "
            + _mesh_scalar_literal(points[index][1]) + ", "
            + _mesh_scalar_literal(points[index][2]) + ")";
    }
    literal + "]"
}

fn _mesh_ints_literal(values) {
    let literal = "[";
    for index in 0..values.len() {
        if index > 0 { literal += ", "; }
        literal += values[index].to_string();
    }
    literal + "]"
}

// Decompose the open octagonal payload perimeter into eight convex beams and
// derive the separate central rover platform collider from its visible mesh
// profile. A single convex hull around the perimeter would fill the tank
// openings, so it is never an acceptable collider for this geometry.
fn physical_top_deck_collider_geometry() {
    let width = griffin_spec::visual_deck_width_m();
    let depth = griffin_spec::visual_deck_depth_m();
    let thickness = griffin_spec::visual_deck_thickness_m();
    let section = griffin_spec::visual_frame_ring_section_m();
    let profile = griffin_spec::visual_outer_body_profile_coordinates();
    let bus_mount = griffin_spec::component_bus_mount();
    let deck_center_y = griffin_spec::visual_deck_center_y_m();
    if width == () || depth == () || thickness == ()
        || !griffin_geometry::scalar_is_finite(width)
        || !griffin_geometry::scalar_is_finite(depth)
        || !griffin_geometry::scalar_is_finite(thickness)
        || section == () || section <= 0.0 || profile.len() != 8
        || width <= 0.0 || depth <= 0.0 || thickness <= 0.0
        || bus_mount == () || !vec3_is_native(bus_mount)
        || deck_center_y == () || !griffin_geometry::scalar_is_finite(deck_center_y) {
        return plan_error("source-owned top-deck dimensions and COM-frame mount are incomplete");
    }
    let ring_center_y = bus_mount.y + deck_center_y;
    let ring_beams = [];
    for index in 0..profile.len() {
        let a = profile[index];
        let b = profile[(index + 1) % profile.len()];
        if !vec2_is_native(a) || !vec2_is_native(b)
            || !vec2_is_finite(a) || !vec2_is_finite(b) {
            return plan_error("top-deck perimeter requires finite native SysML profile points");
        }
        let ax = a.x * width / 2.0;
        let az = a.y * depth / 2.0;
        let bx = b.x * width / 2.0;
        let bz = b.y * depth / 2.0;
        let dx = bx - ax;
        let dz = bz - az;
        let edge_length = (dx * dx + dz * dz).sqrt();
        if edge_length <= 0.0 { return plan_error("top-deck profile has a zero-length edge"); }
        // Cube local X rotates toward -Z about Y. atan(dz/dx) is sufficient
        // for an undirected beam axis; reversing an edge leaves the same box.
        let rotation_y = if dx.abs() <= 1.0e-12 { -90.0 }
            else { (-dz / dx).atan() * 180.0 / 3.141592653589793 };
        ring_beams.push(#{name: "TopDeckBeamCollider" + index.to_string(),
            translation: [(ax + bx) / 2.0, ring_center_y, (az + bz) / 2.0],
            rotation: [0.0, rotation_y, 0.0],
            dimensions: [edge_length + section, thickness, section]});
    }
    let adapter_width = griffin_spec::visual_payload_adapter_width_m();
    let adapter_depth = griffin_spec::visual_payload_adapter_depth_m();
    let adapter_thickness = griffin_spec::visual_payload_adapter_thickness_m();
    let adapter_center_y = griffin_spec::visual_payload_adapter_center_y_m();
    if adapter_width == () || adapter_depth == () || adapter_thickness == ()
        || adapter_center_y == () || adapter_width <= 0.0
        || adapter_depth <= 0.0 || adapter_thickness <= 0.0 {
        return plan_error("source-owned rover payload adapter dimensions are incomplete");
    }
    let adapter_mesh = _outer_body_prism_geometry(adapter_width,
        adapter_depth, adapter_thickness);
    if adapter_mesh.ok != true { return adapter_mesh; }
    let adapter_points = adapter_mesh.points;
    for index in 0..adapter_points.len() { adapter_points[index][1] += adapter_center_y; }
    #{ok: true, ring_beams: ring_beams, ring_center_y_m: ring_center_y,
      ring_section_m: section, deck_width_m: width, deck_depth_m: depth,
      deck_thickness_m: thickness, profile_vertex_count: profile.len(),
      adapter_points: adapter_points, adapter_face_counts: adapter_mesh.face_counts,
      adapter_face_indices: adapter_mesh.face_indices,
      adapter_width_m: adapter_width, adapter_depth_m: adapter_depth,
      adapter_thickness_m: adapter_thickness, adapter_center_y_m: adapter_center_y}
}

/// Return one generation-bound Editor plan for the octagonal perimeter and
/// rover platform. The obsolete solid convex hull is removed before any new
/// colliders are authored through the typed Editor journal.
fn physical_top_deck_collider_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("physical_top_deck_collider_plan requires a document, edit target, and absolute root");
    }
    let geometry = physical_top_deck_collider_geometry();
    if geometry.ok != true { return geometry; }
    let ops = [];
    let perimeter_source_path = root + "/Bus/TopDeckOctagon";
    let perimeter_source = assembly_builder::composed_query(doc,
        #{path: perimeter_source_path, children: false});
    if !query_ok(perimeter_source) || perimeter_source.type_name != "Mesh" {
        return plan_error(perimeter_source_path + ": source-owned octagonal deck mesh is required");
    }
    let adapter_source_path = root + "/Bus/RoverPayloadDeck";
    let adapter_source = assembly_builder::composed_query(doc,
        #{path: adapter_source_path, children: false});
    if !query_ok(adapter_source) || adapter_source.type_name != "Mesh" {
        return plan_error(adapter_source_path + ": source-owned rover platform mesh is required");
    }
    for op in remove_legacy_semantic_string_ops(doc, edit_target,
        root + "/PayloadAdapter") {
        ops.push(op);
    }
    let legacy_path = root + "/TopDeckCollisionProxy";
    if query_ok(assembly_builder::composed_query(doc,
        #{path: legacy_path, children: false})) {
        ops.push(#{RemovePrim: #{edit_target: edit_target, path: legacy_path}});
    }
    for beam in geometry.ring_beams {
        let path = root + "/" + beam.name;
        let current = assembly_builder::composed_query(doc, #{path: path, children: false});
        if query_ok(current) && current.type_name != "Cube" {
            return plan_error(path + ": octagonal ring collider must be a Cube");
        }
        if !query_ok(current) {
            let shape = assembly_builder::cube_shape_plan(edit_target, root,
                beam.name, 1.0, beam.dimensions, true);
            if !shape.ok { return shape; }
            for op in shape.ops { ops.push(op); }
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            beam.translation, beam.rotation, beam.dimensions);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        for attribute in [
            #{name: "physics:collisionEnabled", type_name: "bool", value: "true"},
            #{name: "purpose", type_name: "token", value: "\"proxy\""},
            #{name: "visibility", type_name: "token", value: "\"invisible\""},
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
                name: attribute.name, type_name: attribute.type_name,
                value: attribute.value}});
        }
        // approximation is a PhysicsMeshCollisionAPI property. These are
        // primitive Cube colliders, so clear any obsolete local opinion.
        ops.push(#{RemoveAttribute: #{edit_target: edit_target, path: path,
            name: "physics:approximation"}});
        for op in remove_legacy_semantic_string_ops(doc, edit_target, path) {
            ops.push(op);
        }
        ops.push(#{SetRelationship: #{edit_target: edit_target, path: path,
            name: "lunco:collider:geometrySource",
            targets: [perimeter_source_path]}});
    }
    let adapter_path = root + "/RoverPayloadDeckCollider";
    let adapter_current = assembly_builder::composed_query(doc,
        #{path: adapter_path, children: false});
    if query_ok(adapter_current) && adapter_current.type_name != "Mesh" {
        return plan_error(adapter_path + ": rover platform collider must be a Mesh");
    }
    if !query_ok(adapter_current) {
        let shape = assembly_builder::mesh_shape_plan(edit_target, root,
            "RoverPayloadDeckCollider", geometry.adapter_points,
            geometry.adapter_face_counts, geometry.adapter_face_indices,
            griffin_spec::visual_deck_display_color(), true);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    for pair in [
        ["points", "point3f[]", _mesh_points_literal(geometry.adapter_points)],
        ["faceVertexCounts", "int[]", _mesh_ints_literal(geometry.adapter_face_counts)],
        ["faceVertexIndices", "int[]", _mesh_ints_literal(geometry.adapter_face_indices)],
        ["subdivisionScheme", "token", "\"none\""]
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: adapter_path,
            name: pair[0], type_name: pair[1], value: pair[2]}});
    }
    for attribute in [
        #{name: "physics:approximation", type_name: "token", value: "\"convexHull\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "true"},
        #{name: "purpose", type_name: "token", value: "\"proxy\""},
        #{name: "visibility", type_name: "token", value: "\"invisible\""}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: adapter_path,
            name: attribute.name, type_name: attribute.type_name,
                value: attribute.value}});
    }
    for op in remove_legacy_semantic_string_ops(doc, edit_target, adapter_path) {
        ops.push(op);
    }
    ops.push(#{SetRelationship: #{edit_target: edit_target, path: adapter_path,
        name: "lunco:collider:geometrySource", targets: [adapter_source_path]}});
    ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: adapter_path,
        schemas: ["PhysicsCollisionAPI", "PhysicsMeshCollisionAPI"]}});
    #{ok: true, kind: "griffin_physical_top_deck_collider", doc_id: doc,
      removed_legacy_path: legacy_path, ring_beam_count: geometry.ring_beams.len(),
      adapter_path: adapter_path, profile_vertex_count: geometry.profile_vertex_count,
      ring_center_y_m: geometry.ring_center_y_m,
      ring_section_m: geometry.ring_section_m,
      adapter_dimensions_m: [geometry.adapter_width_m, geometry.adapter_thickness_m,
        geometry.adapter_depth_m], adapter_center_y_m: geometry.adapter_center_y_m,
      ops: ops}
}

fn _griffin_cooked_geometry_is_valid(actual_geometry, expected_vertex_count,
                                     expected_approximation) {
    if actual_geometry == () || actual_geometry.frame != "canonical_stage"
        || actual_geometry.shape != "convex_hull"
        || actual_geometry.vertices == ()
        || actual_geometry.vertices.len() != expected_vertex_count {
        return false;
    }
    if expected_approximation != ()
        && actual_geometry.approximation != expected_approximation {
        return false;
    }
    for point in actual_geometry.vertices {
        for axis in 0..3 {
            let component = _native_vec3_axis(point, axis);
            if component == () || !griffin_geometry::scalar_is_finite(component) {
                return false;
            }
        }
    }
    true
}

/// Measure the nine source-derived colliders from one composed Avian cook.
/// Eight separate perimeter boxes preserve the central opening.
fn physical_top_deck_collider_observation(doc, root) {
    let expected = physical_top_deck_collider_geometry();
    if expected.ok != true {
        return #{ok: false, state: "invalid", detail: expected.error};
    }
    let tolerance = sysml_requirements::number(sysml_requirements::source(),
        "GriffinMechanicalRequirements::GR018_HullAndDeck::topDeckProfileToleranceM");
    if tolerance == () || tolerance <= 0.0 {
        return #{ok: false, state: "invalid", detail: "shared geometry tolerance is missing from SysML"};
    }
    let paths = [];
    for beam in expected.ring_beams { paths.push(root + "/" + beam.name); }
    let adapter_path = root + "/RoverPayloadDeckCollider";
    paths.push(adapter_path);
    paths.push(root);
    let request = #{paths: paths,
        attrs: ["xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale",
            "size", "points", "faceVertexCounts", "faceVertexIndices",
            "physics:collisionEnabled", "physics:approximation", "visibility", "purpose"],
        rels: ["lunco:collider:geometrySource"], schemas: true,
        children: true, collision_geometry: true};
    if doc != () { request.doc_id = doc; }
    let batch = query("QueryUsdPrims", request);
    if !query_ok(batch) || batch.records == () || batch.records.len() != paths.len() {
        return #{ok: false, state: "unavailable",
            detail: "one-snapshot Avian collider geometry is unavailable"};
    }
    let records = batch.records;
    let doc_id = records[0].doc_id;
    let document_generation = records[0].document_generation;
    let stage_generation = records[0].stage_generation;
    if stage_generation == () {
        return #{ok: false, state: "unavailable",
            detail: "collider snapshot is missing composed-stage provenance"};
    }
    let all_beams_match = true;
    let all_beams_collide = true;
    let all_beams_hidden = true;
    let all_beams_source_linked = true;
    let all_beam_geometry_matches = true;
    let max_transform_error = 0.0;
    let open_interior_radius = 1.0e30;
    let root_record = records[expected.ring_beams.len() + 1];
    let old_hull_removed = root_record.type_name == "Xform"
        && root_record.doc_id == doc_id
        && root_record.document_generation == document_generation
        && root_record.stage_generation == stage_generation
        && root_record.children != ()
        && !root_record.children.contains(root + "/TopDeckCollisionProxy");
    for index in 0..expected.ring_beams.len() {
        let beam = expected.ring_beams[index];
        let record = records[index];
        if record.doc_id != doc_id || record.document_generation != document_generation
            || record.stage_generation != stage_generation
            || record.type_name != "Cube" || record.attrs == ()
            || record.attrs["size"] != 1.0 {
            all_beams_match = false;
            all_beams_collide = false;
            all_beams_hidden = false;
            all_beams_source_linked = false;
            all_beam_geometry_matches = false;
            continue;
        }
        let translation = record.attrs["xformOp:translate"];
        let rotation = record.attrs["xformOp:rotateXYZ"];
        let scale = record.attrs["xformOp:scale"];
        if translation == () || rotation == () || scale == () {
            all_beams_match = false;
            all_beams_source_linked = false;
            continue;
        }
        let actual = [_native_vec3_axis(translation, 0), _native_vec3_axis(translation, 1),
            _native_vec3_axis(translation, 2), _native_vec3_axis(rotation, 1),
            _native_vec3_axis(scale, 0), _native_vec3_axis(scale, 1),
            _native_vec3_axis(scale, 2)];
        let wanted = [beam.translation[0], beam.translation[1], beam.translation[2],
            beam.rotation[1], beam.dimensions[0], beam.dimensions[1], beam.dimensions[2]];
        for index in 0..actual.len() {
            let error = (actual[index] - wanted[index]).abs();
            if index == 3 { error *= 3.141592653589793 / 180.0 * beam.dimensions[0] / 2.0; }
            if error > max_transform_error { max_transform_error = error; }
            if error > tolerance { all_beams_match = false; }
        }
        if record.attrs["physics:collisionEnabled"] != true {
            all_beams_collide = false;
        }
        if record.attrs["visibility"] != "invisible" || record.attrs["purpose"] != "proxy" {
            all_beams_hidden = false;
        }
        let source_targets = if record.relationships == () { () }
            else { record.relationships["lunco:collider:geometrySource"] };
        if source_targets == () || source_targets.len() != 1
            || source_targets[0] != root + "/Bus/TopDeckOctagon" {
            all_beams_source_linked = false;
        }
        let cooked_geometry_matches = _griffin_cooked_geometry_is_valid(
            record.collision_geometry, 8, ());
        if !cooked_geometry_matches {
            all_beam_geometry_matches = false;
        }
        let inner_radius = (beam.translation[0] * beam.translation[0]
            + beam.translation[2] * beam.translation[2]).sqrt()
            - beam.dimensions[2] / 2.0;
        if inner_radius < open_interior_radius { open_interior_radius = inner_radius; }
    }
    let adapter = records[expected.ring_beams.len()];
    if adapter.doc_id != doc_id || adapter.document_generation != document_generation
        || adapter.stage_generation != stage_generation { all_beams_match = false; }
    let adapter_matches = query_ok(adapter) && adapter.type_name == "Mesh"
        && adapter.attrs != ()
        && adapter.attrs["faceVertexCounts"] == expected.adapter_face_counts
        && adapter.attrs["faceVertexIndices"] == expected.adapter_face_indices;
    let adapter_point_deviation = 0.0;
    if adapter_matches {
        let observed_points = adapter.attrs["points"];
        if observed_points == () || observed_points.len() != expected.adapter_points.len() {
            adapter_matches = false;
        } else {
            for index in 0..observed_points.len() {
                let dx = _native_vec3_axis(observed_points[index], 0)
                    - _native_vec3_axis(expected.adapter_points[index], 0);
                let dy = _native_vec3_axis(observed_points[index], 1)
                    - _native_vec3_axis(expected.adapter_points[index], 1);
                let dz = _native_vec3_axis(observed_points[index], 2)
                    - _native_vec3_axis(expected.adapter_points[index], 2);
                let deviation = (dx * dx + dy * dy + dz * dz).sqrt();
                if deviation > adapter_point_deviation { adapter_point_deviation = deviation; }
            }
            if adapter_point_deviation > tolerance { adapter_matches = false; }
        }
    }
    let adapter_collides = query_ok(adapter) && adapter.attrs != ()
        && adapter.attrs["physics:collisionEnabled"] == true
        && adapter.attrs["physics:approximation"] == "convexHull"
        && adapter.collision_geometry != ()
        && adapter.collision_geometry.approximation == "convexHull"
        && adapter.api_schemas.contains("PhysicsCollisionAPI")
        && adapter.api_schemas.contains("PhysicsMeshCollisionAPI");
    let adapter_hidden = query_ok(adapter) && adapter.attrs != ()
        && adapter.attrs["visibility"] == "invisible"
        && adapter.attrs["purpose"] == "proxy";
    let adapter_targets = if query_ok(adapter) && adapter.relationships != () {
        adapter.relationships["lunco:collider:geometrySource"]
    } else { () };
    let adapter_source_linked = adapter_targets != ()
        && adapter_targets.len() == 1
        && adapter_targets[0] == root + "/Bus/RoverPayloadDeck";
    let adapter_cooked_geometry_matches = _griffin_cooked_geometry_is_valid(
        adapter.collision_geometry, expected.adapter_points.len(), "convexHull");
    let source_geometry_linked = all_beams_source_linked && adapter_source_linked;
    let topology_matches = old_hull_removed && expected.ring_beams.len() == 8
        && all_beams_match && all_beam_geometry_matches && adapter_matches
        && adapter_cooked_geometry_matches && open_interior_radius > 0.0;
    let collision_enabled = all_beams_collide && adapter_collides;
    let proxy_hidden = all_beams_hidden && adapter_hidden;
    let cooked_convex_geometry = all_beam_geometry_matches
        && adapter_cooked_geometry_matches && adapter_collides;
    let profile_deviation = if adapter_point_deviation > max_transform_error {
        adapter_point_deviation
    } else { max_transform_error };
    let ok = topology_matches && collision_enabled && proxy_hidden
        && cooked_convex_geometry && source_geometry_linked;
    #{ok: true, state: if ok { "pass" } else { "fail" },
      legacy_hull_removed: old_hull_removed, ring_beam_count: expected.ring_beams.len(),
      topology_matches: topology_matches, profile_deviation_m: profile_deviation,
      source_geometry_linked: source_geometry_linked,
      ring_source_geometry_linked: all_beams_source_linked,
      payload_source_geometry_linked: adapter_source_linked,
      collision_enabled: collision_enabled, proxy_hidden: proxy_hidden,
      cooked_convex_geometry: cooked_convex_geometry,
      ring_geometry_matches_source: all_beams_match,
      ring_collision_enabled: all_beams_collide, ring_proxy_hidden: all_beams_hidden,
      open_interior_radius_m: open_interior_radius,
      payload_adapter_geometry_matches_source: adapter_matches,
      payload_adapter_max_point_deviation_m: adapter_point_deviation,
      cooked_collider_geometry_matches_source: all_beam_geometry_matches
          && adapter_cooked_geometry_matches,
      payload_adapter_collision_enabled: adapter_collides,
      payload_adapter_proxy_hidden: adapter_hidden,
      maximum_transform_error_m: max_transform_error,
      tolerance_m: tolerance,
      doc_id: doc_id, document_generation: document_generation,
      stage_generation: stage_generation}
}

// The simulation lander's legacy leg roots own dynamics and joints; their
// obsolete visible cylinders/capsules are replaced by the requirement-owned
// LandingLeg visual component plus one hidden cylinder contact proxy. Both
// shapes use the same SysML foot-pad dimensions and leg-local datum.
fn physical_landing_leg_pad_geometry() {
    let visual = "GriffinLandingLegRequirements::GriffinLandingLegAssembly::";
    let configuration = "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::";
    let source = sysml_requirements::source_with_selection([
        visual + "footPadRadiusM", visual + "footPadHeightM",
        visual + "footPadCenterYM",
        configuration + "legStations", configuration + "legStationRotationYDeg",
        visual + "physicalLegPlacementToleranceM",
        visual + "physicalLegRotationToleranceDeg",
        visual + "padColliderToleranceM"
    ], ["GriffinLandingLegRequirements::gll005",
        "GriffinLandingLegRequirements::gll008"],
       ["GriffinLandingLegRequirements::Verify_GriffinLandingLegRequirements"]);
    if source.ok != true {
        return plan_error("SysML landing-leg geometry source is unavailable");
    }
    let radius = sysml_requirements::number(source, visual + "footPadRadiusM");
    let height = sysml_requirements::number(source, visual + "footPadHeightM");
    let center_y = sysml_requirements::number(source, visual + "footPadCenterYM");
    let stations = sysml_requirement_checks::source_position_list(source,
        configuration + "legStations");
    let rotations = sysml_requirements::vector(source,
        configuration + "legStationRotationYDeg");
    let station_tolerance = sysml_requirements::number(source,
        visual + "physicalLegPlacementToleranceM");
    let rotation_tolerance = sysml_requirements::number(source,
        visual + "physicalLegRotationToleranceDeg");
    let tolerance = sysml_requirements::number(source,
        visual + "padColliderToleranceM");
    if radius == () || height == () || center_y == () || tolerance == ()
        || station_tolerance == () || rotation_tolerance == ()
        || stations.len() != 4 || rotations.len() != 4
        || radius <= 0.0 || height <= 0.0 || tolerance <= 0.0
        || station_tolerance <= 0.0 || rotation_tolerance <= 0.0 {
        return plan_error("SysML landing-leg pad or COM-frame station datums are incomplete");
    }
    #{ok: true, radius_m: radius, height_m: height, center_y_m: center_y,
      stations: stations, rotations_y_deg: rotations,
      tolerance_m: tolerance, station_tolerance_m: station_tolerance,
      rotation_tolerance_deg: rotation_tolerance}
}

fn physical_landing_leg_pad_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("physical_landing_leg_pad_plan requires a document, edit target, and absolute root");
    }
    let geometry = physical_landing_leg_pad_geometry();
    if geometry.ok != true { return geometry; }
    let suffixes = ["PX", "NX", "PZ", "NZ"];
    let ops = [];
    let removed_legacy = [];
    for index in 0..suffixes.len() {
        let leg_path = root + "/Leg" + suffixes[index];
        let leg = assembly_builder::composed_query(doc,
            #{path: leg_path, children: false});
        if !query_ok(leg) || leg.type_name != "Xform" {
            return plan_error(leg_path + ": dynamics leg body is missing or is not an Xform");
        }
        // This relation targeted the enclosing compound body, so it filtered
        // no distinct rigid body. Clear its target list through the typed USD
        // relationship operation and remove its empty applied schema; the root
        // owns all four leg colliders.
        ops.push(#{SetRelationship: #{edit_target: edit_target,
            path: leg_path, name: "physics:filteredPairs", targets: []}});
        ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: leg_path,
            schemas: ["PhysicsRigidBodyAPI"]}});
        let station = geometry.stations[index];
        let placement = assembly_builder::place_plan(edit_target, leg_path,
            vec3_array(station), [0.0, geometry.rotations_y_deg[index], 0.0], ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }

        // The suspension joint's body-side anchor and the referenced leg
        // body now share the one SysML leg station. This preserves a real
        // articulated attachment after correcting the legacy low leg pose.
        let joint_path = root + "/Leg" + suffixes[index] + "_Spring";
        let joint = assembly_builder::composed_query(doc,
            #{path: joint_path, children: false});
        if query_ok(joint) {
            ops.push(#{SetAttribute: #{edit_target: edit_target,
                path: joint_path, name: "physics:localPos0", type_name: "point3f",
                value: "(" + station.x.to_string() + ", "
                    + station.y.to_string() + ", " + station.z.to_string() + ")"}});
            ops.push(#{SetAttribute: #{edit_target: edit_target,
                path: joint_path, name: "physics:localPos1", type_name: "point3f",
                value: "(0.0, 0.0, 0.0)"}});
        } else {
            return plan_error(joint_path + ": physical suspension joint is missing");
        }

        // Remove the assembly-local legacy presentation and pad capsule; the
        // referenced physical leg body, mass, joint, and outputs remain.
        for name in ["Strut", "Pad" + suffixes[index]] {
            let legacy_path = leg_path + "/" + name;
            if query_ok(assembly_builder::composed_query(doc,
                #{path: legacy_path, children: false})) {
                ops.push(#{RemovePrim: #{edit_target: edit_target, path: legacy_path}});
                removed_legacy.push(legacy_path);
            }
        }
        // Disable and hide the old source component's coarse render/collision
        // primitives. The shared, requirement-driven visual reference below
        // owns presentation; the new FootPadCollider owns terrain contact.
        for name in ["TopMount", "OuterStrut", "ShockHousing", "Piston", "FootHub", "FootPad"] {
            let old_path = leg_path + "/" + name;
            if query_ok(assembly_builder::composed_query(doc,
                #{path: old_path, children: false})) {
                ops.push(#{SetAttribute: #{edit_target: edit_target, path: old_path,
                    name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
                ops.push(#{SetAttribute: #{edit_target: edit_target, path: old_path,
                    name: "visibility", type_name: "token", value: "\"invisible\""}});
            }
        }

        let visual_path = leg_path + "/LandingLegVisual";
        let visual_prim = assembly_builder::composed_query(doc,
            #{path: visual_path, children: false});
        if !query_ok(visual_prim) || visual_prim.type_name != "Xform" {
            return plan_error(visual_path + ": compose the source visual component before deriving its contact geometry");
        }
        let source_path = visual_path + "/FootPad";
        let source_shape = assembly_builder::composed_query(doc,
            #{path: source_path, children: false,
              attrs: ["radius", "height", "axis", "xformOp:translate",
                "xformOp:rotateXYZ", "xformOp:scale", "physics:collisionEnabled"]});
        if !query_ok(source_shape) || source_shape.type_name != "Cylinder"
            || source_shape.attrs == () {
            return plan_error(source_path + ": source FootPad must compose as a typed Cylinder before collider derivation");
        }
        let source_radius = source_shape.attrs["radius"];
        let source_height = source_shape.attrs["height"];
        let source_axis = source_shape.attrs["axis"];
        let source_translation = source_shape.attrs["xformOp:translate"];
        let source_rotation = source_shape.attrs["xformOp:rotateXYZ"];
        let source_scale = source_shape.attrs["xformOp:scale"];
        if source_radius == () || source_height == () || source_axis != "Y"
            || source_translation == () || source_translation.len() != 3
            || source_shape.attrs["physics:collisionEnabled"] != false {
            return plan_error(source_path + ": source FootPad dimensions, Y axis, transform, and render-only ownership are required");
        }
        if (source_radius - geometry.radius_m).abs() > geometry.tolerance_m
            || (source_height - geometry.height_m).abs() > geometry.tolerance_m
            || (source_translation[1] - geometry.center_y_m).abs() > geometry.tolerance_m
            || source_translation[0].abs() > geometry.tolerance_m
            || source_translation[2].abs() > geometry.tolerance_m {
            return plan_error(source_path + ": composed visual pad no longer matches its SysML geometry datums");
        }
        if source_rotation == () { source_rotation = [0.0, 0.0, 0.0]; }
        if source_scale == () { source_scale = [1.0, 1.0, 1.0]; }

        // The proxy is a sibling of the visual pad under the same referenced
        // component frame. Its primitive, dimensions, and local transform are
        // copied from composed geometry; a typed relationship preserves the
        // source edge without encoding a prim path in a string attribute.
        let collider_path = visual_path + "/FootPadCollider";
        let collider = assembly_builder::composed_query(doc,
            #{path: collider_path, children: false,
              attrs: ["lunco:collider:geometrySource", "lunco:requirement"]});
        if query_ok(collider) && collider.type_name != "Cylinder" {
            return plan_error(collider_path + ": contact proxy must remain a UsdGeomCylinder");
        }
        let legacy_collider_path = leg_path + "/FootPadCollider";
        if query_ok(assembly_builder::composed_query(doc,
            #{path: legacy_collider_path, children: false})) {
            ops.push(#{RemovePrim: #{edit_target: edit_target,
                path: legacy_collider_path}});
            removed_legacy.push(legacy_collider_path);
        }
        if !query_ok(collider) {
            let shape = assembly_builder::cylinder_shape_plan_axis(edit_target,
                visual_path, "FootPadCollider", source_radius, source_height,
                source_translation, source_rotation, source_scale, source_axis, true);
            if !shape.ok { return shape; }
            for op in shape.ops { ops.push(op); }
        } else {
            for item in [
                #{name: "radius", type_name: "double", value: source_radius.to_string()},
                #{name: "height", type_name: "double", value: source_height.to_string()},
                #{name: "axis", type_name: "token", value: "\"" + source_axis + "\""},
                #{name: "extent", type_name: "float3[]", value: "[(-" + source_radius.to_string() + ", -" + (source_height / 2.0).to_string() + ", -" + source_radius.to_string() + "), (" + source_radius.to_string() + ", " + (source_height / 2.0).to_string() + ", " + source_radius.to_string() + ")]"},
                #{name: "physics:collisionEnabled", type_name: "bool", value: "true"},
                #{name: "purpose", type_name: "token", value: "\"proxy\""},
                #{name: "visibility", type_name: "token", value: "\"invisible\""}
            ] {
                ops.push(#{SetAttribute: #{edit_target: edit_target, path: collider_path,
                    name: item.name, type_name: item.type_name, value: item.value}});
            }
            ops.push(#{SetApiSchemas: #{edit_target: edit_target,
                path: collider_path, schemas: ["PhysicsCollisionAPI"]}});
            let collider_placement = assembly_builder::place_plan(edit_target,
                collider_path, source_translation, source_rotation, source_scale);
            if !collider_placement.ok { return collider_placement; }
            for op in collider_placement.ops { ops.push(op); }
            if collider.attrs["lunco:collider:geometrySource"] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: collider_path, name: "lunco:collider:geometrySource"}});
            }
            if collider.attrs["lunco:requirement"] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: collider_path, name: "lunco:requirement"}});
            }
        }
        for attribute in [
            #{name: "purpose", type_name: "token", value: "\"proxy\""},
            #{name: "visibility", type_name: "token", value: "\"invisible\""}
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target,
                path: collider_path, name: attribute.name,
                type_name: attribute.type_name, value: attribute.value}});
        }
        ops.push(#{SetRelationship: #{edit_target: edit_target,
            path: collider_path, name: "lunco:collider:geometrySource",
            targets: [source_path]}});
    }
    #{ok: true, kind: "griffin_physical_landing_leg_pads", root: root,
      radius_m: geometry.radius_m, height_m: geometry.height_m,
      center_y_m: geometry.center_y_m, tolerance_m: geometry.tolerance_m,
      removed_legacy_paths: removed_legacy,
      collider_paths: [root + "/LegPX/LandingLegVisual/FootPadCollider",
        root + "/LegNX/LandingLegVisual/FootPadCollider",
        root + "/LegPZ/LandingLegVisual/FootPadCollider",
        root + "/LegNZ/LandingLegVisual/FootPadCollider"], ops: ops}
}

fn physical_pad_bounds_deviation(left, right) {
    if left == () || right == ()
        || left.frame != "canonical_stage"
        || right.frame != "canonical_stage" { return (); }
    let maximum = 0.0;
    for key in ["min", "max", "center", "half_extents"] {
        let a = left[key];
        let b = right[key];
        if a == () || b == () || a.len() != 3 || b.len() != 3 { return (); }
        for axis in 0..3 {
            let delta = (a[axis] - b[axis]).abs();
            if delta > maximum { maximum = delta; }
        }
    }
    maximum
}

fn physical_vector_deviation(left, right) {
    if left == () || right == () || left.len() != right.len() { return (); }
    let maximum = 0.0;
    for index in 0..left.len() {
        let deviation = (left[index] - right[index]).abs();
        if deviation > maximum { maximum = deviation; }
    }
    maximum
}

fn physical_transform_or_identity(attrs, name, identity) {
    let value = attrs[name];
    if value == () { return identity; }
    if value.len() != identity.len() { return (); }
    value
}

fn physical_bounds_overlap_depth(left, right) {
    if left == () || right == () || left.min == () || right.min == ()
        || left.max == () || right.max == ()
        || left.min.len() != 3 || right.min.len() != 3
        || left.max.len() != 3 || right.max.len() != 3 {
        return ();
    }
    let depths = [];
    for axis in 0..3 {
        let lower = if left.min[axis] > right.min[axis] {
            left.min[axis] } else { right.min[axis] };
        let upper = if left.max[axis] < right.max[axis] {
            left.max[axis] } else { right.max[axis] };
        let depth = upper - lower;
        if depth < 0.0 { return 0.0; }
        depths.push(depth);
    }
    if depths[0] < depths[1] && depths[0] < depths[2] { return depths[0]; }
    if depths[1] < depths[2] { return depths[1]; }
    depths[2]
}

fn physical_landing_pad_snapshot_matches(record, snapshot_doc,
    document_generation, stage_generation) {
    record != () && record.doc_id == snapshot_doc
        && record.document_generation == document_generation
        && record.stage_generation == stage_generation
}

fn physical_cooked_y_axis_matches(rotation_wxyz, tolerance_deg) {
    if rotation_wxyz == () || rotation_wxyz.len() != 4
        || tolerance_deg == () || tolerance_deg < 0.0 {
        return false;
    }
    let norm_squared = 0.0;
    for value in rotation_wxyz {
        if !griffin_geometry::scalar_is_finite(value) { return false; }
        norm_squared += value * value;
    }
    if !griffin_geometry::scalar_is_finite(norm_squared) || norm_squared <= 0.0 {
        return false;
    }
    let inverse_norm = 1.0 / norm_squared.sqrt();
    let w = rotation_wxyz[0] * inverse_norm;
    let x = rotation_wxyz[1] * inverse_norm;
    let y = rotation_wxyz[2] * inverse_norm;
    let z = rotation_wxyz[3] * inverse_norm;
    let cooked_axis = [2.0 * (x * y - w * z),
        1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z + w * x)];
    let axis_deviation = physical_vector_deviation(cooked_axis, [0.0, 1.0, 0.0]);
    let axis_tolerance = sin(tolerance_deg * griffin_spec::pi_value() / 180.0);
    axis_deviation != () && axis_deviation <= axis_tolerance
}

fn physical_landing_leg_pad_observation(doc, root) {
    let geometry = physical_landing_leg_pad_geometry();
    if geometry.ok != true {
        return #{ok: false, state: "invalid", detail: geometry.error};
    }
    let suffixes = ["PX", "NX", "PZ", "NZ"];
    let geometry_deviation = 0.0;
    let maximum_cooked_geometry_deviation_m = 0.0;
    let all_cooked_geometry_comparable = true;
    let all_cooked_axis_matches = true;
    let source_radius_deviation = 0.0;
    let source_height_deviation = 0.0;
    let source_center_deviation = 0.0;
    let all_topology = true;
    let all_collision_enabled = true;
    let all_proxy_hidden = true;
    let all_visual_disabled = true;
    let all_legacy_disabled = true;
    let all_source_relationships = true;
    let all_self_collision_filters_clear = true;
    let all_geometry_available = true;
    let all_axes_match = true;
    let all_geometry_semantics_match = true;
    let station_deviation = 0.0;
    let rotations_match = true;
    let minimum_bus_overlap = 1.0e30;
    let minimum_axle_overlap = 1.0e30;
    let physical_joints_match = true;
    let bus_frame = assembly_builder::composed_query(doc,
        #{path: root + "/Bus/PerimeterFrame", children: false,
          geometry_bounds: true});
    if !query_ok(bus_frame) {
        let reason = if bus_frame.error == () {
            "composed bus-frame prim query failed"
        } else { bus_frame.error };
        return #{ok: false, state: "unavailable",
            detail: root + "/Bus/PerimeterFrame: " + reason};
    }
    if bus_frame.geometry_bounds == () {
        return #{ok: false, state: "unavailable",
            detail: root + "/Bus/PerimeterFrame: composed geometry bounds are unavailable"};
    }
    let pad_paths = [];
    for suffix in suffixes {
        let visual_root = root + "/Leg" + suffix + "/LandingLegVisual";
        pad_paths.push(visual_root + "/FootPadCollider");
        pad_paths.push(visual_root + "/FootPad");
    }
    let pad_request = #{paths: pad_paths,
        attrs: ["radius", "height", "axis", "xformOp:translate",
            "xformOp:rotateXYZ", "xformOp:scale",
            "physics:collisionEnabled", "visibility", "purpose",
            "lunco:collider:geometrySource", "lunco:requirement"],
        rels: ["lunco:collider:geometrySource"], schemas: true,
        geometry_bounds: true, collision_geometry: true};
    if doc != () { pad_request.doc_id = doc; }
    let pad_batch = query("QueryUsdPrims", pad_request);
    if !query_ok(pad_batch) || pad_batch.records == ()
        || pad_batch.records.len() != pad_paths.len() {
        let reason = if pad_batch == () || pad_batch.error == () {
            "one-snapshot Avian pad geometry query did not return all visual/proxy pairs"
        } else { pad_batch.error };
        return #{ok: false, state: "unavailable", detail: reason};
    }
    let pad_records = pad_batch.records;
    let snapshot_doc = pad_records[0].doc_id;
    let document_generation = pad_records[0].document_generation;
    let stage_generation = pad_records[0].stage_generation;
    if snapshot_doc == () || document_generation == () || stage_generation == () {
        return #{ok: false, state: "unavailable",
            detail: "composed pad geometry is missing document or stage snapshot provenance"};
    }
    for record in pad_records {
        if record.doc_id == () || record.document_generation == ()
            || record.stage_generation == () {
            return #{ok: false, state: "unavailable",
                detail: "a composed pad observation is missing document or stage snapshot provenance"};
        }
        if !physical_landing_pad_snapshot_matches(record, snapshot_doc,
                document_generation, stage_generation) {
            return #{ok: false, state: "stale",
                detail: "landing-pad visuals and proxies came from mixed composed USD snapshots"};
        }
    }
    if !physical_landing_pad_snapshot_matches(bus_frame, snapshot_doc,
            document_generation, stage_generation) {
        return #{ok: false, state: "stale",
            detail: "bus-frame and pad measurements came from different composed USD snapshots"};
    }
    let details = [];
    for index in 0..suffixes.len() {
        let leg_path = root + "/Leg" + suffixes[index];
        let visual_root = leg_path + "/LandingLegVisual";
        let collider_path = visual_root + "/FootPadCollider";
        let visual_path = visual_root + "/FootPad";
        let collider = pad_records[index * 2];
        let visual = pad_records[index * 2 + 1];
        if collider.path != collider_path || visual.path != visual_path {
            return #{ok: false, state: "invalid",
                detail: leg_path + ": batched composed pad paths do not match their requested order"};
        }
        let mount_arm = assembly_builder::composed_query(doc,
            #{path: visual_root + "/BodyMountArm", children: false,
              geometry_bounds: true});
        let mount_axle = assembly_builder::composed_query(doc,
            #{path: visual_root + "/MountAxle", children: false,
              geometry_bounds: true});
        let leg_pose = assembly_builder::composed_query(doc, #{path: leg_path,
            children: false, attrs: ["xformOp:translate", "xformOp:rotateXYZ"],
            rels: ["physics:filteredPairs"], schemas: true});
        let joint_path = root + "/Leg" + suffixes[index] + "_Spring";
        let joint = assembly_builder::composed_query(doc, #{path: joint_path,
            children: false, attrs: ["physics:localPos0", "physics:localPos1"],
            rels: ["physics:body0", "physics:body1"]});
        if !query_ok(collider) || !query_ok(visual)
            || !query_ok(mount_arm) || !query_ok(mount_axle)
            || !query_ok(leg_pose) || !query_ok(joint)
            || mount_arm.geometry_bounds == () || mount_axle.geometry_bounds == ()
            || collider.attrs == () || visual.attrs == ()
            || leg_pose.attrs == () {
            return #{ok: false, state: "unavailable",
                detail: leg_path + ": composed pad proxy or visual source geometry is missing"};
        }
        if !physical_landing_pad_snapshot_matches(mount_arm, snapshot_doc,
                document_generation, stage_generation)
            || !physical_landing_pad_snapshot_matches(mount_axle, snapshot_doc,
                document_generation, stage_generation)
            || !physical_landing_pad_snapshot_matches(leg_pose, snapshot_doc,
                document_generation, stage_generation)
            || !physical_landing_pad_snapshot_matches(joint, snapshot_doc,
                document_generation, stage_generation) {
            return #{ok: false, state: "stale",
                detail: leg_path + ": pad, mount, leg, and joint measurements came from different composed USD snapshots"};
        }
        let actual_station = leg_pose.attrs["xformOp:translate"];
        let actual_rotation = leg_pose.attrs["xformOp:rotateXYZ"];
        let filtered_pairs = if leg_pose.relationships == () { () }
            else { leg_pose.relationships["physics:filteredPairs"] };
        if filtered_pairs != () && filtered_pairs.len() > 0 {
            all_self_collision_filters_clear = false;
        }
        if leg_pose.api_schemas.contains("PhysicsFilteredPairsAPI") {
            all_self_collision_filters_clear = false;
        }
        if actual_station == () || actual_rotation == () {
            return #{ok: false, state: "unavailable",
                detail: leg_path + ": composed physical station or orientation is missing"};
        }
        for attrs in [collider.attrs, visual.attrs] {
            if attrs["radius"] == () || attrs["height"] == ()
                || attrs["axis"] == () || attrs["xformOp:translate"] == ()
                || attrs["xformOp:translate"].len() != 3 {
                return #{ok: false, state: "unavailable",
                    detail: leg_path + ": pad dimensions or local transform are incomplete"};
            }
        }
        let expected_station = geometry.stations[index];
        let station_errors = [actual_station[0] - expected_station.x,
            actual_station[1] - expected_station.y,
            actual_station[2] - expected_station.z];
        for error in station_errors {
            if error.abs() > station_deviation { station_deviation = error.abs(); }
        }
        if actual_rotation[0].abs() > geometry.rotation_tolerance_deg
            || (actual_rotation[1] - geometry.rotations_y_deg[index]).abs()
                > geometry.rotation_tolerance_deg
            || actual_rotation[2].abs() > geometry.rotation_tolerance_deg {
            rotations_match = false;
        }
        let bus_overlap = physical_bounds_overlap_depth(bus_frame.geometry_bounds,
            mount_arm.geometry_bounds);
        let axle_overlap = physical_bounds_overlap_depth(mount_arm.geometry_bounds,
            mount_axle.geometry_bounds);
        if bus_overlap == () || axle_overlap == () {
            return #{ok: false, state: "unavailable",
                detail: leg_path + ": composed bus-mount overlap could not be measured"};
        }
        if bus_overlap < minimum_bus_overlap { minimum_bus_overlap = bus_overlap; }
        if axle_overlap < minimum_axle_overlap { minimum_axle_overlap = axle_overlap; }
        let joint_targets = if joint.relationships == () { () } else { joint.relationships };
        let body0_targets = if joint_targets == () { () } else { joint_targets["physics:body0"] };
        let body1_targets = if joint_targets == () { () } else { joint_targets["physics:body1"] };
        let expected_joint_anchor = [expected_station.x, expected_station.y, expected_station.z];
        let joint_anchor = if joint.attrs == () { () } else { joint.attrs["physics:localPos0"] };
        let joint_other_anchor = if joint.attrs == () { () } else { joint.attrs["physics:localPos1"] };
        let joint_anchor_error = physical_vector_deviation(joint_anchor, expected_joint_anchor);
        let joint_other_anchor_error = physical_vector_deviation(joint_other_anchor, [0.0, 0.0, 0.0]);
        if body0_targets == () || body0_targets.len() != 1 || body0_targets[0] != root
            || body1_targets == () || body1_targets.len() != 1 || body1_targets[0] != leg_path
            || joint_anchor == () || joint_other_anchor == ()
            || joint_anchor_error == () || joint_anchor_error > geometry.station_tolerance_m
            || joint_other_anchor_error == () || joint_other_anchor_error > geometry.station_tolerance_m {
            physical_joints_match = false;
        }
        if collider.type_name != "Cylinder" || visual.type_name != "Cylinder" {
            all_topology = false;
        }
        let expected_center = geometry.center_y_m;
        let source_radius_error = (visual.attrs["radius"] - geometry.radius_m).abs();
        let source_height_error = (visual.attrs["height"] - geometry.height_m).abs();
        let source_center_error = physical_vector_deviation(
            visual.attrs["xformOp:translate"], [0.0, expected_center, 0.0]);
        let proxy_radius_error = (collider.attrs["radius"] - visual.attrs["radius"]).abs();
        let proxy_height_error = (collider.attrs["height"] - visual.attrs["height"]).abs();
        let proxy_center_error = physical_vector_deviation(
            collider.attrs["xformOp:translate"], visual.attrs["xformOp:translate"]);
        if source_center_error == () || proxy_center_error == () {
            return #{ok: false, state: "unavailable",
                detail: leg_path + ": pad-local source or proxy placement is incomplete"};
        }
        let collider_rotation = physical_transform_or_identity(collider.attrs,
            "xformOp:rotateXYZ", [0.0, 0.0, 0.0]);
        let visual_rotation = physical_transform_or_identity(visual.attrs,
            "xformOp:rotateXYZ", [0.0, 0.0, 0.0]);
        let collider_scale = physical_transform_or_identity(collider.attrs,
            "xformOp:scale", [1.0, 1.0, 1.0]);
        let visual_scale = physical_transform_or_identity(visual.attrs,
            "xformOp:scale", [1.0, 1.0, 1.0]);
        let collider_rotation_error = physical_vector_deviation(collider_rotation,
            [0.0, 0.0, 0.0]);
        let visual_rotation_error = physical_vector_deviation(visual_rotation,
            [0.0, 0.0, 0.0]);
        let collider_scale_error = physical_vector_deviation(collider_scale,
            [1.0, 1.0, 1.0]);
        let visual_scale_error = physical_vector_deviation(visual_scale,
            [1.0, 1.0, 1.0]);
        if collider_rotation_error == () || visual_rotation_error == ()
            || collider_scale_error == () || visual_scale_error == () {
            return #{ok: false, state: "unavailable",
                detail: leg_path + ": pad source or proxy orientation and scale are malformed"};
        }
        if source_radius_error > source_radius_deviation {
            source_radius_deviation = source_radius_error;
        }
        if source_height_error > source_height_deviation {
            source_height_deviation = source_height_error;
        }
        if source_center_error > source_center_deviation {
            source_center_deviation = source_center_error;
        }
        for deviation in [proxy_radius_error, proxy_height_error, proxy_center_error] {
            if deviation > geometry_deviation { geometry_deviation = deviation; }
        }
        let cooked_geometry = collider.collision_geometry;
        if cooked_geometry == () {
            return #{ok: false, state: "unavailable",
                detail: collider_path + ": effective Avian collider geometry is unavailable"};
        }
        if cooked_geometry.frame != "canonical_stage" {
            return #{ok: false, state: "unavailable",
                detail: collider_path + ": effective collider geometry is not in canonical-stage coordinates"};
        }
        let cooked_shape = cooked_geometry.shape;
        let cooked_deviation = ();
        let cooked_axis_matches = false;
        if cooked_shape == "cylinder" {
            let cooked_pose = cooked_geometry.local_to_stage;
            let visual_bounds = visual.geometry_bounds;
            if cooked_geometry.geometry_frame != "collider_local"
                || cooked_geometry.radius_m == () || cooked_geometry.half_height_m == ()
                || cooked_pose == () || cooked_pose.translation_m == ()
                || cooked_pose.rotation_wxyz == () || cooked_pose.rotation_wxyz.len() != 4
                || visual_bounds == () || visual_bounds.frame != "canonical_stage"
                || visual_bounds.center == () || visual_bounds.half_extents == ()
                || visual_bounds.center.len() != 3 || visual_bounds.half_extents.len() != 3
                || cooked_pose.translation_m.len() != 3 {
                return #{ok: false, state: "unavailable",
                    detail: collider_path + ": cooked cylinder dimensions, pose, or visible source bounds are incomplete"};
            }
            if !griffin_geometry::scalar_is_finite(cooked_geometry.radius_m)
                || !griffin_geometry::scalar_is_finite(cooked_geometry.half_height_m)
                || cooked_geometry.radius_m <= 0.0 || cooked_geometry.half_height_m <= 0.0 {
                return #{ok: false, state: "invalid",
                    detail: collider_path + ": cooked cylinder dimensions are not finite and positive"};
            }
            for value in cooked_pose.translation_m {
                if !griffin_geometry::scalar_is_finite(value) {
                    return #{ok: false, state: "invalid",
                        detail: collider_path + ": cooked collider pose is not finite"};
                }
            }
            for value in cooked_pose.rotation_wxyz {
                if !griffin_geometry::scalar_is_finite(value) {
                    return #{ok: false, state: "invalid",
                        detail: collider_path + ": cooked collider orientation is not finite"};
                }
            }
            cooked_axis_matches = physical_cooked_y_axis_matches(
                cooked_pose.rotation_wxyz, geometry.rotation_tolerance_deg);
            if !cooked_axis_matches {
                all_cooked_axis_matches = false;
                all_geometry_semantics_match = false;
            }
            let dimensions_deviation = physical_vector_deviation(
                [cooked_geometry.radius_m, cooked_geometry.half_height_m,
                    cooked_geometry.radius_m], visual_bounds.half_extents);
            let center_deviation = physical_vector_deviation(
                cooked_pose.translation_m, visual_bounds.center);
            if dimensions_deviation == () || center_deviation == () {
                return #{ok: false, state: "unavailable",
                    detail: collider_path + ": cooked and visual geometry could not be compared in a common frame"};
            }
            cooked_deviation = dimensions_deviation;
            if center_deviation > cooked_deviation { cooked_deviation = center_deviation; }
            if cooked_deviation > maximum_cooked_geometry_deviation_m {
                maximum_cooked_geometry_deviation_m = cooked_deviation;
            }
            if cooked_deviation > geometry_deviation { geometry_deviation = cooked_deviation; }
        } else {
            all_geometry_semantics_match = false;
            all_cooked_geometry_comparable = false;
        }
        let bounds_deviation = physical_pad_bounds_deviation(
            collider.geometry_bounds, visual.geometry_bounds);
        if bounds_deviation == () {
            all_topology = false;
            all_geometry_available = false;
        } else if bounds_deviation > geometry_deviation {
            geometry_deviation = bounds_deviation;
        }
        if collider.attrs["axis"] != "Y" || visual.attrs["axis"] != "Y" {
            all_axes_match = false;
        }
        if collider.type_name != "Cylinder" || visual.type_name != "Cylinder"
            || collider.attrs["axis"] != "Y" || visual.attrs["axis"] != "Y"
            || collider_rotation_error > geometry.rotation_tolerance_deg
            || visual_rotation_error > geometry.rotation_tolerance_deg
            || collider_scale_error != 0.0 || visual_scale_error != 0.0 {
            all_geometry_semantics_match = false;
        }
        if collider.attrs["axis"] != "Y" || visual.attrs["axis"] != "Y"
            || collider.attrs["xformOp:translate"][0].abs() > geometry.tolerance_m
            || collider.attrs["xformOp:translate"][2].abs() > geometry.tolerance_m
            || visual.attrs["xformOp:translate"][0].abs() > geometry.tolerance_m
            || visual.attrs["xformOp:translate"][2].abs() > geometry.tolerance_m {
            all_topology = false;
        }
        if collider.attrs["physics:collisionEnabled"] != true {
            all_collision_enabled = false;
        }
        if collider.attrs["visibility"] != "invisible"
            || collider.attrs["purpose"] != "proxy" {
            all_proxy_hidden = false;
        }
        if !collider.api_schemas.contains("PhysicsCollisionAPI") {
            all_collision_enabled = false;
        }
        let targets = collider.relationships["lunco:collider:geometrySource"];
        if targets == () || targets.len() != 1 || targets[0] != visual_path
            || collider.attrs["lunco:collider:geometrySource"] != ()
            || collider.attrs["lunco:requirement"] != () {
            all_source_relationships = false;
        }
        if visual.attrs["physics:collisionEnabled"] != false {
            all_visual_disabled = false;
        }
        for legacy_name in ["OuterStrut", "FootPad"] {
            let legacy = assembly_builder::composed_query(doc,
                #{path: leg_path + "/" + legacy_name, children: false,
                  attrs: ["physics:collisionEnabled", "visibility"]});
            if !query_ok(legacy) || legacy.attrs == ()
                || legacy.attrs["physics:collisionEnabled"] != false
                || legacy.attrs["visibility"] != "invisible" {
                all_legacy_disabled = false;
            } else if !physical_landing_pad_snapshot_matches(legacy, snapshot_doc,
                    document_generation, stage_generation) {
                return #{ok: false, state: "stale",
                    detail: leg_path + ": legacy collider measurements came from a different composed USD snapshot"};
            }
        }
        let legacy_proxy = assembly_builder::composed_query(doc,
            #{path: leg_path + "/FootPadCollider", children: false});
        if query_ok(legacy_proxy) {
            if !physical_landing_pad_snapshot_matches(legacy_proxy, snapshot_doc,
                    document_generation, stage_generation) {
                return #{ok: false, state: "stale",
                    detail: leg_path + ": legacy collider query came from a different composed USD snapshot"};
            }
            all_legacy_disabled = false;
        }
        details.push(#{leg: leg_path, proxy: collider_path, visual: visual_path,
            collision_enabled: collider.attrs["physics:collisionEnabled"],
            proxy_hidden: collider.attrs["visibility"] == "invisible",
            source_relationship: targets, composed_geometry_deviation_m: bounds_deviation,
            cooked_geometry_shape: cooked_shape,
            cooked_axis_matches: cooked_axis_matches,
            cooked_geometry_deviation_m: cooked_deviation,
            filtered_pairs: filtered_pairs, bus_mount_overlap_m: bus_overlap,
            mount_axle_overlap_m: axle_overlap, joint_targets: joint_targets,
            joint_anchor: joint_anchor,
            station: actual_station, rotation_y_deg: actual_rotation[1]});
    }
    #{ok: true, state: "available", doc_id: snapshot_doc,
      document_generation: document_generation, stage_generation: stage_generation,
      geometry_deviation_m: if all_geometry_available { geometry_deviation } else { () },
      cooked_geometry_deviation_m: if all_cooked_geometry_comparable {
          maximum_cooked_geometry_deviation_m
      } else { () },
      cooked_axis_matches: all_cooked_axis_matches,
      source_radius_deviation_m: source_radius_deviation,
      source_height_deviation_m: source_height_deviation,
      source_center_deviation_m: source_center_deviation,
      station_deviation_m: station_deviation,
      rotation_matches: rotations_match,
      bus_mount_overlap_m: minimum_bus_overlap,
      mount_axle_overlap_m: minimum_axle_overlap,
      physical_joints_match: physical_joints_match,
      topology_matches: all_topology,
      collision_enabled: all_collision_enabled,
      pad_axes_match: all_axes_match,
      pad_geometry_semantics_match: all_geometry_semantics_match,
      proxy_hidden: all_proxy_hidden,
      source_relationships_valid: all_source_relationships,
      self_collision_filter_clear: all_self_collision_filters_clear,
      visual_collision_disabled: all_visual_disabled,
      legacy_collision_disabled: all_legacy_disabled,
      collision_matches_visual: all_geometry_available && all_axes_match
        && all_geometry_semantics_match && all_cooked_geometry_comparable
        && all_cooked_axis_matches && geometry_deviation <= geometry.tolerance_m,
      tolerance_m: geometry.tolerance_m, details: details}
}

/// Compose the source-derived deck and leg contact plans into one Editor edit.
fn physical_collision_plan(doc, edit_target, root) {
    let deck = physical_top_deck_collider_plan(doc, edit_target, root);
    if deck.ok != true { return deck; }
    let legs = physical_landing_leg_pad_plan(doc, edit_target, root);
    if legs.ok != true { return legs; }
    let ops = [];
    for op in deck.ops { ops.push(op); }
    for op in legs.ops { ops.push(op); }
    #{ok: true, kind: "griffin_physical_collision_geometry", root: root,
      deck_op_count: deck.ops.len(), leg_op_count: legs.ops.len(),
      deck_collider_count: 9, collider_count: 13, ops: ops}
}

fn apply_physical_colliders(doc, edit_target, root, parent_gen) {
    let plan = physical_collision_plan(doc, edit_target, root);
    if plan.ok != true || plan.ops.len() == 0 { return plan; }
    let command = assembly_edit::batch(doc,
        "Derive Griffin physical colliders from source geometry", plan.ops, parent_gen);
    #{ok: command.ok == true, kind: plan.kind, command: command,
      root: root, collider_count: plan.collider_count}
}

fn _tank_support_annulus_geometry(center, inner_radius, outer_radius, thickness, segments) {
    if center == () || !vec3_is_native(center) || inner_radius <= 0.0
        || outer_radius <= inner_radius || thickness <= 0.0 || segments < 8 {
        return plan_error("tank-support annulus needs a typed center, ordered radii, positive stock, and at least eight segments");
    }
    let points = [];
    let half = thickness / 2.0;
    for radius in [outer_radius, outer_radius, inner_radius, inner_radius] {
        let y = if radius == outer_radius {
            if points.len() == 0 { half } else { -half }
        } else { if points.len() == segments * 2 { half } else { -half } };
        for index in 0..segments {
            let angle = 2.0 * griffin_spec::pi_value() * index / segments;
            points.push([center.x + radius * cos(angle), center.y + y,
                center.z + radius * sin(angle)]);
        }
    }
    let counts = [];
    let indices = [];
    for index in 0..segments {
        let next = (index + 1) % segments;
        let ot = index; let ot_next = next;
        let ob = segments + index; let ob_next = segments + next;
        let it = 2 * segments + index; let it_next = 2 * segments + next;
        let ib = 3 * segments + index; let ib_next = 3 * segments + next;
        for face in [
            [ot, it, it_next, ot_next],
            [ob, ob_next, ib_next, ib],
            [ot, ot_next, ob_next, ob],
            [it, ib, ib_next, it_next]
        ] {
            counts.push(4);
            for vertex in face { indices.push(vertex); }
        }
    }
    #{ok: true, points: points, face_counts: counts, face_indices: indices,
      segments: segments, inner_radius: inner_radius, outer_radius: outer_radius}
}

fn _tank_support_annulus_mesh_plan(doc, edit_target, parent, name, center,
    inner_radius, outer_radius, thickness, segments, color) {
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let geometry = _tank_support_annulus_geometry(center, inner_radius,
        outer_radius, thickness, segments);
    if geometry.ok == false { return geometry; }
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": tank opening collar must resolve to Mesh");
        }
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        let shape = assembly_builder::mesh_shape_plan(edit_target, parent, name,
            geometry.points, geometry.face_counts, geometry.face_indices, color, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "points", type_name: "point3f[]", value: _mesh_points_literal(geometry.points)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "faceVertexCounts", type_name: "int[]", value: _mesh_ints_literal(geometry.face_counts)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "faceVertexIndices", type_name: "int[]", value: _mesh_ints_literal(geometry.face_indices)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "subdivisionScheme", type_name: "token", value: "\"none\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "doubleSided", type_name: "bool", value: "false"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(color)}});
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: path, value: [0.0, 0.0, 0.0]}});
    #{ok: true, path: path, ops: ops, geometry: geometry}
}

fn tank_support_perimeter_plan(doc, edit_target, root, plane_index) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("tank_support_perimeter_plan requires a document, edit target, and absolute root");
    }
    let profile = griffin_spec::visual_outer_body_profile_coordinates();
    let radius = griffin_spec::visual_tank_support_perimeter_radius_m();
    let section = griffin_spec::visual_tank_support_perimeter_section_m();
    let planes = griffin_spec::visual_tank_support_planes_m();
    if profile.len() != 8 || radius <= 0.0 || section <= 0.0
        || planes.len() != 3 || plane_index < 0 || plane_index >= planes.len() {
        return plan_error("typed Griffin tank-support perimeter datums or plane index are invalid");
    }
    for plane_y in planes {
        if !griffin_geometry::scalar_is_finite(plane_y) {
            return plan_error("tank-support ring planes must be finite SysML scalars");
        }
    }
    let parent = root + "/TankSupportPlate";
    let assembly = assembly_builder::composed_query(doc, #{path: parent, children: false});
    if !query_ok(assembly) || assembly.type_name != "Xform" {
        return plan_error(parent + ": source-owned support assembly must be an Xform");
    }
    let names = ["TankSupportPerimeterUpper", "TankSupportPerimeter",
        "TankSupportPerimeterLower"];
    _octagonal_perimeter_mesh_plan(doc, edit_target, parent, names[plane_index],
        profile, radius, planes[plane_index], section,
        griffin_spec::visual_tank_support_display_color())
}

fn tank_support_opening_plan(doc, edit_target, root, tank_index, plane_index) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("tank_support_opening_plan requires a document, edit target, and absolute root");
    }
    let tanks = griffin_spec::component_tank_stations();
    let names = griffin_spec::propellant_tank_names();
    let planes = griffin_spec::visual_tank_support_planes_m();
    let inner = griffin_spec::visual_tank_opening_inner_radius_m();
    let outer = griffin_spec::visual_tank_opening_outer_radius_m();
    let section = griffin_spec::visual_tank_support_perimeter_section_m();
    let segments = griffin_spec::visual_tank_opening_segments();
    if tanks.len() != 4 || names.len() != 4 || planes.len() != 3
        || tank_index < 0 || tank_index >= tanks.len()
        || plane_index < 0 || plane_index >= planes.len()
        || inner <= 0.0 || outer <= inner || section <= 0.0 || segments < 8 {
        return plan_error("typed Griffin annular-opening datums or indices are invalid");
    }
    let suffix = if plane_index == 0 { "Upper" }
        else if plane_index == 1 { "" } else { "Lower" };
    let center = vec3(tanks[tank_index].x, planes[plane_index], tanks[tank_index].z);
    _tank_support_annulus_mesh_plan(doc, edit_target, root + "/TankSupportPlate",
        "Opening" + names[tank_index] + suffix, center, inner, outer,
        section, segments, griffin_spec::visual_tank_collar_display_color())
}

fn _octagonal_open_frame_mesh_plan(doc, edit_target, root, name, stations, ring_y, section, color) {
    let path = root + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let geometry = griffin_geometry::perimeter_beam_geometry(stations, ring_y, section);
    if geometry.ok == false { return plan_error(geometry.error); }
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": open octagonal frame must resolve to a Mesh");
        }
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        let shape = assembly_builder::mesh_shape_plan(edit_target, root, name,
            geometry.points, geometry.face_counts, geometry.face_indices,
            color, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "points", type_name: "point3f[]",
        value: _mesh_points_literal(geometry.points)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "faceVertexCounts", type_name: "int[]",
        value: _mesh_ints_literal(geometry.face_counts)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "faceVertexIndices", type_name: "int[]",
        value: _mesh_ints_literal(geometry.face_indices)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "subdivisionScheme", type_name: "token", value: "\"none\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "doubleSided", type_name: "bool", value: "false"}});
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: path,
        value: [0.0, 0.0, 0.0]}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(color)}});
    #{ok: true, path: path, ops: ops,
      point_count: geometry.points.len(), face_count: geometry.face_counts.len()}
}

fn _octagonal_perimeter_mesh_plan(doc, edit_target, root, name,
    profile, radius, center_y, section, color) {
    let path = root + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let geometry = griffin_geometry::tank_support_perimeter_geometry(
        profile, radius, center_y, section);
    if geometry.ok == false { return plan_error(geometry.error); }
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": octagonal perimeter must resolve to Mesh");
        }
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        let shape = assembly_builder::mesh_shape_plan(edit_target, root, name,
            geometry.points, geometry.face_counts, geometry.face_indices, color, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    for pair in [
        ["points", "point3f[]", _mesh_points_literal(geometry.points)],
        ["faceVertexCounts", "int[]", _mesh_ints_literal(geometry.face_counts)],
        ["faceVertexIndices", "int[]", _mesh_ints_literal(geometry.face_indices)]
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: pair[0], type_name: pair[1], value: pair[2]}});
    }
    for property in [
        #{name: "doubleSided", type_name: "bool", value: "false"},
        #{name: "subdivisionScheme", type_name: "token", value: "\"none\""},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: property.name, type_name: property.type_name, value: property.value}});
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(color)}});
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: path, value: [0.0, 0.0, 0.0]}});
    #{ok: true, path: path, ops: ops,
      point_count: geometry.points.len(), face_count: geometry.face_counts.len()}
}

fn _central_bucket_mesh_plan(doc, edit_target, root, name, profile, segments, color) {
    let path = root + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": central bucket must resolve to Mesh");
        }
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: root,
            name: name, type_name: "Mesh", reference: (), reference_prim_path: ""}});
    }
    ops.push(#{RevolveProfileMesh: #{edit_target: edit_target, path: path,
        profile: profile, angular_segments: segments.to_int(), display_color: color,
        collision_enabled: false}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    #{ok: true, path: path, ops: ops}
}

fn refine_griffin_bus_component_plan(doc, edit_target, root) {
    octagonal_griffin_bus_component_plan(doc, edit_target, root)
}

// Assembly convenience wrapper. It is intentionally a dry diagnostic only:
// referenced children remain owned by their component document, so callers
// must open that document and submit refine_griffin_bus_component_plan there.
fn refine_griffin_bus_plan(doc, edit_target, root) {
    if !absolute_root(root) { return plan_error("refine_griffin_bus_plan requires an absolute root"); }
    refine_griffin_bus_component_plan(doc, edit_target, root + "/Bus")
}

fn apply_refined_griffin_bus(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_bus_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Refine Griffin bus octagonal frame", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

// The bus has a few genuinely cuboidal equipment details (avionics shelf and
// rails). Keep this primitive helper local to those details; the load-bearing
// body itself is authored from the typed octagonal profile below.
fn _bus_detail_cube_plan(doc, edit_target, parent, name, size, scale, translation, color) {
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Cube" {
            return plan_error(path + ": bus equipment detail must resolve to Cube, got " + current.type_name);
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            translation, (), scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    } else {
        let shape = assembly_builder::cube_shape_plan(edit_target, parent, name,
            size, scale, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
        ops.push(#{SetTranslate: #{edit_target: edit_target, path: path, value: translation}});
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(color)}});
    #{ok: true, path: path, ops: ops}
}

// Author the actual Griffin bus geometry from the typed SysML visual
// configuration. The primary body is an open eight-sided frame mesh; the outer
// deck, skirt, and tank-support perimeter reuse the same octagonal profile.
fn _outer_body_component_mesh_plan(doc, edit_target, parent, name, width, depth,
    height, translation, color) {
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let geometry = _outer_body_prism_geometry(width, depth, height);
    if !geometry.ok { return geometry; }
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": typed outer-body profile must resolve to Mesh, got " + current.type_name);
        }
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        let shape = assembly_builder::mesh_shape_plan(edit_target, parent, name,
            geometry.points, geometry.face_counts, geometry.face_indices, color, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path, name: "points",
        type_name: "point3f[]", value: _mesh_points_literal(geometry.points)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "faceVertexCounts", type_name: "int[]",
        value: _mesh_ints_literal(geometry.face_counts)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "faceVertexIndices", type_name: "int[]",
        value: _mesh_ints_literal(geometry.face_indices)}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "subdivisionScheme", type_name: "token", value: "\"none\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "doubleSided", type_name: "bool", value: "false"}});
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: path, value: translation}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(color)}});
    #{ok: true, path: path, ops: ops}
}

fn octagonal_griffin_bus_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("octagonal_griffin_bus_component_plan requires a document, edit target, and absolute root");
    }
    let body_width = griffin_spec::visual_body_width_m();
    let body_depth = griffin_spec::visual_body_depth_m();
    let body_height = griffin_spec::visual_body_height_m();
    let deck_width = griffin_spec::visual_deck_width_m();
    let deck_depth = griffin_spec::visual_deck_depth_m();
    let deck_thickness = griffin_spec::visual_deck_thickness_m();
    let deck_y = griffin_spec::visual_deck_center_y_m();
    let skirt_width = griffin_spec::visual_lower_skirt_width_m();
    let skirt_depth = griffin_spec::visual_lower_skirt_depth_m();
    let skirt_height = griffin_spec::visual_lower_skirt_height_m();
    let skirt_y = griffin_spec::visual_lower_skirt_center_y_m();
    let body_name = "PerimeterFrame";
    let skirt_name = "LowerServiceSkirtOctagon";
    let ring_y = griffin_spec::visual_frame_ring_center_y_m();
    let ring_section = griffin_spec::visual_frame_ring_section_m();
    if body_width == () || body_depth == () || body_height == () || deck_width == ()
        || deck_depth == () || deck_thickness == () || deck_y == () || skirt_width == ()
        || skirt_depth == () || skirt_height == () || skirt_y == ()
        || ring_section == () {
        return plan_error("typed Griffin octagonal body datums are incomplete");
    }
    let ops = [];
    let rail_names = griffin_spec::visual_rail_names();
    let rail_stations = griffin_spec::visual_rail_station_positions();
    let rail_width = griffin_spec::visual_rail_width_m();
    let rail_length = griffin_spec::visual_rail_length_m();
    let rail_depth = griffin_spec::visual_rail_depth_m();
    if rail_names.len() != 8 || rail_stations.len() != rail_names.len()
        || ring_y.len() != 2
        || ring_section <= 0.0 || rail_width == () || rail_length == () || rail_depth == () {
        return plan_error("typed Griffin open-frame station vectors or member dimensions are incomplete");
    }
    let frame = _octagonal_open_frame_mesh_plan(doc, edit_target, root,
        body_name, rail_stations, ring_y, ring_section,
        griffin_spec::visual_frame_display_color());
    if !frame.ok { return frame; }
    for op in frame.ops { ops.push(op); }
    if (deck_width - deck_depth).abs() > 1.0e-6
        || (skirt_width - skirt_depth).abs() > 1.0e-6 {
        return plan_error("Griffin deck and service-skirt plan profiles must remain octagonal and square");
    }
    let profile = griffin_spec::visual_outer_body_profile_coordinates();
    let rings = [
        #{name: "TopDeckOctagon", radius: deck_width / 2.0, center_y: deck_y,
          section: deck_thickness, color: griffin_spec::visual_deck_display_color()},
        #{name: skirt_name, radius: skirt_width / 2.0, center_y: skirt_y,
          section: skirt_height, color: griffin_spec::visual_lower_skirt_display_color()}
    ];
    for ring in rings {
        let plan = _octagonal_perimeter_mesh_plan(doc, edit_target, root, ring.name,
            profile, ring.radius, ring.center_y, ring.section, ring.color);
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    let avionics = _bus_detail_cube_plan(doc, edit_target, root, "AvionicsDeck", 1.0,
        [griffin_spec::visual_avionics_deck_width_m(), griffin_spec::visual_avionics_deck_thickness_m(), griffin_spec::visual_avionics_deck_depth_m()],
        [0.0, griffin_spec::visual_avionics_deck_center_y_m(), 0.0],
        griffin_spec::visual_avionics_deck_display_color());
    if !avionics.ok { return avionics; }
    for op in avionics.ops { ops.push(op); }
    let pod = _bus_detail_cube_plan(doc, edit_target, root, "AvionicsPod", 1.0,
        [0.72, 0.36, 0.72], [0.0, griffin_spec::visual_avionics_deck_center_y_m() + 0.21, 0.0],
        griffin_spec::visual_avionics_pod_display_color());
    if !pod.ok { return pod; }
    for op in pod.ops { ops.push(op); }
    for index in 0..rail_names.len() {
        let station = rail_stations[index];
        let plan = _bus_detail_cube_plan(doc, edit_target, root, rail_names[index], 1.0,
            [rail_width, rail_length, rail_depth], [station.x, station.y, station.z],
            griffin_spec::visual_rail_display_color());
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    let source = sysml_requirements::source();
    let bucket_segments = _sysml_number(source, "centralBucketSegments");
    let bucket_thickness = _sysml_number(source, "centralBucketShellThicknessM");
    let upper_inner_bottom = _sysml_number(source, "upperBucketInnerBottomRadiusM");
    let upper_outer_bottom = _sysml_number(source, "upperBucketOuterBottomRadiusM");
    let upper_inner_top = _sysml_number(source, "upperBucketInnerTopRadiusM");
    let upper_outer_top = _sysml_number(source, "upperBucketOuterTopRadiusM");
    let upper_bottom_y = _sysml_number(source, "upperBucketBottomCenterYM");
    let upper_top_y = _sysml_number(source, "upperBucketTopCenterYM");
    let lower_inner_top = _sysml_number(source, "lowerBucketInnerTopRadiusM");
    let lower_outer_top = _sysml_number(source, "lowerBucketOuterTopRadiusM");
    let lower_inner_bottom = _sysml_number(source, "lowerBucketInnerBottomRadiusM");
    let lower_outer_bottom = _sysml_number(source, "lowerBucketOuterBottomRadiusM");
    let lower_top_y = _sysml_number(source, "lowerBucketTopCenterYM");
    let lower_bottom_y = _sysml_number(source, "lowerBucketBottomCenterYM");
    if bucket_segments < 8 || bucket_thickness <= 0.0
        || upper_inner_bottom <= 0.0 || upper_outer_bottom <= upper_inner_bottom
        || upper_inner_top <= 0.0 || upper_outer_top <= upper_inner_top
        || upper_bottom_y >= upper_top_y || lower_inner_top <= 0.0
        || lower_outer_top <= lower_inner_top || lower_inner_bottom <= 0.0
        || lower_outer_bottom <= lower_inner_bottom || lower_bottom_y >= lower_top_y {
        return plan_error("typed Griffin upper/lower bucket profile datums are incomplete or invalid");
    }
    for bucket in [
        #{name: "UpperCentralBucket",
          profile: [[upper_inner_bottom, upper_bottom_y],
              [upper_outer_bottom, upper_bottom_y], [upper_outer_top, upper_top_y],
              [upper_inner_top, upper_top_y]]},
        #{name: "LowerCentralBucket",
          profile: [[lower_inner_top, lower_top_y],
              [lower_outer_top, lower_top_y], [lower_outer_bottom, lower_bottom_y],
              [lower_inner_bottom, lower_bottom_y]]}
    ] {
        let plan = _central_bucket_mesh_plan(doc, edit_target, root,
            bucket.name, bucket.profile, bucket_segments,
            griffin_spec::visual_tank_support_display_color());
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    // The central bucket carries a dedicated FLIP deck. Keep the platform
    // geometry in the same component and derive its local placement from the
    // Griffin-frame SysML datum and the bus mount, so the rover and adapter
    // cannot drift onto separate hard-coded coordinate systems.
    let adapter_width = griffin_spec::visual_payload_adapter_width_m();
    let adapter_depth = griffin_spec::visual_payload_adapter_depth_m();
    let adapter_thickness = griffin_spec::visual_payload_adapter_thickness_m();
    let adapter_center_y = griffin_spec::visual_payload_adapter_center_y_m();
    let bus_mount_y = griffin_spec::component_bus_mount_y();
    if adapter_width == () || adapter_depth == () || adapter_thickness == ()
        || adapter_center_y == () || bus_mount_y == ()
        || adapter_width <= 0.0 || adapter_depth <= 0.0 || adapter_thickness <= 0.0
        || adapter_center_y - bus_mount_y - adapter_thickness / 2.0
            < upper_top_y - 1.0e-6 {
        return plan_error("FLIP payload-adapter footprint or upper-bucket contact datum is invalid");
    }
    let adapter = _outer_body_component_mesh_plan(doc, edit_target, root,
        "RoverPayloadDeck", adapter_width, adapter_depth, adapter_thickness,
        [0.0, adapter_center_y - bus_mount_y, 0.0],
        griffin_spec::visual_deck_display_color());
    if !adapter.ok { return adapter; }
    for op in adapter.ops { ops.push(op); }
    #{ok: true, kind: "griffin_octagonal_bus_component", root: root,
      paths: [root + "/" + body_name, root + "/TopDeckOctagon", root + "/" + skirt_name,
        root + "/TankSupportPlate", root + "/UpperCentralBucket", root + "/LowerCentralBucket",
        root + "/RoverPayloadDeck"],
      ops: ops, no_op: ops.len() == 0}
}

fn _native_vec3_axis(value, axis) {
    if vec3_is_native(value) {
        return if axis == 0 { value.x } else if axis == 1 { value.y } else { value.z };
    }
    if array_is(value) && value.len() == 3 { return value[axis]; }
    ()
}

// Read the payload deck mesh and both linked assembly roots back from the
// composed Editor document. The check measures tire-to-deck contact and the
// wheel footprint from SysML wheel stations, so a matching scene transform
// alone cannot pass when the adapter geometry or source wheel envelope drifts.
fn flip_payload_interface_observation(doc, root) {
    if doc == () || !absolute_root(root) {
        return #{ok: false, state: "invalid", error: "payload observation requires a document and absolute scene root"};
    }
    let source = sysml_requirements::source();
    let adapter = assembly_builder::composed_query(doc, #{
        path: root + "/Griffin1/Bus/RoverPayloadDeck", children: false,
        attrs: ["points", "xformOp:translate"]});
    let bus = assembly_builder::composed_query(doc, #{
        path: root + "/Griffin1/Bus", children: false,
        attrs: ["xformOp:translate"]});
    let lander = assembly_builder::composed_query(doc, #{
        path: root + "/Griffin1", children: false,
        attrs: ["xformOp:translate"]});
    let rover = assembly_builder::composed_query(doc, #{
        path: root + "/FLIP", children: false,
        attrs: ["xformOp:translate"]});
    if !query_ok(adapter) || adapter.type_name != "Mesh" || adapter.attrs == ()
        || !query_ok(bus) || bus.attrs == () || !query_ok(lander) || lander.attrs == ()
        || !query_ok(rover) || rover.attrs == () {
        return #{ok: false, state: "unavailable", error: "composed payload adapter or linked vehicle transforms are unavailable"};
    }
    let points = adapter.attrs["points"];
    let adapter_t = adapter.attrs["xformOp:translate"];
    let bus_t = bus.attrs["xformOp:translate"];
    let lander_t = lander.attrs["xformOp:translate"];
    let rover_t = rover.attrs["xformOp:translate"];
    if points == () || points.len() < 8 || adapter_t == () || bus_t == ()
        || lander_t == () || rover_t == () {
        return #{ok: false, state: "unavailable", error: "adapter mesh or composed translations are incomplete"};
    }
    let min_x = 1.0e30;
    let max_x = -1.0e30;
    let min_y = 1.0e30;
    let max_y = -1.0e30;
    let min_z = 1.0e30;
    let max_z = -1.0e30;
    for point in points {
        let x = _native_vec3_axis(point, 0);
        let y = _native_vec3_axis(point, 1);
        let z = _native_vec3_axis(point, 2);
        if x == () || y == () || z == () {
            return #{ok: false, state: "unavailable", error: "adapter mesh points are not native 3D vectors"};
        }
        if x < min_x { min_x = x; }
        if x > max_x { max_x = x; }
        if y < min_y { min_y = y; }
        if y > max_y { max_y = y; }
        if z < min_z { min_z = z; }
        if z > max_z { max_z = z; }
    }
    let wheel_x = griffin_spec::rover_wheel_station_x();
    let wheel_y = griffin_spec::rover_wheel_station_y();
    let wheel_z = griffin_spec::rover_wheel_station_z();
    let radius = griffin_spec::rover_wheel_radius_m();
    let width = griffin_spec::rover_wheel_width_m();
    let tolerance = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("geometryVerificationToleranceM"));
    if wheel_x.len() != 4 || wheel_y.len() != 4 || wheel_z.len() != 4
        || radius == () || width == () || tolerance == () {
        return #{ok: false, state: "invalid", error: "FLIP wheel geometry or shared tolerance is missing from SysML"};
    }
    let minimum_wheel_y = wheel_y[0];
    for index in 1..wheel_y.len() {
        if wheel_y[index] < minimum_wheel_y { minimum_wheel_y = wheel_y[index]; }
    }
    let adapter_top = _native_vec3_axis(lander_t, 1)
        + _native_vec3_axis(bus_t, 1) + _native_vec3_axis(adapter_t, 1) + max_y;
    let wheel_bottom = _native_vec3_axis(rover_t, 1) + minimum_wheel_y - radius;
    let vertical_error = wheel_bottom - adapter_top;
    let deck_center_x = _native_vec3_axis(lander_t, 0)
        + _native_vec3_axis(bus_t, 0) + _native_vec3_axis(adapter_t, 0);
    let deck_center_z = _native_vec3_axis(lander_t, 2)
        + _native_vec3_axis(bus_t, 2) + _native_vec3_axis(adapter_t, 2);
    let deck_min_x = deck_center_x + min_x;
    let deck_max_x = deck_center_x + max_x;
    let deck_min_z = deck_center_z + min_z;
    let deck_max_z = deck_center_z + max_z;
    let rover_x = _native_vec3_axis(rover_t, 0);
    let rover_z = _native_vec3_axis(rover_t, 2);
    let footprint_fits = true;
    for index in 0..4 {
        if rover_x + wheel_x[index] - radius < deck_min_x - tolerance
            || rover_x + wheel_x[index] + radius > deck_max_x + tolerance
            || rover_z + wheel_z[index] - width / 2.0 < deck_min_z - tolerance
            || rover_z + wheel_z[index] + width / 2.0 > deck_max_z + tolerance {
            footprint_fits = false;
        }
    }
    #{ok: true, state: if vertical_error.abs() <= tolerance && footprint_fits { "pass" } else { "fail" },
      path: root + "/Griffin1/Bus/RoverPayloadDeck", tire_bottom_y_m: wheel_bottom,
      adapter_top_y_m: adapter_top, vertical_error_m: vertical_error,
      adapter_bounds_x_m: [deck_min_x, deck_max_x],
      adapter_bounds_z_m: [deck_min_z, deck_max_z],
      wheel_footprint_fits: footprint_fits, tolerance_m: tolerance}
}

// Update the eight assembly-owned corner posts in-place. These posts are not
// part of the replaceable bus asset: they are visual-review detail geometry
// authored in the vehicle document, so their metric contract must be applied
// against the same document through the typed Editor journal.
fn refine_griffin_bus_assembly_rails_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_bus_assembly_rails_plan requires a document, edit target, and absolute root");
    }
    let names = griffin_spec::visual_rail_names();
    let xs = griffin_spec::visual_rail_station_x();
    let ys = griffin_spec::visual_rail_station_y();
    let zs = griffin_spec::visual_rail_station_z();
    let width = griffin_spec::visual_rail_width_m();
    let length = griffin_spec::visual_rail_length_m();
    let depth = griffin_spec::visual_rail_depth_m();
    if names.len() == 0 || xs.len() != names.len() || ys.len() != names.len()
        || zs.len() != names.len() || width == () || length == () || depth == () {
        return plan_error("bus assembly rail SysML arrays or dimensions are incomplete");
    }
    let ops = [];
    let paths = [];
    for index in 0..names.len() {
        let path = root + "/" + names[index];
        let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
        if !query_ok(prim) || prim.type_name != "Cube" {
            return plan_error(path + ": assembly rail must already be an existing Cube");
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            [xs[index], ys[index], zs[index]], (), [width, length, depth]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: "purpose", type_name: "token", value: "\"render\""}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
        paths.push(path);
    }
    #{ok: true, kind: "griffin_bus_assembly_rail_refinement", root: root,
      paths: paths, ops: ops, no_op: ops.len() == 0}
}

fn apply_refined_griffin_bus_assembly_rails(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_bus_assembly_rails_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Refine Griffin bus assembly rails", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

// Component-local helpers for presentation refinements.  They deliberately
// use the same typed shape/placement planners as assembly authoring, so a
// reusable component can be improved in its own Editor document without
// writing USDA text or leaking a second geometry recipe into the vehicle.
fn _component_cube_visual_ops(doc, edit_target, parent, name,
    translation, rotation, scale, color) {
    let path = parent + "/" + name;
    let existing = _component_query(doc, path);
    let ops = [];
    if !existing.ok {
        let shape = assembly_builder::cube_shape_plan(edit_target, parent,
            name, 1.0, scale, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
        ops.push(#{SetTranslate: #{edit_target: edit_target, path: path,
            value: translation}});
        if rotation != () {
            ops.push(#{SetRotate: #{edit_target: edit_target, path: path,
                value: rotation}});
        }
    } else {
        if existing.type_name != "Cube" {
            return plan_error(path + ": expected Cube, got " + existing.type_name);
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            translation, rotation, scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "primvars:displayColor", type_name: "color3f[]",
        value: _color_literal(color)}});
    #{ok: true, path: path, ops: ops}
}

fn _component_cylinder_visual_ops(doc, edit_target, parent, name,
    translation, rotation, radius, height, axis, color) {
    let path = parent + "/" + name;
    let existing = assembly_builder::composed_query(doc,
        #{path: path, children: false, attrs: ["radius", "height"]});
    let exists = query_ok(existing);
    let ops = [];
    // The existing landing-leg source uses float radius/height attributes for
    // ShockPiston and FootPad, while MountAxle is double. QueryUsdPrim exposes
    // values but the current property catalog may report the UsdGeom default
    // double rather than the authored scalar type. Keep this explicit named
    // mapping typed and fail closed for any future unregistered cylinder.
    let scalar_type = "double";
    if exists {
        if name == "ShockPiston" || name == "FootPad" {
            scalar_type = "float";
        } else if name == "HingeCollarPort" || name == "HingeCollarStarboard" {
            // The legacy ramp component declares its collar scalar fields as
            // float.  Preserve that authored schema when refining the
            // composed child; a typed USD edit must not promote it by name.
            scalar_type = "float";
        } else if name == "MountAxle" || name == "HingeBar" {
            scalar_type = "double";
        } else if name != "StrutOuter" && name != "StrutInner" {
            return plan_error(path + ": existing cylinder scalar type is not registered in the component schema map");
        }
    }
    let retype_study_strut = exists && existing.type_name == "Cube"
        && (name == "StrutOuter" || name == "StrutInner");
    if exists && existing.type_name != "Cylinder" && !retype_study_strut {
        return plan_error(path + ": expected Cylinder, got " + existing.type_name);
    }
    if !exists || retype_study_strut {
        // AddPrim is a typed DefinePrim operation; reusing this exact child
        // path changes the schema owner from Cube to Cylinder in the component
        // document. Unit scale clears the old slab proportions while the
        // native cylinder radius/height carry the SysML dimensions.
        let shape = assembly_builder::cylinder_shape_plan_axis(edit_target,
            parent, name, radius, height, translation, rotation,
            if retype_study_strut { [1.0, 1.0, 1.0] } else { () }, axis, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
        if retype_study_strut {
            ops.push(#{RemoveAttribute: #{edit_target: edit_target, path: path,
                name: "size"}});
        }
    } else {
        let placement = assembly_builder::place_plan(edit_target, path,
            translation, rotation, ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    let scalar_ops = [
        #{name: "radius", type_name: scalar_type, value: radius.to_string()},
        #{name: "height", type_name: scalar_type, value: height.to_string()},
    ];
    for item in scalar_ops + [
        #{name: "axis", type_name: "token", value: "\"" + axis + "\""},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"},
        #{name: "primvars:displayColor", type_name: "color3f[]",
          value: _color_literal(color)},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    #{ok: true, path: path, ops: ops}
}

fn _leg_number(source, name) {
    if source == () || source.ok != true { return (); }
    sysml_requirements::number(source,
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::" + name)
}

fn _leg_usd_axis(direction) {
    if !vec3_is_native(direction) { return (); }
    if direction.x == 1.0 && direction.y == 0.0 && direction.z == 0.0 { return "X"; }
    if direction.x == 0.0 && direction.y == 1.0 && direction.z == 0.0 { return "Y"; }
    if direction.x == 0.0 && direction.y == 0.0 && direction.z == 1.0 { return "Z"; }
    ()
}

// Refine the reusable landing-leg component in its own document.  The
// previous square struts read as broad slabs. Keep the canted members round,
// and keep their radius, axis, positions and angles owned by the landing-leg
// SysML package. No supplier section ICD is implied by this visual study.
fn refine_griffin_landing_leg_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_landing_leg_component_plan requires a document, edit target, and absolute root");
    }
    let component = _component_query(doc, root);
    if !component.ok || component.type_name != "Xform" {
        return plan_error(root + ": landing-leg component root is missing or not Xform");
    }
    let source = sysml_requirements::source();
    let strut_radius = _leg_number(source, "strutRadiusM");
    let strut_height = _leg_number(source, "strutHeightM");
    let strut_axis = _leg_usd_axis(sysml_requirements::native_value(source,
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::strutAxis"));
    let outer_x = _leg_number(source, "strutOuterCenterXM");
    let inner_x = _leg_number(source, "strutInnerCenterXM");
    let strut_y = _leg_number(source, "strutCenterYM");
    let outer_tilt = _leg_number(source, "strutOuterTiltZDeg");
    let inner_tilt = _leg_number(source, "strutInnerTiltZDeg");
    let piston_radius = _leg_number(source, "shockPistonRadiusM");
    let piston_height = _leg_number(source, "shockPistonHeightM");
    let piston_y = _leg_number(source, "shockPistonCenterYM");
    let pad_radius = _leg_number(source, "footPadRadiusM");
    let pad_height = _leg_number(source, "footPadHeightM");
    let pad_y = _leg_number(source, "footPadCenterYM");
    let clevis_width = _leg_number(source, "mountClevisWidthM");
    let clevis_height = _leg_number(source, "mountClevisHeightM");
    let clevis_depth = _leg_number(source, "mountClevisDepthM");
    let clevis_y = _leg_number(source, "mountClevisCenterYM");
    let plate_width = _leg_number(source, "footPadPlateWidthM");
    let plate_height = _leg_number(source, "footPadPlateHeightM");
    let plate_depth = _leg_number(source, "footPadPlateDepthM");
    let plate_y = _leg_number(source, "footPadPlateCenterYM");
    let overlap = _leg_number(source, "bodyMountOverlapM");
    let visual = "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::";
    let body_dimensions = sysml_requirements::native_value(source, visual + "bodyDimensions");
    let frame_section = sysml_requirements::number(source, visual + "frameRingSectionM");
    let leg_stations = sysml_requirement_checks::source_position_list(source, visual + "legStations");
    let missing_strut = strut_radius == () || strut_height == ()
        || strut_axis == () || outer_x == () || inner_x == ()
        || strut_y == () || outer_tilt == () || inner_tilt == ();
    let missing_shock = piston_radius == () || piston_height == ()
        || piston_y == () || pad_radius == () || pad_height == ()
        || pad_y == ();
    let missing_mount = clevis_width == () || clevis_height == ()
        || clevis_depth == () || clevis_y == () || plate_width == ()
        || plate_height == () || plate_depth == () || plate_y == ()
        || overlap == () || body_dimensions == () || frame_section == ();
    let invalid_mount_source = body_dimensions != ()
        && !vec3_is_native(body_dimensions);
    if missing_strut || missing_shock || missing_mount || invalid_mount_source
        || leg_stations.len() != 4 || (overlap != () && overlap <= 0.0) {
        return plan_error("landing-leg SysML geometry datums are incomplete");
    }
    let radial_station = (leg_stations[0].x * leg_stations[0].x
        + leg_stations[0].z * leg_stations[0].z).sqrt();
    let bus_inner_edge = body_dimensions.x / 2.0 - frame_section / 2.0 - overlap;
    let axle_inner_edge = radial_station - clevis_height / 2.0;
    let arm_outer_edge = axle_inner_edge + overlap;
    let arm_length = arm_outer_edge - bus_inner_edge;
    let arm_center_x = (bus_inner_edge + arm_outer_edge) / 2.0 - radial_station;
    if radial_station <= 0.0 || arm_length <= 0.0 {
        return plan_error("landing-leg mount does not span the bus frame to the clevis axle");
    }
    let ops = [];
    for item in [
        #{name: "MountClevisOuter", translation: [outer_x, clevis_y, 0.0],
          rotation: (), scale: [clevis_width, clevis_height, clevis_depth],
          color: [0.18, 0.21, 0.25]},
        #{name: "MountClevisInner", translation: [inner_x, clevis_y, 0.0],
          rotation: (), scale: [clevis_width, clevis_height, clevis_depth],
          color: [0.18, 0.21, 0.25]},
        #{name: "FootPadPlate", translation: [0.0, plate_y, 0.0],
          rotation: (), scale: [plate_width, plate_height, plate_depth],
          color: [0.20, 0.23, 0.27]},
        #{name: "BodyMountArm", translation: [arm_center_x, clevis_y, 0.0],
          rotation: (), scale: [arm_length, clevis_height, clevis_width],
          color: [0.28, 0.32, 0.38]},
    ] {
        let part = _component_cube_visual_ops(doc, edit_target, root,
            item.name, item.translation, item.rotation, item.scale, item.color);
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
    }
    for item in [
        #{name: "StrutOuter", translation: [outer_x, strut_y, 0.0],
          rotation: [0.0, 0.0, outer_tilt], radius: strut_radius,
          height: strut_height, axis: strut_axis, color: [0.08, 0.10, 0.13]},
        #{name: "StrutInner", translation: [inner_x, strut_y, 0.0],
          rotation: [0.0, 0.0, inner_tilt], radius: strut_radius,
          height: strut_height, axis: strut_axis, color: [0.08, 0.10, 0.13]},
        #{name: "ShockPiston", translation: [0.0, piston_y, 0.0],
          rotation: (), radius: piston_radius, height: piston_height,
          axis: "Y", color: [0.72, 0.75, 0.80]},
        #{name: "FootPad", translation: [0.0, pad_y, 0.0],
          rotation: (), radius: pad_radius, height: pad_height,
          axis: "Y", color: [0.28, 0.32, 0.38]},
        #{name: "MountAxle", translation: [0.0, clevis_y, 0.0],
          rotation: (), radius: clevis_height / 2.0, height: clevis_width,
          axis: "Z", color: [0.48, 0.52, 0.58]},
    ] {
        let part = _component_cylinder_visual_ops(doc, edit_target, root,
            item.name, item.translation, item.rotation, item.radius,
            item.height, item.axis, item.color);
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
    }
    let root_record = assembly_builder::composed_query(doc, #{path: root,
        attrs: ["lunco:visual:component", "lunco:visual:requirement",
            "lunco:visual:configuration"], children: false});
    if query_ok(root_record) && root_record.attrs != () {
        for name in ["lunco:visual:component", "lunco:visual:requirement",
            "lunco:visual:configuration"] {
            if root_record.attrs[name] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: root, name: name}});
            }
        }
    }
    #{ok: true, kind: "griffin_landing_leg_component_refinement",
      root: root, paths: [root + "/StrutOuter", root + "/StrutInner",
        root + "/ShockPiston", root + "/FootPad", root + "/MountClevisOuter",
        root + "/MountClevisInner", root + "/MountAxle", root + "/FootPadPlate",
        root + "/BodyMountArm"],
      ops: ops, no_op: ops.len() == 0}
}

fn apply_refined_griffin_landing_leg(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_landing_leg_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Refine Griffin landing-leg component", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

// A narrow refinement entry point for the reviewable change to the leg's two
// load struts.  Unlike the full component normalization above, this emits no
// operations for the clevis, piston, pad, or plate.  Identity still comes
// from the SysML enum collection; its literal is converted to a USD child
// path only at this addressing boundary.
fn refine_griffin_landing_leg_struts_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_landing_leg_struts_plan requires a document, edit target, and absolute root");
    }
    let component = _component_query(doc, root);
    if !component.ok || component.type_name != "Xform" {
        return plan_error(root + ": landing-leg component root is missing or not Xform");
    }
    let source = sysml_requirements::source();
    if source == () || source.ok != true {
        return plan_error("landing-leg SysML source is unavailable");
    }
    let child_names = sysml_requirements::native_value(source,
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::childNames");
    if !array_is(child_names) {
        return plan_error("landing-leg child identity collection is not a typed enum array");
    }
    let outer_name = ();
    let inner_name = ();
    for child in child_names {
        if !sysml_enum_is(child) { continue; }
        if child.literal == "StrutOuter" { outer_name = child.literal; }
        if child.literal == "StrutInner" { inner_name = child.literal; }
    }
    if outer_name == () || inner_name == () {
        return plan_error("typed landing-leg child identities omit one of the two struts");
    }
    let radius = _leg_number(source, "strutRadiusM");
    let height = _leg_number(source, "strutHeightM");
    let axis = _leg_usd_axis(sysml_requirements::native_value(source,
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::strutAxis"));
    let outer_x = _leg_number(source, "strutOuterCenterXM");
    let inner_x = _leg_number(source, "strutInnerCenterXM");
    let center_y = _leg_number(source, "strutCenterYM");
    let outer_tilt = _leg_number(source, "strutOuterTiltZDeg");
    let inner_tilt = _leg_number(source, "strutInnerTiltZDeg");
    if radius == () || radius <= 0.0 || height == () || height <= 0.0
        || axis == () || outer_x == () || inner_x == () || center_y == ()
        || outer_tilt == () || inner_tilt == () {
        return plan_error("landing-leg strut dimensions, axis, or stations are incomplete");
    }

    let specs = [
        #{name: outer_name, translation: [outer_x, center_y, 0.0],
          rotation: [0.0, 0.0, outer_tilt], color: [0.08, 0.10, 0.13]},
        #{name: inner_name, translation: [inner_x, center_y, 0.0],
          rotation: [0.0, 0.0, inner_tilt], color: [0.08, 0.10, 0.13]},
    ];
    let ops = [];
    let changed_paths = [];
    for item in specs {
        let path = root + "/" + item.name;
        let record = assembly_builder::composed_query(doc,
            #{path: path, children: false,
              attrs: ["radius", "height", "axis", "size",
                "xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale",
                "physics:collisionEnabled", "purpose", "primvars:displayColor"]});
        if !query_ok(record) {
            return plan_error(path + ": composed strut query failed");
        }
        let attrs = record.attrs;
        let color = attrs["primvars:displayColor"];
        let color_matches = array_is(color) && color.len() == 1
            && assembly_audit::close_vec(color[0], item.color, 0.001);
        let matches = record.type_name == "Cylinder"
            && assembly_audit::close_scalar(attrs["radius"], radius, 0.000001)
            && assembly_audit::close_scalar(attrs["height"], height, 0.000001)
            && attrs["axis"] == axis && attrs["size"] == ()
            && assembly_audit::close_vec(attrs["xformOp:translate"], item.translation, 0.000001)
            && assembly_audit::close_vec(attrs["xformOp:rotateXYZ"], item.rotation, 0.000001)
            && assembly_audit::close_vec(attrs["xformOp:scale"], [1.0, 1.0, 1.0], 0.000001)
            && attrs["physics:collisionEnabled"] == false
            && attrs["purpose"] == "render" && color_matches;
        if !matches {
            let part = _component_cylinder_visual_ops(doc, edit_target, root,
                item.name, item.translation, item.rotation, radius, height,
                axis, item.color);
            if !part.ok { return part; }
            for op in part.ops { ops.push(op); }
            changed_paths.push(path);
        }
    }
    #{ok: true, kind: "griffin_landing_leg_strut_refinement", root: root,
      paths: changed_paths, ops: ops, no_op: ops.is_empty()}
}

fn apply_refined_griffin_landing_leg_struts(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_landing_leg_struts_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Refine Griffin landing-leg tubular struts", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

fn _solar_number(name) {
    griffin_spec::solar_component_number(name)
}

fn _component_mesh_visual_ops(doc, edit_target, parent, name, geometry, color) {
    if geometry == () || geometry.ok != true || geometry.points == ()
        || geometry.face_counts == () || geometry.face_indices == () {
        return plan_error("component mesh geometry is incomplete");
    }
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let ops = [];
    if query_ok(current) && current.type_name != "Mesh" {
        ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
        let shape = assembly_builder::mesh_shape_plan(edit_target, parent, name,
            geometry.points, geometry.face_counts, geometry.face_indices, color, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    } else if query_ok(current) {
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        let shape = assembly_builder::mesh_shape_plan(edit_target, parent, name,
            geometry.points, geometry.face_counts, geometry.face_indices, color, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    for item in [
        #{name: "points", type_name: "point3f[]", value: _mesh_points_literal(geometry.points)},
        #{name: "faceVertexCounts", type_name: "int[]", value: _mesh_ints_literal(geometry.face_counts)},
        #{name: "faceVertexIndices", type_name: "int[]", value: _mesh_ints_literal(geometry.face_indices)},
        #{name: "subdivisionScheme", type_name: "token", value: "\"none\""},
        #{name: "doubleSided", type_name: "bool", value: "false"},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"},
        #{name: "primvars:displayColor", type_name: "color3f[]", value: _color_literal(color)}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: path, value: [0.0, 0.0, 0.0]}});
    #{ok: true, path: path, ops: ops}
}

fn _solar_frame_plan(doc, edit_target, root, width, depth, section,
    clearance_center_x, clearance_width, clearance_depth, color) {
    let offset_x = width / 2.0 - section / 2.0;
    let offset_z = depth / 2.0 - section / 2.0;
    let notch_left_x = clearance_center_x - clearance_width / 2.0;
    let notch_right_x = clearance_center_x + clearance_width / 2.0;
    let notch_start_z = depth / 2.0 - clearance_depth;
    if clearance_width <= section || notch_left_x <= -offset_x
        || notch_right_x >= offset_x
        || clearance_depth <= section || clearance_depth >= depth - section {
        return plan_error("solar-panel lower clearance cutout does not fit within the source-owned frame envelope");
    }
    let stations = [
        vec3(-offset_x, 0.0, -offset_z),
        vec3(offset_x, 0.0, -offset_z),
        vec3(offset_x, 0.0, offset_z),
        vec3(notch_right_x, 0.0, offset_z),
        vec3(notch_right_x, 0.0, notch_start_z),
        vec3(notch_left_x, 0.0, notch_start_z),
        vec3(notch_left_x, 0.0, offset_z),
        vec3(-offset_x, 0.0, offset_z),
    ];
    let geometry = griffin_geometry::perimeter_beam_geometry(stations, [0.0], section);
    if geometry.ok != true { return plan_error(geometry.error); }
    _component_mesh_visual_ops(doc, edit_target, root, "Frame", geometry, color)
}

fn _solar_notched_surface_geometry(width, thickness, depth, center_y,
    clearance_center_x, clearance_width, clearance_depth) {
    if width <= 0.0 || thickness <= 0.0 || depth <= 0.0
        || clearance_width <= 0.0
        || clearance_center_x - clearance_width / 2.0 <= -width / 2.0
        || clearance_center_x + clearance_width / 2.0 >= width / 2.0
        || clearance_depth <= 0.0 || clearance_depth >= depth {
        return #{ok: false, error: "solar-panel surface clearance cutout must fit inside a positive panel envelope"};
    }
    let z_min = -depth / 2.0;
    let z_max = depth / 2.0;
    let notch_start_z = z_max - clearance_depth;
    let upper_depth = notch_start_z - z_min;
    let wing_depth = clearance_depth;
    let notch_left_x = clearance_center_x - clearance_width / 2.0;
    let notch_right_x = clearance_center_x + clearance_width / 2.0;
    let left_wing_width = notch_left_x + width / 2.0;
    let right_wing_width = width / 2.0 - notch_right_x;
    if upper_depth <= 0.0 || left_wing_width <= 0.0 || right_wing_width <= 0.0 {
        return #{ok: false, error: "solar-panel surface cutout leaves no connected cell or backplane material"};
    }
    let upper = griffin_geometry::rectangular_prism_geometry(
        vec3(0.0, center_y, (z_min + notch_start_z) / 2.0),
        vec3(width, thickness, upper_depth));
    let left = griffin_geometry::rectangular_prism_geometry(
        vec3((-width / 2.0 + notch_left_x) / 2.0, center_y,
            (notch_start_z + z_max) / 2.0),
        vec3(left_wing_width, thickness, wing_depth));
    let right = griffin_geometry::rectangular_prism_geometry(
        vec3((notch_right_x + width / 2.0) / 2.0, center_y,
            (notch_start_z + z_max) / 2.0),
        vec3(right_wing_width, thickness, wing_depth));
    if upper.ok != true || left.ok != true || right.ok != true {
        return #{ok: false, error: "solar-panel clearance surface mesh could not be generated"};
    }
    griffin_geometry::merge_mesh_geometries([upper, left, right])
}

// Refine the reusable solar-array component in its own document.  The
// outward-facing root rotation is owned by GriffinLanderComponent; this
// operation owns only the panel's local frame, blue cell face, grid members,
// and bracket geometry.
fn refine_griffin_solar_panel_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_solar_panel_component_plan requires a document, edit target, and absolute root");
    }
    let component = _component_query(doc, root);
    if !component.ok || component.type_name != "Xform" {
        return plan_error(root + ": solar-panel component root is missing or not Xform");
    }
    let frame_width = _solar_number("frameWidthM");
    let frame_thickness = _solar_number("frameThicknessM");
    let frame_depth = _solar_number("frameDepthM");
    let clearance_center_x_fraction = _solar_number("lowerClearanceCenterXFraction");
    let clearance_width_fraction = _solar_number("lowerClearanceWidthFraction");
    let clearance_depth_fraction = _solar_number("lowerClearanceDepthFraction");
    let cell_width = _solar_number("cellWidthM");
    let cell_thickness = _solar_number("cellThicknessM");
    let cell_depth = _solar_number("cellDepthM");
    let cell_offset = _solar_number("cellOffsetYM");
    let backplane_thickness = _solar_number("arrayBackplaneThicknessM");
    let backplane_center = _solar_number("arrayBackplaneCenterYM");
    let columns_value = _solar_number("gridColumnCount");
    let rows_value = _solar_number("gridRowCount");
    let columns = if columns_value == () { 0 } else { columns_value.to_int() };
    let rows = if rows_value == () { 0 } else { rows_value.to_int() };
    let divider_width = _solar_number("dividerXWidthM");
    let divider_x_thickness = _solar_number("dividerXThicknessM");
    let divider_span = _solar_number("dividerZWidthM");
    let divider_z_thickness = _solar_number("dividerZThicknessM");
    let bracket_width = _solar_number("mountBracketWidthM");
    let bracket_thickness = _solar_number("mountBracketThicknessM");
    let bracket_depth = _solar_number("mountBracketDepthM");
    let hinge_radius = _solar_number("hingeBarRadiusM");
    let hinge_length = _solar_number("hingeBarLengthM");
    let hinge_y = _solar_number("hingeBarCenterYM");
    let hinge_z = _solar_number("hingeBarCenterZM");
    let link_height = _solar_number("mountLinkHeightM");
    let link_depth = _solar_number("mountLinkDepthM");
    let link_y = _solar_number("mountLinkCenterYM");
    let link_z = _solar_number("mountLinkCenterZM");
    let frame_rail_names = griffin_spec::visual_rail_names();
    let frame_rail_stations = griffin_spec::visual_rail_station_positions();
    let solar_stations = griffin_spec::component_solar_stations();
    let solar_rotations_x = griffin_spec::component_solar_station_rotation_x_deg();
    let solar_rotations_z = griffin_spec::component_solar_station_rotation_z_deg();
    let mount_rail_names = griffin_spec::solar_mount_rail_names();
    let solar_count = griffin_spec::solar_array_count();
    let solar_widths = griffin_spec::component_solar_array_widths_m();
    let bus_mount = griffin_spec::component_bus_mount();
    if frame_width == () || frame_thickness == () || frame_depth == ()
        || clearance_center_x_fraction == () || clearance_width_fraction == ()
        || clearance_depth_fraction == () || clearance_center_x_fraction <= -0.5
        || clearance_center_x_fraction >= 0.5
        || clearance_width_fraction <= 0.0 || clearance_width_fraction >= 1.0
        || clearance_depth_fraction <= 0.0 || clearance_depth_fraction >= 1.0
        || cell_width == () || cell_thickness == () || cell_depth == ()
        || cell_offset == () || backplane_thickness == () || backplane_center == () {
        return plan_error("solar-panel SysML geometry datums are incomplete");
    }
    if columns < 2 || rows < 2 {
        return plan_error("solar-panel grid must have at least two columns and rows");
    }
    if divider_width == () || divider_x_thickness == () || divider_span == ()
        || divider_z_thickness == ()
        || bracket_width == () || bracket_thickness == () || bracket_depth == () {
        return plan_error("solar-panel divider or bracket datums are incomplete");
    }
    if hinge_radius == () || hinge_length == () || hinge_y == () || hinge_z == ()
        || link_height == () || link_depth == () || link_y == () || link_z == ()
        || solar_count <= 0 || solar_stations.len() != solar_count
        || solar_rotations_x.len() != solar_count || solar_rotations_z.len() != solar_count
        || solar_widths.len() != solar_count || mount_rail_names.len() != solar_count * 2
        || frame_rail_names.len() != frame_rail_stations.len()
        || bus_mount == () || !vec3_is_native(bus_mount) {
        return plan_error("solar-panel installation requires one typed station, orientation, and bus-rail pair per canonical array");
    }
    let ops = [];
    let clearance_center_x = frame_width * clearance_center_x_fraction;
    let clearance_width = frame_width * clearance_width_fraction;
    let clearance_depth = frame_depth * clearance_depth_fraction;
    if clearance_width >= cell_width || clearance_depth >= cell_depth {
        return plan_error("solar-panel lower clearance cutout exceeds the typed cell field");
    }
    let frame = _solar_frame_plan(doc, edit_target, root,
        frame_width, frame_depth, frame_thickness, clearance_center_x, clearance_width,
        clearance_depth, [0.44, 0.48, 0.55]);
    if !frame.ok { return frame; }
    for op in frame.ops { ops.push(op); }
    let surface_specs = [
        #{name: "ArrayBackplane", center_y: backplane_center,
          thickness: backplane_thickness, color: [0.015, 0.035, 0.12]},
        #{name: "Cells", center_y: cell_offset,
          thickness: cell_thickness, color: [0.025, 0.12, 0.48]},
    ];
    for item in surface_specs {
        let geometry = _solar_notched_surface_geometry(cell_width,
            item.thickness, cell_depth, item.center_y,
            clearance_center_x, clearance_width, clearance_depth);
        if geometry.ok != true { return plan_error(geometry.error); }
        let part = _component_mesh_visual_ops(doc, edit_target, root,
            item.name, geometry, item.color);
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
    }
    let divider_y = cell_offset + cell_thickness / 2.0;
    let notch_start_z = cell_depth / 2.0 - clearance_depth;
    for index in 1..columns {
        let name = "CellDividerX" + index.to_string();
        let x = -cell_width / 2.0 + cell_width * index / columns;
        let inside_clearance = x >= clearance_center_x - clearance_width / 2.0
            && x <= clearance_center_x + clearance_width / 2.0;
        let divider_depth = if inside_clearance { cell_depth - clearance_depth } else { cell_depth };
        let divider_center_z = if inside_clearance { -clearance_depth / 2.0 } else { 0.0 };
        let divider = _component_cube_visual_ops(doc, edit_target, root, name,
            [x, divider_y, divider_center_z], (),
            [divider_width, divider_x_thickness, divider_depth],
            [0.72, 0.78, 0.88]);
        if !divider.ok { return divider; }
        for op in divider.ops { ops.push(op); }
    }
    for index in 1..rows {
        let name = "CellDividerZ" + index.to_string();
        let z = -cell_depth / 2.0 + cell_depth * index / rows;
        let divider = if z > notch_start_z {
            let notch_left_x = clearance_center_x - clearance_width / 2.0;
            let notch_right_x = clearance_center_x + clearance_width / 2.0;
            let left_width = notch_left_x + cell_width / 2.0;
            let right_width = cell_width / 2.0 - notch_right_x;
            let left = griffin_geometry::rectangular_prism_geometry(
                vec3((-cell_width / 2.0 + notch_left_x) / 2.0, divider_y, z),
                vec3(left_width, divider_z_thickness, divider_span));
            let right = griffin_geometry::rectangular_prism_geometry(
                vec3((notch_right_x + cell_width / 2.0) / 2.0, divider_y, z),
                vec3(right_width, divider_z_thickness, divider_span));
            let geometry = griffin_geometry::merge_mesh_geometries([left, right]);
            _component_mesh_visual_ops(doc, edit_target, root, name,
                geometry, [0.72, 0.78, 0.88])
        } else {
            _component_cube_visual_ops(doc, edit_target, root, name,
                [0.0, divider_y, z], (),
                [cell_width, divider_z_thickness, divider_span],
                [0.72, 0.78, 0.88])
        };
        if !divider.ok { return divider; }
        for op in divider.ops { ops.push(op); }
    }
    for name in ["CellDividerX", "CellDividerXLeft", "CellDividerXRight",
        "CellDividerZ", "CellDividerZUpper", "CellDividerZLower"] {
        let path = root + "/" + name;
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) {
            ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
        }
    }
    let hinge = _component_cylinder_visual_ops(doc, edit_target, root,
        "HingeBar", [0.0, hinge_y, hinge_z], (), hinge_radius,
        hinge_length, "X", [0.16, 0.19, 0.24]);
    if !hinge.ok { return hinge; }
    for op in hinge.ops { ops.push(op); }
    let mount_names = ["NegativeX", "PositiveX"];
    let half_frame_width = frame_width / 2.0;
    let minimum_overlap = _solar_number("minimumMountOverlapM");
    if minimum_overlap == () || minimum_overlap <= 0.0 {
        return plan_error("solar-panel minimum mount overlap is missing from SysML");
    }
    let bracket_center_y_values = [];
    let bracket_center_z_values = [];
    for array_index in 0..solar_count {
        if (solar_rotations_x[array_index] - 90.0).abs() > 0.001 {
            return plan_error("all upright Griffin panel faces use the shared +90 degree X orientation");
        }
        let alpha = solar_rotations_z[array_index] * griffin_spec::pi_value() / 180.0;
        let c = cos(alpha);
        let s = sin(alpha);
        let pair_local = [];
        for endpoint in 0..2 {
            let rail_name = mount_rail_names[array_index * 2 + endpoint];
            let rail_station = ();
            for rail_index in 0..frame_rail_names.len() {
                if frame_rail_names[rail_index] == rail_name {
                    rail_station = frame_rail_stations[rail_index];
                    break;
                }
            }
            if rail_station == () {
                return plan_error("solar installation references an unknown bus rail station");
            }
            let dx = rail_station.x + bus_mount.x - solar_stations[array_index].x;
            let dy = rail_station.y + bus_mount.y - solar_stations[array_index].y;
            let dz = rail_station.z + bus_mount.z - solar_stations[array_index].z;
            let local = vec3(c * dx + s * dz, -s * dx + c * dz, -dy);
            pair_local.push(local);
        }
        if pair_local[0].x >= 0.0 || pair_local[1].x <= 0.0
            || (pair_local[0].y - pair_local[1].y).abs() > minimum_overlap
            || pair_local[0].z.abs() > minimum_overlap
            || pair_local[1].z.abs() > minimum_overlap {
            return plan_error("each adjacent-face panel must map its negative and positive local X mounts to coplanar bus rails");
        }
        bracket_center_y_values.push((pair_local[0].y + pair_local[1].y) / 2.0);
        bracket_center_z_values.push((pair_local[0].z + pair_local[1].z) / 2.0);
    }
    let bracket_center_y = bracket_center_y_values[0];
    let bracket_center_z = bracket_center_z_values[0];
    for index in 1..solar_count {
        if (bracket_center_y_values[index] - bracket_center_y).abs() > minimum_overlap
            || (bracket_center_z_values[index] - bracket_center_z).abs() > minimum_overlap {
            return plan_error("adjacent solar panel mount rails do not share the reusable component attachment plane");
        }
    }
    for index in 0..mount_names.len() {
        let side = mount_names[index];
        let sign = if index == 0 { -1.0 } else { 1.0 };
        let bracket_x = sign * half_frame_width;
        let bracket = _component_cube_visual_ops(doc, edit_target, root,
            "MountBracket" + side, [bracket_x, bracket_center_y, bracket_center_z], (),
            [bracket_width, bracket_thickness, bracket_depth],
            [0.12, 0.15, 0.20]);
        if !bracket.ok { return bracket; }
        for op in bracket.ops { ops.push(op); }
        let link = _component_cube_visual_ops(doc, edit_target, root,
            "MountLink" + side, [bracket_x, link_y, link_z], (),
            [bracket_width, link_height, link_depth],
            [0.10, 0.13, 0.18]);
        if !link.ok { return link; }
        for op in link.ops { ops.push(op); }
    }
    let root_record = assembly_builder::composed_query(doc, #{path: root,
        attrs: ["lunco:visual:component", "lunco:visual:requirement",
            "lunco:visual:cell_face_normal"], children: false});
    if query_ok(root_record) && root_record.attrs != () {
        for name in ["lunco:visual:component", "lunco:visual:requirement",
            "lunco:visual:cell_face_normal"] {
            if root_record.attrs[name] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: root, name: name}});
            }
        }
    }
    let paths = [root + "/Frame", root + "/ArrayBackplane", root + "/Cells"];
    for index in 1..columns { paths.push(root + "/CellDividerX" + index.to_string()); }
    for index in 1..rows { paths.push(root + "/CellDividerZ" + index.to_string()); }
    paths.push(root + "/HingeBar");
    for side in ["NegativeX", "PositiveX"] {
        paths.push(root + "/MountBracket" + side);
        paths.push(root + "/MountLink" + side);
    }
    #{ok: true, kind: "griffin_solar_panel_component_refinement",
      root: root, paths: paths,
      ops: ops, no_op: ops.len() == 0}
}

fn apply_refined_griffin_solar_panel(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_solar_panel_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Refine Griffin solar-panel component", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

// Refine the reusable propellant-tank visual in its own document.  USD
// geometry dimensions stay double all the way to the schema boundary.  The
// only lower-precision value authored here is the required renderer extent.
fn _tank_extent_literal(radius, height) {
    let half_height = height / 2.0;
    "[(-" + radius.to_string() + ", -" + half_height.to_string()
        + ", -" + radius.to_string() + "), (" + radius.to_string()
        + ", " + half_height.to_string() + ", " + radius.to_string() + ")]"
}

fn _tank_enum_name(source, name) {
    let value = sysml_requirements::native_value(source,
        "GriffinTankRequirements::GriffinPropellantTankAssembly::" + name);
    if sysml_enum_is(value) { value.literal } else { () }
}

fn _tank_enum_names(source, name) {
    let values = sysml_requirements::native_value(source,
        "GriffinTankRequirements::GriffinPropellantTankAssembly::" + name);
    let result = [];
    if values == () || !array_is(values) { return result; }
    for value in values {
        if !sysml_enum_is(value) { return []; }
        result.push(value.literal);
    }
    result
}

fn _tank_cylinder_schema_ops(edit_target, parent, name, radius, height,
    translation, axis, color, add) {
    let path = parent + "/" + name;
    let ops = [];
    if add {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: parent,
            name: name, type_name: "Cylinder", reference: (),
            reference_prim_path: ""}});
    }
    let placement = assembly_builder::place_plan(edit_target, path,
        translation, (), ());
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
    for item in [
        #{name: "radius", type_name: "double", value: radius.to_string()},
        #{name: "height", type_name: "double", value: height.to_string()},
        #{name: "axis", type_name: "token", value: "\"" + axis + "\""},
        #{name: "extent", type_name: "float3[]", value: _tank_extent_literal(radius, height)},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"},
        #{name: "primvars:displayColor", type_name: "color3f[]",
          value: "[(" + color[0].to_string() + ", " + color[1].to_string()
              + ", " + color[2].to_string() + ")]"},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    #{ok: true, path: path, ops: ops}
}

fn _tank_sphere_schema_ops(edit_target, parent, name, radius,
    translation, color, add) {
    let path = parent + "/" + name;
    let ops = [];
    if add {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: parent,
            name: name, type_name: "Sphere", reference: (),
            reference_prim_path: ""}});
    }
    let placement = assembly_builder::place_plan(edit_target, path,
        translation, (), ());
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
    for item in [
        #{name: "radius", type_name: "double", value: radius.to_string()},
        #{name: "extent", type_name: "float3[]",
          value: _tank_extent_literal(radius, 2.0 * radius)},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"},
        #{name: "primvars:displayColor", type_name: "color3f[]",
          value: "[(" + color[0].to_string() + ", " + color[1].to_string()
              + ", " + color[2].to_string() + ")]"},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    #{ok: true, path: path, ops: ops}
}

fn _tank_cone_schema_ops(edit_target, parent, name, radius1, radius2,
    height, translation, axis, color, add) {
    let path = parent + "/" + name;
    let ops = [];
    if add {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: parent,
            name: name, type_name: "Cone", reference: (),
            reference_prim_path: ""}});
    }
    let placement = assembly_builder::place_plan(edit_target, path,
        translation, (), ());
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
    let extent_radius = if radius1 > radius2 { radius1 } else { radius2 };
    for item in [
        #{name: "radius1", type_name: "double", value: radius1.to_string()},
        #{name: "radius2", type_name: "double", value: radius2.to_string()},
        #{name: "radius", type_name: "double", value: radius1.to_string()},
        #{name: "height", type_name: "double", value: height.to_string()},
        #{name: "axis", type_name: "token", value: "\"" + axis + "\""},
        #{name: "extent", type_name: "float3[]",
          value: _tank_extent_literal(extent_radius, height)},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "primvars:displayColor", type_name: "color3f[]",
          value: "[(" + color[0].to_string() + ", " + color[1].to_string()
              + ", " + color[2].to_string() + ")]"},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    #{ok: true, path: path, ops: ops}
}

fn _tank_schema_prim_ready(doc, path, type_name) {
    let inspection = assembly_edit::inspect(doc, path);
    if inspection == () || inspection.prim == () || inspection.prim.exists != true
        || inspection.prim.type != type_name {
        return false;
    }
    let required = if type_name == "Sphere" {
        ["radius", "extent"]
    } else if type_name == "Cone" {
        ["radius1", "radius2", "height", "extent"]
    } else {
        ["radius", "height", "extent"]
    };
    for field in required {
        let found = false;
        for attr in inspection.prim.attributes {
            if attr.name.ends_with("." + field) {
                if field == "extent" && attr.type != "float3[]"
                    || field != "extent" && attr.type != "double" {
                    return false;
                }
                found = true;
            }
        }
        if !found { return false; }
    }
    true
}

fn refine_griffin_tank_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_tank_component_plan requires a document, edit target, and absolute root");
    }
    let component = assembly_builder::composed_query(doc, #{path: root, children: false});
    if !query_ok(component) || component.type_name != "Xform" {
        return plan_error(root + ": propellant tank component root is missing or not Xform");
    }
    let tank = "GriffinTankRequirements::GriffinPropellantTankAssembly::";
    let visual = "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::";
    let source = sysml_requirements::source_with_attributes([
        tank + "bodyName", tank + "bodyShape", tank + "bodyCenter", tank + "bodyRadiusM",
        tank + "tankAxis", tank + "retentionBandNames", tank + "retentionBandShape",
        tank + "axialHardwareShape", tank + "transitionShape", tank + "endHardwareNames",
        tank + "serviceHardwareNames", tank + "axialHardwareNames", tank + "neckRadiusM",
        tank + "neckHeightM", tank + "shoulderCollarRadiusM", tank + "shoulderCollarHeightM",
        tank + "valveRadiusM", tank + "valveHeightM", tank + "valveCapRadiusM",
        tank + "valveCapHeightM", tank + "transitionShoulderRadiusM",
        tank + "transitionNeckRadiusM", tank + "transitionHeightM", tank + "transitionRadiusM",
        tank + "shoulderCenterYM", tank + "transitionCenterYM", tank + "neckCenterYM",
        tank + "valveCenterYM", tank + "capCenterYM", tank + "bandHeightM",
        tank + "bandCenterYM", tank + "bandRadiusByCenterM", tank + "cradleName",
        tank + "cradleShape", tank + "cradleRadiusM", tank + "cradleHeightM",
        tank + "minimumSkirtClearanceM", tank + "cradlePadName", tank + "cradlePadShape",
        tank + "cradlePadWidthM", tank + "cradlePadDepthM", tank + "cradlePadHeightM",
        tank + "supportName", tank + "supportShape", tank + "supportRadiusM",
        tank + "bracketGroupName", tank + "bracketNames", tank + "bracketShape",
        tank + "bracketLengthM", tank + "bracketWidthM", tank + "bracketDepthM",
        tank + "bracketCenterOffsetM", tank + "bracketTiltDeg",
        visual + "bodyMount", visual + "lowerSkirtCenter",
        visual + "lowerSkirtDimensions", visual + "tankStations", visual + "tankScale",
    ]);
    if source == () || source.ok != true {
        return plan_error("tank authoring requires the mounted, selected SysML source facts");
    }
    let body_name = _tank_enum_name(source, "bodyName");
    let body_shape = _tank_enum_name(source, "bodyShape");
    let body_center = sysml_requirements::native_value(source, tank + "bodyCenter");
    let radius = sysml_requirements::number(source, tank + "bodyRadiusM");
    let axis = _tank_enum_name(source, "tankAxis");
    let band_names = _tank_enum_names(source, "retentionBandNames");
    let band_shape = _tank_enum_name(source, "retentionBandShape");
    let axial_shape = _tank_enum_name(source, "axialHardwareShape");
    let transition_shape = _tank_enum_name(source, "transitionShape");
    let end_names = _tank_enum_names(source, "endHardwareNames");
    let service_names = _tank_enum_names(source, "serviceHardwareNames");
    let axial_names = _tank_enum_names(source, "axialHardwareNames");
    let neck_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::neckRadiusM");
    let neck_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::neckHeightM");
    let shoulder_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::shoulderCollarRadiusM");
    let shoulder_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::shoulderCollarHeightM");
    let valve_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::valveRadiusM");
    let valve_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::valveHeightM");
    let cap_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::valveCapRadiusM");
    let cap_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::valveCapHeightM");
    let transition_shoulder = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::transitionShoulderRadiusM");
    let transition_neck = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::transitionNeckRadiusM");
    let transition_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::transitionHeightM");
    let transition_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::transitionRadiusM");
    let shoulder_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::shoulderCenterYM");
    let transition_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::transitionCenterYM");
    let neck_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::neckCenterYM");
    let valve_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::valveCenterYM");
    let cap_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::capCenterYM");
    let band_height = sysml_requirements::number(source, tank + "bandHeightM");
    let band_centers = sysml_requirement_checks::source_number_list(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bandCenterYM");
    let band_radii = sysml_requirement_checks::source_number_list(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bandRadiusByCenterM");
    let cradle_name = _tank_enum_name(source, "cradleName");
    let cradle_shape = _tank_enum_name(source, "cradleShape");
    let cradle_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradleRadiusM");
    let cradle_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradleHeightM");
    let minimum_skirt_clearance = sysml_requirements::number(source, tank + "minimumSkirtClearanceM");
    let cradle_pad_name = _tank_enum_name(source, "cradlePadName");
    let cradle_pad_shape = _tank_enum_name(source, "cradlePadShape");
    let cradle_pad_width = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadWidthM");
    let cradle_pad_depth = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadDepthM");
    let cradle_pad_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadHeightM");
    let support_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportRadiusM");
    let support_name = _tank_enum_name(source, "supportName");
    let support_shape = _tank_enum_name(source, "supportShape");
    let body_mount = sysml_requirements::native_value(source, visual + "bodyMount");
    let skirt_center = sysml_requirements::native_value(source, visual + "lowerSkirtCenter");
    let skirt_dimensions = sysml_requirements::native_value(source, visual + "lowerSkirtDimensions");
    let tank_stations = sysml_requirement_checks::source_position_list(source, visual + "tankStations");
    let tank_scales = sysml_requirement_checks::source_number_list(source, visual + "tankScale");
    let bracket_length = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketLengthM");
    let bracket_width = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketWidthM");
    let bracket_depth = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketDepthM");
    let bracket_offset = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketCenterOffsetM");
    let bracket_group_name = _tank_enum_name(source, "bracketGroupName");
    let bracket_names = _tank_enum_names(source, "bracketNames");
    let bracket_shape = _tank_enum_name(source, "bracketShape");
    let bracket_tilt = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketTiltDeg");
    let missing_body = body_name == () || body_shape != "Sphere"
        || !vec3_is_native(body_center) || !vec3_is_finite(body_center)
        || radius == () || axis == () || band_names.len() != 3
        || band_shape != "Cylinder" || axial_shape != "Cylinder"
        || transition_shape != "Cone" || end_names.len() != 2
        || service_names.len() != 6 || axial_names.len() != 11;
    let missing_end = neck_radius == () || neck_height == ()
        || shoulder_radius == () || shoulder_height == ()
        || valve_radius == () || valve_height == ()
        || cap_radius == () || cap_height == ();
    let missing_transitions = transition_shoulder == () || transition_neck == ()
        || transition_height == () || transition_radius == ()
        || shoulder_y == () || transition_y == () || neck_y == ()
        || valve_y == () || cap_y == () || band_height == ();
    let missing_interface_a = band_centers.len() != 3 || band_radii.len() != 3
        || cradle_name == () || cradle_shape != "Cylinder"
        || cradle_radius == () || cradle_height == () || minimum_skirt_clearance == ();
    let missing_interface_b = cradle_pad_name == () || cradle_pad_shape != "Cube"
        || cradle_pad_width == () || cradle_pad_depth == () || cradle_pad_height == ()
        || support_name == () || support_shape != "Cylinder" || support_radius == ();
    let missing_interface_c = !vec3_is_native(body_mount) || !vec3_is_native(skirt_center)
        || !vec3_is_native(skirt_dimensions) || tank_stations == () || tank_scales.len() != 4;
    let missing_brackets = bracket_group_name == () || bracket_names.len() != 4
        || bracket_shape != "Cube" || bracket_length == () || bracket_width == ()
        || bracket_depth == () || bracket_offset == () || bracket_tilt == ();
    if missing_body || missing_end || missing_transitions || missing_interface_a
        || missing_interface_b || missing_interface_c || missing_brackets {
        return plan_error("tank SysML double dimensions or axial datums are missing");
    }
    if tank_stations.len() != 4 || tank_scales.len() != 4 {
        return plan_error("tank station and scale arrays must each contain four typed entries");
    }
    for index in 0..tank_stations.len() {
        if !vec3_is_native(tank_stations[index]) || !vec3_is_finite(tank_stations[index])
            || (tank_stations[index].y - tank_stations[0].y).abs() > 0.000001
            || (tank_scales[index] - tank_scales[0]).abs() > 0.000001 {
            return plan_error("tank component instances must share one Y datum and uniform scale for a common authored cradle");
        }
    }
    if tank_stations[0].y != body_mount.y || tank_scales[0] <= 0.0 {
        return plan_error("tank mounting datum must share the bus origin and use a positive uniform scale");
    }
    let skirt_top_y = body_mount.y + skirt_center.y + skirt_dimensions.y / 2.0;
    let cradle_top_local_y = (skirt_top_y + minimum_skirt_clearance
        - tank_stations[0].y) / tank_scales[0];
    let cradle_y = cradle_top_local_y - cradle_height / 2.0;
    let cradle_pad_y = cradle_top_local_y + cradle_pad_height / 2.0;
    let pad_top_local_y = cradle_top_local_y + cradle_pad_height;
    let lower_neck_bottom_y = -neck_y - neck_height / 2.0;
    let support_height = lower_neck_bottom_y - pad_top_local_y;
    let support_y = (lower_neck_bottom_y + pad_top_local_y) / 2.0;
    let bracket_y = pad_top_local_y + bracket_length / 2.0;
    if support_height <= 0.0 || !griffin_geometry::scalar_is_finite(support_height) {
        return plan_error("derived tank support span does not connect the cradle pad to the lower neck");
    }
    let desired = [
        #{path: root + "/" + body_name, type_name: body_shape},
        #{path: root + "/" + band_names[0], type_name: band_shape},
        #{path: root + "/" + band_names[1], type_name: band_shape},
        #{path: root + "/" + band_names[2], type_name: band_shape},
        #{path: root + "/" + end_names[0], type_name: axial_shape},
        #{path: root + "/" + end_names[1], type_name: axial_shape},
        #{path: root + "/" + service_names[0], type_name: axial_shape},
        #{path: root + "/" + service_names[1], type_name: axial_shape},
        #{path: root + "/" + service_names[2], type_name: axial_shape},
        #{path: root + "/" + service_names[3], type_name: axial_shape},
        #{path: root + "/" + service_names[4], type_name: axial_shape},
        #{path: root + "/" + service_names[5], type_name: axial_shape},
        #{path: root + "/" + cradle_name, type_name: cradle_shape},
        #{path: root + "/" + support_name, type_name: support_shape},
        #{path: root + "/" + axial_names[8], type_name: transition_shape},
        #{path: root + "/" + axial_names[9], type_name: transition_shape},
    ];
    let existing_invalid = [];
    for item in desired {
        if !_tank_schema_prim_ready(doc, item.path, item.type_name) {
            if query_ok(assembly_builder::composed_query(doc, #{path: item.path, children: false})) {
                existing_invalid.push(item.path);
            }
        }
    }
    let ops = [];
    // OpenUSD validates a typed attribute against the composed prim before
    // applying a batch. A prim with the wrong schema therefore needs its own
    // transaction: removing it and recreating it in the same batch is not
    // valid because the AddPrim still sees the old schema.  Return an
    // explicit removal phase so callers cannot accidentally hide this state.
    if existing_invalid.len() > 0 {
        for path in existing_invalid { ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}}); }
        return #{ok: true, kind: "griffin_tank_usd_double_schema_remove_required",
            phase: "remove", root: root, component_count: 1, ops: ops,
            no_op: ops.len() == 0,
            diagnostic: "mismatched tank schemas require a separate Editor removal transaction"};
    }
    // Once the removal transaction has committed, only absent prims are
    // added. Existing valid prims receive typed placement/attribute updates.
    let body_path = root + "/" + body_name;
    let body = _tank_sphere_schema_ops(edit_target, root, body_name, radius,
        body_center, [0.58, 0.43, 0.24],
        !query_ok(assembly_builder::composed_query(doc, #{path: body_path, children: false})));
    if !body.ok { return body; }
    for op in body.ops { ops.push(op); }
    for band in 0..band_names.len() {
        let band_name = band_names[band];
        let ring = _tank_cylinder_schema_ops(edit_target, root, band_name,
            band_radii[band], band_height,
            [0.0, band_centers[band], 0.0], axis, [0.10, 0.12, 0.15],
            !query_ok(assembly_builder::composed_query(doc, #{path: root + "/" + band_name, children: false})));
        if !ring.ok { return ring; }
        for op in ring.ops { ops.push(op); }
    }
    let cylinders = [
        #{name: end_names[0], radius: neck_radius, height: neck_height, y: neck_y, color: [0.25, 0.19, 0.12]},
        #{name: end_names[1], radius: neck_radius, height: neck_height, y: -neck_y, color: [0.25, 0.19, 0.12]},
        #{name: service_names[0], radius: shoulder_radius, height: shoulder_height, y: shoulder_y, color: [0.28, 0.18, 0.08]},
        #{name: service_names[1], radius: shoulder_radius, height: shoulder_height, y: -shoulder_y, color: [0.28, 0.18, 0.08]},
        #{name: service_names[2], radius: valve_radius, height: valve_height, y: valve_y, color: [0.48, 0.50, 0.53]},
        #{name: service_names[3], radius: valve_radius, height: valve_height, y: -valve_y, color: [0.48, 0.50, 0.53]},
        #{name: service_names[4], radius: cap_radius, height: cap_height, y: cap_y, color: [0.20, 0.22, 0.25]},
        #{name: service_names[5], radius: cap_radius, height: cap_height, y: -cap_y, color: [0.20, 0.22, 0.25]},
        #{name: cradle_name, radius: cradle_radius, height: cradle_height, y: cradle_y, color: [0.20, 0.22, 0.25]},
        #{name: support_name, radius: support_radius, height: support_height, y: support_y, color: [0.10, 0.12, 0.15]},
    ];
    for item in cylinders {
        let part = _tank_cylinder_schema_ops(edit_target, root, item.name,
            item.radius, item.height, [0.0, item.y, 0.0], axis, item.color,
            !query_ok(assembly_builder::composed_query(doc, #{path: root + "/" + item.name, children: false})));
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
    }
    for cone in [
        #{name: axial_names[8], radius1: transition_shoulder, radius2: transition_neck, y: transition_y},
        #{name: axial_names[9], radius1: transition_neck, radius2: transition_shoulder, y: -transition_y},
    ] {
        let part = _tank_cone_schema_ops(edit_target, root, cone.name,
            cone.radius1, cone.radius2, transition_height,
            [0.0, cone.y, 0.0], axis, [0.28, 0.18, 0.08],
            !query_ok(assembly_builder::composed_query(doc, #{path: root + "/" + cone.name, children: false})));
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: part.path,
            name: "radius", type_name: "double", value: transition_radius.to_string()}});
    }
    // The lower tank interface is part of the reusable component, not an
    // assembly-local decoration.  Keep the pad and four radial braces typed
    // from SysML so a tank can be reviewed in isolation and in the vehicle.
    let pad_path = root + "/" + cradle_pad_name;
    let pad = assembly_builder::composed_query(doc, #{path: pad_path, children: false});
    if query_ok(pad) && pad.type_name != "Cube" {
        return plan_error(pad_path + ": expected Cube, got " + pad.type_name);
    }
    if !query_ok(pad) {
        let shape = assembly_builder::cube_shape_plan(edit_target, root, cradle_pad_name, 1.0,
            [cradle_pad_width, cradle_pad_height, cradle_pad_depth], false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    let pad_placement = assembly_builder::place_plan(edit_target, pad_path,
        [0.0, cradle_pad_y, 0.0], (), [cradle_pad_width, cradle_pad_height, cradle_pad_depth]);
    if !pad_placement.ok { return pad_placement; }
    for op in pad_placement.ops { ops.push(op); }
    let bracket_group = root + "/" + bracket_group_name;
    let group = assembly_builder::composed_query(doc, #{path: bracket_group, children: false});
    if !query_ok(group) || group.type_name != "Xform" {
        return plan_error(bracket_group + ": tank bracket group is missing or not Xform");
    }
    let bracket_specs = [
        #{name: bracket_names[0], translation: [bracket_offset, bracket_y, bracket_offset], rotation: [-bracket_tilt, 0.0, -bracket_tilt]},
        #{name: bracket_names[1], translation: [-bracket_offset, bracket_y, bracket_offset], rotation: [-bracket_tilt, 0.0, bracket_tilt]},
        #{name: bracket_names[2], translation: [bracket_offset, bracket_y, -bracket_offset], rotation: [bracket_tilt, 0.0, -bracket_tilt]},
        #{name: bracket_names[3], translation: [-bracket_offset, bracket_y, -bracket_offset], rotation: [bracket_tilt, 0.0, bracket_tilt]},
    ];
    for bracket in bracket_specs {
        let bracket_path = bracket_group + "/" + bracket.name;
        let existing = assembly_builder::composed_query(doc, #{path: bracket_path, children: false});
        if query_ok(existing) && existing.type_name != "Cube" {
            return plan_error(bracket_path + ": expected Cube, got " + existing.type_name);
        }
        if !query_ok(existing) {
            let shape = assembly_builder::cube_shape_plan(edit_target, bracket_group, bracket.name, 1.0,
                [bracket_width, bracket_length, bracket_depth], false);
            if !shape.ok { return shape; }
            for op in shape.ops { ops.push(op); }
        }
        let placement = assembly_builder::place_plan(edit_target, bracket_path,
            bracket.translation, bracket.rotation, [bracket_width, bracket_length, bracket_depth]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: bracket_path,
            name: "purpose", type_name: "token", value: "\"render\""}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: bracket_path,
            name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    }
    #{ok: true, kind: "griffin_tank_usd_sphere_schema", root: root,
      component_count: 1, ops: ops, no_op: ops.len() == 0}
}

fn apply_refined_griffin_tank(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_tank_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Normalize Griffin tank USD double schema", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, component_count: plan.component_count}
}

// Refine only the engine-skirt frame.  This is intentionally a separate
// Editor task: the four rails remain assembly-owned geometry, while the
// engine bell references stay untouched and continue to own the visual bell
// profile.  All dimensions and the adapter datum come from the lander SysML
// source, so this helper contains no second placement table.
fn refine_griffin_engine_skirt_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_engine_skirt_plan requires a document, edit target, and absolute root");
    }
    let source = sysml_requirements::source();
    // The component owns its typed rail envelope. Avoid duplicated lander
    // geometry fields and source-path indirection.
    let width = _skirt_number(source, "railLengthM");
    let depth = width;
    let height = _skirt_number(source, "railHeightM");
    let section = _skirt_number(source, "railWidthM");
    let shell_depth = _skirt_number(source, "shellDepthM");
    let shell_inset = _skirt_number(source, "shellBottomInsetM");
    let adapter_name = sysml_requirements::text(source,
        "GriffinPropulsionRequirements::GriffinEngineSkirtComponent::adapterPlateName");
    let adapter_width = _skirt_number(source, "adapterPlateWidthM");
    let adapter_depth = _skirt_number(source, "adapterPlateDepthM");
    let adapter_height = _skirt_number(source, "adapterPlateHeightM");
    let local_center_y = _skirt_number(source, "componentLocalCenterYM");
    if width == () || depth == () || height == () || section == ()
        || shell_depth == () || shell_inset == () || local_center_y == ()
        || adapter_name == () || adapter_name == ""
        || adapter_width == () || adapter_depth == () || adapter_height == ()
        || width <= 0.0 || depth <= 0.0 || height <= 0.0 || section <= 0.0
        || shell_depth <= 0.0 || shell_inset <= 0.0
        || shell_inset >= width / 2.0 || shell_inset >= depth / 2.0
        || adapter_width <= 0.0 || adapter_depth <= 0.0 || adapter_height <= 0.0 {
        return plan_error("engine-skirt SysML metric dimensions are missing");
    }
    // The isolated component owns the skirt geometry; assembly-local legacy
    // beam opinions are removed during the one-time Editor migration.
    let paths = [
        root + "/RailFront", root + "/RailRear",
        root + "/RailPort", root + "/RailStarboard",
    ];
    let rail_x = width / 2.0 - section / 2.0;
    let rail_z = depth / 2.0 - section / 2.0;
    // This document is the reusable component asset.  Its parent instance
    // owns the global engineClusterMountYM; applying that global value here would
    // double-translate every rail when the component is referenced.
    let rail_y = local_center_y;
    let specs = [
        // Rails run to the outer envelope; their centres are inset by half
        // the section so adjacent members meet without a corner gap.
        // USD Cube size is one metre, so these are full physical envelopes;
        // halving them here silently produced rails that were half the SysML
        // requirement and made the skirt look detached from the engine bay.
        #{path: paths[0], translation: [0.0, rail_y, rail_z], scale: [width, height, section]},
        #{path: paths[1], translation: [0.0, rail_y, -rail_z], scale: [width, height, section]},
        #{path: paths[2], translation: [rail_x, rail_y, 0.0], scale: [section, height, depth]},
        #{path: paths[3], translation: [-rail_x, rail_y, 0.0], scale: [section, height, depth]},
    ];
    let ops = [];
    for spec in specs {
        let existing = _component_query(doc, spec.path);
        if !query_ok(existing) { return plan_error(spec.path + ": engine-skirt rail is missing"); }
        if existing.type_name != "Cube" { return plan_error(spec.path + ": expected Cube, got " + existing.type_name); }
        let placement = assembly_builder::place_plan(edit_target, spec.path,
            spec.translation, (), spec.scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: spec.path,
            name: "purpose", type_name: "token", value: "\"render\""}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: spec.path,
            name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    }
    let adapter_path = root + "/" + adapter_name;
    let adapter = _component_query(doc, adapter_path);
    if query_ok(adapter) && adapter.type_name != "Cube" {
        return plan_error(adapter_path + ": expected Cube, got " + adapter.type_name);
    }
    if !query_ok(adapter) {
        let adapter_plan = assembly_builder::cube_shape_plan(edit_target, root, adapter_name,
            1.0, [adapter_width, adapter_height, adapter_depth], false);
        if !adapter_plan.ok { return adapter_plan; }
        for op in adapter_plan.ops { ops.push(op); }
        ops.push(#{SetTranslate: #{edit_target: edit_target, path: adapter_path,
            value: [0.0, local_center_y + height / 2.0 + adapter_height / 2.0, 0.0]}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: adapter_path,
            name: "purpose", type_name: "token", value: "\"render\""}});
    }
    // Add the visible beveled octagonal shroud as its own replaceable visual part.
    // It is open at both ends so the seven bells remain readable, and it is
    // double-sided because a study-level thin shell must not disappear when
    // the Editor camera moves underneath the lander.
    let shell_path = root + "/EngineSkirtShell";
    let shell = _component_query(doc, shell_path);
    if query_ok(shell) && shell.type_name != "Mesh" {
        return plan_error(shell_path + ": existing skirt shell must be Mesh, got " + shell.type_name);
    }
    if !query_ok(shell) {
        let y_top = local_center_y + height / 2.0;
        let y_bottom = y_top - shell_depth;
        let top_x = width / 2.0;
        let top_z = depth / 2.0;
        let corner = shell_inset;
        let top_x_bevel = top_x - corner;
        let top_z_bevel = top_z - corner;
        let points = [
            [-top_x, y_top, top_z_bevel], [-top_x_bevel, y_top, top_z],
            [top_x_bevel, y_top, top_z], [top_x, y_top, top_z_bevel],
            [top_x, y_top, -top_z_bevel], [top_x_bevel, y_top, -top_z],
            [-top_x_bevel, y_top, -top_z], [-top_x, y_top, -top_z_bevel],
            [-top_x, y_bottom, top_z_bevel], [-top_x_bevel, y_bottom, top_z],
            [top_x_bevel, y_bottom, top_z], [top_x, y_bottom, top_z_bevel],
            [top_x, y_bottom, -top_z_bevel], [top_x_bevel, y_bottom, -top_z],
            [-top_x_bevel, y_bottom, -top_z], [-top_x, y_bottom, -top_z_bevel],
        ];
        let mesh = assembly_builder::mesh_shape_plan(edit_target, root,
            "EngineSkirtShell", points, [4, 4, 4, 4, 4, 4, 4, 4],
            [0, 1, 9, 8, 1, 2, 10, 9, 2, 3, 11, 10, 3, 4, 12, 11,
             4, 5, 13, 12, 5, 6, 14, 13, 6, 7, 15, 14, 7, 0, 8, 15],
            [0.07, 0.09, 0.12], false);
        if !mesh.ok { return mesh; }
        for op in mesh.ops { ops.push(op); }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: shell_path,
        name: "doubleSided", type_name: "bool", value: "true"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: shell_path,
        name: "purpose", type_name: "token", value: "\"render\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: shell_path,
        name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
    let component_record = assembly_builder::composed_query(doc,
        #{path: root, attrs: ["lunco:visual:component",
            "lunco:visual:datum", "lunco:visual:skirt_metric_envelope"],
          children: false});
    if query_ok(component_record) && component_record.attrs != () {
        for name in ["lunco:visual:component", "lunco:visual:datum",
            "lunco:visual:skirt_metric_envelope"] {
            if component_record.attrs[name] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: root, name: name}});
            }
        }
    }
    paths.push(shell_path);
    #{ok: true, kind: "griffin_engine_skirt_refinement", root: root,
      paths: paths, ops: ops, no_op: ops.len() == 0}
}

fn apply_refined_griffin_engine_skirt(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_engine_skirt_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Refine Griffin engine skirt", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

fn refine_griffin_engine_bell_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_engine_bell_component_plan requires a document, edit target, and absolute root");
    }
    let component = _component_query(doc, root);
    if !component.ok || component.type_name != "Xform" {
        return plan_error(root + ": engine-bell component root is missing or not Xform");
    }
    let record = assembly_builder::composed_query(doc, #{path: root,
        attrs: ["lunco:visual:component"], children: false});
    let ops = [];
    if query_ok(record) && record.attrs != ()
        && record.attrs["lunco:visual:component"] != () {
        ops.push(#{RemoveAttribute: #{edit_target: edit_target,
            path: root, name: "lunco:visual:component"}});
    }
    #{ok: true, kind: "griffin_engine_bell_component_refinement",
      root: root, paths: [root], ops: ops, no_op: ops.len() == 0}
}

fn apply_refined_griffin_engine_bell(doc, edit_target, root, parent_gen) {
    let plan = refine_griffin_engine_bell_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Remove stale Griffin engine-bell string metadata", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

fn _isolated_ramp_spec(root, side) {
    let mount_x = _ramp_number(if side == "port" {
        "rampPortMountX"
    } else if side == "starboard" {
        "rampStarboardMountX"
    } else {
        ""
    });
    let mount_y = _ramp_number("rampMountY");
    let mount_z = _ramp_number("rampMountZ");
    let angle_deg = _ramp_angle_deg(side);
    if mount_x == () || mount_y == () || mount_z == () || angle_deg == () {
        return ();
    }
    if side == "port" {
        return #{parent: root, name: "EgressRampPort", type_name: "Xform",
            asset: component_asset("lander/griffin_ramp_visual.usda"),
            translation: [mount_x, mount_y, mount_z], rotation: [0.0, 0.0, angle_deg], scale: ()};
    }
    if side == "starboard" {
        return #{parent: root, name: "EgressRampStarboard", type_name: "Xform",
            asset: component_asset("lander/griffin_ramp_visual.usda"),
            translation: [mount_x, mount_y, mount_z], rotation: [0.0, 180.0, angle_deg], scale: ()};
    }
    ()
}

fn _isolated_ramp_contract_ops(edit_target, path, side) {
    let source = sysml_requirements::source();
    let limit = _sysml_number(source, "rampMaxDeploymentAngleRad");
    let length = _sysml_number(source, "rampSurfaceLengthM");
    let width = _sysml_number(source, "rampSurfaceWidthM");
    let angle_name = if side == "port" {
        "rampPortDeploymentAngleRad"
    } else {
        "rampStarboardDeploymentAngleRad"
    };
    let angle = _sysml_number(source, angle_name);
    let section_count = _sysml_integer(source, "rampSectionCount");
    let section_length = _sysml_number(source, "rampSectionLengthM");
    let hinge_axis = sysml_requirements::native_value(source,
        griffin_spec::qualified_attribute_name("hingeAxis"));
    if limit == () || length == () || width == () || angle == ()
        || section_count == () || section_length == ()
        || !sysml_enum_is(hinge_axis) || hinge_axis.literal != "Z" {
        return plan_error("ramp SysML dimensions, placement, or deployment values are missing");
    }
    [
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:side", type_name: "token", value: "\"" + side + "\""}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:hinge_axis", type_name: "token",
            value: "\"" + hinge_axis.literal + "\""}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:surface_length_m", type_name: "double", value: length.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:surface_width_m", type_name: "double", value: width.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:section_count", type_name: "int", value: section_count.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:section_length_m", type_name: "double", value: section_length.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:deployment_limit_rad", type_name: "double", value: limit.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:deployment_angle_rad", type_name: "double", value: angle.to_string()}},
    ]
}

fn _ramp_section_track_points(length, thickness, width, toe_bevel) {
    let x_tip_bottom = length - toe_bevel;
    let half_thickness = thickness / 2.0;
    let half_width = width / 2.0;
    [
        [0.0, -half_thickness, -half_width],
        [0.0, half_thickness, -half_width],
        [length, half_thickness, -half_width],
        [x_tip_bottom, -half_thickness, -half_width],
        [0.0, -half_thickness, half_width],
        [0.0, half_thickness, half_width],
        [length, half_thickness, half_width],
        [x_tip_bottom, -half_thickness, half_width],
    ]
}

// Materialize one physical ramp section from its SysML dimensions. The USD
// component is a topology template; all dimensions, stations, and toe bevel
// are written from the canonical requirement source before the section is
// accepted by the Editor plan.
fn _isolated_ramp_section_geometry_ops(doc, edit_target, section_path,
    section_name, section_length, section_index, deployment_angle) {
    let source = sysml_requirements::source();
    let section_count = griffin_spec::ramp_section_count();
    let total_length = _sysml_number(source, "rampSurfaceLengthM");
    let thickness = _sysml_number(source, "rampSurfaceThicknessM");
    let surface_y = _sysml_number(source, "rampSurfaceCenterYM");
    let track_width = _sysml_number(source, "assemblyTrackWidthM");
    let rail_height = _sysml_number(source, "rampRailHeightM");
    let rail_width = _sysml_number(source, "rampRailWidthM");
    let rail_y = _sysml_number(source, "rampRailCenterYM");
    let rail_z = _sysml_number(source, "rampRailOffsetZM");
    let rail_pin_names = griffin_spec::ramp_rail_joint_pin_names();
    let rail_pin_radius = griffin_spec::ramp_rail_joint_pin_radius_m();
    let rail_pin_length = griffin_spec::ramp_rail_joint_pin_length_m();
    let track_centers = griffin_spec::rover_wheel_station_z();
    let tread_count = griffin_spec::ramp_tread_count_per_section();
    let tread_names = griffin_spec::ramp_tread_names();
    let tread_width = griffin_spec::ramp_tread_width_m();
    let tread_height = griffin_spec::ramp_tread_height_m();
    let tread_first_x = griffin_spec::ramp_tread_first_center_x_m();
    let tread_pitch = griffin_spec::ramp_tread_pitch_m();
    let beam_width = griffin_spec::ramp_under_beam_width_m();
    let beam_height = griffin_spec::ramp_under_beam_height_m();
    let beam_y = griffin_spec::ramp_under_beam_center_y_m();
    let beam_z = griffin_spec::ramp_under_beam_center_offset_z_m();
    let post_count = griffin_spec::ramp_side_post_count_per_section_per_side();
    let post_width = griffin_spec::ramp_side_post_width_m();
    let post_depth = griffin_spec::ramp_side_post_depth_m();
    let post_embed = griffin_spec::ramp_side_post_embedded_depth_m();
    let post_first_x = griffin_spec::ramp_side_post_first_center_x_m();
    let post_pitch = griffin_spec::ramp_side_post_pitch_m();
    let hinge_radius = griffin_spec::ramp_section_hinge_barrel_radius_m();
    let hinge_length = griffin_spec::ramp_section_hinge_barrel_length_m();
    let hinge_y = griffin_spec::ramp_section_hinge_barrel_center_y_m();
    let invalid_section = section_count != 3 || section_index < 0
        || section_index >= section_count;
    let invalid_dimensions = section_length <= 0.0 || total_length == ()
        || thickness == () || surface_y == () || track_width == ();
    let invalid_rail_geometry = rail_height == () || rail_width == ()
        || rail_y == () || rail_z == ();
    let invalid_rail_pins = rail_pin_names.len() != 2 || rail_pin_radius == ()
        || rail_pin_length == ();
    let invalid_tread_count = tread_count <= 0 || tread_names.len() != tread_count
        || track_centers.len() != 4;
    let invalid_tread_size = tread_width == () || tread_height == ()
        || tread_first_x == () || tread_pitch == ();
    let invalid_beams = beam_width == () || beam_height == ()
        || beam_y == () || beam_z == ();
    let invalid_post_count = post_count <= 0 || post_width == () || post_depth == ();
    let invalid_post_fit = post_embed == () || post_first_x == () || post_pitch == ();
    let invalid_hinge = hinge_radius == () || hinge_length == ()
        || hinge_y == () || deployment_angle == ();
    let invalid_basic = invalid_section || invalid_dimensions || invalid_rail_geometry;
    let invalid_repeated = invalid_rail_pins || invalid_tread_count || invalid_tread_size;
    let invalid_support = invalid_beams || invalid_post_count || invalid_post_fit;
    if invalid_basic || invalid_repeated || invalid_support || invalid_hinge {
        return plan_error(section_path + ": ramp section geometry source values are incomplete");
    }
    let tolerance = _sysml_number(source, "rampSectionGeometryToleranceM");
    if tolerance == () || (section_count * section_length - total_length).abs() > tolerance
        || tread_count * section_count != _sysml_integer(source, "assemblyTreadCount") {
        return plan_error(section_path + ": ramp section length or tread count does not match the SysML assembly");
    }
    let walking_surface_top_y = surface_y + thickness / 2.0;
    let rail_bottom_y = rail_y - rail_height / 2.0;
    if (rail_bottom_y - walking_surface_top_y).abs() > tolerance {
        return plan_error(section_path + ": upper rail base does not meet the walking-surface top");
    }
    let post_bottom_y = walking_surface_top_y - post_embed;
    let post_top_y = rail_y + rail_height / 2.0;
    let post_height = post_top_y - post_bottom_y;
    let post_y = (post_top_y + post_bottom_y) / 2.0;
    if post_embed <= 0.0 || post_height <= 0.0 {
        return plan_error(section_path + ": rail support embedment produces an invalid post extent");
    }
    let half_track = 0.0;
    for station in track_centers {
        if station.abs() > half_track { half_track = station.abs(); }
    }
    let toe_bevel = if section_index == section_count - 1 {
        mechanical_relations::planar_horizontal_face_bevel_run(thickness, deployment_angle)
    } else { 0.0 };
    if toe_bevel == () || toe_bevel < 0.0 || toe_bevel >= section_length {
        return plan_error(section_path + ": source deployment angle yields an invalid ramp toe bevel");
    }
    let points = _ramp_section_track_points(section_length, thickness, track_width, toe_bevel);
    let ops = [];
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: section_path,
        name: "lunco:ramp:section:identity", type_name: "token",
        value: "\"" + section_name + "\""}});

    for track in [
        #{name: "RampTrackPort", center_z: half_track},
        #{name: "RampTrackStarboard", center_z: -half_track},
    ] {
        let track_path = section_path + "/" + track.name;
        let member = assembly_builder::composed_query(doc,
            #{path: track_path, children: false});
        if !query_ok(member) || member.type_name != "Mesh" {
            return plan_error(track_path + ": section contact-track mesh is missing");
        }
        let geometry = assembly_builder::mesh_points_update_plan(
            edit_target, track_path, points);
        if !geometry.ok { return geometry; }
        for op in geometry.ops { ops.push(op); }
        for item in [
            #{name: "physics:collisionEnabled", type_name: "bool", value: "true"},
            #{name: "physics:approximation", type_name: "token", value: "\"convexHull\""},
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: track_path,
                name: item.name, type_name: item.type_name, value: item.value}});
        }
        let placement = assembly_builder::place_plan(edit_target, track_path,
            [0.0, surface_y, track.center_z], (), [1.0, 1.0, 1.0]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }

    for rail in [
        #{name: "OuterRail", z: rail_z},
        #{name: "InnerRail", z: -rail_z},
    ] {
        let rail_path = section_path + "/" + rail.name;
        let placement = assembly_builder::place_plan(edit_target, rail_path,
            [section_length / 2.0, rail_y, rail.z], (),
            [section_length, rail_height, rail_width]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }

    // Each section begins at either the deck pivot or an intermediate pivot.
    // Place the two edge-rail fittings on that same line so the rail assembly
    // visibly follows all three revolute joints.
    for index in 0..rail_pin_names.len() {
        let pin_name = rail_pin_names[index];
        let pin_path = section_path + "/" + pin_name;
        let pin = assembly_builder::composed_query(doc,
            #{path: pin_path, children: false});
        if !query_ok(pin) || pin.type_name != "Cylinder" {
            return plan_error(pin_path + ": source-owned upper-rail pivot fitting is missing");
        }
        let pin_z = if pin_name == "OuterRailJointPin" { rail_z } else { -rail_z };
        for item in [
            #{name: "radius", type_name: "double", value: rail_pin_radius.to_string()},
            #{name: "height", type_name: "double", value: rail_pin_length.to_string()},
            #{name: "axis", type_name: "token", value: "\"Z\""},
            #{name: "physics:collisionEnabled", type_name: "bool", value: "false"},
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: pin_path,
                name: item.name, type_name: item.type_name, value: item.value}});
        }
        let pin_placement = assembly_builder::place_plan(edit_target, pin_path,
            [0.0, rail_y, pin_z], (), [1.0, 1.0, 1.0]);
        if !pin_placement.ok { return pin_placement; }
        for op in pin_placement.ops { ops.push(op); }
    }

    for beam in [
        #{name: "UnderBeamPort", z: beam_z},
        #{name: "UnderBeamStarboard", z: -beam_z},
    ] {
        let beam_path = section_path + "/" + beam.name;
        let placement = assembly_builder::place_plan(edit_target, beam_path,
            [section_length / 2.0, beam_y, beam.z],
            (), [section_length, beam_height, beam_width]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }

    for post_side in [
        #{name: "Port", z: rail_z},
        #{name: "Starboard", z: -rail_z},
    ] {
        for index in 0..post_count {
            let post_path = section_path + "/SidePost" + post_side.name
                + (index + 1).to_string();
            let placement = assembly_builder::place_plan(edit_target, post_path,
                [post_first_x + post_pitch * index, post_y, post_side.z],
                (), [post_width, post_height, post_depth]);
            if !placement.ok { return placement; }
            for op in placement.ops { ops.push(op); }
        }
    }

    for track in [
        #{name: "Port", center_z: half_track},
        #{name: "Starboard", center_z: -half_track},
    ] {
        for index in 0..tread_count {
            let tread_path = section_path + "/Tread" + track.name
                + (index + 1).to_string();
            let tread_y = thickness / 2.0 + tread_height / 2.0;
            let placement = assembly_builder::place_plan(edit_target, tread_path,
                [tread_first_x + tread_pitch * index, tread_y, track.center_z],
                (), [tread_width, tread_height, track_width]);
            if !placement.ok { return placement; }
            for op in placement.ops { ops.push(op); }
        }
    }

    let hinge_path = section_path + "/HingeBarrel";
    for item in [
        #{name: "radius", type_name: "double", value: hinge_radius.to_string()},
        #{name: "height", type_name: "double", value: hinge_length.to_string()},
        #{name: "axis", type_name: "token", value: "\"Z\""},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: hinge_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    let hinge_place = assembly_builder::place_plan(edit_target, hinge_path,
        [0.0, hinge_y, 0.0], (), [1.0, 1.0, 1.0]);
    if !hinge_place.ok { return hinge_place; }
    for op in hinge_place.ops { ops.push(op); }

    #{ok: true, kind: "griffin_ramp_section_geometry",
      path: section_path, section: section_name, section_index: section_index,
      section_length_m: section_length, toe_bevel_m: toe_bevel,
      contact_track_paths: [section_path + "/RampTrackPort",
          section_path + "/RampTrackStarboard"],
      ops: ops, no_op: ops.len() == 0}
}

// Reconcile the three inherited section instances in the reusable visual
// assembly and materialize their geometry from the SysML source.
fn _isolated_ramp_visual_geometry_ops(doc, edit_target, path, side) {
    let section_count = griffin_spec::ramp_section_count();
    let section_length = griffin_spec::ramp_section_length_m();
    let section_names = griffin_spec::ramp_section_names();
    let angle = _ramp_number(if side == "port" {
        "rampPortDeploymentAngleRad"
    } else {
        "rampStarboardDeploymentAngleRad"
    });
    let tolerance = _ramp_number("rampSectionGeometryToleranceM");
    if section_count != 3 || section_length == () || section_length <= 0.0
        || section_names.len() != section_count || tolerance == () || tolerance <= 0.0
        || angle == () {
        return plan_error("articulated ramp section datums are incomplete");
    }
    let ops = [];
    for index in 0..section_count {
        let name = section_names[index];
        let section_path = path + "/" + name;
        let section = assembly_builder::composed_query(doc,
            #{path: section_path, children: false});
        if !query_ok(section) || section.type_name != "Xform" {
            return plan_error(section_path + ": referenced ramp section is missing");
        }
        for child in ["RampTrackPort", "RampTrackStarboard", "OuterRail", "InnerRail"] {
            let member = assembly_builder::composed_query(doc,
                #{path: section_path + "/" + child, children: false,
                  attrs: ["physics:collisionEnabled"]});
            if !query_ok(member) {
                return plan_error(section_path + "/" + child + ": section geometry is missing");
            }
            if child == "RampTrackPort" || child == "RampTrackStarboard"
                || child == "OuterRail" || child == "InnerRail" {
                if member.attrs == () || member.attrs["physics:collisionEnabled"] != true {
                    return plan_error(section_path + "/" + child + ": composed contact/guard geometry must own collision");
                }
            }
        }
        let local_x = section_length * index;
        let placement = assembly_builder::place_plan(edit_target, section_path,
            [local_x, 0.0, 0.0], (), ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        let section_geometry = _isolated_ramp_section_geometry_ops(doc, edit_target,
            section_path, name, section_length, index, angle);
        if !section_geometry.ok { return section_geometry; }
        for op in section_geometry.ops { ops.push(op); }
    }
    #{ok: true, kind: "griffin_articulated_ramp_visual_sections",
      section_count: section_count, section_length_m: section_length,
      total_length_m: section_length * section_count, ops: ops,
      no_op: ops.len() == 0}
}

fn _physical_ramp_transition_ops(doc, edit_target, lander_root, ramp_root, side,
    transition_length, thickness, width, surface_y) {
    let source = sysml_requirements::source();
    let name = griffin_spec::physical_ramp_transition_child_name();
    let mass = griffin_spec::physical_ramp_deck_transition_mass_kg();
    let inertia = griffin_spec::physical_ramp_deck_transition_inertia_kg_m2();
    let joint_name = griffin_spec::physical_ramp_transition_joint_name(side);
    let mount_y = _sysml_number(source, "physicalRampMountY");
    let mount_z = _sysml_number(source, "physicalRampMountZ");
    let mount_x = _sysml_number(source, if side == "port" {
        "physicalRampPortMountX"
    } else {
        "physicalRampStarboardMountX"
    });
    if name == () || name == "" || mass == () || mass <= 0.0
        || inertia.len() != 3 || joint_name == () || joint_name == ""
        || mount_x == () || mount_y == () || mount_z == () {
        return plan_error("physical ramp transition identity/mass/inertia datums are incomplete in SysML");
    }
    let path = ramp_root + "/" + name;
    let contact_name = griffin_spec::physical_ramp_transition_contact_child_name();
    if contact_name == () || contact_name == "" {
        return plan_error("physical ramp transition contact child name is missing from SysML");
    }
    let contact_path = path + "/" + contact_name;
    let existing = assembly_builder::composed_query(doc, #{path: path, children: false});
    let migrate_scaled_body = query_ok(existing) && existing.type_name == "Cube";
    if query_ok(existing) && existing.type_name != "Xform" && !migrate_scaled_body {
        return plan_error(path + ": physical ramp transition must be an Xform rigid-body frame");
    }
    let ops = [];
    if migrate_scaled_body {
        // A scaled Cube cannot serve as the rigid-body frame. Replace it with
        // the required Xform and author its contact child and fixed joint in
        // the same undoable Editor change set.
        ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: ramp_root,
            name: name, type_name: "Xform", reference: (), reference_prim_path: ""}});
    } else if !query_ok(existing) {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: ramp_root,
            name: name, type_name: "Xform", reference: (),
            reference_prim_path: ""}});
    }
    // The frame is deliberately unscaled: a rigid body must not carry a
    // non-uniform transform that stretches future mounted children.
    ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: path,
        schemas: ["PhysicsRigidBodyAPI", "PhysxRigidBodyAPI", "PhysicsMassAPI"]}});
    // The plate is inboard of the hinge in each side-local ramp frame. Its
    // local authored placement is also the fixed-joint body1 origin. Once the
    // joint is admitted, the physics projector owns this nested body and keeps
    // it horizontal at the Griffin deck anchor while the parent ramp rotates.
    let center_x = if side == "port" {
        -transition_length / 2.0
    } else {
        transition_length / 2.0
    };
    let placement = assembly_builder::place_plan(edit_target, path,
        [center_x, surface_y, 0.0], [0.0, 0.0, 0.0], ());
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
    for item in [
        #{name: "physics:mass", type_name: "float", value: mass.to_string()},
        #{name: "physics:diagonalInertia", type_name: "float3",
          value: "(" + inertia[0].to_string() + ", " + inertia[1].to_string()
            + ", " + inertia[2].to_string() + ")"}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    for op in remove_legacy_semantic_string_ops(doc, edit_target, path) {
        ops.push(op);
    }
    let existing_contact = assembly_builder::composed_query(doc,
        #{path: contact_path, children: false});
    if query_ok(existing_contact) && existing_contact.type_name != "Cube" {
        return plan_error(contact_path + ": transition contact child must be a Cube");
    }
    if !query_ok(existing_contact) || migrate_scaled_body {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: path,
            name: contact_name, type_name: "Cube", reference: (),
            reference_prim_path: ""}});
    }
    ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: contact_path,
        schemas: ["PhysicsCollisionAPI", "MaterialBindingAPI"]}});
    let contact_placement = assembly_builder::place_plan(edit_target, contact_path,
        [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [transition_length, thickness, width]);
    if !contact_placement.ok { return contact_placement; }
    for op in contact_placement.ops { ops.push(op); }
    for item in [
        #{name: "size", type_name: "double", value: "1.0"},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "true"},
        #{name: "primvars:displayColor", type_name: "color3f[]",
          value: "[(0.42, 0.26, 0.12)]"}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: contact_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    for op in remove_legacy_semantic_string_ops(doc, edit_target, contact_path) {
        ops.push(op);
    }
    let joint_path = ramp_root + "/" + joint_name;
    let existing_joint = assembly_builder::composed_query(doc,
        #{path: joint_path, children: false});
    if query_ok(existing_joint) && existing_joint.type_name != "PhysicsFixedJoint" {
        return plan_error(joint_path + ": transition joint must be PhysicsFixedJoint");
    }
    if !query_ok(existing_joint) || migrate_scaled_body {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: ramp_root,
            name: joint_name, type_name: "PhysicsFixedJoint", reference: (),
            reference_prim_path: ""}});
    }
    // The fixed joint is deliberately attached to the lander root rather than
    // the rotating ramp body. body1 remains the named nested TransitionPlate;
    // localPos0 is the deck-frame centre and localPos1 is its own origin.
    let anchor_x = mount_x + center_x;
    for relation in [
        #{name: "physics:body0", targets: [lander_root]},
        #{name: "physics:body1", targets: [ramp_root + "/" + name]},
    ] {
        ops.push(#{SetRelationship: #{edit_target: edit_target, path: joint_path,
            name: relation.name, targets: relation.targets}});
    }
    for item in [
        #{name: "physics:localPos0", type_name: "point3f",
          value: "(" + anchor_x.to_string() + ", " + mount_y.to_string()
            + ", " + mount_z.to_string() + ")"},
        #{name: "physics:localPos1", type_name: "point3f", value: "(0.0, 0.0, 0.0)"},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    for op in remove_legacy_semantic_string_ops(doc, edit_target, joint_path) {
        ops.push(op);
    }
    #{ok: true, path: path, name: name, center_x_m: center_x,
      transition_length_m: transition_length, mass_kg: mass, inertia_kg_m2: inertia,
      contact_path: contact_path, joint_path: joint_path,
      joint_anchor_x_m: anchor_x, ops: ops}
}

// Reconcile the physical ramp as a top-deck hinge plus three rigid sections.
// Geometry is materialized by the same source-driven section builder used by
// the visual assembly; this plan adds section masses, placement, and joints.
fn isolated_griffin_physical_ramp_geometry_plan(doc, edit_target, lander_root, side) {
    if doc == () || edit_target == () || !absolute_root(lander_root) {
        return plan_error("physical articulated-ramp planning requires a document, edit target, and absolute lander root");
    }
    if side != "port" && side != "starboard" {
        return plan_error("physical ramp side must be port or starboard");
    }
    let source = sysml_requirements::source();
    let suffix = if side == "port" { "Port" } else { "Starboard" };
    let ramp_path = lander_root + "/EgressRamp" + suffix;
    let section_count = _sysml_integer(source, "rampSectionCount");
    let section_length = _sysml_number(source, "rampSectionLengthM");
    let total_length = _sysml_number(source, "rampSurfaceLengthM");
    let geometry_tolerance = _sysml_number(source, "rampSectionGeometryToleranceM");
    let width = _sysml_number(source, "rampSurfaceWidthM");
    let thickness = _sysml_number(source, "rampSurfaceThicknessM");
    let rail_height = _sysml_number(source, "rampRailHeightM");
    let rail_width = _sysml_number(source, "rampRailWidthM");
    let surface_y = _sysml_number(source, "rampSurfaceCenterYM");
    let clearance = _sysml_number(source, "rampWheelClearanceM");
    let mass = _sysml_number(source, "physicalRampMassKg");
    let section_mass = _sysml_number(source, "physicalRampSectionMassKg");
    let inertia_x = _sysml_number(source, "physicalRampSectionInertiaXKgM2");
    let inertia_y = _sysml_number(source, "physicalRampSectionInertiaYKgM2");
    let inertia_z = _sysml_number(source, "physicalRampSectionInertiaZKgM2");
    let mass_tolerance = _sysml_number(source,
        "physicalRampSectionMassPropertiesToleranceKgM2");
    let mass_partition_tolerance = _sysml_number(source,
        "physicalRampSectionMassPartitionToleranceKg");
    let section_limit_rad = _sysml_number(source,
        "physicalRampSectionJointLimitRad");
    let target_rad = _sysml_number(source,
        "physicalRampSectionDriveTargetRad");
    let drive_stiffness = _sysml_number(source,
        "physicalRampSectionDriveStiffnessNmPerDeg");
    let drive_damping = _sysml_number(source,
        "physicalRampSectionDriveDampingNmPerDegPerSec");
    let drive_max_torque = _sysml_number(source,
        "physicalRampSectionDriveMaxTorqueNm");
    let root_limit_rad = _sysml_number(source, "rampMaxDeploymentAngleRad");
    let mount_x = _sysml_number(source, if side == "port" {
        "physicalRampPortMountX"
    } else {
        "physicalRampStarboardMountX"
    });
    let mount_y = _sysml_number(source, "physicalRampMountY");
    let mount_z = _sysml_number(source, "physicalRampMountZ");
    let section_names = griffin_spec::ramp_section_names();
    let joint_names = griffin_spec::ramp_intermediate_joint_names();
    let missing_geometry = section_count != 3 || section_length == ()
        || total_length == () || geometry_tolerance == () || width == ()
        || thickness == () || rail_height == () || rail_width == () || clearance == ();
    let missing_mass = mass == () || section_mass == () || inertia_x == ()
        || inertia_y == () || inertia_z == () || mass_tolerance == ()
        || mass_partition_tolerance == ();
    let missing_actuation = section_limit_rad == () || target_rad == ()
        || drive_stiffness == () || drive_damping == ()
        || drive_max_torque == () || root_limit_rad == ();
    let missing_mount = mount_x == () || mount_y == () || mount_z == ()
        || section_names.len() != 3 || joint_names.len() != 4;
    if missing_geometry || missing_mass || missing_actuation || missing_mount {
        return plan_error("articulated physical-ramp SysML datums are incomplete");
    }
    let invalid_length = (section_count * section_length - total_length).abs()
        > geometry_tolerance || section_mass <= 0.0;
    let invalid_mass = (section_count * section_mass - mass).abs()
        > mass_partition_tolerance || mass_tolerance <= 0.0
        || mass_partition_tolerance <= 0.0;
    let invalid_inertia = inertia_x <= 0.0 || inertia_y <= 0.0 || inertia_z <= 0.0;
    let invalid_actuation = section_limit_rad <= 0.0 || root_limit_rad <= 0.0
        || drive_stiffness <= 0.0 || drive_damping < 0.0 || drive_max_torque <= 0.0;
    let invalid_envelope = width <= 0.0 || thickness <= 0.0
        || rail_height <= 0.0 || rail_width <= 0.0 || clearance <= 0.0;
    if invalid_length || invalid_mass || invalid_inertia || invalid_actuation
        || invalid_envelope {
        return plan_error("articulated physical-ramp source values violate the section, mass, or geometry contract");
    }
    let expected_inertia_x = section_mass * (width * width + thickness * thickness) / 12.0;
    let expected_inertia_y = section_mass * (section_length * section_length
        + width * width) / 12.0;
    let expected_inertia_z = section_mass * (section_length * section_length
        + thickness * thickness) / 12.0;
    if (inertia_x - expected_inertia_x).abs() > mass_tolerance
        || (inertia_y - expected_inertia_y).abs() > mass_tolerance
        || (inertia_z - expected_inertia_z).abs() > mass_tolerance {
        return plan_error("ramp section inertia no longer matches its source geometry envelope");
    }
    let root = assembly_builder::composed_query(doc,
        #{path: ramp_path, children: false});
    if !query_ok(root) || root.type_name != "Xform" {
        return plan_error(ramp_path + ": top-deck physical ramp rigid body is missing");
    }
    let middle_path = ramp_path + "/MiddleSection";
    let toe_path = middle_path + "/ToeSection";
    for body_path in [middle_path, toe_path] {
        let body = assembly_builder::composed_query(doc,
            #{path: body_path, children: false});
        if !query_ok(body) || body.type_name != "Xform" {
            return plan_error(body_path + ": articulated rigid section is missing");
        }
    }

    let ops = [];
    let root_rotation = if side == "port" { [0.0, 0.0, 0.0] }
        else { [0.0, 180.0, 0.0] };
    let root_placement = assembly_builder::place_plan(edit_target, ramp_path,
        [mount_x, mount_y, mount_z], root_rotation, ());
    if !root_placement.ok { return root_placement; }
    for op in root_placement.ops { ops.push(op); }
    for body in [ramp_path, middle_path, toe_path] {
        for item in [
            #{name: "physics:mass", type_name: "float", value: section_mass.to_string()},
            #{name: "physics:diagonalInertia", type_name: "float3",
              value: "(" + inertia_x.to_string() + ", " + inertia_y.to_string()
                + ", " + inertia_z.to_string() + ")"}
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: body,
                name: item.name, type_name: item.type_name, value: item.value}});
        }
    }
    let middle_place = assembly_builder::place_plan(edit_target, middle_path,
        [section_length, 0.0, 0.0], (), ());
    if !middle_place.ok { return middle_place; }
    for op in middle_place.ops { ops.push(op); }
    let toe_place = assembly_builder::place_plan(edit_target, toe_path,
        [section_length, 0.0, 0.0], (), ());
    if !toe_place.ok { return toe_place; }
    for op in toe_place.ops { ops.push(op); }
    let section_angle = _sysml_number(source, if side == "port" {
        "physicalRampPortDeploymentAngleRad"
    } else {
        "physicalRampStarboardDeploymentAngleRad"
    });
    if section_angle == () {
        return plan_error("physical ramp toe geometry requires its source deployment angle");
    }
    for section in [
        #{name: section_names[0], path: ramp_path + "/DeckSection", index: 0},
        #{name: section_names[1], path: middle_path, index: 1},
        #{name: section_names[2], path: toe_path, index: 2},
    ] {
        let geometry = _isolated_ramp_section_geometry_ops(doc, edit_target,
            section.path, section.name, section_length, section.index, section_angle);
        if !geometry.ok { return geometry; }
        for op in geometry.ops { ops.push(op); }
    }
    for item in [
        #{name: "lunco:operational_width_m", type_name: "double", value: width.to_string()},
        #{name: "lunco:wheel_clearance_m", type_name: "double", value: clearance.to_string()},
        #{name: "lunco:deployment_angle_rad", type_name: "float", value: "0.0"}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: ramp_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }

    // The root joint starts at the upper deck datum. The starboard body is
    // mirrored about Y, so its joint frame is rotated to retain the same USD Z axis.
    let root_joint_path = lander_root + "/RampHinge" + suffix;
    let root_joint = assembly_builder::composed_query(doc,
        #{path: root_joint_path, children: false});
    if !query_ok(root_joint) || root_joint.type_name != "PhysicsRevoluteJoint" {
        return plan_error(root_joint_path + ": top-deck revolute hinge is missing");
    }
    let root_limit_deg = root_limit_rad * 180.0 / 3.141592653589793;
    let root_rot1 = if side == "port" { "(0.0, 0.0, 0.0, 1.0)" }
        else { "(0.0, 1.0, 0.0, 0.0)" };
    for item in [
        #{name: "physics:localPos0", type_name: "point3f",
          value: "(" + mount_x.to_string() + ", " + mount_y.to_string()
            + ", " + mount_z.to_string() + ")"},
        #{name: "physics:localPos1", type_name: "point3f", value: "(0.0, 0.0, 0.0)"},
        #{name: "physics:localRot1", type_name: "quatf", value: root_rot1},
        #{name: "physics:lowerLimit", type_name: "float", value: (-root_limit_deg).to_string()},
        #{name: "physics:upperLimit", type_name: "float", value: root_limit_deg.to_string()}
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: root_joint_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }

    let joint_offset = if side == "port" { 0 } else { 2 };
    let section_limit_deg = section_limit_rad * 180.0 / 3.141592653589793;
    let target_deg = target_rad * 180.0 / 3.141592653589793;
    for section_index in 0..2 {
        let joint_name = joint_names[joint_offset + section_index];
        let joint_path = lander_root + "/" + joint_name;
        let joint = assembly_builder::composed_query(doc,
            #{path: joint_path, children: false});
        if !query_ok(joint) || joint.type_name != "PhysicsRevoluteJoint" {
            return plan_error(joint_path + ": intermediate physical ramp hinge is missing");
        }
        let body0 = if section_index == 0 { ramp_path } else { middle_path };
        let body1 = if section_index == 0 { middle_path } else { toe_path };
        for relation in [
            #{name: "physics:body0", targets: [body0]},
            #{name: "physics:body1", targets: [body1]}
        ] {
            ops.push(#{SetRelationship: #{edit_target: edit_target,
                path: joint_path, name: relation.name, targets: relation.targets}});
        }
        for item in [
            #{name: "physics:axis", type_name: "token", value: "\"Z\""},
            #{name: "physics:localPos0", type_name: "point3f",
              value: "(" + section_length.to_string() + ", 0.0, 0.0)"},
            #{name: "physics:localPos1", type_name: "point3f", value: "(0.0, 0.0, 0.0)"},
            #{name: "physics:lowerLimit", type_name: "float", value: (-section_limit_deg).to_string()},
            #{name: "physics:upperLimit", type_name: "float", value: section_limit_deg.to_string()},
            #{name: "drive:angular:physics:targetPosition", type_name: "float", value: target_deg.to_string()},
            #{name: "drive:angular:physics:targetVelocity", type_name: "float", value: "0.0"},
            #{name: "drive:angular:physics:stiffness", type_name: "float", value: drive_stiffness.to_string()},
            #{name: "drive:angular:physics:damping", type_name: "float", value: drive_damping.to_string()},
            #{name: "drive:angular:physics:maxForce", type_name: "float", value: drive_max_torque.to_string()},
            #{name: "physics:collisionEnabled", type_name: "bool", value: "false"}
        ] {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint_path,
                name: item.name, type_name: item.type_name, value: item.value}});
        }
    }

    let transition_length = _sysml_number(source,
        "physicalRampDeckTransitionLengthM");
    let transition = _physical_ramp_transition_ops(doc, edit_target,
        lander_root, ramp_path, side, transition_length, thickness, width, surface_y);
    if !transition.ok { return transition; }
    for op in transition.ops { ops.push(op); }
    #{ok: true, kind: "griffin_articulated_physical_ramp",
      root: ramp_path, side: side, section_count: section_count,
      section_length_m: section_length, mass_per_section_kg: section_mass,
      root_hinge_path: root_joint_path, intermediate_joint_names: joint_names,
      paths: [ramp_path, middle_path, toe_path], ops: ops,
      no_op: ops.len() == 0}
}

fn apply_isolated_griffin_physical_ramp_geometry(doc, edit_target,
    lander_root, side, parent_gen) {
    let plan = isolated_griffin_physical_ramp_geometry_plan(doc, edit_target,
        lander_root, side);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Reconcile Griffin " + side + " articulated physical ramp", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: plan.root, side: side, section_count: plan.section_count,
      section_length_m: plan.section_length_m}
}

/// Build one ramp, its hinge datum, and its typed mount relation.  This is the
/// preferred entry point when an agent is refining the ramp in the Editor;
/// the full-vehicle plan is only a convenience that composes these same
/// operations.   is deliberately explicit so port/starboard cannot be
/// accidentally edited together.
fn isolated_griffin_ramp_plan(doc, edit_target, root, side) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("isolated_griffin_ramp_plan requires a document, edit target, and absolute root");
    }
    let spec = _isolated_ramp_spec(root, side);
    if spec == () { return plan_error("ramp side must be port or starboard"); }
    let component = _isolated_component_plan(doc, edit_target, spec);
    if !component.ok { return component; }
    let path = spec.parent + "/" + spec.name;
    let ops = [];
    for op in component.ops { ops.push(op); }
    let details = _isolated_griffin_detail_specs(root);
    for detail in details {
        if detail.parent != path { continue; }
        let detail_path = detail.parent + "/" + detail.name;
        if query_ok(assembly_builder::composed_query(doc, #{path: detail_path, children: false})) { continue; }
        let detail_plan = _detail_ops(edit_target, detail);
        if !detail_plan.ok { return detail_plan; }
        for op in detail_plan.ops { ops.push(op); }
    }
    for op in _isolated_ramp_contract_ops(edit_target, path, side) { ops.push(op); }
    let geometry = _isolated_ramp_visual_geometry_ops(doc, edit_target, path, side);
    if !geometry.ok { return geometry; }
    for op in geometry.ops { ops.push(op); }
    let socket = root + "/Bus/RampSocket" + (if side == "port" { "Port" } else { "Starboard" });
    let frame = path + "/MountFrame";
    let hinge_x = _ramp_number("rampHingeOffsetX");
    let hinge_y = _ramp_number("rampHingeOffsetY");
    let hinge_z = _ramp_number("rampHingeOffsetZ");
    let angle_deg = _ramp_angle_deg(side);
    if hinge_x == () || hinge_y == () || hinge_z == () || angle_deg == () {
        return plan_error("ramp SysML hinge datum is missing");
    }
    let frame_spec = #{parent: path, name: "MountFrame", translation: [hinge_x, hinge_y, hinge_z],
        rotation: if side == "port" { [0.0, 0.0, angle_deg] } else { [0.0, 180.0, angle_deg] }, socket: false};
    let frame_plan = _mount_frame_ops(doc, edit_target, frame_spec, root);
    if !frame_plan.ok { return frame_plan; }
    for op in frame_plan.ops { ops.push(op); }
    ops.push(#{SetRelationship: #{edit_target: edit_target, path: path,
        name: "lunco:mount:frame", targets: [frame]}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "lunco:mount:plug", type_name: "token", value: "\"egress_ramp\""}});
    let socket_exists = assembly_builder::composed_query(doc, #{path: socket, children: false});
    if query_ok(socket_exists) {
        // Keep the existing socket transform synchronized with the current
        // SysML datum.  The older visual source carried the pre-refinement
        // 2.60 m / -1.10 m opinion; updating only the ramp root left a stale
        // relationship in the Editor tree even though the rendered body had
        // moved.  This is a typed assembly-layer opinion, so it remains
        // idempotent and does not touch the component USDA.
        let socket_x = _ramp_number("rampSocketX");
        let socket_y = _ramp_number("rampSocketY");
        let socket_z = _ramp_number("rampSocketZ");
        if socket_x == () || socket_y == () || socket_z == () {
            return plan_error("ramp SysML socket datum is missing");
        }
        let socket_place = assembly_builder::place_plan(edit_target, socket,
            [if side == "port" { socket_x } else { -socket_x }, socket_y, socket_z], (), ());
        if !socket_place.ok { return socket_place; }
        for op in socket_place.ops { ops.push(op); }
        // Some older referenced socket opinions are represented as an
        // inherited xform rather than a local transform.  The generic
        // placement planner can therefore emit no transform op even though
        // the component task must make the new socket datum durable.  This
        // is still a typed Editor operation, and remains idempotent on save.
        ops.push(#{SetTranslate: #{edit_target: edit_target, path: socket,
            value: [if side == "port" { socket_x } else { -socket_x }, socket_y, socket_z]}});
        ops.push(#{SetRelationship: #{edit_target: edit_target, path: socket,
            name: "lunco:mount:part", targets: [path]}});
        ops.push(#{SetApiSchemas: #{edit_target: edit_target, path: socket,
            schemas: ["LunCoMountSocketAPI"]}});
    }
    #{ok: true, kind: "griffin_isolated_ramp_assembly", root: root, side: side,
      path: path, component_count: 1, ops: ops, no_op: ops.len() == 0}
}

fn apply_isolated_griffin_ramp(doc, edit_target, root, side, parent_gen) {
    let plan = isolated_griffin_ramp_plan(doc, edit_target, root, side);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build isolated Griffin " + side + " ramp", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      component_count: plan.component_count, root: root, side: side}
}

// Reconcile a referenced ramp instance after the old assembly-layer overlay
// recipe has been removed. The component file owns paired RampTrack geometry,
// rails, treads, support members, and the mount frame; the assembly owns only the
// instance transform and state.  This plan removes authored child opinions
// from the assembly layer so the referenced component becomes the single
// geometry owner, then applies the typed stowed pose with SetScale so the
// scale is included in xformOpOrder rather than sitting as an inert custom
// attribute.
fn normalize_griffin_visual_ramp_plan(doc, edit_target, root, side) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("normalize_griffin_visual_ramp_plan requires a document, edit target, and absolute root");
    }
    if side != "port" && side != "starboard" {
        return plan_error("ramp side must be port or starboard");
    }
    let ramp_state = griffin_spec::visual_ramp_state();
    if !sysml_enum_is(ramp_state) || ramp_state.literal != "Stowed" {
        return plan_error("visual ramp review state must be SysML stowed");
    }
    let mount_xs = griffin_spec::visual_ramp_mount_x();
    let mount_y = griffin_spec::visual_ramp_mount_y();
    let mount_z = griffin_spec::visual_ramp_mount_z();
    let scale = griffin_spec::visual_ramp_stowed_scale();
    let rotation = griffin_spec::visual_ramp_stowed_rotation(side);
    let child_names = griffin_spec::visual_ramp_child_names();
    if mount_xs.len() != 2 || mount_y == () || mount_z == () || scale == ()
        || scale <= 0.0 || rotation.len() != 3 || child_names.len() == 0 {
        return plan_error("stowed ramp transform or component child contract is incomplete");
    }
    let instance_x = if side == "port" { mount_xs[0] } else { mount_xs[1] };
    let ops = [];
    // The parent layer may contain local specs for referenced children.  A
    // RemovePrim here removes only that authored overlay; the referenced
    // component remains composed at the same path and becomes authoritative.
    for name in child_names {
        let path = root + "/" + name;
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) {
            ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
        }
    }
    let placement = assembly_builder::place_plan(edit_target, root,
        [instance_x, mount_y, mount_z], rotation, [scale, scale, scale]);
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
    for item in [
        #{name: "lunco:visual:ramp_state", type_name: "token", value: "\"stowed\""},
        #{name: "lunco:visual:ramp_geometry_owner", type_name: "token", value: "\"component\""},
        #{name: "lunco:visual:ramp_deployed_length_m", type_name: "double",
          value: _ramp_number("rampSurfaceLengthM").to_string()},
        #{name: "lunco:visual:ramp_deployed_width_m", type_name: "double",
          value: _ramp_number("rampSurfaceWidthM").to_string()},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    #{ok: true, kind: "griffin_visual_ramp_component_reconciliation", root: root,
      side: side, state: "stowed", instance_x_m: instance_x,
      scale: scale, rotation: rotation, removed_overlay_children: child_names.len(),
      ops: ops, no_op: ops.len() == 0}
}

fn apply_normalize_griffin_visual_ramp(doc, edit_target, root, side, parent_gen) {
    let plan = normalize_griffin_visual_ramp_plan(doc, edit_target, root, side);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Make Griffin " + side + " ramp a component-owned stowed instance",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, side: side, state: plan.state,
      removed_overlay_children: plan.removed_overlay_children}
}

// Replace obsolete inline flight-model render primitives with references to
// the same maintained component assets used by the visual review assembly.
// Engine and solar stations are read from GriffinVisualConfiguration; shared
// component files remain the only owners of their shapes and dimensions.
fn _migrate_griffin_component_reference(doc, edit_target, parent, name,
    asset, asset_root, translation, rotation, scale, required_children) {
    let path = parent + "/" + name;
    let existing = assembly_builder::composed_query(doc,
        #{path: path, children: true});
    if query_ok(existing) && existing.type_name == "Xform"
        && existing.children != () {
        let complete = true;
        for child in required_children {
            if !existing.children.contains(path + "/" + child) {
                complete = false;
            }
        }
        if complete {
            let placement = assembly_builder::place_plan(edit_target, path,
                translation, rotation, scale);
            if !placement.ok { return placement; }
            return #{ok: true, path: path, ops: placement.ops,
                replaced: false};
        }
    }

    let ops = [];
    if query_ok(existing) {
        ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
    }
    let temporary_name = "__GriffinComponentMigration_" + name;
    let temporary_path = parent + "/" + temporary_name;
    let temporary = assembly_builder::composed_query(doc,
        #{path: temporary_path, children: false});
    if query_ok(temporary) {
        ops.push(#{RemovePrim: #{edit_target: edit_target,
            path: temporary_path}});
    }
    let reference = assembly_builder::referenced_instance_targeted_plan(
        doc, edit_target, parent, temporary_name, "Xform", asset,
        asset_root, translation, rotation, scale, (), ());
    if !reference.ok { return reference; }
    for op in reference.ops { ops.push(op); }
    ops.push(#{MovePrim: #{edit_target: edit_target,
        from_path: temporary_path, to_path: path}});
    #{ok: true, path: path, ops: ops, replaced: true}
}

fn migrate_griffin_physical_visuals_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("migrate_griffin_physical_visuals_plan requires a document, edit target, and absolute root");
    }
    let solar_names = griffin_spec::solar_array_names();
    let solar_stations = griffin_spec::component_solar_stations();
    let solar_rot_x = griffin_spec::component_solar_station_rotation_x_deg();
    let solar_rot_z = griffin_spec::component_solar_station_rotation_z_deg();
    let solar_widths = griffin_spec::component_solar_array_widths_m();
    let solar_frame_width = griffin_spec::solar_panel_frame_width_m();
    let engine_names = griffin_spec::main_engine_names();
    let engine_stations = griffin_spec::component_engine_stations();
    let solar_members = griffin_spec::solar_component_child_names();
    let engine_members = griffin_spec::main_engine_component_child_names();
    let skirt_name = griffin_spec::engine_skirt_component_root_name();
    let skirt_members = griffin_spec::engine_skirt_component_member_names();
    let skirt_shell = griffin_spec::engine_skirt_component_shell_name();
    let skirt_adapter = griffin_spec::engine_skirt_component_adapter_name();
    let skirt_y = griffin_spec::visual_engine_skirt_mount_y();
    skirt_members.push(skirt_shell);
    skirt_members.push(skirt_adapter);
    if solar_names.len() != griffin_spec::solar_array_count() || solar_names.len() == 0
        || solar_stations.len() != solar_names.len()
        || solar_rot_x.len() != solar_names.len()
        || solar_rot_z.len() != solar_names.len()
        || solar_widths.len() != solar_names.len() || solar_frame_width == ()
        || engine_names.len() != 7 || engine_stations.len() != engine_names.len()
        || engine_members.len() != 2 || skirt_name == () || skirt_name == ""
        || skirt_members.len() != 6 || skirt_y == () {
        return plan_error("typed Griffin leg, solar, or propulsion stations are incomplete");
    }
    let ops = [];
    let migrated = [];
    let solar_asset = component_asset("lander/griffin_solar_panel_visual.usda");
    for index in 0..solar_names.len() {
        let result = _migrate_griffin_component_reference(doc, edit_target,
            root, solar_names[index], solar_asset, "/SolarPanel",
            vec3_array(solar_stations[index]),
            [solar_rot_x[index], 0.0, solar_rot_z[index]],
            [solar_widths[index] / solar_frame_width, 1.0, 1.0],
            solar_members);
        if !result.ok { return result; }
        for op in result.ops { ops.push(op); }
        migrated.push(result.path);
    }
    let engine_parent = root + "/Nozzle/MainEngineCluster";
    let engine_asset = component_asset("lander/griffin_engine_bell_visual.usda");
    for index in 0..engine_names.len() {
        let result = _migrate_griffin_component_reference(doc, edit_target,
            engine_parent, engine_names[index], engine_asset, "/EngineBell",
            vec3_array(engine_stations[index]), (), (), engine_members);
        if !result.ok { return result; }
        for op in result.ops { ops.push(op); }
        migrated.push(result.path);
    }

    let skirt_asset = component_asset("lander/griffin_engine_skirt_visual.usda");
    let skirt_result = _migrate_griffin_component_reference(doc, edit_target,
        engine_parent, skirt_name, skirt_asset, "/World/EngineSkirt",
        [0.0, skirt_y, 0.0], (), (), skirt_members);
    if !skirt_result.ok { return skirt_result; }
    for op in skirt_result.ops { ops.push(op); }
    migrated.push(skirt_result.path);

    // MainEngineVisual remains the flight force actuator. Its seven guide
    // cones were a second, non-source-owned nozzle layout and are obsolete.
    let actuator = root + "/MainEngineVisual";
    for name in ["NozzleCenter", "NozzlePX", "NozzleNX", "NozzlePZ",
        "NozzleNZ", "NozzleDiagP", "NozzleDiagN"] {
        let path = actuator + "/" + name;
        if query_ok(assembly_builder::composed_query(doc,
            #{path: path, children: false})) {
            ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
        }
    }
    let nozzle = root + "/Nozzle";
    let nozzle_record = assembly_builder::composed_query(doc,
        #{path: nozzle, attrs: ["lunco:parameter_status",
            "lunco:provenance:source"], children: false});
    if query_ok(nozzle_record) && nozzle_record.attrs != () {
        for name in ["lunco:parameter_status", "lunco:provenance:source"] {
            if nozzle_record.attrs[name] != () {
                ops.push(#{RemoveAttribute: #{edit_target: edit_target,
                    path: nozzle, name: name}});
            }
        }
    }
    #{ok: true, kind: "griffin_physical_visual_component_migration",
      root: root, migrated_paths: migrated, ops: ops,
      no_op: ops.len() == 0}
}

fn apply_migrated_griffin_physical_visuals(doc, edit_target, root, parent_gen) {
    let plan = migrate_griffin_physical_visuals_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Migrate Griffin solar arrays and main engines to shared components",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: root,
      migrated_paths: plan.migrated_paths, command: command}
}

fn apply_isolated_griffin(doc, edit_target, root, parent_gen) {
    let plan = isolated_griffin_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build isolated Griffin visual", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      component_count: plan.component_count, root: root}
}

// Standard terrain presentation -------------------------------------------
//
// The visual-review scene used to rely on a dark, flat RegolithPad proxy.  It
// is useful as a dimension guide, but it must not be the visible terrain when
// the Twin has a source-backed terrain asset.  This plan mounts the same
// South-Pole surrogate used by the mission scene and hides the guide pad
// through typed, journaled opinions.  The terrain asset owns its
// LunCoTerrainAPI, DEM layer, physics material, and terrain_layered.wgsl
// binding; this helper only owns the review-scene composition decision.
fn standard_terrain_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("standard_terrain_plan requires a document, edit target, and absolute root");
    }
    let asset = griffin_spec::visual_terrain_asset();
    let shader = griffin_spec::visual_terrain_shader_asset();
    if asset == () || asset == "" || shader == () || shader == "" {
        return plan_error("visual terrain asset and shader identities are missing from SysML");
    }
    if !asset.starts_with("twin://") && !asset.starts_with("lunco://") {
        return plan_error("visual terrain asset must be a logical twin:// or lunco:// URI");
    }
    if !shader.starts_with("lunco://") {
        return plan_error("visual terrain shader must be a canonical lunco:// shader URI");
    }

    let environment = root + "/Environment";
    let existing = assembly_builder::composed_query(doc, #{path: environment, children: false});
    let ops = [];
    if query_ok(existing) {
        if existing.type_name != "Xform" {
            return plan_error(environment + ": existing terrain owner must be an Xform");
        }
        // A pre-existing owner is accepted only when it already composes the
        // standard terrain child.  Do not silently overwrite another asset.
        let terrain = assembly_builder::composed_query(doc,
            #{path: environment + "/Terrain", children: false});
        if !query_ok(terrain) {
            return plan_error(environment + ": existing owner does not contain the standard Terrain prim");
        }
    } else {
        let reference = assembly_builder::referenced_instance_targeted_plan(
            doc, edit_target, root, "Environment", "Xform", asset,
            (), (), (), (), (), ());
        if !reference.ok { return reference; }
        for op in reference.ops { ops.push(op); }
    }

    // Preserve the guide's authored dimensions for measurement checks, but
    // make it invisible so it cannot occlude the standard terrain or create a
    // second visual surface.  Its render purpose and disabled collision remain
    // inspectable evidence of the review-only guide contract.
    let guide = root + "/Ground/RegolithPad";
    let guide_record = assembly_builder::composed_query(doc, #{path: guide, children: false});
    if query_ok(guide_record) {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: guide,
            name: "visibility", type_name: "token", value: "\"invisible\""}});
    }
    // The source terrain asset contains two optional synthetic berm markers
    // for mission-scale route studies.  They are not part of the visual
    // vehicle context and their 12–16 m radii can dominate a component review
    // frame.  Keep the DEM and canonical terrain shader visible, but hide
    // these optional markers in the vehicle review layer through reversible
    // typed opinions.
    for berm in [environment + "/VisualBerms/BermEast",
                 environment + "/VisualBerms/BermWest"] {
        let berm_record = assembly_builder::composed_query(doc, #{path: berm, children: false});
        if query_ok(berm_record) {
            ops.push(#{SetAttribute: #{edit_target: edit_target, path: berm,
                name: "visibility", type_name: "token", value: "\"invisible\""}});
        }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:terrain_mode", type_name: "token",
        value: "\"standard_layered\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:terrain_asset", type_name: "asset",
        value: "@" + asset + "@"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:terrain_shader", type_name: "asset",
        value: "@" + shader + "@"}});
    #{ok: true, kind: "standard_lunar_terrain", root: root,
      environment: environment, asset: asset, shader: shader,
      ops: ops, no_op: ops.len() == 0}
}

fn apply_standard_terrain(doc, edit_target, root, parent_gen) {
    let plan = standard_terrain_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Use standard layered lunar terrain", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, environment: plan.environment, asset: plan.asset,
      shader: plan.shader}
}
