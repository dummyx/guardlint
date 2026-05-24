# Suggested patch sequence

This sequence is designed for a coding agent that edits and compiles iteratively.

## Patch 1: Metadata and anonymization

Files:

- `main.tex`
- `README.md`
- `REPRODUCIBILITY.md` if included in artifact

Actions:

1. Change title.
2. Remove author block.
3. Replace abstract.
4. Update keywords.
5. Scrub obvious names/emails/local paths from paper-facing docs.

Compile after this patch to ensure the LaTeX still builds.

## Patch 2: Introduction rewrite

File:

- `sections/01-introduction.tex`

Actions:

1. Replace lead with GC runtime/raw pointer/compiler-liveness problem.
2. State source-level placement problem.
3. Introduce derive--trigger--use witness.
4. Add headline numbers.
5. Replace contributions.

Quality gate:

- A reviewer should understand the research model by the end of page 1.

## Patch 3: Background compression

File:

- `sections/02-background.tex`

Actions:

1. Rename to `Background and Motivating Example`.
2. Keep only necessary CRuby and `RB_GC_GUARD` mechanics.
3. Preserve one motivating example.
4. Remove repeated evaluation or workflow claims.

Quality gate:

- Background should support the model, not compete with it.

## Patch 4: Model-first design section

File:

- `sections/03-design.tex`

Actions:

1. Rename to `Derive--Trigger--Use Model and Analysis`.
2. Define witness tuple `(o,p,d,t,u)`.
3. Add timeline figure.
4. Reorganize CodeQL details by model relation.
5. Keep at most one short example.
6. Cut pipeline/artifact/workflow detail.

Quality gate:

- The section reads as a model plus implementation, not a script manual.

## Patch 5: Evaluation restructure

File:

- `sections/04-evaluation.tex`

Actions:

1. Replace RQs.
2. Add overview table.
3. Add evidence matrix.
4. Add classification and family tables if space permits.
5. Add model-feedback taxonomy.
6. Add over-guarding interpretation.
7. Demote cross-release monitoring to supporting evidence.
8. Add ablation only if real values are available.

Quality gate:

- The evaluation should support the model, not just artifact reproducibility.

## Patch 6: Discussion and threats

File:

- `sections/05-discussion.tex`

Actions:

1. Keep research lessons.
2. Shorten adoption workflow to at most one paragraph or remove it.
3. Strengthen threats around single subject, curated model, macro-heavy C, bounded dynamic tests, manual classification.
4. Mention v4.0.4 release-monitoring result only as artifact/scalability limitation.

Quality gate:

- Limitations are honest but do not dominate the contribution.

## Patch 7: Related work rewrite

File:

- `sections/06-related-work.tex`

Actions:

1. Start with GC rooting and runtime hazard analyses.
2. Discuss Ugawa/Fujimoto immediately after SpiderMonkey.
3. Discuss Coccinelle, QL/CodeQL, UAF/dangling-pointer analyses, actionable-warning literature, CRuby memory-management engineering.
4. Add explicit distinction from UAF and explicit root registration.

Quality gate:

- Novelty is clear without overstating uniqueness.

## Patch 8: Conclusion rewrite

File:

- `sections/07-conclusion.tex`

Actions:

1. Remove `\vfill\break` unless final layout absolutely needs it.
2. Remove Engineering Track language.
3. Conclude with derive--trigger--use model and evidence.

Quality gate:

- The final paragraph should sound like a Research Track result.

## Patch 9: Artifact/data cleanup

Files:

- `repro/generated/redundant_guard_classification.csv`
- `repro/generated/performance_overguard_summary.csv`
- docs and artifact files
- query pack, if available

Actions:

1. Fix redundant CSV quoting.
2. Complete redundant-guard classification or downgrade claim.
3. Replace absolute local paths with relative/anonymized paths.
4. Add query pack or weaken reproducibility claims.

Quality gate:

- `python3 tools/claim_audit.py .` should produce no serious warnings, except accepted warnings documented in the paper/artifact README.

## Patch 10: Page budget and polish

Actions:

1. Compile fully with BibTeX.
2. Inspect page count.
3. Cut content until body ends by page 10.
4. Check no unresolved references/citations.
5. Search for identity leaks.
6. Run claim audit.

Likely cuts if over budget:

- Long macro expansion details.
- Artifact table.
- Cross-release setup.
- Detailed adoption workflow.
- Duplicate examples.
- Verbose threats.
- Redundant guard detail if not fully classified.
