within;
package PneumaticCircuits "Pneumatic circuits from first principles: ISO 6358 valves, polytropic volumes, cylinders"
  constant Real p_atm(unit = "Pa") = 101325 "Atmospheric pressure";
  constant Real T0(unit = "K") = 293.15 "Air temperature everywhere (isothermal flow); ISO 8778 reference";
  constant Real R_air(unit = "J/(kg.K)") = 287.05 "Gas constant of dry air";
  constant Real rho0(unit = "kg/m3") = 1.185 "Air density at the ISO 8778 reference (ANR); ISO 6358 flows are referred to it";
  constant Real g_n(unit = "m/s2") = 9.80665 "Standard gravity";
  constant Real pi = 3.14159265358979;

  annotation(
    Icon(graphics = {Rectangle(extent = {{-100, -100}, {100, 100}}, lineColor = {0, 0, 0}, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid, radius = 20), Rectangle(extent = {{-60, 20}, {40, -20}}, lineColor = {0, 0, 0}), Line(points = {{-20, 20}, {-20, -20}}, thickness = 1), Line(points = {{-20, 0}, {80, 0}}, thickness = 1)}),
    version = "1.0.0",
    Documentation(info = "<html>
<p>A small, self-contained library (no other library needed) for pneumatic circuits as built on
a teaching kit: supply, tube volumes, push-button, roller and pilot valves, two-pressure (AND)
and shuttle (OR) valves, one-way flow control, quick exhaust, pressure sequence valve,
double-acting cylinder and gauges.</p>
<p>Physics: every connection net is a <b>Tube</b> volume, dp/dt = n R T0 m_flow / V; every valve
path is an ISO 6358 restriction, m_flow = C rho0 p_up phi(p_down/p_up, b); the cylinder's two
chambers are variable volumes, its piston obeys Newton's law with friction and end stops.
Rule: each net joins exactly one Tube with the restrictive ports of valves and cylinders.</p>
<p>Parameters are marked in their descriptions: VERIFIED (a manufacturer's datasheet) or
ESTIMATED. See docs/PHYSICS.md and docs/COMPONENTS.md.</p>
<p><b>Start here:</b> Learn.Lessons (L01 to L08), then Learn.Exercises, then the Experiments.
After a simulation, open the Diagram Window (Plotting perspective) and press Play to watch the circuit run.</p>
<p><small>Festo, Festo Didactic and FluidSIM are trademarks of Festo SE & Co. KG. This project is independent: it is not affiliated with, sponsored or endorsed by Festo. Festo part numbers and datasheets are cited only to identify where a parameter value comes from; no Festo text, drawing, software or datasheet is reproduced. The circuit symbols are drawn here after the ISO 1219-1 conventions. MIT licence.</small></p>
</html>"));
end PneumaticCircuits;
