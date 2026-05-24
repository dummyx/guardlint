# File-by-file rewrite plan

This plan assumes the current file layout is preserved. Keeping paths stable reduces patch risk.

## `main.tex`

### Required edits

1. Change title to:

```tex
\title{Derive--Trigger--Use: Static Detection of GC Guard Obligations in CRuby}
```

2. Remove or anonymize the full `\author{...}` block. For double-blind review, author names and affiliations must be omitted. A safe minimal form is:

```tex
\author{}
```

or comment out the author block and leave no visible author identity.

3. Replace the abstract with the Research Track abstract in `03_SECTION_BLUEPRINTS_AND_SNIPPETS.md`.

4. Replace keywords with:

```tex
\begin{IEEEkeywords}
source code analysis, static analysis, garbage collection, compiler liveness, CodeQL, runtime C, Ruby
\end{IEEEkeywords}
```

5. After all section edits, compile and revisit:

```tex
\newpage
\IEEEtriggeratref{13}
```

Do not retain these mechanically if they damage page budget or layout. The goal is content ending by page 10 and references on pages 11--12.

## `sections/01-introduction.tex`

### Replace the lead

The current lead starts with “Source-code analyses are often most effective when they capture project-specific maintenance rules.” That is too Engineering Track oriented.

Replace with a lead that says:

- GC runtimes written in C expose raw borrowed pointers.
- Correctness depends on keeping a managed-object owner visible to conservative GC/compaction across a GC-relevant operation.
- This is source-level and placement-sensitive.
- The paper proposes a derive--trigger--use witness model.

### Required content

The introduction should include:

1. A concise problem paragraph.
2. A research gap paragraph distinguishing this from ordinary UAF and generic rooting.
3. A model paragraph defining derive--trigger--use informally.
4. A results paragraph with the headline numbers.
5. A contribution list matching `01_RESEARCH_TRACK_POSITIONING.md`.

### Remove or demote

- Remove “The case study also offers reusable lessons...” unless replaced with a stronger research result sentence.
- Remove “reproducible CSV artifact and practical lessons” from the contribution list; artifact support belongs in evaluation/artifact statement, not core contribution.
- Remove “maintenance workflow” as the main identity.

### Suggested final paragraph before contributions

Use a sentence like:

```tex
The result is not a proof of guard correctness; it is a bounded witness generator for a source-level obligation that maintainers otherwise apply by inspection.
```

## `sections/02-background.tex`

### Rename section title

Use:

```tex
\section{Background and Motivating Example}
```

### Keep

- The terms table, possibly shortened.
- Explanation of `VALUE`, raw pointers, and `RB_GC_GUARD`.
- The point that `RB_GC_GUARD` must be placed after the last derived-pointer use.
- The point that a later owner use can be an anchor.
- One compact running example.

### Shorten

- Long discussion of compaction and general GC mechanics.
- Macro expansion detail, unless directly needed for why macro-aware recognition matters.
- Multiple failure-mode paragraphs that repeat the introduction.

### Add or emphasize

State explicitly:

```tex
The analysis target is not the existence of a guard macro in a function, but coverage of a vulnerable source interval: derivation before trigger, trigger before use, and guard or owner anchor after the use.
```

## `sections/03-design.tex`

### Rename section title

Use:

```tex
\section{Derive--Trigger--Use Model and Analysis}
\label{sec:model-analysis}
```

If existing references use `sec:design`, either preserve `\label{sec:design}` as an alias or update references.

### Restructure

Use these subsections:

```tex
\subsection{Guard Obligations as Witnesses}
\subsection{Coverage by Guards and Owner Anchors}
\subsection{CodeQL Realization}
\subsection{CRuby-Specific Models}
\subsection{Report Construction and Deduplication}
```

### Required model definition

Include a semi-formal definition:

```tex
A missing-guard witness is a tuple
$(o,p,d,t,u)$ where owner $o$ is a \texttt{VALUE}, raw pointer $p$ is derived
from $o$ at derivation site $d$, a GC-relevant trigger $t$ occurs after $d$,
$p$ is consumed at use site $u$ after $t$, and no recognized guard or owner
anchor covers the interval through $u$.
```

Then explain what each component means.

### Required figure

Add a simple timeline figure or table. If space is tight, use a small `figure` with `\fbox{\begin{minipage}...}` rather than a graphic file.

### Reorganize implementation

Do not explain CodeQL first. Explain the model first, then say the CodeQL realization maps each relation to predicates:

- derivation relation;
- trigger relation;
- consumer/use relation;
- guard recognition;
- owner-anchor recognition;
- limited interprocedural summaries;
- deduplication from raw witnesses to review sites.

### Cut or move

Move these to reproducibility docs or shorten heavily:

- `Pipeline`
- `Review Workflow and Artifact`
- Large file inventory tables
- Long artifact prose
- Multiple examples; keep at most one short example in design and one in evaluation.

