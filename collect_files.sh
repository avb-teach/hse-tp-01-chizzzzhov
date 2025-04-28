#!/usr/bin/env bash
set -euo pipefail

MAX_DEPTH=""
if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR" >&2
  exit 1
fi

if [[ "$1" == "--max_depth" ]]; then
  [[ "$#" -lt 4 ]] && { echo "Error: --max_depth needs a value"; exit 1; }
  MAX_DEPTH="$2"
  [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] || { echo "Error: N must be integer"; exit 1; }
  shift 2
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

[[ -d "$INPUT_DIR" ]] || { echo "Input dir does not exist"; exit 1; }
mkdir -p "$OUTPUT_DIR"

make_unique() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    printf "%s" "$path"
    return
  fi
  local dir base ext dot i
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  ext="${base##*.}"
  if [[ "$ext" != "$base" ]]; then
    dot="."
    base="${base%.*}"
  else
    ext=""
    dot=""
  fi
  i=1
  while [[ -e "$dir/${base}_${i}${dot}${ext}" ]]; do
    ((i++))
  done
  printf "%s/%s_%d%s%s" "$dir" "$base" "$i" "$dot" "$ext"
}

find "$INPUT_DIR" -type f -print0 |
while IFS= read -r -d '' file; do
  rel="${file#$INPUT_DIR/}"
  if [[ -z "$MAX_DEPTH" ]]; then
    target_rel="$(basename "$rel")"
  else
    IFS='/' read -r -a parts <<< "$rel"
    total="${#parts[@]}"
    if (( total > MAX_DEPTH )); then
      start=$(( total - MAX_DEPTH ))
      target_rel="$(IFS=/; echo "${parts[*]:$start}")"
    else
      target_rel="$rel"
    fi
  fi
  target_path="$OUTPUT_DIR/$target_rel"
  mkdir -p "$(dirname "$target_path")"
  target_path="$(make_unique "$target_path")"
  cp "$file" "$target_path"
done
