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

// Remove obsolete Twin-local visual annotations from the Editor-owned layer.
// Geometry and behavior are defined by typed SysML values plus authored USD
// geometry/transforms; custom visual strings are not a second source of truth.
fn _clear_bus_label_ops(doc, edit_target, path, ops) {
    let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
    if !query_ok(prim) || prim.attrs == () { return; }
    for name in prim.attrs.keys() {
        if name.starts_with("lunco:visual:") {
            ops.push(#{RemoveAttribute: #{edit_target: edit_target, path: path, name: name}});
        }
    }
}

fn _clear_bus_label_tree(doc, edit_target, path, ops) {
    let prim = assembly_builder::composed_query(doc, #{path: path, children: true});
    if !query_ok(prim) { return; }
    _clear_bus_label_ops(doc, edit_target, path, ops);
    if prim.children != () {
        for child_path in prim.children {
            _clear_bus_label_tree(doc, edit_target, child_path, ops);
        }
    }
}

fn absolute_root(root) {
    root != () && type_of(root) == "string" && root != ""
        && root.starts_with("/") && !(root.ends_with("/") && root != "/")
}

fn component_asset(relative) {
    "twin://" + twin_name() + "/components/" + relative
}

fn _sysml_number(report, name) {
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

fn flip_steering_angles() {
    let report = sysml_requirements::source();
    let front = _sysml_number(report, "frontSteeringAngleDeg");
    let rear = _sysml_number(report, "rearSteeringAngleDeg");
    if front == () || rear == () { return (); }
    [front, rear]
}

fn _visual_component_parent(root, record) {
    if record.parent_role == "lander" { return root + "/Griffin1"; }
    if record.parent_role == "rover" { return root + "/FLIP"; }
    if record.parent_role == "wheel" {
        return root + "/FLIP/Suspension_" + record.station;
    }
    root + "/Griffin1/Nozzle/MainEngineCluster"
}

// Native spatial values remain native until this final command adapter. The
// USD editor command currently accepts its compatibility array form, so the
// lowering is explicit and local rather than leaking array reconstruction into
// every component recipe.
fn _visual_component_spec(root, record) {
    let scale = if record.scale_enabled { vec3_array(record.pose.scale) } else { () };
    #{parent: _visual_component_parent(root, record), name: record.name,
      type_name: "Xform", asset: component_asset(record.asset),
      translation: vec3_array(record.pose.translation),
      rotation: vec3_array(quat_to_euler_xyz_deg(record.pose.rotation)), scale: scale}
}

fn visual_component_specs(root) {
    let records = griffin_spec::visual_component_transform_plan();
    if records.len() == 0 { return []; }
    let specs = [];
    for record in records { specs.push(_visual_component_spec(root, record)); }
    specs
}

fn _color_literal(color) {
    "[(" + color[0].to_string() + ", " + color[1].to_string()
        + ", " + color[2].to_string() + ")]"
}

// Detail geometry is authored in the assembly document through typed
// AddPrim/SetAttribute operations.  It is deliberately separate from the
// replaceable component assets: a renderer can replace the bus/chassis asset
// without losing the semantic placement recipe or adding a second USD writer.
fn visual_detail_specs(root) {
    let lander = root + "/Griffin1";
    let bus = lander + "/Bus";
    let cluster = lander + "/Nozzle/MainEngineCluster";
    let details = [];
    // Rail identity, stations, and envelope are already one native typed plan;
    // only the primitive command's array wire format is produced here.
    for rail in griffin_spec::visual_rail_station_plan() {
        details.push(#{parent: bus, name: rail.name, shape: "cube",
            translation: vec3_array(rail.pose.translation), scale: vec3_array(rail.pose.scale),
            color: [0.16, 0.18, 0.21]});
    }
    for detail in [
        // The engine skirt is a four-beam frame around the seven bells; it
        // keeps the nozzles visually attached to the lower bus deck.
        #{parent: cluster, name: "EngineSkirtFront", shape: "cube", translation: [0.0, 1.68, 1.50], scale: [3.20, 0.20, 0.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtRear", shape: "cube", translation: [0.0, 1.68, -1.50], scale: [3.20, 0.20, 0.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtPort", shape: "cube", translation: [1.50, 1.68, 0.0], scale: [0.20, 0.20, 3.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtStarboard", shape: "cube", translation: [-1.50, 1.68, 0.0], scale: [0.20, 0.20, 3.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineAdapterPlate", shape: "cube", translation: [0.0, 1.76, 0.0], scale: [2.84, 0.12, 2.84], color: [0.18, 0.20, 0.23]},
        // Hinge plates and pins are assembly-owned mounting evidence.  The
        // component origin remains untouched; the parent transform places the
        // ramp surface against the bus side.
        #{parent: lander + "/EgressRampPort", name: "MountPlate", shape: "cube", translation: [0.70, 0.0, 0.0], scale: [0.12, 0.22, 0.92], color: [0.12, 0.14, 0.17]},
        #{parent: lander + "/EgressRampPort", name: "HingePin", shape: "cylinder", translation: [0.70, 0.0, 0.0], radius: 0.12, height: 0.92, axis: "Z", color: [0.10, 0.12, 0.15]},
        #{parent: lander + "/EgressRampStarboard", name: "MountPlate", shape: "cube", translation: [0.70, 0.0, 0.0], scale: [0.12, 0.22, 0.92], color: [0.12, 0.14, 0.17]},
        #{parent: lander + "/EgressRampStarboard", name: "HingePin", shape: "cylinder", translation: [0.70, 0.0, 0.0], radius: 0.12, height: 0.92, axis: "Z", color: [0.10, 0.12, 0.15]},
        // FLIP's camera pod gets a lens barrel and the chassis gets side
        // guards, making the four-wheel directional rover legible at a glance.
        #{parent: root + "/FLIP/Chassis", name: "SideGuardLeft", shape: "cube", translation: [-1.98, 0.36, 0.0], scale: [0.08, 0.42, 1.18], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/FLIP/Chassis", name: "SideGuardRight", shape: "cube", translation: [1.98, 0.36, 0.0], scale: [0.08, 0.42, 1.18], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/FLIP/SensorMast", name: "SensorLens", shape: "cylinder", translation: [0.0, 1.88, -0.55], radius: 0.12, height: 0.16, axis: "Z", color: [0.04, 0.08, 0.12]},
    ] { details.push(detail); }
    // USD Cone exposes radius1/radius2 while the current lightweight viewer
    // uses one effective radius. Keep a thin typed collar at every bell so
    // the engine throat remains legible at every mesh quality.
    for entry in griffin_spec::main_engine_names() {
        details.push(#{parent: cluster + "/" + entry, name: "BellCollar", shape: "cylinder",
            translation: [0.0, -0.23, 0.0], radius: 0.38, height: 0.08, axis: "Y",
            color: [0.24, 0.27, 0.31]});
    }
    details
}

fn _engine_radius_ops(edit_target, root) {
    let cluster = root + "/Griffin1/Nozzle/MainEngineCluster";
    let ops = [];
    // Keep the standard radius1/radius2 opinions in the component asset while
    // providing an explicit effective radius to the lightweight primitive
    // viewer until frustum tessellation is available there.
    for entry in griffin_spec::main_engine_names() {
        ops.push(#{SetAttribute: #{edit_target: edit_target,
            path: cluster + "/" + entry + "/Bell", name: "radius1",
            type_name: "float", value: "0.34"}});
        ops.push(#{SetAttribute: #{edit_target: edit_target,
            path: cluster + "/" + entry + "/Bell", name: "radius2",
            type_name: "float", value: "0.16"}});
        ops.push(#{SetAttribute: #{edit_target: edit_target,
            path: cluster + "/" + entry + "/Bell", name: "radius",
            type_name: "double", value: "0.34"}});
    }
    ops
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

/// Return a dry, idempotent typed plan for the visual components. All parent
/// frames must already exist in the target document; this avoids guessing
/// authored namespace ownership and makes a stale target fail before submit.
fn visual_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("visual_component_plan requires a document, edit target, and absolute root");
    }
    let specs = visual_component_specs(root);
    if specs.len() == 0 {
        return plan_error("cannot build visual assembly: required SysML FLIP steering angles are missing");
    }
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
    let rover = root + "/FLIP";
    // Keep the four wheel station roots in the same authored frame as the
    // SysML source.  This is separate from adding the wheel instance so a
    // source vehicle with stale station transforms is corrected idempotently.
    let wheel_names = griffin_spec::visual_rover_wheel_names();
    let wheel_x = griffin_spec::rover_wheel_station_x();
    let wheel_y = griffin_spec::rover_wheel_station_y();
    let wheel_z = griffin_spec::rover_wheel_station_z();
    if wheel_names.len() != 4 || wheel_x.len() != 4 || wheel_y.len() != 4 || wheel_z.len() != 4 {
        return plan_error("FLIP wheel station datums must contain four entries");
    }
    for index in 0..wheel_names.len() {
        let station = rover + "/Suspension_" + wheel_names[index];
        let placement = assembly_builder::place_plan(edit_target, station,
            [wheel_x[index], wheel_y[index], wheel_z[index]], (), ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    // Deactivate obsolete middle stations from older six-wheel visual
    // revisions through a reversible authored opinion.  RemovePrim would be
    // invalid here because those children are owned by the referenced vehicle
    // source layer; SetActive is the generic USD override for that case.
    for obsolete in [rover + "/Suspension_ML", rover + "/Suspension_MR"] {
        let old = assembly_builder::composed_query(doc, #{path: obsolete, children: false});
        if query_ok(old) {
            ops.push(#{SetActive: #{edit_target: edit_target, path: obsolete, active: false}});
        }
    }
    let detail_paths = [];
    let detail_added = [];
    // A warm MLI-white finish is an authored visual opinion on the referenced
    // mesh, keeping the faceted bus readable against the dark service skirt.
    ops.push(#{SetAttribute: #{edit_target: edit_target,
        path: root + "/Griffin1/Bus/WhiteEquipmentBox",
        name: "primvars:displayColor", type_name: "color3f[]",
        value: "[(0.72, 0.74, 0.77)]"}});
    // Keep the presentation contract in the authored assembly layer even
    // though the referenced source asset predates the four-wheel study.
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: rover,
        name: "lunco:visual:wheel_count", type_name: "int", value: "4"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: rover,
        name: "lunco:visual:configuration", type_name: "string",
        value: "four directional wheels, white equipment box, sensor mast, fixed solar-array proxy"}});
    for detail in visual_detail_specs(root) {
        let path = detail.parent + "/" + detail.name;
        detail_paths.push(path);
        let existing_detail = assembly_builder::composed_query(doc, #{path: path, children: false});
        if query_ok(existing_detail) {
            continue;
        }
        let detail_plan = _detail_ops(edit_target, detail);
        if !detail_plan.ok { return detail_plan; }
        detail_added.push(path);
        for op in detail_plan.ops { ops.push(op); }
    }
    for op in _engine_radius_ops(edit_target, root) { ops.push(op); }
    #{ok: true, kind: "griffin_visual_component_assembly", root: root,
      component_count: specs.len(), paths: paths, existing: existing, added: added,
      detail_paths: detail_paths, detail_added: detail_added,
      no_op: ops.len() == 0, ops: ops}
}

/// Apply one dry plan through LunCoSim's journaled USD command. The command
/// remains asynchronous; callers should poll its acknowledgement and then
/// query the same document generation for visual acceptance.
fn apply_visual_components(doc, edit_target, root, parent_gen) {
    let plan = visual_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build componentized Griffin and FLIP visuals",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: root,
      component_count: plan.component_count, added: plan.added,
      command: command}
}

// The physical FLIP source and the review-only FLIP visual intentionally use
// different station datums.  Apply the physical values as local, typed
// assembly opinions in the current scene: this keeps the replaceable vehicle
// source untouched while making the raycast support envelope reproducible.
// The station order is owned by SysML FlipRover::visualWheelNames.
fn physical_flip_station_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("physical_flip_station_plan requires a document, edit target, and absolute root");
    }
    let names = griffin_spec::visual_rover_wheel_names();
    let xs = griffin_spec::physical_rover_wheel_station_x();
    let ys = griffin_spec::physical_rover_wheel_station_y();
    let zs = griffin_spec::physical_rover_wheel_station_z();
    let rest_length = griffin_spec::physical_suspension_rest_length_m();
    if names.len() != 4 || xs.len() != 4 || ys.len() != 4 || zs.len() != 4
        || rest_length == () || rest_length <= 0.0 {
        return plan_error("physical FLIP wheel station datums must contain four entries");
    }
    let rover = root + "/FLIP";
    let ops = [];
    let paths = [];
    for index in 0..names.len() {
        let path = rover + "/Suspension_" + names[index];
        let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
        if !query_ok(prim) || prim.type_name != "Xform" {
            return plan_error(path + ": physical FLIP station must be an existing Xform");
        }
        let placement = assembly_builder::place_plan(edit_target, path,
            [xs[index], ys[index], zs[index]], (), ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        let wheel = path + "/Wheel_" + names[index];
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: wheel,
            name: "lunco:suspension:restLength", type_name: "float",
            value: rest_length.to_string()}});
        paths.push(path);
    }
    #{ok: true, kind: "flip_physical_station_support_envelope", root: rover,
      paths: paths, physical_station_x: xs, physical_station_y: ys,
      physical_station_z: zs, physical_suspension_rest_length_m: rest_length,
      ops: ops, no_op: ops.len() == 0}
}

