#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot2-download.log"

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
download 65f1185f3e0e630d9f924b51 "complements/lot2/consommation-annuelle-delectricite-et-gaz-par-region"
download 5cbf0fea634f4127672d69e1 "complements/lot2/donnees-sur-les-appels-doffres-relatifs-aux-energies-renouvelables"
download 5c6c382e634f416847f2de3f "complements/lot2/observatoire-des-marches-de-detail-d-electricite-et-de-gaz-naturel"
download 5b160132a3a7291530758884 "complements/lot2/distributeurs-de-gaz-et-d-electricite-par-commune"
download 5c7e468a634f4139a0331672 "complements/lot2/observatoire-des-marches-de-gros-d-electricite-et-de-gaz-naturel"
download 5b1628d8b59508189015c486 "complements/lot2/points-d-injection-de-methane-renouvelable-et-bas-carbone-en-france-en-service"
download 5b90b88306e3e7417c2ffd33 "complements/lot2/production-regionale-annuelle-des-energies-renouvelables"
download 5bc171609ce2e750ce422d3e "complements/lot2/consommation-regionale-de-gaz-naturel-carburant-gnc"
download 5ac5a221a3a7291d89cf960c "complements/lot2/stock-quotidien-dans-les-stockages-de-gaz-a-partir-de-novembre-2010"
download 6380aad4474d0548142034d8 "complements/lot2/cadastre-solaire-de-la-savoie"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
