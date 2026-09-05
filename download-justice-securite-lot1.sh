#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/justice-securite"
LOG="/mnt/data/datasets/logs/justice-securite-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/delinquance" \
  "$ROOT/justice/juridictions" \
  "$ROOT/justice/condamnations" \
  "$ROOT/justice/detention"

download() {
    local id="$1"
    local dest="$2"
    echo
    echo "===== $id -> $dest =====" | tee -a "$LOG"
    mkdir -p "$ROOT/$dest"
    if datagouv download "$id" -o "$ROOT/$dest" >>"$LOG" 2>&1; then
        echo "OK: $id -> $dest" | tee -a "$LOG"
    else
        echo "ECHEC: $id -> $dest" | tee -a "$LOG" >&2
    fi
}

echo "Début : $(date --iso-8601=seconds)" >"$LOG"

# LOT 1 — DÉLINQUANCE / JURIDICTIONS / CONDAMNATIONS / DÉTENTION
download 621df2954fa5a3b5a023e23c "delinquance/bases-territoriales"
download 5617b11dc751df083fcdbb48 "delinquance/crimes-delits-depuis-2012"
download 5617ad4dc751df6211cdbb49 "delinquance/chiffres-mensuels-depuis-1996"
download 694410b463279019f7d95486 "delinquance/victimes-mis-en-cause"
download 5369932fa3a729239d20410c "justice/juridictions/structures-geocodees"
download 6392017edf7251532fda4bab "justice/juridictions/competence-communes"
download 539a67b7a3a7293bc2728384 "justice/condamnations/casier-judiciaire"
download 5369a048a3a729239d206322 "justice/detention/population-mensuelle"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
