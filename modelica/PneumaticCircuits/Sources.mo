within PneumaticCircuits;
package Sources "Supply, exhaust and tube volumes"

  model PressureSupply "Compressor and service unit: a reservoir at p_gauge behind the service unit's conductance"
    parameter String tag = "" "designation shown in the diagram, e.g. 1V2" annotation(Dialog(group = "Diagram"));
    parameter Real p_gauge(unit = "Pa") = 6e5 "regulated supply pressure (gauge)";
    parameter Real qn(unit = "l/min") = 750 "service unit's standard nominal flow rate (ESTIMATED)";
    parameter Real b = 0.3 "critical pressure ratio (ESTIMATED)";
    final parameter Real C = Functions.conductance(qn, b);
    Interfaces.Port port annotation(Placement(transformation(extent = {{-8, 32}, {8, 48}})));
  equation
    port.m_flow = -Functions.massFlow(C, b, p_atm + p_gauge, port.p);
    annotation(Icon(coordinateSystem(extent = {{-40, -40}, {40, 40}}), graphics = {
      Ellipse(extent = {{-30, 30}, {30, -30}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Polygon(points = {{0, 22}, {-10, 6}, {10, 6}, {0, 22}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid),
      Line(points = {{0, 30}, {0, 40}}),
      Text(extent = {{34, 5}, {120, -5}}, textString = "%tag  %name", horizontalAlignment = TextAlignment.Left)}),
      Documentation(info = "<html><p>The service unit (filter, regulator) is the supply's only restriction; the
regulator is taken as ideal (p_gauge held upstream of it).</p></html>"));
  end PressureSupply;

  model Exhaust "Exhaust to atmosphere"
    Interfaces.Port port annotation(Placement(transformation(extent = {{-6, 14}, {6, 26}})));
  equation
    port.p = p_atm;
    annotation(Documentation(info = "<html><h4>Exhaust</h4><p>A port open to the atmosphere (1.013 bar absolute, 0 bar gauge). Most valves here
have their exhausts built in; use this for any other port that vents.</p></html>"),
      Icon(coordinateSystem(extent = {{-20, -20}, {20, 20}}), graphics = {
      Polygon(points = {{0, 14}, {-10, -4}, {10, -4}, {0, 14}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{0, 14}, {0, 20}})}));
  end Exhaust;

  model Tube "Tube net: the lumped volume of the tubing joining the connected ports"
    parameter Real L(unit = "m") = 0.5 "tube length (ESTIMATED)";
    parameter Real D(unit = "m") = 2.5e-3 "inner diameter: PUN 4 x 0.75 tubing (VERIFIED: Festo Didactic 152888 datasheet names it)";
    parameter Real V_extra(unit = "m3") = 0.3e-6 "fittings (ESTIMATED)";
    parameter Real n = 1.2 "polytropic exponent (ESTIMATED; 1 isothermal, 1.4 adiabatic)";
    parameter Real p_start(unit = "Pa") = p_atm "initial pressure";
    final parameter Real V(unit = "m3") = pi * D ^ 2 / 4 * L + V_extra;
    Real p_bar = (port.p - p_atm) / 1e5 "gauge (bar)";
    Interfaces.Port port annotation(Placement(transformation(extent = {{-6, -6}, {6, 6}})));
  initial equation
    port.p = p_start;
  equation
    der(port.p) = n * R_air * T0 / V * port.m_flow;
    annotation(Icon(coordinateSystem(extent = {{-10, -10}, {10, 10}}), graphics = {
      Ellipse(extent = DynamicSelect({{-2.5, 2.5}, {2.5, -2.5}}, {{-4, 4}, {4, -4}}), lineColor = DynamicSelect({0, 0, 0}, if p_bar > 0.5 then {0, 90, 220} else {0, 0, 0}),
        fillColor = DynamicSelect({0, 0, 0}, if p_bar > 0.5 then {0, 90, 220} else {0, 0, 0}), fillPattern = FillPattern.Solid)}),
      Documentation(info = "<html><p>One net of the circuit: the tubes and fittings between the ports it connects.
dp/dt = n R T0 m_flow / V. Its flow resistance is lumped into the components' conductances.</p></html>"));
  end Tube;

end Sources;
