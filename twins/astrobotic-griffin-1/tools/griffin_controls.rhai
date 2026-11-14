// Griffin-1 control surface.
//
// The simulator already owns possession, input routing, and autopilot
// authority. This Twin-local library makes those existing commands explicit
// for this mission and keeps the on-screen handoff language in one place.
// It is deliberately not a second vehicle-control implementation.

fn lander_path() { "/Griffin1SurfaceOps/Lander" }
fn rover_path() { "/Griffin1SurfaceOps/FLIP" }

fn controls_visible() {
    if get_twin_setting("ui.vehicle_controls")==false {
        clear_guided_hud_actions("griffin-controls");
        clear_hint("griffin-controls");
        return false;
    }
    true
}

// Mission status uses the same visibility owner as the control buttons.
fn show_hint(text) {
    if !controls_visible() {return;}
    hint("griffin-controls",text);
}

// Runtime topology, rather than a release acknowledgement, decides whether
// wheel commands can move the rover independently of Griffin.
fn rover_attached() {
    let joint = find_path("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint");
    joint != () && joint >= 0
}

// The compact mission only unlocks drive after the authored tether program
// has unloaded both lines at a stable four-wheel ground transfer. A visual
// tether or a missing Modelica entity is never enough to enable the rover.
fn compact_tether_installed() {
    find_path("/Griffin1SurfaceOps/EgressTether")>=0
        && find_path("/Griffin1SurfaceOps/CompactEgressObservation")>=0
}

