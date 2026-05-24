#!/usr/bin/env python3
"""Audit empirical claims used in the GuardLint SCAM paper.

Usage:
    python3 claim_audit.py /path/to/repo/root

This script is intentionally read-only. It prints counts and warnings that a
coding agent should compare against the manuscript. It does not require pandas.
"""
from __future__ import annotations

import csv
import json
import sys
from collections import Counter
from pathlib import Path


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def check_field_counts(path: Path) -> list[str]:
    warnings: list[str] = []
    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        try:
            header = next(reader)
        except StopIteration:
            return [f"{path}: empty CSV"]
        expected = len(header)
        for lineno, row in enumerate(reader, start=2):
            if len(row) != expected:
                warnings.append(
                    f"{path}: line {lineno} has {len(row)} fields; expected {expected}: {row}"
                )
    return warnings


def safe(path: Path, label: str) -> bool:
    if not path.exists():
        print(f"MISSING: {label}: {path}")
        return False
    return True


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    gen = root / "repro" / "generated"
    print(f"Repository root: {root}")
    print(f"Generated data:   {gen}")
    print()

    warnings: list[str] = []

    # analysis_summary.csv
    p = gen / "analysis_summary.csv"
    if safe(p, "analysis summary"):
        rows = read_csv(p)
        by_query = {r.get("query", ""): r for r in rows}
        print("analysis_summary.csv")
        def row_count(r: dict[str, str]) -> str | None:
            return r.get("output_rows") or r.get("rows")

        def site_count(r: dict[str, str]) -> str | None:
            return r.get("site_count") or r.get("unique_locations")

        for q in ["missing_guards", "good_guards", "redundant_guards", "missing_guard_detail"]:
            r = by_query.get(q)
            if r:
                print(
                    f"  {q:22s} rows={row_count(r)} sites={site_count(r)} runtime_s={r.get('runtime_s')} codeql={r.get('codeql_cli')}"
                )
            else:
                warnings.append(f"analysis_summary.csv lacks query row {q!r}")
        print()
        expected = {
            "missing_guards": ("40", "40"),
            "good_guards": ("76", "76"),
            "redundant_guards": ("213", "213"),
            "missing_guard_detail": ("244", "40"),
        }
        for q, (exp_rows, exp_sites) in expected.items():
            r = by_query.get(q)
            if not r:
                continue
            if row_count(r) != exp_rows or site_count(r) != exp_sites:
                warnings.append(
                    f"analysis_summary.csv {q}: expected rows/sites {exp_rows}/{exp_sites}, got {row_count(r)}/{site_count(r)}"
                )

    # missing_detail_summary.json
    p = gen / "missing_detail_summary.json"
    if safe(p, "missing detail summary"):
        data = json.loads(p.read_text(encoding="utf-8"))
        print("missing_detail_summary.json")
        print(f"  CodeQL version: {data.get('codeql_version')}")
        print(f"  Raw derivation family counts: {data.get('counts_by_derivation_family')}")
        print()

    # missing_classification.csv
    p = gen / "missing_classification.csv"
    if safe(p, "missing classification"):
        rows = read_csv(p)
        class_counts = Counter(r.get("classification", "") for r in rows)
        action_counts = Counter(r.get("actionability", "") for r in rows)
        family_counts = Counter(r.get("derivation_family", "") for r in rows)
        fp_counts = Counter(r.get("false_positive_pattern", "") for r in rows if r.get("false_positive_pattern", ""))
        print("missing_classification.csv")
        print(f"  rows: {len(rows)}")
        print(f"  classification: {dict(class_counts)}")
        print(f"  actionability:  {dict(action_counts)}")
        print(f"  family sites:   {dict(family_counts)}")
        print(f"  fp patterns:    {dict(fp_counts)}")
        print()
        expected_class = {"confirmed": 6, "strong_candidate": 1, "plausible_candidate": 26, "likely_false_positive": 7}
        for k, v in expected_class.items():
            if class_counts.get(k, 0) != v:
                warnings.append(f"missing_classification.csv classification {k}: expected {v}, got {class_counts.get(k, 0)}")
        expected_family = {"string": 20, "array": 12, "other": 6, "typed_data": 1, "other|typed_data": 1}
        for k, v in expected_family.items():
            if family_counts.get(k, 0) != v:
                warnings.append(f"missing_classification.csv family {k}: expected {v}, got {family_counts.get(k, 0)}")

    # Evidence counts
    for fname, expected_count, label in [
        ("dynamic_poc_results.csv", 6, "bounded dynamic failures"),
        ("historical_replay_results.csv", 4, "historical replays"),
        ("pr_validation.csv", 3, "upstream corroborated sites"),
        ("assembly_evidence.csv", 3, "optimized-code witnesses"),
    ]:
        p = gen / fname
        if safe(p, label):
            rows = read_csv(p)
            print(f"{fname}")
            print(f"  rows: {len(rows)} ({label})")
            if len(rows) != expected_count:
                warnings.append(f"{fname}: expected {expected_count} rows for {label}, got {len(rows)}")
            print()

    # Overguard summary
    p = gen / "performance_overguard_summary.csv"
    if safe(p, "performance overguard summary"):
        rows = read_csv(p)
        print("performance_overguard_summary.csv")
        if rows:
            r = rows[0]
            print(f"  status: {r.get('status')}")
            print(f"  matched benchmarks: {r.get('benchmarks_matched')}")
            print(f"  geomean slowdown percent: {r.get('geomean_slowdown_percent')}")
            if r.get("benchmarks_matched") != "68":
                warnings.append(f"performance_overguard_summary.csv: expected 68 benchmarks, got {r.get('benchmarks_matched')}")
            if r.get("geomean_slowdown_percent") != "6.99":
                warnings.append(f"performance_overguard_summary.csv: expected 6.99 slowdown, got {r.get('geomean_slowdown_percent')}")
            for field in ["baseline_csv", "overguard_csv"]:
                val = r.get(field, "")
                if val.startswith("/home/") or val.startswith("/Users/"):
                    warnings.append(f"performance_overguard_summary.csv: {field} contains local absolute path: {val}")
        print()

    # Redundant classification
    p = gen / "redundant_guard_classification.csv"
    if safe(p, "redundant guard classification"):
        warnings.extend(check_field_counts(p))
        try:
            rows = read_csv(p)
            print("redundant_guard_classification.csv")
            print(f"  parseable rows by DictReader: {len(rows)}")
            print("  audited subset expected by current artifact: 9 rows")
            if len(rows) != 9:
                warnings.append(
                    f"redundant_guard_classification.csv: expected 9 audited subset rows, got {len(rows)}"
                )
            print()
        except Exception as exc:
            warnings.append(f"Could not parse redundant_guard_classification.csv: {exc}")

    # Identity/path hints
    identity_terms = [
        "Zhijie", "Xie", "Hidehiko", "Masuhara", "Koichi", "Sasada",
        "Science Tokyo", "is.titech", "STORES", "/home/", "/Users/",
    ]
    print("identity/path scan hints")
    for term in identity_terms:
        hits = []
        for path in [root / "main.tex", root / "README.md", root / "REPRODUCIBILITY.md"]:
            if path.exists() and term in path.read_text(encoding="utf-8", errors="ignore"):
                hits.append(str(path.relative_to(root)))
        if hits:
            warnings.append(f"Identity/path term {term!r} found in {hits}")
    print("  scanned main.tex, README.md, REPRODUCIBILITY.md for common identity/path terms")
    print()

    if warnings:
        print("WARNINGS")
        for w in warnings:
            print(f"  - {w}")
        return 1

    print("No warnings from claim audit.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
