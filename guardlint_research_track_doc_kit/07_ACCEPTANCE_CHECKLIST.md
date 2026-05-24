# Final acceptance checklist for the rewrite

Use this checklist before returning the rewritten paper.

## Framing

- [ ] Title foregrounds derive--trigger--use, witness-oriented analysis, or source-level GC guard obligations.
- [ ] Abstract opens with the research problem, not the tool.
- [ ] Introduction states a research gap and thesis by the end of the first page.
- [ ] Contributions are research contributions, not artifact/workflow bullets.
- [ ] GuardLint is presented as an implementation of the model.
- [ ] The conclusion does not mention Engineering Track value.

## Model clarity

- [ ] The paper defines owner, raw pointer, derivation, trigger, post-trigger use, guard, anchor, and witness.
- [ ] The report condition is stated as derive before trigger before use, with no covering guard/anchor.
- [ ] The paper explains that placement matters.
- [ ] The paper distinguishes guard coverage from mere presence of `RB_GC_GUARD` in a function.
- [ ] The paper avoids claiming whole-program soundness.

## Evaluation rigor

- [ ] Evaluation uses RQ1--RQ4 or equivalent research questions.
- [ ] RQ1 reports boundedness: 244 internal evidence rows -> 40 guard-obligation sites.
- [ ] RQ1 reports recognized covering guards: 76.
- [ ] RQ1 reports 213 redundant-side model-feedback rows, with the audited-subset limitation handled honestly.
- [ ] RQ2 includes evidence matrix or equivalent structured validation.
- [ ] RQ2 distinguishes dynamic failures, upstream fixes, historical replay, optimized-code witnesses, and manual classification.
- [ ] RQ3 presents false positives/model feedback as structured precision limits.
- [ ] RQ4 explains guard necessity and over-guarding cost without overclaiming.
- [ ] Cross-release release-monitoring material is not a main result.
- [ ] Optional but preferred: ablation study is included with real generated numbers.

## Numeric claim audit

- [ ] All numeric claims match `repro/generated` data or are explicitly regenerated.
- [ ] `missing_classification.csv` classification counts are correct: 6 confirmed, 1 strong candidate, 26 plausible candidate, 7 likely false positive/model feedback.
- [ ] Site-level derivation family counts are correct: 20 string, 12 array, 6 other, 1 typed_data, 1 other|typed_data.
- [ ] Dynamic failures count is six.
- [ ] Upstream corroboration count is three.
- [ ] Historical replay count is four.
- [ ] Optimized-code witness count is three.
- [ ] Over-guarding experiment says 68 matched workloads and 6.99% geomean slowdown.
- [ ] No claim says all 213 redundant-side rows were classified unless the CSV is fixed and completed.

## Related work

- [ ] Related work leads with GC rooting/runtime hazard analysis, not generic UAF.
- [ ] SpiderMonkey hazard analysis is compared precisely.
- [ ] Ugawa/Fujimoto is discussed as close academic GC-rooting work.
- [ ] Coccinelle is discussed as semantic source transformation/maintenance, not as a direct competitor.
- [ ] QL/CodeQL is substrate, not contribution.
- [ ] UAF/dangling-pointer analyses are distinguished by explicit deallocation versus GC/compiler-liveness mechanism.
- [ ] Actionable-warning literature is used to justify classification/evidence treatment.

## Double-blind compliance

- [ ] No author names in PDF.
- [ ] No affiliations in PDF.
- [ ] No emails in PDF.
- [ ] No local usernames or absolute home paths in submitted artifact.
- [ ] Self-citations, if any, are in third person.
- [ ] PDF metadata does not reveal author identity if controllable.

## Artifact consistency

- [ ] Query pack is included or claims are weakened.
- [ ] Reproduction README matches paper claims.
- [ ] Generated output files used by tables are present.
- [ ] `redundant_guard_classification.csv` is valid CSV.
- [ ] Performance summary uses relative or anonymized paths.
- [ ] The artifact states dynamic PoCs are bounded demonstrations.

## Page/layout

- [ ] Paper compiles without unresolved references or citations.
- [ ] Tables fit in IEEE two-column layout.
- [ ] Content ends by page 10.
- [ ] References fit in pages 11--12.
- [ ] No excessive `\vspace`/font shrinking is used to hide overflow.
- [ ] `\vfill\break`, `\newpage`, and `\IEEEtriggeratref` are justified by final layout.

## Language quality

- [ ] Avoids “project-specific maintenance rule” as the lead identity.
- [ ] Avoids “automatic repair” language.
- [ ] Avoids “proved” unless tied to a specific formal statement, which this paper likely does not have.
- [ ] Uses “review candidate”, “corroboration”, “bounded”, “witness”, and “model-feedback” consistently.
- [ ] Keeps limitations visible but not self-defeating.
