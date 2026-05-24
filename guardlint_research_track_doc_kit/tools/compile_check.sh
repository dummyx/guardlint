#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 0 ]]; then
  cd "$1"
fi

if command -v latexmk >/dev/null 2>&1; then
  latexmk -pdf -interaction=nonstopmode main.tex
else
  pdflatex -interaction=nonstopmode main.tex
  bibtex main
  pdflatex -interaction=nonstopmode main.tex
  pdflatex -interaction=nonstopmode main.tex
fi

if command -v pdfinfo >/dev/null 2>&1; then
  pdfinfo main.pdf | grep '^Pages:' || true
fi
