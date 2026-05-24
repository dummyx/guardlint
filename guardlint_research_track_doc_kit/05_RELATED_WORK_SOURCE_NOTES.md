# Related work and SCAM-style source notes

This file guides the related-work rewrite and the Research Track style. It includes source notes and positioning arguments. Add citations to the paper only when the cited work is discussed in the paper body.

## SCAM Research Track style notes

Official SCAM Research Track pages describe the track as soliciting original and significant work in source-code analysis/manipulation and evaluating papers for novelty, quality, importance, evaluation, and scientific rigor. They list static/dynamic analysis, security vulnerability analysis, source-level testing/verification, source-level optimization, and repository/change analysis as relevant topics.

Use this as a writing constraint, not as a paper citation. The paper should not say “SCAM wants...”. Instead, the paper should demonstrate novelty and rigor through model, evaluation, and related-work positioning.

Source URLs for agent context:

- SCAM 2026 Research Track: https://conf.researchr.org/track/scam-2026/scam-2026-research-track
- SCAM 2025 Research Track: https://conf.researchr.org/track/scam-2025/scam-2025-research-track

## Recent SCAM Research Track pattern to imitate

### UnCheckGuard: exception-related behavioral breaking changes

Source:

- IEEE CSDL entry: https://www.computer.org/csdl/proceedings-article/scam/2025/969800a001/2aHoJqhkwxi
- Artifact repository found during review: https://github.com/vinayaksh42/UnCheckGuard-docker

Useful pattern:

- Starts from a broad semantic problem.
- Narrows it to a tractable source-level witness class.
- Uses static analysis and filtering to reduce false positives.
- Evaluates reports empirically.
- Provides artifact support.

How to map this pattern to GuardLint:

| SCAM-style pattern | GuardLint paper equivalent |
|---|---|
| Broad semantic problem | GC/rooting/lifetime failures in C runtimes are hard |
| Tractable witness class | derive--trigger--use GC guard witnesses |
| Filtering | owner anchors, guard coverage, macro role binding, consumer/trigger models |
| Evaluation | 40-site classification, dynamic failures, upstream fixes, historical replay, optimized-code witnesses |
| Artifact | scripts, generated CSVs, query pack if added, reproducibility docs |

Do not overdo this comparison in the paper. It can inform structure without being named.

## Closest related work: CRuby documentation and guard semantics

### Ruby `RB_GC_GUARD` documentation

Source:

- Current C API docs: https://docs.ruby-lang.org/capi/en/master/dc/d18/memory_8h.html
- Extension docs example: https://docs.ruby-lang.org/en/3.0/extension_rdoc.html#label-RB_GC_GUARD+to+protect+from+premature+GC

Safe claims:

- CRuby documents `RB_GC_GUARD` as a mechanism to keep a `VALUE` visible to conservative GC.
- The documentation states that optimizing C compilers may optimize away the original `VALUE` even if later code depends on data associated with it.
- The documentation's example places `RB_GC_GUARD` after the last use of the derived pointer and says earlier placement is ineffective.
- The documentation contrasts `RB_GC_GUARD` with volatile and notes optimization concerns.

How to cite/position:

- Use this in Background, not Related Work.
- It supports the claim that the obligation is documented and placement-sensitive.
- It supports the claim that blanket volatile-like guarding is not free.

Suggested sentence:

```tex
CRuby's documentation explicitly describes `RB_GC_GUARD` as a source-level use that must occur after the last derived-pointer use; a guard before that use does not cover the vulnerable interval.
```

## Closest related work: SpiderMonkey hazard analysis

Source:

- Firefox Source Docs: https://firefox-source-docs.mozilla.org/js/HazardAnalysis/index.html

Safe claims:

- SpiderMonkey has static analyses for rooting and heap-write hazards.
- The analysis is used as part of production development workflows.
- The documentation describes rooting hazards and repairs such as using `Rooted` types.

Positioning:

- This is the closest runtime-engineering analogue.
- Both encode GC-related source-code obligations.
- Difference: SpiderMonkey checks a rooted/handle discipline; GuardLint checks CRuby's placement-sensitive `RB_GC_GUARD` convention for borrowed raw pointers and compiler-visible owner liveness.

Suggested paragraph:

```tex
A close runtime-engineering analogue is SpiderMonkey's rooting and heap-write hazard analysis. Both systems encode GC-related source-code rules to make runtime maintenance reviewable. The models differ: SpiderMonkey checks a rooting/handle discipline, whereas GuardLint checks CRuby's placement-sensitive `RB_GC_GUARD` convention for raw pointers derived from managed objects.
```

## Closest academic GC-rooting paper: Ugawa and Fujimoto

Source:

- J-STAGE page: https://www.jstage.jst.go.jp/article/ipsjjip/28/0/28_169/_article
- Existing BibTeX key in the repository: `UgawaFujimoto2020JIP`

Safe claims:

- The paper studies accurate GC in a VM implemented in C.
- Local C variables may contain pointers that belong to the root set.
- The approach checks whether variables are added/removed correctly using pattern matching against control-flow graphs.
- It found missed and redundant additions.

