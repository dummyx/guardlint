# Instructions for coding agents

You are updating a LaTeX research paper repository. Your task is to rewrite the paper for the SCAM Research Track. Do not change empirical claims unless you regenerate or verify the corresponding artifact data.

## Work style

Make edits in small, reviewable commits or patches. After each major content pass, compile the paper and run the claim audit helper if available.

Prefer preserving the current file layout. Do not split section files unless the paper becomes easier to maintain and all `\input{...}` references in `main.tex` are updated correctly.

## Target narrative

The paper is not primarily a tool report. It is a source-code analysis paper. The central contribution is the derive--trigger--use witness model for GC guard obligations in CRuby-like runtime C code.

GuardLint is the implementation used to instantiate and evaluate the model.

## Required high-level edits

1. `main.tex`
   - Change the title to foreground the model.
   - Remove author names, affiliations, and emails.
   - Replace the abstract with a Research Track abstract.
   - Update keywords to include static/source-code analysis, GC guard obligations, compiler liveness, CodeQL, runtime C.
   - Revisit `\newpage` before the bibliography and `\IEEEtriggeratref{13}` after compiling; do not force content beyond the 10-page content budget.

2. `sections/01-introduction.tex`
   - Replace Engineering Track/problem-workflow framing with a research gap and thesis.
   - State the derive--trigger--use idea in the first page.
   - Replace the contribution list with model/evaluation contributions.
   - Remove “project-specific maintenance rule” as the lead framing unless it is used only as secondary motivation.

3. `sections/02-background.tex`
   - Keep CRuby/RB_GC_GUARD background, but shorten it.
   - Add or preserve one compact motivating example.
   - Emphasize that guard placement is source-level and placement-sensitive.

4. `sections/03-design.tex`
   - Rename conceptually to model + analysis.
   - Start with formal/semi-formal definitions: owner, derived pointer, trigger, post-trigger use, guard, anchor, witness.
   - Then describe the CodeQL realization organized by model relation.
   - Remove or drastically shorten pipeline/adoption details.

5. `sections/04-evaluation.tex`
   - Replace the current research questions with four Research Track RQs:
     - RQ1: boundedness and coverage.
     - RQ2: evidence of real defects.
     - RQ3: precision limits and model-feedback taxonomy.
     - RQ4: guard necessity versus over-guarding.
   - Add an evidence matrix.
   - Add or prepare an ablation table. Do not fabricate ablation results.
   - Move cross-release release-monitoring material to threats or artifact notes.

6. `sections/05-discussion.tex`
   - Shorten adoption workflow.
   - Keep threats, limitations, and generality boundaries.
   - Emphasize single-subject validity, curated model risk, macro-heavy C, and bounded dynamic validation.

7. `sections/06-related-work.tex`
   - Lead with GC rooting/hazard analysis and Ugawa/Fujimoto.
   - Then compare Coccinelle, CodeQL/QL, UAF/dangling-pointer work, and actionable warning work.
   - Make the novelty distinction explicit: this is not explicit deallocation; it is a compiler-liveness/source-placement obligation for borrowed raw pointers.

8. `sections/07-conclusion.tex`
   - Remove `\vfill\break` unless needed only after final page-budget tuning.
   - Remove Engineering Track language.
   - Conclude with the research result, not adoption workflow.

9. `references.bib`
   - Reuse existing entries when present.
   - Add only references actually cited in the paper.
   - Do not cite SCAM submission pages in the paper body unless discussing venue requirements, which normally should not appear in the paper.

10. Artifact docs and generated data
   - Fix malformed `repro/generated/redundant_guard_classification.csv` if relying on it.
   - Add anonymized CodeQL query pack if available.
   - Scrub paths such as `/home/x17/...` before double-blind submission or move them to non-submission artifact notes.

## Empirical claim policy

Every empirical number must be traceable:

- `analysis_summary.csv`: 40 missing sites, 76 covering guard sites, 213 redundant-side rows, 244 internal evidence rows, runtimes, CodeQL version.
- `missing_classification.csv`: 40-site classification counts and derivation-family counts.
- `dynamic_poc_results.csv`: six bounded dynamic failures.
- `historical_replay_results.csv`: four historical replays.
- `pr_validation.csv`: three upstream corroborated sites.
- `assembly_evidence.csv`: three optimized-code witnesses.
- `performance_overguard_summary.csv`: 68 workloads and 6.99% geomean slowdown.

Do not write “proved”, “sound”, “complete”, or “all bugs”. Preferred phrasing: “reports review candidates”, “corroborates”, “bounded evidence”, “single-subject evaluation”, “witness-oriented”.

## Verification commands

From repository root:

```sh
python3 /path/to/kit/tools/claim_audit.py .
latexmk -pdf -interaction=nonstopmode main.tex || \
  (pdflatex -interaction=nonstopmode main.tex && bibtex main && pdflatex -interaction=nonstopmode main.tex && pdflatex -interaction=nonstopmode main.tex)
```

After compiling, inspect the PDF manually:

- Content should end by page 10.
- References should occupy pages 11--12 at most.
- No author identity should be visible.
- Abstract should not overclaim soundness or completeness.
- Tables should fit in IEEE two-column format.
