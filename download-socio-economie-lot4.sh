#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/socio-economie-lot4-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/equipements/bpe" \
  "$ROOT/equipements/bpe-geolocalisee" \
  "$ROOT/equipements/categories" \
  "$ROOT/equipements/accessibilite" \
  "$ROOT/entreprises/demographie"

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
# LOT 4 — ÉQUIPEMENTS / ACCESSIBILITÉ / BPE / COMPLÉMENTS STRUCTURANTS
# ============================================================================

# BPE national et millésimes
download 548acaf2c751df1eac4120e7 "equipements/bpe/national"
download 5a341272c751df2a33f64d43 "equipements/bpe/insee-2016"
download 61d78365ebfd25902b8b8e9e "equipements/bpe/occitanie"
download 6a633ddac2298f03e19a9bfe "equipements/bpe/guyane"
download 6856c1cabfa938660452b645 "equipements/bpe/loiret"
download 6728a7c30b67384ce0aa33f6 "equipements/bpe/haute-marne-2021"
download 6826a519165bacf9146c1037 "equipements/bpe/haute-marne-2023"
download 68d67e644b6be22a1d9c884e "equipements/bpe/haute-marne-2024"
download 6a754a1e0a5de9836a987f2f "equipements/bpe/haute-marne-2025"

# BPE géolocalisée
download 5fcace5eb6ba4c68f843096a "equipements/bpe-geolocalisee/pays-loire"
download 5fb85926e09592b82971eb96 "equipements/bpe-geolocalisee/orleans"
download 66b46872bfde2f73aa2d08c8 "equipements/bpe-geolocalisee/troyes-2021"

# Catégories d'équipements / services
download 53699837a3a729239d204ecb "equipements/categories/tourisme-transport-idf"
download 536997fea3a729239d204e35 "equipements/categories/commerces-idf"
download 5369987da3a729239d204f92 "equipements/categories/services-particuliers-idf"
download 5369987da3a729239d204f93 "equipements/categories/services-sante-idf"
download 53699a7ca3a729239d2054d8 "equipements/categories/fonctions-medicales-paramedicales-idf"

# Accessibilité de la population aux équipements
download 67fe0fe2423db9c4a05d8ced "equipements/accessibilite/localisation-acces-population"

# Compléments démographie d'entreprises
download 68b7e68e1ee49772fbcafa50 "entreprises/demographie/ensemble-insee"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