Positioning:

- Very relevant; discuss before generic use-after-free work.
- Difference: their setting is explicit root registration/removal; GuardLint's setting is a compiler-liveness-dependent guard placement for borrowed raw pointers, with owner anchors and macro-expanded guard forms.

Suggested paragraph:

```tex
Ugawa and Fujimoto use Coccinelle to find missing and redundant registrations of local variables for accurate GC in a C virtual machine. Their analysis checks explicit add/remove operations for root-table registration. GuardLint instead analyzes a source-level guard convention: the owner may remain logically reachable, but a borrowed raw pointer can outlive the compiler-visible owner unless a later guard or anchor covers the interval.
```

## Coccinelle and semantic source transformations

Source:

- Padioleau et al., EuroSys 2008. Existing BibTeX key: `coccinelle_eurosys2008`.
- DOI: https://doi.org/10.1145/1352592.1352618

Safe claims:

- Coccinelle provides semantic patches for documenting and automating source transformations in Linux device drivers.
- It is a source-level tool for recurring C maintenance patterns.

Positioning:

- Coccinelle is relevant because GuardLint also encodes a recurring source-level maintenance rule.
- Difference: GuardLint produces reviewable lifetime witnesses, not automatic source transformations. Its over-guarding transformation is an experiment, not a recommended repair.

Suggested sentence:

```tex
Unlike semantic-patch systems, GuardLint's primary output is not a patch but a witness tying together derivation, trigger, use, and missing coverage.
```

## QL/CodeQL as substrate

Sources:

- QL paper: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ECOOP.2016.2
- CodeQL official site: https://codeql.github.com/
- GitHub CodeQL docs: https://docs.github.com/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning-with-codeql
- Existing BibTeX key: `ql_ecoop`

Safe claims:

- QL is a declarative language for querying complex, recursive data structures; it compiles to Datalog and has been used for static analyses that scale to large code bases.
- CodeQL treats code as data and supports custom analysis queries.

Positioning:

- CodeQL is not the contribution.
- The contribution is the CRuby guard-obligation model and evaluation.
- Avoid spending much paper space explaining CodeQL basics.

Suggested sentence:

```tex
GuardLint uses CodeQL as a declarative source-analysis substrate; the contribution is the obligation model and CRuby-specific semantics rather than the query language itself.
```

## Use-after-free and dangling-pointer analyses

Existing BibTeX keys in repository:

- `static_analysis_use_after_free_cpp`
- `spatio_temporal_context_reduction`
- `static_analysis_dangling_pointer`

Safe positioning:

- These works target explicit deallocation/dangling pointer memory-safety defects.
- GuardLint targets a different mechanism: a GC-managed owner may become compiler-invisible or moved/reclaimed while a raw borrowed pointer remains in use.

Required distinction sentence:

```tex
Unlike ordinary use-after-free analyses, the relevant object is not explicitly freed by the source program; the failure is mediated by GC activity, compiler-visible owner liveness, and a borrowed raw pointer that survives across a trigger.
```

## Actionable static-analysis warnings and industrial bug finding

Existing BibTeX keys:

- `bessey2010fewbillion`
- `static_driver_verifier`
- `sate_home`
- `sate_v`
- `ruthruff2008actionable`
- `christakis2016developers`
- `imtiaz2019coverity`

Safe positioning:

- This literature motivates treating static-analysis outputs as warnings requiring classification and actionability analysis.
- GuardLint follows this by separating confirmed defects, plausible candidates, likely false positives, and model-feedback cases.

Suggested sentence:

```tex
Our evaluation follows warning-assessment practice by treating reports as review candidates, separating confirmation evidence from plausibility, and recording model-feedback cases rather than treating all warnings as bugs.
```

## CRuby memory-management engineering

Existing BibTeX key:

- `ismm2025_cruby`

Safe positioning:

- Recent work studies CRuby memory-management redesign/practitioner issues.
- GuardLint is complementary: it reviews a specific existing guard discipline rather than redesigning allocation/GC interfaces.

## Suggested related-work section structure

Use this order:

1. GC rooting and runtime hazard analyses.
2. Source-level maintenance patterns and semantic patching.
3. Declarative source-code querying and CodeQL.
4. Memory-safety/UAF analyses.
5. Actionable static-analysis warning work.
6. CRuby memory-management engineering.

Target length: about one page.

## References that are already present

The uploaded `references.bib` already appears to contain:

- `ruby_capi_rb_gc_guard`
- `gchandbook`
- `ql_ecoop`
- `spidermonkey_hazard_analysis`
- `coccinelle_eurosys2008`
- `UgawaFujimoto2020JIP`
- `static_analysis_use_after_free_cpp`
- `spatio_temporal_context_reduction`
- `static_analysis_dangling_pointer`
- `bessey2010fewbillion`
- `static_driver_verifier`
- `sate_home`
- `sate_v`
- `ruthruff2008actionable`
- `christakis2016developers`
- `imtiaz2019coverity`
- `ismm2025_cruby`

Add only missing references that the final text actually cites.
