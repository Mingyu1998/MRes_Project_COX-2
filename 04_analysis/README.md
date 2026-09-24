# 4. Analysis

Trajectory data (`.nc`, `.parm7`) are too large for git, so the notebooks can't be re-run from this repository alone. They are kept **with their outputs (plots)** as a record of the results. To reproduce them, put the stripped trajectories next to the notebook, or change the `pt.iterload(...)` paths.

## Preparing trajectories (`trajectory/cpptraj/`)

| File | Purpose |
|---|---|
| `strip_solvent.parmed` | Strip water/ions from the topology: `parmed -p NAME_HMR.parm7 -i strip_solvent.parmed` |
| `strip_traj.cpptraj` | Join the 50 ns segments, re-image, and strip water/ions: `cpptraj -i strip_traj.cpptraj` |
| `strip_traj_hpc.cpptraj` | Same, for segments named `1.nc` … `6.nc` |
| `correlation_matrix.cpptraj` | Residue-level dynamic cross-correlation matrix → `correl_3.out` |
| `correlation_matrix_hpc.pbs` | PBS wrapper that runs the correlation matrix on a cluster node |
| `native_contacts.cpptraj` | Residue contact map against the average structure → `native.dist_all_3.out`, `nonnative.dist_all_3.out` |

Edit the file names and residue ranges (`:1-1108` for the dimer with iron-bound water, `:1-1106` for `COX-2_re`) to match your system.

## Trajectory notebooks (`trajectory/`)

Each notebook covers a single system, using pytraj.

| Notebook | System | Analyses |
|---|---|---|
| `basic_MD_traj_analysis.ipynb` | General template (with explanations) | RMSD, Rg, key distances, open/closed state cut-offs, t-tests |
| `RMSD_Rg_COX-2.ipynb` | Apo COX-2 | RMSD, radius of gyration |
| `empty_rep3.ipynb` | Apo COX-2, replica 3 | RMSD, per-monomer RMSF |
| `One_heme.ipynb` | COX-2 with heme in one monomer only | RMSD, per-monomer RMSF |
| `AA_production.ipynb` | Arachidonic acid, productive pose | RMSD, RMSF, AA–Tyr385 distance |
| `4-AA.ipynb` | 4-aminoantipyrine | RMSD, RMSF, distances |
| `AM404_COX.ipynb` | AM404 in the COX site | RMSD, RMSF, AM404–Tyr385 distance |
| `AM404_1C_2P.ipynb` | AM404, one COX + one POX ligand | RMSD, RMSF, distances |
| `MAA_POX_rep2.ipynb` | MAA at the POX site, replica 2 | RMSD, RMSF, MAA–Fe distance |
| `Corr.ipynb` | Apo COX-2 | Correlation × contact weighted network, inter-monomer residue pairs |

## MM/PBSA (`mmpbsa/`)

| File | Purpose |
|---|---|
| `mmpbsa.in` | MMPBSA.py input (GB igb=2 and PB, 0.15 M salt). Set `ligand_mask`/`receptor_mask` for your system |
| `mmpbsa_array.pbs` | Splits the trajectory into chunks over a PBS array job: `qsub -J 1-200 -v JOB=NAME,CHUNK=30 mmpbsa_array.pbs` |
| `APAP_POX.ipynb`, `MAA_1C_2P_COX.ipynb`, `AA_COX_double_P.ipynb`, `twoheme_rep3.ipynb` | Collect the per-chunk results (`<i>_2/_MMPBSA_info`) with `MMPBSA_mods.API` and plot the ΔG decomposition over time |

The MM/PBSA notebooks `os.chdir` into absolute paths on the original laptop (`/Users/mingyu/MMPBSA/...`). Change these to where your results are.

`MMPBSA_mods` ships with AmberTools. Import it from the same Python environment that `MMPBSA.py` uses.
