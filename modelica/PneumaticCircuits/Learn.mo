within PneumaticCircuits;
package Learn "Start here: lessons from one cylinder to two-hand control, exercises to build yourself, a sandbox"

  package Lessons "Ready-to-run circuits, one idea each. Open, Simulate, then watch them in the Diagram Window"

    model L01_DirectSingleActing "L01 Direct control: a push button extends a single-acting cylinder"
      Actuators.SingleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sensors.PressureGauge g1(tag = "1Z1") annotation(Placement(transformation(extent = {{-100, 20}, {-60, 60}})));
      Sources.Tube t1(L = 0.5) annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-88, -45}, {12, 5}})));
      Signals.Schedule hand(t_on = {1}, t_off = {3}) "the operator's hand" annotation(Placement(transformation(extent = {{-125, -35}, {-95, -5}})));
      Sources.Tube tS(L = 0.5) annotation(Placement(transformation(extent = {{-40, -80}, {-20, -60}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-70, -160}, {10, -80}})));
    equation
      connect(hand.y, s1.pressed) annotation(Line(points = {{-95, -20}, {-88, -20}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-30, -80}, {-30, -70}}));
      connect(s1.p1, tS.port) annotation(Line(points = {{-30, -35}, {-30, -70}}));
      connect(s1.p2, t1.port) annotation(Line(points = {{-30, -5}, {-30, 40}}));
      connect(t1.port, cyl.A) annotation(Line(points = {{-30, 40}, {-30, 70}}));
      connect(g1.port, t1.port) annotation(Line(points = {{-60, 40}, {-30, 40}}));
      annotation(Diagram(coordinateSystem(extent = {{-150, -170}, {160, 150}})),
        experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>The simplest pneumatic circuit: a 3/2-way push-button valve (1S1) feeds a single-acting
cylinder (1A). Pressed, the valve connects supply port 1 to output 2: air flows in, the piston
extends against its spring. Released, the valve's spring returns it: output 2 connects to exhaust
3, the air leaves, the cylinder's spring pushes the piston back.</p>
<h3>Read the symbol</h3>
<ul><li>Each square is one position of the valve; the square next to the spring is the rest position.</li>
<li>Arrows are flow paths, a T is a blocked port, a triangle is an exhaust to atmosphere.</li>
<li>Ports: 1 supply, 2 (and 4) outputs, 3 (and 5) exhausts, 12/14 pilot signals.
\"3/2\" means 3 ports, 2 positions; \"normally closed\": at rest, 1 is blocked.</li></ul>
<h3>Run it</h3>
<p>Simulation &gt; Simulate. In the Plotting perspective click <b>Diagram Window</b> (toolbar), then
Play (top right). The pressed button turns red, its active position turns blue, the cylinder's
chamber fills blue, the gauge needle rises, the piston moves.</p>
<h3>Watch for</h3>
<ul><li>The gauge 1Z1 rises in two steps: first the tube fills (fast), then the piston moves and the pressure
stays where force balances the spring, then it climbs to the supply pressure at the end stop.</li>
<li>Returning, only the spring pushes: it is slower than extending.</li></ul>
<h3>Try this</h3>
<ul><li>Set <code>sup.p_gauge</code> to 1e5 (1 bar): does the piston still reach the end? Compare (p - 1 atm) A with the spring force.</li>
<li>Set <code>cyl.k_spring</code> to 3000: the return gets faster; the end force drops.</li>
<li>Release earlier: <code>hand.t_off = {1.05}</code>. The piston stops part-way and comes back.</li></ul>
</html>"));
    end L01_DirectSingleActing;

    model L02_DirectDoubleActing "L02 Direct control: a 5/2 selector valve drives a double-acting cylinder both ways"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sensors.PressureGauge g1(tag = "1Z1") annotation(Placement(transformation(extent = {{-100, 20}, {-60, 60}})));
      Sensors.PressureGauge g2(tag = "1Z2") annotation(Placement(transformation(extent = {{130, 20}, {90, 60}})));
      Sources.Tube tA(L = 0.5) annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Sources.Tube tB(L = 0.5) annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
      Valves.SelectorValve52 v1(tag = "1S1") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Signals.Schedule hand(t_on = {1}, t_off = {3}) "the operator sets, then resets the switch" annotation(Placement(transformation(extent = {{-140, -35}, {-110, -5}})));
      Sources.Tube tS(L = 0.5) annotation(Placement(transformation(extent = {{-30, -80}, {-10, -60}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -160}, {20, -80}})));
    equation
      connect(hand.y, v1.on) annotation(Line(points = {{-110, -20}, {-100, -20}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-20, -80}, {-20, -70}}));
      connect(v1.p1, tS.port) annotation(Line(points = {{-20, -40}, {-20, -70}}));
      connect(v1.p4, tA.port) annotation(Line(points = {{-30, 0}, {-30, 40}}));
      connect(v1.p2, tB.port) annotation(Line(points = {{-10, 0}, {-10, 20}, {70, 20}, {70, 40}}));
      connect(tA.port, cyl.A) annotation(Line(points = {{-30, 40}, {-30, 70}}));
      connect(tB.port, cyl.B) annotation(Line(points = {{70, 40}, {70, 70}}));
      connect(g1.port, tA.port) annotation(Line(points = {{-60, 40}, {-30, 40}}));
      connect(g2.port, tB.port) annotation(Line(points = {{90, 40}, {70, 40}}));
      annotation(Diagram(coordinateSystem(extent = {{-150, -170}, {160, 150}})),
        experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>A double-acting cylinder needs air on both sides: a 5/2-way valve (5 ports, 2 positions) feeds one
side and exhausts the other. At rest it feeds port 2 (rod side: the cylinder is held retracted)
and exhausts port 4 through 5; set, it feeds 4 (cap side: extend) and exhausts 2 through 3.
The detented selector stays where you put it.</p>
<h3>Watch for</h3>
<ul><li>Both gauges: at rest 1Z2 shows the supply, 1Z1 zero; switched, they swap.</li>
<li>During each stroke the driving side is well below the supply: the air has to flow in, and the
exhausting side has to empty. Force on the piston = p_cap A_cap - p_rod A_rod.</li>
<li>The return is not slower here: air, not a spring, drives it (compare L01).</li></ul>
<h3>Try this</h3>
<ul><li><code>cyl.m = 5</code>: a heavy tool. The piston overshoots into the end stop and the pressures oscillate.</li>
<li><code>v1.qn = 30</code>: a small valve. Both strokes slow down: the valve's conductance limits the flow.</li>
<li>The extend force is larger than the return force at the same pressure: why? (the rod takes area)</li></ul>
</html>"));
    end L02_DirectDoubleActing;

    model L03_IndirectControl "L03 Indirect control: a small signal valve pilots the power valve"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sensors.PressureGauge g1(tag = "1Z1") annotation(Placement(transformation(extent = {{-100, 20}, {-60, 60}})));
      Sensors.PressureGauge g2(tag = "1Z2") annotation(Placement(transformation(extent = {{130, 20}, {90, 60}})));
      Sources.Tube tA(L = 0.5) annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Sources.Tube tB(L = 0.5) annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
      Valves.PilotValve52 v1(tag = "1V1") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP(L = 1.0) annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-200, -105}, {-100, -55}})));
      Signals.Schedule hand(t_on = {1}, t_off = {3}) "the operator's hand" annotation(Placement(transformation(extent = {{-240, -95}, {-210, -65}})));
      Sources.Tube tS(L = 1.0) annotation(Placement(transformation(extent = {{-30, -140}, {-10, -120}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -220}, {20, -140}})));
    equation
      connect(hand.y, s1.pressed) annotation(Line(points = {{-210, -80}, {-200, -80}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-20, -140}, {-20, -130}}));
      connect(v1.p1, tS.port) annotation(Line(points = {{-20, -40}, {-20, -130}}));
      connect(s1.p1, tS.port) annotation(Line(points = {{-142, -95}, {-142, -130}, {-20, -130}}));
      connect(s1.p2, tP.port) annotation(Line(points = {{-142, -65}, {-142, -20}}));
      connect(tP.port, v1.p14) annotation(Line(points = {{-142, -20}, {-100, -20}}));
      connect(v1.p4, tA.port) annotation(Line(points = {{-30, 0}, {-30, 40}}));
      connect(v1.p2, tB.port) annotation(Line(points = {{-10, 0}, {-10, 20}, {70, 20}, {70, 40}}));
      connect(tA.port, cyl.A) annotation(Line(points = {{-30, 40}, {-30, 70}}));
      connect(tB.port, cyl.B) annotation(Line(points = {{70, 40}, {70, 70}}));
      connect(g1.port, tA.port) annotation(Line(points = {{-60, 40}, {-30, 40}}));
      connect(g2.port, tB.port) annotation(Line(points = {{90, 40}, {70, 40}}));
      annotation(Diagram(coordinateSystem(extent = {{-250, -230}, {160, 150}})),
        experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>Large cylinders need large valves, which are hard to push by hand and should sit near the
cylinder. Indirect control separates <b>signal</b> from <b>power</b>: the push button 1S1 only
fills the pilot chamber 14 of the power valve 1V1; air pressure on the pilot moves 1V1's spool.
Releasing the button vents the pilot and 1V1's spring returns it.</p>
<h3>Watch for</h3>
<ul><li>The delay between pressing and moving: the pilot line (1 m of tube) must fill to the switching
pressure (1.5 bar) before 1V1 moves. Plot <code>v1.p_pilot</code>.</li>
<li>Hysteresis: 1V1 switches on at 1.5 bar but back only below 1.0 bar (spool friction).</li></ul>
<h3>Try this</h3>
<ul><li><code>tP.L = 10</code>: a 10 m pilot line. How much later does the cylinder start? Why?</li>
<li><code>v1.p_on = 4e5</code>: a stiff pilot valve. With the supply at 3 bar (<code>sup.p_gauge = 3e5</code>) nothing happens.</li></ul>
</html>"));
    end L03_IndirectControl;

    model L04_OrTwoPlaces "L04 OR: a shuttle valve lets either of two buttons start the cylinder"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sources.Tube tA(L = 0.5) annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Sources.Tube tB(L = 0.5) annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
      Valves.PilotValve52 v1(tag = "1V2") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP(L = 0.5) annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      replaceable Valves.ShuttleValve or1(tag = "1V1") constrainedby Valves.LogicValve annotation(Placement(transformation(extent = {{-182, -65}, {-102, -25}})));
      Sources.Tube t1(L = 0.5) annotation(Placement(transformation(extent = {{-232, -80}, {-212, -60}})));
      Sources.Tube t2(L = 0.5) annotation(Placement(transformation(extent = {{-92, -80}, {-72, -60}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-280, -135}, {-180, -85}})));
      Valves.PushButtonValve32 s2(tag = "1S2") annotation(Placement(transformation(extent = {{-140, -135}, {-40, -85}})));
      Signals.Schedule hand1(t_on = {1}, t_off = {2}) "operator at station 1" annotation(Placement(transformation(extent = {{-320, -125}, {-290, -95}})));
      Signals.Schedule hand2(t_on = {3}, t_off = {4}) "operator at station 2" annotation(Placement(transformation(extent = {{-175, -125}, {-145, -95}})));
      Sources.Tube tS(L = 1.5) annotation(Placement(transformation(extent = {{-30, -160}, {-10, -140}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -240}, {20, -160}})));
    equation
      connect(hand1.y, s1.pressed) annotation(Line(points = {{-290, -110}, {-280, -110}}, color = {255, 0, 255}));
      connect(hand2.y, s2.pressed) annotation(Line(points = {{-145, -110}, {-140, -110}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-20, -160}, {-20, -150}}));
      connect(v1.p1, tS.port) annotation(Line(points = {{-20, -40}, {-20, -150}}));
      connect(s1.p1, tS.port) annotation(Line(points = {{-222, -125}, {-222, -150}, {-20, -150}}));
      connect(s2.p1, tS.port) annotation(Line(points = {{-82, -125}, {-82, -150}, {-20, -150}}));
      connect(s1.p2, t1.port) annotation(Line(points = {{-222, -95}, {-222, -70}}));
      connect(s2.p2, t2.port) annotation(Line(points = {{-82, -95}, {-82, -70}}));
      connect(t1.port, or1.x) annotation(Line(points = {{-222, -70}, {-222, -50}, {-182, -50}}));
      connect(t2.port, or1.y) annotation(Line(points = {{-82, -70}, {-82, -50}, {-102, -50}}));
      connect(or1.a, tP.port) annotation(Line(points = {{-142, -25}, {-142, -20}}));
      connect(tP.port, v1.p14) annotation(Line(points = {{-142, -20}, {-100, -20}}));
      connect(v1.p4, tA.port) annotation(Line(points = {{-30, 0}, {-30, 40}}));
      connect(v1.p2, tB.port) annotation(Line(points = {{-10, 0}, {-10, 20}, {70, 20}, {70, 40}}));
      connect(tA.port, cyl.A) annotation(Line(points = {{-30, 40}, {-30, 70}}));
      connect(tB.port, cyl.B) annotation(Line(points = {{70, 40}, {70, 70}}));
      annotation(Diagram(coordinateSystem(extent = {{-330, -250}, {160, 150}})),
        experiment(StartTime = 0, StopTime = 6, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>A shuttle valve (OR) passes whichever input is pressurised; its ball blocks the other input so
the air cannot escape through the released button. Station 1 is pressed from 1 s to 2 s, station 2
from 3 s to 4 s: the cylinder extends both times.</p>
<h3>Why not a plain T-junction?</h3>
<p>Join the two button outputs directly instead: when one button is pressed, its air flows into the
other button's output and out through that button's exhaust 3. Try it: delete <code>or1</code>,
<code>t1</code> and <code>t2</code>, connect both buttons' port 2 to <code>tP</code>, and watch the
pilot pressure stay low.</p>
<h3>Try this</h3>
<ul><li>Overlap the presses: <code>hand2.t_on = {1.5}</code>. Nothing new happens: OR is already true.</li>
<li>Replace <code>or1</code> by a <code>TwoPressureValve</code> (AND): now the cylinder never moves with these schedules (L05).</li></ul>
</html>"));
    end L04_OrTwoPlaces;

    model L05_AndTwoHands "L05 AND: a two-pressure valve needs both buttons (the core of a two-hand control)"
      extends L04_OrTwoPlaces(redeclare Valves.TwoPressureValve or1(tag = "1V1"), hand1(t_on = {1}, t_off = {3}), hand2(t_on = {1.5}, t_off = {4}));
      annotation(experiment(StartTime = 0, StopTime = 6, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>The two-pressure valve (AND) passes air only when both inputs are pressurised (it passes the
lower of the two). Button 1 is held from 1 s to 3 s, button 2 from 1.5 s to 4 s: the cylinder
extends at about 1.5 s and returns at 3 s, as soon as either hand lets go.</p>
<h3>Watch for</h3>
<ul><li>From 1 s to 1.5 s, one button alone: the AND body stays white, the pilot stays empty.</li>
<li>A plain AND has <b>no time window</b>: button 2 pressed half a second later still starts the
press. A safety-rated two-hand control also requires both within 0.5 s. See the experiment
<code>Experiments.TwoHandPress</code> for the full circuit with speed control.</li></ul>
<h3>Try this</h3>
<ul><li><code>hand2.t_on = {3.5}</code>: the hands never overlap: no motion.</li></ul>
</html>"));
    end L05_AndTwoHands;

    model L06_SpeedControl "L06 Speed: one-way flow control valves throttle the exhaust air (meter-out)"
      parameter Real openingA = 0.2 "1V2: throttles the cap side's air";
      parameter Real openingB = 0.2 "1V3: throttles the rod side's air";
      parameter Boolean meterIn = false "throttle the air going in instead";
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 160}, {140, 220}})));
      Sensors.PressureGauge g1(tag = "1Z1") annotation(Placement(transformation(extent = {{-100, 110}, {-60, 150}})));
      Sensors.PressureGauge g2(tag = "1Z2") annotation(Placement(transformation(extent = {{130, 110}, {90, 150}})));
      Sources.Tube tA(L = 0.3) annotation(Placement(transformation(extent = {{-40, 120}, {-20, 140}})));
      Sources.Tube tB(L = 0.3) annotation(Placement(transformation(extent = {{60, 120}, {80, 140}})));
      Valves.OneWayFlowControl fcA(opening = openingA, reversed = meterIn, tag = "1V2") annotation(Placement(transformation(extent = {{-55, 25}, {-5, 115}})));
      Valves.OneWayFlowControl fcB(opening = openingB, reversed = meterIn, tag = "1V3") annotation(Placement(transformation(extent = {{45, 25}, {95, 115}})));
      Sources.Tube tE(L = 0.3) annotation(Placement(transformation(extent = {{-40, 0}, {-20, 20}})));
      Sources.Tube tR(L = 0.3) annotation(Placement(transformation(extent = {{-20, 0}, {0, 20}})));
      Valves.PilotValve52 v1(tag = "1V1") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP(L = 1.0) annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-200, -105}, {-100, -55}})));
      Signals.Schedule hand(t_on = {1}, t_off = {3}) "the operator's hand" annotation(Placement(transformation(extent = {{-240, -95}, {-210, -65}})));
      Sources.Tube tS(L = 1.0) annotation(Placement(transformation(extent = {{-30, -140}, {-10, -120}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -220}, {20, -140}})));
    equation
      connect(hand.y, s1.pressed) annotation(Line(points = {{-210, -80}, {-200, -80}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-20, -140}, {-20, -130}}));
      connect(v1.p1, tS.port) annotation(Line(points = {{-20, -40}, {-20, -130}}));
      connect(s1.p1, tS.port) annotation(Line(points = {{-142, -95}, {-142, -130}, {-20, -130}}));
      connect(s1.p2, tP.port) annotation(Line(points = {{-142, -65}, {-142, -20}}));
      connect(tP.port, v1.p14) annotation(Line(points = {{-142, -20}, {-100, -20}}));
      connect(v1.p4, tE.port) annotation(Line(points = {{-30, 0}, {-30, 10}}));
      connect(tE.port, fcA.pa) annotation(Line(points = {{-30, 10}, {-30, 25}}));
      connect(v1.p2, tR.port) annotation(Line(points = {{-10, 0}, {-10, 10}}));
      connect(tR.port, fcB.pa) annotation(Line(points = {{-10, 10}, {70, 10}, {70, 25}}));
      connect(fcA.pb, tA.port) annotation(Line(points = {{-30, 115}, {-30, 130}}));
      connect(fcB.pb, tB.port) annotation(Line(points = {{70, 115}, {70, 130}}));
      connect(tA.port, cyl.A) annotation(Line(points = {{-30, 130}, {-30, 160}}));
      connect(tB.port, cyl.B) annotation(Line(points = {{70, 130}, {70, 160}}));
      connect(g1.port, tA.port) annotation(Line(points = {{-60, 130}, {-30, 130}}));
      connect(g2.port, tB.port) annotation(Line(points = {{90, 130}, {70, 130}}));
      annotation(Diagram(coordinateSystem(extent = {{-250, -230}, {160, 240}})),
        experiment(StartTime = 0, StopTime = 6, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>A one-way flow control valve is a throttle with a check valve in parallel: air passes freely
one way (the check valve opens, its ball turns blue) and is throttled the other way. Fitted as
here, the air flows freely <i>into</i> the cylinder and is throttled <i>out</i> of it:
<b>meter-out</b>. The piston can only move as fast as the trapped air escapes.</p>
<h3>The physics in one line</h3>
<p>When the throttle chokes (the trapped side above about 3.4 bar absolute), its mass flow is
C rho0 p and the piston speed is v = C rho0 R T0 / A: set by the throttle's conductance and the
piston area, independent of the pressure and, within limits, of the load.</p>
<h3>Watch for</h3>
<ul><li>The exhausting side's gauge stays high during the stroke (the air cushion that holds the piston).</li>
<li>The constant speed: a straight line in the cylinder's position.</li></ul>
<h3>Try this</h3>
<ul><li><code>openingA = 0.05</code>: the return takes four times longer. Halve the opening, double the time.</li>
<li><code>meterIn = true</code>: the same settings now throttle the air going in. Faster and jumpier, and the
speed changes with the load: add <code>cyl.F_load = 60</code> and compare. Industry uses meter-out for that reason.</li></ul>
</html>"));
    end L06_SpeedControl;

    model L07_QuickExhaust "L07 A quick-exhaust valve lets the rod side's air out at the cylinder"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 160}, {140, 220}})));
      Sensors.PressureGauge g1(tag = "1Z1") annotation(Placement(transformation(extent = {{-100, 110}, {-60, 150}})));
      Sensors.PressureGauge g2(tag = "1Z2") annotation(Placement(transformation(extent = {{130, 110}, {90, 150}})));
      Sources.Tube tA(L = 0.5) annotation(Placement(transformation(extent = {{-40, 120}, {-20, 140}})));
      Sources.Tube tB(L = 0.3) annotation(Placement(transformation(extent = {{60, 120}, {80, 140}})));
      Valves.QuickExhaust qe(tag = "1V2") annotation(Placement(transformation(extent = {{30, 50}, {110, 100}})));
      Sources.Tube tR(L = 0.2) annotation(Placement(transformation(extent = {{-20, 0}, {0, 20}})));
      Valves.PilotValve52 v1(tag = "1V1") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP(L = 1.0) annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-200, -105}, {-100, -55}})));
      Signals.Schedule hand(t_on = {1}, t_off = {3}) "the operator's hand" annotation(Placement(transformation(extent = {{-240, -95}, {-210, -65}})));
      Sources.Tube tS(L = 1.0) annotation(Placement(transformation(extent = {{-30, -140}, {-10, -120}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -220}, {20, -140}})));
    equation
      connect(hand.y, s1.pressed) annotation(Line(points = {{-210, -80}, {-200, -80}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-20, -140}, {-20, -130}}));
      connect(v1.p1, tS.port) annotation(Line(points = {{-20, -40}, {-20, -130}}));
      connect(s1.p1, tS.port) annotation(Line(points = {{-142, -95}, {-142, -130}, {-20, -130}}));
      connect(s1.p2, tP.port) annotation(Line(points = {{-142, -65}, {-142, -20}}));
      connect(tP.port, v1.p14) annotation(Line(points = {{-142, -20}, {-100, -20}}));
      connect(v1.p4, tA.port) annotation(Line(points = {{-30, 0}, {-30, 130}}));
      connect(v1.p2, tR.port) annotation(Line(points = {{-10, 0}, {-10, 10}}));
      connect(tR.port, qe.p1) annotation(Line(points = {{-10, 10}, {10, 10}, {10, 70}, {30, 70}}));
      connect(qe.p2, tB.port) annotation(Line(points = {{70, 100}, {70, 130}}));
      connect(tA.port, cyl.A) annotation(Line(points = {{-30, 130}, {-30, 160}}));
      connect(tB.port, cyl.B) annotation(Line(points = {{70, 130}, {70, 160}}));
      connect(g1.port, tA.port) annotation(Line(points = {{-60, 130}, {-30, 130}}));
      connect(g2.port, tB.port) annotation(Line(points = {{90, 130}, {70, 130}}));
      annotation(Diagram(coordinateSystem(extent = {{-250, -230}, {160, 240}})),
        experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.001),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>Extending, the rod side's air must leave before the piston can move. Normally it travels back
