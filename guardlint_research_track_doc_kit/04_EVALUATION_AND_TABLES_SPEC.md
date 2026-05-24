# Evaluation and tables specification

This file defines the evaluation rewrite. It is the most important part of the Research Track conversion.

## Evaluation strategy

The evaluation should answer whether the derive--trigger--use model is useful as a source-code analysis formulation. It should not merely describe a pipeline.

Use four kinds of evidence:

1. **Boundedness:** the model condenses raw witnesses into a small review queue.
2. **Corroboration:** independent evidence shows that some reports correspond to real defects.
3. **Precision limits:** false positives are structured and explain model boundaries.
4. **Mechanism/cost:** optimized code and over-guarding show why selective guard analysis matters.

## Authoritative data files

Use these files as the source of numerical claims:

| Claim | Source file |
|---|---|
| 40 potential missing guards | `repro/generated/analysis_summary.csv` |
| 76 recognized covering guards | `repro/generated/analysis_summary.csv` |
| 213 redundant-side model-feedback rows | `repro/generated/analysis_summary.csv` |
| 244 internal evidence rows | `repro/generated/analysis_summary.csv`, `repro/generated/missing_detail_summary.json` |
| CodeQL version 2.25.0 | `repro/generated/analysis_summary.csv`, `repro/generated/missing_detail_summary.json` |
| Query runtimes roughly 960--1023s | `repro/generated/analysis_summary.csv` |
| Classification counts | `repro/generated/missing_classification.csv` |
| Derivation-family site counts | `repro/generated/missing_classification.csv` |
| Raw derivation-family row counts | `repro/generated/missing_detail_summary.json` |
| Dynamic failures | `repro/generated/dynamic_poc_results.csv` |
| Historical replays | `repro/generated/historical_replay_results.csv` |
| Upstream corroboration | `repro/generated/pr_validation.csv` |
| Optimized-code witnesses | `repro/generated/assembly_evidence.csv`, `repro/generated/optimized_witnesses.md` |
| Over-guarding slowdown | `repro/generated/performance_overguard_summary.csv` |
| Model-feedback patterns | `repro/generated/model_feedback_review.csv`, `repro/generated/likely_false_positive_pattern_review.csv`, `repro/generated/unclear_site_review.csv` |
| Redundant guard classification | `repro/generated/redundant_guard_classification.csv` after fixing malformed/incomplete data |

## RQ1: Boundedness and coverage

### Research question

> Can a derive--trigger--use model produce a bounded, inspectable set of GC guard obligations in a production C runtime?

### Claims to make

- GuardLint emits 244 internal missing-detail evidence rows.
- These rows condense to 40 unique potential missing-guard sites.
- The same model recognizes 76 existing covering guard sites as justified/covered.
- It reports 213 redundant-side model-feedback rows, but only an audited subset is classified in depth.
- Site-level derivation-family coverage is not one trivial pattern: 20 string, 12 array, 6 other, 1 typed-data, and 1 other/typed-data combination.

### Table 1: result overview

Use the table from `03_SECTION_BLUEPRINTS_AND_SNIPPETS.md`.

### Table 2: derivation-family site counts

Use the site counts from `missing_classification.csv`, not raw witness counts, unless explicitly labeled as raw rows.

### Suggested prose

```tex
The raw witness count is intentionally larger than the review queue because a single source site can contain several trigger/use combinations. GuardLint's deduplication therefore matters: it preserves the source evidence needed for review while presenting maintainers with 40 guard-obligation sites rather than 244 evidence rows.
```

### Ablation study: strongly recommended

Ablation is the largest missing Research Track element. Add it if query sources are available.

#### Purpose

Show that the model is not just a monolithic CodeQL rule; its components materially control precision and boundedness.

#### Candidate variants

| Variant | Meaning |
|---|---|
| V0: derivation + later use only | raw pointer derived from owner and later used |
| V1: + trigger requirement | require a GC-relevant operation between derivation and use |
| V2: + post-trigger consumer model | require actual modeled consumption after trigger |
| V3: + guard coverage | suppress intervals covered by recognized guards |
| V4: + owner anchors | suppress intervals covered by later owner anchors |
| V5: + macro/out-param binding | apply CRuby-specific macro owner/out-param role modeling |
| Full | current enabled model |

#### Metrics

For each variant, record:

- raw witness rows;
- unique sites;
- number of six confirmed dynamic-failure sites retained;
- number of likely false positives/model-feedback sites retained if easy to compute;
- runtime if available.

#### Table template

```tex
\begin{table}[t]
\caption{Ablation of derive--trigger--use model components.}
\label{tab:ablation}
\centering
\scriptsize
\begin{tabular}{@{}lrrr@{}}
\toprule
Variant & Raw rows & Sites & Confirmed sites retained \\
\midrule
Derivation + later use only & TODO & TODO & TODO \\
+ GC trigger & TODO & TODO & TODO \\
+ post-trigger consumer & TODO & TODO & TODO \\
+ guard coverage & TODO & TODO & TODO \\
+ owner anchors & TODO & TODO & TODO \\
+ macro/out-param binding & TODO & TODO & TODO \\
Full model & 244 & 40 & 6 \\
\bottomrule
\end{tabular}
\end{table}
```

Do not leave `TODO` values in the submitted paper. If ablation cannot be run, omit this table and add a threat/future-work sentence:

```tex
We did not include a full ablation because the artifact records only the enabled query results; adding query-variant runs is future work.
```

This is weaker than a true ablation. Prefer running the ablation.

## RQ2: Evidence of real defects

### Research question

> How much independent evidence supports the reported missing-guard obligations?

### Evidence types

Use an evidence matrix with counts and limitations. Avoid claiming that any single evidence source is a full oracle.

