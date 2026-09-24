# 3. MD protocol (pmemd.cuda)

## Stages

| Stage | Input | Topology | Details |
|---|---|---|---|
| 1. Minimisation | `inputs/min_1.in` | `NAME.parm7` | 10,000 steps, solute restrained (10 kcal/mol/Å²) |
| 2. Minimisation | `inputs/min_2.in` | `NAME.parm7` | 16,000 steps, no restraints |
| 3. Heating | `inputs/Heat_1.in` | `NAME.parm7` | 0 → 100 K, 50 ps, NVT, restrained |
| 4. Heating | `inputs/Heat_2.in` | `NAME.parm7` | 100 → 320 K over 60 ps, then 320 → 300 K over 40 ps, NPT, restrained |
| 5. Equilibration | `inputs/equi_1.in` | `NAME_HMR.parm7` | 10 ns, 300 K, NPT (MC barostat), 4 fs step |
| 6. Production | `inputs/production.in` | `NAME_HMR.parm7` | 50 ns per segment, frame every 50 ps; the project used 6 segments (300 ns) per replica |

All stages use a Langevin thermostat (γ = 1 ps⁻¹), SHAKE on bonds to hydrogen, and a random seed (`ig=-1`), so each replica is independent. Equilibration and production switch to the hydrogen-mass-repartitioned topology to allow the 4 fs time step.

`RESNUM` in the restraint masks is a placeholder for the last solute residue (protein + heme + ligand). `run_equilibration.sh` fills it in.

## Running locally (one GPU)

Run from the folder holding `NAME.parm7`, `NAME.rst7` and `NAME_HMR.parm7`:

```bash
/path/to/03_md_protocol/run_equilibration.sh MAA_POX 1107 0     # NAME RESNUM GPU_ID
/path/to/03_md_protocol/run_production.sh    MAA_POX 6 0        # NAME NSEG GPU_ID -> 300 ns
```

`run_production.sh` writes `NAME_seg01.nc`, `NAME_seg02.nc`, and so on. To resume after an interruption, pass the first segment to run as the 4th argument. Set `PMEMD=/path/to/pmemd.cuda_SPFP` if the binary is not on your `PATH`.

## Running on a PBS cluster (Imperial RCS)

```bash
# Equilibration
qsub -v NAME=MAA_POX,RESNUM=1107,PROTOCOL_DIR=/path/to/03_md_protocol \
     /path/to/03_md_protocol/hpc/equilibration.pbs

# Production: self-resubmitting chain, one 50 ns segment per job
python /path/to/03_md_protocol/hpc/next_job.py MAA_POX 1 0 --init --nseg 6
```

`next_job.py` runs each segment in node-local scratch, copies the results back, then submits the next segment. Files are named `NAME_rep01-01.*`, `NAME_rep01-02.*`, and so on. Edit the `#PBS` resource lines in both files for a different cluster.

## Changes from the original scripts

- `Heat_2.in` had an `&wt type='END'` between the two temperature ramps, so pmemd stopped reading there and never saw the second ramp (320 → 300 K over the last 40 ps). The intended gradual cool-down to 300 K did not happen before equilibration. The extra `END` has been removed. **The original project's simulations were most likely run with the old file.**
- The old run scripts had one hard-coded line per segment, fixed GPU IDs, and pmemd/Python paths in other users' HPC home directories. Those are replaced by `run_equilibration.sh`, `run_production.sh`, `hpc/equilibration.pbs` and `hpc/next_job.py`. The old versions are still in the git history.