through the tube and the directional valve's exhaust. A quick-exhaust valve at the cylinder opens
its own exhaust (the triangle turns blue) as soon as the line pressure drops below the cylinder's:
the air leaves where it is, the back-pressure collapses, the piston is faster.</p>
<h3>Try this</h3>
<ul><li>Compare with L03, the same circuit without the quick-exhaust valve (same tube lengths): plot
<code>cyl.x</code> and <code>cyl.pB</code> of both and compare the extension time and the rod-side pressure during the stroke.</li>
<li>Lengthen the rod-side line, <code>tR.L = 5</code>: the quick exhaust matters more the longer the line.</li></ul>
</html>"));
    end L07_QuickExhaust;

    model L08_MemoryValve "L08 Memory: a double-pilot valve remembers the last signal"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sources.Tube tA(L = 0.5) annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Sources.Tube tB(L = 0.5) annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
      Valves.DoublePilotValve52 v1(tag = "1V1") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP14(L = 1.0) annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      Sources.Tube tP12(L = 1.0) annotation(Placement(transformation(extent = {{108, -30}, {128, -10}})));
      Valves.PushButtonValve32 s1(tag = "1S1") "start" annotation(Placement(transformation(extent = {{-200, -105}, {-100, -55}})));
      Valves.PushButtonValve32 s2(tag = "1S2") "return" annotation(Placement(transformation(extent = {{60, -105}, {160, -55}})));
      Signals.Schedule handStart(t_on = {1, 5}, t_off = {1.2, 7}) "start: a tap, then held" annotation(Placement(transformation(extent = {{-240, -95}, {-210, -65}})));
      Signals.Schedule handReturn(t_on = {3, 6}, t_off = {3.2, 6.5}) "return: a tap, then while start is held" annotation(Placement(transformation(extent = {{20, -95}, {50, -65}})));
      Sources.Tube tS(L = 1.5) annotation(Placement(transformation(extent = {{-30, -140}, {-10, -120}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -220}, {20, -140}})));
    equation
      connect(handStart.y, s1.pressed) annotation(Line(points = {{-210, -80}, {-200, -80}}, color = {255, 0, 255}));
      connect(handReturn.y, s2.pressed) annotation(Line(points = {{50, -80}, {60, -80}}, color = {255, 0, 255}));
      connect(sup.port, tS.port) annotation(Line(points = {{-20, -140}, {-20, -130}}));
      connect(v1.p1, tS.port) annotation(Line(points = {{-20, -40}, {-20, -130}}));
      connect(s1.p1, tS.port) annotation(Line(points = {{-142, -95}, {-142, -130}, {-20, -130}}));
      connect(s2.p1, tS.port) annotation(Line(points = {{118, -95}, {118, -130}, {-20, -130}}));
      connect(s1.p2, tP14.port) annotation(Line(points = {{-142, -65}, {-142, -20}}));
      connect(tP14.port, v1.p14) annotation(Line(points = {{-142, -20}, {-100, -20}}));
      connect(s2.p2, tP12.port) annotation(Line(points = {{118, -65}, {118, -20}}));
      connect(tP12.port, v1.p12) annotation(Line(points = {{118, -20}, {20, -20}}));
      connect(v1.p4, tA.port) annotation(Line(points = {{-30, 0}, {-30, 40}}));
      connect(v1.p2, tB.port) annotation(Line(points = {{-10, 0}, {-10, 20}, {70, 20}, {70, 40}}));
      connect(tA.port, cyl.A) annotation(Line(points = {{-30, 40}, {-30, 70}}));
      connect(tB.port, cyl.B) annotation(Line(points = {{70, 40}, {70, 70}}));
      annotation(Diagram(coordinateSystem(extent = {{-250, -230}, {170, 150}})),
        experiment(StartTime = 0, StopTime = 8, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html>
<h3>What you learn</h3>
<p>A double-pilot valve has no spring: it stays in the position the last pilot signal put it in.
A tap on start (1 s) extends the cylinder and it <b>stays</b> extended after the button is released;
a tap on return (3 s) brings it back. It is the pneumatic equivalent of a latch.</p>
<h3>Watch for: overlapping signals</h3>
<p>From 5 s start is held; at 6 s return is pressed while start is still held. With both pilots
pressurised the valve cannot change: it stays extended until start is released at 7 s - and then
it still waits, because return was released at 6.5 s. Signal overlap is the classic fault of
memory-valve circuits; the cure is short (pulse) signals or cancelling the opposing one.</p>
<h3>Try this</h3>
<ul><li><code>handReturn.t_off = {3.2, 7.5}</code>: return now outlasts start, and the cylinder returns at 7 s.</li></ul>
</html>"));
    end L08_MemoryValve;
    annotation(Documentation(info = "<html><p>Lessons in order. Each opens with its circuit; Simulate it, then in the
Plotting perspective press <b>Diagram Window</b> and Play to watch it run. Each lesson's
documentation (the <i>i</i> button) says what to watch and what to change.</p>
<ol><li>L01 Direct control of a single-acting cylinder</li><li>L02 Direct control of a double-acting cylinder</li>
<li>L03 Indirect control (signal and power valves)</li><li>L04 OR: a shuttle valve</li><li>L05 AND: a two-pressure valve</li>
<li>L06 Speed control: meter-out and meter-in</li><li>L07 The quick-exhaust valve</li><li>L08 Memory valves and overlapping signals</li>
<li>then the full experiments: Experiments.TwoHandPress, Reciprocating, PressureStamp</li></ol></html>"));
  end Lessons;

  package Exercises "Build it yourself: the parts are placed, the connections are yours"

    model X01_BuildDirectControl "X01 Connect the parts so that the push button extends the cylinder"
      Actuators.SingleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sources.Tube t1 annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-88, -45}, {12, 5}})));
      Signals.Schedule hand(t_on = {1}, t_off = {3}) annotation(Placement(transformation(extent = {{-125, -35}, {-95, -5}})));
      Sources.Tube tS annotation(Placement(transformation(extent = {{-40, -80}, {-20, -60}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-70, -160}, {10, -80}})));
      annotation(Diagram(coordinateSystem(extent = {{-150, -170}, {160, 150}})),
        experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html><p><b>Task.</b> Draw the connections (hover a port until the cursor is a cross, drag to
the other port): the hand to the button's input; the supply to a tube; that tube to the button's
port 1; the button's port 2 to the other tube; that tube to the cylinder. Then Simulate.</p>
<p><b>Rules.</b> Each net needs exactly one Tube: two valve ports never connect directly. Ports: 1 supply,
2 output. If the check fails, read the message: an unconnected input or a net without a tube.</p>
<p><b>Solution.</b> Lessons.L01_DirectSingleActing. Then add a gauge (Sensors.PressureGauge) to the cylinder's tube.</p></html>"));
    end X01_BuildDirectControl;

    model X02_BuildTwoHandControl "X02 Build a two-hand control: the cylinder may move only with both buttons pressed"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sources.Tube tA annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Sources.Tube tB annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
      Valves.PilotValve52 v1(tag = "1V2") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      Valves.TwoPressureValve and1(tag = "1V1") annotation(Placement(transformation(extent = {{-182, -65}, {-102, -25}})));
      Sources.Tube t1 annotation(Placement(transformation(extent = {{-232, -80}, {-212, -60}})));
      Sources.Tube t2 annotation(Placement(transformation(extent = {{-92, -80}, {-72, -60}})));
      Valves.PushButtonValve32 s1(tag = "1S1") annotation(Placement(transformation(extent = {{-280, -135}, {-180, -85}})));
      Valves.PushButtonValve32 s2(tag = "1S2") annotation(Placement(transformation(extent = {{-140, -135}, {-40, -85}})));
      Signals.Schedule hand1(t_on = {1}, t_off = {3}) annotation(Placement(transformation(extent = {{-320, -125}, {-290, -95}})));
      Signals.Schedule hand2(t_on = {1.5}, t_off = {4}) annotation(Placement(transformation(extent = {{-175, -125}, {-145, -95}})));
      Sources.Tube tS annotation(Placement(transformation(extent = {{-30, -160}, {-10, -140}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -240}, {20, -160}})));
      annotation(Diagram(coordinateSystem(extent = {{-330, -250}, {160, 150}})),
        experiment(StartTime = 0, StopTime = 6, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html><p><b>Task.</b> Connect the parts into a two-hand control: both buttons feed the
two-pressure valve, its output pilots 14 of the 5/2 valve, the 5/2 valve drives the cylinder
(4 to the cap side, 2 to the rod side). Then add speed control: drag a Valves.OneWayFlowControl
into the cap-side line (you will need one more Tube) so the return is slow.</p>
<p><b>Check yourself.</b> Simulate: the cylinder must extend at 1.5 s (when the second hand
arrives) and return at 3 s. Change hand2 to {3.5}..{4}: it must not move at all.</p>
<p><b>Solution.</b> Lessons.L05_AndTwoHands, then Experiments.TwoHandPress.</p></html>"));
    end X02_BuildTwoHandControl;

    model X03_BuildReciprocation "X03 Make the cylinder cycle on its own: roller valves at both ends"
      Actuators.DoubleActingCylinder cyl(tag = "1A") annotation(Placement(transformation(extent = {{-60, 70}, {140, 130}})));
      Sources.Tube tA annotation(Placement(transformation(extent = {{-40, 30}, {-20, 50}})));
      Sources.Tube tB annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
      Valves.DoublePilotValve52 v1(tag = "1V1") annotation(Placement(transformation(extent = {{-100, -50}, {20, 10}})));
      Sources.Tube tP14 annotation(Placement(transformation(extent = {{-152, -30}, {-132, -10}})));
      Sources.Tube tP12 annotation(Placement(transformation(extent = {{108, -30}, {128, -10}})));
      Valves.RollerValve32 r0(x_trip = 0.003, whenAbove = false, tag = "1S1") "pressed while retracted" annotation(Placement(transformation(extent = {{-200, -105}, {-100, -55}})));
      Valves.RollerValve32 r1(x_trip = 0.097, whenAbove = true, tag = "1S2") "pressed while extended" annotation(Placement(transformation(extent = {{60, -105}, {160, -55}})));
      Sources.Tube tS annotation(Placement(transformation(extent = {{-30, -140}, {-10, -120}})));
      Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -220}, {20, -140}})));
      annotation(Diagram(coordinateSystem(extent = {{-250, -230}, {170, 150}})),
        experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.002),
        Documentation(info = "<html><p><b>Task.</b> Connect: supply to the 5/2 valve and to both roller valves; roller r0
(pressed while retracted) to pilot 14 (extend); roller r1 (pressed while extended) to pilot 12
(return); the cylinder's position output (the blue triangle at the rod end) to both rollers' inputs.
The cylinder should cycle back and forth forever.</p>
<p><b>Then.</b> Add a start switch: a SelectorValve32 and a TwoPressureValve between r0 and pilot 14, so the
cycle runs only while the switch is set. Add two OneWayFlowControl valves to set the speed.</p>
<p><b>Solution.</b> Experiments.Reciprocating.</p></html>"));
    end X03_BuildReciprocation;
  end Exercises;

  model Sandbox "An empty bench with a supply: drag parts from the library and build anything"
    Sources.PressureSupply sup(tag = "0Z") annotation(Placement(transformation(extent = {{-60, -240}, {20, -160}})));
    Sources.Tube tS(L = 1.0) "the supply manifold: connect valves' port 1 here" annotation(Placement(transformation(extent = {{-30, -160}, {-10, -140}})));
  equation
    connect(sup.port, tS.port) annotation(Line(points = {{-20, -160}, {-20, -150}}));
    annotation(Diagram(coordinateSystem(extent = {{-300, -250}, {300, 250}})),
      experiment(StartTime = 0, StopTime = 5, Tolerance = 1e-6, Interval = 0.002),
      Documentation(info = "<html><p>Duplicate this model (right-click &gt; Duplicate) to keep your work, then drag parts from
<b>Valves</b>, <b>Actuators</b>, <b>Sensors</b> and <b>Signals</b> onto the diagram and connect them.</p>
<ul><li>Every connection point (net) needs exactly <b>one Tube</b>; ports of valves and cylinders never connect directly.</li>
<li>Operate push buttons and selector switches with a <b>Signals.Schedule</b> (press and release times).</li>
<li>Roller valves take the cylinder's position: connect the cylinder's blue output triangle to the roller's input.</li>
<li>Set each part's <code>tag</code> (e.g. 1V1) to label it as in a circuit diagram.</li>
<li>Simulate, then Diagram Window and Play to watch it; plot any variable (pressures in Pa, positions in m).</li></ul></html>"));
  end Sandbox;
  annotation(Documentation(info = "<html><h3>Learn pneumatics by running and building circuits</h3>
<p><b>Lessons</b>: eight ready circuits, from one cylinder to memory valves; <b>Exercises</b>: parts placed,
you connect them; <b>Sandbox</b>: an empty bench. Every circuit animates after a simulation:
Plotting perspective &gt; Diagram Window &gt; Play. Blue = compressed air; a valve's blue square
is its active position; red = a button being pressed.</p></html>"));
end Learn;
