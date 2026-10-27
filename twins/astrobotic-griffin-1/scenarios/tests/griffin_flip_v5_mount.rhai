// Authored assembly acceptance only. This does not claim landing or driving.
fn prim(doc, path, bounds, rels) {
    query("QueryUsdPrim", #{doc_id: doc, path: path,
        collision_bounds: bounds, rels: rels})
}

fn verify(doc, root) {
    let rover_path = root + "/FLIP";
    let lander_path = root + "/Lander";
    let rover = prim(doc, rover_path, true, []);
    let lander = prim(doc, lander_path, false, []);
    let deck = prim(doc, lander_path + "/RoverPayloadDeckCollider", true, []);
    let adapter = prim(doc, root + "/FLIPPayloadAdapterJoint", false,
        ["physics:body0", "physics:body1"]);
    let tolerance = 0.000001;
    // This scene has an identity root; lander yaw preserves the vertical datum.
    // Use authored doubles; world_position is a presentation readback.
    let deck_local_y = deck.attrs["points"][0][1];
    for point in deck.attrs["points"] {
        if point[1] > deck_local_y { deck_local_y = point[1]; }
    }
    let deck_y = lander.attrs["xformOp:translate"][1] + deck_local_y;
    let checks = [];
    checks.push(#{name: "deck seating",
        pass: (rover.collision_bounds.min[1] - deck_y).abs() <= tolerance});
    checks.push(#{name: "adapter endpoints",
        pass: adapter.type_name == "PhysicsFixedJoint"
            && adapter.relationships["physics:body0"] == [lander_path]
            && adapter.relationships["physics:body1"] == [rover_path]});
    let anchor0 = lander.attrs["xformOp:translate"][1] + adapter.attrs["physics:localPos0"][1];
    let anchor1 = rover.attrs["xformOp:translate"][1] + adapter.attrs["physics:localPos1"][1];
    checks.push(#{name: "adapter vertical frame alignment",
        pass: (anchor0 - anchor1).abs() <= tolerance});
    let yaw = (rover.attrs["xformOp:rotateXYZ"][1]
        - lander.attrs["xformOp:rotateY"]) * acos(-1.0) / 180.0;
    // CAD forward is -Z. The port rail runs outboard along lander +X.
    checks.push(#{name: "mounted forward points along port rails",
        pass: (-sin(yaw) - 1.0).abs() <= tolerance && cos(yaw).abs() <= tolerance});
    let q0 = adapter.attrs["physics:localRot0"];
    let q1 = adapter.attrs["physics:localRot1"];
    checks.push(#{name: "adapter angular frame alignment",
        pass: q0 != () && q1 != ()
            && (q0[0] - cos(yaw / 2.0)).abs() <= tolerance
            && q0[1].abs() <= tolerance
            && (q0[2] - sin(yaw / 2.0)).abs() <= tolerance
            && q0[3].abs() <= tolerance
            && (q1[0] - 1.0).abs() <= tolerance
            && q1[1].abs() <= tolerance && q1[2].abs() <= tolerance
            && q1[3].abs() <= tolerance});
    let panel = prim(doc, rover_path + "/PanelHinge", false,
        ["physics:body0", "physics:body1"]);
    checks.push(#{name: "panel hinge retained",
        pass: panel.relationships["physics:body0"] == [rover_path]
            && panel.relationships["physics:body1"] == [rover_path + "/SolarMechanism"]});
    for station in ["FL", "FR", "RL", "RR"] {
        let wheel_path = rover_path + "/Suspension_" + station + "/Wheel_" + station;
        let wheel = prim(doc, wheel_path, false, []);
        let hinge = prim(doc, rover_path + "/Wheel_" + station + "_Hinge", false,
            ["physics:body0", "physics:body1"]);
        let motor = prim(doc, rover_path + "/Motor_" + station, false, []);
        let shaft = prim(doc, rover_path + "/Shaft_" + station, false, []);
        checks.push(#{name: "wheel and drive " + station,
            pass: wheel.active && wheel.type_name == "Cylinder"
                && wheel.attrs["radius"] > 0.0 && motor.active && shaft.active
                && hinge.relationships["physics:body1"] == [wheel_path]});
    }
    let ok = true;
    for row in checks { if !row.pass { ok = false; } }
    let result = #{ok: ok, scope: "composed assembly; no dynamic acceptance", checks: checks,
        deck_y: deck_y, rover_bottom_y: rover.collision_bounds.min[1],
        adapter_frame_error_m: (anchor0 - anchor1).abs()};
    print("GRIFFIN_FLIP_V5_MOUNT: " + if ok { "PASS" } else { "FAIL" });
    result
}
