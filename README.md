# CDA Compressor

**Mean-line preliminary design and off-design analysis of axial compressors**: rotor–stator (with or without the last stator), rotor–rotor on one shaft and rotor–rotor on two shafts.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23299569.svg)](https://doi.org/10.5281/zenodo.23299569)

![Configurations](src/cda_configurations.png)

CDA Compressor contains two linked MATLAB apps and a launcher:

| App | What it does |
|---|---|
| **Design app** | Sweeps the flow coefficient, loading coefficient, reaction (and speed ratio) for 1–12 stages or rotors; feasibility limits (solidity, Mach number, de Haller, hub/tip, h/c, exit swirl); four interactive design maps; selection by objective or by clicking a map; row-by-row design (velocity triangles, losses, NACA-65 metal angles, annulus, blade numbers); comparison of designs; export of the design file. |
| **Off-design app** | Reads the design file and computes the complete map (15 speed lines, 50–120 % speed): choke, peak pressure ratio, Howell stall onset, first stability limit, stall and choke margins, usable range, Greitzer B (surge or rotating stall), Koch stage-loading indicator; non-dimensional, relative and corrected maps with fitted boundary lines; validation against measured maps; correlation settings for sensitivity studies; PDF/Excel/PNG reports. |

The method and its validation against NACA measured compressor maps are described in the paper below.

## Install

Choose one of the three ways (files under **Releases** on the right of this page):

1. **Windows program (no MATLAB needed)** – download `CDA_Compressor_Installer_web.exe` and run it. The installer also installs the free MATLAB Runtime R2025b (internet needed the first time). Start *CDA Compressor* from the Start menu.
2. **MATLAB toolbox** – download `CDA_Compressor_v1.0.0.mltbx` and double-click it in MATLAB. Start it from the APPS tab or by typing `CDA_launcher`.
3. **From the source** – download the repository, add the `src` folder to the MATLAB path and run `CDA_launcher`.

**Requirements (2, 3):** MATLAB R2020a or later (developed and tested in R2025b). No toolbox is required; the Optimization Toolbox is used only by the optional "iterative" inlet-velocity setting.

> If the Windows program reports *"Could not find version 25.2 of the MATLAB Runtime"*, add
> `C:\Program Files\MATLAB\MATLAB Runtime\R2025b\runtime\win64` to your **user** Path
> (Start → "Edit environment variables for your account" → Path → New), then sign out and in.

## Quick start

1. Run `CDA_launcher`, choose a configuration and press **Open the design app**.
2. Press **Default inputs**, then **Compute the design space**, pick a point (*Find the best point* or click a map), press **Use this point**.
3. Press **Send to the off-design app**, then **Run** in the off-design app.
4. Or open one of the files in `examples/` directly in the off-design app.

Both apps have an illustrated guide (buttons in the launcher; `src/cda_guide.html`, `src/cda_offdesign_guide.html`).

## Examples

| Folder | Content |
|---|---|
| `examples/` | Design files of the eight two-row designs of the paper (four configurations × maximum efficiency / maximum pressure ratio). |
| `examples/validation/` | The NACA stage (RM E50A09/E50D26) and rotor (RM E57I03) validation cases, levels A and B, with the measured maps. |

## How to cite

If you use CDA Compressor, please cite the software (button **"Cite this repository"** on the right) and the paper.

The software is archived on Zenodo. DOI of version 1.0.0: [10.5281/zenodo.23299570](https://doi.org/10.5281/zenodo.23299570); DOI of all versions (always the latest): [10.5281/zenodo.23299569](https://doi.org/10.5281/zenodo.23299569).

> Hassan AMA, Hemid AAA, Abdelhamid TST, Elshebiny DEN (2026) CDA Compressor: mean-line design and off-design analysis of axial compressors, version 1.0.0 [software]. Zenodo. https://doi.org/10.5281/zenodo.23299570

> Hassan AMA, Hemid AAA, Abdelhamid TST, Elshebiny DEN (2026) Preliminary design and off-design performance of rotor–stator and rotor–rotor axial compressor configurations. *Journal, volume, pages.* https://doi.org/xx.xxxx/xxxxx  *(to be completed after publication)*

## Owners

CDA Compressor is owned jointly by its four authors, who hold its copyright together (table below).
The GitHub repository is administered by **Ahmed Mohamed Ahmed Hassan** ([@AhmedDMoHassan](https://github.com/AhmedDMoHassan)).

Questions, bug reports and feature requests: please open an [issue](https://github.com/AhmedDMoHassan/CDA-Compressor/issues) or e-mail one of the owners.

## Authors

| Owner / author | Contribution | Contact |
|---|---|---|
| Ahmed Mohamed Ahmed Hassan | Off-design method, design and off-design applications, validation and sensitivity study, and app designing  (repository administrator) | ahmedhassan200282@gmail.com |
| Abdalmoez Ahmed Abdullah Hemid | Off-design method, applications, validation and sensitivity study, and contributed to design module and the app | abdalmoez.hemid04@eng-st.cu.edu.eg |
| Thabet Saber Thabet Abdelhamid | Design method, design study and design maps | thabetmaher709@gmail.com |
| Deyaa ElHaq Nabil Elshebiny | Supervision, methodology review | deyaa.nabil@eng.cu.edu.eg |

Department of Aerospace Engineering, Faculty of Engineering, Cairo University, Giza, Egypt.

## License

**PolyForm Noncommercial License 1.0.0** – see [LICENSE](LICENSE).

- ✅ Free for noncommercial use: study, teaching, academic and personal research, universities, research institutes, charities and government bodies.
- ✅ You may modify and share it, but every copy must keep the copyright notice and the authors' names (the *Required Notice* lines in LICENSE).
- ❌ Commercial use (selling it, putting it in a commercial product or service, or using it for paid company work) is **not allowed** without a separate written license from the owners.
- 📧 Commercial licensing: ahmedhassan200282@gmail.com, deyaa.nabil@eng.cu.edu.eg

If you use CDA Compressor in your work, please cite it (see *How to cite*).

The MATLAB Runtime is distributed by MathWorks under its own license.