## `sections/04-evaluation.tex`

### Rename opening

Keep `\section{Evaluation}`, but replace the current RQs with the four Research Track RQs.

### New structure

Use these subsections:

```tex
\subsection{Evaluation Questions and Data Sources}
\subsection{RQ1: Boundedness and Coverage}
\subsection{RQ2: Evidence of Real Defects}
\subsection{RQ3: Precision Limits}
\subsection{RQ4: Guard Necessity and Over-Guarding}
```

If an ablation study is added, include it under RQ1:

```tex
\subsubsection{Ablation of Model Components}
```

### RQ1 content

Include:

- 244 internal evidence rows.
- 40 unique potential missing-guard sites.
- 76 existing covering guard sites.
- 213 redundant-side model-feedback rows.
- CodeQL version and runtime if space permits.
- Derivation-family counts by site: string 20, array 12, other 6, typed_data 1, other|typed_data 1.

### RQ2 content

Use an evidence matrix and confirmed-sites table.

Evidence types:

- six bounded dynamic failures;
- three upstream corroborated sites;
- four historical replays;
- three optimized-code witnesses;
- full manual classification;
- over-guarding stress experiment as supporting motivation, not defect proof.

### RQ3 content

Turn false positives into a taxonomy of precision limits. Use classification/model-feedback files.

Key categories:

- later owner re-anchor;
- receiver owner liveness;
- pointer reassignment before use;
- caller-slot owner anchor;
- owner identity mismatch;
- pointer arithmetic completed before trigger;
- same-call owner anchor;
- receiver alias/return anchor;
- non-owning typed-data payload.

### RQ4 content

Connect:

- Ruby documentation: guard placement and optimization reason.
- optimized-code witnesses: compiler mechanism.
- dynamic failures: safety consequence.
- over-guarding benchmark: cost of blanket strategy.

Phrase the 6.99% result as a stress experiment, not a per-site cost estimate.

### Demote cross-release material

The v4.0.4 release-monitoring run should not be a main RQ. Move it to threats/artifact limitations:

```tex
The artifact also records cross-release database construction and guard inventories. The witness-sensitive v4.0.4 queries completed in this run, so we do treat cross-release matching as release-monitoring evidence.
```

## `sections/05-discussion.tex`

### Keep

- Lessons for source-code analysis, but make them research lessons.
- Threats to validity.
- Future work.

### Remove or shorten

- Detailed adoption workflow.
- CSV/file workflow prose.
- Engineering Track framing.

### Required threat statements

Include:

- single-runtime/single-version subject;
- curated CRuby-specific model;
- intentionally incomplete trigger/consumer/alias modeling;
- macro-heavy C and CodeQL extraction limitations;
- dynamic validation is bounded;
- manual classification is judgment-based;
- over-guarding result is a broad stress test;
- artifact may need query pack inclusion/anonymization.

## `sections/06-related-work.tex`

### New order

1. GC rooting and runtime hazard analyses.
2. Ugawa/Fujimoto on local-variable GC registration with Coccinelle.
3. Coccinelle and semantic source transformations.
4. QL/CodeQL and declarative source-code querying.
5. UAF/dangling-pointer/memory-safety analyses.
6. Actionable static-analysis warning work.
7. CRuby memory-management engineering.

### Required distinction sentence

Use a sentence like:

```tex
Unlike ordinary use-after-free analyses, the relevant object is not explicitly freed by the source program; the failure is mediated by GC activity, compiler-visible owner liveness, and a borrowed raw pointer that survives across a trigger.
```

## `sections/07-conclusion.tex`

### Required edits

- Remove `\vfill\break` unless final layout requires it.
- Remove “Engineering Track value”.
- Conclude with the research result.

Suggested conclusion shape:

1. One sentence restating the problem and model.
2. One sentence summarizing evidence.
3. One sentence stating the broader lesson.

Example:

```tex
This paper shows that CRuby's GC guard discipline can be treated as a placement-sensitive source-code analysis problem. A derive--trigger--use model condenses raw pointer, trigger, use, guard, and owner-anchor facts into a bounded review queue, and the CRuby evaluation provides dynamic, upstream, historical, optimized-code, and performance evidence for the model's relevance. The broader result is that compiler-liveness-dependent runtime conventions can be made reviewable without claiming whole-program soundness or relying on blanket source transformations.
```

## `README.md`, `REPRODUCIBILITY.md`, `repro/README.md`

### Anonymization and artifact cleanup

- Remove names/emails if these docs are included in the double-blind artifact.
- Remove local paths like `/home/x17/...` or replace with relative paths.
- Ensure the query pack is present or state explicitly that generated outputs are included but query sources are omitted from the anonymized package.
- Update instructions to reflect the Research Track framing.
