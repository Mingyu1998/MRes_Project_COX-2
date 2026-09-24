#!/usr/bin/env bash
# Chain N production segments (50 ns each with inputs/production.in) after equilibration.
#
# Usage:  ./run_production.sh NAME [NSEG] [GPU_ID] [START]
#   NAME    prefix of NAME_HMR.parm7
#   NSEG    number of 50 ns segments to run (default 6 -> 300 ns)
#   GPU_ID  CUDA device to use (default 0)
#   START   first segment to run (default 1); lets you resume an interrupted run
#
# Segment i writes NAME_seg<i>.{out,nc,rst7}. Segment 1 starts from equi_1.ncrst.
# Set PMEMD to override the engine (default: pmemd.cuda_SPFP on your PATH).
set -euo pipefail

if [[ $# -lt 1 ]]; then
    sed -n '2,11p' "$0"; exit 1
fi

NAME=$1
NSEG=${2:-6}
export CUDA_VISIBLE_DEVICES=${3:-0}
START=${4:-1}
PMEMD=${PMEMD:-pmemd.cuda_SPFP}
INPUTS=$(cd "$(dirname "$0")/inputs" && pwd)

for ((i = START; i <= NSEG; i++)); do
    seg=$(printf "%s_seg%02d" "$NAME" "$i")
    if [[ $i -eq 1 ]]; then
        rst=equi_1.ncrst
    else
        rst=$(printf "%s_seg%02d.rst7" "$NAME" "$((i - 1))")
    fi
    "$PMEMD" -O -i "${INPUTS}/production.in" -p "${NAME}_HMR.parm7" -c "$rst" \
        -o "${seg}.out" -r "${seg}.rst7" -x "${seg}.nc" -inf "${seg}.inf"
done
