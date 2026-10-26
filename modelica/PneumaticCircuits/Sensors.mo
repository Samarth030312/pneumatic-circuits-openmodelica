within PneumaticCircuits;
package Sensors "Gauges"

  model PressureGauge "Pressure gauge: reads the net's pressure (gauge, bar); takes no flow"
    Interfaces.Port port annotation(Placement(transformation(extent = {{16, -4}, {24, 4}})));
    Interfaces.RealOutput p_bar "gauge pressure (bar)" annotation(Placement(transformation(extent = {{-4, 16}, {4, 24}})));
  equation
    port.m_flow = 0;
    p_bar = (port.p - p_atm) / 1e5;
    annotation(Icon(coordinateSystem(extent = {{-20, -20}, {20, 20}}), graphics = {
      Ellipse(extent = {{-14, 14}, {14, -14}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-8, -8}, {8, 8}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{14, 0}, {20, 0}}),
      Text(extent = {{-20, -16}, {20, -26}}, textString = "%name")}));
  end PressureGauge;
end Sensors;
