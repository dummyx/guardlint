# GuardLint SCAM Research Track rewrite kit

This kit is a repo-aware guide for a coding agent that will rewrite the uploaded SCAM paper from an Engineering Track-style paper into a Research Track-style paper.

The intended repository root is the unpacked LaTeX project containing:

- `main.tex`
- `sections/01-introduction.tex`
- `sections/02-background.tex`
- `sections/03-design.tex`
- `sections/04-evaluation.tex`
- `sections/05-discussion.tex`
- `sections/06-related-work.tex`
- `sections/07-conclusion.tex`
- `references.bib`
- `repro/generated/*.csv`, `*.json`, and `*.md`
- `scripts/*.py`, `scripts/*.sh`

The agent should treat this kit as implementation guidance, not as paper text that must be copied blindly. The rewrite must preserve empirical truth and trace all numeric claims back to generated artifacts.

## Core objective

Transform the paper from:

> A practical GuardLint/CRuby maintenance workflow with useful evidence.

into:

> A research paper about a derive--trigger--use static-analysis model for compiler-liveness-dependent GC guard obligations, evaluated on CRuby.

The implementation/tool name `GuardLint` should remain, but the paper's intellectual center should be the model and validation argument, not tool adoption.

## Non-negotiable constraints

1. Do not fabricate results. If an ablation, query pack, redundant-guard audit, or artifact file is unavailable, mark it as a TODO or threat; do not write numbers.
2. Remove author-identifying content for Research Track review. This includes author blocks, affiliations, emails, local usernames, local home-directory paths, and non-anonymous artifact references.
3. Keep the paper within the Research Track budget: 12 pages total, with the last 2 pages for references only. The target is therefore 10 content pages plus references.
4. Preserve the verified numerical claims unless regenerated data changes them:
   - 244 internal missing-detail evidence rows.
   - 40 unique potential missing-guard sites.
   - 76 existing covering guard sites.
   - 213 redundant-side model-feedback rows, but audit/classification currently needs cleanup.
   - 6 bounded dynamic failures.
   - 3 later upstream fixes/corroborated sites.
   - 4 historical replays.
   - 3 optimized-code witnesses.
   - 68 benchmark workloads.
   - 6.99% geometric-mean slowdown in the over-guarding stress experiment.
5. Rewrite around a source-code analysis research contribution. Avoid language that says the main value is an Engineering Track workflow.

## Primary thesis

Use this thesis consistently:

> Compiler-liveness-dependent GC guard obligations can be modeled as derive--trigger--use witnesses over source code. This model produces a bounded, reviewable set of obligations in a production runtime, exposes real defects, and shows that over-guarding is not an adequate substitute for analysis.

## How to use this kit

Read the files in this order:

1. `AGENTS.md` — operational instructions for the coding agent.
2. `00_MASTER_AGENT_PROMPT.md` — copy/paste prompt for a coding agent session.
3. `01_RESEARCH_TRACK_POSITIONING.md` — target framing, claims, and narrative constraints.
4. `02_FILE_BY_FILE_REWRITE_PLAN.md` — exact edits by repository file.
5. `03_SECTION_BLUEPRINTS_AND_SNIPPETS.md` — section-level outlines and LaTeX-ready text fragments.
6. `04_EVALUATION_AND_TABLES_SPEC.md` — RQs, table designs, data sources, and ablation guidance.
7. `05_RELATED_WORK_SOURCE_NOTES.md` — related-work positioning and citations.
8. `06_ARTIFACT_AND_ANONYMIZATION_CHECKLIST.md` — double-blind and artifact tasks.
9. `07_ACCEPTANCE_CHECKLIST.md` — final review gate.
10. `08_TASKS.yaml` — structured task list for automated agents.

The `tools/` directory contains optional validation helpers. They do not modify the paper.

## Known issues in the uploaded package

The current package appears to contain paper text, scripts, and generated outputs, but not the actual CodeQL `.ql`/`.qll` query pack. A Research Track artifact should include an anonymized query pack or the paper should weaken reproducibility claims about query execution.

`repro/generated/redundant_guard_classification.csv` currently appears incomplete relative to the 213 redundant-side reports, and one row is malformed as CSV because the detail field contains an unquoted comma. Fix this before relying on redundant-guard classification numbers.

The current conclusion explicitly says “Engineering Track value.” Remove that phrase and the surrounding Engineering Track framing.

The current `main.tex` contains author names, affiliations, and emails. Remove or anonymize them before Research Track submission.
