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

fn plan_error(message) {
    #{ ok: false, kind: "griffin_visual_component_assembly", error: message, ops: [] }
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
    sysml_requirements::number(report, name)
}

fn flip_steering_angles() {
    let report = sysml_requirements::source();
    let front = _sysml_number(report, "frontSteeringAngleDeg");
    let rear = _sysml_number(report, "rearSteeringAngleDeg");
    if front == () || rear == () { return (); }
    [front, rear]
}

fn visual_component_specs(root) {
    let lander = root + "/Griffin1";
    let rover = root + "/FLIP";
    let steering = flip_steering_angles();
    if steering == () {
        return [];
    }
    let specs = [
        #{parent: lander, name: "Bus", type_name: "Xform",
          asset: component_asset("lander/griffin_bus_visual.usda"),
          translation: [0.0, 3.20, 0.0], rotation: (), scale: ()},
        #{parent: lander, name: "TankPX", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [1.30, 5.85, -1.15], rotation: (), scale: ()},
        #{parent: lander, name: "TankNX", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [-1.30, 5.85, -1.15], rotation: (), scale: ()},
        #{parent: lander, name: "TankPZ", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [1.30, 5.85, 1.15], rotation: (), scale: ()},
        #{parent: lander, name: "TankNZ", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [-1.30, 5.85, 1.15], rotation: (), scale: ()},
        #{parent: lander, name: "LegPX", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [1.75, 2.35, -1.25], rotation: (), scale: ()},
        #{parent: lander, name: "LegNX", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [-1.75, 2.35, -1.25], rotation: (), scale: ()},
        #{parent: lander, name: "LegPZ", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [1.75, 2.35, 1.25], rotation: (), scale: ()},
        #{parent: lander, name: "LegNZ", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [-1.75, 2.35, 1.25], rotation: (), scale: ()},
        #{parent: lander, name: "SolarPanelPort", type_name: "Xform",
          asset: component_asset("lander/griffin_solar_panel_visual.usda"),
          translation: [2.65, 3.35, 0.0], rotation: [0.0, 0.0, 90.0], scale: ()},
        #{parent: lander, name: "SolarPanelStarboard", type_name: "Xform",
          asset: component_asset("lander/griffin_solar_panel_visual.usda"),
          translation: [-2.65, 3.35, 0.0], rotation: [0.0, 0.0, -90.0], scale: ()},
        #{parent: lander, name: "EgressRampPort", type_name: "Xform",
          asset: component_asset("lander/griffin_ramp_visual.usda"),
          translation: [2.60, 1.65, 0.0], rotation: (), scale: ()},
        #{parent: lander, name: "EgressRampStarboard", type_name: "Xform",
          asset: component_asset("lander/griffin_ramp_visual.usda"),
          translation: [-2.60, 1.65, 0.0], rotation: [0.0, 180.0, 0.0], scale: ()},
        #{parent: rover, name: "Chassis", type_name: "Xform",
          asset: component_asset("rover/flip_chassis_visual.usda"),
          translation: (), rotation: (), scale: ()},
        #{parent: rover, name: "SensorMast", type_name: "Xform",
          asset: component_asset("rover/flip_sensor_mast_visual.usda"),
          translation: (), rotation: (), scale: ()},
        #{parent: rover, name: "SolarArray", type_name: "Xform",
          asset: component_asset("rover/flip_solar_panel_visual.usda"),
          translation: [0.0, 1.45, 1.30], rotation: [18.0, 0.0, 0.0], scale: ()},
    ];
    // FLIP is a four-wheel directional rover.  The front and rear steering
    // angles are intentionally explicit so the visual communicates the
    // steering architecture instead of looking like a six-wheel box proxy.
    let wheel_names = griffin_spec::visual_rover_wheel_names();
    let wheel_positions = [
        [-1.75, -0.42, -1.15],
        [-1.75, -0.42, 1.15],
        [1.75, -0.42, -1.15],
        [1.75, -0.42, 1.15],
    ];
    if wheel_names.len() != wheel_positions.len() {
        return [];
    }
    for index in 0..wheel_names.len() {
        let name = wheel_names[index];
        let steering_index = if name.starts_with("F") { 0 } else { 1 };
        let station = rover + "/Suspension_" + name;
        specs.push(#{parent: station, name: "Wheel_" + name, type_name: "Xform",
            asset: component_asset("rover/flip_wheel_visual.usda"),
            translation: (), rotation: [0.0, steering[steering_index], 0.0],
            scale: (), index: index});
    }
    let engine_names = griffin_spec::main_engine_names();
    let engine_positions = [
        [0.0, 1.75, 0.0], [1.0, 1.75, 0.0], [-1.0, 1.75, 0.0],
        [0.0, 1.75, 1.0], [0.0, 1.75, -1.0], [0.9, 1.75, 0.9],
        [-0.9, 1.75, -0.9],
    ];
    if engine_names.len() != engine_positions.len() {
        return [];
    }
    for index in 0..engine_names.len() {
        specs.push(#{parent: lander + "/Nozzle/MainEngineCluster", name: engine_names[index],
            type_name: "Xform", asset: component_asset("lander/griffin_engine_bell_visual.usda"),
            translation: engine_positions[index], rotation: (), scale: ()});
    }
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
    let details = [
        // Hexagonal bus corner rails make the silhouette read as a faceted
        // equipment module even in an oblique viewport.
        #{parent: bus, name: "HexCornerRailFront", shape: "cube", translation: [0.0, 0.0, 2.58], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailRear", shape: "cube", translation: [0.0, 0.0, -2.58], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailPortFront", shape: "cube", translation: [2.53, 0.0, 1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailPortRear", shape: "cube", translation: [2.53, 0.0, -1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailStarboardFront", shape: "cube", translation: [-2.53, 0.0, 1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailStarboardRear", shape: "cube", translation: [-2.53, 0.0, -1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        // The engine skirt is a four-beam frame around the seven bells; it
        // keeps the nozzles visually attached to the lower bus deck.
        #{parent: cluster, name: "EngineSkirtFront", shape: "cube", translation: [0.0, 1.68, 1.55], scale: [1.65, 0.10, 0.10], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtRear", shape: "cube", translation: [0.0, 1.68, -1.55], scale: [1.65, 0.10, 0.10], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtPort", shape: "cube", translation: [1.55, 1.68, 0.0], scale: [0.10, 0.10, 1.55], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtStarboard", shape: "cube", translation: [-1.55, 1.68, 0.0], scale: [0.10, 0.10, 1.55], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineAdapterPlate", shape: "cube", translation: [0.0, 1.70, 0.0], scale: [1.42, 0.06, 1.42], color: [0.18, 0.20, 0.23]},
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
    ];
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
// are derived once by `align_visual_mounts`; the durable contract is the
// socket/frame relationship, so a later component replacement can be snapped
// by the generic frame-alignment tool without hand-editing USDA.
fn _mount_frame_specs(root) {
    let bus = root + "/Griffin1/Bus";
    let port = root + "/Griffin1/EgressRampPort";
    let starboard = root + "/Griffin1/EgressRampStarboard";
    [
        #{parent: bus, name: "RampSocketPort", translation: [2.60, -1.10, 0.0], rotation: (), socket: true},
        #{parent: bus, name: "RampSocketStarboard", translation: [-2.60, -1.10, 0.0], rotation: (), socket: true},
        #{parent: port, name: "MountFrame", translation: [0.725, 0.0, 0.0], rotation: (), socket: false},
        #{parent: starboard, name: "MountFrame", translation: [0.725, 0.0, 0.0], rotation: [0.0, 180.0, 0.0], socket: false},
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
    // Deactivate obsolete middle stations from older six-wheel visual
    // revisions through a reversible authored opinion.  RemovePrim would be
    // invalid here because those children are owned by the referenced vehicle
    // source layer; SetActive is the generic USD override for that case.
    let rover = root + "/FLIP";
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
        value: "\"four directional wheels, white equipment box, sensor mast, fixed solar-array proxy\""}});
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
