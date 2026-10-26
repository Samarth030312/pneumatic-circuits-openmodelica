within PneumaticCircuits;
package Sensors "Gauges"

  model PressureGauge "Pressure gauge: reads the net's pressure (gauge, bar); takes no flow"
    parameter String tag = "" "designation shown in the diagram, e.g. 1V2" annotation(Dialog(group = "Diagram"));
    Interfaces.Port port annotation(Placement(transformation(extent = {{16, -4}, {24, 4}})));
    Real p_bar "gauge pressure (bar)";
  equation
    port.m_flow = 0;
    p_bar = (port.p - p_atm) / 1e5;
    annotation(Documentation(info = "<html><h4>Pressure gauge</h4><p>Shows the gauge pressure of the net it is connected to, in bar, on its dial
and as a number in the animation. It takes no air. Fit one on each side of a cylinder: the piston's force
is p_cap A_cap - p_rod A_rod, which no single gauge shows.</p></html>"),
      Icon(coordinateSystem(extent = {{-20, -20}, {20, 20}}), graphics = {
      Ellipse(extent = {{-14, 14}, {14, -14}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = DynamicSelect({{-8, -8}, {8, 8}}, {{0, 0}, {11 * sin((min(max(p_bar, 0), 10) * 27 - 135) * 3.14159 / 180), 11 * cos((min(max(p_bar, 0), 10) * 27 - 135) * 3.14159 / 180)}}), color = {200, 0, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Text(extent = {{-30, 26}, {30, 16}}, textString = DynamicSelect("", String(p_bar, significantDigits = 2) + " bar"), textColor = {0, 0, 160}),
      Line(points = {{14, 0}, {20, 0}}),
      Text(extent = {{-20, -16}, {20, -26}}, textString = "%tag  %name")}));
  end PressureGauge;
end Sensors;
