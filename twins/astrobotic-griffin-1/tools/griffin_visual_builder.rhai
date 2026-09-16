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

// Component documents are inspected through the same Editor readback API
// used for selection.  QueryUsdPrim is a live-stage query and cannot resolve
// an isolated component's default-prim path after an asset-only edit.
fn _component_query(doc, path) {
    let record = assembly_edit::inspect(doc, path);
    if record == () || record.prim == () || record.prim.exists != true {
        return #{ok: false, error: path + ": component prim is missing"};
    }
    #{ok: true, type_name: record.prim.type, path: path}
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

fn visual_component_specs(root) {
    let lander = root + "/Griffin1";
    let rover = root + "/FLIP";
    let steering = flip_steering_angles();
    let port_mount_x = _ramp_number("rampPortMountX");
    let starboard_mount_x = _ramp_number("rampStarboardMountX");
    let mount_y = _ramp_number("rampMountY");
    let mount_z = _ramp_number("rampMountZ");
    let port_angle = _ramp_angle_deg("port");
    let starboard_angle = _ramp_angle_deg("starboard");
    let tank_x = griffin_spec::component_tank_station_x();
    let tank_y = griffin_spec::component_tank_station_y();
    let tank_z = griffin_spec::component_tank_station_z();
    let leg_x = griffin_spec::component_leg_station_x();
    let leg_y = griffin_spec::component_leg_station_y();
    let leg_z = griffin_spec::component_leg_station_z();
    let solar_x = griffin_spec::component_solar_station_x();
    let solar_y = griffin_spec::component_solar_station_y();
    let solar_z = griffin_spec::component_solar_station_z();
    let engine_x = griffin_spec::component_engine_station_x();
    let engine_y = griffin_spec::component_engine_station_y();
    let engine_z = griffin_spec::component_engine_station_z();
    let rover_solar_mount = griffin_spec::rover_solar_array_mount();
    let rover_solar_tilt = griffin_spec::rover_solar_array_tilt_deg();
    if steering == () || port_mount_x == () || starboard_mount_x == ()
        || mount_y == () || mount_z == () || port_angle == ()
        || starboard_angle == () || griffin_spec::component_bus_mount_y() == ()
        || tank_x.len() != 4 || tank_y.len() != 4 || tank_z.len() != 4
        || leg_x.len() != 4 || leg_y.len() != 4 || leg_z.len() != 4
        || solar_x.len() != 2 || solar_y.len() != 2 || solar_z.len() != 2
        || rover_solar_mount.len() != 3 || rover_solar_tilt == ()
        || engine_x.len() != 7 || engine_y.len() != 7 || engine_z.len() != 7 {
        return [];
    }
    let specs = [
        #{parent: lander, name: "Bus", type_name: "Xform",
          asset: component_asset("lander/griffin_bus_visual.usda"),
          translation: [0.0, griffin_spec::component_bus_mount_y(), 0.0], rotation: (), scale: ()},
        #{parent: lander, name: "TankPX", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[0], tank_y[0], tank_z[0]], rotation: (), scale: ()},
        #{parent: lander, name: "TankNX", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[1], tank_y[1], tank_z[1]], rotation: (), scale: ()},
        #{parent: lander, name: "TankPZ", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[2], tank_y[2], tank_z[2]], rotation: (), scale: ()},
        #{parent: lander, name: "TankNZ", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[3], tank_y[3], tank_z[3]], rotation: (), scale: ()},
        #{parent: lander, name: "LegPX", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[0], leg_y[0], leg_z[0]], rotation: (), scale: ()},
        #{parent: lander, name: "LegNX", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[1], leg_y[1], leg_z[1]], rotation: (), scale: ()},
        #{parent: lander, name: "LegPZ", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[2], leg_y[2], leg_z[2]], rotation: (), scale: ()},
        #{parent: lander, name: "LegNZ", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[3], leg_y[3], leg_z[3]], rotation: (), scale: ()},
        #{parent: lander, name: "SolarPanelPort", type_name: "Xform",
          asset: component_asset("lander/griffin_solar_panel_visual.usda"),
          translation: [solar_x[0], solar_y[0], solar_z[0]], rotation: [0.0, 0.0, 90.0], scale: ()},
        #{parent: lander, name: "SolarPanelStarboard", type_name: "Xform",
          asset: component_asset("lander/griffin_solar_panel_visual.usda"),
          translation: [solar_x[1], solar_y[1], solar_z[1]], rotation: [0.0, 0.0, -90.0], scale: ()},
        #{parent: lander, name: "EgressRampPort", type_name: "Xform",
          asset: component_asset("lander/griffin_ramp_visual.usda"),
          translation: [port_mount_x, mount_y, mount_z], rotation: [0.0, 0.0, port_angle], scale: ()},
        #{parent: lander, name: "EgressRampStarboard", type_name: "Xform",
          asset: component_asset("lander/griffin_ramp_visual.usda"),
          translation: [starboard_mount_x, mount_y, mount_z], rotation: [0.0, 180.0, starboard_angle], scale: ()},
        #{parent: rover, name: "Chassis", type_name: "Xform",
          asset: component_asset("rover/flip_chassis_visual.usda"),
          translation: (), rotation: (), scale: ()},
        #{parent: rover, name: "SensorMast", type_name: "Xform",
          asset: component_asset("rover/flip_sensor_mast_visual.usda"),
          translation: (), rotation: (), scale: ()},
        #{parent: rover, name: "SolarArray", type_name: "Xform",
          asset: component_asset("rover/flip_solar_panel_visual.usda"),
          translation: rover_solar_mount, rotation: [rover_solar_tilt, 0.0, 0.0], scale: ()},
    ];
    // FLIP is a four-wheel directional rover.  The front and rear steering
    // angles are intentionally explicit so the visual communicates the
    // steering architecture instead of looking like a six-wheel box proxy.
    let wheel_names = griffin_spec::visual_rover_wheel_names();
    let wheel_x = griffin_spec::rover_wheel_station_x();
    let wheel_y = griffin_spec::rover_wheel_station_y();
    let wheel_z = griffin_spec::rover_wheel_station_z();
    if wheel_names.len() != 4 || wheel_x.len() != 4
        || wheel_y.len() != 4 || wheel_z.len() != 4 {
        return [];
    }
    for index in 0..wheel_names.len() {
        let name = wheel_names[index];
        let steering_index = if name.starts_with("F") { 0 } else { 1 };
        let station = rover + "/Suspension_" + name;
        specs.push(#{parent: station, name: "Wheel_" + name, type_name: "Xform",
            asset: component_asset("rover/flip_wheel_visual.usda"),
            translation: [0.0, 0.0, 0.0], rotation: [0.0, steering[steering_index], 0.0],
            scale: (), index: index});
    }
    let engine_names = griffin_spec::main_engine_names();
    if engine_names.len() != engine_x.len() {
        return [];
    }
    for index in 0..engine_names.len() {
        specs.push(#{parent: lander + "/Nozzle/MainEngineCluster", name: engine_names[index],
            type_name: "Xform", asset: component_asset("lander/griffin_engine_bell_visual.usda"),
            translation: [engine_x[index], engine_y[index], engine_z[index]], rotation: (), scale: ()});
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
    let port_mount_x = _ramp_number("rampPortMountX");
    let starboard_mount_x = _ramp_number("rampStarboardMountX");
    let mount_y = _ramp_number("rampMountY");
    let mount_z = _ramp_number("rampMountZ");
    let port_angle = _ramp_angle_deg("port");
    let starboard_angle = _ramp_angle_deg("starboard");
    let tank_x = griffin_spec::component_tank_station_x();
    let tank_y = griffin_spec::component_tank_station_y();
    let tank_z = griffin_spec::component_tank_station_z();
    let leg_x = griffin_spec::component_leg_station_x();
    let leg_y = griffin_spec::component_leg_station_y();
    let leg_z = griffin_spec::component_leg_station_z();
    let solar_x = griffin_spec::component_solar_station_x();
    let solar_y = griffin_spec::component_solar_station_y();
    let solar_z = griffin_spec::component_solar_station_z();
    let engine_x = griffin_spec::component_engine_station_x();
    let engine_y = griffin_spec::component_engine_station_y();
    let engine_z = griffin_spec::component_engine_station_z();
    if port_mount_x == () || starboard_mount_x == () || mount_y == ()
        || mount_z == () || port_angle == () || starboard_angle == ()
        || griffin_spec::component_bus_mount_y() == ()
        || tank_x.len() != 4 || tank_y.len() != 4 || tank_z.len() != 4
        || leg_x.len() != 4 || leg_y.len() != 4 || leg_z.len() != 4
        || solar_x.len() != 2 || solar_y.len() != 2 || solar_z.len() != 2
        || engine_x.len() != 7 || engine_y.len() != 7 || engine_z.len() != 7 {
        return [];
    }
    let specs = [
        #{parent: root, name: "Bus", type_name: "Xform",
          asset: component_asset("lander/griffin_bus_visual.usda"),
          translation: [0.0, griffin_spec::component_bus_mount_y(), 0.0], rotation: (), scale: ()},
        #{parent: root, name: "TankPX", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[0], tank_y[0], tank_z[0]], rotation: (), scale: ()},
        #{parent: root, name: "TankNX", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[1], tank_y[1], tank_z[1]], rotation: (), scale: ()},
        #{parent: root, name: "TankPZ", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[2], tank_y[2], tank_z[2]], rotation: (), scale: ()},
        #{parent: root, name: "TankNZ", type_name: "Xform",
          asset: component_asset("lander/griffin_tank_visual.usda"),
          translation: [tank_x[3], tank_y[3], tank_z[3]], rotation: (), scale: ()},
        #{parent: root, name: "LegPX", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[0], leg_y[0], leg_z[0]], rotation: (), scale: ()},
        #{parent: root, name: "LegNX", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[1], leg_y[1], leg_z[1]], rotation: (), scale: ()},
        #{parent: root, name: "LegPZ", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[2], leg_y[2], leg_z[2]], rotation: (), scale: ()},
        #{parent: root, name: "LegNZ", type_name: "Xform",
          asset: component_asset("lander/griffin_landing_leg_visual.usda"),
          translation: [leg_x[3], leg_y[3], leg_z[3]], rotation: (), scale: ()},
        #{parent: root, name: "SolarPanelPort", type_name: "Xform",
          asset: component_asset("lander/griffin_solar_panel_visual.usda"),
          translation: [solar_x[0], solar_y[0], solar_z[0]], rotation: [0.0, 0.0, 90.0], scale: ()},
        #{parent: root, name: "SolarPanelStarboard", type_name: "Xform",
          asset: component_asset("lander/griffin_solar_panel_visual.usda"),
          translation: [solar_x[1], solar_y[1], solar_z[1]], rotation: [0.0, 0.0, -90.0], scale: ()},
        #{parent: root, name: "EgressRampPort", type_name: "Xform",
          asset: component_asset("lander/griffin_ramp_visual.usda"),
          translation: [port_mount_x, mount_y, mount_z], rotation: [0.0, 0.0, port_angle], scale: ()},
        #{parent: root, name: "EgressRampStarboard", type_name: "Xform",
          asset: component_asset("lander/griffin_ramp_visual.usda"),
          translation: [starboard_mount_x, mount_y, mount_z], rotation: [0.0, 180.0, starboard_angle], scale: ()},
    ];
    let steering = flip_steering_angles();
    if steering == () { return []; }
    let cluster = root + "/Nozzle/MainEngineCluster";
    let engines = griffin_spec::main_engine_names();
    if engines.len() != engine_x.len() { return []; }
    for index in 0..engines.len() {
        specs.push(#{parent: cluster, name: engines[index], type_name: "Xform",
            asset: component_asset("lander/griffin_engine_bell_visual.usda"),
            translation: [engine_x[index], engine_y[index], engine_z[index]], rotation: (), scale: ()});
    }
    specs
}

