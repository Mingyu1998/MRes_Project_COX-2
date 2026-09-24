# 5. Project summary

Notebooks that compare ligands and replicas side by side. These produced the main figures of the project. Like the other notebooks, they are kept with their outputs because the trajectories are not in the repository.

| Notebook | Comparison |
|---|---|
| `Vioxx_AA_npAA.ipynb` | Rofecoxib vs productive (tail-up) and non-productive (head-up) arachidonic acid in the COX site: Tyr385 distance, RMSD/Rg, RMSF |
| `COX_oneligand.ipynb` | APAP, 4-MAA, 4-AA and AM404 in the COX site of one monomer: Tyr385 distance, RMSD/Rg, RMSF |
| `POX_site.ipynb` | APAP, 4-MAA, 4-AA and AM404 at the POX site: distance to the heme, RMSD/Rg, RMSF |
| `1C_2P_site_distances.ipynb` | APAP, 4-AA and AM404 with two copies of the ligand, one in a COX site and one at a POX site: distances to the heme and Tyr385 |

Set `DATA_DIR` in the loading cell to the folder with the stripped trajectories. Figures are written next to the notebook as PNGs.

> **Figure bug in `POX_site.ipynb`:** in the saved ligand–heme distance figure (`dist_POX.png`), the two "AM404" lines are actually 4-AA rep1 data. The code is now fixed; re-run the notebook to regenerate the figure. See each notebook's header for the other corrections.
