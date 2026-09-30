import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
// Standalone Griffin landing-leg verification. Typed identities and stations
// come from GriffinVisualConfigurationRequirements; the lander owns the count.

const PACKAGE = "GriffinLandingLegRequirements";
const VERIFICATION = "Verify_GriffinLandingLegRequirements";
const SPRING_FRAME_CONSTRAINT = PACKAGE + "::GLLC009_SpringFrameAlignment";
const PI = 3.141592653589793;

fn own(name) { PACKAGE + "::GriffinLandingLegAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

// Keep this component pass proportional to its own source contract.
fn leg_source() {
    let attributes = [parent("legCount"), visual("landingLegInstances"),
        visual("legStations"), visual("legStationRotationYDeg"),
        "Griffin1Requirements::PublicMissionContext::landingVehicleReferenceTouchdownY",
        "Griffin1Requirements::PublicMissionContext::siteSurfaceY"];
    for name in ["usdRootPath", "childNames", "strutAxis", "strutRadiusM",
        "shockPistonRadiusM", "footPadRadiusM", "footPadHeightM", "footPadCenterYM",
        "physicalLegRotationToleranceDeg", "physicalLegPlacementToleranceM",
        "springLowerLimitM", "springUpperLimitM", "springStiffnessNPerM",
        "springDampingNsPerM", "springMaxForceN", "springTargetVelocityMps",
        "springPoseToleranceM"] { attributes.push(own(name)); }
    let requirements = [];
    for name in ["gll001", "gll002", "gll003", "gll004", "gll005",
        "gll006", "gll007", "gll008", "gll009", "gll010"] {
        requirements.push(PACKAGE + "::" + name);
    }
    sysml_requirements::source_with_selection(attributes, requirements,
        [PACKAGE + "::" + VERIFICATION])
}

fn position(id, path, index, expected) {
    #{id: id, component: "landing_leg", requirement: "gll005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn joint_relationship(id, path, relationship, target) {
    #{id: id, component: "landing_leg", requirement: "gll009",
      verification: VERIFICATION, kind: "relationship", path: path,
      rel: relationship, targets: [target]}
}

fn joint_frame_component(id, path, attr, index, expected, tolerance) {
    #{id: id, component: "landing_leg", requirement: "gll009",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: attr, index: index, expected: expected, tolerance: tolerance}
}

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn _joint_frame_observation(root, name) {
    let body_path = root + "/" + name;
    let joint_path = root + "/" + name + "_Spring";
    let snapshot = query("QueryUsdPrims", #{paths: [body_path, joint_path],
        attrs: ["xformOp:rotateXYZ", "physics:localRot0", "physics:localRot1"]});
    if snapshot == () || snapshot.error != () || snapshot.records == () {
        let detail = if snapshot == () { "QueryUsdPrims returned no response" }
            else if snapshot.error != () { snapshot.error }
            else { "QueryUsdPrims returned no records" };
        return #{ok: false, error: detail, joint: ()};
    }
    let body = ();
    let joint = ();
    for record in snapshot.records {
        if record.path == body_path { body = record; }
        else if record.path == joint_path { joint = record; }
    }
    if body == () || joint == () {
        return #{ok: false, error: "batched frame snapshot omitted the requested leg body or spring joint", joint: joint};
    }
    let body_euler = body.attrs["xformOp:rotateXYZ"];
    let local_rot0 = joint.attrs["physics:localRot0"];
    let local_rot1 = joint.attrs["physics:localRot1"];
    if type_of(body_euler) != "array" || body_euler.len() != 3
        || type_of(local_rot0) != "array" || local_rot0.len() != 4
        || type_of(local_rot1) != "array" || local_rot1.len() != 4 {
        return #{ok: false, error: "composed leg pose or authored spring frame is missing or malformed", joint: joint};
    }
    // QueryUsdPrims returns USD quaternions in (w, x, y, z) order; the native
    // Rhai constructor accepts (x, y, z, w). Compare rotations, so q and -q
    // remain equivalent as required by quaternion semantics.
    let frame0 = quat(local_rot0[1], local_rot0[2], local_rot0[3], local_rot0[0]);
    let frame1 = quat(local_rot1[1], local_rot1[2], local_rot1[3], local_rot1[0]);
    let body_rotation = quat_from_euler_xyz_deg(vec3(body_euler[0], body_euler[1], body_euler[2]));
    if !quat_is_valid(frame0) || !quat_is_valid(frame1) || !quat_is_valid(body_rotation) {
        return #{ok: false, error: "composed leg pose or authored spring frame is not a valid rotation", joint: joint};
    }
    let seated_rotation = frame0 * quat_inverse(frame1);
    let relative = quat_inverse(body_rotation) * seated_rotation;
    let cosine = if relative.w.abs() > 1.0 { 1.0 } else { relative.w.abs() };
    let error_deg = 2.0 * acos(cosine) * 180.0 / PI;
    if !error_deg.is_finite() {
        return #{ok: false, error: "spring-frame seating error is not finite", joint: joint};
    }
    #{ok: true, error_deg: error_deg, joint: joint}
}

