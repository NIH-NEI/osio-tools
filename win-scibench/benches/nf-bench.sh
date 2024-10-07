#!/usr/bin/env zsh

set -e

echo "[INFO] running nextflow nf-core/sarek..."
NXF_OPTS='-Xms1g -Xmx4g'

OUTDIR="results"
PLATFORM=$(uname -m)
CHIP_BRAND_NAME=$(sysctl -n machdep.cpu.brand_string | awk '{gsub(" ", "-", $0);print}')
DATE=$(date -I)
CORES=$(sysctl -n hw.ncpu)
TIMELINE_FILE="timeline-report_${DATE}_${CHIP_BRAND_NAME}_${PLATFORM}_${CORES}-cores.html"

echo "[INFO] writing timeline file to ${TIMELINE_FILE}"
echo "[INFO] Removing .nextflow.log work/..."
rm -rf .nextflow.log work $OUTDIR 
echo "[INFO] Running nextflow..."
nextflow run nf-core/sarek\
	-profile test,docker\
	-with-timeline "$TIMELINE_FILE"\
	-with-trace\
	--outdir "${OUTDIR}"

echo "[INFO] DONE, renaming tracefile."
mv ${TIMELINE_FILE} results/pipeline_info/${TIMELINE_FILE}
