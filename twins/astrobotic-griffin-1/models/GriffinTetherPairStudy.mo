model GriffinTetherPairStudy
  "Two tension-only lines with optional cylindrical rear-wheel wraps"
  function routedGuide
    "Last frictionless contact of a taut line on a convex inboard-to-outboard profile"
    input Real anchor[3]; input Real guides[7,3];
    input Real axis[3]; input Real inboard[3]; input Real up[3];
    input Real radius; input Real branch;
    output Real selected[3];
  protected
    Real v[3]; Real planar[3]; Real radial[3]; Real free[3];
    Real d2; Real score; Real best;
  algorithm
    selected:=anchor;
    planar:=anchor-axis*(axis*anchor);
    d2:=planar*planar;
    radial:=radius^2/max(d2,radius^2+1e-12)*planar
      +branch*radius*sqrt(max(0,d2-radius^2))/max(d2,radius^2+1e-12)*cross(axis,planar);
    free:=anchor-radial;
    best:=atan2(free*up,free*inboard);
    for i in 1:7 loop
      v:=guides[i,:];
      planar:=v-axis*(axis*v);
      d2:=planar*planar;
      if d2>radius^2+1e-12 and v*inboard>=0 then
        radial:=radius^2/d2*planar+branch*radius*sqrt(d2-radius^2)/d2*cross(axis,planar);
        free:=v-radial;
        score:=atan2(free*up,free*inboard);
        if score>best then
          best:=score;selected:=v;
        end if;
      end if;
    end for;
  end routedGuide;

  model Line
    parameter Real stiffness(unit="N/m")=0.0;
    parameter Real damping(unit="N.s/m")=0.0;
    parameter Real initial_length(unit="m")=0.0;
    parameter Real preload_tension(unit="N")=0.0;
    input Real payout_speed(unit="m/s")
      "Signed shared winch command: positive pays out, negative reels in, zero holds";
    parameter Real payout_extension(unit="m")=0.0;
    parameter Real tension_limit(unit="N")=0.0;
    input Real enabled=0.0;
    input Real regulate=0.0;
    input Real drive_scale=1.0;
    input Real payout_scale=1.0;
    input Real pose_load=0.0;
    parameter Real pose_tension(unit="N")=preload_tension;
    parameter Real governor_tension(unit="N")=600.0;
    parameter Real reel_speed_limit(unit="m/s")=2.5;
    parameter Real governed_material_speed(unit="m/s")=0.02;
    parameter Real loading_response_time(unit="s")=0.15;
    parameter Real unloading_response_time(unit="s")=0.05;
    input Real dx(unit="m")=0.0;
    input Real dy(unit="m")=0.0;
    input Real dz(unit="m")=0.0;
    input Real radial_rate(unit="m/s")=0.0;
    parameter Real wheel_radius(unit="m")=0.0;
    parameter Real tangent_branch=1.0;
    parameter Real balanced_wrap=0.0
      "Reduced balanced wheel sling: resultant through axle, no shaft-work coupling";
    parameter Real routed=0.0;
    input Real guides[7,3]=zeros(7,3);
    input Real inboard[3]={1,0,0}; input Real up[3]={0,1,0};
    input Real lander_omega[3]={0,0,0};
    Real guide_delta[3]; Real relative[3];
    input Real axis_x=1.0; input Real axis_y=0.0; input Real axis_z=0.0;
    input Real relative_x=0.0; input Real relative_y=0.0; input Real relative_z=0.0;
    input Real omega_x=0.0; input Real omega_y=0.0; input Real omega_z=0.0;
    Real wrap_torque[3]=cross(radial,{force_x,force_y,force_z});
    output Real wrap_torque_x=wrap_torque[1];
    output Real wrap_torque_y=wrap_torque[2];
    output Real wrap_torque_z=wrap_torque[3];
    output Real power_residual={force_x,force_y,force_z}*relative
      +wrap_torque_x*omega_x+wrap_torque_y*omega_y+wrap_torque_z*omega_z
      +tension*contact_rate;
    Real axis[3]; Real span[3]; Real planar[3]; Real radial[3]; Real free[3];
    Real planar_squared; Real free_distance; Real contact_rate;
    Real material_distance(start=initial_length,fixed=true);
    output Real length(unit="m",start=initial_length,fixed=true);
    output Real distance(unit="m");
    output Real extension(unit="m");
    output Real paid_rate(unit="m/s");
    output Real tension(unit="N");
    output Real force_x(unit="N");
    output Real force_y(unit="N");
    output Real force_z(unit="N");
    output Real elastic_energy(unit="J");
    output Real spool_power(unit="W");
    output Real damper_power(unit="W");
  protected
    Real stretch_rate(unit="m/s");
    Real takeup_factor;
    Real regulated_rate(unit="m/s");
    Real restraint_target(unit="N");
    Real regulated_tension(unit="N",start=preload_tension,fixed=true);
    Real positive_rate_limit(unit="m/s");
  equation
    assert(stiffness>0 and damping>=0 and initial_length>0 and preload_tension>0
      and payout_extension>0 and tension_limit>0 and governed_material_speed>0
      and loading_response_time>0 and unloading_response_time>0,
      "Positive tether and actuator study parameters required");
    axis={axis_x,axis_y,axis_z}/sqrt(axis_x^2+axis_y^2+axis_z^2);
    span=if routed>0.5 then routedGuide({dx,dy,dz},guides,axis,inboard,up,
      if balanced_wrap>0.5 then 0.0 else wheel_radius,tangent_branch)
      else {dx,dy,dz};
    guide_delta=span-{dx,dy,dz};
    relative={relative_x,relative_y,relative_z}-cross(lander_omega,guide_delta);
    planar=span-axis*(axis*span);
    planar_squared=planar*planar;
    assert(enabled<0.5 or balanced_wrap>0.5 or wheel_radius<=0 or planar_squared>wheel_radius^2,
      "Enabled tether guide intersects its wheel wrap");
    radial=if wheel_radius>0 and balanced_wrap<0.5 then wheel_radius^2/max(planar_squared,wheel_radius^2+1e-12)*planar
      +tangent_branch*wheel_radius*sqrt(max(0,planar_squared-wheel_radius^2))
        /max(planar_squared,wheel_radius^2+1e-12)*cross(axis,planar) else {0,0,0};
    free=span-radial;
    free_distance=sqrt(free*free+1e-12);
    contact_rate=if wheel_radius>0 then
      -free/free_distance*(relative+cross({omega_x,omega_y,omega_z},radial))
      else if routed>0.5 then -free/free_distance*relative else radial_rate;
    der(material_distance)=if enabled>0.5 and (wheel_radius>0 or routed>0.5) then contact_rate else 0.0;
    distance=if wheel_radius>0 or routed>0.5 then material_distance else free_distance;
    extension=max(0.0,distance-length);
    assert(regulate<0.5 or damping>0,"Tension regulation requires positive damping");
    takeup_factor=min(1.0,extension/payout_extension);
    // A load governor may oppose outgoing material, but must not pull a
    // returning wheel/body harder merely because its speed magnitude rose.
    // The same ideal bidirectional actuator can relieve stored elastic load
    // on rebound; nominal deployment payout remains command bounded.
    restraint_target=max(preload_tension+(1.0-drive_scale)*(governor_tension-preload_tension)
      *max(0.0,min(1.0,contact_rate/governed_material_speed)),
      preload_tension+pose_load*(pose_tension-preload_tension));
    // A sampled contact change is not an instantaneous actuator-load change.
    // Finite pressure/load response also prevents the two independent winches
    // from exchanging a full governed-load step at a wheel/rail handoff.
    der(regulated_tension)=((if regulate>0.5 then restraint_target else preload_tension)
      -regulated_tension)/(if restraint_target>regulated_tension
        then loading_response_time else unloading_response_time);
    positive_rate_limit=max(payout_scale*max(0.0,payout_speed),
      reel_speed_limit*max(0.0,min(1.0,-contact_rate/max(payout_speed,1e-9))));
    regulated_rate=if noEvent(regulate>0.5) then
      contact_rate+stiffness/damping*(distance-length
        -regulated_tension/stiffness) else 0.0;
    paid_rate=if noEvent(enabled>0.5) then
      (if payout_speed>0.0 then
        (if noEvent(regulate>0.5 and takeup_factor>1e-6) then
          if regulated_rate<0.0 then max(-reel_speed_limit,regulated_rate)
          else min(positive_rate_limit,regulated_rate)
         else if noEvent(regulate>0.5) then min(0.0,max(-reel_speed_limit,regulated_rate)) else payout_speed*takeup_factor)
       else if payout_speed<0.0 then payout_speed*max(0.0,min(1.0,
         (preload_tension-stiffness*extension)/preload_tension)) else 0.0)
      else 0.0;
    der(length)=paid_rate;
    stretch_rate=contact_rate-paid_rate;
    tension=if noEvent(enabled>0.5 and extension>0.0)
      then max(0.0,stiffness*extension+damping*stretch_rate) else 0.0;
    assert(tension<=tension_limit,"Tether study exceeds its assumed tension limit");
    force_x=tension*free[1]/free_distance;
    force_y=tension*free[2]/free_distance;
    force_z=tension*free[3]/free_distance;
    elastic_energy=if noEvent(enabled>0.5) then 0.5*stiffness*extension*extension else 0.0;
    spool_power=tension*paid_rate;
    damper_power=if noEvent(enabled>0.5 and extension>0.0)
      then (tension-stiffness*extension)*stretch_rate else 0.0;
  end Line;

  parameter Real stiffness(unit="N/m")=0.0;
  parameter Real damping(unit="N.s/m")=0.0;
  parameter Real initial_length(unit="m")=0.0;
  parameter Real preload_tension(unit="N")=50.0;
  parameter Real governor_tension(unit="N")=1000.0;
  parameter Real pose_tension(unit="N")=750.0;
  parameter Real loading_response_time(unit="s")=0.15;
  parameter Real unloading_response_time(unit="s")=0.05;
  parameter Real reel_speed_limit(unit="m/s")=2.5;
  input Real payout_speed0(unit="m/s");
  input Real payout_speed1(unit="m/s");
  parameter Real payout_extension(unit="m")=0.0;
  parameter Real tension_limit(unit="N")=0.0;
  input Real enabled=0.0;
  input Real regulate=0.0;
  input Real body_speed(unit="m/s")=0.0;
  parameter Real governed_speed(unit="m/s")=0.10;
  parameter Real payout_stop_speed(unit="m/s")=0.18;
  input Real body_angular_speed(unit="rad/s")=0.0;
  input Real angular_govern_enabled=0.0;
  input Real front_grounded=0.0;
  parameter Real governed_angular_speed(unit="rad/s")=0.05;
  parameter Real payout_stop_angular_speed(unit="rad/s")=0.10;
  Real angular_scale=if angular_govern_enabled>0.5 and nose_down_rate<=0.0 then max(0.0,min(1.0,
    (payout_stop_angular_speed-body_angular_speed)/(payout_stop_angular_speed-governed_angular_speed))) else 1.0;
  input Real up_vertical=1.0;
  input Real nose_down_rate(unit="rad/s")=0.0;
  parameter Real pitch_govern_start=0.3420201433256687 "cos(70 degrees)";
  parameter Real pitch_govern_stop=0.08715574274765817 "cos(85 degrees)";
  parameter Real maximum_pitch_rate(unit="rad/s")=0.05;
  Real speed_scale=max(0.0,min(1.0,
    (payout_stop_speed-body_speed)/(payout_stop_speed-governed_speed)));
  Real pitch_rate_demand=max(0.0,min(1.0,(pitch_govern_start-up_vertical)
    /(pitch_govern_start-pitch_govern_stop)))
    *max(0.0,min(1.0,nose_down_rate/maximum_pitch_rate));
  Real pitch_position_demand=max(0.0,min(1.0,
    (pitch_govern_stop-up_vertical)/pitch_govern_stop));
  // Once the front tires carry fixed-world support, forward front-axle
  // traction catches the descending centre of mass and restores upright.
  // Inhibiting that traction for nose-down pitch would worsen over-center.
  Real pitch_demand=if front_grounded<0.5
    then max(pitch_rate_demand,pitch_position_demand) else 0.0;
  Real payout_scale=min(speed_scale,angular_scale);
  output Real drive_scale=min(payout_scale,
    if angular_govern_enabled>0.5 then 1.0 else 1.0-pitch_demand);
  Real restraint_scale=min(payout_scale,1.0-pitch_demand);
  parameter Real wheel_radius(unit="m")=0.0;
  parameter Real tangent_branch=1.0;
  parameter Real balanced_wrap=1.0
    "Production study uses a balanced rear-wheel bridle resultant; detailed end rigging is unknown";
  parameter Real routed=0.0;
  input Real inboard_x=1.0; input Real inboard_y=0.0; input Real inboard_z=0.0;
  input Real up_x=0.0; input Real up_y=1.0; input Real up_z=0.0;
  input Real lander_omega_x=0.0; input Real lander_omega_y=0.0; input Real lander_omega_z=0.0;
  input Real guide0_0_x=0.0; input Real guide0_0_y=0.0; input Real guide0_0_z=0.0;
  input Real guide0_1_x=0.0; input Real guide0_1_y=0.0; input Real guide0_1_z=0.0;
  input Real guide0_2_x=0.0; input Real guide0_2_y=0.0; input Real guide0_2_z=0.0;
  input Real guide0_3_x=0.0; input Real guide0_3_y=0.0; input Real guide0_3_z=0.0;
  input Real guide0_4_x=0.0; input Real guide0_4_y=0.0; input Real guide0_4_z=0.0;
  input Real guide0_5_x=0.0; input Real guide0_5_y=0.0; input Real guide0_5_z=0.0;
  input Real guide0_6_x=0.0; input Real guide0_6_y=0.0; input Real guide0_6_z=0.0;
  input Real guide1_0_x=0.0; input Real guide1_0_y=0.0; input Real guide1_0_z=0.0;
  input Real guide1_1_x=0.0; input Real guide1_1_y=0.0; input Real guide1_1_z=0.0;
  input Real guide1_2_x=0.0; input Real guide1_2_y=0.0; input Real guide1_2_z=0.0;
  input Real guide1_3_x=0.0; input Real guide1_3_y=0.0; input Real guide1_3_z=0.0;
  input Real guide1_4_x=0.0; input Real guide1_4_y=0.0; input Real guide1_4_z=0.0;
  input Real guide1_5_x=0.0; input Real guide1_5_y=0.0; input Real guide1_5_z=0.0;
  input Real guide1_6_x=0.0; input Real guide1_6_y=0.0; input Real guide1_6_z=0.0;
  input Real axis0_x=1.0; input Real axis0_y=0.0; input Real axis0_z=0.0;
  input Real axis1_x=1.0; input Real axis1_y=0.0; input Real axis1_z=0.0;
  input Real relative0_x=0.0; input Real relative0_y=0.0; input Real relative0_z=0.0;
  input Real relative1_x=0.0; input Real relative1_y=0.0; input Real relative1_z=0.0;
  input Real omega0_x=0.0; input Real omega0_y=0.0; input Real omega0_z=0.0;
  input Real omega1_x=0.0; input Real omega1_y=0.0; input Real omega1_z=0.0;
  input Real span0_x=0.0; input Real span0_y=0.0; input Real span0_z=0.0;
  input Real span1_x=0.0; input Real span1_y=0.0; input Real span1_z=0.0;
  input Real rate0=0.0; input Real rate1=0.0;
  input Real rover_arm0_x=0.0; input Real rover_arm0_y=0.0; input Real rover_arm0_z=0.0;
  input Real rover_arm1_x=0.0; input Real rover_arm1_y=0.0; input Real rover_arm1_z=0.0;
  input Real lander_arm0_x=0.0; input Real lander_arm0_y=0.0; input Real lander_arm0_z=0.0;
  input Real lander_arm1_x=0.0; input Real lander_arm1_y=0.0; input Real lander_arm1_z=0.0;
  Line line0(stiffness=stiffness,damping=damping,initial_length=initial_length,
    preload_tension=preload_tension,governor_tension=governor_tension,reel_speed_limit=reel_speed_limit,payout_speed=payout_speed0,payout_extension=payout_extension,tension_limit=tension_limit,
    enabled=enabled,regulate=regulate,drive_scale=restraint_scale,payout_scale=payout_scale,
    pose_load=if front_grounded<0.5 then pitch_position_demand else 0.0,pose_tension=pose_tension,
    loading_response_time=loading_response_time,unloading_response_time=unloading_response_time,
    governed_material_speed=if wheel_radius>0 then wheel_radius*governed_angular_speed else governed_speed,
    dx=span0_x,dy=span0_y,dz=span0_z,radial_rate=rate0,
    wheel_radius=wheel_radius,tangent_branch=tangent_branch,balanced_wrap=balanced_wrap,routed=routed,
    guides=[guide0_0_x,guide0_0_y,guide0_0_z;guide0_1_x,guide0_1_y,guide0_1_z;guide0_2_x,guide0_2_y,guide0_2_z;guide0_3_x,guide0_3_y,guide0_3_z;guide0_4_x,guide0_4_y,guide0_4_z;guide0_5_x,guide0_5_y,guide0_5_z;guide0_6_x,guide0_6_y,guide0_6_z],inboard={inboard_x,inboard_y,inboard_z},up={up_x,up_y,up_z},
    lander_omega={lander_omega_x,lander_omega_y,lander_omega_z},
    axis_x=axis0_x,axis_y=axis0_y,axis_z=axis0_z,
    relative_x=relative0_x,relative_y=relative0_y,relative_z=relative0_z,
    omega_x=omega0_x,omega_y=omega0_y,omega_z=omega0_z);
  Line line1(stiffness=stiffness,damping=damping,initial_length=initial_length,
    preload_tension=preload_tension,governor_tension=governor_tension,reel_speed_limit=reel_speed_limit,payout_speed=payout_speed1,payout_extension=payout_extension,tension_limit=tension_limit,
    enabled=enabled,regulate=regulate,drive_scale=restraint_scale,payout_scale=payout_scale,
    pose_load=if front_grounded<0.5 then pitch_position_demand else 0.0,pose_tension=pose_tension,
    loading_response_time=loading_response_time,unloading_response_time=unloading_response_time,
    governed_material_speed=if wheel_radius>0 then wheel_radius*governed_angular_speed else governed_speed,
    dx=span1_x,dy=span1_y,dz=span1_z,radial_rate=rate1,
    wheel_radius=wheel_radius,tangent_branch=tangent_branch,balanced_wrap=balanced_wrap,routed=routed,
    guides=[guide1_0_x,guide1_0_y,guide1_0_z;guide1_1_x,guide1_1_y,guide1_1_z;guide1_2_x,guide1_2_y,guide1_2_z;guide1_3_x,guide1_3_y,guide1_3_z;guide1_4_x,guide1_4_y,guide1_4_z;guide1_5_x,guide1_5_y,guide1_5_z;guide1_6_x,guide1_6_y,guide1_6_z],inboard={inboard_x,inboard_y,inboard_z},up={up_x,up_y,up_z},
    lander_omega={lander_omega_x,lander_omega_y,lander_omega_z},
    axis_x=axis1_x,axis_y=axis1_y,axis_z=axis1_z,
    relative_x=relative1_x,relative_y=relative1_y,relative_z=relative1_z,
    omega_x=omega1_x,omega_y=omega1_y,omega_z=omega1_z);
  output Real wheel_force0_x=line0.force_x;
  output Real wheel_torque0_x=line0.wrap_torque_x;
  output Real wheel_force0_y=line0.force_y;
  output Real wheel_torque0_y=line0.wrap_torque_y;
  output Real wheel_force0_z=line0.force_z;
  output Real wheel_torque0_z=line0.wrap_torque_z;
  output Real power_residual0=line0.power_residual;
  output Real wheel_force1_x=line1.force_x;
  output Real wheel_torque1_x=line1.wrap_torque_x;
  output Real wheel_force1_y=line1.force_y;
  output Real wheel_torque1_y=line1.wrap_torque_y;
  output Real wheel_force1_z=line1.force_z;
  output Real wheel_torque1_z=line1.wrap_torque_z;
  output Real power_residual1=line1.power_residual;
  output Real force_x=line0.force_x+line1.force_x;
  output Real routing0_x=line0.span[1];
  output Real routing0_y=line0.span[2];
  output Real routing0_z=line0.span[3];
  output Real routing1_x=line1.span[1];
  output Real routing1_y=line1.span[2];
  output Real routing1_z=line1.span[3];
  output Real force_y=line0.force_y+line1.force_y;
  output Real force_z=line0.force_z+line1.force_z;
  output Real reaction_x=-force_x;
  output Real reaction_y=-force_y;
  output Real reaction_z=-force_z;
  output Real torque_x=rover_arm0_y*line0.force_z-rover_arm0_z*line0.force_y
    +rover_arm1_y*line1.force_z-rover_arm1_z*line1.force_y+line0.wrap_torque_x+line1.wrap_torque_x;
  output Real torque_y=rover_arm0_z*line0.force_x-rover_arm0_x*line0.force_z
    +rover_arm1_z*line1.force_x-rover_arm1_x*line1.force_z+line0.wrap_torque_y+line1.wrap_torque_y;
  output Real torque_z=rover_arm0_x*line0.force_y-rover_arm0_y*line0.force_x
    +rover_arm1_x*line1.force_y-rover_arm1_y*line1.force_x+line0.wrap_torque_z+line1.wrap_torque_z;
  output Real reaction_torque_x=-(lander_arm0_y+line0.guide_delta[2])*line0.force_z+(lander_arm0_z+line0.guide_delta[3])*line0.force_y
    -(lander_arm1_y+line1.guide_delta[2])*line1.force_z+(lander_arm1_z+line1.guide_delta[3])*line1.force_y;
  output Real reaction_torque_y=-(lander_arm0_z+line0.guide_delta[3])*line0.force_x+(lander_arm0_x+line0.guide_delta[1])*line0.force_z
    -(lander_arm1_z+line1.guide_delta[3])*line1.force_x+(lander_arm1_x+line1.guide_delta[1])*line1.force_z;
  output Real reaction_torque_z=-(lander_arm0_x+line0.guide_delta[1])*line0.force_y+(lander_arm0_y+line0.guide_delta[2])*line0.force_x
    -(lander_arm1_x+line1.guide_delta[1])*line1.force_y+(lander_arm1_y+line1.guide_delta[2])*line1.force_x;
  output Real material_rate0=line0.contact_rate;
  output Real paid_rate0=line0.paid_rate;
  output Real extension0=line0.extension;
  output Real tension0=line0.tension;
  output Real material_rate1=line1.contact_rate;
  output Real paid_rate1=line1.paid_rate;
  output Real extension1=line1.extension;
  output Real tension1=line1.tension;
  output Real length0=line0.length;
  output Real length1=line1.length;
  output Real elastic_energy=line0.elastic_energy+line1.elastic_energy;
  output Real spool_power=line0.spool_power+line1.spool_power;
  output Real damper_power=line0.damper_power+line1.damper_power;
equation
  assert(pitch_govern_start<=1 and pitch_govern_start>pitch_govern_stop and pitch_govern_stop>0 and maximum_pitch_rate>0,
    "Pitch governor must act before vertical with a positive angular-rate bound");
  assert(governor_tension>=pose_tension and pose_tension>=preload_tension and governor_tension<tension_limit and reel_speed_limit>0,
    "Governed load and take-up must remain inside the assumed line envelope");
  assert(governed_speed>0 and payout_stop_speed>governed_speed,
    "The payout stop speed must exceed the positive governed descent speed");
  assert(governed_angular_speed>0 and payout_stop_angular_speed>governed_angular_speed,
    "The angular payout stop must exceed the positive governed angular speed");
end GriffinTetherPairStudy;
