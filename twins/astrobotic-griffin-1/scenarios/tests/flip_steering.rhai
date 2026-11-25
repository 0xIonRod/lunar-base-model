// Exercise the manual intent binding on the mission terrain and physical V5 rover.
import "lunco://scripting/tools/sysml_requirements" as source;
const PACKAGE = "FlipMotionRequirements::";
const TEST_KIND = "headless";
const ROOT = "/Griffin1SurfaceOps/FLIP";

fn simulation_dependencies(me, ctx) {
    let rover = find_path(ROOT);
    let reads = [rover];
    for station in ["FL","FR","RL","RR"] {
        reads.push(find_path(ROOT + "/Suspension_" + station + "/Wheel_" + station));
    }
    #{modelica_entities:[rover], entity_reads:reads, entity_writes:[rover],
      query_reads:["QueryPhysicsState","ReadActiveTwinContract","AnalyzeSysml"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_source_identity()}]}
}

fn hold(key, down) {
    let receipt = cmd("SimulateIntent", #{target:find_path(ROOT), intent:key, held:down});
    if receipt.ok != true { throw("Rejected " + key + " command: " + receipt); }
}

fn on_start(me, ctx) {
    this.phase = 0;
    this.time = 0.0;
    this.start_tick = sim_tick();
    this.samples = #{};
    this.tires = #{};
    for station in ["FL","FR","RL","RR"] {
        this.tires[station] = #{peakPivotSideN:0.0, peakPivotTorqueNm:0.0,
            peakMovingSideN:0.0, peakSoilSinkageM:0.0, peakOpposingPowerW:0.0, minOpposingPowerW:0.0};
    }
    this.done = false;
    this.normal_impulse = 0.0;
    this.support_time = 0.0;
    this.peak_yaw = 0.0;
    this.peak_side = 0.0;
    try {
        let acquire = cmd("AcquireControl", #{target:find_path(ROOT), bind_camera:true});
        if acquire.ok != true { throw("FLIP control unavailable: " + acquire); }
        hold("brake", true);
    } catch (err) {
        this.done = true;
        report_verdict([err.to_string()], "FLIP steering", "FLIP_STEERING");
    }
}

fn sample() {
    let rover = find_path(ROOT);
    let physics = query("QueryPhysicsState", #{id:rover});
    let rotation = world_rotation_quat(rover);
    let side = qrot(rotation, vec3(1.0, 0.0, 0.0));
    let forward = qrot(rotation, vec3(0.0, 0.0, -1.0));
    #{right_rate:-physics.angular_velocity_radps[1],
      side:vdot(physics.linear_velocity_mps, side),
      forward:vdot(physics.linear_velocity_mps, forward)}
}

fn requirement_check(model, number, name, run, values, first_tick) {
    let req = PACKAGE + "fmr" + number;
    let constraint = PACKAGE + "FMR" + number + "_" + name;
    let ir = source::required_constraint_ir(model, model.requirement(req), constraint);
    if ir.ok != true { throw("Cannot resolve " + constraint + ": " + ir); }
    let bindings = [];
    for parameter in ir.constraint.parameters {
        let value = values[parameter.name];
        if value == () || !value.is_finite() {
            throw("Missing " + parameter.name + " for " + req + " " + run);
        }
        let observed = #{provider:"telemetry", state:"value", value:value,
            source_revision:model.source_revision, provider_generation:sim_tick(),
            document_id:(), document_generation:(),
            sample_interval:#{clock:"simulation", start_tick:first_tick, end_tick:sim_tick()}};
        bindings.push(source::scalar_constraint_observation(ir, parameter.name, observed));
    }
    source::required_constraints_check("FMR-" + number + "-" + run, "flip_steering", req,
        PACKAGE + "Verify_FLIPSteering", constraint, bindings, "typed", 0.0)
}

fn finish() {
    let model = source::model();
    let checks = [];
    for station in ["FL","FR","RL","RR"] {
        checks.push(requirement_check(model, "002", "WheelCalibration", station,
            this.tires[station], this.start_tick));
    }
    let samples = this.samples;
    for key in ["right","left"] {
        let sign = if key == "right" { 1.0 } else { -1.0 };
        let pivot = samples["pivot " + key];
        checks.push(requirement_check(model, "003", "PivotEnvelope", key, #{
            opposedPeakYawRadPerS:samples["opposed keys"].peak_yaw,
            signedEndYawRadPerS:sign * pivot.right_rate, peakYawRadPerS:pivot.peak_yaw,
            peakSideMps:pivot.peak_side, releaseYawRadPerS:abs(samples["release " + key].right_rate)
        }, this.start_tick));
        let entry = if key == "right" { samples.straight } else { samples.reverse };
        let arc = if key == "right" { samples["forward right"] } else { samples["reverse left"] };
        checks.push(requirement_check(model, "004", "MovingTurnEnvelope", key, #{
            signedEntryMps:sign * entry.forward, straightYawRadPerS:abs(entry.right_rate),
            signedExitMps:sign * arc.forward, signedEndYawRadPerS:sign * arc.right_rate,
            peakYawRadPerS:arc.peak_yaw, peakSideMps:arc.peak_side,
            straightenedYawRadPerS:abs(samples.straighten.right_rate),
            straightenedSideMps:abs(samples.straighten.side),
            brakedPlanarComponentMps:max(abs(samples.stop.forward), abs(samples.stop.side))
        }, this.start_tick));
    }
    let selection = source::source_with_selection([], [PACKAGE+"fmr002", PACKAGE+"fmr003",
        PACKAGE+"fmr004"], [PACKAGE+"Verify_FLIPSteering"]);
    let result = source::evaluate(selection, checks);
    report_structured_verdict(result, "FLIP steering", "FLIP_STEERING");
}

