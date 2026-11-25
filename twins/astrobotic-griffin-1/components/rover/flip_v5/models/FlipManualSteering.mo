within;
model FlipManualSteering "Operator turn-rate demand for the fixed-axis FLIP wheels"
  input Real steer "Signed operator or direct program demand, right positive";
  input Real program_active;
  input Real throttle "Signed operator or direct program travel demand";
  input Real velocity_x(unit="m/s");
  input Real velocity_z(unit="m/s");
  input Real yaw(unit="rad") "Native heading about +Y";
  input Real yaw_rate(unit="rad/s") "Native yaw about +Y, left positive";
  parameter Real pivot_rate(min=1.0e-6, unit="rad/s") = 0.30 "Full-stick pivot target";
  parameter Real lateral_acceleration(min=1.0e-6, unit="m/s2") = 0.30 "Travel turn budget";
  parameter Real rate_gain(unit="s/rad") = 2.0 "Differential drive per turn-rate error";
  parameter Real integral_gain(unit="1/rad") = 0.6;
  parameter Real integral_limit = 0.3;
  parameter Real pivot_speed_gain(unit="s/m") = 1.5;
  parameter Real pivot_speed_integral_gain(unit="1/m") = 1.0;
  parameter Real reset_time(unit="s", min=1e-6) = 0.15;
  parameter Real neutral_rate(unit="rad/s") = 0.01 "Release differential drive below this residual rate";
  output Real demand "Normalized differential command to the skid mixer";
  output Real throttle_demand "Common drive allocated after differential demand";
  Real ground_speed(unit="m/s");
  Real target_rate(unit="rad/s");
  Real rate_error(unit="rad/s");
  Real integral_demand(start=0, fixed=true);
  Real raw_demand;
  Real common_limit;
  Real forward_speed(unit="m/s");
  Real pivot_speed_integral(start=0, fixed=true);
  Real pivot_common;
  Real pivot_gate;
equation
  ground_speed = sqrt(velocity_x^2 + velocity_z^2);
  target_rate = steer * lateral_acceleration / max(ground_speed, lateral_acceleration / pivot_rate);
  rate_error = target_rate + yaw_rate;
  raw_demand = rate_gain*rate_error +
    (if noEvent(abs(steer) > 0) then integral_demand else 0);
  // Conditional integration retains steering authority against steady soil
  // resistance and prevents windup at both the actuator and integrator bounds.
  der(integral_demand) = if noEvent(program_active > 0.5 or abs(steer) <= 0) then
      -integral_demand/reset_time
    elseif noEvent((raw_demand >= 1 or integral_demand >= integral_limit) and rate_error > 0
      or (raw_demand <= -1 or integral_demand <= -integral_limit) and rate_error < 0) then 0
    else integral_gain*rate_error;
  demand = if program_active > 0.5 then steer
           elseif noEvent(abs(steer) <= 0.0 and abs(yaw_rate) < neutral_rate) then 0.0
           else max(-1.0, min(1.0, raw_demand));
  // Preserve the requested differential rather than clipping it independently
  // at full throttle in RoverDrivetrain's left and right motor commands.
  common_limit = 1-abs(demand);
  forward_speed = -velocity_x*sin(yaw)-velocity_z*cos(yaw);
  pivot_gate = if noEvent(program_active <= 0.5 and abs(throttle) <= 0 and abs(steer) > 0) then 1.0 else 0.0;
  pivot_common = -pivot_speed_gain*forward_speed + pivot_speed_integral;
  der(pivot_speed_integral) = if noEvent(pivot_gate < 0.5) then -pivot_speed_integral/reset_time
    elseif noEvent((pivot_common >= common_limit and forward_speed < 0)
      or (pivot_common <= -common_limit and forward_speed > 0)) then 0
    else -pivot_speed_integral_gain*forward_speed;
  throttle_demand = if program_active > 0.5 then throttle
    elseif noEvent(pivot_gate > 0.5) then max(-common_limit, min(common_limit, pivot_common))
    else max(-common_limit, min(common_limit, throttle));
end FlipManualSteering;
