// FLIP operator route: the first point uses an unpossessed terrain-pointer
// context and the next two resolve from the possessed subject. This headless
// policy gate supplies semantic contexts; window input is covered separately.
// The action intent starts following, and FLIP must visit every
// point upright on the DEM terrain. Wheel traces are a windowed presentation
// and are verified in a live session, not by this headless gate.
import "lunco://scripting/tools/waypoint_editor" as waypoint_editor;

const ROOT = "/Griffin1SurfaceOps";
const FLIP_PATH = "/Griffin1SurfaceOps/FLIP";
const ROUTE = "/Griffin1SurfaceOps/FlipRoute";
// Relative to FLIP's settled position, in metres on the local surface.
const POINT_OFFSETS = [[8.0, 0.0], [14.0, 6.0], [8.0, 12.0]];
const SETTLE_S = 3.0;
const ROUTE_TIMEOUT_S = 150.0;
// 25 degrees of roll/pitch is the study tip-over margin for driving tests.
const MINIMUM_UPRIGHT_Y = 0.906307787;
fn simulation_dependencies(me, ctx) {
    let flip = find_path(FLIP_PATH);
    #{ modelica_entities: [flip, find_path(FLIP_PATH+"/Thermal")], entity_reads: [flip], entity_writes: [],
       query_reads: ["QueryUsdPrim", "QueryUsdPrims", "QueryPhysicsState", "ResolveUsdTarget",
                     "InspectSelection", "InspectUsdSelection", "TerrainHeight"],
       required_inputs: [] }
}

fn _flip_position() {
    let pose = query("QueryUsdPrim", #{ path: FLIP_PATH, attrs: [] });
    if pose == () || pose.ok == false || pose.world_position == () { return (); }
    pose.world_position
}

fn _gesture(doc, x, z) {
    let y = terrain_height(x, z);
    if y == () { return (); }
    #{
        button: "primary",
        screen_position: [64.0, 64.0],
        doc_id: doc,
        scene_root_path: ROOT,
        controlled_path: FLIP_PATH,
        modifiers: #{ alt: true, shift: false, ctrl: false },
        pointer_intents: ["route.add_point"],
        world_position: point3([x, y, z], "active_physics"),
        surface_world_position: point3([x, y, z], "active_physics"),
    }
}

fn _route_point_count(doc) {
    let read = waypoint_editor::route_positions(doc, ROUTE);
    if read == () || read.ok != true { return (); }
    read.paths.len()
}

