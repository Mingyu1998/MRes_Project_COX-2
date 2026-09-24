#!/usr/bin/env bash
# Minimisation -> heating -> equilibration for one solvated system (local GPU).
#
# Usage:  ./run_equilibration.sh NAME RESNUM [GPU_ID]
#   NAME    prefix of the tleap/parmed outputs: NAME.parm7, NAME.rst7, NAME_HMR.parm7
#   RESNUM  last solute residue (protein + heme + ligand); restrained during min/heat
#   GPU_ID  CUDA device to use (default 0)
#
# Set PMEMD to override the engine (default: pmemd.cuda_SPFP on your PATH).
# Run from the directory that holds the topology/coordinate files.
set -euo pipefail

if [[ $# -lt 2 ]]; then
    sed -n '2,10p' "$0"; exit 1
fi

NAME=$1
RESNUM=$2
export CUDA_VISIBLE_DEVICES=${3:-0}
PMEMD=${PMEMD:-pmemd.cuda_SPFP}
INPUTS=$(cd "$(dirname "$0")/inputs" && pwd)

# Fill the restraint mask placeholder in local copies of the input files
for stage in min_1 min_2 Heat_1 Heat_2 equi_1; do
    sed "s/RESNUM/${RESNUM}/g" "${INPUTS}/${stage}.in" > "${stage}.in"
done

"$PMEMD" -O -i min_1.in  -o min_1.out  -p "${NAME}.parm7"     -c "${NAME}.rst7" -ref "${NAME}.rst7" -r min_1.ncrst  -inf min_1.inf
"$PMEMD" -O -i min_2.in  -o min_2.out  -p "${NAME}.parm7"     -c min_1.ncrst                        -r min_2.ncrst  -inf min_2.inf
"$PMEMD" -O -i Heat_1.in -o Heat_1.out -p "${NAME}.parm7"     -c min_2.ncrst  -ref min_2.ncrst      -r Heat_1.ncrst -inf Heat_1.inf
"$PMEMD" -O -i Heat_2.in -o Heat_2.out -p "${NAME}.parm7"     -c Heat_1.ncrst -ref Heat_1.ncrst     -r Heat_2.ncrst -inf Heat_2.inf
# Equilibration switches to the hydrogen-mass-repartitioned topology (4 fs time step)
"$PMEMD" -O -i equi_1.in -o equi_1.out -p "${NAME}_HMR.parm7" -c Heat_2.ncrst                       -r equi_1.ncrst -inf equi_1.inf
