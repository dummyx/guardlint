# Section blueprints and reusable LaTeX snippets

The snippets below are intended for adaptation. They are not mandatory verbatim text, but they provide a safe Research Track framing.

## Abstract replacement

```tex
\begin{abstract}
Garbage-collected language runtimes written in C often expose raw pointers into managed objects. These pointers can outlive the compiler-visible owner variable: the object may remain logically reachable, but the C local that keeps the garbage collector aware of the owner may be optimized away before a later allocation, compaction point, callback, or other GC-relevant operation. In CRuby, \verb|RB_GC_GUARD| is the source-level mechanism for preserving such owners, but deciding where guards are required is a placement-sensitive static-analysis problem.

We present GuardLint, a witness-oriented static analysis that models this obligation as a derive--trigger--use relation. A warning consists of a raw pointer derived from a Ruby object, a later GC-relevant trigger, and a post-trigger use of the pointer without a covering owner anchor or guard. The analysis is implemented in CodeQL and models CRuby-specific borrowing APIs, macro-expanded guard forms, wrapper calls, owner anchors, and selected interprocedural consumers.

On CRuby 3.4.5, GuardLint reports 40 potential missing-guard sites from 244 internal evidence rows, recognizes 76 covering guard sites, and reports 213 redundant-side model-feedback rows. Validation combines full manual classification, six bounded dynamic failures, three later upstream fixes, four historical replays, three optimized-code witnesses, and an over-guarding stress experiment showing a 6.99\% geometric-mean slowdown. The results show that compiler-liveness-dependent GC guard placement can be made reviewable with a narrow source-level model, while also exposing why blanket guarding is not an adequate substitute for analysis.
\end{abstract}
```

## Introduction blueprint

Target length: about 1 page.

Paragraph 1: problem.

```tex
Garbage-collected runtimes implemented in C often cross an uncomfortable boundary: runtime objects are managed by a collector, but optimized C code manipulates ordinary raw pointers into those objects. In CRuby, a local \verb|VALUE| can own string bytes, array elements, or extension data, while C code may borrow a \verb|char *|, element pointer, or native payload pointer from that owner. If a later operation can allocate, compact, run Ruby code, or enter a callback, the borrowed pointer remains safe only if the owner remains visible to the collector through the last pointer use.
```

Paragraph 2: why the problem is source-analysis-specific.

```tex
This obligation is not a conventional C use-after-free trace. The source program need not explicitly deallocate the object, and another Ruby-level reference may keep the object logically reachable. The failure can instead arise because the compiler no longer materializes the owner variable at a GC-relevant point, or because compaction can update managed references but not a previously borrowed C pointer. Guard placement is therefore a source-level, placement-sensitive obligation: the relevant facts are where a raw pointer is derived, where a GC-relevant trigger can occur, where the pointer is later used, and whether a guard or owner anchor covers that interval.
```

Paragraph 3: model.

```tex
We model this obligation as a derive--trigger--use witness. A warning records an owner object, a raw pointer derived from it, a later GC-relevant trigger, and a post-trigger pointer use with no recognized covering guard or owner anchor. The model is deliberately narrower than whole-program lifetime analysis. It aims to produce reviewable witnesses for a documented runtime convention rather than prove absence of all guard bugs.
```

Paragraph 4: implementation and results.

```tex
We implement the model in GuardLint, a CodeQL analysis for CRuby's macro-heavy C code. The implementation models CRuby-specific derivation APIs, GC-relevant trigger families, pointer consumers, macro-expanded guard forms, selected wrapper functions, limited interprocedural consumers, and owner anchors. On a CRuby 3.4.5 database, GuardLint emits 244 internal missing-detail evidence rows that condense to 40 unique potential missing-guard sites. It also recognizes 76 covering guard sites justified by the model and reports 213 redundant-side model-feedback rows.
```

Paragraph 5: validation.

```tex
The evaluation combines several independent forms of evidence: full manual classification of the 40 reported sites, six bounded dynamic failures, three later upstream fixes, four historical replays of accepted guard additions, three optimized-code witnesses, and an over-guarding stress experiment over 68 ruby-bench workloads. These sources do not make the analysis sound or complete; they show that the witness model exposes real guard obligations while keeping the review queue bounded.
```

Contribution list: use the contribution list in `01_RESEARCH_TRACK_POSITIONING.md`.

