within;
model GriffinTrackingCamera "Two-axis observer camera that follows Griffin"
  input Real target_x_m(unit="m") "Tracked object's world X position";
  input Real target_y_m(unit="m") "Tracked object's world Y position";
  input Real target_z_m(unit="m") "Tracked object's world Z position";
  parameter Real mount_x_m(unit="m") = 4.0 "Fixed gimbal world X position";
  parameter Real mount_y_m(unit="m") = 65.0 "Fixed gimbal world Y position";
  parameter Real mount_z_m(unit="m") = -14.0 "Fixed gimbal world Z position";
  parameter Real servo_tau_s(unit="s") = 0.18 "Command response time";
  parameter Real max_pan_rate_rad_s(unit="rad/s") = 1.047197551196598 "Pan speed limit";
  parameter Real max_tilt_rate_rad_s(unit="rad/s") = 1.047197551196598 "Tilt speed limit";
  // Keep a 2 degree control margin inside the USD revolute-joint hard stops
  // (pan +/-170 degrees, tilt +/-85 degrees). The margin exceeds one
  // communication interval of travel at the configured 60 degree/s slew rate.
  parameter Real pan_soft_limit_rad(unit="rad") = 2.9321531433504737;
  parameter Real tilt_soft_limit_rad(unit="rad") = 1.4486232791552935;
  parameter Real initial_pan_rad(unit="rad") = 2.863292994584682;
  parameter Real initial_tilt_rad(unit="rad") = -0.330784291082257;

  output Real pan_angle_rad(unit="rad", start=initial_pan_rad, fixed=true);
  output Real tilt_angle_rad(unit="rad", start=initial_tilt_rad, fixed=true);
  output Real target_range_m(unit="m");
  output Real tracking_valid;

  Real delta_x_m;
  Real delta_y_m;
  Real delta_z_m;
  Real horizontal_range_m;
  Real pan_unlimited_command_rad;
  Real tilt_unlimited_command_rad;
  Real pan_command_rad;
  Real tilt_command_rad;
  Real pan_error_rad;
  Real tilt_error_rad;
  Real pan_rate_command_rad_s;
  Real tilt_rate_command_rad_s;
equation
  delta_x_m = target_x_m - mount_x_m;
  delta_y_m = target_y_m - mount_y_m;
  delta_z_m = target_z_m - mount_z_m;
  horizontal_range_m = sqrt(delta_x_m * delta_x_m + delta_z_m * delta_z_m);
  target_range_m = sqrt(horizontal_range_m * horizontal_range_m + delta_y_m * delta_y_m);

  // Camera local forward is -Z. Pan is about world +Y and tilt about the
  // panned head's local +X, so these angles aim -Z along the target vector.
  pan_unlimited_command_rad = atan2(-delta_x_m, -delta_z_m);
  tilt_unlimited_command_rad = atan2(delta_y_m, horizontal_range_m);
  pan_command_rad = max(-pan_soft_limit_rad,
                        min(pan_soft_limit_rad, pan_unlimited_command_rad));
  tilt_command_rad = max(-tilt_soft_limit_rad,
                         min(tilt_soft_limit_rad, tilt_unlimited_command_rad));
  pan_error_rad = atan2(sin(pan_command_rad - pan_angle_rad),
                        cos(pan_command_rad - pan_angle_rad));
  tilt_error_rad = tilt_command_rad - tilt_angle_rad;

  pan_rate_command_rad_s = max(-max_pan_rate_rad_s,
                               min(max_pan_rate_rad_s, pan_error_rad / servo_tau_s));
  tilt_rate_command_rad_s = max(-max_tilt_rate_rad_s,
                                min(max_tilt_rate_rad_s, tilt_error_rad / servo_tau_s));
  der(pan_angle_rad) = noEvent(
    if pan_angle_rad >= pan_soft_limit_rad and pan_rate_command_rad_s > 0.0 then 0.0
    elseif pan_angle_rad <= -pan_soft_limit_rad and pan_rate_command_rad_s < 0.0 then 0.0
    else pan_rate_command_rad_s);
  der(tilt_angle_rad) = noEvent(
    if tilt_angle_rad >= tilt_soft_limit_rad and tilt_rate_command_rad_s > 0.0 then 0.0
    elseif tilt_angle_rad <= -tilt_soft_limit_rad and tilt_rate_command_rad_s < 0.0 then 0.0
    else tilt_rate_command_rad_s);
  tracking_valid = noEvent(if target_range_m > 0.001 then 1.0 else 0.0);
end GriffinTrackingCamera;
