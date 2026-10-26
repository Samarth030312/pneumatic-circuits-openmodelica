# Pneumatic circuits in OpenModelica

Pneumatic control circuits of a basic teaching kit, simulated from first principles with free
software: a small Modelica library of valves, tubes and cylinders (ISO 6358 flow, polytropic
volumes, a cylinder with friction), three experiments with 48 runs, and an independent Python
implementation that reproduces every run. Circuits are drawn and run in OMEdit, OpenModelica's
graphical editor, as in a commercial fluid-power simulator.

![two-hand press: circuit and simulated strokes](docs/img/circuit_two_hand_press.png)

| Experiment | Circuit | What it shows |
|---|---|---|
| **E1** two-hand press | two push buttons → two-pressure (AND) valve → pilot 5/2-way valve; one-way flow control (meter-out) and quick-exhaust valve | the AND logic and its limits; stroke times against the throttle; what the quick-exhaust valve gains; gauge pressures |
| **E2** automatic reciprocation | selector switch, roller limit valves, double-pilot 5/2-way valve, two one-way flow controls | cycle time against the throttles; meter-in against meter-out under no load, an opposing load and an overrunning load |
| **E3** pressure-dependent stamping | push button, double-pilot 5/2-way valve, meter-in, pressure sequence valve gated by a roller valve | force control by a pressure setting, and what fails without the gate, with meter-out, or with the button held |

## Results in brief

- **Return speed under meter-out is set by the throttle alone:** v = C ρ0 R T0 / A, the
  conductance of the choked throttle over the piston area. The simulations match it within 1 %
  from 2.5 % to 30 % opening, at any supply from 3 to 6 bar ([E1](docs/EXPERIMENTS.md#e1-two-hand-press)).
- **The quick-exhaust valve** shortens the extension from 0.123 s to 0.094 s (−24 %); the return
  is unchanged.
- **A two-pressure valve is not a safety control:** it has no time window (a button pressed 1.5 s
  late still starts the press), and releasing a button mid-stroke does not stop a 94 ms stroke.
- **Meter-out holds the speed against the load** (−3 % with 60 N against it); meter-in follows
  the load (−42 %) and lets a pulling load run away (+30 %) ([E2](docs/EXPERIMENTS.md#e2-automatic-reciprocation)).
- **A pressure sequence valve sets the press force** F = p_set A1 − F_c (within 0.6 N from 2 to
  5 bar), provided the approach is metered in and the valve is enabled only near the work: the
  breakaway pressure peak and meter-out both defeat it ([E3](docs/EXPERIMENTS.md#e3-pressure-dependent-stamping)).

All are simulations; parameters without a datasheet are estimated, and their effect is
quantified ([sensitivity](docs/EXPERIMENTS.md#sensitivity)).

## Run it

Requirements: Docker (OpenModelica runs from its official images; nothing else is installed),
Python 3.10+ with NumPy, SciPy and Matplotlib.

```bash
docker pull openmodelica/openmodelica:v1.27.1-minimal   # compiler and simulator
docker pull openmodelica/openmodelica:v1.27.1-gui       # for OMEdit (optional)

scripts/omedit.sh                     # OMEdit with the library: Experiments > double-click > Simulate
python3 scripts/play.py TwoHandPress opening=0.1   # one run with your settings, plotted (--list shows them)
python3 scripts/run_experiments.py    # all 48 runs, OpenModelica and the Python twin (about 5 min)
python3 scripts/make_figures.py       # figures and circuit diagrams -> docs/img
python3 scripts/sensitivity.py        # parameter sensitivity -> results/tables/sensitivity.csv
python3 -m pytest tests               # tests (CI runs them on every push)
```

On Windows or macOS: install [OpenModelica](https://openmodelica.org/download/) and open
`modelica/PneumaticCircuits/package.mo` in OMEdit.

## Documentation

| | |
|---|---|
| [Software](docs/SOFTWARE.md) | the free and commercial tools compared, and why OpenModelica |
| [Physics](docs/PHYSICS.md) | every equation, and the results they predict in closed form |
| [Components](docs/COMPONENTS.md) | the kit's parts, every parameter with its source and status |
| [Experiments](docs/EXPERIMENTS.md) | hypothesis, procedure, results, verification and sensitivity for each experiment |
| [For ENR312 students](docs/course/README.md) | which run serves which task of the course's pneumatics guideline |

## Repository

```
modelica/PneumaticCircuits/   the Modelica library: components (Valves, Actuators, Sources, ...) and Experiments
python/pneusim/               the Python twin (model.py, circuits.py), scenarios, metrics, diagram drawing, OpenModelica runner
scripts/                      run_experiments, make_figures, sensitivity, om.sh (compiler), omedit.sh (editor)
results/                      data/ (every run, 5 ms), tables/ (measured quantities, cross-check, sensitivity), RUN_INFO.json
docs/                         documentation and figures
tests/                        pytest suite
```

## Related

Other apparatus of the same laboratory, each in its own repository:
[DC servo control (Rhino RMCS-2303)](https://github.com/Samarth030312/rhino-rmcs-2303-dc-servo-control),
[temperature control (Arduino)](https://github.com/Samarth030312/arduino-temperature-control-lab),
[water-level control (Arduino)](https://github.com/Samarth030312/arduino-water-level-control-lab).

## Licence

MIT ([LICENSE](LICENSE)). Third-party software and cited sources: [THIRD_PARTY.md](THIRD_PARTY.md).
