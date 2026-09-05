#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/education"
LOG="/mnt/data/datasets/logs/education-lot5-download.log"

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
download 56ec08b1c751df73c2cc7148 "complements/lot5/etablissements-d-enseignement-superieur-de-la-metropole-de-lyon-point-d-interet"
download 63478da8b4c219a0cf8c0d3a "complements/lot5/indices-de-position-sociale-des-ecoles-2016-2021"
download 6a633dbcc2298f03e19a9bcd "complements/lot5/etablissements-du-secondaire-colleges-et-lycees-en-2026"
download 63bce30c70d6d100b09dde9a "complements/lot5/indices-de-position-sociale-des-lycees-2016-2021"
download 64265b673eb38d94e6538672 "complements/lot5/indices-de-position-sociale-dans-les-lycees-2022"
download 53699374a3a729239d2041cc "complements/lot5/effectifs-d-etudiants-inscrits-dans-les-etablissements-publics-sous-tutelle-du-m"
download 6503d805d0fd3360f16e33b0 "complements/lot5/annuaire-des-bureaux-des-entreprises-des-lycees-professionnels-et-polyvalents"
download 53699841a3a729239d204ee9 "complements/lot5/les-etudiants-etrangers-dans-lenseignement-superieur"
download 5889d041a3a72974cbf0d5b7 "complements/lot5/origine-scolaire-des-etudiants-entrant-en-premiere-annee-de-cpge"
download 57db115088ee3802f55ff490 "complements/lot5/candidats-et-laureats-du-prix-peps-passion-enseignement-et-pedagogie-dans-le-sup"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
