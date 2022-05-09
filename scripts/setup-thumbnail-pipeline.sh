#!/usr/bin/env bash
set -euo pipefail

video_name="$1"

raw_dir="data/raw/${video_name}"
processed_dir="data/processed/${video_name}"

thumbnail_raw="$raw_dir/thumbnail.png"

thumbnail_processed="$processed_dir/thumbnail.png"

dvc add "$thumbnail_raw"

dvc run --no-exec -n "${video_name}_thumbnail" \
    -d "$thumbnail_raw" \
    -o "$thumbnail_processed" \
    "./scripts/resize.sh $thumbnail_raw 1740 $processed_dir/"