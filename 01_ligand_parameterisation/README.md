# 1. Ligand parameterisation

GAFF parameters and RESP charges for each small molecule, produced with Gaussian 16 and AmberTools.

| Folder | Ligand | Residue name | Files |
|---|---|---|---|
| `arachidonic_acid/` | Arachidonic acid (AA, the COX-2 substrate) | `ACD` | two starting poses in the COX site (`ACD_headup.mol2`, `ACD_tailup.mol2`) and `ACD.frcmod` |
| `paracetamol/` | Paracetamol (acetaminophen, APAP) | `MOL` | `paracetamol_6-31g.mol2` (RESP) and `paracetamol.frcmod` |
| `metamizole_MAA/` | 4-methylaminoantipyrine (MAA), the active metabolite of dipyrone/metamizole | `MAA` | `MAA_resp.mol2` (RESP) and `MAA_may.frcmod` |
| `rofecoxib/` | Rofecoxib (Vioxx), a selective COX-2 inhibitor used as a reference | `RCX` | Gaussian inputs/outputs (`*.gjf`, `*.out`, `*.log`), poses (`Vioxx_*.pdb`) and RESP mol2 |

Parameters for 4-aminoantipyrine (4-AA) and AM404, which appear in the analysis notebooks, were not saved in this repository.

## Protocol

### 1. Prepare the structure
Extract the ligand from the complex (e.g. PDB) and add hydrogens in GaussView. Check that the atom order and atom names match the PDB you will later load in tleap.

### 2. Geometry optimisation (Gaussian 16)
Generate `ligand_opt.gjf` in GaussView (charge, multiplicity, coordinates) with this header:

```
%nprocshared=4
%chk=opt1.chk
# opt=loose b3lyp scrf=(solvent=water) def2svp em=gd3bj
```

```bash
g16 < ligand_opt.gjf > ligand_opt.out
```

### 3. Electrostatic potential for RESP
Build `ligand_resp.gjf` from the optimised geometry in `opt1.chk`:

```
%nprocshared=4
%chk=resp.chk
#p hf/6-31g(d) pop=mk iop(6/33=2,6/41=10,6/42=17) scf=tight
```

```bash
g16 < ligand_resp.gjf > ligand_resp.out
```

### 4. RESP charges and GAFF parameters (AmberTools)

```bash
# RESP fit -> mol2. Set -nc to the net charge and -rn to the residue name.
antechamber -i ligand_resp.out -fi gout -o LIG_resp.mol2 -fo mol2 -nc 0 -pf y -c resp -rn LIG
# Check bond orders in the mol2 (e.g. carboxylate C-O) before continuing.

# Missing force-field terms
parmchk2 -i LIG_resp.mol2 -f mol2 -o LIG.frcmod
```

The mol2 and frcmod files are then loaded in tleap (see [`../02_system_setup`](../02_system_setup)).

### Optional: two-stage RESP fit by hand
`-c resp` above does this in one step. The manual route lets you edit the restraints between stages:

```bash
antechamber -i ligand_resp.out -fi gout -o LIG.ac -fo ac -pf y
respgen -i LIG.ac -o LIG.respin1 -f resp1
respgen -i LIG.ac -o LIG.respin2 -f resp2
espgen  -i ligand_resp.out -o LIG.esp
resp -O -i LIG.respin1 -o LIG.respout1 -e LIG.esp -t qout_stage1
resp -O -i LIG.respin2 -o LIG.respout2 -e LIG.esp -q qout_stage1 -t qout_stage2
antechamber -i LIG.ac -fi ac -o LIG_resp.ac -fo ac -c rc -cf qout_stage2
antechamber -i LIG_resp.ac -fi ac -o LIG.mol2 -fo mol2 -rn LIG
```

> AmberTools changes between releases, so check the current [Amber manual](https://ambermd.org/Manuals.php) for any updated options.
