model GriffinTetherWrenchProbe
  "One-step bounded wrench pass-through for the native FLIP body ports"
  input Real force_x=0.0;
  input Real torque_y=0.0;
  output Real body_force_x;
  output Real body_torque_y;
equation
  body_force_x=force_x;
  body_torque_y=torque_y;
end GriffinTetherWrenchProbe;