fn apply_physical_flip_station_geometry(doc, edit_target, root, parent_gen) {
    let plan = physical_flip_station_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Author FLIP physical suspension support envelope", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: plan.root,
      paths: plan.paths, physical_station_y: plan.physical_station_y,
      physical_suspension_rest_length_m: plan.physical_suspension_rest_length_m,
      command: command}
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
// exception or a rover teleport.  All dimensions, placement, source, and
// rationale cross the typed SysML bridge; this function only projects them
// into the active scene through the journaled Editor command.
fn egress_apron_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("egress_apron_plan requires a document, edit target, and absolute root");
    }
    let name = griffin_spec::egress_apron_name();
    let requirement_id = griffin_spec::egress_apron_requirement_id();
    let cx = griffin_spec::egress_apron_center_x_m();
    let cy = griffin_spec::egress_apron_center_y_m();
    let cz = griffin_spec::egress_apron_center_z_m();
    let length = griffin_spec::egress_apron_length_m();
    let width = griffin_spec::egress_apron_width_m();
    let thickness = griffin_spec::egress_apron_thickness_m();
    let surface_y = griffin_spec::egress_apron_surface_y_m();
    if name == () || name == "" || requirement_id == () || requirement_id == ""
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
        name: "lunco:requirement", type_name: "token", value: "\"" + requirement_id + "\""}});
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

fn _isolated_flip_specs(root) {
    let steering = flip_steering_angles();
    let solar_mount = griffin_spec::rover_solar_array_mount();
    let solar_tilt = griffin_spec::rover_solar_array_tilt_deg();
    // The component's X-Z plane is already horizontal in the rover frame;
    // SysML's deck-relative tilt is therefore the direct X rotation.
    let solar_rotation = solar_tilt;
    let sensor_mount = griffin_spec::rover_sensor_mast_mount();
    if steering == () || solar_mount.len() != 3 || solar_tilt == () || sensor_mount.len() != 2 { return []; }
    let specs = [
        #{parent: root, name: "Chassis", type_name: "Xform",
          asset: component_asset("rover/flip_chassis_visual.usda"),
          translation: [0.0, 0.0, 0.0], rotation: (), scale: ()},
        #{parent: root, name: "SensorMast", type_name: "Xform",
          asset: component_asset("rover/flip_sensor_mast_visual.usda"),
          translation: [0.0, sensor_mount[0], sensor_mount[1]], rotation: (), scale: ()},
        #{parent: root, name: "SolarArray", type_name: "Xform",
          asset: component_asset("rover/flip_solar_panel_visual.usda"),
          translation: solar_mount, rotation: [solar_rotation, 0.0, 0.0], scale: ()},
    ];
    let names = griffin_spec::visual_rover_wheel_names();
    let wheel_x = griffin_spec::rover_wheel_station_x();
    let wheel_y = griffin_spec::rover_wheel_station_y();
    let wheel_z = griffin_spec::rover_wheel_station_z();
    if names.len() != 4 || wheel_x.len() != 4 || wheel_y.len() != 4 || wheel_z.len() != 4 { return []; }
    for index in 0..names.len() {
        let name = names[index];
        let steering_index = if name.starts_with("F") { 0 } else { 1 };
        let station = root + "/Suspension_" + name;
        specs.push(#{parent: station, name: "Wheel_" + name, type_name: "Xform",
            asset: component_asset("rover/flip_wheel_visual.usda"),
            translation: [0.0, 0.0, 0.0], rotation: [0.0, steering[steering_index], 0.0], scale: ()});
    }
    specs
}

fn _isolated_griffin_detail_specs(root) {
    let bus = root + "/Bus";
    let cluster = root + "/Nozzle/MainEngineCluster";
    let details = [];
    for rail in griffin_spec::visual_rail_station_plan() {
        details.push(#{parent: bus, name: rail.name, shape: "cube",
            translation: vec3_array(rail.pose.translation), scale: vec3_array(rail.pose.scale),
            color: [0.16, 0.18, 0.21]});
    }
    for detail in [
        // A dark adapter/skirt makes the seven engine bells read as one
        // mounted propulsion module instead of disconnected cones.
        #{parent: cluster, name: "EngineSkirtFront", shape: "cube", translation: [0.0, 1.68, 1.50], scale: [3.20, 0.20, 0.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtRear", shape: "cube", translation: [0.0, 1.68, -1.50], scale: [3.20, 0.20, 0.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtPort", shape: "cube", translation: [1.50, 1.68, 0.0], scale: [0.20, 0.20, 3.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtStarboard", shape: "cube", translation: [-1.50, 1.68, 0.0], scale: [0.20, 0.20, 3.20], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineAdapterPlate", shape: "cube", translation: [0.0, 1.76, 0.0], scale: [2.84, 0.12, 2.84], color: [0.18, 0.20, 0.23]},
        // Mount plate/pin at the actual ramp hinge datum.  This avoids the
        // old offset that left the ramp rail visibly detached from the bus.
        #{parent: root + "/EgressRampPort", name: "MountPlate", shape: "cube", translation: [1.60, 0.0, 0.0], scale: [0.12, 0.22, 0.92], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/EgressRampPort", name: "HingePin", shape: "cylinder", translation: [1.60, 0.0, 0.0], radius: 0.12, height: 0.92, axis: "Z", color: [0.10, 0.12, 0.15]},
        #{parent: root + "/EgressRampStarboard", name: "MountPlate", shape: "cube", translation: [1.60, 0.0, 0.0], scale: [0.12, 0.22, 0.92], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/EgressRampStarboard", name: "HingePin", shape: "cylinder", translation: [1.60, 0.0, 0.0], radius: 0.12, height: 0.92, axis: "Z", color: [0.10, 0.12, 0.15]},
    ] { details.push(detail); }
    for entry in griffin_spec::main_engine_names() {
        details.push(#{parent: cluster + "/" + entry, name: "BellCollar", shape: "cylinder",
            translation: [0.0, -0.23, 0.0], radius: 0.38, height: 0.08, axis: "Y",
            color: [0.24, 0.27, 0.31]});
    }
    details
}

fn _isolated_flip_detail_specs(root) {
    // Chassis guards and the sensor lens are presentation details of the FLIP
    // assembly itself.  Wheel suspension is deliberately not authored here:
    // it is a replaceable component with its own SysML contract and gate.
    [
        #{parent: root + "/Chassis", name: "SideGuardLeft", shape: "cube", translation: [-1.98, 0.36, 0.0], scale: [0.08, 0.42, 1.18], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/Chassis", name: "SideGuardRight", shape: "cube", translation: [1.98, 0.36, 0.0], scale: [0.08, 0.42, 1.18], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/SensorMast", name: "SensorLens", shape: "cylinder", translation: [0.0, 1.88, -0.55], radius: 0.12, height: 0.16, axis: "Z", color: [0.04, 0.08, 0.12]},
    ]
}

// One reusable suspension asset is instanced at every wheel station.  The
// canonical component points toward +X; right-hand stations mirror it with a
// typed 180-degree Y rotation.  Station positions remain owned by FlipRover.
fn _isolated_flip_suspension_specs(root) {
    let names = griffin_spec::visual_rover_wheel_names();
    let wheel_x = griffin_spec::rover_wheel_station_x();
    if names.len() != 4 || wheel_x.len() != names.len() {
        throw("FlipRequirements wheel station datums must contain four entries");
    }
    let specs = [];
    for index in 0..names.len() {
        let station = root + "/Suspension_" + names[index];
        specs.push(#{parent: station, name: "Suspension", type_name: "Xform",
            asset: component_asset("rover/flip_suspension_visual.usda"),
            translation: (),
            rotation: if wheel_x[index] < 0.0 { [0.0, 0.0, 0.0] } else { [0.0, 180.0, 0.0] },
            scale: ()});
    }
    specs
}

fn _isolated_details_plan(doc, edit_target, details) {
    let ops = [];
    let paths = [];
    for detail in details {
        let path = detail.parent + "/" + detail.name;
        paths.push(path);
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) { continue; }
        let plan = _detail_ops(edit_target, detail);
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    #{ok: true, paths: paths, ops: ops}
}

fn _isolated_engine_radius_ops(edit_target, root) {
    let ops = [];
    let cluster = root + "/Nozzle/MainEngineCluster";
    for entry in griffin_spec::main_engine_names() {
        // USD Cone radius1 is the -Y end.  The bell's wide lip belongs at the
        // nozzle exit (downward), with the narrow throat toward the deck.
        ops.push(#{SetAttribute: #{edit_target: edit_target,
            path: cluster + "/" + entry + "/Bell", name: "radius1",
            type_name: "float", value: "0.34"}});
        ops.push(#{SetAttribute: #{edit_target: edit_target,
            path: cluster + "/" + entry + "/Bell", name: "radius2",
            type_name: "float", value: "0.16"}});
        ops.push(#{SetAttribute: #{edit_target: edit_target,
            path: cluster + "/" + entry + "/Bell", name: "radius",
            type_name: "double", value: "0.34"}});
    }
    ops
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
    for op in _isolated_engine_radius_ops(edit_target, root) { ops.push(op); }
    let mount = _isolated_mount_ops(doc, edit_target, root);
    if !mount.ok { return mount; }
    for op in mount.ops { ops.push(op); }
    for side in ["port", "starboard"] {
        let ramp_path = root + "/EgressRamp" + (if side == "port" { "Port" } else { "Starboard" });
        for op in _isolated_ramp_contract_ops(edit_target, ramp_path, side) {
            ops.push(op);
        }
        let geometry = _isolated_ramp_visual_geometry_ops(doc, edit_target, ramp_path);
        if !geometry.ok { return geometry; }
        for op in geometry.ops { ops.push(op); }
    }
    #{ok: true, kind: "griffin_isolated_visual_assembly", root: root,
      component_count: specs.len(), paths: paths, ops: ops, no_op: ops.len() == 0}
}

fn _flip_suspension_cleanup_and_refs(doc, edit_target, root, names, ops, paths) {
    for name in names {
        let station = root + "/Suspension_" + name;
        // These struts were authored by the pre-component vehicle source.
        // Remove only an actually composed prim; a rejected source-layer edit
        // must remain a loud error rather than silently duplicating geometry.
        let obsolete = station + "/SuspensionStrut";
        if query_ok(assembly_builder::composed_query(doc, #{path: obsolete, children: false})) {
            ops.push(#{RemovePrim: #{edit_target: edit_target, path: obsolete}});
        }
    }
    for spec in _isolated_flip_suspension_specs(root) {
        let result = _component_plan(doc, edit_target, spec);
        if !result.ok { return result; }
        paths.push(result.path);
        for op in result.ops { ops.push(op); }
    }
    #{ok: true, ops: ops, paths: paths}
}

fn isolated_flip_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("isolated_flip_component_plan requires a document, edit target, and absolute root");
    }
    let specs = _isolated_flip_specs(root);
    if specs.len() == 0 { return plan_error("SysML FLIP visual parameters are missing"); }
    let ops = [];
    let paths = [];
    for spec in specs {
        let result = _isolated_component_plan(doc, edit_target, spec);
        if !result.ok { return result; }
        paths.push(result.path);
        for op in result.ops { ops.push(op); }
    }
    // Station roots are authored in the visual vehicle source.  Update those
    // roots through the same typed placement plan so the builder and verifier
    // consume the identical SysML datum rather than relying on stale source
    // transforms.
    let names = griffin_spec::visual_rover_wheel_names();
    let wheel_x = griffin_spec::rover_wheel_station_x();
    let wheel_y = griffin_spec::rover_wheel_station_y();
    let wheel_z = griffin_spec::rover_wheel_station_z();
    if names.len() != 4 || wheel_x.len() != 4 || wheel_y.len() != 4 || wheel_z.len() != 4 {
        return plan_error("FLIP wheel station datums must contain four entries");
    }
    for index in 0..names.len() {
        let station = root + "/Suspension_" + names[index];
        let placement = assembly_builder::place_plan(edit_target, station,
            [wheel_x[index], wheel_y[index], wheel_z[index]], (), ());
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    let suspension = _flip_suspension_cleanup_and_refs(doc, edit_target, root, names, ops, paths);
    if !suspension.ok { return suspension; }
    ops = suspension.ops;
    paths = suspension.paths;
    // The source vehicle predates the four-wheel SysML study.  Preserve its
    // authored history, but make the isolated presentation loud and typed.
    for obsolete in [root + "/Suspension_ML", root + "/Suspension_MR"] {
        if query_ok(assembly_builder::composed_query(doc, #{path: obsolete, children: false})) {
            ops.push(#{SetActive: #{edit_target: edit_target, path: obsolete, active: false}});
        }
    }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:wheel_count", type_name: "int", value: "4"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:configuration", type_name: "string",
        value: "four directional wheels, white equipment box, sensor mast, fixed solar-array proxy"}});
    for detail in _isolated_flip_detail_specs(root) {
        let path = detail.parent + "/" + detail.name;
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) { continue; }
        let result = _detail_ops(edit_target, detail);
        if !result.ok { return result; }
        for op in result.ops { ops.push(op); }
    }
    #{ok: true, kind: "flip_isolated_visual_assembly", root: root,
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
    if task == "Bus" { return parent.ends_with("/Bus"); }
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
    if task == "MainEngineCluster" {
        for op in _isolated_engine_radius_ops(edit_target, root) { ops.push(op); }
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
fn _hex_prism_geometry(width, depth, height) {
    let source_profile = griffin_spec::visual_hex_profile_coordinates();
    if source_profile.len() != 6 || width <= 0.0 || depth <= 0.0 || height <= 0.0 {
        return plan_error("hex prism requires six typed SysML profile points and positive dimensions");
    }
    let profile = [];
    for point in source_profile {
        if type_of(point) != "Vec2" || !vec2_is_finite(point) {
            return plan_error("hex profile coordinates must project as finite native Vec2 values");
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

fn _griffin_bus_number(source, name) {
    sysml_requirements::number(source,
        "GriffinBusRequirements::GriffinBusComponent::" + name)
}

// Resize an existing component-owned hex mesh in place.  The operation is
// deliberately a typed SetAttribute plan: the bus remains one replaceable
// component, while its dimensions stay visible in the SysML-backed builder
// rather than being hidden in a hand-edited USDA layer.
fn _resize_existing_hex_mesh_plan(doc, edit_target, path, width, depth, height) {
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    if !query_ok(current) || current.type_name != "Mesh" {
        return plan_error(path + ": expected an existing Mesh owned by the bus component");
    }
    let geometry = _hex_prism_geometry(width, depth, height);
    if !geometry.ok { return geometry; }
    let ops = [
        #{SetAttribute: #{edit_target: edit_target, path: path, name: "points",
            type_name: "point3f[]", value: _mesh_points_literal(geometry.points)}},
        #{SetAttribute: #{edit_target: edit_target, path: path, name: "faceVertexCounts",
            type_name: "int[]", value: _mesh_ints_literal(geometry.face_counts)}},
        #{SetAttribute: #{edit_target: edit_target, path: path, name: "faceVertexIndices",
            type_name: "int[]", value: _mesh_ints_literal(geometry.face_indices)}},
        #{SetAttribute: #{edit_target: edit_target, path: path, name: "subdivisionScheme",
            type_name: "token", value: "\"none\""}}
    ];
    #{ok: true, ops: ops}
}

