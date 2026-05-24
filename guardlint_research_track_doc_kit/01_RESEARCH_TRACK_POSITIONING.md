# Research Track positioning guide

## Target identity of the paper

The paper should read as a Research Track contribution in source-code analysis, not as an Engineering Track case study.

Current identity to replace:

> GuardLint is a useful CodeQL tool and workflow for CRuby maintainers.

Target identity:

> GuardLint instantiates a derive--trigger--use source-code analysis model for compiler-liveness-dependent GC guard obligations. CRuby is the production runtime used to evaluate the model.

## Core research claim

Use this claim as the backbone of the paper:

> Compiler-liveness-dependent GC guard obligations can be modeled as derive--trigger--use witnesses over source code. This model produces a bounded, reviewable set of obligations in a production runtime, exposes real defects, and shows that over-guarding is not an adequate substitute for analysis.

This claim is research-facing because it defines a class of source-code analysis problem and evaluates a model, rather than merely reporting a tool.

## Research gap

The gap is not “CRuby needs a tool.” The gap is:

1. Garbage-collected runtimes written in C often expose raw pointers into managed objects.
2. Existing C source code can contain a logical owner, but the compiler may no longer keep that owner visible at a GC-relevant point.
3. The correctness obligation depends on source placement: derivation, later GC trigger, post-trigger pointer use, and later owner guard/anchor.
4. This differs from ordinary use-after-free analysis because the object may not be explicitly freed by source code; the failure is mediated by GC and compiler-visible owner liveness.
5. This differs from ordinary rooting analyses because CRuby uses a placement-sensitive source-level guard idiom rather than a uniform rooted-handle discipline.

## Suggested title

Preferred:

> Derive--Trigger--Use: Static Detection of GC Guard Obligations in CRuby

Acceptable alternatives:

> A Witness-Oriented Static Analysis for Compiler-Liveness GC Guards

> Source-Level Analysis of Garbage-Collector Guard Obligations in CRuby

Avoid:

> GuardLint: Source Code Analysis for Garbage Collector Guard Obligations in CRuby

The old title foregrounds the tool. Research Track reviewers should see the model first.

## Contribution list to use

Use a contribution list close to this one:

1. **A source-level model of GC guard obligations.** Formulate CRuby's `RB_GC_GUARD` discipline as a derive--trigger--use obligation over managed-object owners, borrowed raw pointers, GC-relevant triggers, post-trigger uses, owner anchors, and guard coverage.

2. **A static analysis for macro-heavy runtime C code.** Implement the model in CodeQL for CRuby, including CRuby-specific derivation APIs, guard forms, wrapper calls, selected interprocedural consumers, owner anchors, and deduplication from raw witnesses to reviewable sites.

3. **An empirical evaluation on a production language runtime.** On CRuby 3.4.5, report 40 potential missing-guard sites from 244 internal evidence rows, recognize 76 covering guard sites, and report 213 redundant-side model-feedback rows.

4. **A multi-evidence validation of reported obligations.** Validate reports using full manual classification, six bounded dynamic failures, three later upstream fixes, four historical replays of accepted fixes, three optimized-code witnesses, and an over-guarding stress experiment.

5. **A taxonomy of precision limits.** Identify recurring model-feedback patterns, including owner re-anchoring, receiver liveness, caller-slot anchors, pointer rebinding, owner-identity mismatches, same-call owner anchors, and non-owning typed-data payloads.

If space is tight, combine contributions 4 and 5.

## Target abstract structure

The abstract should have three paragraphs:

1. Problem: C runtimes, managed objects, raw pointers, compiler-visible owner liveness, placement-sensitive guards.
2. Approach: GuardLint as derive--trigger--use witness analysis in CodeQL, with guard/anchor coverage.
3. Results: 40 sites, 244 internal evidence rows, 76 covering guard sites, 213 redundant-side model-feedback rows, six failures, three upstream fixes, four replays, three assembly witnesses, 6.99% slowdown.

Do not cite papers in the abstract. Do not claim soundness or completeness.

## Research questions

Use these RQs instead of the current engineering/release-oriented ones:

- **RQ1. Boundedness and coverage.** Can a derive--trigger--use model produce a bounded, inspectable set of GC guard obligations in a production C runtime?
- **RQ2. Evidence of real defects.** How much independent evidence supports the reported missing-guard obligations?
- **RQ3. Precision limits.** What false-positive and model-feedback patterns arise, and what do they reveal about source-level GC guard analysis?
- **RQ4. Guard necessity versus over-guarding.** What mechanism evidence explains why guards are needed, and what cost evidence explains why indiscriminate guarding is not an adequate substitute?

## Claims that reviewers should remember

By the end of page 1, reviewers should know:

- The analysis target is a placement-sensitive lifetime obligation, not a generic UAF pattern.
- The core abstraction is derive--trigger--use.
- The paper intentionally produces reviewable witnesses, not proofs or automatic patches.
- The empirical evidence is unusually broad for a narrow static analysis: classification, dynamic failures, upstream fixes, historical replay, optimized-code witnesses, performance stress test.

## Claims to avoid

Do not claim:

- GuardLint is sound.
- GuardLint finds all missing guards.
- Any site without a dynamic failure is safe or unsafe.
- Redundant guards can be automatically removed.
- Over-guarding slowdown is the cost of any individual guard.
- CRuby results automatically generalize to all GC runtimes.

Preferred language:

- “review candidate” instead of “bug” unless confirmed.
- “corroborates” instead of “proves.”
- “bounded dynamic failure” instead of “complete dynamic validation.”
- “stress experiment” instead of “performance model.”
- “single-subject evaluation” instead of “general result across runtimes.”

## SCAM Research Track fit

The fit argument should remain implicit in the paper, but it should guide writing:

- The topic is source-code analysis and manipulation.
- The paper describes original/significant work, not just a process.
- The evaluation must demonstrate novelty, quality, importance, and scientific rigor.
- The research artifact should be reproducible enough for reviewers.

Do not mention SCAM reviewing criteria in the paper body. Use them only to guide framing and quality control.
