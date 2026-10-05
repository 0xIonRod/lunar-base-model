// Test-only: observe native joint/body physics; never animate mesh transforms.
fn simulation_dependencies(me, ctx) {
    let r=find_path("/World/FLIP");
    #{modelica_entities:[r,find_path("/World/FLIP/SolarMechanism/Controller")],
      entity_reads:vessel_descendants(r),entity_writes:[],query_reads:[],required_inputs:[]}
}
fn on_start(me, ctx) {
    this.r=find_path("/World/FLIP"); this.p=find_path("/World/FLIP/SolarMechanism");
    this.j=find_path("/World/FLIP/PanelHinge"); this.c=find_path("/World/FLIP/SolarMechanism/Controller");
    this.t=0.0; this.done=false; this.leg=-1; this.samples=0;
    this.anchor_error=0.0; this.max_rate=0.0; this.max_contact=0; this.max_tilt=0.0;
    this.orientation_error=0.0; this.endpoint_error=0.0; this.hold_rate=0.0;
    this.motion_rate=0.0; this.motion_tilt=0.0; this.settled=false;
    this.low=100.0; this.high=-100.0; this.poses=[]; this.valid=false;
    this.debug_time=0.0;
    if this.r==() || this.p==() || this.j==() || this.c==() || this.j<0 {
        print("PANEL missing physical body/joint/controller");
        emit("FLIP_PANEL","FAIL"); this.done=true; return;
    }
    let q=query("QueryUsdPrim",#{path:"/World/FLIP/PanelHinge",attrs:["drive:angular:physics:maxForce"],connections:true});
    let wires=q.connections["inputs:angle"];
    if wires==() || wires.len()!=1 || q.attrs["drive:angular:physics:maxForce"]!=60.0 {
        print("PANEL missing drive wire or finite study torque cap");
        emit("FLIP_PANEL","FAIL"); this.done=true; return;
    }
    this.valid=true;
}
fn on_tick(me, ctx) {
    if this.done {return;}
    this.t+=dt(); this.samples+=1; brake(this.r);
    let angle=get(this.j,"angle"); let rate=get(this.j,"angular_velocity");
    let contact=contact_debug(this.p);
    if this.t>=this.debug_time && this.t<3.0 {
        print("PANEL startup t="+this.t+" angle="+angle+" rate="+rate+" tilt="+tilt_deg(this.r));
        this.debug_time+=0.25;
    }
    if angle==() || rate==() || contact==() {this.valid=false;}
    else {
        this.low=min(this.low,angle);this.high=max(this.high,angle);
        this.max_rate=max(this.max_rate,abs(rate));
        this.max_contact=max(this.max_contact,contact.touching_pair_count);
        let anchor=vadd(world_pos(this.r),vadd(vscale(world_right(this.r),0.69),vscale(world_up(this.r),0.257)));
        this.anchor_error=max(this.anchor_error,vlen(vsub(world_pos(this.p),anchor)));
        this.max_tilt=max(this.max_tilt,tilt_deg(this.r));
        if this.leg>=0 {
            this.motion_rate=max(this.motion_rate,abs(rate));
            this.motion_tilt=max(this.motion_tilt,tilt_deg(this.r));
        }
        // The visual body axes must follow the same measured joint coordinate.
        let expected=vadd(vscale(world_right(this.r),cos(angle)),vscale(world_up(this.r),sin(angle)));
        this.orientation_error=max(this.orientation_error,angle_deg(world_right(this.p),expected));
        if this.orientation_error>0.5 {this.valid=false;}
    }
    if this.t<2.0 {return;}
    if this.leg<0 {
        this.settled=get(this.r,"speed")<0.2 && tilt_deg(this.r)<3.0 && abs(rate)<0.03;
        print("PANEL settled="+this.settled+" speed="+get(this.r,"speed"));
    }
    let leg=((this.t-2.0)/12.0).floor().to_int();
    let commands=[0.0,90.0,0.0,90.0,-10.0,100.0];
    if leg!=this.leg {
        if this.leg>=0 {
            let wanted=clamp(commands[this.leg],0.0,90.0);
            let measured=-angle*57.29577951308232;
            this.poses.push(measured);
            this.endpoint_error=max(this.endpoint_error,abs(measured-wanted));
            this.hold_rate=max(this.hold_rate,abs(rate));
            print("PANEL leg="+this.leg+" target="+wanted+" measured="+measured);
            if abs(measured-wanted)>1.0 || abs(rate)>0.02 {this.valid=false;}
        }
        this.leg=leg;
        if leg<commands.len() {write_ports(this.c,[["command_deg",commands[leg]]]);}
        else {
            let mass=get(this.r,"mass")+get(this.p,"mass");
            for tag in ["FL","FR","RL","RR"] {
                mass+=get(find_path("/World/FLIP/Suspension_"+tag),"mass");
                mass+=get(find_path("/World/FLIP/Suspension_"+tag+"/Wheel_"+tag),"mass");
            }
            let ok=this.valid && this.poses.len()==6 && abs(mass-450.0)<0.1 && this.samples>4000 &&
                this.settled && this.anchor_error<0.005 && this.motion_rate<0.35 && this.max_contact==0 &&
                this.max_tilt<20.0 && this.motion_tilt<10.0 &&
                this.low>=-1.58825 && this.high<=0.01746;
            print("PANEL measures totalMass="+mass+" anchorError="+this.anchor_error+" maxRate="+this.max_rate+
                  " contacts="+this.max_contact+" tilt="+this.max_tilt);
            print("PANEL range="+this.low+","+this.high+" orientationError="+this.orientation_error);
            print("PANEL motionRate="+this.motion_rate+" motionTilt="+this.motion_tilt+" settled="+this.settled);
            print("PANEL endpointError="+this.endpoint_error+" holdRate="+this.hold_rate+" valid="+this.valid);
            emit("FLIP_PANEL",if ok {"PASS"} else {"FAIL"}); this.done=true;
        }
    }
}