fn _mesh_points_literal(points) {
    let literal = "[";
    for index in 0..points.len() {
        if index > 0 { literal += ", "; }
        literal += "(" + points[index][0].to_string() + ", "
            + points[index][1].to_string() + ", "
            + points[index][2].to_string() + ")";
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

// Build twelve individually closed beam solids as one replaceable airframe
// mesh: six upper and six lower perimeter members. Each beam uses a local
// right-handed (along, up, across) basis and outward-wound quad faces, so the
// open bays are real openings rather than a transparent/one-sided prism.
fn _hexagonal_open_frame_geometry(stations, station_order, ring_y, section) {
    let points = [];
    let face_counts = [];
    let face_indices = [];
    let half_section = section / 2.0;
    for ring_index in 0..ring_y.len() {
        for edge in 0..station_order.len() {
            let start_index = station_order[edge].to_int() - 1;
            let end_order_index = (edge + 1) % station_order.len();
            let end_index = station_order[end_order_index].to_int() - 1;
            if start_index < 0 || end_index < 0 || start_index >= stations.len()
                || end_index >= stations.len() {
                return plan_error("SysML perimeter station order is outside the typed rail vector");
            }
            let ax = stations[start_index].x;
            let az = stations[start_index].z;
            let bx = stations[end_index].x;
            let bz = stations[end_index].z;
            let dx = bx - ax;
            let dz = bz - az;
            let length = (dx * dx + dz * dz).sqrt();
            if length <= 0.0 { return plan_error("SysML perimeter contains a zero-length edge"); }
            let tx = dx / length;
            let tz = dz / length;
            let nx = -tz;
            let nz = tx;
            let mx = (ax + bx) / 2.0;
            let mz = (az + bz) / 2.0;
            let half_length = length / 2.0;
            let cy = ring_y[ring_index];
            let base = points.len();
            for vertex in [
                [-tx * half_length - nx * half_section, cy - half_section, -tz * half_length - nz * half_section],
                [ tx * half_length - nx * half_section, cy - half_section,  tz * half_length - nz * half_section],
                [ tx * half_length - nx * half_section, cy + half_section,  tz * half_length - nz * half_section],
                [-tx * half_length - nx * half_section, cy + half_section, -tz * half_length - nz * half_section],
                [-tx * half_length + nx * half_section, cy - half_section, -tz * half_length + nz * half_section],
                [ tx * half_length + nx * half_section, cy - half_section,  tz * half_length + nz * half_section],
                [ tx * half_length + nx * half_section, cy + half_section,  tz * half_length + nz * half_section],
                [-tx * half_length + nx * half_section, cy + half_section, -tz * half_length + nz * half_section]
            ] {
                points.push([mx + vertex[0], vertex[1], mz + vertex[2]]);
            }
            for face_index in 0..6 { face_counts.push(4); }
            for index in [0, 4, 7, 3, 1, 2, 6, 5, 0, 3, 2, 1,
                4, 5, 6, 7, 0, 1, 5, 4, 3, 7, 6, 2] {
                face_indices.push(base + index);
            }
        }
    }
    #{points: points, face_counts: face_counts, face_indices: face_indices}
}

fn _hexagonal_open_frame_mesh_plan(doc, edit_target, root, name, stations,
    station_order, ring_y, section) {
    let path = root + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let geometry = _hexagonal_open_frame_geometry(stations, station_order, ring_y, section);
    if geometry.ok == false { return geometry; }
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": open hexagonal frame must resolve to a Mesh");
        }
        ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: true}});
    } else {
        let shape = assembly_builder::mesh_shape_plan(edit_target, root, name,
            geometry.points, geometry.face_counts, geometry.face_indices,
            [0.55, 0.59, 0.64], false);
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
        value: _color_literal([0.55, 0.59, 0.64])}});
    #{ok: true, path: path, ops: ops,
      point_count: geometry.points.len(), face_count: geometry.face_counts.len()}
}

