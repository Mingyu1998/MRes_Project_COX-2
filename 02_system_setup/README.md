# 2. System setup (tleap)

Builds the solvated COX-2 dimer + ligand systems and writes the Amber topology/coordinates (`.parm7`/`.rst7`).

## Layout

| Folder | What it holds |
|---|---|
| `common/` | Protein model and heme/iron parameters shared by every system |
| `AA_COX/` | Arachidonic acid in the cyclooxygenase (COX) site: head-up, tail-up and one of each (`AA_double.in`) |
| `APAP_COX/` | Paracetamol in the COX site (dry complex only) |
| `APAP_POX/` | Paracetamol docked at the peroxidase (POX) site next to the heme |
| `MAA_POX/` | 4-methylaminoantipyrine docked at the POX site |
| `hmr.parmed` | ParmEd input for hydrogen mass repartitioning |

Each system folder contains its tleap input (`*.in`), the resulting dry and solvated PDBs, and the original `leap.log`/`parmed.log` as a record of what was run. The `.parm7`/`.rst7` files are not stored (too large); rerun tleap to regenerate them.

### `common/`

- `COX-2.pdb`: the COX-2 homodimer (1108 residues) with a heme in each monomer. The heme iron and the residues coordinating it (including a water bound to the iron, `HH1`) are renamed so they pick up the MCPB.py parameters.
- `COX-2_re.pdb`: the same model without the iron-bound water (1106 residues). The POX-site systems use it so the ligand can occupy that position. Residue numbers after 553 are shifted by one, which is why the disulfide `bond` lines differ between the two scripts.
- `HD1`, `HD2`, `FE1`, `FE2`, `HH1`, `H21`, `HEM`, `HOH` `.mol2` files and `HE2`, `HOH`, `HEM`, `COX-2_mcpbpy` `.frcmod` files: MCPB.py-derived residue templates and parameters for the heme/Fe/His site. They define the atom types added with `addAtomTypes` in each tleap script.

## Force field

| Component | Choice |
|---|---|
| Protein | ff19SB |
| Ligands | GAFF with RESP charges (see [`../01_ligand_parameterisation`](../01_ligand_parameterisation)) |
| Heme / Fe site | MCPB.py bonded model (`common/`) |
| Water / ions | OPC + Li/Merz 12-6 ions for the AA systems; TIP3P + 12-6-4 ions for the paracetamol and MAA systems |
| Box | rectangular box with a 20 Å buffer, neutralised with Na+, plus 219 Na+/Cl- pairs |

The water model differs between the AA and POX-site systems; keep that in mind when comparing them directly. `APAP_COX/APAP_COX.in` loads TIP3P water with an OPC ion frcmod as well; it only writes a dry PDB, so this does not affect any simulation here, but fix it before solvating that system.

## Building a system

Run tleap from inside the system folder, because file paths are relative to it:

```bash
cd 02_system_setup/APAP_POX
tleap -f APAP_POX.in                 # -> APAP_POX.parm7, APAP_POX.rst7, *_dry.pdb, *_solv.pdb

# Hydrogen mass repartitioning for the 4 fs time step
# (edit the outparm name in hmr.parmed to NAME_HMR.parm7 first)
parmed -p APAP_POX.parm7 -i ../hmr.parmed
```

Then follow [`../03_md_protocol`](../03_md_protocol).

### Notes

- `MAA_POX/MAA_POX.in` was reconstructed from `MAA_POX/leap.log` because the original input was not saved. It needs `MAA_POX.mol2` (MAA at the POX site with RESP charges), which is also missing. Residue 1 of `MAA_POX_dry.pdb` has the docked coordinates, and `../01_ligand_parameterisation/metamizole_MAA/MAA_resp.mol2` has the charges.
- `APAP_POX/` holds two docked poses. `APAP_POX.in` uses `APAP_POX_dock.mol2`, which matches the saved PDBs. `APAP_POX_newdock.mol2` is an alternative pose that `leap.log` shows was also built.
