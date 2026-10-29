model FlipIdleMotorContract
  LunCo.Electrical.DCMotor coast(coast_at_zero=1.0);
  LunCo.Electrical.DCMotor brake(coast_at_zero=0.0);
  LunCo.Electrical.DCMotor powered(coast_at_zero=1.0);
  LunCo.Electrical.IdealVoltageSource supply;
equation
  connect(supply.p,coast.p);
  connect(supply.p,brake.p);
  connect(supply.p,powered.p);
  coast.speed=2400.0; coast.demand=0.0;
  brake.speed=2400.0; brake.demand=0.0;
  powered.speed=0.0; powered.demand=1.0;
  assert(abs(coast.shaft_torque)<1e-9 and abs(coast.heat)<1e-9 and abs(coast.electrical_power)<1e-9,
    "Open-circuit idle must have zero current, torque and heat");
  assert(brake.shaft_torque<0.0 and brake.heat>0.0,
    "Legacy zero-voltage drive must retain short-circuit braking");
  assert(powered.shaft_torque>0.0 and powered.heat>0.0,
    "Idle-coast selection must preserve nonzero commanded drive");
  assert(abs(coast.electrical_power-coast.mechanical_power_w-coast.heat)<1e-6
    and abs(brake.electrical_power-brake.mechanical_power_w-brake.heat)<1e-6
    and abs(powered.electrical_power-powered.mechanical_power_w-powered.heat)<1e-6,
    "Every selected motor mode must close its power balance");
end FlipIdleMotorContract;