fn _refine_hex_slab(doc, edit_target, parent, name, width, depth, height, translation, color) {
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    if !query_ok(current) { return plan_error(path + ": bus slab is missing"); }
    // Referenced component children are owned by their source layer.  A
    // runtime assembly must not try to RemovePrim them from @root@ (that
    // would reject the whole compound edit).  Instead, mute the inherited
    // slab with a typed active opinion and add a sibling mesh owned by this
    // assembly.  This preserves source ownership while making the refinement
    // reversible and journaled.
    let replacement_name = name + "Hex";
    let replacement_path = parent + "/" + replacement_name;
    let replacement = assembly_builder::composed_query(doc, #{path: replacement_path, children: false});
    if query_ok(replacement) {
        if replacement.type_name != "Mesh" {
            return plan_error(replacement_path + ": existing refinement must be Mesh, got " + replacement.type_name);
        }
        return #{ok: true, path: replacement_path, ops: [], no_op: true};
    }
    if current.type_name != "Cube" && current.type_name != "Mesh" {
        return plan_error(path + ": expected the referenced slab to be Cube or Mesh, got " + current.type_name);
    }
    let geometry = _hex_prism_geometry(width, depth, height);
    if !geometry.ok { return geometry; }
    let mesh = assembly_builder::mesh_shape_plan(edit_target, parent, name,
        geometry.points, geometry.face_counts, geometry.face_indices, color, false);
    if !mesh.ok { return mesh; }
    // mesh_shape_plan targets the requested name, so retarget its operations
    // to the assembly-owned sibling before submission.
    let ops = [#{SetActive: #{edit_target: edit_target, path: path, active: false}}];
    for op in mesh.ops {
        if op.AddPrim != () {
            let add = op.AddPrim;
            add.name = replacement_name;
            add.parent_path = parent;
            ops.push(#{AddPrim: add});
        } else if op.SetAttribute != () {
            let attr = op.SetAttribute;
            attr.path = replacement_path;
            ops.push(#{SetAttribute: attr});
        } else if op.SetApiSchemas != () {
            let schema = op.SetApiSchemas;
            schema.path = replacement_path;
            ops.push(#{SetApiSchemas: schema});
        } else {
            ops.push(op);
        }
    }
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: replacement_path, value: translation}});
    #{ok: true, path: replacement_path, ops: ops, no_op: false}
}

fn refine_griffin_bus_component_plan(doc, edit_target, root) {
    // Keep the public refinement entry point on the same positive, typed
    // hexagonal contract as the component builder.  The old body below is
    // retained only as historical source context until the next cleanup; it
    // is unreachable and cannot author a competing geometry recipe.
    return hexagonal_griffin_bus_component_plan(doc, edit_target, root);
    /*
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_bus_component_plan requires a document, edit target, and absolute root");
    }
    let source = sysml_requirements::source();
    let width = _sysml_number(source, "bodyWidthM");
    let depth = _sysml_number(source, "bodyDepthM");
    let height = _sysml_number(source, "bodyHeightM");
    let frame_width = _griffin_bus_number(source, "perimeterFrameWidthM");
    let frame_depth = _griffin_bus_number(source, "perimeterFrameDepthM");
    let frame_height = _griffin_bus_number(source, "perimeterFrameHeightM");
    let equipment_width = _griffin_bus_number(source, "equipmentBodyWidthM");
    let equipment_depth = _griffin_bus_number(source, "equipmentBodyDepthM");
    let equipment_height = _griffin_bus_number(source, "equipmentBodyHeightM");
    let top_width = _griffin_bus_number(source, "topDeckWidthM");
    let top_depth = _griffin_bus_number(source, "topDeckDepthM");
    let top_thickness = _griffin_bus_number(source, "topDeckThicknessM");
    let top_y = _griffin_bus_number(source, "topDeckCenterYM");
    let avionics_width = _griffin_bus_number(source, "avionicsDeckWidthM");
    let avionics_depth = _griffin_bus_number(source, "avionicsDeckDepthM");
    let avionics_thickness = _griffin_bus_number(source, "avionicsDeckThicknessM");
    let avionics_y = _griffin_bus_number(source, "avionicsDeckCenterYM");
    if width == () || depth == () || height == () || frame_width == ()
        || frame_depth == () || frame_height == () || equipment_width == ()
        || equipment_depth == () || equipment_height == () || top_width == ()
        || top_depth == () || top_thickness == () || top_y == ()
        || avionics_width == () || avionics_depth == ()
        || avionics_thickness == () || avionics_y == ()
        || width <= 0.0 || depth <= 0.0 || height <= 0.0 {
        return plan_error("Griffin lander metric bus envelope is missing");
    }
    let ops = [];
    for mesh in [
        #{path: root + "/PerimeterFrame", width: frame_width, depth: frame_depth, height: frame_height},
        #{path: root + "/WhiteEquipmentBox", width: equipment_width, depth: equipment_depth, height: equipment_height},
        #{path: root + "/TopDeckHex", width: top_width, depth: top_depth, height: top_thickness},
        #{path: root + "/LowerServiceSkirtHex", width: width - 0.15, depth: depth - 0.15, height: 0.22}
    ] {
        let resize = _resize_existing_hex_mesh_plan(doc, edit_target, mesh.path,
            mesh.width, mesh.depth, mesh.height);
        if !resize.ok { return resize; }
        for op in resize.ops { ops.push(op); }
    }
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: root + "/TopDeckHex", value: [0.0, top_y, 0.0]}});
    ops.push(#{SetTranslate: #{edit_target: edit_target, path: root + "/LowerServiceSkirtHex", value: [0.0, -(height / 2.0 + 0.11), 0.0]}});
    let deck = assembly_builder::place_plan(edit_target, root + "/AvionicsDeck",
        [0.0, avionics_y, 0.0], (), [avionics_width, avionics_thickness, avionics_depth]);
    if !deck.ok { return deck; }
    for op in deck.ops { ops.push(op); }
    let pod = assembly_builder::place_plan(edit_target, root + "/AvionicsPod",
        [0.0, avionics_y + 0.21, 0.0], (), [0.72, 0.36, 0.72]);
    if !pod.ok { return pod; }
    for op in pod.ops { ops.push(op); }
    // The component's legacy detail layer was authored for the old 5.6 m
    // frame.  Keep those named details, but seat every one against the new
    // 4.50 m x 4.50 m x 2.00 m envelope so no rail or panel floats outside
    // the bus after the dimension correction.
    let detail_specs = [
        #{path: root + "/FrontThermalPanel", translation: [0.0, 0.0, 2.26], rotation: (), scale: [1.35, 0.65, 0.035]},
        #{path: root + "/FrontLogoRedA", translation: [-0.30, 0.0, 2.30], rotation: [0.0, 0.0, -18.0], scale: [0.08, 0.28, 0.04]},
        #{path: root + "/FrontLogoRedB", translation: [0.30, 0.0, 2.30], rotation: [0.0, 0.0, 18.0], scale: [0.08, 0.28, 0.04]},
        #{path: root + "/DeckRailFront", translation: [0.0, 1.19, 2.05], rotation: (), scale: [1.90, 0.06, 0.06]},
        #{path: root + "/ServiceBayPort", translation: [2.18, -0.12, -0.34], rotation: (), scale: [0.08, 0.35, 0.55]},
        #{path: root + "/ServiceBayStarboard", translation: [-2.18, -0.12, -0.34], rotation: (), scale: [0.08, 0.35, 0.55]},
        #{path: root + "/HexPanelFrontRight", translation: [1.125, 0.0, 1.6875], rotation: [0.0, 27.0, 0.0], scale: [1.26, 0.78, 0.06]},
        #{path: root + "/HexPanelRightRear", translation: [2.25, 0.0, 0.0], rotation: [0.0, 90.0, 0.0], scale: [1.26, 0.78, 0.06]},
        #{path: root + "/HexPanelRearRight", translation: [1.125, 0.0, -1.6875], rotation: [0.0, 153.0, 0.0], scale: [1.26, 0.78, 0.06]},
        #{path: root + "/HexPanelRearLeft", translation: [-1.125, 0.0, -1.6875], rotation: [0.0, 207.0, 0.0], scale: [1.26, 0.78, 0.06]},
        #{path: root + "/HexPanelLeftFront", translation: [-2.25, 0.0, 0.0], rotation: [0.0, 270.0, 0.0], scale: [1.26, 0.78, 0.06]},
        #{path: root + "/HexPanelFrontLeft", translation: [-1.125, 0.0, 1.6875], rotation: [0.0, 333.0, 0.0], scale: [1.26, 0.78, 0.06]}
    ];
    for detail in detail_specs {
        let placement = assembly_builder::place_plan(edit_target, detail.path,
            detail.translation, detail.rotation, detail.scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    #{ok: true, kind: "griffin_bus_hex_refinement", root: root,
      paths: [root + "/PerimeterFrame", root + "/WhiteEquipmentBox",
              root + "/TopDeckHex", root + "/LowerServiceSkirtHex",
              root + "/AvionicsDeck", root + "/AvionicsPod"],
      ops: ops, no_op: ops.len() == 0}
    */
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
    let command = assembly_edit::batch(doc, "Refine Griffin bus hexagonal shell", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

fn boxy_griffin_bus_component_plan(doc, edit_target, root) {
    // Compatibility name for existing scenario calls.  The implementation is
    // intentionally routed to the positive hexagonal component contract so an
    // old caller cannot recreate a box-shaped bus.
    return hexagonal_griffin_bus_component_plan(doc, edit_target, root);
}

fn apply_boxy_griffin_bus_component(doc, edit_target, root, parent_gen) {
    let plan = hexagonal_griffin_bus_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build typed hexagonal Griffin bus", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, paths: plan.paths}
}

// The bus has a few genuinely cuboidal equipment details (avionics shelf and
// rails). Keep this primitive helper local to those details; the load-bearing
// body itself is authored by the typed hexagonal mesh plan below.
fn _bus_detail_cube_plan(doc, edit_target, parent, name, size, scale, translation, color) {
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Cube" {
            return plan_error(path + ": bus equipment detail must resolve to Cube, got " + current.type_name);
        }
    } else {
        let shape = assembly_builder::cube_shape_plan(edit_target, parent, name,
            size, scale, false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    let placement = assembly_builder::place_plan(edit_target, path,
        translation, (), scale);
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
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
// configuration. The primary body is an open six-sided frame mesh; the deck
// and skirt remain separate hex meshes, and the six corner rails stay
// individually named Cube details.
fn _hex_component_mesh_plan(doc, edit_target, parent, name, width, depth,
    height, translation, color) {
    let path = parent + "/" + name;
    let current = assembly_builder::composed_query(doc, #{path: path, children: false});
    let geometry = _hex_prism_geometry(width, depth, height);
    if !geometry.ok { return geometry; }
    let ops = [];
    if query_ok(current) {
        if current.type_name != "Mesh" {
            return plan_error(path + ": typed hex geometry must resolve to Mesh, got " + current.type_name);
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

fn hexagonal_griffin_bus_component_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("hexagonal_griffin_bus_component_plan requires a document, edit target, and absolute root");
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
    let skirt_name = "LowerServiceSkirtHex";
    let ring_order = griffin_spec::visual_frame_perimeter_station_order();
    let ring_y = griffin_spec::visual_frame_ring_center_y_m();
    let ring_member_count = griffin_spec::visual_frame_ring_member_count();
    let ring_section = griffin_spec::visual_frame_ring_section_m();
    if body_width == () || body_depth == () || body_height == () || deck_width == ()
        || deck_depth == () || deck_thickness == () || deck_y == () || skirt_width == ()
        || skirt_depth == () || skirt_height == () || skirt_y == ()
        || ring_member_count == () || ring_section == () {
        return plan_error("typed Griffin hexagonal body datums are incomplete");
    }
    let ops = [];
    for legacy in ["BoxyAirframe", "LowerServiceSkirtBox", "IsogridDeck", "WhiteEquipmentBox"] {
        let path = root + "/" + legacy;
        let existing = assembly_builder::composed_query(doc, #{path: path, children: false});
        if query_ok(existing) {
            ops.push(#{SetActive: #{edit_target: edit_target, path: path, active: false}});
        }
    }
    let open_bay_panels = griffin_spec::visual_frame_open_bay_panel_names();
    if open_bay_panels.len() != 6 {
        return plan_error("typed Griffin open-bay panel identities must contain six source names");
    }
    for panel_name in open_bay_panels {
        let panel_path = root + "/" + panel_name;
        let panel = assembly_builder::composed_query(doc, #{path: panel_path, children: false});
        if !query_ok(panel) || panel.type_name != "Cube" {
            return plan_error(panel_path + ": source-named side bay skin must resolve to a Cube");
        }
        if panel.active != false {
            ops.push(#{SetActive: #{edit_target: edit_target, path: panel_path, active: false}});
        }
    }
    let rail_names = griffin_spec::visual_rail_names();
    let rail_stations = griffin_spec::visual_rail_station_positions();
    let rail_width = griffin_spec::visual_rail_width_m();
    let rail_length = griffin_spec::visual_rail_length_m();
    let rail_depth = griffin_spec::visual_rail_depth_m();
    if rail_names.len() != 6 || rail_stations.len() != rail_names.len()
        || ring_order.len() != 6 || ring_y.len() != 2 || ring_member_count != 12
        || ring_section <= 0.0 || rail_width == () || rail_length == () || rail_depth == () {
        return plan_error("typed Griffin open-frame station vectors or member dimensions are incomplete");
    }
    let frame = _hexagonal_open_frame_mesh_plan(doc, edit_target, root,
        body_name, rail_stations, ring_order, ring_y, ring_section);
    if !frame.ok { return frame; }
    for op in frame.ops { ops.push(op); }
    let meshes = [
        #{name: "TopDeckHex", width: deck_width, depth: deck_depth, height: deck_thickness,
            translation: [0.0, deck_y, 0.0], color: [0.22, 0.25, 0.29]},
        #{name: skirt_name, width: skirt_width, depth: skirt_depth, height: skirt_height,
            translation: [0.0, skirt_y, 0.0], color: [0.10, 0.12, 0.15]}
    ];
    for mesh in meshes {
        let plan = _hex_component_mesh_plan(doc, edit_target, root, mesh.name,
            mesh.width, mesh.depth, mesh.height, mesh.translation, mesh.color);
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    let avionics = _bus_detail_cube_plan(doc, edit_target, root, "AvionicsDeck", 1.0,
        [griffin_spec::visual_avionics_deck_width_m(), griffin_spec::visual_avionics_deck_thickness_m(), griffin_spec::visual_avionics_deck_depth_m()],
        [0.0, griffin_spec::visual_avionics_deck_center_y_m(), 0.0], [0.34, 0.38, 0.43]);
    if !avionics.ok { return avionics; }
    for op in avionics.ops { ops.push(op); }
    let pod = _bus_detail_cube_plan(doc, edit_target, root, "AvionicsPod", 1.0,
        [0.72, 0.36, 0.72], [0.0, griffin_spec::visual_avionics_deck_center_y_m() + 0.21, 0.0], [0.62, 0.66, 0.71]);
    if !pod.ok { return pod; }
    for op in pod.ops { ops.push(op); }
    for index in 0..rail_names.len() {
        let station = rail_stations[index];
        let plan = _bus_detail_cube_plan(doc, edit_target, root, rail_names[index], 1.0,
            [rail_width, rail_length, rail_depth], [station.x, station.y, station.z],
            [0.10, 0.12, 0.15]);
        if !plan.ok { return plan; }
        for op in plan.ops { ops.push(op); }
    }
    _clear_bus_label_tree(doc, edit_target, root, ops);
    if root.ends_with("/Bus") {
        let vehicle_root = root.sub_string(0, root.len() - 4);
        _clear_bus_label_ops(doc, edit_target, vehicle_root, ops);
    }
    #{ok: true, kind: "griffin_hexagonal_bus_component", root: root,
      paths: [root + "/" + body_name, root + "/TopDeckHex", root + "/" + skirt_name],
      ops: ops, no_op: ops.len() == 0}
}

// Update the six assembly-owned corner rails in-place.  These rails are not
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

// Ensure the standalone Griffin vehicle preview carries its own render intent.
// The vehicle is deliberately a portable assembly and therefore does not own
// a terrain scene, sun, or dome light.  Without an authored LunCoEnvironment
// prim the Editor falls back to the host presentation defaults; a white PBR
// proxy then saturates and bloom makes the close-up unreadable.  Keep the
// correction as typed USD operations so the same intent is visible in Edit
// perspective, journaled, and reloadable instead of hiding it in a viewport
// preference.
fn ensure_griffin_visual_environment_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("ensure_griffin_visual_environment_plan requires a document, edit target, and absolute root");
    }
    let path = root + "/Environment";
    let existing = assembly_builder::composed_query(doc, #{path: path, children: false});
    let ops = [];
    if query_ok(existing) {
        if existing.type_name != "LunCoEnvironment" {
            return plan_error(path + ": expected LunCoEnvironment, got " + existing.type_name);
        }
    } else {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: root,
            name: "Environment", type_name: "LunCoEnvironment",
            reference: (), reference_prim_path: ""}});
    }
    // EV100=16 is the current visual-review calibration for the 128 klx lunar
    // key used by LunCoSim. EV14 washed out the white proxy and erased the
    // deck/tank detail in the headful runtime. Keep this builder
    // datum aligned with the saved vehicle visual source so regeneration does
    // not reintroduce either failure mode.
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "lunco:env:exposureEv100", type_name: "float", value: "16.0"}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
        name: "lunco:env:bloomIntensity", type_name: "float", value: "0.0"}});
    #{ok: true, kind: "griffin_visual_environment", path: path,
      exposure_ev100: 16.0, bloom_intensity: 0.0, ops: ops,
      no_op: false}
}

fn ensure_griffin_visual_environment(doc, edit_target, root, parent_gen) {
    let plan = ensure_griffin_visual_environment_plan(doc, edit_target, root);
    if !plan.ok { return plan; }
    let command = assembly_edit::batch(doc, "Author Griffin visual environment", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      path: plan.path, exposure_ev100: plan.exposure_ev100,
      bloom_intensity: plan.bloom_intensity}
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
    if type_of(direction) != "Vec3" { return (); }
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
    if strut_radius == () || strut_height == () || strut_axis == ()
        || outer_x == () || inner_x == () || strut_y == ()
        || outer_tilt == () || inner_tilt == () || piston_radius == ()
        || piston_height == () || piston_y == () || pad_radius == ()
        || pad_height == () || pad_y == () || clevis_width == ()
        || clevis_height == () || clevis_depth == () || clevis_y == ()
        || plate_width == () || plate_height == () || plate_depth == ()
        || plate_y == () {
        return plan_error("landing-leg SysML geometry datums are incomplete");
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
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:requirement", type_name: "string",
        value: "\"GriffinLandingLegRequirements::GLL001-GLL008\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:configuration", type_name: "string",
        value: "\"two canted load struts, clevis and axle, shock piston, load plate, foot pad\""}});
    #{ok: true, kind: "griffin_landing_leg_component_refinement",
      root: root, paths: [root + "/StrutOuter", root + "/StrutInner",
        root + "/ShockPiston", root + "/FootPad", root + "/MountClevisOuter",
        root + "/MountClevisInner", root + "/MountAxle", root + "/FootPadPlate"],
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
    if type_of(child_names) != "array" {
        return plan_error("landing-leg child identity collection is not a typed enum array");
    }
    let outer_name = ();
    let inner_name = ();
    for child in child_names {
        if type_of(child) != "EnumValue" { continue; }
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
        let color_matches = type_of(color) == "array" && color.len() == 1
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

fn _solar_number(source, name) {
    if source == () || source.ok != true { return (); }
    sysml_requirements::number(source,
        "GriffinSolarRequirements::GriffinSolarArrayAssembly::" + name)
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
    let source = sysml_requirements::source();
    let frame_width = _solar_number(source, "frameWidthM");
    let frame_thickness = _solar_number(source, "frameThicknessM");
    let frame_depth = _solar_number(source, "frameDepthM");
    let cell_width = _solar_number(source, "cellWidthM");
    let cell_thickness = _solar_number(source, "cellThicknessM");
    let cell_depth = _solar_number(source, "cellDepthM");
    let cell_offset = _solar_number(source, "cellOffsetYM");
    let divider_width = _solar_number(source, "dividerXWidthM");
    let divider_thickness = _solar_number(source, "dividerXThicknessM");
    let divider_span = _solar_number(source, "dividerZWidthM");
    let bracket_width = _solar_number(source, "mountBracketWidthM");
    let bracket_thickness = _solar_number(source, "mountBracketThicknessM");
    let bracket_depth = _solar_number(source, "mountBracketDepthM");
    let hinge_radius = _solar_number(source, "hingeBarRadiusM");
    let hinge_length = _solar_number(source, "hingeBarLengthM");
    let hinge_y = _solar_number(source, "hingeBarCenterYM");
    let hinge_z = _solar_number(source, "hingeBarCenterZM");
    let link_width = _solar_number(source, "mountLinkWidthM");
    let link_height = _solar_number(source, "mountLinkHeightM");
    let link_depth = _solar_number(source, "mountLinkDepthM");
    let link_x = _solar_number(source, "mountLinkCenterXM");
    let link_y = _solar_number(source, "mountLinkCenterYM");
    let link_z = _solar_number(source, "mountLinkCenterZM");
    if frame_width == () || frame_thickness == () || frame_depth == ()
        || cell_width == () || cell_thickness == () || cell_depth == ()
        || cell_offset == () || divider_width == () || divider_thickness == ()
        || divider_span == () || bracket_width == () || bracket_thickness == ()
        || bracket_depth == () || hinge_radius == () || hinge_length == ()
        || hinge_y == () || hinge_z == () || link_width == ()
        || link_height == () || link_depth == () || link_x == ()
        || link_y == () || link_z == () {
        return plan_error("solar-panel SysML geometry datums are incomplete");
    }
    let ops = [];
    let cubes = [
        #{name: "Frame", translation: [0.0, 0.0, 0.0], rotation: (),
          scale: [frame_width / 2.0, frame_thickness / 2.0, frame_depth / 2.0],
          color: [0.44, 0.48, 0.55]},
        #{name: "ArrayBackplane", translation: [0.0, -0.075, 0.0], rotation: (),
          scale: [cell_width / 2.0, 0.018, cell_depth / 2.0],
          color: [0.015, 0.035, 0.12]},
        #{name: "Cells", translation: [0.0, cell_offset, 0.0], rotation: (),
          scale: [cell_width / 2.0, cell_thickness / 2.0, cell_depth / 2.0],
          color: [0.015, 0.16, 0.62]},
        #{name: "CellDividerX", translation: [0.0, cell_offset + 0.025, 0.0], rotation: (),
          scale: [divider_width / 2.0, divider_thickness / 2.0, cell_depth / 2.0],
          color: [0.72, 0.78, 0.88]},
        #{name: "CellDividerXLeft", translation: [-cell_width / 6.0, cell_offset + 0.028, 0.0], rotation: (),
          scale: [divider_width / 2.0, divider_thickness / 2.0, cell_depth / 2.0],
          color: [0.72, 0.78, 0.88]},
        #{name: "CellDividerXRight", translation: [cell_width / 6.0, cell_offset + 0.028, 0.0], rotation: (),
          scale: [divider_width / 2.0, divider_thickness / 2.0, cell_depth / 2.0],
          color: [0.72, 0.78, 0.88]},
        #{name: "CellDividerZ", translation: [0.0, cell_offset + 0.028, 0.0], rotation: (),
          scale: [divider_span / 2.0, divider_thickness / 2.0, divider_width / 2.0],
          color: [0.72, 0.78, 0.88]},
        #{name: "CellDividerZUpper", translation: [0.0, cell_offset + 0.03, cell_depth / 6.0], rotation: (),
          scale: [divider_span / 2.0, divider_thickness / 2.0, divider_width / 2.0],
          color: [0.72, 0.78, 0.88]},
        #{name: "CellDividerZLower", translation: [0.0, cell_offset + 0.03, -cell_depth / 6.0], rotation: (),
          scale: [divider_span / 2.0, divider_thickness / 2.0, divider_width / 2.0],
          color: [0.72, 0.78, 0.88]},
        #{name: "MountBracket", translation: [0.0, -bracket_thickness / 2.0, 0.0], rotation: (),
          scale: [bracket_width / 2.0, bracket_thickness / 2.0, bracket_depth / 2.0],
          color: [0.12, 0.15, 0.20]},
    ];
    for item in cubes {
        let part = _component_cube_visual_ops(doc, edit_target, root,
            item.name, item.translation, item.rotation, item.scale, item.color);
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
    }
    let hinge = _component_cylinder_visual_ops(doc, edit_target, root,
        "HingeBar", [0.0, hinge_y, hinge_z], (), hinge_radius,
        hinge_length, "Z", [0.16, 0.19, 0.24]);
    if !hinge.ok { return hinge; }
    for op in hinge.ops { ops.push(op); }
    let link = _component_cube_visual_ops(doc, edit_target, root,
        "MountLink", [link_x, link_y, link_z], (),
        [link_width / 2.0, link_height / 2.0, link_depth / 2.0],
        [0.10, 0.13, 0.18]);
    if !link.ok { return link; }
    for op in link.ops { ops.push(op); }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:requirement", type_name: "string",
        value: "\"GriffinSolarRequirements::GSA001-GSA008\""}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:cell_face_normal", type_name: "token",
        value: "\"+Y; outward after signed assembly X rotation onto the signed Z side\""}});
    #{ok: true, kind: "griffin_solar_panel_component_refinement",
      root: root, paths: [root + "/Frame", root + "/Cells",
        root + "/ArrayBackplane", root + "/CellDividerX",
        root + "/CellDividerXLeft", root + "/CellDividerXRight",
        root + "/CellDividerZ", root + "/CellDividerZUpper",
        root + "/CellDividerZLower", root + "/MountBracket",
        root + "/HingeBar", root + "/MountLink"],
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