fn _usd_value(value, record) {
    let observation = #{provider: "usd",
        state: if value == () { "unavailable" } else { "value" }, value: value};
    if record != () {
        observation.doc_id = record.doc_id;
        observation.document_generation = record.document_generation;
        observation.stage_generation = record.stage_generation;
    }
    observation
}

fn _source_value(value, source) {
    #{provider: "source_literal",
      state: if value == () { "unavailable" } else { "value" },
      value: value, provider_generation: source.source_revision,
      source_revision: source.source_revision}
}

fn usd_axis(direction) {
    if !vec3_is_native(direction) { return (); }
    if direction.x == 1.0 && direction.y == 0.0 && direction.z == 0.0 { return "X"; }
    if direction.x == 0.0 && direction.y == 1.0 && direction.z == 0.0 { return "Y"; }
    if direction.x == 0.0 && direction.y == 0.0 && direction.z == 1.0 { return "Z"; }
    ()
}

// Measure actual transformed cylinder endpoints rather than comparing a
// second table of guessed angles/heights with the builder's output.
fn _member_endpoint_errors(record, upper, lower) {
    if record==() || record.attrs==() {return #{upper:(),lower:()};}
    let a=record.attrs;let t=a["xformOp:translate"];let e=a["xformOp:rotateXYZ"];
    let scale=a["xformOp:scale"];let height=a["height"];
    if !array_is(t) || !array_is(e) || t.len()!=3 || e.len()!=3 || height==() {return #{upper:(),lower:()};}
    let order=a["xformOpOrder"];
    if order != ["xformOp:translate","xformOp:rotateXYZ"]
        && order != ["xformOp:translate","xformOp:rotateXYZ","xformOp:scale"] {
        return #{upper:(),lower:()};
    }
    if scale!=() && (!array_is(scale) || scale.len()!=3) {return #{upper:(),lower:()};}
    let y_scale=if array_is(scale) {scale[1]} else {1.0};
    let center=vec3(t[0],t[1],t[2]);
    let q=quat_from_euler_xyz_deg(vec3(e[0],e[1],e[2]));
    let delta=qrot(q,vec3(0.0,height*y_scale/2.0,0.0));
    let u=center+delta-upper;let l=center-delta-lower;
    #{upper:(u.x*u.x+u.y*u.y+u.z*u.z).sqrt(),lower:(l.x*l.x+l.y*l.y+l.z*l.z).sqrt()}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = leg_source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("landingLegInstances"));
    let part_names = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let stations = sysml_requirement_checks::source_position_list(source, visual("legStations"));
    let rotations_y = sysml_requirement_checks::source_number_list(source,
        visual("legStationRotationYDeg"));
    let model = sysml_requirements::model();
    let leg_requirement = model.requirement(PACKAGE + "::gll009");
    let frame_tolerance = sysml_requirements::number(source,
        own("physicalLegRotationToleranceDeg"));
    if frame_tolerance == () {
        throw("GLL-009 physicalLegRotationToleranceDeg is missing from the typed source");
    }
    let strut_axis = usd_axis(sysml_requirements::native_value(source, own("strutAxis")));
    let count = parent("legCount");
    let checks = [];
    checks.push(sysml_requirement_checks::source_list_count("GLL-001-count", "landing_legs", "gll001", VERIFICATION, visual("landingLegInstances"), count));
    checks.push(sysml_requirement_checks::source_list_count("GLL-005-stations", "landing_leg", "gll005", VERIFICATION, visual("legStations"), count));
    checks.push(sysml_requirement_checks::source_list_count("GLL-009-leg-rotations", "landing_leg", "gll009", VERIFICATION, visual("legStationRotationYDeg"), count));
    let spring_pose = griffin_requirements::landing_gear_spring_pose_report(
        (), root, source, VERIFICATION);
    for check in spring_pose.checks { checks.push(check); }
    if spring_pose.ok != true {
        print("[griffin] GLL-010 spring-rest verification evidence: " + spring_pose);
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        let visual_path = path + "/LandingLegVisual";
        if rotations_y.len() == names.len() {
            let joint_path = root + "/" + name + "_Spring";
            checks.push(sysml_requirement_checks::exists("GLL-009-" + name + "-spring-joint",
                "landing_leg", "gll009", VERIFICATION, joint_path, "PhysicsPrismaticJoint"));
            checks.push(joint_relationship("GLL-009-" + name + "-spring-body0",
                joint_path, "physics:body0", root));
            checks.push(joint_relationship("GLL-009-" + name + "-spring-body1",
                joint_path, "physics:body1", path));
            checks.push(#{id: "GLL-009-" + name + "-spring-axis", component: "landing_leg",
                requirement: "gll009", verification: VERIFICATION, kind: "attribute_equals",
                path: joint_path, attr: "physics:axis", expected: "Y"});
            checks.push(joint_frame_component("GLL-009-" + name + "-body-rotation-y",
                path, "xformOp:rotateXYZ", 1, rotations_y[index], frame_tolerance));
            let frame = _joint_frame_observation(root, name);
            let error_observation = _usd_value(
                if frame.ok == true { frame.error_deg } else { () }, frame.joint);
            if frame.ok != true { error_observation.detail = frame.error; }
            let inputs = sysml_requirements::required_constraint_input_observations(
                model, leg_requirement, SPRING_FRAME_CONSTRAINT, [
                    ["seatingErrorDeg", error_observation],
                    ["toleranceDeg", _source_value(frame_tolerance, source)]
                ]);
            checks.push(sysml_requirements::required_constraint_check(
                "GLL-009-" + name + "-spring-frame", "landing_leg", "gll009",
                VERIFICATION, SPRING_FRAME_CONSTRAINT, inputs, "typed", 0.0));
        }
        checks.push(sysml_requirement_checks::exists("GLL-001-" + name, "landing_leg", "gll001", VERIFICATION, path, "Xform"));
        let required_children = [];
        for part_name in part_names { required_children.push(visual_path + "/" + part_name); }
        checks.push(sysml_requirement_checks::children("GLL-002-" + name, "landing_leg", "gll002", VERIFICATION, visual_path, required_children));
        let members=model.value(own("loadMembers"));
        let anchors=model.value(own("memberUpperAnchors"));
        let lower=model.value(own("memberLowerAnchor"));
        let tolerance=model.value(own("memberEndpointToleranceM"));
        if members.len()!=3 || anchors.len()!=3 {throw("landing leg load paths incomplete");}
        for member_index in 0..3 {
            let child=members[member_index].literal;
            let member_path=visual_path+"/"+child;
            let req=if member_index==0 {"gll007"} else {"gll006"};
            checks.push(sysml_requirement_checks::exists("leg-member-"+name+child,"landing_leg",req,VERIFICATION,member_path,"Cylinder"));
            checks.push(sysml_requirement_checks::attribute_check("leg-radius-"+name+child,"landing_leg",req,VERIFICATION,
                member_path,"radius",own(if member_index==0 {"shockPistonRadiusM"} else {"strutRadiusM"}),0.002));
            checks.push(sysml_requirement_checks::attribute_equals("leg-axis-"+name+child,"landing_leg",req,VERIFICATION,member_path,"axis",strut_axis));
            let record=query("QueryUsdPrim",#{path:member_path,attrs:["height","xformOp:translate","xformOp:rotateXYZ","xformOp:scale","xformOpOrder"]});
            let errors=_member_endpoint_errors(record,anchors[member_index],lower);
            let requirement=model.requirement("GriffinLandingLegRequirements::"+req);
            let predicate="GriffinLandingLegRequirements::GLLC006_MemberClosure";
            let inputs=sysml_requirements::required_constraint_input_observations(model,requirement,predicate,[
                ["measuredUpperEndpointErrorM",_usd_value(errors.upper,record)],
                ["measuredLowerEndpointErrorM",_usd_value(errors.lower,record)],
                ["toleranceM",_source_value(tolerance,source)]
            ]);
            checks.push(sysml_requirements::required_constraint_check("leg-endpoints-"+name+child,"landing_leg",req,VERIFICATION,predicate,inputs,"typed",0.0));
        }
        checks.push(#{id: "GLL-008-" + name + "-radius", component: "landing_leg",
            requirement: "gll008", verification: VERIFICATION, kind: "attribute",
            path: visual_path + "/FootPad", attr: "radius", expected_attr: own("footPadRadiusM"), tolerance: 0.002});
        checks.push(#{id: "GLL-008-" + name + "-height", component: "landing_leg",
            requirement: "gll008", verification: VERIFICATION, kind: "attribute",
            path: visual_path + "/FootPad", attr: "height", expected_attr: own("footPadHeightM"), tolerance: 0.002});
        if stations.len() == names.len() {
            checks.push(position("GLL-005-" + name + "-x", path, 0, stations[index].x));
            checks.push(position("GLL-005-" + name + "-y", path, 1, stations[index].y));
            checks.push(position("GLL-005-" + name + "-z", path, 2, stations[index].z));
        }
    }
    checks.push(sysml_requirement_checks::coverage("GLL-003-frame", "landing_leg", "gll003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("GLL-004-traceability", "landing_leg", "gll004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "GRIFFIN LANDING LEG REQUIREMENTS", "GRIFFIN_LANDING_LEG_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
