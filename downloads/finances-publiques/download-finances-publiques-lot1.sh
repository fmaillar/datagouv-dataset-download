#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/finances-publiques"
LOG="/mnt/data/datasets/logs/finances-publiques-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/collectivites/communes" \
  "$ROOT/collectivites/departements" \
  "$ROOT/collectivites/regions" \
  "$ROOT/fiscalite-locale" \
  "$ROOT/budget-etat"

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

# LOT 1 — COMPTES LOCAUX / FISCALITÉ / BUDGET DE L'ÉTAT
download 5f68c4ec23ac65f6fd8021e3 "collectivites/communes/comptes-2018-2025"
download 5f68c4ec93e22c89418021e3 "collectivites/communes/comptes-consolides-2018-2025"
download 5f68c4ed0a143d9ab88021e3 "collectivites/departements/comptes-2012-2025"
download 5f68c4edc9ed7984245b654b "collectivites/departements/comptes-consolides-2012-2025"
download 5f68c4ed0be7ff90225b6549 "collectivites/regions/comptes-2012-2025"
download 5f68c4ec9920494bf28021e3 "collectivites/regions/comptes-consolides-2012-2025"
download 5369965fa3a729239d204999 "fiscalite-locale/impots-locaux"
download 6657c57abbefc8869c7c6364 "fiscalite-locale/rei"
download 6916717fd1613a14a77b95df "budget-etat/budget-vert-2026"
download 5bbf72438b4c417355377505 "budget-etat/plf-2019-pap"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
