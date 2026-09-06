#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/tourisme"
LOG="/mnt/data/datasets/logs/tourisme-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/offre-nationale" \
  "$ROOT/accessibilite" \
  "$ROOT/hebergements/hotels" \
  "$ROOT/hebergements/residences"

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

# LOT 1 — OFFRE TOURISTIQUE / HÉBERGEMENTS / ACCESSIBILITÉ
download 59c36c6a88ee3826d5998a35 "offre-nationale/hebergements-classes"
download 5b598be088ee387c0c353714 "offre-nationale/datatourisme"
download 66cd17b117d11e62a5d2cd46 "accessibilite/tourisme-handicap"
download 5dddbf3806e3e77cec832c57 "hebergements/hotels/centre-val-loire"
download 5b4cdb5ca3a729797ae1c35f "hebergements/hotels/pays-loire"
download 5dddbf359ce2e72e0fb62c09 "hebergements/residences/centre-val-loire"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
