model GriffinTetherPairContract
  model LoadResponse
    extends GriffinTetherPairStudy.Line;
    output Real command_tension=regulated_tension;
  end LoadResponse;
  GriffinTetherPairStudy pair(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=1.01,span1_y=1.01);
  GriffinTetherPairStudy slack(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=0.8,span1_y=0.8);
  GriffinTetherPairStudy held(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed0=0.0,payout_speed1=0.0,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=1.01,span1_y=0.8);
  GriffinTetherPairStudy commanded(stiffness=4000,damping=800,initial_length=1.0,
    payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=1.01,span1_y=0.8);
  GriffinTetherPairStudy reeled(stiffness=4000,damping=800,initial_length=1.0,
    payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=1.02,span1_y=0.8);
  Real dissipated(start=0.0,fixed=true);
  GriffinTetherPairStudy independent(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed0=0.0,payout_speed1=0.12,
    payout_extension=0.03,tension_limit=2500,enabled=1.0,
    span0_x=1.01,span1_y=1.01);
  GriffinTetherPairStudy governed(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,regulate=1.0,body_speed=0.25,span0_x=1.02,span1_y=1.02);
  GriffinTetherPairStudy regulated(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,regulate=1.0,body_speed=0.0,span0_x=1.0125,span1_y=1.0125);
  GriffinTetherPairStudy.Line rolling(wheel_radius=0.465,tangent_branch=1,
    stiffness=4000,damping=800,initial_length=1.0,preload_tension=50,
    payout_speed=-0.01,payout_extension=0.03,tension_limit=2500,enabled=1.0,
    dx=-1.0,dy=-0.465,dz=0,axis_x=0,axis_y=0,axis_z=1,
    relative_x=0.1,relative_y=0,relative_z=0,omega_x=0,omega_y=0,omega_z=-0.1/0.465);
  GriffinTetherPairStudy.Line routed(wheel_radius=0.465,tangent_branch=1,routed=1,
    stiffness=4000,damping=2000,initial_length=1.0,preload_tension=50,
    payout_speed=-0.01,payout_extension=0.03,tension_limit=2500,enabled=1.0,
    dx=4.46,dy=1.02,dz=0,axis_x=0,axis_y=0,axis_z=-1,
    guides=[4.25,0.98,0;1.35,0.98,0;1.10,0.94,0;0.88,0.77,0;0.70,0.48,0;0.56,0.05,0;0.46,-0.51,0]);
  GriffinTetherPairStudy pitch_guard(stiffness=4000,damping=300,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,regulate=1.0,body_speed=0.0,up_vertical=0.0,nose_down_rate=0.1,
    span0_x=1.02,span1_y=1.02);
  GriffinTetherPairStudy slow_pitch_guard(stiffness=4000,damping=300,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,regulate=1.0,up_vertical=-0.01,nose_down_rate=-0.001,
    span0_x=1.02,span1_y=1.02);
  GriffinTetherPairStudy angular_guard(stiffness=4000,damping=300,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,regulate=1.0,angular_govern_enabled=1.0,body_angular_speed=0.2,
    span0_x=1.02,span1_y=1.02);
  GriffinTetherPairStudy front_catch(stiffness=4000,damping=300,initial_length=1.0,
    payout_speed0=0.12,payout_speed1=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,regulate=1.0,angular_govern_enabled=1.0,body_angular_speed=0.2,
    nose_down_rate=0.2,up_vertical=-0.05,span0_x=1.02,span1_y=1.02);
  GriffinTetherPairStudy wrapped_pair(stiffness=4000,damping=300,initial_length=1.0,
    payout_speed0=-0.01,payout_speed1=-0.01,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,wheel_radius=0.465,tangent_branch=1,
    span0_x=-1.0,span0_y=-0.465,span1_x=-1.0,span1_y=-0.465,
    axis0_x=0,axis0_z=1,axis1_x=0,axis1_z=1,
    lander_arm0_x=-1.0,lander_arm0_y=-0.465,
    lander_arm1_x=-1.0,lander_arm1_y=-0.465);
  GriffinTetherPairStudy.Line creeping(wheel_radius=0.465,tangent_branch=1,
    stiffness=4000,damping=300,initial_length=1.0,preload_tension=50,
    payout_speed=-0.01,payout_extension=0.03,tension_limit=2500,enabled=1.0,
    dx=-1.0,dy=-0.465,dz=0,axis_x=0,axis_y=0,axis_z=1,
    relative_x=-1e-6,relative_y=0,relative_z=0,omega_x=0,omega_y=0,omega_z=0);
  GriffinTetherPairStudy.Line returning(stiffness=4000,damping=300,initial_length=1.0,
    preload_tension=50,governor_tension=600,payout_speed=0.12,payout_extension=0.03,
    tension_limit=2500,enabled=1.0,regulate=1.0,drive_scale=0.0,
    dx=1.15-0.12*time,radial_rate=-0.12);
  LoadResponse load_response(stiffness=4000,damping=300,initial_length=1.0,
    preload_tension=50,governor_tension=600,payout_speed=0.12,payout_extension=0.03,
    tension_limit=2500,enabled=1.0,regulate=1.0,
    drive_scale=if time<0.5 or time>=1.5 then 1.0 else 0.0,
    dx=1.0125+0.03*time,radial_rate=0.03);
  GriffinTetherPairStudy.Line sling(stiffness=4000,damping=300,initial_length=1.0,
    preload_tension=50,payout_speed=-0.01,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,wheel_radius=0.465,balanced_wrap=1.0,dx=-1.0,dy=1.0,
    axis_x=0,axis_z=1,omega_z=2.0);
