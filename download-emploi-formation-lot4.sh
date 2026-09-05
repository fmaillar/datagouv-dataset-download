#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/emploi-formation-lot4-download.log"

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
download 584810d9c751df5ed8c0bb7e "complements/lot4/insertion-professionnelle-des-diplome-e-s-de-licence-professionnelle-en-universi"
download 53699538a3a729239d20466d "complements/lot4/evolution-des-recrutements-de-civils-sur-24-ans"
download 57d59600c751df032a97bae5 "complements/lot4/base-des-diplomes-des-metiers-du-sport-2015"
download 60e678ffcecb26f4352c4f6b "complements/lot4/concours-de-recrutement-de-personnels-enseignants-du-2nd-degre-prive"
download 60e67905b1315808a72c4f6a "complements/lot4/concours-de-recrutement-de-personnels-enseignants-du-1er-degre-prive"
download 664723eb8ecd21c19bbfd060 "complements/lot4/evaluation-des-formations-par-le-hceres"
download 6830a0bdcbad82b7876585bd "complements/lot4/fiches-pratiques-travail-emploi-vectorisees"
download 54ad4ff3c751df50f7de6534 "complements/lot4/insertion-professionnelle-des-diplomes-de-master-en-universites-et-etablissement"
download 66a01380616b7eda72530d6c "complements/lot4/emploi-de-la-polynesie-francaise"
download 69c7528e084a6cbddeb42a1e "complements/lot4/salaires-nets-mensuels-moyens-des-agents-de-la-region-ile-de-france"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
