within PneumaticCircuits;
package Valves "Directional, logic, flow and pressure valves"
  import PneumaticCircuits.Functions.massFlow;
  import PneumaticCircuits.Functions.conductance;
  import PneumaticCircuits.Functions.step;

  partial model Valve32 "3/2-way valve, normally closed, spring return; port 3 exhausts to atmosphere"
    parameter Real qn(unit = "l/min") = 80 "standard nominal flow rate (ESTIMATED)";
    parameter Real b = 0.3 "critical pressure ratio (ESTIMATED)";
    parameter Real tau(unit = "s") = 0.005 "switching time constant (ESTIMATED)";
    final parameter Real C = conductance(qn, b);
    Interfaces.Port p1 "1: supply" annotation(Placement(transformation(extent = {{4, -19}, {12, -11}})));
    Interfaces.Port p2 "2: output" annotation(Placement(transformation(extent = {{4, 11}, {12, 19}})));
    Real xv(start = 0, fixed = true) "spool position, 0 at rest (2 -> 3), 1 actuated (1 -> 2)";
    Real m12(unit = "kg/s") "1 -> 2";
    Real m23(unit = "kg/s") "2 -> 3 (exhaust)";
    Boolean actuated;
  equation
    der(xv) = ((if actuated then 1 else 0) - xv) / tau;
    m12 = xv * massFlow(C, b, p1.p, p2.p);
    m23 = (1 - xv) * massFlow(C, b, p2.p, p_atm);
    p1.m_flow = m12;
    p2.m_flow = -m12 + m23;
    annotation(Icon(coordinateSystem(extent = {{-50, -25}, {50, 25}}), graphics = {
      Rectangle(extent = {{-30, 15}, {0, -15}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Rectangle(extent = {{0, 15}, {30, -15}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-22, -15}, {-22, 15}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{-8, -15}, {-8, -9}}), Line(points = {{-12, -9}, {-4, -9}}),
      Line(points = {{8, 15}, {22, -15}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{8, -15}, {8, -9}}), Line(points = {{4, -9}, {12, -9}}),
      Line(points = {{22, -15}, {22, -19}}),
      Polygon(points = {{22, -19}, {18, -25}, {26, -25}, {22, -19}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{30, 0}, {33, 6}, {36, -6}, {39, 6}, {42, -6}, {45, 0}}),
      Text(extent = {{-50, 26}, {0, 16}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}));
  end Valve32;

  model PushButtonValve32 "3/2-way push-button valve, normally closed, spring return"
    extends Valve32;
    Interfaces.BooleanInput pressed "the operator presses" annotation(Placement(transformation(extent = {{-54, -4}, {-46, 4}})));
  equation
    actuated = pressed;
    annotation(Icon(graphics = {Line(points = {{-30, 0}, {-40, 0}}), Line(points = {{-40, -7}, {-40, 7}}), Line(points = {{-43, -7}, {-43, 7}})}));
  end PushButtonValve32;

  model SelectorValve32 "3/2-way valve with selector switch (detented), normally closed"
    extends Valve32;
    Interfaces.BooleanInput on "the switch is set" annotation(Placement(transformation(extent = {{-54, -4}, {-46, 4}})));
  equation
    actuated = on;
    annotation(Icon(graphics = {Line(points = {{-30, 0}, {-38, 0}, {-44, 8}}), Line(points = {{-36, 4}, {-34, 0}, {-36, -4}})}));
  end SelectorValve32;

  model RollerValve32 "3/2-way roller lever valve, normally closed: actuated by the piston's trip cam"
    extends Valve32;
    parameter Real x_trip(unit = "m") "position at which the cam presses the roller";
    parameter Boolean whenAbove = true "actuated for x >= x_trip (else x <= x_trip)";
    Interfaces.RealInput x(unit = "m") "piston position" annotation(Placement(transformation(extent = {{-54, -4}, {-46, 4}})));
  equation
    actuated = if whenAbove then x >= x_trip else x <= x_trip;
    annotation(Icon(graphics = {Line(points = {{-30, 0}, {-36, 0}}), Ellipse(extent = {{-46, 5}, {-36, -5}}, lineColor = {0, 0, 0})}));
  end RollerValve32;

  model PressureSequenceValve "Pressure sequence valve: a 3/2-way valve switched when port 12 exceeds p_set"
    extends Valve32(qn = 80);
    parameter Real p_set(unit = "Pa") = 4e5 "switching pressure, gauge (adjustable)";
    parameter Real dp_hyst(unit = "Pa") = 0.2e5 "switches back at p_set - dp_hyst (ESTIMATED)";
    parameter Real V_sense(unit = "m3") = 0.3e-6 "control chamber (ESTIMATED)";
    parameter Real qn_sense(unit = "l/min") = 20 "into the control chamber (ESTIMATED)";
    parameter Real n = 1.2;
    final parameter Real Cs = conductance(qn_sense, b);
    Interfaces.Port p12 "12: control (sensed) pressure" annotation(Placement(transformation(extent = {{-54, -4}, {-46, 4}})));
    Real p_c(unit = "Pa", start = p_atm, fixed = true) "control chamber pressure";
    discrete Boolean on(start = false, fixed = true);
  equation
    p12.m_flow = massFlow(Cs, b, p12.p, p_c);
    der(p_c) = n * R_air * T0 / V_sense * p12.m_flow;
    when p_c - p_atm > p_set then
      on = true;
    elsewhen p_c - p_atm < p_set - dp_hyst then
      on = false;
    end when;
    actuated = on;
    annotation(Icon(graphics = {Line(points = {{-30, 0}, {-46, 0}}, pattern = LinePattern.Dash),
      Polygon(points = {{-30, 0}, {-36, 4}, {-36, -4}, {-30, 0}}, lineColor = {0, 0, 0}),
      Line(points = {{30, 0}, {33, 6}, {36, -6}, {39, 6}, {42, -6}, {45, 0}}), Line(points = {{32, -8}, {44, 8}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 3)}));
  end PressureSequenceValve;

  partial model Valve52 "5/2-way valve: at rest 1 -> 2 and 4 -> 5, switched 1 -> 4 and 2 -> 3; 3 and 5 exhaust"
    parameter Real qn(unit = "l/min") = 110 "standard nominal flow rate per path (ESTIMATED)";
    parameter Real b = 0.3 "critical pressure ratio (ESTIMATED)";
    parameter Real tau(unit = "s") = 0.008 "switching time constant (ESTIMATED)";
    parameter Real p_on(unit = "Pa") = 1.5e5 "pilot pressure that switches the valve, gauge (ESTIMATED)";
    parameter Real p_off(unit = "Pa") = 1.0e5 "pilot pressure below which it returns, gauge (ESTIMATED)";
    parameter Real V_pilot(unit = "m3") = 0.5e-6 "pilot chamber (ESTIMATED)";
    parameter Real qn_pilot(unit = "l/min") = 30 "into the pilot chamber (ESTIMATED)";
    parameter Real n = 1.2;
    final parameter Real C = conductance(qn, b);
    final parameter Real Cp = conductance(qn_pilot, b);
    Interfaces.Port p1 "1: supply" annotation(Placement(transformation(extent = {{16, -24}, {24, -16}})));
    Interfaces.Port p2 "2: output, pressurised at rest" annotation(Placement(transformation(extent = {{26, 16}, {34, 24}})));
    Interfaces.Port p4 "4: output, pressurised when switched" annotation(Placement(transformation(extent = {{6, 16}, {14, 24}})));
    Real xv(start = 0, fixed = true) "spool, 0 at rest, 1 switched";
    Real m14(unit = "kg/s"), m23(unit = "kg/s"), m12(unit = "kg/s"), m45(unit = "kg/s");
    Boolean switched;
  equation
    der(xv) = ((if switched then 1 else 0) - xv) / tau;
    m14 = xv * massFlow(C, b, p1.p, p4.p);
    m23 = xv * massFlow(C, b, p2.p, p_atm);
    m12 = (1 - xv) * massFlow(C, b, p1.p, p2.p);
    m45 = (1 - xv) * massFlow(C, b, p4.p, p_atm);
    p1.m_flow = m14 + m12;
    p2.m_flow = -m12 + m23;
    p4.m_flow = -m14 + m45;
    annotation(Icon(coordinateSystem(extent = {{-60, -30}, {60, 30}}), graphics = {
      Rectangle(extent = {{-40, 20}, {0, -20}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Rectangle(extent = {{0, 20}, {40, -20}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-20, -20}, {-30, 20}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{-10, 20}, {-6, -20}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{-34, -20}, {-34, -14}}), Line(points = {{-38, -14}, {-30, -14}}),
      Line(points = {{20, -20}, {30, 20}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{10, 20}, {6, -20}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{34, -20}, {34, -14}}), Line(points = {{30, -14}, {38, -14}}),
      Line(points = {{6, -20}, {6, -23}}), Line(points = {{34, -20}, {34, -23}}),
      Polygon(points = {{6, -23}, {2, -29}, {10, -29}, {6, -23}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Polygon(points = {{34, -23}, {30, -29}, {38, -29}, {34, -23}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-60, 30}, {0, 21}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}));
  end Valve52;

  model PilotValve52 "5/2-way valve, pneumatic pilot 14, spring return"
    extends Valve52;
    Interfaces.Port p14 "14: pilot" annotation(Placement(transformation(extent = {{-64, -4}, {-56, 4}})));
    Real p_pilot(unit = "Pa", start = p_atm, fixed = true);
    discrete Boolean on(start = false, fixed = true);
  equation
    p14.m_flow = massFlow(Cp, b, p14.p, p_pilot);
    der(p_pilot) = n * R_air * T0 / V_pilot * p14.m_flow;
    when p_pilot - p_atm > p_on then
      on = true;
    elsewhen p_pilot - p_atm < p_off then
      on = false;
    end when;
    switched = on;
    annotation(Icon(graphics = {Line(points = {{-60, 0}, {-48, 0}}, pattern = LinePattern.Dash),
      Polygon(points = {{-40, 0}, {-48, 5}, {-48, -5}, {-40, 0}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{40, 0}, {43, 7}, {47, -7}, {51, 7}, {55, -7}, {58, 0}})}));
  end PilotValve52;

  model DoublePilotValve52 "5/2-way double-pilot valve (memory): 14 switches it, 12 switches it back"
    extends Valve52;
    parameter Boolean switched_start = false "initial position";
    Interfaces.Port p14 "14: pilot, switch" annotation(Placement(transformation(extent = {{-64, -4}, {-56, 4}})));
    Interfaces.Port p12 "12: pilot, back" annotation(Placement(transformation(extent = {{56, -4}, {64, 4}})));
    Real p_pilot14(unit = "Pa", start = p_atm, fixed = true);
    Real p_pilot12(unit = "Pa", start = p_atm, fixed = true);
    discrete Boolean on(start = switched_start, fixed = true);
  equation
    p14.m_flow = massFlow(Cp, b, p14.p, p_pilot14);
    p12.m_flow = massFlow(Cp, b, p12.p, p_pilot12);
    der(p_pilot14) = n * R_air * T0 / V_pilot * p14.m_flow;
    der(p_pilot12) = n * R_air * T0 / V_pilot * p12.m_flow;
    when p_pilot14 - p_atm > p_on and p_pilot12 - p_atm < p_off then
      on = true;
    elsewhen p_pilot12 - p_atm > p_on and p_pilot14 - p_atm < p_off then
      on = false;
    end when;
    switched = on;
    annotation(Icon(graphics = {Line(points = {{-60, 0}, {-48, 0}}, pattern = LinePattern.Dash),
      Polygon(points = {{-40, 0}, {-48, 5}, {-48, -5}, {-40, 0}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{60, 0}, {48, 0}}, pattern = LinePattern.Dash),
      Polygon(points = {{40, 0}, {48, 5}, {48, -5}, {40, 0}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}));
  end DoublePilotValve52;

  model TwoPressureValve "Two-pressure valve (AND): the output follows the lower of the two inputs"
    parameter Real qn(unit = "l/min") = 100 "standard nominal flow rate (ESTIMATED)";
    parameter Real b = 0.3 "(ESTIMATED)";
    parameter Real dp_w(unit = "Pa") = 5e3 "pressure difference over which the shuttle moves (ESTIMATED)";
    final parameter Real C = conductance(qn, b);
    Interfaces.Port x "1: input" annotation(Placement(transformation(extent = {{-44, -4}, {-36, 4}})));
    Interfaces.Port y "1: input" annotation(Placement(transformation(extent = {{36, -4}, {44, 4}})));
    Interfaces.Port a "2: output" annotation(Placement(transformation(extent = {{-4, 21}, {4, 29}})));
    Real w "1: x is the lower input and feeds the output";
    Real mx(unit = "kg/s"), my(unit = "kg/s");
  equation
    w = step(y.p - x.p, dp_w);
    mx = w * massFlow(C, b, x.p, a.p);
    my = (1 - w) * massFlow(C, b, y.p, a.p);
    x.m_flow = mx;
    y.m_flow = my;
    a.m_flow = -mx - my;
    annotation(Icon(coordinateSystem(extent = {{-40, -15}, {40, 25}}), graphics = {
      Rectangle(extent = {{-30, 10}, {30, -10}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-40, 0}, {-30, 0}}), Line(points = {{30, 0}, {40, 0}}), Line(points = {{0, 10}, {0, 25}}),
      Rectangle(extent = {{-12, 6}, {12, -6}}, lineColor = {0, 0, 0}),
      Line(points = {{-12, 0}, {-22, 0}}), Line(points = {{12, 0}, {22, 0}}),
      Line(points = {{-22, 6}, {-22, -6}}), Line(points = {{22, 6}, {22, -6}}),
      Text(extent = {{-40, 25}, {-4, 13}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}));
  end TwoPressureValve;

  model ShuttleValve "Shuttle valve (OR): the output follows the higher of the two inputs"
    parameter Real qn(unit = "l/min") = 100 "(ESTIMATED)";
    parameter Real b = 0.3 "(ESTIMATED)";
    parameter Real dp_w(unit = "Pa") = 5e3 "(ESTIMATED)";
    final parameter Real C = conductance(qn, b);
    Interfaces.Port x "1: input" annotation(Placement(transformation(extent = {{-44, -4}, {-36, 4}})));
    Interfaces.Port y "1: input" annotation(Placement(transformation(extent = {{36, -4}, {44, 4}})));
    Interfaces.Port a "2: output" annotation(Placement(transformation(extent = {{-4, 21}, {4, 29}})));
    Real w "1: x is the higher input and feeds the output";
    Real mx(unit = "kg/s"), my(unit = "kg/s");
  equation
    w = step(x.p - y.p, dp_w);
    mx = w * massFlow(C, b, x.p, a.p);
    my = (1 - w) * massFlow(C, b, y.p, a.p);
    x.m_flow = mx;
    y.m_flow = my;
    a.m_flow = -mx - my;
    annotation(Icon(coordinateSystem(extent = {{-40, -15}, {40, 25}}), graphics = {
      Rectangle(extent = {{-30, 10}, {30, -10}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-40, 0}, {-30, 0}}), Line(points = {{30, 0}, {40, 0}}), Line(points = {{0, 10}, {0, 25}}),
      Ellipse(extent = {{-6, 6}, {6, -6}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-22, 8}, {-16, 0}, {-22, -8}}), Line(points = {{22, 8}, {16, 0}, {22, -8}}),
      Text(extent = {{-40, 25}, {-4, 13}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}));
  end ShuttleValve;

  model OneWayFlowControl "One-way flow control valve: free flow pa -> pb through the check valve, throttled pb -> pa"
    parameter Real opening(min = 0, max = 1) = 0.3 "throttle setting as a fraction of its largest nominal flow";
    parameter Boolean reversed = false "free flow pb -> pa instead";
    parameter Real qn_throttle_max(unit = "l/min") = 85 "throttled direction, fully open (VERIFIED: Festo Didactic 193967, 0-85 l/min)";
    parameter Real qn_free_min(unit = "l/min") = 100 "free direction, throttle closed (VERIFIED: 193967, 100-110 l/min)";
    parameter Real qn_free_max(unit = "l/min") = 110 "free direction, throttle open (VERIFIED: 193967)";
    parameter Real p_crack(unit = "Pa") = 0.1e5 "check valve cracking pressure (ESTIMATED)";
    parameter Real dp_w(unit = "Pa") = 5e3 "check valve opening range (ESTIMATED)";
    parameter Real b = 0.3 "(ESTIMATED)";
    final parameter Real C_thr = conductance(opening * qn_throttle_max, b);
    final parameter Real C_free = conductance(qn_free_min + opening * (qn_free_max - qn_free_min), b);
    Interfaces.Port pa "valve side" annotation(Placement(transformation(extent = {{-4, -49}, {4, -41}})));
    Interfaces.Port pb "cylinder side" annotation(Placement(transformation(extent = {{-4, 41}, {4, 49}})));
    Real w "1: check valve open (free direction)";
    Real m_ab(unit = "kg/s") "pa -> pb";
  equation
    w = step((if reversed then pb.p - pa.p else pa.p - pb.p) - p_crack, dp_w);
    m_ab = w * massFlow(C_free, b, pa.p, pb.p) + (1 - w) * massFlow(C_thr, b, pa.p, pb.p);
    pa.m_flow = m_ab;
    pb.m_flow = -m_ab;
    annotation(Icon(coordinateSystem(extent = {{-25, -45}, {25, 45}}), graphics = {
      Rectangle(extent = {{-20, 30}, {20, -30}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{0, -45}, {0, 45}}),
      Line(points = {{6, 12}, {2, 0}, {6, -12}}, smooth = Smooth.Bezier), Line(points = {{14, 12}, {10, 0}, {14, -12}}, smooth = Smooth.Bezier),
      Line(points = {{0, 18}, {8, 18}, {8, -18}, {0, -18}}),
      Line(points = {{0, -12}, {16, 12}}, arrow = {Arrow.None, Arrow.Filled}, arrowSize = 4),
      Line(points = {{0, 18}, {-12, 18}, {-12, -18}, {0, -18}}),
      Ellipse(extent = {{-16, 4}, {-8, -4}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-17, -8}, {-12, -3}, {-7, -8}}),
      Text(extent = {{22, 10}, {70, -2}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}),
      Documentation(info = "<html><p>Modelled from its datasheet as a direction-dependent conductance: free direction
qn = 100 + 10 opening l/min, throttled direction qn = 85 opening l/min; the check valve's state
blends the two over a few kPa above its cracking pressure.</p></html>"));
  end OneWayFlowControl;

  model QuickExhaust "Quick-exhaust valve: 1 -> 2 while 1 is higher; 2 -> 3 (atmosphere) when 1 drops"
    parameter Real qn12(unit = "l/min") = 300 "1 -> 2 (UNVERIFIED: Festo Didactic quick-exhaust valve page, 300 l/min)";
    parameter Real qn23(unit = "l/min") = 390 "2 -> 3 (UNVERIFIED: same page, 390 l/min)";
    parameter Real b = 0.3 "(ESTIMATED)";
    parameter Real dp_open(unit = "Pa") = 0.1e5 "excess of 2 over 1 that lifts the disc off the exhaust seat (ESTIMATED)";
    parameter Real dp_w(unit = "Pa") = 2e3 "seat transition range (ESTIMATED)";
    final parameter Real C12 = conductance(qn12, b);
    final parameter Real C23 = conductance(qn23, b);
    Interfaces.Port p1 "1: from the valve" annotation(Placement(transformation(extent = {{-44, -4}, {-36, 4}})));
    Interfaces.Port p2 "2: to the cylinder" annotation(Placement(transformation(extent = {{-4, 26}, {4, 34}})));
    Real w12 "1: the lip seal passes 1 -> 2 (port 1 higher); it never passes 2 -> 1";
    Real w23 "1: the disc has lifted off the exhaust seat (port 2 higher by dp_open)";
    Real m12(unit = "kg/s"), m23(unit = "kg/s");
  equation
    w12 = step(p1.p - p2.p, dp_w);
    w23 = step(p2.p - p1.p - dp_open, dp_w);
    m12 = w12 * massFlow(C12, b, p1.p, p2.p);
    m23 = w23 * massFlow(C23, b, p2.p, p_atm);
    p1.m_flow = m12;
    p2.m_flow = -m12 + m23;
    annotation(Icon(coordinateSystem(extent = {{-40, -20}, {40, 30}}), graphics = {
      Rectangle(extent = {{-30, 12}, {30, -12}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{-40, 0}, {-30, 0}}), Line(points = {{-30, 0}, {-10, 0}}), Line(points = {{0, 30}, {0, 12}}), Line(points = {{0, 0}, {0, 12}}),
      Ellipse(extent = {{-14, 5}, {-4, -5}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Line(points = {{2, 0}, {20, 0}}, arrow = {Arrow.None, Arrow.Open}, arrowSize = 4),
      Polygon(points = {{30, 0}, {36, 5}, {36, -5}, {30, 0}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-40, 26}, {-4, 14}}, textString = "%name", horizontalAlignment = TextAlignment.Left)}));
  end QuickExhaust;
end Valves;