fn compact_tether_disconnect_status() {
    if rover_attached() {return #{ok:false,reason:"FLIP is still attached to Griffin"};}
    let ground=compact_rover_transfer_status();
    if ground.ok!=true {return #{ok:false,reason:ground.reason};}
    let tether=find_path("/Griffin1SurfaceOps/EgressTether");
    if tether<0 {return #{ok:false,reason:"no tether restraint is installed"};}
    let values=#{};
    for p in read_ports(tether,["enabled","tension0","tension1","elastic_energy"]).ports {
        if (p.name=="enabled" && p.direction=="in") || p.direction=="out" {values[p.name]=p.value;}
    }
    for name in ["enabled","tension0","tension1","elastic_energy"] {
        if values[name]==() || !values[name].is_finite() {return #{ok:false,reason:"tether telemetry is unavailable"};}
    }
    let ok=values.enabled>0.5 && values.tension0>=0.0 && values.tension1>=0.0
        && values.tension0<=griffin_tether_study::datum("releaseTensionN")
        && values.tension1<=griffin_tether_study::datum("releaseTensionN")
        && values.elastic_energy>=0.0 && values.elastic_energy<=griffin_tether_study::datum("releaseElasticEnergyJ");
    #{ok:ok,reason:if ok {"parked with both tethers unloaded"}else{"tethers are loaded or already disconnected"}}
}

fn compact_tether_release_status() {
    let tether=find_path("/Griffin1SurfaceOps/EgressTether");
    if tether==() || tether<0 {
        return #{ok:false,reason:"physical Modelica tether is not installed in this scene"};
    }
    let snapshot=read_ports(tether,["enabled","tension0","tension1","elastic_energy"]);
    let enabled=();let t0=();let t1=();let energy=();
    for p in snapshot.ports {
        if p.name=="enabled" && p.direction=="in" {enabled=p.value;}
        if p.name=="tension0" && p.direction=="out" {t0=p.value;}
        if p.name=="tension1" && p.direction=="out" {t1=p.value;}
        if p.name=="elastic_energy" && p.direction=="out" {energy=p.value;}
    }
    if enabled==() || t0==() || t1==() || energy==()
        || !t0.is_finite() || !t1.is_finite() || !energy.is_finite() {
        return #{ok:false,reason:"tether load or cut-state telemetry is missing"};
    }
    for body in [find_path(rover_path()+"/Suspension_RL/Wheel_RL"),
        find_path(rover_path()+"/Suspension_RR/Wheel_RR"),find_path(lander_path())] {
        let seen=#{};
        for port in read_ports(body,["force_x","force_y","force_z","torque_x","torque_y","torque_z"]).ports {
            if port.direction=="in" {
                if port.value==() || !port.value.is_finite() || port.value!=0.0 {
                    return #{ok:false,reason:"Native restraint wrench is not clear"};
                }
                seen[port.name]=true;
            }
        }
        for name in ["force_x","force_y","force_z","torque_x","torque_y","torque_z"] {
            if seen[name]!=true {return #{ok:false,reason:"Native restraint release telemetry missing: "+name};}
        }
    }
    for station in ["FL","FR","RL","RR"] {
        let released=false;
        for port in read_ports(find_path(rover_path()+"/Suspension_"+station+"/Wheel_"+station),["brake"]).ports {
            if port.direction=="in" && port.name=="brake" && port.value==0.0 {released=true;}
        }
        if !released {return #{ok:false,reason:"Egress wheel brake has not been released"};}
    }
    let tension_limit=griffin_tether_study::datum("releaseTensionN");
    let energy_limit=griffin_tether_study::datum("releaseElasticEnergyJ");
    let unloaded=enabled<0.5 && t0>=0.0 && t1>=0.0
        && t0<=tension_limit && t1<=tension_limit && energy>=0.0 && energy<=energy_limit;
    #{ok:unloaded,enabled:enabled,tension0_n:t0,tension1_n:t1,elastic_energy_j:energy,
      reason:if unloaded {"both lines are cut and unloaded"} else {"tethered transfer has not passed its unload and cut gate"}}
}

fn compact_rover_transfer_status() {
    let stations=griffin_compact_egress::datum("stationsXM");
    let dimensions=query("QueryUsdPrim",#{path:rover_path()+"/Suspension_RL/Wheel_RL",attrs:["radius","height"]}).attrs;
    compact_rover_transfer_status(#{ground_min:griffin_tether_study::datum("groundedWheelCenterMinM"),
        ground_max:griffin_tether_study::datum("groundedWheelCenterMaxM"),
        minimum_upright:griffin_tether_study::datum("minimumUprightCos"),
        transfer_speed:griffin_tether_study::datum("groundTransferSpeedMps"),
        transfer_rate:griffin_tether_study::datum("groundTransferRateRadps"),
        minimum_clearance:griffin_tether_study::datum("minimumTrackClearanceM"),
        track_end_x:stations[stations.len()-1],wheel_radius:dimensions["radius"],wheel_width:dimensions["height"]})
}

fn compact_rover_transfer_status(config) {
    let rover=find_path(rover_path());
    if rover==() || rover<0 {return #{ok:false,reason:"FLIP body is unavailable"};}
    let up=world_up3(rover).y;
    let physics=query("QueryPhysicsState",#{id:rover});
    if physics.physics_state_ready!=true || physics.body_mode!="dynamic"
        || physics.rigid_body_disabled==true || physics.simulation_object_paused==true {
        return #{ok:false,reason:"FLIP is not an enabled, ready dynamic body"};
    }
    let speed=vlen(physics.linear_velocity_mps);
    let angular_speed=vlen(physics.angular_velocity_radps);
    let wheel_count=0;
    let front_count=0;let rear_count=0;let rear_supported_count=0;let fixed_count=0;let front_sum=vec3(0.0,0.0,0.0);let front_supported=[];
    let ramp=find_path("/Griffin1SurfaceOps/Lander/CompactEgress");
    let origin=world_pos3(ramp);let rotation=world_rotation_quat(ramp);let inverse=quat_inverse(rotation);
    let inboard=qrot(rotation,vec3(1.0,0.0,0.0));
    let rear_inboard=-1.0e30;
    for station in ["FL","FR","RL","RR"] {
        let wheel=find_path(rover_path()+"/Suspension_"+station+"/Wheel_"+station);
        if wheel==() || wheel<0 {return #{ok:false,reason:"Missing wheel "+station};}
        let p=world_pos3(wheel);
        if station=="FL" || station=="FR" {front_sum+=p;}
        else {
            let axle=qrot(world_rotation_quat(wheel),vec3(1.0,0.0,0.0));
            let cosine=min(1.0,abs(vdot(axle,inboard)));
            let extent=config.wheel_radius*sqrt(max(0.0,1.0-cosine*cosine))+config.wheel_width*0.5*cosine;
            rear_inboard=max(rear_inboard,qrot(inverse,p-origin).x+extent);
        }
        let ground=terrain_height(p.x,p.z);
        if ground==() {return #{ok:false,reason:"Terrain height missing under "+station};}
        let height=p.y-ground;
        let contact=();let fixed=();
        let ports=read_ports(wheel,["loaded_contact","fixed_contact"]);
        for port in ports.ports {
            if port.name=="loaded_contact" && port.direction=="out" && port.value!=()
                && port.value.is_finite() {contact=port.value;}
            if port.name=="fixed_contact" && port.direction=="out" && port.value!=()
                && port.value.is_finite() {fixed=port.value;}
        }
        if contact==() || fixed==() {return #{ok:false,reason:"Native support telemetry missing for "+station};}
        if station=="FL" || station=="FR" {front_supported.push(contact>0.5);}
        if fixed>0.5 {fixed_count+=1;}
        if (station=="RL" || station=="RR") && contact>0.5 {rear_supported_count+=1;}
        if height>=config.ground_min
            && height<=config.ground_max
            && contact>0.5 && fixed>0.5 {
            wheel_count+=1;
            if station=="FL" || station=="FR" {front_count+=1;}else{rear_count+=1;}
        }
    }
    let clearance=config.track_end_x-rear_inboard;
    let front_center=front_sum*0.5;
    let front_toe_clearance=config.track_end_x-qrot(inverse,front_center-origin).x;
    let stable=wheel_count==4 && up>=config.minimum_upright
        && speed<=config.transfer_speed && angular_speed<=config.transfer_rate;
    let ok=stable && clearance>=config.minimum_clearance;
    #{ok:ok,wheel_count:wheel_count,front_count:front_count,rear_count:rear_count,rear_supported_count:rear_supported_count,fixed_count:fixed_count,
      front_center_m:vec3_array(front_center),front_toe_clearance_m:front_toe_clearance,front_supported:front_supported,upright_cos:up,speed_mps:speed,angular_speed_radps:angular_speed,
      mechanically_stable:stable,track_clearance_m:clearance,
      reason:if ok {"stable four-wheel ground transfer"} else {"four-wheel contact, attitude, or motion gate is not satisfied"}}
}

fn show_mounted_rover_controls() {
    if !controls_visible() {return;}
    if griffin_compact_egress::enabled() {
        let text=if compact_tether_installed() {
            "FLIP ATTACHED: DEPLOY FLIP prepares the tethers and starts deployment after landing."
        } else {"FLIP ATTACHED: DETACH ROVER releases the adapter and keeps FLIP parked; this scene has no descent restraint."};
        hint("griffin-controls",text);
        return;
    }
    hint("griffin-controls", "FLIP ATTACHED: the payload adapter locks the rover to Griffin. Use OPEN RAMPS, wait for settlement, then DETACH ROVER. U opens ramps and F detaches while controlling Griffin; on FLIP, F runs/stops the route.");
}

fn resolve(path, label) {
    let target = find_path(path);
    if target == () || target < 0 {
        notify_kind(label + " is not available in the active scene.", "error");
        return ();
    }
    target
}

fn show_briefing() {
    if !controls_visible() {return;}
    let cancel = input_hint("cancel");
    if rover_attached() { show_mounted_rover_controls(); }
    else { hint("griffin-controls", "Click a vehicle to control. " + cancel + " releases."); }
    objectives_hud("griffin-controls", []);
    set_surface_action_buttons();
}

/// Guidance commands the lander while engaged and no accepted operator input
/// holds manual authority. Selecting the vehicle alone preserves guidance.
fn gnc_connected() {
    let lander = find_path(lander_path());
    if lander == () || lander < 0 { return (); }
    let piloted = get(lander, "piloted");
    let gnc = find_path(lander_path() + "/GNC");
    if gnc == () || gnc < 0 { return (); }
    let engage = get(gnc, "engage");
    if piloted == () || engage == () { return (); }
    piloted < 0.5 && engage >= 0.5
}

fn set_surface_action_buttons() {
    set_surface_action_buttons_for(gnc_connected())
}

fn guidance_engagement_applied(enabled) {
    if !controls_visible() {return;}
    if enabled {
        hint("griffin-controls", "GNC RECONNECTED: guidance commands the lander again.");
        notify_kind("Griffin GNC reconnected.", "success");
    } else {
        hint("griffin-controls", "GNC DISCONNECTED: flight input takes manual control. RECONNECT GNC restores guidance.");
        notify_kind("Griffin GNC disconnected.", "warning");
    }
    set_surface_action_buttons();
}

/// `gnc` is the guidance state the GNC button offers to change.
fn set_surface_action_buttons_for(gnc) {
    if !controls_visible() {return #{ok:true,visible:false};}
    let result = guided_hud_actions("griffin-controls", "griffin_surface_ops", "on_hud_action", [
        #{id: "unfold_ramps", label: if griffin_compact_egress::enabled() {"FIXED EGRESS TRACKS"}else{"OPEN RAMPS  U"}, enabled: !griffin_compact_egress::enabled()},
        #{id: "release_rover", label: if compact_tether_installed() {"DEPLOY FLIP"}else{"DETACH ROVER"}, enabled: rover_attached()},
        #{id: "disconnect_tethers", label: "DISCONNECT TETHERS", enabled: compact_tether_installed() && compact_tether_disconnect_status().ok},
        #{id: "toggle_gnc",
          label: if gnc == false { "RECONNECT GNC" } else { "DISCONNECT GNC" },
          enabled: gnc != ()}
    ]);
    if result == () || result.ok != true {
        let detail = if result == () || result.error == () { "unknown HUD action update rejection" } else { result.error };
        notify_kind("Griffin mission buttons could not be updated: " + detail, "error");
    }
    result
}

fn show_touchdown_actions() {
    if !controls_visible() {return;}
    show_briefing();
    if griffin_compact_egress::enabled() {
        let text=if compact_tether_installed() {
            "TOUCHDOWN CONFIRMED: F or DEPLOY FLIP starts tethered deployment. Manual drive unlocks after ground transfer and tether release."
        } else {"TOUCHDOWN CONFIRMED: F or DETACH ROVER releases the adapter and keeps FLIP parked."};
        hint("griffin-controls",text);
        return;
    }
    hint("griffin-controls", "TOUCHDOWN CONFIRMED: U or OPEN RAMPS to lower both ramps. F detaches FLIP immediately.");
    set_surface_action_buttons();
}

fn show_ramp_unfolding_actions() {
    if !controls_visible() {return;}
    hint("griffin-controls", "RAMP UNFOLDING: middle sections, toes, then deck hinges. F remains available.");
    set_surface_action_buttons();
}

fn show_rover_release_actions() {
    if !controls_visible() {return;}
    hint("griffin-controls", "RAMPS SETTLED: F or DETACH ROVER detaches FLIP from the top deck.");
    set_surface_action_buttons();
}

fn show_rover_release_pending() {
    if !controls_visible() {return;}
    let paused=clock_snapshot().transport_playing==false;
    let detached=find_path("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint")<0;
    let message=if paused {
        if detached {"ADAPTER DETACHED: resume simulation to finish rover handover."}
        else {"DETACH ACCEPTED: resume simulation to confirm release and hand over rover control."}
    } else {"PAYLOAD RELEASE: confirming detachment and waiting for egress readiness."};
    hint("griffin-controls",message);
    set_surface_action_buttons();
}

fn clear_surface_operation_actions() {
    clear_guided_hud_actions("griffin-controls")
}

fn show_rover_controls() {
    if !controls_visible() {return;}
    if rover_attached() { show_mounted_rover_controls(); return; }
    if griffin_compact_egress::enabled() && find_path("/Griffin1SurfaceOps/Lander")>=0 {
        let tether=compact_tether_release_status();
        let transfer=compact_rover_transfer_status();
        if tether.ok!=true || transfer.ok!=true {
            let reason=if tether.ok!=true {tether.reason}else{transfer.reason};
            hint("griffin-controls","FLIP: manual drive locked; "+reason+".");
            return;
        }
    }
    let forward = input_hint("forward");
    let backward = input_hint("backward");
    let left = input_hint("left");
    let right = input_hint("right");
    let action = input_hint("action");
    let cancel = input_hint("cancel");
    // The vessel HUD carries telemetry and the route program run/stop button;
    // this brief only names the manual skid-steer controls.
    hint("griffin-controls", "FLIP CONTROL: " + forward + "/" + backward + " drive | " + left + "/" + right
        + " skid turn | Space brake | " + action + " run/stop route | " + cancel + " release");
}

// SimulateIntent is the controller-owned persistent hold used by the keyboard;
// the immediate SetPorts write closes the one-tick gap before the next control
// projection.  Both target the authored `brake` input and therefore use the
// generic mobility parking-brake boundary.  No autopilot-specific command is
// assumed: route ownership is explicit in the mission's AcquireControl step.
fn hold_rover_brake() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }
    let intent = cmd("SimulateIntent", #{ intent: "brake", held: true, target: target });
    if intent == () || intent.ok != true {
        return #{ ok: false, error: "controller rejected persistent brake intent" };
    }
    let result = cmd("SetPorts", #{
        target: target,
        writes: [["throttle", 0.0], ["steer", 0.0], ["brake", 1.0]],
    });
    result
}

fn release_rover_brake() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }
    let intent = cmd("SimulateIntent", #{ intent: "brake", held: false, target: target });
    if intent == () || intent.ok != true {
        return #{ ok: false, error: "controller rejected brake release" };
    }
    // Adapter release can originate from the HUD/control command layer. Its
    // persistent brake hold outranks a simulation program's zero setpoint.
    // End that hold explicitly before handing braking back to the program.
    let released = cmd("ReleasePort", #{target:target,name:"brake"});
    if released == () || released.ok != true {
        return #{ok:false,error:"persistent brake hold could not be released"};
    }
    cmd("SetPorts", #{
        target: target,
        writes: [["throttle", 0.0], ["steer", 0.0], ["brake", 0.0]],
    })
}

// FLIP's steering architecture is a SysML-selected, authored assembly fact
// (`lunco:steeringGeometry`). The mission verifies it before route control
// instead of mutating USD while physics runs.
fn configure_route_steering() {
    let mode = griffin_spec::route_steering_mode();
    if mode == () || mode == "" {
        return #{ ok: false, error: "SysML missionSteeringMode is unavailable" };
    }
    let state = query("QueryUsdPrim", #{ path: rover_path(), attrs: ["lunco:steeringGeometry"] });
    if state == () || state.ok == false {
        return #{ ok: false, error: "authored FLIP steering geometry is unavailable" };
    }
    let geometry = state.attrs["lunco:steeringGeometry"];
    if geometry != mode {
        return #{ ok: false, error: "authored FLIP steering geometry " + geometry
            + " does not match SysML " + mode };
    }
    #{ ok: true, mode: mode }
}

fn control_lander() {
    let target = resolve(lander_path(), "Griffin lander");
    if target == () { return; }
    let result = cmd("AcquireControl", #{ target: target, bind_camera: true });
    if result.ok {
        let egress_hint=" | F detach rover";
        hint("griffin-controls", "LANDER CONTROL: GNC stays on until flight input. " + input_hint("thrust") + " thrust | W/S pitch | A/D roll | Q/E yaw"+egress_hint);
        notify_kind("Griffin selected. Flight input takes manual control.", "success");
    } else {
        notify_kind("Lander control was rejected: " + result.error, "error");
    }
    result
}

/// Explicitly disconnect guidance or release manual possession and re-engage
/// it. Ordinary selection leaves guidance active until the first flight input.
fn toggle_gnc() {
    let connected = gnc_connected();
    if connected == () {
        notify_kind("Griffin GNC state is not readable from the active scene.", "error");
        return #{ok: false, error: "lander guidance authority is unavailable"};
    }
    let result = if connected { control_lander() } else { release_lander() };
    if result == () || result.ok != true {
        let detail = if result == () || result.error == () { "control command rejected" } else { result.error };
        return #{ok: false, error: detail};
    }
    // The mission owns fixed-tick guidance writes. HUD and console callbacks
    // submit the same event as simulation callers, with no fabricated producer.
    emit("griffin_gnc_engagement_requested", #{enabled: !connected});
    if connected {
        notify_kind("Griffin GNC disconnect requested.", "warning");
    } else {
        hint("griffin-controls", "GNC RECONNECT REQUESTED: waiting for guidance engagement.");
        notify_kind("Griffin GNC reconnect requested.", "info");
    }
    set_surface_action_buttons_for(!connected);
    #{ok: true, queued: true, gnc_connected: !connected}
}

fn control_rover() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    let result = cmd("AcquireControl", #{ target: target, bind_camera: true });
    if result.ok {
        follow(target);
        show_rover_controls();
        if rover_attached() {
            notify_kind("FLIP selected; detach the payload adapter before driving.", "warning");
        } else { notify_kind("FLIP under manual control.", "success"); }
    } else {
        notify_kind("FLIP control was rejected: " + result.error, "error");
    }
    result
}

fn release_lander() {
    let source = resolve("/Griffin1SurfaceOps/Avatar", "local control avatar");
    if source == () { return #{ ok: false, error: "local control avatar is unavailable" }; }
    cmd("ReleaseControlSource", #{ source: source });
}

fn release_rover() {
    let source = resolve("/Griffin1SurfaceOps/Avatar", "local control avatar");
    if source == () { return #{ ok: false, error: "local control avatar is unavailable" }; }
    cmd("ReleaseControlSource", #{ source: source });
}

fn release_control() {
    let lander = release_lander();
    let rover = release_rover();
    hint("griffin-controls", "FREE FLIGHT: click Griffin or FLIP to take control; " + input_hint("cancel") + " releases control");
    #{ lander: lander, rover: rover }
}
