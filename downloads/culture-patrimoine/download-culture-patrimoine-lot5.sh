#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/culture-patrimoine"
LOG="/mnt/data/datasets/logs/culture-patrimoine-lot5-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot5"

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

# LOT 5 — COMPLÉMENTS THÉMATIQUES
download 6a11bacd77a67baa26b8cecd "complements/lot5/catalogue-topic-univers-culture-deps"
download 659d7da1a28b115513e756ff "complements/lot5/portail-francearchives-inventaires-des-archives-francaises"
download 5f7fe0822a00717c597ce91e "complements/lot5/activite-des-services-darchives-en-france"
download 54510dc1c751df1fdb5a81f3 "complements/lot5/geographie-du-cinema-equipement-et-frequentation"
download 64062266e9fd809db3246d1c "complements/lot5/archives-des-saisons-passees-a-l-opera-national-de-bordeaux"
download 5b7679e8634f412ed6d322f7 "complements/lot5/inventaire-des-archives-du-climat-conservees-dans-le-centre-des-archives-interme"
download 61aa0bd25c40b31e464ed799 "complements/lot5/sla-bibliotheques-mediatheques"
download 54b4e31dc751df0605ae2616 "complements/lot5/balade-nature-culture-fil-de-l-hers"
download 5ef45f5720c559a4e8950d2d "complements/lot5/mediations-culturelles-des-musees-de-la-ville-d-antibes"
download 5a1d46e7c751df151abbb304 "complements/lot5/liste-des-bibliotheques-departementales-des-cotes-d-armor"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
