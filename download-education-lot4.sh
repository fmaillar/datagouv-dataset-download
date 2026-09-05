#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/education"
LOG="/mnt/data/datasets/logs/education-lot4-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot4"

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

# LOT 4 — COMPLÉMENTS THÉMATIQUES
download 5c9e3c478b4c414290a0f73c "complements/lot4/programme-d-enseignement-des-classes-preparatoires-au-baccalaureat-professionnel"
download 5889d03fa3a72974c1f0d5ff "complements/lot4/colleges-education-prioritaire"
download 5889d03ea3a72974c1f0d5fe "complements/lot4/reseau-d-education-prioritaire-des-colleges"
download 56eb191e88ee38750689c52e "complements/lot4/journees-des-arts-et-de-la-culture-dans-l-enseignement-superieur"
download 6a2984c099d1cb741398dfce "complements/lot4/extrait-des-coordonnees-des-etudiants-boursiers-pour-les-demarches-proactives"
download 668d0a25a847603d391cbefe "complements/lot4/localisation-des-lycees-publics-en-region-provence-alpes-cote-d-azur"
download 536998eba3a729239d2050c2 "complements/lot4/liste-des-colleges-de-la-gironde"
download 5d36ef386f444131f0f9e9ae "complements/lot4/colleges-du-morbihan"
download 694527a76d1022dd2fb85fb7 "complements/lot4/effectifs-etudiants-de-nantes-universite-2024-2025"
download 56ec086dc751df1d76cc7146 "complements/lot4/etablissements-d-enseignement-superieur-de-la-metropole-de-lyon"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
