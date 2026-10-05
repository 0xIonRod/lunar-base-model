// Production acceptance: structural facts, static support, shaft motion, travel, turning.
fn simulation_dependencies(me, ctx) {
    let r=find_path("/World/FLIP");
    #{modelica_entities:[r], entity_reads:vessel_descendants(r), entity_writes:[], query_reads:[], required_inputs:[]}
}
fn on_start(me, ctx) {
    this.r=find_path("/World/FLIP"); this.t=0.0; this.done=false;
    this.failures=[]; this.p0=(); this.f0=(); this.distance=0.0;
    this.spin=0.0; this.yaw=0.0; this.tilt=0.0; this.settle_speed=0.0;
    this.samples=0; this.finalized=false;
    // Fail closed if a query throws. Full mesh topology exceeds Rhai's string limit;
    // exhaustive CAD topology is verified separately by verify_visuals.py.
    this.visual_ok=false;
    let valid=true;
    let hidden=["Chassis","Battery/Body","WifiRadio/RadioHousing","WifiRadio/Whip"];
    for tag in ["FL","FR","RL","RR"] {
        hidden.push("Motor_"+tag+"/Body");
        for shape in ["SuspensionCasing","SuspensionPiston","SuspensionSpring"] {
            hidden.push("Suspension_"+tag+"/Wheel_"+tag+"/"+shape);
        }
        let q=query("QueryUsdPrim",#{path:"/World/FLIP/Suspension_"+tag+"/Wheel_"+tag,attrs:["primvars:displayOpacity"]});
        let opacity=q.attrs["primvars:displayOpacity"];
        if opacity==() || opacity.len()!=1 || opacity[0]!=0.0 {valid=false;}
    }
    for suffix in hidden {
        let q=query("QueryUsdPrim",#{path:"/World/FLIP/"+suffix,attrs:["visibility"]});
        if q.attrs["visibility"]!="invisible" {print("Unexpected non-CAD visual: "+suffix);valid=false;}
    }
    this.visual_ok=valid;
    print("CAD-only audit ok="+this.visual_ok);
}
fn on_tick(me, ctx) {
    if this.done {return;}
    this.t+=dt(); this.samples+=1;
    if this.r==() || this.r<0 {
        emit("FLIP_ACCEPTANCE", "FAIL"); this.done=true; return;
    }
    let p=world_pos(this.r);
    let up=world_up(this.r);
    if up!=() { this.tilt=max(this.tilt,acos(clamp(up[1],-1.0,1.0))*57.2957795); }
    if this.t<3.0 { brake(this.r); }
    else if this.t<15.0 {
        if this.p0==() {
            this.p0=p;
            this.settle_speed=get(this.r,"speed");
            cmd("AcquireControl",#{target:this.r,bind_camera:false});
        }
        drive(this.r,0.4,0.0);
        this.distance=vlen(vsub(p,this.p0));
        for tag in ["FL","FR","RL","RR"] {
            let w=find_path("/World/FLIP/Suspension_"+tag+"/Wheel_"+tag);
            let omega=get(w,"shaft_speed");
            if omega!=() {this.spin=max(this.spin,abs(omega));}
        }
    }
    else if this.t<19.0 {
        if this.f0==() {this.f0=world_forward(this.r);}
        drive(this.r,0.4,0.5);
        let f=world_forward(this.r);
        this.yaw=acos(clamp(vdot(f,this.f0),-1.0,1.0))*57.2957795;
    }
    else {
        brake(this.r);
        let mass=get(this.r,"mass");
        let panel=find_path("/World/FLIP/SolarMechanism");
        let panel_mass=if panel==() || panel<0 {()} else {get(panel,"mass")};
        let mass_ok=mass!=() && abs(mass-343.0)<0.1 && panel_mass!=() && abs(panel_mass-15.0)<0.1;
        let moving=this.distance>0.5 && this.spin>0.1;
        let turning=this.yaw>2.0;
        let upright=this.tilt<20.0;
        let settled=this.settle_speed!=() && this.settle_speed<0.2;
        let wheels_ok=true;
        for tag in ["FL","FR","RL","RR"] {
            let w=find_path("/World/FLIP/Suspension_"+tag+"/Wheel_"+tag);
            if w==() || w<0 {wheels_ok=false;}
            else {
                let wm=get(w,"mass");
                if wm==() || abs(wm-18.0)>0.1 {wheels_ok=false;}
                let wp=world_pos(w);
                if wp==() || vlen(vsub(wp,p))>2.0 {wheels_ok=false;}
            }
        }
        print("FLIP measures mass="+mass+" settledSpeed="+this.settle_speed+" travel="+this.distance+" spin="+this.spin+" yaw="+this.yaw+" tilt="+this.tilt+" wheels="+wheels_ok);
        emit("FLIP_MEASUREMENTS",#{mass:mass,settle_speed:this.settle_speed,travel_m:this.distance,
            spin_rad_s:this.spin,yaw_deg:this.yaw,max_tilt_deg:this.tilt,samples:this.samples,
            mass_ok:mass_ok,wheels_ok:wheels_ok,moving:moving,turning:turning,upright:upright,settled:settled});
        let bump=find_path("/World/Bump");
        let crossed=bump==() || bump<0 || p[2] < -4.7;
        if this.visual_ok && mass_ok && wheels_ok && moving && turning && upright && settled && crossed && this.samples>700 {
            emit("FLIP_ACCEPTANCE","PASS");
        } else {emit("FLIP_ACCEPTANCE","FAIL");}
        this.done=true;
    }
}
