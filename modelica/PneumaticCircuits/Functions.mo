within PneumaticCircuits;
package Functions "ISO 6358 flow, conductance from a nominal flow rate, smooth switching"

  function phi "ISO 6358 flow function of the pressure ratio r = p_down/p_up"
    input Real r "pressure ratio, 0..1";
    input Real b "critical pressure ratio";
    output Real y "1 when choked, falls to 0 at r = 1";
  protected
    constant Real r_lam = 0.999 "above this ratio the flow is taken as laminar: linear in (1 - r)";
  algorithm
    if r <= b then
      y := 1;
    elseif r <= r_lam then
      y := sqrt(1 - ((r - b) / (1 - b)) ^ 2);
    else
      y := sqrt(1 - ((r_lam - b) / (1 - b)) ^ 2) * (1 - r) / (1 - r_lam);
    end if;
    annotation(Documentation(info = "<html><p>ISO 6358-1: q = C p1 phi(p2/p1) with phi = 1 below the critical
ratio b (choked) and phi = sqrt(1 - ((r - b)/(1 - b))^2) above it. The square root has an infinite
slope at r = 1; above r = 0.999 it is replaced by its secant to zero (laminar flow), which keeps
the Jacobian finite and changes the flow by less than 0.1 % of the choked value.</p></html>"));
  end phi;

  function massFlow "Mass flow from a to b through an ISO 6358 restriction (negative when b > a)"
    input Real C(unit = "m3/(s.Pa)") "sonic conductance";
    input Real b "critical pressure ratio";
    input Real pa(unit = "Pa");
    input Real pb(unit = "Pa");
    output Real m_flow(unit = "kg/s");
  algorithm
    if pa >= pb then
      m_flow := C * rho0 * pa * phi(pb / pa, b);
    else
      m_flow := -C * rho0 * pb * phi(pa / pb, b);
    end if;
  end massFlow;

  function conductance "Sonic conductance C from a standard nominal flow rate qn (6 bar -> 5 bar gauge)"
    input Real qn(unit = "l/min") "standard nominal flow rate at 600 kPa inlet, 100 kPa drop (ANR)";
    input Real b "critical pressure ratio";
    output Real C(unit = "m3/(s.Pa)");
  protected
    Real p1 = 6e5 + p_atm;
    Real p2 = 5e5 + p_atm;
  algorithm
    C := qn / 60000 / (p1 * phi(p2 / p1, b));
  end conductance;

  function step "Smooth step: 0 for x << -w, 1 for x >> w"
    input Real x;
    input Real w;
    output Real y;
  algorithm
    y := 0.5 + 0.5 * tanh(x / w);
  end step;
end Functions;