### Confirmed dynamic failures

From `dynamic_poc_results.csv`:

| Case | File/function | Outcome |
|---|---|---|
| `open_key_args` | `io.c` / `open_key_args` | crash |
| `io_buffer_set_string` | `io_buffer.c` / `io_buffer_set_string` | crash |
| `arith_seq_inspect` | `enumerator.c` / `arith_seq_inspect` | corruption |
| `append_method` | `enumerator.c` / `append_method` | corruption |
| `str_transcode0` | `transcode.c` / `str_transcode0` | corruption |
| `rb_str_format_m` | `string.c` / `rb_str_format_m` | crash |

### Upstream corroboration

From `pr_validation.csv`:

- `cruby/string.c:2555:11:tmp` — merged PR, fix adds `RB_GC_GUARD(tmp)`.
- `cruby/enumerator.c:1168:19:eargs` — merged direct commit, fix adds `RB_GC_GUARD(eargs)`.
- `cruby/enumerator.c:4200:22:eargs` — same merged direct commit, fix adds `RB_GC_GUARD(eargs)`.

Use the term “upstream corroboration,” not “ground truth.”

### Historical replay

From `historical_replay_results.csv`, four fixes are recovered. The key claim:

> GuardLint reports the repaired variable in the pre-fix revision and the report drops after the guard-adding change.

### Classification counts

From `missing_classification.csv`:

- confirmed: 6;
- strong candidate: 1;
- plausible candidate: 42;
- likely false positive/model feedback: 13.

Actionability counts:

- review candidate: 43;
- model feedback: 13;
- fix candidate: 6.

Phrase carefully. “Confirmed” means confirmed by dynamic/upstream/assembly evidence as classified in the artifact, not formally proven.

## RQ3: Precision limits

### Research question

> What false-positive and model-feedback patterns arise, and what do they reveal about source-level GC guard analysis?

### Goal

Make false positives into a research result. The paper should show that precision limits are structured, not random noise.

### Patterns from classification files

Site-level `false_positive_pattern` counts in `missing_classification.csv` include:

- later_owner_reanchor: 3;
- pointer_reassigned_before_use: 2;
- receiver_owner_liveness: 2;
- caller_slot_owner_anchor: 1;
- owner_identity_mismatch: 1;
- pointer_arithmetic_completed_before_trigger: 1;
- later_owner_return_anchor: 1;
- receiver_alias_return_anchor: 1;
- same_call_owner_anchor: 1.

`model_feedback_review.csv` and `likely_false_positive_pattern_review.csv` add richer explanations such as non-owning typed-data payload, exact macro owner/out-parameter binding, scalar pointer difference only, and write-only pointer rebinding.

### Suggested prose

```tex
The 7 likely false positives are not arbitrary parser artifacts. They cluster around missing semantic anchors: caller-owned VALUE slots, receiver liveness, same-call owner arguments, later returns, pointer rebinding, and owner-identity mismatches. These cases indicate where a local source-order witness is insufficient and where future versions need stronger path-sensitive or interprocedural owner-anchor reasoning.
```

### Table

Use the taxonomy table from `03_SECTION_BLUEPRINTS_AND_SNIPPETS.md`. If page budget is tight, make it a compact paragraph instead of a table.

## RQ4: Guard necessity versus over-guarding

### Research question

> What mechanism evidence explains why guards are needed, and what cost evidence explains why indiscriminate guarding is not an adequate substitute?

### Required elements

1. Ruby documentation says `RB_GC_GUARD` must be placed after last use and is preferable to volatile partly because volatile can hurt optimization.
2. Optimized-code witnesses show the owner may not remain visible in generated code.
3. Dynamic failures show correctness consequences.
4. Over-guarding stress experiment shows blanket insertion has measurable cost.

### Over-guarding wording

Use:

```tex
The over-guarding experiment is a stress test of a blanket strategy, not a per-site cost model. It demonstrates that “add guards everywhere” is not a satisfactory substitute for selective analysis.
```

### Do not write

- “Every redundant guard slows down CRuby.”
- “Removing all redundant guards improves by 6.99%.”
- “The slowdown is caused by the 213 redundant-side rows.”

Correct interpretation:

> Mechanically inserting scope-end guards for local `VALUE` variables across the scope slowed 68 matched ruby-bench workloads by 6.99% geomean. This motivates selectivity.

## Handling redundant guards

Current issue:

- `analysis_summary.csv` reports 213 redundant-side rows.
- `redundant_guard_classification.csv` has only 9 data rows and is malformed because at least one detail field contains an unquoted comma.

Agent actions:

1. Fix CSV quoting.
2. If possible, classify all 213 redundant-side reports.
3. If only 9 are audited, state that explicitly:

```tex
We audited 9 of the 213 redundant-side reports in depth. These reports are used as model-boundary evidence rather than as automatic removal recommendations.
```

Do not imply that all 213 have been classified unless the file is completed.

## Cross-release material

The current paper spends evaluation space on cross-release setup and v4.0.4 release-monitoring result. For Research Track, demote it.

Preferred placement:

- Threats to validity.
- Artifact note.
- One sentence in evaluation setup only if needed.

Suggested sentence:

```tex
The artifact records v4.0.4 database construction, completed site-level query runs, guard inventories, and a normalized missing-site delta; we treat cross-release matching as release-monitoring evidence rather than the primary evaluation result.
```

## Final evaluation shape

A strong Research Track evaluation section should contain:

1. RQ overview and data sources.
2. Result overview table.
3. Optional ablation table.
4. Evidence matrix.
5. Dynamic/upstream/historical evidence tables or compressed text.
6. Classification/taxonomy.
7. Over-guarding and optimized-code mechanism discussion.

Target length: about 3 pages.
