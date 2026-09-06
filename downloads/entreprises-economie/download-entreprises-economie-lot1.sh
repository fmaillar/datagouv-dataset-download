#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/entreprises-economie-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/entreprises/bodacc" \
  "$ROOT/entreprises/creations" \
  "$ROOT/entreprises/aides" \
  "$ROOT/commerce-exterieur"

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

# LOT 1 — BODACC / CRÉATIONS / AIDES / COMMERCE EXTÉRIEUR
download 559395f1c751df0f51a453b9 "entreprises/bodacc/annonces"
download 592d454188ee3802a9b970af "entreprises/bodacc/greffes"
download 683f8e739bf2fdce342f1775 "entreprises/creations/entreprises-individuelles"
download 5ae2d5b5c751df3498bc70ad "entreprises/aides/base-nationale"
download 6859c780b3bad4fe6445a50e "entreprises/aides/transition-ecologique"
download 5369a0b4a3a729239d206418 "commerce-exterieur/statistiques-nationales"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
