#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/education"
LOG="/mnt/data/datasets/logs/education-lot2-download.log"

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
download 65c4f98979eb66d71c1484bc "complements/lot2/a-paraitre-fevrier-2026-resultat-des-elections-des-representants-des-etudiants-a"
download 60e678fececb26f4352c4f6a "complements/lot2/carte-scolaire-des-colleges-publics"
download 5889d040a3a72974c1f0d601 "complements/lot2/reussite-au-baccalaureat-selon-l-age"
download 60b5b0ed5d1dd28f2b2ee2c5 "complements/lot2/inserjeunes-apprentissage-par-centre-de-formation-d-apprentis-cfa-et-niveau-de-f"
download 5f979bd875978e1460d5f959 "complements/lot2/cartographie-des-formations-parcoursup"
download 559e98cdc751df4443390bd3 "complements/lot2/cartographie-de-l-enseignement-superieur"
download 65b786b3e7e30d2591b6ae3c "complements/lot2/janvier-2026-election-des-representants-des-etudiants-au-sein-des-crous-liste-de"
download 5889d044a3a72974cbf0d5bd "complements/lot2/effectifs-detudiants-en-cpge-par-annee-et-par-sexe"
download 5653a8dc88ee38737fe72046 "complements/lot2/lexique-francais-anglais-des-termes-lies-a-l-enseignement-superieur-et-a-la-rech"
download 56535b0dc751df4793aad371 "complements/lot2/statistiques-mensuelles-du-nombre-de-telechargements-des-jeux-de-donnees-open-da"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
