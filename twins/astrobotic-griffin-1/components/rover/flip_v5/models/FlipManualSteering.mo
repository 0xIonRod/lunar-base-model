within;
model FlipManualSteering "Operator turn-rate demand for the fixed-axis FLIP wheels"
  input Real steer "Signed operator or direct program demand, right positive";
  input Real program_active;
  input Real velocity_x(unit="m/s");
  input Real velocity_z(unit="m/s");
  input Real yaw_rate(unit="rad/s") "Native yaw about +Y, left positive";
  parameter Real pivot_rate(min=1.0e-6, unit="rad/s") = 0.30 "Full-stick pivot target";
  parameter Real lateral_acceleration(min=1.0e-6, unit="m/s2") = 0.30 "Travel turn budget";
  parameter Real rate_gain(unit="s/rad") = 2.0 "Differential drive per turn-rate error";
  parameter Real neutral_rate(unit="rad/s") = 0.01 "Release differential drive below this residual rate";
  output Real demand "Normalized differential command to the skid mixer";
  Real ground_speed(unit="m/s");
  Real target_rate(unit="rad/s");
equation
  ground_speed = sqrt(velocity_x^2 + velocity_z^2);
  target_rate = steer * lateral_acceleration / max(ground_speed, lateral_acceleration / pivot_rate);
  demand = if program_active > 0.5 then steer
           elseif noEvent(abs(steer) <= 0.0 and abs(yaw_rate) < neutral_rate) then 0.0
           else max(-1.0, min(1.0, rate_gain * (target_rate + yaw_rate)));
end FlipManualSteering;
