# Components and parameters

## The kit

The circuits use only parts of a basic pneumatics teaching set of the Festo Didactic TP 101
kind. Its listing ([LabVolt 5407-10](https://labvolt.festo.com/solutions/3_fluid_power/22-5407-10_tp_101_pneumatics_basic_level))
includes three 3/2-way push-button valves (normally closed), 3/2- and 5/2-way selector-switch
valves, two 3/2-way roller lever valves, 3/2- and 5/2-way single-pilot valves, 5/2-way
double-pilot valves, two two-pressure valves (AND), a shuttle valve (OR), a quick-exhaust valve,
two one-way flow control valves, a pressure sequence valve, a time-delay valve, single- and
double-acting cylinders, pressure gauges and a service unit. Counts differ between editions:
check the set at hand.

| Library component | Kit part | Used in |
|---|---|---|
| `Sources.PressureSupply` | compressor and service unit (filter, regulator) | all |
| `Sources.Tube` | PUN 4 × 0.75 tubing and fittings | all |
| `Valves.PushButtonValve32` | 3/2-way push-button valve, normally closed | E1, E3 |
| `Valves.SelectorValve32` | 3/2-way selector-switch valve | E2 |
| `Valves.RollerValve32` | 3/2-way roller lever valve | E2, E3 |
| `Valves.PilotValve52` | 5/2-way valve, pneumatically actuated one side | E1 |
| `Valves.DoublePilotValve52` | 5/2-way double-pilot valve | E2, E3 |
| `Valves.TwoPressureValve` | two-pressure valve (AND) | E1, E2 |
| `Valves.ShuttleValve` | shuttle valve (OR) | (library) |
| `Valves.OneWayFlowControl` | one-way flow control valve | all |
| `Valves.QuickExhaust` | quick-exhaust valve | E1 |
| `Valves.PressureSequenceValve` | pressure sequence valve | E3 |
| `Actuators.DoubleActingCylinder` | double-acting cylinder | all |
| `Sensors.PressureGauge` | pressure gauge | all |

## Parameters

Status: **VERIFIED** from a manufacturer's datasheet; **UNVERIFIED** from a manufacturer's page
that could not be retrieved in full; **ESTIMATED** where no datasheet value was found: a typical
value for parts of this size, to be replaced by a measurement. Results that depend on an
ESTIMATED value are given with its sensitivity in [the results](EXPERIMENTS.md#sensitivity).

| Parameter | Value | Status, source |
|---|---|---|
| cylinder bore / rod / stroke | 20 / 8 / 100 mm | VERIFIED: Festo Didactic 152888 datasheet (German edition; the English one prints 8 mm as the piston diameter, a translation error: thrust 189 N at 6 bar requires 20 mm) |
| cylinder thrust / retraction force at 6 bar | 189 / 158 N | VERIFIED: 152888; equal to 6 bar × A1 / A2 |
| tubing | PUN 4 × 0.75 (bore 2.5 mm) | VERIFIED: 152888 names the fittings QS-G1/8-4 for PUN 4 × 0.75 |
| one-way flow control, throttled direction | 0–85 l/min | VERIFIED: Festo Didactic 193967 datasheet |
| one-way flow control, free direction | 100–110 l/min | VERIFIED: 193967 |
| quick-exhaust valve 1 → 2 / 2 → 3 | 300 / 390 l/min | UNVERIFIED: Festo Didactic product page (search excerpt) |
| 3/2-way valves (push-button, roller, selector, sequence) | 80 l/min | ESTIMATED |
| 5/2-way valves | 110 l/min per path | ESTIMATED |
| two-pressure / shuttle valve | 100 l/min | ESTIMATED |
| cylinder port (fitting and tube resistance) | 150 l/min | ESTIMATED |
| service unit | 750 l/min | ESTIMATED |
| critical pressure ratio b, all | 0.3 | ESTIMATED |
| pilot switching pressure, on / off | 1.5 / 1.0 bar | ESTIMATED |
| spool time constants | 5 ms (3/2), 8 ms (5/2) | ESTIMATED |
| check valve cracking pressure | 0.1 bar | ESTIMATED |
| quick-exhaust valve opening difference | 0.1 bar | ESTIMATED |
| moving mass | 0.15 kg | ESTIMATED (piston, rod, trip cam) |
| friction: Coulomb / breakaway / viscous | 8 N / 12 N / 20 N·s/m | ESTIMATED (about 5 % of the thrust) |
| cylinder dead volumes | 1.5 cm³ each side | ESTIMATED |
| polytropic exponent n | 1.2 | ESTIMATED (1.0 isothermal, 1.4 adiabatic) |
| tube lengths per net | 0.3–1.5 m | ESTIMATED (as set in each circuit) |
| supply pressure | 6 bar (gauge) | setting; 3–6 bar studied |

Conversions from a nominal flow rate to the sonic conductance C: [physics §2](PHYSICS.md#2-restrictions-iso-6358).
