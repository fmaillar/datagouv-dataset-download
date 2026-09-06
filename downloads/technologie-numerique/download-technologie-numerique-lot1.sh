#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/technologie-numerique"
LOG="/mnt/data/datasets/logs/technologie-numerique-lot1-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/connectivite/mobile" \
  "$ROOT/connectivite/fixe" \
  "$ROOT/connectivite/fibre" \
  "$ROOT/usages" \
  "$ROOT/inclusion-numerique" \
  "$ROOT/cybersecurite"

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
# LOT 1 — CONNECTIVITÉ / USAGES / INCLUSION NUMÉRIQUE
# ============================================================================

download 58c98b1888ee38770950152b "connectivite/mobile/mon-reseau-mobile"
download 5e836644ca07c8558d91a6fc "connectivite/fixe/ma-connexion-internet"
download 547d8d7ac751df405d090fcb "connectivite/fixe/marche-haut-tres-haut-debit"
download 64a3e3ab22a67ba76e06b1a6 "connectivite/fibre/qualite-reseaux"
download 691d9e1fa936b579807ceafa "connectivite/fibre/zonage-france-tres-haut-debit"
download 691dba38a5d5e13a5f63418f "connectivite/fibre/deploiement-et-cuivre"

download 5838300988ee386317c65bb3 "usages/barometre-numerique"
download 67dde5bb8b979e2f5c9d869d "usages/equipements-barometre-arcom"
download 69c3ba7a9884d29f3b44f77d "inclusion-numerique/lieux-mediation"
download 681017096ef14106359e6b68 "cybersecurite/offre-nationale"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
