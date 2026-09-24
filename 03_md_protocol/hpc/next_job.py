#!/usr/bin/env python3
"""Self-resubmitting chain of PBS production jobs.

Each job runs one production segment (inputs/production.in, 50 ns) and, when it
finishes, calls this script again to submit the next segment, so a long
trajectory is split into jobs that fit inside the cluster walltime limit.

Start a chain (replica 1, 6 segments = 300 ns) from the directory holding
equi_1.ncrst and NAME_HMR.parm7:

    python next_job.py NAME 1 0 --init --nseg 6

Segment files are named NAME_rep<REP>-<RUN>.{out,nc,rst}. Resume after a failed
segment k by running ``python next_job.py NAME REP k-1`` (resubmits segment k).

Environment:
    PMEMD   path to pmemd.cuda_SPFP (default: pmemd.cuda_SPFP on PATH)
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PRODUCTION_IN = HERE.parent / "inputs" / "production.in"

PBS_HEADER = """#PBS -lselect=1:ncpus=4:mem=24gb:ngpus=1:gpu_type=RTX6000
#PBS -lwalltime=24:00:00
module load cuda/9.0
"""


def write_submit(prefix, rep, run, nseg, pmemd):
    rst = "equi_1.ncrst" if run == 1 else f"{prefix}_rep{rep:02}-{run - 1:02}.rst"
    name = f"{prefix}_rep{rep:02}-{run:02}"
    script = f"production{rep:02}-{run:02}.sh"
    # Run in node-local scratch, then copy results back to the submit directory
    with open(script, "w") as out:
        out.write(PBS_HEADER)
        out.write("\ncd /tmp/pbs.$PBS_JOBID\n")
        out.write(f"cp {PRODUCTION_IN} $PBS_O_WORKDIR/{rst} $PBS_O_WORKDIR/{prefix}_HMR.parm7 .\n")
        out.write(
            f"{pmemd} -O -i production.in -o {name}.out -c {rst} -p {prefix}_HMR.parm7 "
            f"-r {name}.rst -x {name}.nc -inf {name}.inf\n\n"
        )
        out.write(f"cp {name}.* $PBS_O_WORKDIR\n")
        out.write("cd $PBS_O_WORKDIR\n")
        out.write(f"{sys.executable} {HERE / 'next_job.py'} {prefix} {rep} {run} --nseg {nseg}\n")
    return script


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("prefix", help="system name (NAME in NAME_HMR.parm7)")
    parser.add_argument("rep", type=int, help="replica number")
    parser.add_argument("run", type=int, help="segment that just finished (0 to start)")
    parser.add_argument("--nseg", type=int, default=20, help="total segments in the chain (default 20)")
    parser.add_argument("--init", action="store_true", help="start a new chain at segment 1")
    args = parser.parse_args()

    next_run = 1 if args.init else args.run + 1
    if next_run > args.nseg:
        return
    pmemd = os.environ.get("PMEMD", "pmemd.cuda_SPFP")
    script = write_submit(args.prefix, args.rep, next_run, args.nseg, pmemd)
    subprocess.run(["qsub", "-N", f"{args.prefix}_{args.rep}_{next_run}", "-v", f"PMEMD={pmemd}", script], check=True)


if __name__ == "__main__":
    main()
