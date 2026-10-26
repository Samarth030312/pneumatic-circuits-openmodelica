within PneumaticCircuits;
package Interfaces "Connectors"

  connector Port "Pneumatic port: absolute pressure and mass flow into the component"
    Real p(unit = "Pa", nominal = 1e5, start = p_atm) "absolute pressure";
    flow Real m_flow(unit = "kg/s", nominal = 1e-3) "mass flow into the component";
    annotation(
      Icon(graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid)}),
      Diagram(graphics = {Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid)}));
  end Port;

  connector RealInput = input Real "Signal input"
    annotation(Icon(graphics = {Polygon(points = {{-100, 100}, {100, 0}, {-100, -100}, {-100, 100}}, lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid)}));

  connector RealOutput = output Real "Signal output"
    annotation(Icon(graphics = {Polygon(points = {{-100, 100}, {100, 0}, {-100, -100}, {-100, 100}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}));

  connector BooleanInput = input Boolean "Logic input"
    annotation(Icon(graphics = {Polygon(points = {{-100, 100}, {100, 0}, {-100, -100}, {-100, 100}}, lineColor = {255, 0, 255}, fillColor = {255, 0, 255}, fillPattern = FillPattern.Solid)}));

  connector BooleanOutput = output Boolean "Logic output"
    annotation(Icon(graphics = {Polygon(points = {{-100, 100}, {100, 0}, {-100, -100}, {-100, 100}}, lineColor = {255, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}));
end Interfaces;
