within PneumaticCircuits;
package Actuators "Cylinders"
  import PneumaticCircuits.Functions.massFlow;
  import PneumaticCircuits.Functions.conductance;

  model DoubleActingCylinder "Double-acting cylinder: two variable chambers, piston with friction, end stops"
    parameter Real D(unit = "m") = 0.020 "piston diameter (VERIFIED: Festo Didactic 152888)";
    parameter Real d(unit = "m") = 0.008 "rod diameter (VERIFIED: 152888)";
    parameter Real L(unit = "m") = 0.100 "stroke (VERIFIED: 152888)";
    parameter Real m(unit = "kg") = 0.15 "moving mass: piston, rod, trip cam, load (ESTIMATED)";
    parameter Real V0A(unit = "m3") = 1.5e-6 "dead volume, cap side (ESTIMATED)";
    parameter Real V0B(unit = "m3") = 1.5e-6 "dead volume, rod side (ESTIMATED)";
    parameter Real qn_port(unit = "l/min") = 150 "each port: fitting QS-G1/8-4 and the tube's resistance (ESTIMATED)";
    parameter Real b = 0.3 "(ESTIMATED)";
    parameter Real n = 1.2 "polytropic exponent (ESTIMATED)";
    parameter Real F_c(unit = "N") = 8 "Coulomb friction (ESTIMATED)";
    parameter Real F_s(unit = "N") = 12 "static (breakaway) friction (ESTIMATED)";
    parameter Real v_s(unit = "m/s") = 0.01 "Stribeck velocity (ESTIMATED)";
    parameter Real v_eps(unit = "m/s") = 1e-3 "friction regularisation velocity";
    parameter Real b_v(unit = "N.s/m") = 20 "viscous friction (ESTIMATED)";
    parameter Real alpha(unit = "deg") = 0 "inclination: 90 extends straight down, -90 straight up";
    parameter Real F_load(unit = "N") = 0 "constant force against extension";
    parameter Real x_work(unit = "m") = 1 "workpiece contact at this position (beyond the stroke: none)";
    parameter Real k_work(unit = "N/m") = 2e5 "workpiece stiffness (ESTIMATED)";
    parameter Real d_work(unit = "N.s/m") = 200 "workpiece damping (ESTIMATED)";
    parameter Real k_stop(unit = "N/m") = 1e7 "end stops (contact model)";
    parameter Real d_stop(unit = "N.s/m") = 2500 "end stops, about critical damping";
    parameter Real x_start(unit = "m") = 0 "initial position";
    final parameter Real A1(unit = "m2") = pi * D ^ 2 / 4 "cap-side area";
    final parameter Real A2(unit = "m2") = pi * (D ^ 2 - d ^ 2) / 4 "rod-side area";
    final parameter Real Cp = conductance(qn_port, b);
    Interfaces.Port A "cap side" annotation(Placement(transformation(extent = {{-74, -34}, {-66, -26}})));
    Interfaces.Port B "rod side" annotation(Placement(transformation(extent = {{26, -34}, {34, -26}})));
    Interfaces.RealOutput x_out(unit = "m") "piston position" annotation(Placement(transformation(extent = {{96, -24}, {104, -16}})));
    Real x(unit = "m", start = x_start, fixed = true) "piston position, 0 retracted";
    Real v(unit = "m/s", start = 0, fixed = true);
    Real pA(unit = "Pa", start = p_atm, fixed = true) "cap chamber";
    Real pB(unit = "Pa", start = p_atm, fixed = true) "rod chamber";
    Real VA(unit = "m3"), VB(unit = "m3");
    Real F_p(unit = "N") "pneumatic force";
    Real F_f(unit = "N") "friction";
    Real F_end(unit = "N") "end stops and workpiece";
  equation
    A.m_flow = massFlow(Cp, b, A.p, pA);
    B.m_flow = massFlow(Cp, b, B.p, pB);
    VA = V0A + A1 * x;
    VB = V0B + A2 * (L - x);
    der(pA) = n / VA * (R_air * T0 * A.m_flow - pA * A1 * v);
    der(pB) = n / VB * (R_air * T0 * B.m_flow + pB * A2 * v);
    F_p = pA * A1 - pB * A2 - p_atm * (A1 - A2);
    F_f = (F_c + (F_s - F_c) * exp(-(v / v_s) ^ 2)) * tanh(v / v_eps) + b_v * v;
    F_end = (if x < 0 then max(0, -k_stop * x - d_stop * v) else 0)
          - (if x > L then max(0, k_stop * (x - L) + d_stop * v) else 0)
          - (if x > x_work then max(0, k_work * (x - x_work) + d_work * v) else 0);
    der(x) = v;
    m * der(v) = F_p - F_f - F_load + F_end + m * g_n * sin(alpha * pi / 180);
    x_out = x;
    annotation(Icon(coordinateSystem(extent = {{-100, -30}, {100, 30}}), graphics = {
      Rectangle(extent = {{-80, 20}, {40, -20}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Rectangle(extent = {{-50, 20}, {-44, -20}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid),
      Rectangle(extent = {{-44, 4}, {96, -4}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-70, -30}, {-70, -20}}), Line(points = {{30, -30}, {30, -20}}),
      Text(extent = {{-80, 32}, {0, 22}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}),
      Documentation(info = "<html><p>Chambers: dp/dt = n/V (R T0 m_flow -/+ p A v), V = V0 + A x (cap), V0 + A_rod (L - x) (rod).
Piston: m dv/dt = pA A1 - pB A2 - p_atm (A1 - A2) - F_friction - F_load + F_stops + m g sin(alpha).
Friction: Stribeck curve (F_s breakaway, F_c sliding, viscous b_v), regularised by tanh(v/v_eps).
End stops and an optional workpiece: stiff spring-dampers that only push.</p></html>"));
  end DoubleActingCylinder;
end Actuators;
