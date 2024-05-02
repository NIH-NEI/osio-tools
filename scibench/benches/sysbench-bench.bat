@echo off
setlocal EnableDelayedExpansion

echo "[INFO] running sysbench benchmarking..."
SET "OUTDIR=sysbench-results"
SET _INTERPOLATION_0=
FOR /f "delims=" %%a in ('sysctl -n hw.ncpu') DO (SET "_INTERPOLATION_0=!_INTERPOLATION_0! %%a")
SET "CORES=!_INTERPOLATION_0:~1!"
SET _INTERPOLATION_1=
FOR /f "delims=" %%a in ('sysctl -n hw.ncpu') DO (SET "_INTERPOLATION_1=!_INTERPOLATION_1! %%a")
SET "!_INTERPOLATION_1:~1!HALF_CORES=$(($CORES / 2))"
mkdir "-p" "!OUTDIR!"
hyperfine "sysbench cpu run --threads=!HALF_CORES!" "--runs" "10" "--export-json" "!OUTDIR!/sysbench-cpu.json"
hyperfine "sysbench memory run --threads=!HALF_CORES!" "--runs" "10" "--export-json" "!OUTDIR!/sysbench-mem.json"
hyperfine "sysbench mutex run --threads=!HALF_CORES!" "--runs" "10" "--export-json" "!OUTDIR!/sysbench-mem.json"
