within PneumaticCircuits;
package Experiments "The circuits, ready to simulate"

  partial model TwoHandPressBase "Two-hand press: the parts common to both rod-side variants"
    parameter Real p_supply(unit = "Pa") = 6e5 "supply pressure, gauge";
    parameter Real opening = 0.3 "1V3 throttle setting (fraction of its largest nominal flow)";
    parameter Real t_on1[:] = {1} "1S1 pressed at";
    parameter Real t_off1[size(t_on1, 1)] = {4} "1S1 released at";
    parameter Real t_on2[:] = {1} "1S2 pressed at";
    parameter Real t_off2[size(t_on2, 1)] = {4} "1S2 released at";
    Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-20, 140}, {180, 200}})));
    Sensors.PressureGauge g1(tag = "1Z1") "1Z1: cap side" annotation(Placement(transformation(extent = {{-50, 80}, {-10, 120}})));
    Sources.Tube t5(L = 0.3) annotation(Placement(transformation(extent = {{0, 90}, {20, 110}})));
    Valves.OneWayFlowControl v3(opening = opening, tag = "1V3") "1V3" annotation(Placement(transformation(extent = {{-15, -5}, {35, 85}})));
    Sources.Tube t4(L = 0.5) annotation(Placement(transformation(extent = {{0, -35}, {20, -15}})));
    Valves.PilotValve52 v2(tag = "1V2") "1V2" annotation(Placement(transformation(extent = {{-60, -100}, {60, -40}})));
    Sources.Tube t6(L = 0.5) annotation(Placement(transformation(extent = {{20, -35}, {40, -15}})));
    Sources.Tube t3(L = 0.3) annotation(Placement(transformation(extent = {{-100, -80}, {-80, -60}})));
    Valves.TwoPressureValve and1(tag = "1V1") "1V1" annotation(Placement(transformation(extent = {{-160, -135}, {-80, -95}})));
    Sources.Tube t1(L = 0.5) annotation(Placement(transformation(extent = {{-192, -145}, {-172, -125}})));
    Sources.Tube t2(L = 0.5) annotation(Placement(transformation(extent = {{-42, -145}, {-22, -125}})));
    Valves.PushButtonValve32 s1(tag = "1S1") "1S1" annotation(Placement(transformation(extent = {{-240, -195}, {-140, -145}})));
    Valves.PushButtonValve32 s2(tag = "1S2") "1S2" annotation(Placement(transformation(extent = {{-90, -195}, {10, -145}})));
    Signals.Schedule op1(t_on = t_on1, t_off = t_off1) "left hand" annotation(Placement(transformation(extent = {{-285, -185}, {-255, -155}})));
    Signals.Schedule op2(t_on = t_on2, t_off = t_off2) "right hand" annotation(Placement(transformation(extent = {{-130, -185}, {-100, -155}})));
    Sources.Tube tS(L = 1.0) annotation(Placement(transformation(extent = {{10, -215}, {30, -195}})));
    Sources.PressureSupply sup(p_gauge = p_supply, tag = "0Z") "0Z" annotation(Placement(transformation(extent = {{40, -275}, {120, -195}})));
  equation
    connect(op1.y, s1.pressed) annotation(Line(points = {{-255, -170}, {-240, -170}}, color = {255, 0, 255}));
    connect(op2.y, s2.pressed) annotation(Line(points = {{-100, -170}, {-90, -170}}, color = {255, 0, 255}));
    connect(sup.port, tS.port) annotation(Line(points = {{80, -195}, {80, -205}, {20, -205}}));
    connect(s1.p1, tS.port) annotation(Line(points = {{-182, -185}, {-182, -205}, {20, -205}}));
    connect(s2.p1, tS.port) annotation(Line(points = {{-32, -185}, {-32, -205}, {20, -205}}));
    connect(v2.p1, tS.port) annotation(Line(points = {{20, -90}, {20, -205}}));
    connect(s1.p2, t1.port) annotation(Line(points = {{-182, -155}, {-182, -135}}));
    connect(t1.port, and1.x) annotation(Line(points = {{-182, -135}, {-182, -120}, {-160, -120}}));
    connect(s2.p2, t2.port) annotation(Line(points = {{-32, -155}, {-32, -135}}));
    connect(t2.port, and1.y) annotation(Line(points = {{-32, -135}, {-32, -120}, {-80, -120}}));
    connect(and1.a, t3.port) annotation(Line(points = {{-120, -95}, {-120, -70}, {-90, -70}}));
    connect(t3.port, v2.p14) annotation(Line(points = {{-90, -70}, {-60, -70}}));
    connect(v2.p4, t4.port) annotation(Line(points = {{10, -50}, {10, -25}}));
    connect(t4.port, v3.pa) annotation(Line(points = {{10, -25}, {10, -5}}));
    connect(v3.pb, t5.port) annotation(Line(points = {{10, 85}, {10, 100}}));
    connect(t5.port, cyl.A) annotation(Line(points = {{10, 100}, {10, 140}}));
    connect(g1.port, t5.port) annotation(Line(points = {{-10, 100}, {10, 100}}));
    connect(v2.p2, t6.port) annotation(Line(points = {{30, -50}, {30, -25}}));
    annotation(Diagram(coordinateSystem(extent = {{-300, -280}, {200, 220}})),
      experiment(StartTime = 0, StopTime = 8, Tolerance = 1e-6, Interval = 0.002));
  end TwoHandPressBase;

  model TwoHandPress "Two-hand press: AND valve, pilot 5/2 valve, meter-out flow control, quick exhaust on the rod side"
    extends TwoHandPressBase;
    Valves.QuickExhaust v4(tag = "1V4") "1V4" annotation(Placement(transformation(extent = {{70, 20}, {150, 70}})));
    Sources.Tube t7(L = 0.3) annotation(Placement(transformation(extent = {{100, 90}, {120, 110}})));
    Sensors.PressureGauge g2(tag = "1Z2") "1Z2: rod side" annotation(Placement(transformation(extent = {{170, 80}, {130, 120}})));
  equation
    connect(t6.port, v4.p1) annotation(Line(points = {{30, -25}, {50, -25}, {50, 40}, {70, 40}}));
    connect(v4.p2, t7.port) annotation(Line(points = {{110, 70}, {110, 100}}));
    connect(t7.port, cyl.B) annotation(Line(points = {{110, 100}, {110, 140}}));
    connect(g2.port, t7.port) annotation(Line(points = {{130, 100}, {110, 100}}));
    annotation(Diagram(coordinateSystem(extent = {{-300, -280}, {200, 220}})),
      experiment(StartTime = 0, StopTime = 8, Tolerance = 1e-6, Interval = 0.002),
      Documentation(info = "<html><p>Both push buttons 1S1 and 1S2 must be held: the two-pressure valve 1V1 passes the
lower of their pressures to the pilot of 1V2. 1V2 then feeds the cap side through the check valve of
1V3 (free), and the rod side exhausts through the quick-exhaust valve 1V4. Releasing either button
vents the pilot; 1V2's spring returns it, the rod side fills through 1V4 and the cap side exhausts
through 1V3's throttle: a slow return set by the throttle.</p></html>"));
  end TwoHandPress;

  model TwoHandPressNoQuickExhaust "Two-hand press with the rod side piped straight to 1V2 (no quick exhaust)"
    extends TwoHandPressBase(t6(L = 0.8));
    Sensors.PressureGauge g2(tag = "1Z2") "1Z2: rod side" annotation(Placement(transformation(extent = {{170, 80}, {130, 120}})));
  equation
    connect(t6.port, cyl.B) annotation(Line(points = {{30, -25}, {50, -25}, {50, 120}, {110, 120}, {110, 140}}));
    connect(g2.port, t6.port) annotation(Line(points = {{130, 100}, {110, 100}, {110, 120}, {50, 120}, {50, -25}, {30, -25}}));
    annotation(Diagram(coordinateSystem(extent = {{-300, -280}, {200, 220}})),
      experiment(StartTime = 0, StopTime = 8, Tolerance = 1e-6, Interval = 0.002),
      Documentation(info = "<html><p>As TwoHandPress, with the quick-exhaust valve removed: the rod side's tube is the
same total length (0.8 m), and its air now leaves through 1V2's exhaust 3.</p></html>"));
  end TwoHandPressNoQuickExhaust;
  model Reciprocating "Automatic reciprocation: start switch, roller limit valves, double-pilot valve, two flow controls"
    parameter Real p_supply(unit = "Pa") = 6e5 "supply pressure, gauge";
    parameter Real openingA = 0.3 "cap-side flow control setting";
    parameter Real openingB = 0.3 "rod-side flow control setting";
    parameter Boolean meterIn = false "flow controls throttle the air into the cylinder (else out of it)";
    parameter Real t_start = 1 "start switch set at";
    parameter Real t_stop = 6 "start switch reset at (the cylinder finishes its cycle and stops)";
    parameter Real m_load(unit = "kg") = 0.15 "moving mass";
    parameter Real alpha(unit = "deg") = 0 "inclination: 90 = extends straight down";
    parameter Real F_load(unit = "N") = 0 "constant force against extension";
    Actuators.DoubleActingCylinder cyl(tag = "1A", m = m_load, alpha = alpha, F_load = F_load) annotation(Placement(transformation(extent = {{-20, 140}, {180, 200}})));
    Sensors.PressureGauge gA(tag = "1Z1") "1Z1: cap side" annotation(Placement(transformation(extent = {{-50, 80}, {-10, 120}})));
    Sources.Tube tCap(L = 0.3) annotation(Placement(transformation(extent = {{0, 90}, {20, 110}})));
    Valves.OneWayFlowControl fcA(opening = openingA, reversed = meterIn, tag = "1V2") "1V2" annotation(Placement(transformation(extent = {{-15, -5}, {35, 85}})));
    Sources.Tube tE(L = 0.5) annotation(Placement(transformation(extent = {{0, -35}, {20, -15}})));
    Valves.DoublePilotValve52 v1(tag = "1V1") "1V1" annotation(Placement(transformation(extent = {{-60, -100}, {60, -40}})));
    Sources.Tube tR(L = 0.5) annotation(Placement(transformation(extent = {{20, -35}, {40, -15}})));
    Valves.OneWayFlowControl fcB(opening = openingB, reversed = meterIn, tag = "1V3") "1V3" annotation(Placement(transformation(extent = {{85, -5}, {135, 85}})));
    Sources.Tube tRod(L = 0.3) annotation(Placement(transformation(extent = {{100, 90}, {120, 110}})));
    Sensors.PressureGauge gB(tag = "1Z2") "1Z2: rod side" annotation(Placement(transformation(extent = {{170, 80}, {130, 120}})));
    Sources.Tube tP14(L = 0.3) annotation(Placement(transformation(extent = {{-100, -80}, {-80, -60}})));
    Sources.Tube tC(L = 0.8) annotation(Placement(transformation(extent = {{80, -80}, {100, -60}})));
    Valves.TwoPressureValve and1(tag = "1V4") "1V4" annotation(Placement(transformation(extent = {{-160, -135}, {-80, -95}})));
    Sources.Tube t1(L = 0.5) annotation(Placement(transformation(extent = {{-192, -145}, {-172, -125}})));
    Sources.Tube t2(L = 0.5) annotation(Placement(transformation(extent = {{-42, -145}, {-22, -125}})));
    Valves.SelectorValve32 s1(tag = "1S1") "1S1: start" annotation(Placement(transformation(extent = {{-240, -195}, {-140, -145}})));
    Valves.RollerValve32 r0(x_trip = 0.003, whenAbove = false, tag = "1S2") "1S2: retracted" annotation(Placement(transformation(extent = {{-90, -195}, {10, -145}})));
    Valves.RollerValve32 r1(x_trip = cyl.L - 0.003, whenAbove = true, tag = "1S3") "1S3: extended" annotation(Placement(transformation(extent = {{80, -195}, {180, -145}})));
    Signals.Schedule op1(t_on = {t_start}, t_off = {t_stop}) "operator" annotation(Placement(transformation(extent = {{-285, -185}, {-255, -155}})));
    Sources.Tube tS(L = 1.5) annotation(Placement(transformation(extent = {{10, -215}, {30, -195}})));
    Sources.PressureSupply sup(p_gauge = p_supply, tag = "0Z") "0Z" annotation(Placement(transformation(extent = {{-320, -275}, {-240, -195}})));
  equation
    connect(op1.y, s1.on) annotation(Line(points = {{-255, -170}, {-240, -170}}, color = {255, 0, 255}));
    connect(cyl.x_out, r0.x) annotation(Line(points = {{180, 150}, {200, 150}, {200, -225}, {-100, -225}, {-100, -170}, {-90, -170}}, color = {0, 0, 127}));
    connect(cyl.x_out, r1.x) annotation(Line(points = {{180, 150}, {200, 150}, {200, -225}, {70, -225}, {70, -170}, {80, -170}}, color = {0, 0, 127}));
    connect(sup.port, tS.port) annotation(Line(points = {{-280, -195}, {-280, -205}, {20, -205}}));
    connect(s1.p1, tS.port) annotation(Line(points = {{-182, -185}, {-182, -205}, {20, -205}}));
    connect(r0.p1, tS.port) annotation(Line(points = {{-32, -185}, {-32, -205}, {20, -205}}));
    connect(r1.p1, tS.port) annotation(Line(points = {{138, -185}, {138, -205}, {20, -205}}));
    connect(v1.p1, tS.port) annotation(Line(points = {{20, -90}, {20, -205}}));
    connect(s1.p2, t1.port) annotation(Line(points = {{-182, -155}, {-182, -135}}));
    connect(t1.port, and1.x) annotation(Line(points = {{-182, -135}, {-182, -120}, {-160, -120}}));
    connect(r0.p2, t2.port) annotation(Line(points = {{-32, -155}, {-32, -135}}));
    connect(t2.port, and1.y) annotation(Line(points = {{-32, -135}, {-32, -120}, {-80, -120}}));
    connect(and1.a, tP14.port) annotation(Line(points = {{-120, -95}, {-120, -70}, {-90, -70}}));
    connect(tP14.port, v1.p14) annotation(Line(points = {{-90, -70}, {-60, -70}}));
    connect(r1.p2, tC.port) annotation(Line(points = {{138, -155}, {138, -110}, {90, -110}, {90, -70}}));
    connect(tC.port, v1.p12) annotation(Line(points = {{90, -70}, {60, -70}}));
    connect(v1.p4, tE.port) annotation(Line(points = {{10, -50}, {10, -25}}));
    connect(tE.port, fcA.pa) annotation(Line(points = {{10, -25}, {10, -5}}));
    connect(fcA.pb, tCap.port) annotation(Line(points = {{10, 85}, {10, 100}}));
    connect(tCap.port, cyl.A) annotation(Line(points = {{10, 100}, {10, 140}}));
    connect(gA.port, tCap.port) annotation(Line(points = {{-10, 100}, {10, 100}}));
    connect(v1.p2, tR.port) annotation(Line(points = {{30, -50}, {30, -25}}));
    connect(tR.port, fcB.pa) annotation(Line(points = {{30, -25}, {110, -25}, {110, -5}}));
    connect(fcB.pb, tRod.port) annotation(Line(points = {{110, 85}, {110, 100}}));
    connect(tRod.port, cyl.B) annotation(Line(points = {{110, 100}, {110, 140}}));
    connect(gB.port, tRod.port) annotation(Line(points = {{130, 100}, {110, 100}}));
    annotation(Diagram(coordinateSystem(extent = {{-330, -280}, {230, 220}})),
      experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-6, Interval = 0.002),
      Documentation(info = "<html><p>With the start switch 1S1 set and the piston retracted (roller 1S2 pressed), the
two-pressure valve 1V4 pilots 14 of the memory valve 1V1: the cylinder extends. At the end of the
stroke the roller 1S3 pilots 12: it retracts, presses 1S2 again, and the cycle repeats while 1S1
is set. Resetting 1S1 lets the running cycle finish at the retracted end. The two one-way flow
controls throttle the air leaving the cylinder (meter-out) or, reversed, the air entering it
(meter-in).</p></html>"));
  end Reciprocating;

  model PressureStamp "Pressure-dependent return: a pressure sequence valve returns the cylinder at a set force"
    parameter Real p_supply(unit = "Pa") = 6e5 "supply pressure, gauge";
    parameter Real p_set(unit = "Pa") = 4e5 "sequence valve setting, gauge";
    parameter Real openingA = 0.1 "cap-side flow control setting (slow approach)";
    parameter Boolean meterIn = true "the flow control throttles the air into the cap side (else out of it)";
    parameter Real t_press = 1 "start button pressed at";
    parameter Real t_release = 1.05 "start button released at (a tap)";
    parameter Real x_work(unit = "m") = 0.08 "workpiece surface (beyond the stroke: no workpiece)";
    parameter Real k_work(unit = "N/m") = 2e5 "workpiece stiffness";
    parameter Real x_gate(unit = "m") = 0.075 "the roller 1S2 enables the sequence valve beyond this position (-1: always)";
    Actuators.DoubleActingCylinder cyl(tag = "1A", x_work = x_work, k_work = k_work) annotation(Placement(transformation(extent = {{-20, 140}, {180, 200}})));
    Sensors.PressureGauge gA(tag = "1Z1") "1Z1: cap side" annotation(Placement(transformation(extent = {{-50, 80}, {-10, 120}})));
    Sources.Tube tCap(L = 0.3) annotation(Placement(transformation(extent = {{0, 90}, {20, 110}})));
    Valves.OneWayFlowControl fcA(opening = openingA, reversed = meterIn, tag = "1V3") "1V3" annotation(Placement(transformation(extent = {{-15, -5}, {35, 85}})));
    Sources.Tube tE(L = 0.5) annotation(Placement(transformation(extent = {{0, -35}, {20, -15}})));
    Valves.DoublePilotValve52 v1(tag = "1V1") "1V1" annotation(Placement(transformation(extent = {{-60, -100}, {60, -40}})));
    Sources.Tube tRod(L = 0.8) annotation(Placement(transformation(extent = {{100, 90}, {120, 110}})));
    Sensors.PressureGauge gB(tag = "1Z2") "1Z2: rod side" annotation(Placement(transformation(extent = {{170, 80}, {130, 120}})));
    Sources.Tube tSt(L = 0.5) annotation(Placement(transformation(extent = {{-100, -80}, {-80, -60}})));
    Valves.PushButtonValve32 s1(tag = "1S1") "1S1: start" annotation(Placement(transformation(extent = {{-180, -195}, {-80, -145}})));
    Signals.Schedule op1(t_on = {t_press}, t_off = {t_release}) "operator" annotation(Placement(transformation(extent = {{-225, -185}, {-195, -155}})));
    Valves.PressureSequenceValve seq(p_set = p_set, tag = "1V2") "1V2" annotation(Placement(transformation(extent = {{60, -195}, {160, -145}})));
    Sources.Tube tQ(L = 0.5) annotation(Placement(transformation(extent = {{108, -120}, {128, -100}})));
    Valves.RollerValve32 r1(x_trip = x_gate, whenAbove = true, tag = "1S2") "1S2: near the work" annotation(Placement(transformation(extent = {{60, -275}, {160, -225}})));
    Sources.Tube tG(L = 0.3) annotation(Placement(transformation(extent = {{108, -225}, {128, -205}})));
    Sources.Tube tS(L = 1.0) annotation(Placement(transformation(extent = {{10, -215}, {30, -195}})));
    Sources.PressureSupply sup(p_gauge = p_supply, tag = "0Z") "0Z" annotation(Placement(transformation(extent = {{-280, -275}, {-200, -195}})));
  equation
    connect(op1.y, s1.pressed) annotation(Line(points = {{-195, -170}, {-180, -170}}, color = {255, 0, 255}));
    connect(sup.port, tS.port) annotation(Line(points = {{-240, -195}, {-240, -205}, {20, -205}}));
    connect(s1.p1, tS.port) annotation(Line(points = {{-122, -185}, {-122, -205}, {20, -205}}));
    connect(seq.p1, tG.port) annotation(Line(points = {{118, -185}, {118, -215}}));
    connect(r1.p2, tG.port) annotation(Line(points = {{118, -235}, {118, -215}}));
    connect(r1.p1, tS.port) annotation(Line(points = {{118, -265}, {118, -285}, {20, -285}, {20, -205}}));
    connect(cyl.x_out, r1.x) annotation(Line(points = {{180, 150}, {210, 150}, {210, -295}, {50, -295}, {50, -250}, {60, -250}}, color = {0, 0, 127}));
    connect(v1.p1, tS.port) annotation(Line(points = {{20, -90}, {20, -205}}));
    connect(s1.p2, tSt.port) annotation(Line(points = {{-122, -155}, {-122, -70}, {-90, -70}}));
    connect(tSt.port, v1.p14) annotation(Line(points = {{-90, -70}, {-60, -70}}));
    connect(seq.p2, tQ.port) annotation(Line(points = {{118, -155}, {118, -110}}));
    connect(tQ.port, v1.p12) annotation(Line(points = {{118, -110}, {118, -70}, {60, -70}}));
    connect(seq.p12, tCap.port) annotation(Line(points = {{60, -170}, {75, -170}, {75, 120}, {10, 120}, {10, 100}}));
    connect(v1.p4, tE.port) annotation(Line(points = {{10, -50}, {10, -25}}));
    connect(tE.port, fcA.pa) annotation(Line(points = {{10, -25}, {10, -5}}));
    connect(fcA.pb, tCap.port) annotation(Line(points = {{10, 85}, {10, 100}}));
    connect(tCap.port, cyl.A) annotation(Line(points = {{10, 100}, {10, 140}}));
    connect(gA.port, tCap.port) annotation(Line(points = {{-10, 100}, {10, 100}}));
    connect(v1.p2, tRod.port) annotation(Line(points = {{30, -50}, {30, -25}, {110, -25}, {110, 100}}));
    connect(tRod.port, cyl.B) annotation(Line(points = {{110, 100}, {110, 140}}));
    connect(gB.port, tRod.port) annotation(Line(points = {{130, 100}, {110, 100}}));
    annotation(Diagram(coordinateSystem(extent = {{-300, -305}, {230, 220}})),
      experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.001),
      Documentation(info = "<html><p>The start button 1S1 pilots 14 of the memory valve 1V1: the cylinder extends, its
speed set by the one-way flow control 1V3 throttling the air into the cap side (meter-in). The
pressure sequence valve 1V2 senses the cap-side line between 1V3 and the cylinder: during free
motion it holds only what friction needs; it rises when the piston is held - by the workpiece or
the end stop - and at p_set 1V2 pilots 12: the cylinder returns. The roller valve 1S2 supplies 1V2
only once the piston is near the work (x_gate): at the start the cap side must briefly exceed
the rod side's held pressure to break away, a peak that would otherwise trip 1V2 at once. With meterIn = false the throttle holds the air in instead, the cap side stays near the
supply pressure during the whole stroke, and the sequence valve returns the cylinder at once.</p></html>"));
  end PressureStamp;
end Experiments;
