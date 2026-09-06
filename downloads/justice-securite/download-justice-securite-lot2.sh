#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/justice-securite"
LOG="/mnt/data/datasets/logs/justice-securite-lot2-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot2"

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

# LOT 2 — COMPLÉMENTS THÉMATIQUES
download 5369986ba3a729239d204f55 "complements/lot2/police-municipale-effectifs-par-commune"
download 62c7daa168ebd3a2212821c5 "complements/lot2/liste-des-infractions-en-vigueur-de-la-nomenclature-natinf"
download 5489cda0c751df35a24120e7 "complements/lot2/competence-territoriale-gendarmerie-et-police-nationales"
download 53699736a3a729239d204c29 "complements/lot2/interventions-realisees-par-les-services-d-incendie-et-de-secours"
download 5387f349a3a7291cb36754a5 "complements/lot2/les-crimes-et-delits-enregistres-par-la-police-nationale--5387f349a3a7291cb36754a5"
download 65548f606fe6f0a87fcf8ca1 "complements/lot2/fonds-des-cartes-de-chaleur-des-taux-de-cambriolages-et-tentatives-de-cambriolag"
download 5387f34aa3a7291cb36754a8 "complements/lot2/les-crimes-et-delits-enregistres-par-la-police-nationale--5387f34aa3a7291cb36754a8"
download 5387f348a3a7291cb36754a3 "complements/lot2/les-crimes-et-delits-enregistres-par-la-gendarmerie-nationale"
download 628da9fdef366eb8a2c7fd48 "complements/lot2/pensions-et-secours-aux-combattants-et-victimes-des-revolutions-de-1789-1830-et-"
download 66fe9472af71f0a023d50128 "complements/lot2/points-d-eau-incendie-du-departement-de-la-seine-maritime"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
