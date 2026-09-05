#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/emploi-formation-lot2-download.log"

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
download 62673976b11acf20def11a3b "complements/lot2/moncompteformation-l-offre-de-formation"
download 5796275a88ee3831d77d97c2 "complements/lot2/referentiel-des-metiers-et-competences-des-systemes-dinformation-et-de-communica"
download 53699f97a3a729239d206178 "complements/lot2/series-chronologiques-sur-les-salaires-et-le-cout-du-travail"
download 62bb96cdaf45285ea1a1f848 "complements/lot2/moncompteformation-les-formations-engagees"
download 64f7c309e0e88e0fcdae9bff "complements/lot2/moncompteformation-entrees-et-sorties-de-formation"
download 60e67902fefedbb57155bb07 "complements/lot2/concours-de-recrutement-de-personnels-enseignants-du-1er-degre-public"
download 58123657c751df389fc562c8 "complements/lot2/referentiel-metiers-referens-iii-pour-la-filiere-des-itrf"
download 58480c1fc751df560cc0bb7e "complements/lot2/insertion-professionnelle-des-diplome-e-s-de-diplome-universitaire-de-technologi"
download 63a4384a1b57813fbca80dc8 "complements/lot2/depenses-et-recettes-de-l-assurance-chomage"
download 60e678ff5e8dc467e055bb07 "complements/lot2/concours-de-recrutement-de-personnels-enseignants-d-education-et-d-orientation-d"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