fn _tank_cylinder_schema_ops(edit_target, parent, name, radius, height,
    translation, color, add) {
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
        #{name: "axis", type_name: "token", value: "\"Y\""},
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

fn _tank_cone_schema_ops(edit_target, parent, name, radius1, radius2,
    height, translation, color, add) {
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
        #{name: "axis", type_name: "token", value: "\"Y\""},
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
    let required = if type_name == "Cone" {
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
    let source = sysml_requirements::source();
    let radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bodyRadiusM");
    let body_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bodyCylindricalHeightM");
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
    let band_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bandHeightM");
    let band_centers = component_requirements::source_number_list(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bandCenterYM");
    let band_radii = component_requirements::source_number_list(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bandRadiusByCenterM");
    let cradle_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradleRadiusM");
    let cradle_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradleHeightM");
    let cradle_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradleLocalY");
    let cradle_pad_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadLocalY");
    let cradle_pad_width = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadWidthM");
    let cradle_pad_depth = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadDepthM");
    let cradle_pad_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::cradlePadHeightM");
    let support_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportRadiusM");
    let support_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportHeightM");
    let support_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportCenterYM");
    let bracket_length = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketLengthM");
    let bracket_width = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketWidthM");
    let bracket_depth = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketDepthM");
    let bracket_offset = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketCenterOffsetM");
    let bracket_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketCenterYM");
    let bracket_tilt = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::bracketTiltDeg");
    let missing_body = radius == () || body_height == ();
    let missing_end = neck_radius == () || neck_height == ()
        || shoulder_radius == () || shoulder_height == ()
        || valve_radius == () || valve_height == ()
        || cap_radius == () || cap_height == ();
    let missing_transitions = transition_shoulder == () || transition_neck == ()
        || transition_height == () || transition_radius == ()
        || shoulder_y == () || transition_y == () || neck_y == ()
        || valve_y == () || cap_y == () || band_height == ();
    let missing_interface = band_centers.len() != 3 || band_radii.len() != 3
        || cradle_radius == () || cradle_height == () || cradle_y == ()
        || cradle_pad_y == () || cradle_pad_width == () || cradle_pad_depth == ()
        || cradle_pad_height == () || support_radius == () || support_height == () || support_y == ()
        || bracket_length == () || bracket_width == () || bracket_depth == ()
        || bracket_offset == () || bracket_y == () || bracket_tilt == ();
    if missing_body || missing_end || missing_transitions || missing_interface {
        return plan_error("tank SysML double dimensions or axial datums are missing");
    }
    let desired = [
        #{path: root + "/MliTank", type_name: "Cylinder"},
        #{path: root + "/TankBandA", type_name: "Cylinder"},
        #{path: root + "/TankBandB", type_name: "Cylinder"},
        #{path: root + "/TankBandC", type_name: "Cylinder"},
        #{path: root + "/TankNeckTop", type_name: "Cylinder"},
        #{path: root + "/TankNeckBottom", type_name: "Cylinder"},
        #{path: root + "/TankShoulderTop", type_name: "Cylinder"},
        #{path: root + "/TankShoulderBottom", type_name: "Cylinder"},
        #{path: root + "/TankValveTop", type_name: "Cylinder"},
        #{path: root + "/TankValveBottom", type_name: "Cylinder"},
        #{path: root + "/TankValveCapTop", type_name: "Cylinder"},
        #{path: root + "/TankValveCapBottom", type_name: "Cylinder"},
        #{path: root + "/TankCradle", type_name: "Cylinder"},
        #{path: root + "/TankSupportPost", type_name: "Cylinder"},
        #{path: root + "/TankTransitionTop", type_name: "Cone"},
        #{path: root + "/TankTransitionBottom", type_name: "Cone"},
    ];
    let existing_invalid = [];
    for item in desired {
        if !_tank_schema_prim_ready(doc, item.path, item.type_name) {
            if query_ok(assembly_builder::composed_query(doc, #{path: item.path, children: false})) {
                existing_invalid.push(item.path);
            }
        }
    }
    let stale_paths = [];
    for old_name in ["TankBodyVisual", "TankBandAVisual", "TankBandBVisual", "TankBandCVisual"] {
        let old_path = root + "/" + old_name;
        if query_ok(assembly_builder::composed_query(doc, #{path: old_path, children: false})) {
            stale_paths.push(old_path);
        }
    }
    let ops = [];
    // OpenUSD validates a typed attribute against the composed prim before
    // applying a batch.  A malformed legacy prim therefore needs its own
    // transaction: removing it and recreating it in the same batch is not
    // valid because the AddPrim still sees the old schema.  Return an
    // explicit removal phase so callers cannot accidentally hide this state.
    if existing_invalid.len() > 0 || stale_paths.len() > 0 {
        for path in existing_invalid { ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}}); }
        for path in stale_paths { ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}}); }
        return #{ok: true, kind: "griffin_tank_usd_double_schema_remove_required",
            phase: "remove", root: root, component_count: 1, ops: ops,
            no_op: ops.len() == 0,
            diagnostic: "legacy tank prims must be removed in a separate Editor transaction before rebuilding"};
    }
    // Once the removal transaction has committed, only absent prims are
    // added. Existing valid prims receive typed placement/attribute updates.
    let body_path = root + "/MliTank";
    let body = _tank_cylinder_schema_ops(edit_target, root, "MliTank", radius,
        body_height, [0.0, 0.0, 0.0], [0.58, 0.43, 0.24],
        !query_ok(assembly_builder::composed_query(doc, #{path: body_path, children: false})));
    if !body.ok { return body; }
    for op in body.ops { ops.push(op); }
    for band in [
        #{name: "TankBandA", index: 0}, #{name: "TankBandB", index: 1},
        #{name: "TankBandC", index: 2},
    ] {
        let ring = _tank_cylinder_schema_ops(edit_target, root, band.name,
            band_radii[band.index], band_height,
            [0.0, band_centers[band.index], 0.0], [0.10, 0.12, 0.15],
            !query_ok(assembly_builder::composed_query(doc, #{path: root + "/" + band.name, children: false})));
        if !ring.ok { return ring; }
        for op in ring.ops { ops.push(op); }
    }
    let cylinders = [
        #{name: "TankNeckTop", radius: neck_radius, height: neck_height, y: neck_y, color: [0.25, 0.19, 0.12]},
        #{name: "TankNeckBottom", radius: neck_radius, height: neck_height, y: -neck_y, color: [0.25, 0.19, 0.12]},
        #{name: "TankShoulderTop", radius: shoulder_radius, height: shoulder_height, y: shoulder_y, color: [0.28, 0.18, 0.08]},
        #{name: "TankShoulderBottom", radius: shoulder_radius, height: shoulder_height, y: -shoulder_y, color: [0.28, 0.18, 0.08]},
        #{name: "TankValveTop", radius: valve_radius, height: valve_height, y: valve_y, color: [0.48, 0.50, 0.53]},
        #{name: "TankValveBottom", radius: valve_radius, height: valve_height, y: -valve_y, color: [0.48, 0.50, 0.53]},
        #{name: "TankValveCapTop", radius: cap_radius, height: cap_height, y: cap_y, color: [0.20, 0.22, 0.25]},
        #{name: "TankValveCapBottom", radius: cap_radius, height: cap_height, y: -cap_y, color: [0.20, 0.22, 0.25]},
        #{name: "TankCradle", radius: cradle_radius, height: cradle_height, y: cradle_y, color: [0.20, 0.22, 0.25]},
        #{name: "TankSupportPost", radius: support_radius, height: support_height, y: support_y, color: [0.10, 0.12, 0.15]},
    ];
    for item in cylinders {
        let part = _tank_cylinder_schema_ops(edit_target, root, item.name,
            item.radius, item.height, [0.0, item.y, 0.0], item.color,
            !query_ok(assembly_builder::composed_query(doc, #{path: root + "/" + item.name, children: false})));
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
    }
    for cone in [
        #{name: "TankTransitionTop", radius1: transition_shoulder, radius2: transition_neck, y: transition_y},
        #{name: "TankTransitionBottom", radius1: transition_neck, radius2: transition_shoulder, y: -transition_y},
    ] {
        let part = _tank_cone_schema_ops(edit_target, root, cone.name,
            cone.radius1, cone.radius2, transition_height,
            [0.0, cone.y, 0.0], [0.28, 0.18, 0.08],
            !query_ok(assembly_builder::composed_query(doc, #{path: root + "/" + cone.name, children: false})));
        if !part.ok { return part; }
        for op in part.ops { ops.push(op); }
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: part.path,
            name: "radius", type_name: "double", value: transition_radius.to_string()}});
    }
    // The lower tank interface is part of the reusable component, not an
    // assembly-local decoration.  Keep the pad and four radial braces typed
    // from SysML so a tank can be reviewed in isolation and in the vehicle.
    let pad_path = root + "/TankCradlePad";
    let pad = assembly_builder::composed_query(doc, #{path: pad_path, children: false});
    if query_ok(pad) && pad.type_name != "Cube" {
        return plan_error(pad_path + ": expected Cube, got " + pad.type_name);
    }
    if !query_ok(pad) {
        let shape = assembly_builder::cube_shape_plan(edit_target, root, "TankCradlePad", 1.0,
            [cradle_pad_width, cradle_pad_height, cradle_pad_depth], false);
        if !shape.ok { return shape; }
        for op in shape.ops { ops.push(op); }
    }
    let pad_placement = assembly_builder::place_plan(edit_target, pad_path,
        [0.0, cradle_pad_y, 0.0], (), [cradle_pad_width, cradle_pad_height, cradle_pad_depth]);
    if !pad_placement.ok { return pad_placement; }
    for op in pad_placement.ops { ops.push(op); }
    let bracket_group = root + "/TankMountBrackets";
    let group = assembly_builder::composed_query(doc, #{path: bracket_group, children: false});
    if !query_ok(group) || group.type_name != "Xform" {
        return plan_error(bracket_group + ": tank bracket group is missing or not Xform");
    }
    let bracket_specs = [
        #{name: "TankMountBracketPX", translation: [bracket_offset, bracket_y, bracket_offset], rotation: [-bracket_tilt, 0.0, bracket_tilt]},
        #{name: "TankMountBracketNX", translation: [-bracket_offset, bracket_y, bracket_offset], rotation: [-bracket_tilt, 0.0, -bracket_tilt]},
        #{name: "TankMountBracketPZ", translation: [bracket_offset, bracket_y, -bracket_offset], rotation: [bracket_tilt, 0.0, bracket_tilt]},
        #{name: "TankMountBracketNZ", translation: [-bracket_offset, bracket_y, -bracket_offset], rotation: [bracket_tilt, 0.0, -bracket_tilt]},
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
    #{ok: true, kind: "griffin_tank_usd_double_schema", root: root,
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
    // The isolated component owns the canonical rail names.  The older
    // assembly-local EngineSkirtFront/... opinions are inactive migration
    // remnants and must never be targeted by a component refinement.
    let paths = [
        root + "/RailFront", root + "/RailRear",
        root + "/RailPort", root + "/RailStarboard",
    ];
    let rail_x = width / 2.0 - section / 2.0;
    let rail_z = depth / 2.0 - section / 2.0;
    // This document is the reusable component asset.  Its parent instance
    // owns the global assemblyMountYM; applying that global value here would
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
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:visual:skirt_metric_envelope", type_name: "string",
        value: "\"3.20 m x 3.20 m x 0.20 m; 0.20 m rails; centered on engine adapter datum\""}});
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

fn _flip_task_match(name, task) {
    if name == task { return true; }
    if task == "DirectionalWheels" { return name.starts_with("Wheel_"); }
    false
}

fn _flip_detail_matches_task(detail, task) {
    let parent = detail.parent;
    if detail.task != () {
        return task == "DirectionalWheels" || detail.task == task;
    }
    if task == "Chassis" { return parent.ends_with("/Chassis"); }
    if task == "SensorMast" { return parent.ends_with("/SensorMast"); }
    false
}

fn isolated_flip_component_plan_for(doc, edit_target, root, task) {
    if doc == () || edit_target == () || !absolute_root(root) || task == () || task == "" {
        return plan_error("isolated_flip_component_plan_for requires a document, edit target, root, and task");
    }
    let specs = _isolated_flip_specs(root);
    if specs.len() == 0 { return plan_error("SysML FLIP visual parameters are missing"); }
    let selected = [];
    for spec in specs {
        if _flip_task_match(spec.name, task) { selected.push(spec); }
    }
    if selected.len() == 0 {
        return plan_error("unknown FLIP visual component task ");
    }
    let ops = [];
    let paths = [];
    for spec in selected {
        let result = _isolated_component_plan(doc, edit_target, spec);
        if !result.ok { return result; }
        paths.push(result.path);
        for op in result.ops { ops.push(op); }
    }
    for detail in _isolated_flip_detail_specs(root) {
        if !_flip_detail_matches_task(detail, task) { continue; }
        let path = detail.parent + "/" + detail.name;
        if query_ok(assembly_builder::composed_query(doc, #{path: path, children: false})) { continue; }
        let detail_plan = _detail_ops(edit_target, detail);
        if !detail_plan.ok { return detail_plan; }
        for op in detail_plan.ops { ops.push(op); }
    }
    if task == "DirectionalWheels" || task.starts_with("Wheel_") {
        let names = griffin_spec::visual_rover_wheel_names();
        let wheel_x = griffin_spec::rover_wheel_station_x();
        if names.len() != 4 || wheel_x.len() != names.len() {
            return plan_error("FLIP wheel station datums must contain four entries");
        }
        let suspension_specs = _isolated_flip_suspension_specs(root);
        for index in 0..names.len() {
            let wheel_name = "Wheel_" + names[index];
            if task != "DirectionalWheels" && wheel_name != task { continue; }
            let station = root + "/Suspension_" + names[index];
            let obsolete = station + "/SuspensionStrut";
            if query_ok(assembly_builder::composed_query(doc, #{path: obsolete, children: false})) {
                ops.push(#{RemovePrim: #{edit_target: edit_target, path: obsolete}});
            }
            let result = _component_plan(doc, edit_target, suspension_specs[index]);
            if !result.ok { return result; }
            paths.push(result.path);
            for op in result.ops { ops.push(op); }
        }
    }
    let names = griffin_spec::visual_rover_wheel_names();
    let wheel_x = griffin_spec::rover_wheel_station_x();
    let wheel_y = griffin_spec::rover_wheel_station_y();
    let wheel_z = griffin_spec::rover_wheel_station_z();
    if task == "DirectionalWheels" || task.starts_with("Wheel_") {
        if names.len() != 4 || wheel_x.len() != 4 || wheel_y.len() != 4 || wheel_z.len() != 4 {
            return plan_error("FLIP wheel station datums must contain four entries");
        }
        for index in 0..names.len() {
            let wheel_name = "Wheel_" + names[index];
            if task != "DirectionalWheels" && wheel_name != task { continue; }
            let station = root + "/Suspension_" + names[index];
            let placement = assembly_builder::place_plan(edit_target, station,
                [wheel_x[index], wheel_y[index], wheel_z[index]], (), ());
            if !placement.ok { return placement; }
            for op in placement.ops { ops.push(op); }
        }
    }
    #{ok: true, kind: "flip_component_task", root: root, component: task,
      component_count: selected.len(), paths: paths, ops: ops, no_op: ops.len() == 0}
}

fn apply_isolated_flip_component(doc, edit_target, root, task, parent_gen) {
    let plan = isolated_flip_component_plan_for(doc, edit_target, root, task);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build FLIP component " + task,
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      component: task, component_count: plan.component_count, root: root}
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
    let behavior = sysml_requirements::text(source,
        griffin_spec::qualified_attribute_name("rampBehavior"));
    if limit == () || length == () || width == () || angle == () {
        return plan_error("ramp SysML dimensions, placement, or deployment values are missing");
    }
    if behavior == () || behavior == "" {
        return plan_error("ramp SysML behavior contract is missing");
    }
    [
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:side", type_name: "token", value: "\"" + side + "\""}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:hinge_axis", type_name: "token", value: "\"Z\""}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:surface_length_m", type_name: "double", value: length.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:surface_width_m", type_name: "double", value: width.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:deployment_limit_rad", type_name: "double", value: limit.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:deployment_angle_rad", type_name: "double", value: angle.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:mount_datum", type_name: "token", value: "\"Bus/RampSocket\""}},
        #{SetAttribute: #{edit_target: edit_target, path: path,
            name: "lunco:visual:behavior", type_name: "string", value: "\"" + behavior + "\""}},
    ]
}

// Scale the referenced ramp children in the owning assembly layer. The
// replaceable ramp asset remains untouched; this typed Editor override makes
// the visual envelope agree with the SysML/FLIP interface contract.
fn _isolated_ramp_visual_geometry_ops(doc, edit_target, path) {
    let source = sysml_requirements::source();
    let length = _sysml_number(source, "rampSurfaceLengthM");
    let width = _sysml_number(source, "rampSurfaceWidthM");
    let thickness = _sysml_number(source, "rampSurfaceThicknessM");
    let rail_height = _sysml_number(source, "rampRailHeightM");
    let rail_width = _sysml_number(source, "rampRailWidthM");
    let rail_offset = _sysml_number(source, "rampRailOffsetZM");
    let surface_y = _sysml_number(source, "rampSurfaceCenterYM");
    let rail_y = _sysml_number(source, "rampRailCenterYM");
    if length == () || width == () || thickness == () || rail_height == ()
        || rail_width == () || rail_offset == () || surface_y == () || rail_y == ()
        || length <= 0.0 || width <= 0.0 || thickness <= 0.0
        || rail_height <= 0.0 || rail_width <= 0.0 || rail_offset <= 0.0 {
        return plan_error("ramp visual geometry SysML datums are incomplete");
    }
    let rail_center = rail_offset;
    let children = [
        #{path: path + "/RampSurface", translation: [length / 2.0, surface_y, 0.0],
          // Cube placement takes the full authored envelope; the half-length
          // appears only in the center translation because the component
          // origin is the hinge and the surface spans x=0..length.
          scale: [length, thickness, width]},
        #{path: path + "/OuterRail", translation: [length / 2.0, rail_y, rail_center],
          scale: [length, rail_height, rail_width]},
        #{path: path + "/InnerRail", translation: [length / 2.0, rail_y, -rail_center],
          scale: [length, rail_height, rail_width]},
    ];
    let ops = [];
    for child in children {
        let prim = assembly_builder::composed_query(doc, #{path: child.path, children: false});
        if !query_ok(prim) || prim.type_name != "Cube" {
            return plan_error(child.path + ": referenced ramp geometry must be an existing Cube");
        }
        let placement = assembly_builder::place_plan(edit_target, child.path,
            child.translation, (), child.scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        let color = if child.path.ends_with("/RampSurface") {
            [0.34, 0.38, 0.44]
        } else {
            [0.18, 0.21, 0.26]
        };
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: child.path,
            name: "primvars:displayColor", type_name: "color3f[]",
            value: _color_literal(color)}});
    }
    // The full-scale ramp needs a readable structural load path.  Update the
    // inherited centre support and add a mirrored outboard support pair in
    // the ramp assembly layer; all dimensions still cross from SysML through
    // typed placement operations.
    let support_x = _ramp_number("supportArmCenterXM");
    let support_y = _ramp_number("supportArmCenterYM");
    let support_w = _ramp_number("supportArmHalfWidthM");
    let support_h = _ramp_number("supportArmHalfHeightM");
    let support_d = _ramp_number("supportArmHalfDepthM");
    let support_offset = _ramp_number("supportArmPairOffsetZM");
    let support_tilt = _ramp_number("supportArmTiltZDeg");
    let tread_prefix = griffin_spec::ramp_tread_name_prefix();
    let tread_count = griffin_spec::ramp_tread_count();
    let tread_width = griffin_spec::ramp_tread_width_m();
    let tread_height = griffin_spec::ramp_tread_height_m();
    let tread_span = griffin_spec::ramp_tread_span_m();
    let tread_first_x = griffin_spec::ramp_tread_first_center_x_m();
    let tread_pitch = griffin_spec::ramp_tread_pitch_m();
    let beam_width = griffin_spec::ramp_under_beam_width_m();
    let beam_height = griffin_spec::ramp_under_beam_height_m();
    let beam_y = griffin_spec::ramp_under_beam_center_y_m();
    let beam_offset = griffin_spec::ramp_under_beam_center_offset_z_m();
    let post_count = griffin_spec::ramp_side_post_count_per_side();
    let post_width = griffin_spec::ramp_side_post_width_m();
    let post_height = griffin_spec::ramp_side_post_height_m();
    let post_depth = griffin_spec::ramp_side_post_depth_m();
    let post_y = griffin_spec::ramp_side_post_center_y_m();
    let post_first_x = griffin_spec::ramp_side_post_first_center_x_m();
    let post_pitch = griffin_spec::ramp_side_post_pitch_m();
    let collar_radius = griffin_spec::ramp_hinge_collar_radius_m();
    let collar_length = griffin_spec::ramp_hinge_collar_length_m();
    let collar_offset = griffin_spec::ramp_hinge_collar_offset_z_m();
    let gusset_width = griffin_spec::ramp_hinge_gusset_width_m();
    let gusset_height = griffin_spec::ramp_hinge_gusset_height_m();
    let gusset_depth = griffin_spec::ramp_hinge_gusset_depth_m();
    let gusset_x = griffin_spec::ramp_hinge_gusset_center_x_m();
    let gusset_y = griffin_spec::ramp_hinge_gusset_center_y_m();
    let gusset_offset = griffin_spec::ramp_hinge_gusset_offset_z_m();
    if support_x == () || support_y == () || support_w == ()
        || support_h == () || support_d == () || support_offset == ()
        || support_tilt == () || tread_prefix == () || tread_prefix == ""
        || tread_count == () || tread_count < 2 || tread_width == ()
        || tread_height == () || tread_span == () || tread_first_x == ()
        || tread_pitch == () || tread_width <= 0.0 || tread_height <= 0.0
        || tread_span <= 0.0 || tread_pitch <= 0.0 {
        return plan_error("ramp support-arm SysML datums are incomplete");
    }
    if beam_width == () || beam_height == () || beam_y == () || beam_offset == ()
        || post_count == () || post_count < 2 || post_width == ()
        || post_height == () || post_depth == () || post_y == ()
        || post_first_x == () || post_pitch == () || collar_radius == ()
        || collar_length == () || collar_offset == ()
        || beam_width <= 0.0 || beam_height <= 0.0 || beam_offset <= 0.0
        || post_width <= 0.0 || post_height <= 0.0 || post_depth <= 0.0
        || post_pitch <= 0.0 || collar_radius <= 0.0 || collar_length <= 0.0
        || collar_offset <= 0.0 {
        return plan_error("ramp load-path SysML datums are incomplete");
    }
    if gusset_width == () || gusset_height == () || gusset_depth == ()
        || gusset_x == () || gusset_y == () || gusset_offset == ()
        || gusset_width <= 0.0 || gusset_height <= 0.0 || gusset_depth <= 0.0
        || gusset_offset <= 0.0 {
        return plan_error("ramp hinge-gusset SysML datums are incomplete");
    }
    let support_specs = [
        #{name: "SupportArm", translation: [support_x, support_y, 0.0]},
        #{name: "SupportArmOuter", translation: [support_x, support_y, support_offset]},
        #{name: "SupportArmInner", translation: [support_x, support_y, -support_offset]},
    ];
    for support in support_specs {
        let support_path = path + "/" + support.name;
        let existing = assembly_builder::composed_query(doc,
            #{path: support_path, children: false});
        if query_ok(existing) && existing.type_name != "Cube" {
            return plan_error(support_path + ": support arm must be a Cube");
        }
        if !query_ok(existing) {
            let shape = assembly_builder::cube_shape_plan(edit_target, path,
                support.name, 1.0, [support_w, support_h, support_d], false);
            if !shape.ok { return shape; }
            for op in shape.ops { ops.push(op); }
        }
        let placement = assembly_builder::place_plan(edit_target, support_path,
            support.translation, [0.0, 0.0, support_tilt],
            [support_w * 2.0, support_h * 2.0, support_d * 2.0]);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: support_path,
            name: "purpose", type_name: "token", value: "\"render\""}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: support_path,
            name: "physics:collisionEnabled", type_name: "bool", value: "false"}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: support_path,
            name: "primvars:displayColor", type_name: "color3f[]",
            value: "[(0.10, 0.12, 0.15)]"}});
    }
    // Add named transverse traction bars to the visual ramp.  They are
    // assembly-owned render geometry, not collision, so the reusable ramp
    // component can still be replaced without changing the physical egress
    // contract. Their spacing and envelope are read from SysML.
    for index in 0..tread_count {
        let tread_name = tread_prefix + (index + 1).to_string();
        let tread = _component_cube_visual_ops(doc, edit_target, path,
            tread_name, [tread_first_x + tread_pitch * index, thickness / 2.0 + tread_height / 2.0, 0.0], (),
            [tread_width, tread_height, tread_span],
            [0.10, 0.12, 0.16]);
        if !tread.ok { return tread; }
        for op in tread.ops { ops.push(op); }
    }
    // Add two longitudinal underside beams. They are deliberately below the
    // walking surface, where the viewer can read a real load path instead of
    // mistaking the ramp for a floating plate.
    for beam in [
        #{name: "UnderBeamPort", z: beam_offset},
        #{name: "UnderBeamStarboard", z: -beam_offset},
    ] {
        let beam_result = _component_cube_visual_ops(doc, edit_target, path,
            beam.name, [length / 2.0, beam_y, beam.z], (),
            [length, beam_height, beam_width],
            [0.10, 0.12, 0.15]);
        if !beam_result.ok { return beam_result; }
        for op in beam_result.ops { ops.push(op); }
    }
    // Four upright posts per edge tie the underside beams/plate to the raised
    // rails. Their ordered stations are source-backed study datums, so the
    // same load-path topology can be checked in the standalone ramp gate.
    for side in ["Port", "Starboard"] {
        let post_z = if side == "Port" { rail_center } else { -rail_center };
        for index in 0..post_count {
            let post_result = _component_cube_visual_ops(doc, edit_target, path,
                "SidePost" + side + (index + 1).to_string(),
                [post_first_x + post_pitch * index, post_y, post_z], (),
                [post_width, post_height, post_depth],
                [0.16, 0.18, 0.22]);
            if !post_result.ok { return post_result; }
            for op in post_result.ops { ops.push(op); }
        }
    }
    // Split hinge collars give the root a mechanical silhouette while the
    // single HingePin remains the semantic Z-axis revolute datum.
    for collar in [
        #{name: "HingeCollarPort", z: collar_offset},
        #{name: "HingeCollarStarboard", z: -collar_offset},
    ] {
        let collar_result = _component_cylinder_visual_ops(doc, edit_target, path,
            collar.name, [0.0, 0.0, collar.z], (), collar_radius, collar_length,
            "Z", [0.30, 0.34, 0.40]);
        if !collar_result.ok { return collar_result; }
        for op in collar_result.ops { ops.push(op); }
    }
    // The short inboard gussets make the hinge-to-rail connection legible in
    // the focused Editor view. They are render-only geometry and remain
    // replaceable when the supplier structural ICD is available.
    for gusset in [
        #{name: "HingeGussetPort", z: gusset_offset},
        #{name: "HingeGussetStarboard", z: -gusset_offset},
    ] {
        let gusset_result = _component_cube_visual_ops(doc, edit_target, path,
            gusset.name, [gusset_x, gusset_y, gusset.z], (),
            [gusset_width / 2.0, gusset_height / 2.0, gusset_depth / 2.0],
            [0.22, 0.26, 0.31]);
        if !gusset_result.ok { return gusset_result; }
        for op in gusset_result.ops { ops.push(op); }
    }
    // The old detail recipe placed the hinge hardware 1.60 m inboard.  The
    // new zero local hinge datum is the actual ramp root and keeps the plate
    // visibly attached to the side socket after the ramp is lengthened.
    for hardware in [path + "/MountPlate", path + "/HingePin"] {
        if query_ok(assembly_builder::composed_query(doc, #{path: hardware, children: false})) {
            let placement = assembly_builder::place_plan(edit_target, hardware,
                [0.0, 0.0, 0.0], (), ());
            if !placement.ok { return placement; }
            for op in placement.ops { ops.push(op); }
        }
    }
    #{ok: true, kind: "griffin_ramp_visual_geometry", ops: ops,
      width_m: width, length_m: length, no_op: ops.len() == 0}
}