fn _isolated_flip_specs(root) {
    let steering = flip_steering_angles();
    let solar_mount = griffin_spec::rover_solar_array_mount();
    let solar_tilt = griffin_spec::rover_solar_array_tilt_deg();
    if steering == () || solar_mount.len() != 3 || solar_tilt == () { return []; }
    let specs = [
        #{parent: root, name: "Chassis", type_name: "Xform",
          asset: component_asset("rover/flip_chassis_visual.usda"),
          translation: [0.0, 0.0, 0.0], rotation: (), scale: ()},
        #{parent: root, name: "SensorMast", type_name: "Xform",
          asset: component_asset("rover/flip_sensor_mast_visual.usda"),
          translation: [0.0, 0.0, 0.0], rotation: (), scale: ()},
        #{parent: root, name: "SolarArray", type_name: "Xform",
          asset: component_asset("rover/flip_solar_panel_visual.usda"),
          translation: solar_mount, rotation: [solar_tilt, 0.0, 0.0], scale: ()},
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
    let details = [
        // Rails follow the six footprint corners, rather than a rectangular
        // bounding box, so the body reads as the public faceted Griffin form.
        #{parent: bus, name: "HexCornerRailFront", shape: "cube", translation: [0.0, 0.0, 2.58], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailRear", shape: "cube", translation: [0.0, 0.0, -2.58], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailPortFront", shape: "cube", translation: [2.53, 0.0, 1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailPortRear", shape: "cube", translation: [2.53, 0.0, -1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailStarboardFront", shape: "cube", translation: [-2.53, 0.0, 1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        #{parent: bus, name: "HexCornerRailStarboardRear", shape: "cube", translation: [-2.53, 0.0, -1.30], scale: [0.10, 1.42, 0.10], color: [0.16, 0.18, 0.21]},
        // A dark adapter/skirt makes the seven engine bells read as one
        // mounted propulsion module instead of disconnected cones.
        #{parent: cluster, name: "EngineSkirtFront", shape: "cube", translation: [0.0, 1.68, 1.55], scale: [1.65, 0.10, 0.10], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtRear", shape: "cube", translation: [0.0, 1.68, -1.55], scale: [1.65, 0.10, 0.10], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtPort", shape: "cube", translation: [1.55, 1.68, 0.0], scale: [0.10, 0.10, 1.55], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineSkirtStarboard", shape: "cube", translation: [-1.55, 1.68, 0.0], scale: [0.10, 0.10, 1.55], color: [0.10, 0.12, 0.15]},
        #{parent: cluster, name: "EngineAdapterPlate", shape: "cube", translation: [0.0, 1.70, 0.0], scale: [1.42, 0.06, 1.42], color: [0.18, 0.20, 0.23]},
        // Mount plate/pin at the actual ramp hinge datum.  This avoids the
        // old offset that left the ramp rail visibly detached from the bus.
        #{parent: root + "/EgressRampPort", name: "MountPlate", shape: "cube", translation: [1.60, 0.0, 0.0], scale: [0.12, 0.22, 0.92], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/EgressRampPort", name: "HingePin", shape: "cylinder", translation: [1.60, 0.0, 0.0], radius: 0.12, height: 0.92, axis: "Z", color: [0.10, 0.12, 0.15]},
        #{parent: root + "/EgressRampStarboard", name: "MountPlate", shape: "cube", translation: [1.60, 0.0, 0.0], scale: [0.12, 0.22, 0.92], color: [0.12, 0.14, 0.17]},
        #{parent: root + "/EgressRampStarboard", name: "HingePin", shape: "cylinder", translation: [1.60, 0.0, 0.0], radius: 0.12, height: 0.92, axis: "Z", color: [0.10, 0.12, 0.15]},
    ];
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

