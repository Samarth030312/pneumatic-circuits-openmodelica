within PneumaticCircuits;
package Signals "The operator"

  block Schedule "An operator's hand: true during [t_on[i], t_off[i])"
    parameter String tag = "" "designation shown in the diagram, e.g. 1V2" annotation(Dialog(group = "Diagram"));
    parameter Real t_on[:](each unit = "s") = {1} "press (or set) times";
    parameter Real t_off[size(t_on, 1)](each unit = "s") = {3} "release times";
    Interfaces.BooleanOutput y annotation(Placement(transformation(extent = {{11, -4}, {19, 4}})));
  equation
    y = sum(if time >= t_on[i] and time < t_off[i] then 1 else 0 for i in 1:size(t_on, 1)) > 0;
    annotation(Documentation(info = "<html><h4>Operator</h4><p>Presses (or sets) during [t_on[i], t_off[i]), in seconds of simulated time. Several presses:
t_on = {1, 4}, t_off = {2, 5}. Connect its output to a push button's or selector switch's input.</p></html>"),
      Icon(coordinateSystem(extent = {{-15, -15}, {15, 15}}), graphics = {
      Rectangle(extent = {{-12, 12}, {12, -12}}, lineColor = {255, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-9, -6}, {-4, -6}, {-4, 6}, {4, 6}, {4, -6}, {9, -6}}, color = {255, 0, 255}),
      Text(extent = {{-15, 22}, {15, 13}}, textString = "%tag  %name"),
      Text(extent = {{-30, -13}, {30, -22}}, textString = DynamicSelect("", if y then "pressed" else ""), textColor = {220, 0, 0})}));
  end Schedule;
end Signals;
