# For ENR312 students (Ahmedabad University): the pneumatic control experiment

The experiment's edge-folding device is experiment **E1**, `PneumaticCircuits.Experiments.TwoHandPress`,
built as in the guideline's circuit diagram. This page says where each task can be done in
simulation; it gives no answers to the report questions.

| Guideline task | In this repository |
|---|---|
| 1. Understand the device and the circuit | [circuit diagram](../img/circuit_two_hand_press.png), [how it works](../EXPERIMENTS.md#e1-two-hand-press), [components](../COMPONENTS.md) |
| 2. Assemble the circuit | open `TwoHandPress` in OMEdit ([software](../SOFTWARE.md)); every part and tube is a block you can move, inspect and re-connect |
| 3. Two-hand actuation | runs E1-01 to E1-05: both buttons, each alone, one released mid-stroke, one pressed late |
| 4. Extension and retraction times against 1V3 | runs E1-T: eight throttle settings, stroke times in `results/tables/E1.csv` |
| 5. The valve that combines the two buttons | runs E1-02, E1-03 (one button), the pilot pressure of 1V2 in the E1-01 figure |
| 6. 1V4 | runs E1-N: the same circuit without it |
| 7. Pressures at 1Z1 and 1Z2 | every E1 run records both gauges; extended, returning and at rest in `E1.csv` |
| 8. A delay by closing 1V3 | runs E1-T down to 2.5 % |
| 9. One button alone | runs E1-02, E1-03 |
| 10. Summary | [results](../EXPERIMENTS.md#e1-two-hand-press) |

**Component names.** The guideline's component list names 1V1 to 1V4 generically ("directional,
shuttle, flow control, check"). The circuit diagram shows 1V1 as a two-pressure (AND) valve, 1V2
as a pilot-operated 5/2-way valve with spring return, 1V3 as a one-way flow control valve and 1V4
as a quick-exhaust valve. The simulation follows the diagram.

**Two more experiments** with the same kit, beyond the guideline: E2, automatic reciprocation with
roller limit valves (meter-in against meter-out), and E3, a pressure-dependent return with a
pressure sequence valve.

**On the real kit.** Supply at most 6 bar through the service unit; push tubes fully home and
tug-test them; vent the circuit before changing tubing; keep hands out of the cylinder's path;
wear eye protection while air lines are being connected.