fn on_start(me, ctx) {
    this.flip = find_path(FLIP_PATH);
    this.phase = "settle";
    this.elapsed = 0.0;
    this.done = false;
    this.started = false;
    this.completed = false;
    this.started_count = 0;
    this.stopped_count = 0;
    this.hud_start_ok = false;
    this.hud_stop_ok = false;
    this.manual_ok = false;
    this.negative_ok = false;
    this.initial_empty = false;
    this.minimum_upright_y = 1.0;
    this.gear_heat_seen = [false,false,false,false];
    this.bearing_heat_seen = [false,false,false,false];
    this.brake_heat_seen = [false,false,false,false];
    this.tire_heat_seen = [false,false,false,false];
    this.native_heat_passive = true;
    this.tire_warming = false;
    this.ground_heat_seen = false;
    this.brake_command_ok = false;
    this.gear_heat_passive = true;
    this.thermal_rise_seen = false;
    this.add_results = [];
    let assembly = query("QueryUsdPrim", #{path: FLIP_PATH,
        attrs: ["lunco:steeringGeometry", "lunco:ui:surfaceId"]});
    this.steering_ok = assembly != () && assembly.ok != false
        && assembly.attrs["lunco:steeringGeometry"] == "differential";
    this.hud_ok = assembly != () && assembly.ok != false
        && assembly.attrs["lunco:ui:surfaceId"] == "vessel-hud";
    // The operator possesses FLIP from the avatar; the control link carries
    // the action key's semantic edges to the route program.
    let avatar = find_path(ROOT + "/Avatar");
    let acquired = if avatar < 0 { #{ ok: false } }
        else { cmd("AcquireControl", #{ target: this.flip, source: avatar, bind_camera: false }) };
    this.control_ok = acquired.ok;
}

fn on_event(me, evt, ctx) {
    if evt.name == "route_started" { this.started = true; this.started_count += 1; }
    if evt.name == "route_stopped" { this.stopped_count += 1; }
    if evt.name == "route_completed" { this.completed = true; }
}

fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed += dt();
    let thermal = find_path(FLIP_PATH+"/Thermal");
    let wheel_sides=["FL","FR","RL","RR"];
    for index in 0..wheel_sides.len() {
        let heat = get(thermal,"gear_heat_"+wheel_sides[index]);
        if heat != () {
            this.gear_heat_passive = this.gear_heat_passive && heat.is_finite() && heat >= -1.0e-6;
            this.gear_heat_seen[index] = this.gear_heat_seen[index] || heat > 1.0e-4;
        }
        for loss in ["bearing","brake","tire"] {
            let power=get(thermal,loss+"_heat_"+wheel_sides[index]);
            if power!=() {
                this.native_heat_passive=this.native_heat_passive && power.is_finite() && power>=-1.0e-6;
                if power>1.0e-6 {
                    if loss=="bearing" {this.bearing_heat_seen[index]=true;}
                    if loss=="brake" {this.brake_heat_seen[index]=true;}
                    if loss=="tire" {this.tire_heat_seen[index]=true;}
                }
            }
        }
    }
    let tire_temperature=get(thermal,"tire_temp_left");
    this.tire_warming=this.tire_warming || (tire_temperature!=() && tire_temperature.is_finite() && tire_temperature>250.000001);
    let ground_heat=get(thermal,"ground_heat_FL");
    this.ground_heat_seen=this.ground_heat_seen || (ground_heat!=() && ground_heat.is_finite() && ground_heat>1.0e-8);
    let temperature = get(thermal,"motor_temp_left");
    this.thermal_rise_seen = this.thermal_rise_seen
        || (temperature != () && temperature.is_finite() && temperature > 250.00001);
    if this.phase == "settle" {
        if this.elapsed < SETTLE_S { return; }
        let route = query("QueryUsdPrim", #{ path: ROUTE, attrs: [] });
        let doc = if route == () || route.ok == false { () } else { route.doc_id };
        let origin = _flip_position();
        if doc == () || origin == () {
            this.done = true;
            report_verdict([t_true(false, "FLIP pose or document is unavailable")],
                "FLIP ROUTE FOLLOW", "FLIP_ROUTE_FOLLOW");
            return;
        }
        // An operator clicks FLIP (selection arms its unique route program),
        // then Alt+left-clicks each point once the previous one has projected.
        let selected = cmd("SelectSceneEntity", #{ entity_id: this.flip,
            extend: false, toggle: false, remove_only: false });
        this.select_ok = selected.ok;
        this.doc = doc;
        this.origin = origin;
        this.initial_empty = _route_point_count(doc) == 0;
        let ordinary = _gesture(doc, origin[0], origin[2]);
        if ordinary != () {
            ordinary.modifiers.alt = false;
            ordinary.pointer_intents = [];
            let ignored = waypoint_editor::route_pointer_action(ordinary);
            this.negative_ok = ignored.ok == true && ignored.handled == false
                && ignored.changed == false && _route_point_count(doc) == 0;
        }
        this.phase = "add";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "add" {
        let snapshot = waypoint_editor::route_positions(this.doc, ROUTE);
        if snapshot == () || snapshot.ok != true {
            // Point edits commit before their document projection. Only the
            // owner's explicit pending status may defer this phase.
            if snapshot != () && snapshot.retryable == true && this.elapsed < 10.0 { return; }
            this.done = true;
            report_verdict([t_true(false, "FlipRoute point query failed: " + snapshot.to_string())],
                "FLIP ROUTE FOLLOW", "FLIP_ROUTE_FOLLOW");
            return;
        }
        let count = snapshot.paths.len();
        if count < this.add_results.len() {
            if this.elapsed < 10.0 { return; }
        }
        if this.add_results.len() == POINT_OFFSETS.len() {
            this.phase = "start";
            this.elapsed = 0.0;
            return;
        }
        let offset = POINT_OFFSETS[this.add_results.len()];
        let gesture = _gesture(this.doc, this.origin[0] + offset[0], this.origin[2] + offset[1]);
        if gesture != () && this.add_results.len() == 0 {
            gesture.remove("controlled_path");
            gesture.target_path = ROOT + "/Environment/Terrain";
            gesture.hit_path = gesture.target_path;
            gesture.prim_paths = [gesture.target_path, ROOT + "/Environment", ROOT];
        }
        let result = if gesture == () { #{ ok: false, error: "terrain height unavailable" } }
            else { waypoint_editor::route_pointer_action(gesture) };
        this.add_results.push(result);
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "start" {
        // Let the runtime-layer edits project, then press the action control.
        if this.elapsed < 0.5 { return; }
        this.point_count = _route_point_count(this.doc);
        // A key press spans frames; the controller samples held state per frame.
        let pressed = cmd("SimulateIntent", #{ target: this.flip, intent: "action", held: true });
        this.action_ok = pressed.ok;
        this.phase = "release";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "release" {
        if this.elapsed < 0.2 { return; }
        let released = cmd("SimulateIntent", #{ target: this.flip, intent: "action", held: false });
        this.action_ok = this.action_ok && released.ok;
        this.phase = "drive";
        this.elapsed = 0.0;
        return;
    }
    let up = world_up3(this.flip);
    if up != () { this.minimum_upright_y = min(this.minimum_upright_y, up.y); }
    if this.phase == "drive" {
        if !this.completed && this.elapsed < ROUTE_TIMEOUT_S { return; }
        this.drive_s = this.elapsed;
        // Completed points remain visited. Add one new destination before
        // exercising HUD guidance and manual takeover on an active route.
        let extension = _gesture(this.doc, this.origin[0]+20.0, this.origin[2]+12.0);
        this.extension = if extension == () { #{ok:false} }
            else { waypoint_editor::route_pointer_action(extension) };
        this.phase = "hud_pending_point";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "hud_pending_point" {
        if _route_point_count(this.doc) != 4 && this.elapsed < 5.0 { return; }
        this.hud_dispatch_ok = this.extension.ok == true && _route_point_count(this.doc) == 4
            && emit("runtime.ui.action", #{action:"program.toggle",parameters:#{}});
        this.phase = "hud_start";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "hud_start" {
        let active = port(this.flip,"program_active");
        let ready = this.started_count >= 2 && active != () && active > 0.5;
        if !ready && this.elapsed < 5.0 { return; }
        this.hud_start_ok = ready;
        this.hud_dispatch_ok = this.hud_dispatch_ok
            && emit("runtime.ui.action", #{action:"program.toggle",parameters:#{}});
        this.phase = "hud_stop";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "hud_stop" {
        let active = port(this.flip,"program_active");
        let ready = this.stopped_count >= 1 && active != () && active < 0.5;
        if !ready && this.elapsed < 5.0 { return; }
        this.hud_stop_ok = ready;
        this.hud_dispatch_ok = this.hud_dispatch_ok
            && emit("runtime.ui.action", #{action:"program.toggle",parameters:#{}});
        this.phase = "manual_start";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "manual_start" {
        let active = port(this.flip,"program_active");
        let ready = this.started_count >= 3 && active != () && active > 0.5;
        if !ready && this.elapsed < 5.0 { return; }
        this.manual_start_ok = ready;
        this.manual_command = cmd("SimulateIntent",#{target:this.flip,intent:"forward",held:true});
        this.phase = "manual_takeover";
        this.elapsed = 0.0;
        return;
    }
    if this.phase == "manual_takeover" {
        let active = port(this.flip,"program_active");
        let ready = this.stopped_count >= 2 && active != () && active < 0.5;
        if !ready && this.elapsed < 5.0 { return; }
        let released = cmd("SimulateIntent",#{target:this.flip,intent:"forward",held:false});
        this.manual_ok = this.manual_start_ok && this.manual_command.ok && released.ok
            && ready
            && is_controlled(this.flip);
        // Build wheel momentum before applying the physical brake command.
        this.brake_command_ok=cmd("SimulateIntent",#{target:this.flip,intent:"forward",held:true}).ok;
        this.phase="brake_accelerate";this.elapsed=0.0;return;
    }
    if this.phase=="brake_accelerate" {
        if this.elapsed<2.0 {return;}
        this.brake_command_ok=this.brake_command_ok
            && cmd("SimulateIntent",#{target:this.flip,intent:"forward",held:false}).ok
            && cmd("SimulateIntent",#{target:this.flip,intent:"brake",held:true}).ok;
        this.phase="braking";this.elapsed=0.0;return;
    }
    if this.phase=="braking" {
        if this.elapsed<1.0 {return;}
        this.brake_command_ok=this.brake_command_ok
            && cmd("SimulateIntent",#{target:this.flip,intent:"brake",held:false}).ok;
    }
    let failures = [];
    let all_bearings=true;let all_tires=true;let brake_seen=false;
    for index in 0..4 {
        all_bearings=all_bearings && this.bearing_heat_seen[index];
        all_tires=all_tires && this.tire_heat_seen[index];
        brake_seen=brake_seen || this.brake_heat_seen[index];
    }
    failures.push(t_true(all_bearings,"all four bearing losses reach the thermal participant"));
    failures.push(t_true(all_tires,"all four tire contact losses reach the thermal participant"));
    failures.push(t_true(this.brake_command_ok && brake_seen,"applied wheel braking produces heat through its native loss port"));
    failures.push(t_true(this.native_heat_passive,"native physical losses remain finite and passive"));
    failures.push(t_true(this.tire_warming,"tire friction warms the wheel thermal bank"));
    failures.push(t_true(this.ground_heat_seen,"contact heat flows through the passive wheel-ground thermal network"));
    failures.push(t_true(this.gear_heat_seen[0] && this.gear_heat_seen[1]
        && this.gear_heat_seen[2] && this.gear_heat_seen[3],
        "all four gearbox heat paths reach the thermal participant while driving"));
    failures.push(t_true(this.gear_heat_passive,"gearbox heat never creates mechanical energy"));
    failures.push(t_true(this.thermal_rise_seen,"drivetrain losses warm the authored thermal bank"));
    failures.push(t_true(this.initial_empty, "runtime waypoints were restored at test start"));
    failures.push(t_true(this.negative_ok, "ordinary click changed the route"));
    failures.push(t_true(this.hud_dispatch_ok && this.hud_start_ok && this.hud_stop_ok,
        "the vessel HUD program action did not start and stop the route"));
    failures.push(t_true(this.manual_ok, "manual driving did not take over from the route"));
    failures.push(t_true(this.steering_ok, "FLIP does not use differential steering"));
    failures.push(t_true(this.hud_ok, "FLIP does not use the standard vessel HUD"));
    failures.push(t_true(this.control_ok, "FLIP control acquisition was rejected"));
    failures.push(t_true(this.select_ok, "selecting FLIP was rejected"));
    for index in 0..this.add_results.len() {
        let result = this.add_results[index];
        failures.push(t_true(result.ok == true && result.handled == true,
            "Alt+click route point " + index + " was not added: " + result.error));
    }
    failures.push(t_true(this.point_count == POINT_OFFSETS.len(),
        "FlipRoute holds " + this.point_count + " points, expected " + POINT_OFFSETS.len()));
    failures.push(t_true(this.action_ok, "action intent was rejected"));
    failures.push(t_true(this.started, "the action control did not start FlipRoute"));
    failures.push(t_true(this.completed,
        "FLIP did not visit every route point within " + ROUTE_TIMEOUT_S + " s"));
    failures.push(t_true(this.minimum_upright_y >= MINIMUM_UPRIGHT_Y,
        "FLIP tilted beyond the driving margin: upright y=" + this.minimum_upright_y));
    print("[flip-route-follow] drive_s=" + this.drive_s + " upright=" + this.minimum_upright_y
        + " points=" + this.point_count + " started=" + this.started + " completed=" + this.completed
        + " adds=" + this.add_results);
    this.done = true;
    report_verdict(failures, "FLIP ROUTE FOLLOW", "FLIP_ROUTE_FOLLOW");
}