// Author the safe pre-landing state of the physical ramp bodies.  The ramp
// geometry remains full-size and collision-enabled, but lies horizontally at
// its hinge so the 8 m body cannot contact terrain while Griffin is descending.
// Deployment is then a native PhysicsRevoluteJoint angle command from the
// mission scenario.  This keeps the scene source authoritative without trying
// to mutate a live collider through an authored transform edit.
fn _physical_ramp_transition_ops(doc, edit_target, root, side,
    overlap, thickness, width, surface_y) {
    let source = sysml_requirements::source();
    let name = griffin_spec::physical_ramp_transition_child_name();
    let mass = griffin_spec::physical_ramp_deck_transition_mass_kg();
    let inertia = griffin_spec::physical_ramp_deck_transition_inertia_kg_m2();
    let joint_prefix = griffin_spec::physical_ramp_transition_joint_name_prefix();
    let mount_y = _sysml_number(source, "physicalRampMountY");
    let mount_z = _sysml_number(source, "physicalRampMountZ");
    let mount_x = _sysml_number(source, if side == "port" {
        "physicalRampPortMountX"
    } else {
        "physicalRampStarboardMountX"
    });
    if name == () || name == "" || mass == () || mass <= 0.0
        || inertia.len() != 3 || joint_prefix == () || joint_prefix == ""
        || mount_x == () || mount_y == () || mount_z == () {
        return plan_error("physical ramp transition identity/mass/inertia datums are incomplete in SysML");
    }
    let path = root + "/" + name;
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
        // The earlier study authored the scaled Cube as the body itself. It is
        // safe to replace that local subtree in one undoable Editor change set
        // because the fixed joint and both body endpoints are re-authored below.
        ops.push(#{RemovePrim: #{edit_target: edit_target, path: path}});
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: root,
            name: name, type_name: "Xform", reference: (), reference_prim_path: ""}});
    } else if !query_ok(existing) {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: root,
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
    let center_x = if side == "port" { -overlap / 2.0 } else { overlap / 2.0 };
    let placement = assembly_builder::place_plan(edit_target, path,
        [center_x, surface_y, 0.0], [0.0, 0.0, 0.0], ());
    if !placement.ok { return placement; }
    for op in placement.ops { ops.push(op); }
    for item in [
        #{name: "physics:mass", type_name: "float", value: mass.to_string()},
        #{name: "physics:diagonalInertia", type_name: "float3",
          value: "(" + inertia[0].to_string() + ", " + inertia[1].to_string()
            + ", " + inertia[2].to_string() + ")"},
        #{name: "lunco:component_role", type_name: "string",
          value: "physical ramp deck transition rigid-body frame"},
        #{name: "lunco:requirement", type_name: "string",
          value: "GriffinRampRequirements::GRR012_PhysicalDeckTransition"},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: path,
            name: item.name, type_name: item.type_name, value: item.value}});
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
        [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [overlap, thickness, width]);
    if !contact_placement.ok { return contact_placement; }
    for op in contact_placement.ops { ops.push(op); }
    for item in [
        #{name: "size", type_name: "double", value: "1.0"},
        #{name: "purpose", type_name: "token", value: "\"render\""},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "true"},
        #{name: "primvars:displayColor", type_name: "color3f[]",
          value: "[(0.42, 0.26, 0.12)]"},
        #{name: "lunco:component_role", type_name: "string",
          value: "physical ramp deck transition contact surface"},
        #{name: "lunco:requirement", type_name: "string",
          value: "GriffinRampRequirements::GRR012_PhysicalDeckTransition"},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: contact_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    let suffix = if side == "port" { "Port" } else { "Starboard" };
    let joint_name = joint_prefix + suffix;
    let joint_path = root + "/" + joint_name;
    let existing_joint = assembly_builder::composed_query(doc,
        #{path: joint_path, children: false});
    if query_ok(existing_joint) && existing_joint.type_name != "PhysicsFixedJoint" {
        return plan_error(joint_path + ": transition joint must be PhysicsFixedJoint");
    }
    if !query_ok(existing_joint) || migrate_scaled_body {
        ops.push(#{AddPrim: #{edit_target: edit_target, parent_path: root,
            name: joint_name, type_name: "PhysicsFixedJoint", reference: (),
            reference_prim_path: ""}});
    }
    // The fixed joint is deliberately attached to the lander root rather than
    // the rotating ramp body. body1 remains the named nested TransitionPlate;
    // localPos0 is the deck-frame centre and localPos1 is its own origin.
    let anchor_x = if side == "port" { mount_x - overlap / 2.0 }
        else { mount_x + overlap / 2.0 };
    for relation in [
        #{name: "physics:body0", targets: ["/Griffin1"]},
        #{name: "physics:body1", targets: ["/Griffin1/" +
            (if side == "port" { "EgressRampPort" } else { "EgressRampStarboard" })
            + "/" + name]},
    ] {
        ops.push(#{SetRelationship: #{edit_target: edit_target, path: joint_path,
            name: relation.name, targets: relation.targets}});
    }
    for item in [
        #{name: "physics:localPos0", type_name: "point3f",
          value: "(" + anchor_x.to_string() + ", " + mount_y.to_string()
            + ", " + mount_z.to_string() + ")"},
        #{name: "physics:localPos1", type_name: "point3f", value: "(0.0, 0.0, 0.0)"},
        #{name: "physics:collisionEnabled", type_name: "bool", value: "false"},
        #{name: "lunco:component_role", type_name: "string",
          value: "fixed physical deck transition joint"},
        #{name: "lunco:requirement", type_name: "string",
          value: "GriffinRampRequirements::GRR012_PhysicalDeckTransition"},
    ] {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint_path,
            name: item.name, type_name: item.type_name, value: item.value}});
    }
    #{ok: true, path: path, name: name, center_x_m: center_x,
      overlap_m: overlap, mass_kg: mass, inertia_kg_m2: inertia,
      contact_path: contact_path, joint_path: joint_path,
      joint_anchor_x_m: anchor_x, ops: ops}
}

