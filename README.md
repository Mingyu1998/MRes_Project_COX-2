# Molecular dynamics of COX-2 with paracetamol, dipyrone metabolites and arachidonic acid

MRes project. All-atom molecular dynamics (Amber) of the cyclooxygenase-2 (COX-2) homodimer to study how paracetamol, its metabolite AM404, and dipyrone (metamizole) metabolites interact with the enzyme's two active sites. Arachidonic acid (the substrate) and rofecoxib (Vioxx, a selective COX-2 inhibitor) serve as references.

- **COX site** (cyclooxygenase channel, Tyr385): where arachidonic acid and classical NSAIDs/coxibs bind.
- **POX site** (peroxidase, heme): one proposed mechanism is that paracetamol and dipyrone metabolites act here as reducing co-substrates rather than as channel blockers.

For each system, the ligand's stability in the binding site (distance to Tyr385 or to the heme iron), protein RMSD/RMSF/Rg, allosteric communication between monomers (correlation and contact networks), and MM/PBSA binding energies were compared.

## Ligands

| Abbreviation | Ligand | Role |
|---|---|---|
| AA | Arachidonic acid | Substrate. Head-up and tail-up poses in the COX site |
| Vioxx | Rofecoxib | Selective COX-2 inhibitor (reference) |
| APAP | Paracetamol (acetaminophen) | |
| AM404 | *N*-arachidonoylphenolamine | Paracetamol metabolite |
| MAA | 4-methylaminoantipyrine | Active metabolite of dipyrone |
| 4-AA | 4-aminoantipyrine | Metabolite of dipyrone |

System names such as `MAA_POX` and `APAP_COX` give the ligand and the site. `1C_2P` systems have two copies of the ligand, one in a COX site and one at a POX site. `rep2`/`rep3` are independent replicas.

## Repository layout

The folders follow the order of the workflow. Each one has its own README.

```
01_ligand_parameterisation/   Gaussian optimisation + RESP charges + GAFF parameters per ligand
02_system_setup/              tleap scripts: protein + heme (MCPB.py) + ligand, solvation, HMR
   common/                    shared COX-2 model and heme/Fe parameters
   AA_COX/ APAP_COX/ APAP_POX/ MAA_POX/
03_md_protocol/               pmemd input files and run scripts (local GPU and PBS cluster)
04_analysis/
   trajectory/                pytraj notebooks per system + cpptraj/parmed inputs
   mmpbsa/                    MMPBSA.py input, PBS array script, result notebooks
05_project_summary/           cross-system comparison notebooks (main figures)
environment.yml               conda environment for analysis (AmberTools, pytraj, ...)
```

Trajectories and topologies are too large for git and are not included (see `.gitignore`). The notebooks are kept with their outputs so the results can still be viewed.

## Workflow

1. **Structure.** Start from a COX-2 crystal structure (PDB) and prepare the dimer with both hemes.
2. **Metal site.** Parameterise the heme/Fe/His site with MCPB.py (`02_system_setup/common/`).
3. **Ligands.** DFT optimisation and HF/6-31G* ESP in Gaussian, then RESP charges and GAFF parameters with antechamber/parmchk2 ([01](01_ligand_parameterisation)). Dock the ligand into the site of interest.
4. **System.** Build and solvate the complex in tleap (ff19SB, OPC or TIP3P, Na+/Cl-), then repartition hydrogen masses with ParmEd ([02](02_system_setup)).
5. **Simulation.** Two minimisations, two heating stages, 10 ns equilibration, then 50 ns production segments (300 ns per replica) with a 4 fs time step ([03](03_md_protocol)).
6. **Analysis.** Strip and re-image with cpptraj, analyse with pytraj, and compute binding energies with MMPBSA.py ([04](04_analysis), [05](05_project_summary)).

### Quick start

```bash
conda env create -f environment.yml && conda activate cox2-md

cd 02_system_setup/APAP_POX
tleap -f APAP_POX.in
parmed -p APAP_POX.parm7 -i ../hmr.parmed           # set outparm to APAP_POX_HMR.parm7

../../03_md_protocol/run_equilibration.sh APAP_POX 1107 0
../../03_md_protocol/run_production.sh    APAP_POX 6 0
```

## Software

- [Amber / AmberTools](https://ambermd.org/): tleap, antechamber, parmchk2, MCPB.py, ParmEd, pmemd.cuda, cpptraj, MMPBSA.py
- Gaussian 16 and GaussView (QM optimisation and ESP)
- Python: pytraj, NumPy, SciPy, pandas, Matplotlib, seaborn

Amber changes between releases. Check the [current manual](https://ambermd.org/Manuals.php) and [tutorials](https://ambermd.org/tutorials/) before reusing the inputs.

## Further reading

**COX-2 review**
- [Chem. Rev., doi:10.1021/acs.chemrev.0c00215](https://pubs.acs.org/doi/10.1021/acs.chemrev.0c00215): a comprehensive starting point

**Allostery in COX-2**
- [PNAS, doi:10.1073/pnas.1507307112](https://www.pnas.org/doi/10.1073/pnas.1507307112)
- [J. Biol. Chem., doi:10.1074/jbc.M113.505503](https://doi.org/10.1074/jbc.M113.505503)
- [J. Biol. Chem., doi:10.1074/jbc.M116.757310](https://doi.org/10.1074/jbc.M116.757310)
- [J. Biol. Chem., doi:10.1074/jbc.TM118.006295](https://doi.org/10.1074/jbc.TM118.006295)

**Dipyrone (metamizole)**
- [doi:10.1002/jcph.1512](https://doi.org/10.1002/jcph.1512)
- [doi:10.1038/sj.bjp.0707239](https://doi.org/10.1038/sj.bjp.0707239)

**Mechanism of paracetamol**
- [doi:10.1016/j.clpt.2005.09.009](https://doi.org/10.1016/j.clpt.2005.09.009)
- [doi:10.1007/s10787-013-0172-x](https://link.springer.com/article/10.1007/s10787-013-0172-x)
- [doi:10.1111/1440-1681.13392](https://doi.org/10.1111/1440-1681.13392)
