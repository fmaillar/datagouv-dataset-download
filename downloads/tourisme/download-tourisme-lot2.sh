#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/tourisme"
LOG="/mnt/data/datasets/logs/tourisme-lot2-download.log"

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
download 6582f2d98b1e2e8d11554dcf "complements/lot2/hebergements-touristiques-du-grand-chambord-muides"
download 5c6f225f634f411aca138430 "complements/lot2/tourisme-en-polynesie-francaise"
download 5488088cc751df17b3a3fc15 "complements/lot2/nuitees-dans-les-campings-municipaux"
download 648095c7842d021d1a5b380e "complements/lot2/tourisme-et-hebergement-touristique-equipements-et-services"
download 6a4e534691d1607d49c0de9d "complements/lot2/meubles-de-tourisme-et-marche-immobilier-en-corse-indicateurs-epci-2025"
download 6a4e5230d1f87854f66a599f "complements/lot2/meubles-de-tourisme-et-marche-immobilier-en-corse-indicateurs-communaux-2025"
download 6a8e2ea9ecff969a2b06cfa8 "complements/lot2/recensement-des-campings-et-des-risques-presents-sur-le-site-isere"
download 6a90d14fccdf3c9af006cfd1 "complements/lot2/recensement-des-campings-soumis-un-risque-naturel-et-ou-technologique-previsible"
download 5d318e9c634f4172420e6f2c "complements/lot2/hotels-de-prefectures"
download 6676141f20b34935aec4be13 "complements/lot2/frequentation-des-hebergements-touristiques"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