## Model section snippet

```tex
\subsection{Guard Obligations as Witnesses}

We define a missing-guard witness as a tuple $(o,p,d,t,u)$. The owner $o$ is a \verb|VALUE| whose managed object owns memory borrowed by C code. The raw pointer $p$ is derived from $o$ at derivation site $d$. A trigger $t$ is a later operation that may permit GC activity, compaction, Ruby callback execution, or allocation. A use $u$ is a post-trigger consumption of $p$, such as a dereference, a call argument to a consumer, or a modeled wrapper use. The source order must satisfy $d < t < u$.

A witness becomes reportable when no recognized guard or owner anchor covers the vulnerable interval through $u$. A guard is a source-level use such as \verb|RB_GC_GUARD(o)| placed after the last vulnerable pointer use. An owner anchor is another modeled source use that keeps $o$ visible after the trigger and through the relevant use. GuardLint therefore checks not merely whether a function contains a guard, but whether the guard or anchor covers a specific derive--trigger--use interval.
```

## Timeline figure snippet

```tex
\begin{figure}[t]
\centering
\fbox{%
\begin{minipage}{0.92\linewidth}
\scriptsize
\centering
\texttt{derive $p$ from owner $o$ at $d$}
$\quad < \quad$
\texttt{GC-relevant trigger $t$}
$\quad < \quad$
\texttt{post-trigger use $u$ of $p$}
\vspace{2pt}

Report if no \texttt{RB\_GC\_GUARD($o$)} or modeled owner anchor covers the interval through $u$.
\end{minipage}}
\caption{Derive--trigger--use witness for a missing GC guard obligation.}
\label{fig:dtu-witness}
\end{figure}
```

## RQ block snippet

```tex
We evaluate GuardLint with four questions:

\begin{description}
\item[RQ1] Can a derive--trigger--use model produce a bounded, inspectable set of GC guard obligations in a production C runtime?
\item[RQ2] How much independent evidence supports the reported missing-guard obligations?
\item[RQ3] What false-positive and model-feedback patterns arise, and what do they reveal about source-level GC guard analysis?
\item[RQ4] What mechanism evidence explains why guards are needed, and what cost evidence explains why indiscriminate guarding is not an adequate substitute?
\end{description}
```

## RQ1 result table snippet

```tex
\begin{table}[t]
\caption{GuardLint results on CRuby 3.4.5.}
\label{tab:result-overview}
\centering
\scriptsize
\begin{tabular}{@{}lrrl@{}}
\toprule
Result class & Raw rows & Unique sites & Role \\
\midrule
Missing-guard detail & 244 & 40 & derive--trigger--use evidence \\
Potential missing guards & 40 & 40 & deduplicated review queue \\
Recognized covering guards & 76 & 76 & positive coverage check \\
Redundant-side reports & 213 & 213 & model-feedback guard queue \\
\bottomrule
\end{tabular}
\end{table}
```

## Derivation family table snippet

Use site-level counts from `missing_classification.csv`:

```tex
\begin{table}[t]
\caption{Potential missing-guard sites by derivation family.}
\label{tab:derivation-families}
\centering
\scriptsize
\begin{tabular}{@{}lr@{}}
\toprule
Derivation family & Sites \\
\midrule
String-related & 20 \\
Array-related & 12 \\
Other & 6 \\
Typed data & 1 \
Other / typed-data combination & 1 \\
\bottomrule
\end{tabular}
\end{table}
```

## Evidence matrix snippet

```tex
\begin{table}[t]
\caption{Independent evidence used to validate missing-guard reports.}
\label{tab:evidence-matrix}
\centering
\scriptsize
\begin{tabular}{@{}p{0.28\linewidth}rp{0.44\linewidth}@{}}
\toprule
Evidence type & Count & Interpretation \\
\midrule
Full manual classification & 40 sites & Every unique report was inspected and categorized. \\
Bounded dynamic failures & 6 sites & Reported sites can produce crash or corruption under stress harnesses. \\
Later upstream fixes & 3 sites & Maintainers later added corresponding guards or accepted fixes. \\
Historical replay & 4 fixes & Pre-fix revisions are reported and post-fix revisions drop the repaired variable. \\
Optimized-code witnesses & 3 sites & Generated code demonstrates the compiler-liveness mechanism. \\
Over-guarding stress experiment & 68 workloads & Blanket guarding caused a 6.99\% geometric-mean slowdown. \\
\bottomrule
\end{tabular}
\end{table}
```