fn isolated_griffin_physical_ramp_stowed_plan(doc, edit_target, root, side) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("isolated_griffin_physical_ramp_stowed_plan requires a document, edit target, and absolute root");
    }
    if side != "port" && side != "starboard" {
        return plan_error("physical ramp side must be port or starboard");
    }
    let source = sysml_requirements::source();
    let length = _sysml_number(source, "physicalRampSurfaceLengthM");
    let width = _sysml_number(source, "physicalRampSurfaceWidthM");
    let thickness = _sysml_number(source, "physicalRampSurfaceThicknessM");
    let rail_height = _sysml_number(source, "physicalRampRailHeightM");
    let rail_width = _sysml_number(source, "physicalRampRailWidthM");
    let stowed_x = _sysml_number(source, "physicalRampStowedSurfaceCenterXM");
    let surface_y = _sysml_number(source, "physicalRampStowedSurfaceCenterYM");
    let rail_y = _sysml_number(source, "physicalRampStowedRailCenterYM");
    let stowed_angle = _sysml_number(source, "physicalRampStowedAngleRad");
    let transition_overlap = _sysml_number(source, "physicalRampDeckTransitionOverlapM");
    let mount_x = _sysml_number(source, if side == "port" {
        "physicalRampPortMountX"
    } else {
        "physicalRampStarboardMountX"
    });
    let mount_y = _sysml_number(source, "physicalRampMountY");
    let mount_z = _sysml_number(source, "physicalRampMountZ");
    let hinge_limit_deg = _sysml_number(source, "physicalRampHingeLimitDeg");
    if length == () || width == () || thickness == () || rail_height == ()
        || rail_width == () || stowed_x == () || surface_y == ()
        || rail_y == () || stowed_angle == () || mount_x == ()
        || mount_y == () || mount_z == () || hinge_limit_deg == ()
        || transition_overlap == ()
        || length <= 0.0 || width <= 0.0 || thickness <= 0.0
        || rail_height <= 0.0 || rail_width <= 0.0 || hinge_limit_deg <= 0.0
        || transition_overlap <= 0.0 || transition_overlap >= length {
        return plan_error("stowed physical ramp SysML datums are incomplete");
    }
    let surface = root + "/Surface";
    let rail = root + "/EdgeRail";
    let inner = root + "/EdgeRailInner";
    for path in [surface, rail, inner] {
        let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
        if !query_ok(prim) || prim.type_name != "Cube" {
            return plan_error(path + ": physical ramp geometry must be an existing Cube");
        }
    }
    let signed_x = if side == "port" { stowed_x } else { -stowed_x };
    let rail_center = width / 2.0 - rail_width / 2.0;
    let ops = [];
    let root_placement = assembly_builder::place_plan(edit_target, root,
        [mount_x, mount_y, mount_z], (), ());
    if !root_placement.ok { return root_placement; }
    for op in root_placement.ops { ops.push(op); }
    for item in [
        #{path: surface, translation: [signed_x, surface_y, 0.0],
          rotation: [0.0, 0.0, 0.0], scale: [length, thickness, width]},
        #{path: rail, translation: [signed_x, rail_y, rail_center],
          rotation: [0.0, 0.0, 0.0], scale: [length, rail_height, rail_width]},
        #{path: inner, translation: [signed_x, rail_y, -rail_center],
          rotation: [0.0, 0.0, 0.0], scale: [length, rail_height, rail_width]},
    ] {
        let placement = assembly_builder::place_plan(edit_target, item.path,
            item.translation, item.rotation, item.scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    let transition = _physical_ramp_transition_ops(doc, edit_target, root, side,
        transition_overlap, thickness, width, surface_y);
    if !transition.ok { return transition; }
    for op in transition.ops { ops.push(op); }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:deployment_angle_rad", type_name: "float",
        value: stowed_angle.to_string()}});
    let joint = if side == "port" {
        "/Griffin1SurfaceOps/Lander/RampHingePort"
    } else {
        "/Griffin1SurfaceOps/Lander/RampHingeStarboard"
    };
    let joint_check = assembly_builder::composed_query(doc, #{path: joint, children: false});
    if query_ok(joint_check) {
        // USD PhysicsRevoluteJoint limits are degrees; SetPorts angle is
        // radians.  Author both the native travel bound and the hinge anchor
        // in the same generation as the stowed geometry.
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint,
            name: "physics:lowerLimit", type_name: "float",
            value: (-hinge_limit_deg).to_string()}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint,
            name: "physics:upperLimit", type_name: "float",
            value: hinge_limit_deg.to_string()}});
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint,
            name: "physics:localPos0", type_name: "point3f",
            value: "(" + mount_x.to_string() + ", " + mount_y.to_string()
                + ", " + mount_z.to_string() + ")"}});
    }
    #{ok: true, kind: "griffin_physical_ramp_stowed_geometry", root: root,
      side: side, length_m: length, width_m: width,
      transition_overlap_m: transition_overlap, hinge_limit_deg: hinge_limit_deg,
      ops: ops, no_op: ops.len() == 0}
}

