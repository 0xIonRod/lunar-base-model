model GriffinTetherPairStudy
  "Reduced pair of straight, tension-only payout lines; no wheel wrapping or cloth model"
  model Line
    parameter Real stiffness(unit="N/m")=0.0;
    parameter Real damping(unit="N.s/m")=0.0;
    parameter Real initial_length(unit="m")=0.0;
    parameter Real payout_speed(unit="m/s")=0.0;
    parameter Real payout_extension(unit="m")=0.0;
    parameter Real tension_limit(unit="N")=0.0;
    input Real enabled=0.0;
    input Real dx(unit="m")=0.0;
    input Real dy(unit="m")=0.0;
    input Real dz(unit="m")=0.0;
    input Real radial_rate(unit="m/s")=0.0;
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
  equation
    assert(stiffness>0 and damping>=0 and initial_length>0 and payout_speed>=0
      and payout_extension>0 and tension_limit>0,"Positive tether study parameters required");
    distance=sqrt(dx*dx+dy*dy+dz*dz+1e-12);
    extension=max(0.0,distance-length);
    paid_rate=if noEvent(enabled>0.5) then payout_speed*min(1.0,extension/payout_extension) else 0.0;
    der(length)=paid_rate;
    stretch_rate=radial_rate-paid_rate;
    tension=if noEvent(enabled>0.5 and extension>0.0)
      then stiffness*extension+damping*max(0.0,stretch_rate) else 0.0;
    assert(tension<=tension_limit,"Tether study exceeds its assumed tension limit");
    force_x=tension*dx/distance;
    force_y=tension*dy/distance;
    force_z=tension*dz/distance;
    elastic_energy=if noEvent(enabled>0.5) then 0.5*stiffness*extension*extension else 0.0;
    spool_power=tension*paid_rate;
    damper_power=if noEvent(enabled>0.5 and extension>0.0)
      then damping*max(0.0,stretch_rate)*max(0.0,stretch_rate) else 0.0;
  end Line;

  parameter Real stiffness(unit="N/m")=0.0;
  parameter Real damping(unit="N.s/m")=0.0;
  parameter Real initial_length(unit="m")=0.0;
  parameter Real payout_speed(unit="m/s")=0.0;
  parameter Real payout_extension(unit="m")=0.0;
  parameter Real tension_limit(unit="N")=0.0;
  input Real enabled=0.0;
  input Real span0_x=0.0; input Real span0_y=0.0; input Real span0_z=0.0;
  input Real span1_x=0.0; input Real span1_y=0.0; input Real span1_z=0.0;
  input Real rate0=0.0; input Real rate1=0.0;
  input Real rover_arm0_x=0.0; input Real rover_arm0_y=0.0; input Real rover_arm0_z=0.0;
  input Real rover_arm1_x=0.0; input Real rover_arm1_y=0.0; input Real rover_arm1_z=0.0;
  input Real lander_arm0_x=0.0; input Real lander_arm0_y=0.0; input Real lander_arm0_z=0.0;
  input Real lander_arm1_x=0.0; input Real lander_arm1_y=0.0; input Real lander_arm1_z=0.0;
  Line line0(stiffness=stiffness,damping=damping,initial_length=initial_length,
    payout_speed=payout_speed,payout_extension=payout_extension,tension_limit=tension_limit,
    enabled=enabled,dx=span0_x,dy=span0_y,dz=span0_z,radial_rate=rate0);
  Line line1(stiffness=stiffness,damping=damping,initial_length=initial_length,
    payout_speed=payout_speed,payout_extension=payout_extension,tension_limit=tension_limit,
    enabled=enabled,dx=span1_x,dy=span1_y,dz=span1_z,radial_rate=rate1);
  output Real force_x=line0.force_x+line1.force_x;
  output Real force_y=line0.force_y+line1.force_y;
  output Real force_z=line0.force_z+line1.force_z;
  output Real reaction_x=-force_x;
  output Real reaction_y=-force_y;
  output Real reaction_z=-force_z;
  output Real torque_x=rover_arm0_y*line0.force_z-rover_arm0_z*line0.force_y
    +rover_arm1_y*line1.force_z-rover_arm1_z*line1.force_y;
  output Real torque_y=rover_arm0_z*line0.force_x-rover_arm0_x*line0.force_z
    +rover_arm1_z*line1.force_x-rover_arm1_x*line1.force_z;
  output Real torque_z=rover_arm0_x*line0.force_y-rover_arm0_y*line0.force_x
    +rover_arm1_x*line1.force_y-rover_arm1_y*line1.force_x;
  output Real reaction_torque_x=-lander_arm0_y*line0.force_z+lander_arm0_z*line0.force_y
    -lander_arm1_y*line1.force_z+lander_arm1_z*line1.force_y;
  output Real reaction_torque_y=-lander_arm0_z*line0.force_x+lander_arm0_x*line0.force_z
    -lander_arm1_z*line1.force_x+lander_arm1_x*line1.force_z;
  output Real reaction_torque_z=-lander_arm0_x*line0.force_y+lander_arm0_y*line0.force_x
    -lander_arm1_x*line1.force_y+lander_arm1_y*line1.force_x;
  output Real tension0=line0.tension;
  output Real tension1=line1.tension;
  output Real length0=line0.length;
  output Real length1=line1.length;
  output Real elastic_energy=line0.elastic_energy+line1.elastic_energy;
  output Real spool_power=line0.spool_power+line1.spool_power;
  output Real damper_power=line0.damper_power+line1.damper_power;
end GriffinTetherPairStudy;
