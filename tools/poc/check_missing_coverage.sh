#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <missing_detail.csv>" >&2
  exit 2
fi

csv="$1"
if [[ ! -f "$csv" ]]; then
  echo "error: csv not found: $csv" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
candidate_runner="$repo_root/tools/poc/poc_missing_candidates_runner.rb"
true_runner="$repo_root/tools/poc/poc_true_missings_runner.rb"
aggregate_runner="$repo_root/tools/poc/poc_missing_all.rb"
standalone="$repo_root/tools/poc/standalone_function_coverage.txt"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

awk -F',' 'NR>1 {gsub(/"/,"",$2); print $2}' "$csv" | sort -u > "$tmp_dir/missing_funcs.txt"

{
  rg --no-filename -o 'id: "[^"]+"' "$candidate_runner" "$true_runner" \
    | sed -E 's/id: "([^"]+)"/\1/'
  rg --no-filename -o 'run_case\("[^"]+"' "$aggregate_runner" \
    | sed -E 's/run_case\("([^"]+)"/\1/'
} | sort -u > "$tmp_dir/runner_funcs.txt"

sort -u "$tmp_dir/runner_funcs.txt" "$standalone" > "$tmp_dir/covered_funcs.raw.txt"

# File.realpath/File.realdirpath PoCs exercise rb_check_realpath_internal through
# public entrypoints, even though the helper itself is not a runnable case id.
cp "$tmp_dir/covered_funcs.raw.txt" "$tmp_dir/covered_funcs.txt"
if grep -qx 'realpath_rec' "$tmp_dir/covered_funcs.raw.txt" ||
   grep -qx 'rb_check_realpath_emulate' "$tmp_dir/covered_funcs.raw.txt"; then
  echo 'rb_check_realpath_internal' >> "$tmp_dir/covered_funcs.txt"
  sort -u -o "$tmp_dir/covered_funcs.txt" "$tmp_dir/covered_funcs.txt"
fi
comm -23 "$tmp_dir/missing_funcs.txt" "$tmp_dir/covered_funcs.txt" > "$tmp_dir/uncovered.txt"

echo "missing_functions=$(wc -l < "$tmp_dir/missing_funcs.txt")"
echo "runner_cases=$(wc -l < "$tmp_dir/runner_funcs.txt")"
echo "covered_union_functions=$(wc -l < "$tmp_dir/covered_funcs.txt")"
echo "uncovered_functions=$(wc -l < "$tmp_dir/uncovered.txt")"

if [[ -s "$tmp_dir/uncovered.txt" ]]; then
  echo "uncovered list:" >&2
  cat "$tmp_dir/uncovered.txt" >&2
  exit 1
fi

echo "coverage check passed"
