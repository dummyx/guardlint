# Master prompt for the coding agent

Use this prompt to start an agent session in the paper repository.

```text
You are editing a LaTeX repository for a SCAM Research Track submission. The current paper is an Engineering Track-style GuardLint/CRuby tool and workflow paper. Rewrite it into a Research Track paper about a derive--trigger--use static-analysis model for compiler-liveness-dependent GC guard obligations.

Primary thesis:
Compiler-liveness-dependent GC guard obligations can be modeled as derive--trigger--use witnesses over source code. This model produces a bounded, reviewable set of obligations in a production runtime, exposes real defects, and shows that over-guarding is not an adequate substitute for analysis.

Repository files to edit:
- main.tex
- sections/01-introduction.tex
- sections/02-background.tex
- sections/03-design.tex
- sections/04-evaluation.tex
- sections/05-discussion.tex
- sections/06-related-work.tex
- sections/07-conclusion.tex
- references.bib only if needed
- reproducibility/artifact docs only for anonymization and consistency

Hard constraints:
1. Do not fabricate results.
2. Preserve empirical numbers unless verified or regenerated from repro/generated.
3. Remove author names, affiliations, emails, local user paths, and self-identifying artifact details for double-blind review.
4. Keep 10 content pages + up to 2 reference pages.
5. Do not claim soundness, completeness, or proof of absence of bugs.
6. If ablation results are unavailable, create a clearly marked TODO or omit the ablation result table; do not invent values.

Required rewrite actions:
- Change the title to foreground the model, e.g. “Derive--Trigger--Use: Static Detection of GC Guard Obligations in CRuby”.
- Replace the abstract with a research abstract centered on the source-level model.
- Rewrite the introduction around the research gap, thesis, and contributions.
- Convert the Design section into a model + analysis section.
- Rewrite evaluation around RQ1--RQ4:
  RQ1 boundedness and coverage;
  RQ2 evidence of real defects;
  RQ3 precision limits and model-feedback taxonomy;
  RQ4 guard necessity versus over-guarding.
- Move cross-release release-monitoring details out of the main result narrative and into threats/artifact limitations.
- Rewrite related work to lead with GC rooting/hazard analysis, Ugawa/Fujimoto, Coccinelle, QL/CodeQL, memory-safety analyses, and actionable static-analysis warnings.
- Remove Engineering Track language from the conclusion and discussion.
- Fix or downgrade claims based on redundant_guard_classification.csv because it is currently incomplete/malformed relative to the 213 redundant-side reports.

Authoritative numbers and sources:
- analysis_summary.csv: 40 missing sites, 76 covering guard sites, 213 redundant-side rows, 244 internal evidence rows.
- missing_classification.csv: 26 plausible candidates, 7 likely false positives/model feedback, 6 confirmed, 1 strong candidate; derivation family counts are 20 string, 12 array, 6 other, 1 typed_data, 1 other|typed_data.
- dynamic_poc_results.csv: 6 bounded dynamic failures.
- historical_replay_results.csv: 4 recovered historical fixes.
- pr_validation.csv: 3 upstream corroborated sites.
- assembly_evidence.csv: 3 optimized-code witnesses.
- performance_overguard_summary.csv: 68 benchmark workloads, 6.99% geometric-mean slowdown.

Preferred terms:
- “witness-oriented static analysis”
- “derive--trigger--use witness”
- “owner anchor”
- “guard coverage”
- “bounded review queue”
- “corroborating evidence”
- “model-feedback pattern”

Avoid terms:
- “complete”, “sound”, “proved”, “guarantees”, “automatic repair”, “Engineering Track value”, “industrial impact” as the main claim.

Before finishing:
- Compile the paper.
- Inspect page count.
- Run the claim audit helper if available.
- Confirm no author identity remains.
- Confirm no unsupported new numeric claim was added.
```
