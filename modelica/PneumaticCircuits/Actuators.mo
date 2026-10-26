within PneumaticCircuits;
package Actuators "Cylinders"
  import PneumaticCircuits.Functions.massFlow;
  import PneumaticCircuits.Functions.conductance;

  model DoubleActingCylinder "Double-acting cylinder: two variable chambers, piston with friction, end stops"
    parameter String tag = "" "designation shown in the diagram, e.g. 1V2" annotation(Dialog(group = "Diagram"));
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
    Real pA_bar = (pA - p_atm) / 1e5 "cap chamber, gauge (bar)";
    Real pB_bar = (pB - p_atm) / 1e5 "rod chamber, gauge (bar)";
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
      Rectangle(extent = DynamicSelect({{-80, 19}, {-50, -19}}, {{-80, 19}, {-50 + 80 * x / L, -19}}), lineColor = {255, 255, 255}, pattern = LinePattern.None,
        fillColor = DynamicSelect({255, 255, 255}, {255 - integer(min(max(pA_bar, 0), 7) * 25), 255 - integer(min(max(pA_bar, 0), 7) * 12), 255}), fillPattern = FillPattern.Solid),
      Rectangle(extent = DynamicSelect({{-44, 19}, {40, -19}}, {{-44 + 80 * x / L, 19}, {40, -19}}), lineColor = {255, 255, 255}, pattern = LinePattern.None,
        fillColor = DynamicSelect({255, 255, 255}, {255 - integer(min(max(pB_bar, 0), 7) * 25), 255 - integer(min(max(pB_bar, 0), 7) * 12), 255}), fillPattern = FillPattern.Solid),
      Rectangle(extent = DynamicSelect({{-50, 20}, {-44, -20}}, {{-50 + 80 * x / L, 20}, {-44 + 80 * x / L, -20}}), lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid),
      Rectangle(extent = DynamicSelect({{-44, 4}, {56, -4}}, {{-44 + 80 * x / L, 4}, {56 + 80 * x / L, -4}}), lineColor = {0, 0, 0}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid),
      Rectangle(extent = {{-80, 20}, {40, -20}}, lineColor = {0, 0, 0}),
      Line(points = {{-70, -30}, {-70, -20}}), Line(points = {{30, -30}, {30, -20}}),
      Text(extent = {{-80, 32}, {0, 22}}, textString = "%tag  %name", horizontalAlignment = TextAlignment.Left),
      Text(extent = {{0, 32}, {100, 22}}, textString = DynamicSelect("", String(floor(x * 1000 + 0.5)) + " mm  " + String(floor(v * 100 + 0.5) / 100) + " m/s"), horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 160})}),
      Documentation(info = "<html><p>Chambers: dp/dt = n/V (R T0 m_flow -/+ p A v), V = V0 + A x (cap), V0 + A_rod (L - x) (rod).
Piston: m dv/dt = pA A1 - pB A2 - p_atm (A1 - A2) - F_friction - F_load + F_stops + m g sin(alpha).
Friction: Stribeck curve (F_s breakaway, F_c sliding, viscous b_v), regularised by tanh(v/v_eps).
End stops and an optional workpiece: stiff spring-dampers that only push.</p></html>"));
  end DoubleActingCylinder;
  model SingleActingCylinder "Single-acting cylinder: air extends it, a spring returns it"
    parameter String tag = "" "designation shown in the diagram, e.g. 1A" annotation(Dialog(group = "Diagram"));
    parameter Real D(unit = "m") = 0.020 "piston diameter (ESTIMATED: as the kit's double-acting cylinder)";
    parameter Real L(unit = "m") = 0.050 "stroke (ESTIMATED)";
    parameter Real m(unit = "kg") = 0.10 "moving mass (ESTIMATED)";
    parameter Real F_spring0(unit = "N") = 10 "spring force, retracted (ESTIMATED)";
    parameter Real k_spring(unit = "N/m") = 300 "spring rate (ESTIMATED)";
    parameter Real V0A(unit = "m3") = 1.5e-6 "dead volume (ESTIMATED)";
    parameter Real qn_port(unit = "l/min") = 150 "port: fitting and the tube's resistance (ESTIMATED)";
    parameter Real b = 0.3 "(ESTIMATED)";
    parameter Real n = 1.2 "polytropic exponent (ESTIMATED)";
    parameter Real F_c(unit = "N") = 6 "Coulomb friction (ESTIMATED)";
    parameter Real F_s(unit = "N") = 9 "breakaway friction (ESTIMATED)";
    parameter Real v_s(unit = "m/s") = 0.01;
    parameter Real v_eps(unit = "m/s") = 1e-3;
    parameter Real b_v(unit = "N.s/m") = 20 "viscous friction (ESTIMATED)";
    parameter Real k_stop(unit = "N/m") = 1e7;
    parameter Real d_stop(unit = "N.s/m") = 2500;
    final parameter Real A1(unit = "m2") = pi * D ^ 2 / 4;
    final parameter Real Cp = conductance(qn_port, b);
    Interfaces.Port A "air port" annotation(Placement(transformation(extent = {{-74, -34}, {-66, -26}})));
    Interfaces.RealOutput x_out(unit = "m") "piston position" annotation(Placement(transformation(extent = {{96, -24}, {104, -16}})));
    Real x(unit = "m", start = 0, fixed = true);
    Real v(unit = "m/s", start = 0, fixed = true);
    Real pA(unit = "Pa", start = p_atm, fixed = true);
    Real pA_bar = (pA - p_atm) / 1e5 "chamber, gauge (bar)";
    Real F_f(unit = "N"), F_end(unit = "N"), F_spring(unit = "N");
  equation
    A.m_flow = massFlow(Cp, b, A.p, pA);
    der(pA) = n / (V0A + A1 * x) * (R_air * T0 * A.m_flow - pA * A1 * v);
    F_spring = F_spring0 + k_spring * x;
    F_f = (F_c + (F_s - F_c) * exp(-(v / v_s) ^ 2)) * tanh(v / v_eps) + b_v * v;
    F_end = (if x < 0 then max(0, -k_stop * x - d_stop * v) else 0) - (if x > L then max(0, k_stop * (x - L) + d_stop * v) else 0);
    der(x) = v;
    m * der(v) = (pA - p_atm) * A1 - F_spring - F_f + F_end;
    x_out = x;
    annotation(Icon(coordinateSystem(extent = {{-100, -30}, {100, 30}}), graphics = {
      Rectangle(extent = {{-80, 20}, {40, -20}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Rectangle(extent = DynamicSelect({{-80, 19}, {-50, -19}}, {{-80, 19}, {-50 + 80 * x / L, -19}}), pattern = LinePattern.None,
        fillColor = DynamicSelect({255, 255, 255}, {255 - integer(min(max(pA_bar, 0), 7) * 25), 255 - integer(min(max(pA_bar, 0), 7) * 12), 255}), fillPattern = FillPattern.Solid),
      Line(points = DynamicSelect({{-44, 0}, {-36, 14}, {-26, -14}, {-16, 14}, {-6, -14}, {4, 14}, {14, -14}, {24, 14}, {34, -14}, {40, 0}},
        {{-44 + 80 * x / L, 0}, {-36 + 72 * x / L, 14}, {-26 + 63 * x / L, -14}, {-16 + 54 * x / L, 14}, {-6 + 45 * x / L, -14}, {4 + 36 * x / L, 14}, {14 + 27 * x / L, -14}, {24 + 18 * x / L, 14}, {34 + 9 * x / L, -14}, {40, 0}})),
      Rectangle(extent = DynamicSelect({{-50, 20}, {-44, -20}}, {{-50 + 80 * x / L, 20}, {-44 + 80 * x / L, -20}}), lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid),
      Rectangle(extent = DynamicSelect({{-44, 4}, {56, -4}}, {{-44 + 80 * x / L, 4}, {56 + 80 * x / L, -4}}), lineColor = {0, 0, 0}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid),
      Rectangle(extent = {{-80, 20}, {40, -20}}, lineColor = {0, 0, 0}),
      Line(points = {{-70, -30}, {-70, -20}}), Line(points = {{30, -20}, {30, -25}}),
      Text(extent = {{-80, 32}, {0, 22}}, textString = "%tag  %name", horizontalAlignment = TextAlignment.Left),
      Text(extent = {{0, 32}, {100, 22}}, textString = DynamicSelect("", String(floor(x * 1000 + 0.5)) + " mm"), horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 160})}),
      Documentation(info = "<html><p>Air on one side extends it; a spring returns it when the air is let out.
Chamber: dp/dt = n/V (R T0 m_flow - p A v). Piston: m dv/dt = (p - p_atm) A - F_spring - F_friction.
The spring takes part of the force: at full stroke only (p - p_atm) A - F_spring is left for the load.</p></html>"));
  end SingleActingCylinder;
end Actuators;
