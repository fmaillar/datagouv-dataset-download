#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/culture-patrimoine"
LOG="/mnt/data/datasets/logs/culture-patrimoine-lot3-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot3"

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

# LOT 3 — COMPLÉMENTS THÉMATIQUES
download 5b228739c751df5132e7fa55 "complements/lot3/les-donnees-du-hackathon-des-archives-nationales"
download 5b714efe8b4c4136058be7f1 "complements/lot3/cadre-de-classement-des-archives-du-climat"
download 5aab4167a3a7291ed12c89f7 "complements/lot3/les-entrees-d-archives-aux-archives-nationales-depuis-2014"
download 65cb6f939898f97cedd0d6d4 "complements/lot3/immeubles-proteges-au-titre-des-monuments-historiques"
download 5dd651708b4c410b091ad508 "complements/lot3/bibliotheques-de-la-metropole-de-lyon-point-d-interet"
download 68aecf1dd2d11c92c4fafe53 "complements/lot3/archives-annuelles-des-observations-bouees"
download 692f01d38fef6c5815d9262a "complements/lot3/archives-de-la-meteo-des-forets"
download 681adb7c1db9b5fc2f4fd5cb "complements/lot3/le-patrimoine-francilien-en-images"
download 69f0c219518c29b1ece62b7e "complements/lot3/archives-departementales-du-morbihan-registre-des-entrees-de-2025"
download 5dd651698b4c410aeb6582df "complements/lot3/bibliotheques-de-la-metropole-de-lyon"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