equation
  assert(abs(sling.wrap_torque_x)+abs(sling.wrap_torque_y)+abs(sling.wrap_torque_z)<1e-9
    and abs(sling.contact_rate)<1e-9 and abs(sling.power_residual)<1e-9,
    "A balanced wheel sling must not gain material length or shaft work from free wheel rotation");
  assert(abs(sling.force_x+sling.force_y)<1e-9,
    "The reduced balanced-sling resultant must pass through the axle and fixed guide");
  assert(load_response.command_tension>=49.999 and load_response.command_tension<=600.001,
    "Finite winch response must remain within preload and governed command bounds");
  assert(time<0.5 or time>0.55 or load_response.command_tension<210.0,
    "A contact handoff must not instantaneously step the commanded load from 50 to 600 N");
  assert(time<1.3 or time>=1.5 or load_response.command_tension>597.0,
    "Finite winch response must establish the requested load within its response envelope");
  assert(time<1.8 or load_response.command_tension<52.0,
    "Unloading response must promptly retire the previous governed-load demand");
  assert(returning.tension<=50.000001 and (time>0.1 or returning.paid_rate>0.12),
    "A stopped drive must relieve stored load on return instead of maintaining the 600 N outgoing restraint target");
  assert(abs(slow_pitch_guard.drive_scale)<1e-12 and slow_pitch_guard.line0.paid_rate<=0.12000001,
    "The position barrier must retain restraint through a small pitch-rate reversal");
  assert(abs(angular_guard.drive_scale)<1e-12 and angular_guard.length0<=1.0+1e-8,
    "Rear-lowering angular speed must inhibit drive and positive payout");
  assert(abs(front_catch.drive_scale-1.0)<1e-12,
    "A supported front axle must retain traction to catch nose-down motion instead of being parked by the upright governor");
  assert(front_catch.line0.pose_load>0.999,
    "Loaded outboard-track traction must not release the sling pose hold before actual front-wheel terrain contact");
  assert(creeping.paid_rate>=-0.01000001 and creeping.paid_rate<=0.0,
    "Preload creep must approach its elastic target continuously without relay chattering");
  assert(time<2.5 or (creeping.tension>40 and creeping.tension<50.01),
    "Continuous take-up must retain finite preload under slow strap motion");
  assert(abs(pitch_guard.drive_scale)<1e-12 and pitch_guard.line0.paid_rate<=0.12000001,
    "Pitch approach must inhibit drive while retaining bounded vertical lowering payout");
  assert(pitch_guard.payout_scale>0.999,
    "Pitch restraint must not lock the independent vertical-lowering payout channel");
  assert(abs(wrapped_pair.torque_x+wrapped_pair.reaction_torque_x)<1e-8
    and abs(wrapped_pair.torque_y+wrapped_pair.reaction_torque_y)<1e-8
    and abs(wrapped_pair.torque_z+wrapped_pair.reaction_torque_z)<1e-8,
    "Wheel wrap couples and fixed-anchor moments must conserve total angular momentum");
  assert(abs(routed.span[1]-0.70)<1e-8 and abs(routed.span[2]-0.48)<1e-8,
    "The loaded bottom wrap must route over the convex rail, rather than through the deck");
  assert(abs(rolling.contact_rate)<1e-9,
    "A bottom wrap must unroll without strain for exact rolling along a flat strap");
  assert(abs(rolling.power_residual)<1e-8,
    "Wheel force and wrap torque must account for the same material power");
  assert(abs(rolling.wrap_torque_z+rolling.force_y-0.465*rolling.force_x)<1e-8,
    "Wheel and fixed-anchor wrenches must conserve angular momentum");
  assert(time<0.2 or rolling.tension>7.9,
    "A taut wheel wrap must carry the preload after take-up");
  der(dissipated)=pair.spool_power+pair.damper_power;
  commanded.payout_speed0=if time<0.1 then 0.0 else 0.12;
  commanded.payout_speed1=commanded.payout_speed0;
  reeled.payout_speed0=if time<0.1 then 0.0 else -0.12;
  reeled.payout_speed1=reeled.payout_speed0;
  assert(abs(pair.force_x+pair.reaction_x)<1e-8 and abs(pair.force_y+pair.reaction_y)<1e-8
    and abs(pair.force_z+pair.reaction_z)<1e-8,"Tether reactions must be equal and opposite");
  assert(pair.tension0>=0.0 and pair.tension1>=0.0 and pair.spool_power>=0.0
    and pair.damper_power>=0.0,"Lines may only pull and dissipate");
  assert(abs(slack.force_x)+abs(slack.force_y)+abs(slack.force_z)<1e-8
    and abs(slack.length0-1.0)<1e-8,"Slack lines must carry no load or uncommanded payout");
  assert(abs(held.tension0-40.0)<1e-6 and abs(held.length0-1.0)<1e-8,
    "The winch hold command must preserve positive pretension without paying out");
  assert(time<0.2 or commanded.length0>1.0001,
    "A nonzero payout command must increase the line's unstretched length");
  assert(time<0.2 or (abs(reeled.length0-1.0)<1e-8 and reeled.length1<0.999),
    "The local preload limiter must hold the taut line while taking up the slack line");
  assert(abs(pair.elastic_energy+dissipated-0.4)<1e-4,
    "Fixed-end payout must dissipate the initial 0.4 J elastic energy");
  assert(abs(independent.length0-1.0)<1e-8 and
    (time<0.2 or independent.length1>1.0001),
    "One winch must be able to pay out while the other holds");
  assert(abs(governed.drive_scale)<1e-12 and governed.length0<=1.0+1e-8
    and governed.length1<=1.0+1e-8,
    "Excess body speed must stop positive payout, take up restraint and remove forward drive demand");
  assert(abs(regulated.tension0-50.0)<1e-6 and abs(regulated.tension1-50.0)<1e-6,
    "The tension servo must hold its target without introducing payout drag at rest");
end GriffinTetherPairContract;
