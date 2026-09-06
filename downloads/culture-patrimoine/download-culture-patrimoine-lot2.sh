#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/culture-patrimoine"
LOG="/mnt/data/datasets/logs/culture-patrimoine-lot2-download.log"

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
download 5dc423178b4c4146ca45d7ef "complements/lot2/ccfr-repertoire-fiches-descriptives-de-bibliotheques"
download 656565de619420d81ca3e3dc "complements/lot2/les-aides-deconcentrees-au-spectacle-vivant-adsv"
download 68e3b8f62e94755428f0270a "complements/lot2/corpus-de-documents-numerises-des-archives-nationales"
download 69b91293c4dd281e19df0839 "complements/lot2/expositions-temporaires-des-archives-nationales-france"
download 6a4be490401803d7002d01d9 "complements/lot2/liste-des-inventaires-des-archives-nationales-publies-en-ligne"
download 536c47bfa3a72933d8d1b3a6 "complements/lot2/liste-des-immeubles-proteges-au-titre-des-monuments-historiques-archives"
download 5fc9b4729dbf684fecb13bae "complements/lot2/licences-et-demandes-de-licences-d-entrepreneurs-de-spectacles-vivants"
download 5369978fa3a729239d204d11 "complements/lot2/journees-europeennes-du-patrimoine"
download 61b4226ca5919d3b718b8e9e "complements/lot2/catalogue-des-donnees-du-ministere-de-la-culture"
download 615bcdd729be9185b3b0681a "complements/lot2/liste-des-objets-proteges-au-titre-des-monuments-historiques"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
