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
    #{ modelica_entities: [flip], entity_reads: [flip], entity_writes: [],
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
        let count = _route_point_count(this.doc);
        if count == () {
            this.done = true;
            report_verdict([t_true(false, "FlipRoute point query failed")],
                "FLIP ROUTE FOLLOW", "FLIP_ROUTE_FOLLOW");
            return;
        }
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
    }
    let failures = [];
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
