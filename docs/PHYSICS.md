# Physics

The equations every component obeys, as written in `modelica/PneumaticCircuits/` and,
independently, in `python/pneusim/model.py`. Symbols: p absolute pressure, m mass flow, V
volume, x piston position (0 retracted), v its velocity.

## 1. Air

Ideal gas, R = 287.05 J/(kg·K). Flows are referred to the ISO 8778 reference state (ANR):
T0 = 293.15 K, ρ0 = 1.185 kg/m³. The air temperature is taken as T0 everywhere (no heat
balance); compression and expansion in a volume follow a polytropic law with exponent n
(section 3).

## 2. Restrictions: ISO 6358

Every valve path, fitting and throttle is a restriction with a **sonic conductance** C
(m³/(s·Pa)) and a **critical pressure ratio** b:

```
m = C ρ0 p_up φ(r),   r = p_down / p_up

φ(r) = 1                                 r ≤ b       (choked: independent of p_down)
φ(r) = sqrt(1 − ((r − b)/(1 − b))²)      b < r ≤ 0.999
φ(r) = φ(0.999) (1 − r)/(1 − 0.999)      r > 0.999   (laminar: linear to 0 at r = 1)
```

The last line replaces the square root's infinite slope at r = 1 by its secant: the flow there
is below 0.1 % of the choked flow, and the Jacobian stays finite. Reverse flow uses the same
law with the ports exchanged.

**From a datasheet to C.** Manufacturers give a *standard nominal flow rate* qn (l/min, ANR) at
6 bar inlet and 5 bar outlet (gauge). Then

```
C = qn / (60000 · p1 · φ(p2/p1)),   p1 = 7.013 bar, p2 = 6.013 bar (absolute)
```

With b = 0.3, φ(0.857) = 0.605: qn = 100 l/min gives C = 3.93·10⁻⁹ m³/(s·Pa) ≈ 3.9 l/(s·bar).

**An opening fraction** s ∈ [0, 1] (a spool between its positions, a throttle setting) scales
the conductance: C(s) = s·C. A throttle's setting in this repository is the fraction of its
largest nominal flow.

## 3. Volumes

Each connection net of a circuit (the tubes and fittings that join a set of ports) is one
volume V = π D²/4 · L + V_fittings, with D = 2.5 mm (PUN 4 × 0.75 tubing):

```
dp/dt = n R T0 / V · Σ m_in
```

n = 1.2 (between isothermal, 1.0, and adiabatic, 1.4). Every net joins exactly one volume with
restrictions: no two volumes touch directly, and no two restrictions meet without a volume
between them. The tube's own flow resistance is lumped into the restrictions on its ends.

## 4. Valves

**Spool.** A directional valve's spool position s follows its commanded position with a
first-order lag, ds/dt = (s_cmd − s)/τ (τ = 5–8 ms). The paths open in proportion: a 3/2-way
valve passes s·C from 1 to 2 and (1 − s)·C from 2 to its exhaust.

**Pilot.** A pneumatic pilot is a small chamber (V = 0.5 cm³) filled through its own
restriction. The valve switches with **hysteresis**: on when the pilot pressure exceeds
p_on = 1.5 bar, back only when it drops below p_off = 1.0 bar (spring force against spool
friction). A double-pilot (memory) valve switches to a side only when that pilot is above p_on
and the opposite pilot below p_off: with both pilots pressurised it stays where it is.

**Two-pressure valve (AND)** and **shuttle valve (OR)**. The free shuttle connects the output
to the lower (AND) or higher (OR) input:

```
w = ½ + ½ tanh((p_y − p_x)/Δ)            (AND: w → 1 when x is the lower input)
m_x→a = w · m(C, x, a),   m_y→a = (1 − w) · m(C, y, a)
```

Δ = 5 kPa is the pressure difference over which the shuttle travels. With one input vented,
the output is connected to that input and vents too: the other input is blocked.

**One-way flow control valve.** Check valve in parallel with a throttle, modelled from the
datasheet as a direction-dependent conductance: free direction qn = 100 + 10·s l/min (check
open above 0.1 bar), throttled direction qn = 85·s l/min, blended by the check valve's state
w = ½ + ½ tanh((Δp − p_crack)/Δ).

**Quick-exhaust valve.** Two seats: the lip seal passes air from port 1 (the directional valve)
to port 2 (the cylinder) only, w12 = ½ + ½ tanh((p1 − p2)/Δ); the disc opens the exhaust 2 → 3
once port 2 exceeds port 1 by 0.1 bar, w23 = ½ + ½ tanh((p2 − p1 − 0.1 bar)/Δ). At rest
(p1 = p2) the exhaust is sealed; when the directional valve vents port 1, the cylinder's air
leaves at the cylinder through a large conductance instead of passing back through the line and
the directional valve.

**Pressure sequence valve.** A 3/2-way valve switched by the pressure at its control port 12:
on above p_set, off below p_set − 0.2 bar.

## 5. Double-acting cylinder

Two chambers, cap (A, area A1 = πD²/4) and rod (B, A2 = π(D² − d²)/4), each a variable volume
behind its port's restriction:

```
VA = V0A + A1 x                  dpA/dt = n/VA · (R T0 mA − pA A1 v)
VB = V0B + A2 (L − x)            dpB/dt = n/VB · (R T0 mB + pB A2 v)

m dv/dt = pA A1 − pB A2 − p_atm (A1 − A2) − F_f(v) − F_load + F_end + m g sin α
F_f(v)  = (F_c + (F_s − F_c) e^{−(v/v_s)²}) tanh(v/v_ε) + b_v v
```

F_end: the end stops and an optional workpiece, stiff spring-dampers that can only push
(k = 10⁷ N/m, about critically damped at the stops; the workpiece 2·10⁵ N/m). The tanh
regularises the friction's sign change: below v_ε = 1 mm/s the piston creeps instead of
sticking.

## 6. Results this predicts in closed form

**Meter-out speed.** With the exhaust throttle choked (the chamber above p_atm/b ≈ 3.4 bar
absolute) and the pressure steady, the chamber equation gives R T0 m = p A v, and the choked
flow is m = C ρ0 p. The pressure cancels:

```
v = C ρ0 R T0 / A        (ρ0 R T0 = 99.7 kPa)
```

The return speed depends only on the throttle's conductance and the piston area: not on the
supply pressure, the load (while the throttle stays choked) or n. At 30 % (qn = 25.5 l/min):
C = 1.00·10⁻⁹ m³/(s·Pa), v = 0.318 m/s for the cap side of the 20 mm cylinder.

**Meter-in speed.** Throttling the inflow instead: m = C ρ0 p_supply (choked), and the chamber
holds only the pressure the load needs, p_ch. Then v = C ρ0 R T0 p_supply / (p_ch A): faster
than meter-out at the same setting by p_supply/p_ch, and dependent on the load through p_ch.
This is why meter-in gives a speed that varies with the load, and why it cannot hold back a
load that pulls the piston (an overrunning load): nothing resists on the outflow side.

**Forces.** Holding, extended, at supply pressure p_s: F = p_s A1 − F_f. At 6 bar,
6·10⁵ · 3.142·10⁻⁴ = 188.5 N (the datasheet states 189 N). Retracting: p_s A2 = 158.3 N
(datasheet 158 N).