## Confirmed dynamic failures table snippet

```tex
\begin{table}[t]
\caption{Bounded dynamic failures for reported missing-guard sites.}
\label{tab:dynamic-failures}
\centering
\scriptsize
\begin{tabular}{@{}lll@{}}
\toprule
Case & File/function & Outcome \\
\midrule
\texttt{open\_key\_args} & \texttt{io.c} / \texttt{open\_key\_args} & crash \\
\texttt{io\_buffer\_set\_string} & \texttt{io\_buffer.c} / \texttt{io\_buffer\_set\_string} & crash \\
\texttt{arith\_seq\_inspect} & \texttt{enumerator.c} / \texttt{arith\_seq\_inspect} & corruption \\
\texttt{append\_method} & \texttt{enumerator.c} / \texttt{append\_method} & corruption \\
\texttt{str\_transcode0} & \texttt{transcode.c} / \texttt{str\_transcode0} & corruption \\
\texttt{rb\_str\_format\_m} & \texttt{string.c} / \texttt{rb\_str\_format\_m} & crash \\
\bottomrule
\end{tabular}
\end{table}
```

## Classification table snippet

From `missing_classification.csv`:

```tex
\begin{table}[t]
\caption{Manual classification of 40 potential missing-guard sites.}
\label{tab:missing-classification}
\centering
\scriptsize
\begin{tabular}{@{}lr@{}}
\toprule
Classification & Sites \\
\midrule
Confirmed & 6 \\
Strong candidate & 1 \\
Plausible candidate & 26 \\
Likely false positive / model feedback & 7 \\
\bottomrule
\end{tabular}
\end{table}
```

## Model-feedback taxonomy snippet

```tex
\begin{table}[t]
\caption{Recurring precision limits found during site classification.}
\label{tab:model-feedback}
\centering
\scriptsize
\begin{tabular}{@{}p{0.34\linewidth}p{0.56\linewidth}@{}}
\toprule
Pattern & Interpretation \\
\midrule
Later owner re-anchor & A later use, return, or reinitialization appears to keep the owner visible, but proving coverage requires stronger path-sensitive reasoning. \\
Receiver owner liveness & Receiver-like values may be anchored by calling convention or API contract, but a blanket receiver rule would hide real obligations. \\
Pointer reassignment & The reported post-trigger access overwrites the pointer rather than reading or escaping the old borrowed pointer. \\
Caller-slot owner anchor & A caller-owned \texttt{VALUE *} slot appears to keep the original owner visible outside the local variable. \\
Owner-identity mismatch & The reported owner is an allocation target or alias expression, not the owner from which the raw pointer was derived. \\
Same-call owner anchor & Owner, trigger, and modeled pointer use occur within the same enclosing call expression. \\
\bottomrule
\end{tabular}
\end{table}
```

## Related work paragraph snippet

```tex
The closest runtime analyses are GC-rooting and hazard analyses. SpiderMonkey's hazard analysis detects rooting hazards in which unrooted values remain live across GC-capable calls, and its usual repair is to use rooted handle types. GuardLint targets a different source-level convention in CRuby: a borrowed raw pointer may cross a GC-relevant trigger while the managed owner is no longer compiler-visible, and the intended repair is often a placement-sensitive \verb|RB_GC_GUARD|. Ugawa and Fujimoto similarly study missing and redundant GC-root registrations in C virtual-machine code using control-flow pattern matching. Their setting concerns explicit registration and removal of local roots, whereas GuardLint models compiler-liveness-dependent guard placement for borrowed raw pointers and owner anchors.
```

## Conclusion snippet

```tex
This paper shows that CRuby's GC guard discipline can be treated as a placement-sensitive source-code analysis problem. A derive--trigger--use model condenses raw-pointer derivations, GC-relevant triggers, post-trigger uses, guards, and owner anchors into a bounded review queue, and the CRuby evaluation provides dynamic, upstream, historical, optimized-code, and performance evidence for the model's relevance. The broader result is that compiler-liveness-dependent runtime conventions can be made reviewable without claiming whole-program soundness or relying on blanket source transformations.
```