// Refine the bus shell in-place without replacing the component identity.
// The original visual asset used rectangular service/deck slabs; these two
// authored mesh replacements retain their stable paths while restoring the
// six-sided Griffin silhouette.  Dimensions come from GriffinLanderComponent,
// and the operation is still submitted through the generic USD journal.
fn _hex_prism_points(width, depth, half_height) {
    let x = width / 2.0;
    let z = depth / 2.0;
    let q = depth / 4.0;
    [
        [0.0, -half_height, z], [x, -half_height, q],
        [x, -half_height, -q], [0.0, -half_height, -z],
        [-x, -half_height, -q], [-x, -half_height, q],
        [0.0, half_height, z], [x, half_height, q],
        [x, half_height, -q], [0.0, half_height, -z],
        [-x, half_height, -q], [-x, half_height, q],
    ]
}

fn _hex_prism_topology() {
    [6, 6, 4, 4, 4, 4, 4, 4]
}

fn _hex_prism_indices() {
    [0, 1, 2, 3, 4, 5, 6, 11, 10, 9, 8, 7,
     0, 6, 7, 1, 1, 7, 8, 2, 2, 8, 9, 3,
     3, 9, 10, 4, 4, 10, 11, 5, 5, 11, 6, 0]
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
    let mesh = assembly_builder::mesh_shape_plan(edit_target, parent, name,
        _hex_prism_points(width, depth, height / 2.0), _hex_prism_topology(),
        _hex_prism_indices(), color, false);
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
    if doc == () || edit_target == () || !absolute_root(root) {
        return plan_error("refine_griffin_bus_component_plan requires a document, edit target, and absolute root");
    }
    let source = sysml_requirements::source();
    let width = _sysml_number(source, "bodyWidthM");
    let depth = _sysml_number(source, "bodyDepthM");
    if width == () || depth == () || width <= 0.0 || depth <= 0.0 {
        return plan_error("Griffin lander metric bus envelope is missing");
    }
    let ops = [];
    let top = _refine_hex_slab(doc, edit_target, root, "TopDeck",
        width + 0.35, depth + 0.35, 0.24, [0.0, 1.55, 0.0], [0.22, 0.25, 0.29]);
    if !top.ok { return top; }
    for op in top.ops { ops.push(op); }
    let lower = _refine_hex_slab(doc, edit_target, root, "LowerServiceSkirt",
        width - 0.10, depth - 0.10, 0.36, [0.0, -1.56, 0.0], [0.10, 0.12, 0.15]);
    if !lower.ok { return lower; }
    for op in lower.ops { ops.push(op); }
    #{ok: true, kind: "griffin_bus_hex_refinement", root: root,
      paths: [root + "/TopDeck", root + "/LowerServiceSkirt"],
      ops: ops, no_op: ops.len() == 0}
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
    let support_radius = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportRadiusM");
    let support_height = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportHeightM");
    let support_y = sysml_requirements::number(source, "GriffinTankRequirements::GriffinPropellantTankAssembly::supportCenterYM");
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
        || support_radius == () || support_height == () || support_y == ();
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
    let width = _sysml_number(source, "engineClusterWidthM");
    let depth = _sysml_number(source, "engineClusterDepthM");
    let height = _sysml_number(source, "engineSkirtHeightM");
    let section = _sysml_number(source, "engineSkirtRailSectionM");
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
        #{path: paths[0], translation: [0.0, rail_y, rail_z], scale: [width / 2.0, height / 2.0, section / 2.0]},
        #{path: paths[1], translation: [0.0, rail_y, -rail_z], scale: [width / 2.0, height / 2.0, section / 2.0]},
        #{path: paths[2], translation: [rail_x, rail_y, 0.0], scale: [section / 2.0, height / 2.0, depth / 2.0]},
        #{path: paths[3], translation: [-rail_x, rail_y, 0.0], scale: [section / 2.0, height / 2.0, depth / 2.0]},
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
            1.0, [adapter_width / 2.0, adapter_height / 2.0, adapter_depth / 2.0], false);
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