fn apply_isolated_griffin_physical_ramp_stowed(doc, edit_target, root, side, parent_gen) {
    let plan = isolated_griffin_physical_ramp_stowed_plan(doc, edit_target, root, side);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Author stowed Griffin " + side + " physical ramp", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, side: side, length_m: plan.length_m, width_m: plan.width_m}
}

// Refine the physical ramp in its own vehicle document.  The surface and
// rails are still ordinary USD component geometry, but all dimensions are
// authored through the Editor's typed placement operations.  Keeping this
// operation separate from `isolated_griffin_ramp_plan` matters: the latter
// builds the render-only review component, while this one owns the collision
// envelope used by the mission's FLIP egress.
fn isolated_griffin_physical_ramp_geometry_plan(doc, edit_target, root, side) {
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("isolated_griffin_physical_ramp_geometry_plan requires a document, edit target, and absolute root");
    }
    if side != "port" && side != "starboard" {
        return plan_error("physical ramp side must be port or starboard");
    }
    let source = sysml_requirements::source();
    let length = _sysml_number(source, "physicalRampSurfaceLengthM");
    let width = _sysml_number(source, "physicalRampSurfaceWidthM");
    let thickness = _sysml_number(source, "physicalRampSurfaceThicknessM");
    let rail_height = _sysml_number(source, "physicalRampRailHeightM");
    let rail_width = _sysml_number(source, "physicalRampRailWidthM");
    let surface_y = _sysml_number(source, "physicalRampSurfaceCenterYM");
    let rail_y = _sysml_number(source, "physicalRampRailCenterYM");
    let clearance = _sysml_number(source, "physicalRampRouteClearanceM");
    let transition_overlap = _sysml_number(source, "physicalRampDeckTransitionOverlapM");
    let angle_name = if side == "port" {
        "physicalRampPortDeploymentAngleRad"
    } else {
        "physicalRampStarboardDeploymentAngleRad"
    };
    let angle = _sysml_number(source, angle_name);
    let mount_x = _sysml_number(source, if side == "port" {
        "physicalRampPortMountX"
    } else {
        "physicalRampStarboardMountX"
    });
    let mount_y = _sysml_number(source, "physicalRampMountY");
    let mount_z = _sysml_number(source, "physicalRampMountZ");
    if length == () || width == () || thickness == () || rail_height == ()
        || rail_width == () || surface_y == () || rail_y == ()
        || clearance == () || angle == () || mount_x == ()
        || mount_y == () || mount_z == ()
        || transition_overlap == ()
        || length <= 0.0 || width <= 0.0 || thickness <= 0.0
        || rail_height <= 0.0 || rail_width <= 0.0 || clearance <= 0.0
        || transition_overlap <= 0.0 || transition_overlap >= length {
        return plan_error("physical ramp geometry SysML datums are incomplete");
    }
    let surface = root + "/Surface";
    let rail = root + "/EdgeRail";
    let inner = root + "/EdgeRailInner";
    for path in [surface, rail, inner] {
        let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
        if !query_ok(prim) || prim.type_name != "Cube" {
            return plan_error(path + ": physical ramp geometry must be an existing Cube");
        }
    }
    let angle_deg = angle * 180.0 / 3.141592653589793;
    // The physical source uses the ramp-local +X axis as the deployed travel
    // axis.  Mirror that local frame for starboard so both ramps start at
    // their hinge and descend away from the deck; the positive SysML angle
    // remains the side-local deployment magnitude.
    let travel_angle_deg = if side == "port" {
        angle_deg
    } else {
        180.0 + angle_deg
    };
    // Translation is expressed in the ramp body's local frame, before the
    // child's own rotation is applied. The cosine projection belongs only to
    // a world-space diagnostic, not to the authored USD xform. This keeps the
    // contact span exactly 0..8 m from the port hinge and -8..0 m from the
    // mirrored starboard hinge.
    let center_x = if side == "port" { length / 2.0 } else { -length / 2.0 };
    let rail_center = width / 2.0 - rail_width / 2.0;
    let ops = [];
    let root_placement = assembly_builder::place_plan(edit_target, root,
        [mount_x, mount_y, mount_z], (), ());
    if !root_placement.ok { return root_placement; }
    for op in root_placement.ops { ops.push(op); }
    for item in [
        #{path: surface, translation: [center_x, surface_y, 0.0],
          // Cube scale is the authored full dimension in the physical source
          // (the source ramp is 3.70 m long at scale x=1.85).  Keep the
          // Editor recipe in the same convention as the USD component and
          // the SysML physical study envelope.
          scale: [length, thickness, width]},
        #{path: rail, translation: [center_x, rail_y, rail_center],
          scale: [length, rail_height, rail_width]},
        #{path: inner, translation: [center_x, rail_y, -rail_center],
          scale: [length, rail_height, rail_width]},
    ] {
        let placement = assembly_builder::place_plan(edit_target, item.path,
            item.translation, [0.0, 0.0, travel_angle_deg], item.scale);
        if !placement.ok { return placement; }
        for op in placement.ops { ops.push(op); }
    }
    let transition = _physical_ramp_transition_ops(doc, edit_target, root, side,
        transition_overlap, thickness, width, surface_y);
    if !transition.ok { return transition; }
    for op in transition.ops { ops.push(op); }
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:operational_width_m", type_name: "double", value: width.to_string()}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        name: "lunco:wheel_clearance_m", type_name: "double", value: clearance.to_string()}});
    ops.push(#{SetAttribute: #{edit_target: edit_target, path: root,
        // The physical ramp source declares this custom attribute as float;
        // keep the typed Editor operation aligned with the composed schema.
        name: "lunco:deployment_angle_rad", type_name: "float", value: angle.to_string()}});
    // The physical source joint is a sibling of the ramp body. Keep its
    // lander-frame anchor coherent with the SysML hinge mount when the ramp is
    // promoted from the low visual proxy to the deck-to-ground study envelope.
    let joint = if side == "port" {
        "/Griffin1SurfaceOps/Lander/RampHingePort"
    } else {
        "/Griffin1SurfaceOps/Lander/RampHingeStarboard"
    };
    let joint_check = assembly_builder::composed_query(doc, #{path: joint, children: false});
    if query_ok(joint_check) {
        ops.push(#{SetAttribute: #{edit_target: edit_target, path: joint,
            name: "physics:localPos0", type_name: "point3f",
            value: "(" + mount_x.to_string() + ", " + mount_y.to_string()
                + ", " + mount_z.to_string() + ")"}});
    }
    #{ok: true, kind: "griffin_physical_ramp_geometry", root: root,
      side: side, width_m: width, clearance_m: clearance,
      transition_overlap_m: transition_overlap,
      paths: [surface, rail, inner, transition.path],
      ops: ops, no_op: ops.len() == 0}
}

fn apply_isolated_griffin_physical_ramp_geometry(doc, edit_target, root, side, parent_gen) {
    let plan = isolated_griffin_physical_ramp_geometry_plan(doc, edit_target, root, side);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc,
        "Refine isolated Griffin " + side + " physical ramp geometry", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      root: root, side: side, width_m: plan.width_m}
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
    let geometry = _isolated_ramp_visual_geometry_ops(doc, edit_target, path);
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
// recipe has been removed.  The component file owns RampSurface, rails,
// treads, support members, and the mount frame; the assembly owns only the
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
    if type_of(ramp_state) != "EnumValue" || ramp_state.literal != "Stowed" {
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

fn apply_isolated_griffin(doc, edit_target, root, parent_gen) {
    let plan = isolated_griffin_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build isolated Griffin visual", plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, command: command,
      component_count: plan.component_count, root: root}
}

fn apply_isolated_flip(doc, edit_target, root, parent_gen) {
    let plan = isolated_flip_component_plan(doc, edit_target, root);
    if !plan.ok || plan.no_op { return plan; }
    let command = assembly_edit::batch(doc, "Build isolated FLIP visual", plan.ops, parent_gen);
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
    let source = sysml_requirements::source();
    let asset = sysml_requirements::text(source,
        griffin_spec::qualified_attribute_name("visualTerrainAsset"));
    let shader = sysml_requirements::text(source,
        griffin_spec::qualified_attribute_name("visualTerrainShaderAsset"));
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
