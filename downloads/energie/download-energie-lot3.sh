#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot3-download.log"

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
download 5e8bfb816ba0b9240dd1046b "complements/lot3/consommation-quotidienne-regionalisee-definitive-de-gaz-des-clients-industriels-"
download 5db7bb2006e3e7769f832c58 "complements/lot3/consommation-horaire-definitive-de-gaz-des-clients-industriels-raccordes-sur-le-"
download 5db7bb20dee7e76680936949 "complements/lot3/consommation-horaire-provisoire-de-gaz-des-clients-industriels-raccordes-sur-le-"
download 609218a179d24006209bacce "complements/lot3/indicateur-annualise-gaz-renouvelable-des-territoires-par-region"
download 5f0fd12c46245dad0c6dcf09 "complements/lot3/consommation-quotidienne-definitive-regionalisee-de-gaz-des-distributions-publiq"
download 652d04bd41b04e798e6a21e2 "complements/lot3/batistato-constitution-et-consommations-energetiques-du-parc-de-bati-en-ile-de-f"
download 63f55b10c75df20987c98e1b "complements/lot3/capacites-solaires-installees-d-edf-power-solutions"
download 667e96ef2d363cacb3215cf1 "complements/lot3/consommation-de-bois-energie-en-bretagne"
download 62ec429a7db5aa5196becad5 "complements/lot3/consommations-energetiques-2018-a-la-parcelle-sur-le-territoire-de-la-metropole-"
download 62f81f97d6c7c1703119322f "complements/lot3/consommations-energetiques-2019-a-l-adresse-sur-le-territoire-de-la-metropole-de"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
