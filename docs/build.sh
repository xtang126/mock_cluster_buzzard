#!/usr/bin/env bash
# Build MockDataVector.pdf from MockDataVector.tex.
#
# Usage (from anywhere):
#   bash docs/build.sh
#
# Two pdflatex passes are needed so the TOC and figure/equation
# cross-references resolve. Build artifacts (.aux, .log, .toc, .out)
# are deleted at the end.

set -euo pipefail

# cd into the directory holding this script (so relative includegraphics
# paths like ../output/figs/*.png resolve correctly).
cd "$(dirname "$0")"

# Load TeX Live on NERSC if pdflatex is not already on PATH.
if ! command -v pdflatex >/dev/null 2>&1; then
    if command -v module >/dev/null 2>&1; then
        module load texlive/2024
    else
        echo "ERROR: pdflatex not found and 'module' is unavailable." >&2
        echo "       Install TeX Live or load the texlive module manually." >&2
        exit 1
    fi
fi

TEX=MockDataVector.tex

pdflatex -interaction=nonstopmode -halt-on-error "$TEX"
pdflatex -interaction=nonstopmode -halt-on-error "$TEX"

rm -f -- *.aux *.log *.toc *.out

echo
echo "Built $(pwd)/${TEX%.tex}.pdf"
