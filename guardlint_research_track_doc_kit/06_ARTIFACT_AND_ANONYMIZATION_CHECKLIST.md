# Artifact and anonymization checklist

The SCAM Research Track uses double-blind review. The paper and any submitted artifact must not reveal author identity.

## Paper anonymization

Check these files:

- `main.tex`
- `README.md`
- `REPRODUCIBILITY.md`
- `repro/README.md`
- `repro/NUMBER_TRACEABILITY.md`
- all generated `.csv`, `.json`, `.md` files if bundled
- scripts and shell files
- any `qlpack.yml`, `.ql`, `.qll`, or query README files if added

Remove or anonymize:

- author names;
- affiliations;
- email addresses;
- local usernames;
- home-directory paths;
- institution-specific build paths;
- comments that identify the authors;
- self-citations phrased in first person.

## Known author-identifying current content

`main.tex` currently contains author names, affiliations, and emails. Remove this for Research Track submission.

`repro/generated/performance_overguard_summary.csv` currently contains local paths such as `/home/x17/code_repo/...`. Replace with relative paths or anonymized placeholders before packaging artifacts.

Search commands:

```sh
grep -RInE 'Zhijie|Xie|Hidehiko|Masuhara|Koichi|Sasada|is\.titech|Science Tokyo|STORES|@|/home/|/Users/|x17' .
```

Be careful: `@` appears in BibTeX entries. Inspect hits manually.

## Self-citation policy

If there is prior public GuardLint work by the same authors, cite it in third person if it is relevant and public. Do not write “our previous work.” Write “Xie et al. previously...” if citation is necessary. If the prior work is an anonymized artifact or unpublished internal draft, do not cite it in a way that breaks anonymity.

## Artifact completeness

For Research Track, the artifact should ideally include:

- CodeQL query pack: `.ql`, `.qll`, `qlpack.yml`, query suite files if used.
- Scripts to build CodeQL database.
- Scripts to run queries.
- Postprocessing scripts.
- Generated CSV/JSON outputs used in tables.
- Classification files.
- Dynamic PoC descriptions/results, with clear limitations.
- Over-guarding rewriter and benchmark summary.
- Exact CRuby revision(s).
- CodeQL CLI version.
- Hardware/runtime notes for performance claims.
- Expected runtimes.
- A single top-level reproduction README.

The uploaded package appears to include scripts and generated outputs but not the actual CodeQL `.ql`/`.qll` query pack. The agent should either add an anonymized query pack or weaken claims that reviewers can reproduce the queries from source.

## Data integrity checks

Run the helper:

```sh
python3 /path/to/kit/tools/claim_audit.py .
```

Manual checks:

1. `repro/generated/analysis_summary.csv` has four rows: `missing_guards`, `good_guards`, `redundant_guards`, `missing_guard_detail`.
2. Missing results are 40 guard-obligation sites and 244 internal evidence rows.
3. `missing_classification.csv` has 40 rows and the classification counts match the paper.
4. `dynamic_poc_results.csv` has six rows.
5. `historical_replay_results.csv` has four rows.
6. `pr_validation.csv` has three rows.
7. `assembly_evidence.csv` has three rows.
8. `performance_overguard_summary.csv` says 68 matched benchmarks and 6.99% geomean slowdown.
9. `redundant_guard_classification.csv` parses as valid CSV and either has 213 rows or the paper explicitly says only a subset was audited.

## Redundant-guard CSV issue

Current file issue:

```text
repro/generated/redundant_guard_classification.csv
```

The current file has nine audited subset rows. Either expand the file to all 213 redundant-side reports or keep redundant-side classification claims limited to the audited subset.

Do not write:

```text
We classified all 213 redundant-side rows.
```

unless the data file has all 213 rows and is internally consistent.

## Page-budget check

Compile the PDF and inspect:

- Paper body must end by page 10.
- References may occupy pages 11--12.
- No section after page 10 except references.
- Do not hide body text in smaller fonts to game the limit.

Suggested commands:

```sh
latexmk -pdf -interaction=nonstopmode main.tex
pdfinfo main.pdf | grep Pages
```

If `latexmk` is unavailable:

```sh
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

## Artifact README language

Use language like:

```text
This artifact contains the anonymized query sources, scripts, generated result files, and classification files needed to reproduce the tables in the paper. Some dynamic failures are reported as bounded demonstrations; they are not exhaustive tests and are not required for normal table reproduction.
```

If the query sources are not included:

```text
This anonymized artifact contains generated query outputs and postprocessing scripts. The query source pack is not included in this package; therefore, the artifact supports table traceability but not full query-source reproduction.
```

Prefer including the query pack.