// Interpolate the mounted calibration at the two WES tow angles for the source check.
fn tow_ratio(knots, degrees) {
    let angle = degrees * 0.017453292519943295;
    for i in 1..knots.len() {
        let left = knots[i-1];
        let right = knots[i];
        if left[0] <= angle && angle <= right[0] {
            return left[1] + (right[1]-left[1]) * (angle-left[0])/(right[0]-left[0]);
        }
    }
    throw("Missing WES tow angle " + degrees + " in mounted calibration");
}

// Sample the actual force exchange at 10 Hz on the fixture's 60 Hz clock.
fn trace_forces(phase, chassis) {
    let wheels = #{};
    for station in ["FL","FR","RL","RR"] {
        let wheel = find_path(ROOT + "/Suspension_" + station + "/Wheel_" + station);
        let force = get(wheel, "WheelForceSample");
        if force == () { throw("Missing native wheel-force sample at " + station); }
        for name in ["normal_n","longitudinal_n","lateral_n","lateral_speed_mps",
                "slip_angle_rad","sinkage_m","drive_torque_nm","lateral_dissipation_w"] {
            if force[name] == () || !force[name].is_finite() { throw("Invalid " + station + " " + name); }
        }
        let stats = this.tires[station];
        if phase == "pivot right" || phase == "pivot left" {
            stats.peakPivotSideN = max(stats.peakPivotSideN, abs(force.lateral_n));
            stats.peakPivotTorqueNm = max(stats.peakPivotTorqueNm, abs(force.drive_torque_nm));
            stats.minOpposingPowerW = min(stats.minOpposingPowerW, force.lateral_dissipation_w);
            stats.peakOpposingPowerW = max(stats.peakOpposingPowerW, force.lateral_dissipation_w);
        }
        if phase == "forward right" || phase == "reverse left" {
            stats.peakMovingSideN = max(stats.peakMovingSideN, abs(force.lateral_n));
        }
        stats.peakSoilSinkageM = max(stats.peakSoilSinkageM, force.sinkage_m);
        this.tires[station] = stats;
        wheels[station] = force;
    }
    emit("FLIP_WHEEL_FORCE_TRACE", #{phase:phase, tick:sim_tick(), chassis:chassis, wheels:wheels});
}

fn run_tick() {
    let phases = ["settle", "opposed keys", "pivot right", "release right", "pivot left",
        "release left", "straight", "forward right", "straighten", "stop", "reverse", "reverse left"];
    let durations = [3.0, 1.0, 3.0, 2.0, 3.0, 2.0, 4.0, 3.0, 2.0, 8.0, 4.0, 3.0];
    let phase = phases[this.phase];
    let s = sample();
    if !s.right_rate.is_finite() || !s.forward.is_finite() || !s.side.is_finite() {
        throw("Missing native steering measurement during " + phase);
    }
    if sim_tick() % 6 == 0 { this.trace_forces(phase, s); }
    this.peak_yaw = max(this.peak_yaw, abs(s.right_rate));
    this.peak_side = max(this.peak_side, abs(s.side));
    if phase == "settle" && this.time >= 2.0 {
        for station in ["FL","FR","RL","RR"] {
            let wheel = find_path(ROOT + "/Suspension_" + station + "/Wheel_" + station);
            this.normal_impulse += contact_debug(wheel).total_normal_impulse;
        }
        this.support_time += dt();
    }
    this.time += dt();
    if this.time < durations[this.phase] { return; }
    let detail = phase + " " + s + " peak yaw=" + this.peak_yaw + " peak lateral=" + this.peak_side;
    print("FLIP steering " + detail);
    s.peak_yaw = this.peak_yaw;
    s.peak_side = this.peak_side;
    this.samples[phase] = s;
    switch phase {
        "settle" => {
            // On the local 4.6 degree slope the wheel reactions should support nearly mg.
            let support = this.normal_impulse / this.support_time;
            print("FLIP measured four-wheel normal load N: " + support);
            for station in ["FL","FR","RL","RR"] {
                let wheel = find_path(ROOT + "/Suspension_" + station + "/Wheel_" + station);
                let knots = get(wheel, "JointedWheelTire.soil_side_force_curve.knots");
                this.tires[station].towAtFiveN = 277.0*tow_ratio(knots,5.0);
                this.tires[station].towAtTenN = 276.0*tow_ratio(knots,10.0);
                this.tires[station].totalSupportN = support;
                this.tires[station].settledPlanarComponentMps = max(abs(s.forward), abs(s.side));
            }
            hold("brake", false); hold("left", true); hold("right", true);
        }
        "opposed keys" => {
            hold("left", false);
        }
        "pivot right" | "pivot left" => {
            let key = if phase == "pivot right" { "right" } else { "left" };
            hold(key, false);
        }
        "release right" | "release left" => {
            hold(if phase == "release right" { "left" } else { "forward" }, true);
        }
        "straight" | "reverse" => {
            hold(if phase == "straight" { "right" } else { "left" }, true);
        }
        "forward right" | "reverse left" => {
            if phase == "forward right" { hold("right", false); }
            else {
                hold("left", false); hold("backward", false); hold("brake", true);
                this.done = true;
                this.finish();
            }
        }
        "straighten" => {
            hold("forward", false); hold("brake", true);
        }
        "stop" => {
            hold("brake", false); hold("backward", true);
        }
    }
    this.phase += 1;
    this.peak_yaw = 0.0;
    this.peak_side = 0.0;
    this.time = 0.0;
}

fn on_tick(me, ctx) {
    if this.done { return; }
    try { this.run_tick(); }
    catch (err) {
        this.done = true;
        report_verdict([err.to_string()], "FLIP steering", "FLIP_STEERING");
    }
}
