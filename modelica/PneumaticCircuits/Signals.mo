within PneumaticCircuits;
package Signals "The operator"

  block Schedule "An operator's hand: true during [t_on[i], t_off[i])"
    parameter Real t_on[:](each unit = "s") = {1} "press (or set) times";
    parameter Real t_off[size(t_on, 1)](each unit = "s") = {3} "release times";
    Interfaces.BooleanOutput y annotation(Placement(transformation(extent = {{11, -4}, {19, 4}})));
  equation
    y = sum(if time >= t_on[i] and time < t_off[i] then 1 else 0 for i in 1:size(t_on, 1)) > 0;
    annotation(Icon(coordinateSystem(extent = {{-15, -15}, {15, 15}}), graphics = {
      Rectangle(extent = {{-12, 12}, {12, -12}}, lineColor = {255, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-9, -6}, {-4, -6}, {-4, 6}, {4, 6}, {4, -6}, {9, -6}}, color = {255, 0, 255}),
      Text(extent = {{-15, 22}, {15, 13}}, textString = "%name")}));
  end Schedule;
end Signals;
