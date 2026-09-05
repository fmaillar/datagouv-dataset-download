#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/territoire-geospatial"
LOG="/mnt/data/datasets/logs/territoire-geospatial-lot4-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/occupation-sol/ocs-ge" \
  "$ROOT/occupation-sol/regional" \
  "$ROOT/occupation-sol/historique"

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
# LOT 4 — OCCUPATION DU SOL / OCS GE
# ============================================================================

download 61489ec3e64c7f138f1b2e13 "occupation-sol/ocs-ge/nationale"
download 693373c62a73b75078265d9d "occupation-sol/ocs-ge/artificialisation"
download 68348c9afa867945df5968e5 "occupation-sol/ocs-ge/couverture-france"
download 6a4b7fae1d7ecb5a4eb55b41 "occupation-sol/ocs-ge/occitanie-2015"
download 601352f5cbef377d66c1ff8f "occupation-sol/ocs-ge/ossature-occitanie"

download 668d09ffa847603d391cbec9 "occupation-sol/regional/region-sud-2014-corrige"
download 6691c65049511eee990f7fac "occupation-sol/regional/region-sud-2006"
download 6691c64f49511eee990f7fab "occupation-sol/regional/region-sud-evolution-2014-2019"
download 66c2ff0f4ea0a9d2ba6a628b "occupation-sol/regional/picardie-1992-2002-2010"
download 670b0dc8c38cf5576f3ecd9c "occupation-sol/regional/grand-est-statistiques-communales"

download 5b4eeb71a3a7297183e1c36f "occupation-sol/historique/nantes-1952"
download 5b4ee890a3a7296dbbe1c35b "occupation-sol/historique/nantes-1999"
download 5b4ee7e7b5950877c5d496cd "occupation-sol/historique/nantes-2004"
download 5b4ee8a7b595087918d496ca "occupation-sol/historique/nantes-2008"
download 5b4eeb62a3a7297183e1c36c "occupation-sol/historique/nantes-2012"
download 5b4eebbca3a7297352e1c34d "occupation-sol/historique/nantes-2014"
download 5e1910819ce2e706dfa48bf5 "occupation-sol/historique/nantes-2016"
download 5f8f7a45f155da7abbd5f962 "occupation-sol/historique/nantes-2018"
download 624794b748e3f6291558ffdc "occupation-sol/historique/nantes-2020"
download 690d3802e444f49a38a376c4 "occupation-sol/historique/nantes-2022"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
