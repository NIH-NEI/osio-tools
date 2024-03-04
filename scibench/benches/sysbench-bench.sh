#!/usr/bin/env zsh

set -e

echo "[INFO] running sysbench benchmarking..."

OUTDIR="sysbench-results"
CORES=$(sysctl -n hw.ncpu)
HALF_CORES=$(($CORES / 2))
mkdir -p $OUTDIR

# cpu
hyperfine "sysbench cpu run --threads=${HALF_CORES}" \
  --runs 10 \
  --export-json "${OUTDIR}/sysbench-cpu.json"

# mem
hyperfine "sysbench memory run --threads=${HALF_CORES}" \
  --runs 10 \
  --export-json "${OUTDIR}/sysbench-mem.json"

# mem
hyperfine "sysbench mutex run --threads=${HALF_CORES}" \
  --runs 10 \
  --export-json "${OUTDIR}/sysbench-mem.json"

