#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/justice-securite"
LOG="/mnt/data/datasets/logs/justice-securite-lot3-download.log"

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
download 5dde689c634f412e071fb12e "complements/lot3/point-d-eau-incendie-2018"
download 650e0f1904eba4f82b1a49b1 "complements/lot3/casernes-du-service-departemental-metropolitain-d-incendie-et-de-secours-sur-le-"
download 5369993fa3a729239d2051cd "complements/lot3/liste-des-unites-de-gendarmerie-accueillant-du-public-comprenant-leur-geolocalis"
download 53699109a3a729239d203b60 "complements/lot3/commission-pour-l-indemnisation-des-victimes-de-spoliations-chiffres-cles"
download 5387f347a3a7291cb36754a1 "complements/lot3/les-crimes-et-delits-enregistres-par-la-gendarmerie-nationale"
download 53699578a3a729239d204722 "complements/lot3/faits-constates-zone-police"
download 60619ae06dc3a97af64087fd "complements/lot3/donnees-essentielles-des-marches-publics-direction-generale-de-la-securite-civil"
download 53d37b7ca3a729042701368f "complements/lot3/accompagnement-des-conjoints-du-personnel-de-la-defense-et-de-la-gendarmerie-201"
download 5bd9c7c8634f412c5f28cc48 "complements/lot3/interventions-des-pompiers"
download 5f201af96831adfdf8aecc02 "complements/lot3/decisions-de-justice-a-la-ville-dantibes"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
