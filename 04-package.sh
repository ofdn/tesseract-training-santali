#!/bin/bash
# Packages a checkpoint as output/sat.traineddata. By default it takes
# output/sat_checkpoint, which holds the best model once training stops.
# Pick another with CHECKPOINT=output/sat_1.234_5678_9000.checkpoint
set -e
cd "$(dirname "$0")"

CHECKPOINT=${CHECKPOINT:-output/sat_checkpoint}
[ -f "$CHECKPOINT" ] || { echo "$CHECKPOINT not found. Run ./03-train.sh first."; exit 1; }

lstmtraining \
    --stop_training \
    --continue_from "$CHECKPOINT" \
    --traineddata   tessdata_best/sat_base.traineddata \
    --model_output  output/sat.traineddata

ls -lh output/sat.traineddata
