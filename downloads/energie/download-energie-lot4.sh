#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot4-download.log"

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
download 62f188a990e901ca4ff9b486 "complements/lot4/consommations-energetiques-2020-a-la-parcelle-sur-le-territoire-de-la-metropole-"
download 62f81f9782675d6f275b7a94 "complements/lot4/consommations-energetiques-2019-a-la-parcelle-sur-le-territoire-de-la-metropole-"
download 61162160ff5e52a51ea9666a "complements/lot4/consommation-annuelle-electricite-gaz-par-iris-et-par-code-naf-dans-la-metropole"
download 67fa2463bb6c4cc70a4455be "complements/lot4/part-d-energie-fossile-charbon-et-produits-petroliers-gaz-naturel-pci-dans-la-co"
download 68e80e9bfac8a35ba7c72e52 "complements/lot4/part-de-chaleur-decarbonee-produite-enr-r-renouvelable-et-de-recuperation-dans-l"
download 6965fd7bdd5d82d4c4664a66 "complements/lot4/production-annuelle-delectricite-par-filiere-saint-pierre-et-miquelon"
download 62e1fc65d2d57106c20505d1 "complements/lot4/infrastructures-de-reseau-de-gaz"
download 66b40c68c73c0b6bcfa06f1f "complements/lot4/consommation-energetique-logement-sociaux-dans-les-departements-2021"
download 684ff3752b3791ece29b3d26 "complements/lot4/scenarios-prospectifs-energie-climat-air"
download 5ac71ff6b595080400c04a3c "complements/lot4/debit-quotidien-des-stockages-de-gaz-a-partir-de-novembre-2010"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
