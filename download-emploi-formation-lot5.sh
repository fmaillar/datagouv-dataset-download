#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/emploi-formation-lot5-download.log"

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
download 53699c18a3a729239d2058bf "complements/lot5/perimetres-des-secteurs-de-recrutements-des-colleges-publics-de-gironde"
download 61d5bd6fd8fa52f2c3c19243 "complements/lot5/referentiel-de-remuneration-des-56-metiers-de-la-filiere-numerique-et-des-system"
download 65a6c0fba8b46aea409ce9ee "complements/lot5/referentiel-de-remuneration-des-55-metiers-de-la-filiere-numerique-janvier-2024"
download 62263311ca3d6516043e0c4d "complements/lot5/la-formation-aux-professions-de-sante"
download 68b0df7b5fc04a2f363846bb "complements/lot5/ideo-formations-initiales-en-france"
download 53698e7ca3a729239d20349e "complements/lot5/adresses-geographiques-et-telephoniques-des-centres-d-information-et-de-recrutem"
download 627a4f9afb5129f462e70b18 "complements/lot5/recrutement-primo-entrants-titulaires-geres-par-la-direction-des-ressources-huma"
download 53d384b6a3a729042701369c "complements/lot5/indemnisation-chomage-des-militaires-2013"
download 53699980a3a729239d205280 "complements/lot5/loi-de-finances-initiale-2011-emplois-temps-plein"
download 635a0252f931c40e6390f68f "complements/lot5/emploi-professions-culturelles-par-zone-d-emploi"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
