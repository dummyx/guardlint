# Claim map for manuscript numbers

Use this map to keep the paper's numerical claims consistent with the artifact.

## Main result claims

| Paper claim | Exact wording to prefer | Artifact source |
|---|---|---|
| Missing guard queue | “GuardLint reports 40 potential missing-guard sites.” | `repro/generated/analysis_summary.csv`, query `missing_guards` |
| Raw witnesses | “The detailed query emits 244 internal evidence rows over 40 guard-obligation sites.” | `repro/generated/analysis_summary.csv`, query `missing_guard_detail` |
| Existing good guards | “The model recognizes 76 covering guard sites.” | `repro/generated/analysis_summary.csv`, query `good_guards` |
| Redundant guards | “The model reports 213 redundant-side model-feedback rows.” | `repro/generated/analysis_summary.csv`, query `redundant_guards` |
| CodeQL version | “The generated outputs record CodeQL CLI 2.25.0.” | `repro/generated/analysis_summary.csv` |
| Runtime | “The four query runs took roughly 960--1023 seconds each.” | `repro/generated/analysis_summary.csv` |

## Classification claims

| Paper claim | Artifact source |
|---|---|
| 40 classified sites | `repro/generated/missing_classification.csv` |
| 6 confirmed | `missing_classification.csv`, `classification=confirmed` |
| 1 strong candidate | `missing_classification.csv`, `classification=strong_candidate` |
| 26 plausible candidates | `missing_classification.csv`, `classification=plausible_candidate` |
| 7 likely false positives/model feedback | `missing_classification.csv`, `classification=likely_false_positive` |
| 27 review candidates | `missing_classification.csv`, `actionability=review_candidate` |
| 6 fix candidates | `missing_classification.csv`, `actionability=fix_candidate` |
| 7 model-feedback cases | `missing_classification.csv`, `actionability=model_feedback` |

## Derivation-family claims

Site-level counts from `missing_classification.csv`:

| Family | Sites |
|---|---:|
| string | 20 |
| array | 12 |
| other | 6 |
| typed_data | 1 |
| other|typed_data | 1 |

Raw witness counts from `missing_detail_summary.json`:

| Family | Raw rows |
|---|---:|
| string | 109 |
| array | 83 |
| other | 22 |
| typed_data | 30 |

Do not mix site-level and raw-row counts in the same table without labeling them clearly.

## Dynamic and external evidence claims

| Paper claim | Artifact source |
|---|---|
| Six bounded dynamic failures | `repro/generated/dynamic_poc_results.csv` |
| Three crash outcomes | dynamic rows: `open_key_args`, `io_buffer_set_string`, `rb_str_format_m` |
| Three corruption/output-mismatch outcomes | dynamic rows: `arith_seq_inspect`, `append_method`, `str_transcode0` |
| Four historical replays | `repro/generated/historical_replay_results.csv` |
| Three upstream corroborated sites | `repro/generated/pr_validation.csv` |
| Three optimized-code witnesses | `repro/generated/assembly_evidence.csv` |
| 68 matched benchmark workloads | `repro/generated/performance_overguard_summary.csv` |
| 6.99% geomean slowdown | `repro/generated/performance_overguard_summary.csv` |

## Redundant-guard claims

Safe claim now:

> The enabled redundant-guard query reports 213 redundant-side model-feedback rows.

Unsafe claim now:

> We classified all 213 redundant-side reports.

Reason: `repro/generated/redundant_guard_classification.csv` currently has 9 audited subset rows. Do not make full redundant-side classification claims unless the file is expanded to all 213 rows.

## Cross-release claims

Safe claim:

> The artifact records v4.0.4 database construction and guard inventories, but the witness-sensitive v4.0.4 queries completed; cross-release matching is treated as release-monitoring evidence, not as the primary evaluation result.

Unsafe claim:

> GuardLint's missing/redundant/good results were fully compared across v3.4.5 and v4.0.4.

## Wording rules

Use:

- “reports”
- “recognizes”
- “corroborates”
- “bounded dynamic failure”
- “stress experiment”
- “review candidate”
- “model-feedback case”

Avoid:

- “proves”
- “sound”
- “complete”
- “guarantees”
- “all missing guards”
- “automatic fix/removal”
