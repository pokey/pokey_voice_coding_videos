#!/usr/bin/env bash
set -euo pipefail

video_name="$1"

raw_dir="data/raw/${video_name}"
interim_dir="data/interim/${video_name}"
processed_dir="data/processed/${video_name}"

mkdir -p "$interim_dir"
mkdir -p "$processed_dir"

timeline="$raw_dir/timeline.xml"
recording_log="$raw_dir/recording-log"
index="$raw_dir/index.toml"
clips="$raw_dir/clips"

reconciled="$interim_dir/reconciled.jsonl"

mark_highlights_timeline="$processed_dir/mark-highlights-timeline.xml"
subtitles="$processed_dir/subtitles.srt"
transcript="$processed_dir/transcript.json"

external_transcript_output="../pokeyrule.com/src/data/videos/$video_name.json"

cp 'scripts/index-template.toml' "$index"
code --wait "$index"

dvc add "$timeline"
dvc add "$recording_log"
dvc add "$clips"

git add "$index"

dvc run --no-exec -n "${video_name}_reconcile" \
    -d poetry.lock \
    -d "$index" \
    -d "$timeline" \
    -d "$recording_log" \
    -o "$reconciled" \
    "voice-vid reconcile $index > $reconciled"

dvc run --no-exec -n "${video_name}_subtitles" \
    -d poetry.lock \
    -d "$index" \
    -d "$timeline" \
    -d "$recording_log" \
    -d "$reconciled" \
    -o "$subtitles" \
    "voice-vid subtitles --reconciled $reconciled $index > $subtitles"

dvc run --no-exec -n "${video_name}_transcript" \
    -d poetry.lock \
    -d "$index" \
    -d "$timeline" \
    -d "$recording_log" \
    -d "$reconciled" \
    -o "$transcript" \
    "voice-vid transcript --reconciled $reconciled $index > $transcript"

dvc run --no-exec -n "${video_name}_mark-highlights-track" \
    -d poetry.lock \
    -d "$index" \
    -d "$timeline" \
    -d "$recording_log" \
    -d "$reconciled" \
    -o "$mark_highlights_timeline" \
    "voice-vid mark-highlights --reconciled $reconciled $index $mark_highlights_timeline"

dvc run --no-exec -n "${video_name}_publish_transcript" \
    --external \
    -d "$transcript" \
    -o "$external_transcript_output" \
    "cp $transcript $external_transcript_output"