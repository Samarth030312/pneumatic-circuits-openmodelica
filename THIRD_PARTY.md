# Third-party software and sources

Nothing below is redistributed in this repository; it is used from its own distribution.

| What | Version | Licence | Used for |
|---|---|---|---|
| [OpenModelica](https://openmodelica.org) (official container images `openmodelica/openmodelica`) | 1.27.1 | OSMC Public License / GPL-3.0 | compiling and simulating the Modelica models; OMEdit, the graphical editor |
| [NumPy](https://numpy.org) | 1.26.4 | BSD-3-Clause | the Python twin, analysis |
| [SciPy](https://scipy.org) | 1.15.3 | BSD-3-Clause | the Python twin's integrator (LSODA) |
| [Matplotlib](https://matplotlib.org) | 3.10.8 | PSF-based (Matplotlib licence) | figures and circuit drawings |
| [pytest](https://pytest.org) | 8.3.5 (CI) | MIT | tests |

Manufacturer data cited (not included): Festo Didactic datasheets 152888 (double-acting
cylinder) and 193967 (one-way flow control valve), and the Festo Didactic product page of the
quick-exhaust valve. ISO 6358 (flow rate characteristics of pneumatic components) and ISO 8778
(standard reference atmosphere) are cited for the flow law; the standards are not included.

The circuit symbols in the library's icons are drawn here in the style of ISO 1219-1; they are
not copied from any vendor's library.
