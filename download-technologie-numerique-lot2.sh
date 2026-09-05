#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/technologie-numerique"
LOG="/mnt/data/datasets/logs/technologie-numerique-lot2-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/recherche-innovation/programmes" \
  "$ROOT/recherche-innovation/brevets" \
  "$ROOT/recherche-innovation/entreprises" \
  "$ROOT/numerique/inclusion" \
  "$ROOT/numerique/catalogues" \
  "$ROOT/numerique/investissements" \
  "$ROOT/intelligence-artificielle/communs"

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

# ============================================================================
# LOT 2 — RECHERCHE / INNOVATION / TRANSFORMATION NUMÉRIQUE
# ============================================================================

download 586dae68a3a7290df6f4be93 "recherche-innovation/programmes/h2020-contrats"
download 586dae76a3a7290df5f4be8c "recherche-innovation/programmes/h2020-participations"
download 5892a0cba3a72974c1f0de3c "recherche-innovation/brevets/inpi-oeb"
download 5bb61a378b4c4118b11dd650 "recherche-innovation/programmes/poles-competitivite-2006-2016"
download 577cb487c751df29779901a0 "recherche-innovation/entreprises/laureats-ilab"
download 5369984da3a729239d204f09 "recherche-innovation/entreprises/jeunes-innovantes"

download 6417a853699eddff29014c0a "numerique/inclusion/conseillers-accompagnements"
download 587379c788ee384d1e0bfefe "numerique/catalogues/observatoires"
download 604b41376268c26e7f983c50 "numerique/investissements/france-relance"
download 69bc03ff32eb35550eff3870 "intelligence-artificielle/communs/partages-sante"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
