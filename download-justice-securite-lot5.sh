#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/justice-securite"
LOG="/mnt/data/datasets/logs/justice-securite-lot5-download.log"

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
download 661fbfff0466b4eb28bd41b9 "complements/lot5/verification-reglementaire-triennale-du-systeme-de-securite-incendie-chr-metz-ho"
download 67fe7df1fb719062dcf4e946 "complements/lot5/realisation-dun-diagnostic-produits-equipements-materiaux-dechets-p-e-m-d-preala"
download 6863a7be3492920481cfef43 "complements/lot5/brigades-de-gendarmerie-isere"
download 67fe7ab58ea4a25aa52844da "complements/lot5/realisation-de-diagnostics-plomb-termites-amiante-prealables-aux-travaux-de-demo"
download 6863a7dc3492920481cfef53 "complements/lot5/compagnies-de-gendarmerie-isere"
download 6863a8733492920481cfefa3 "complements/lot5/carte-synthetique-de-lalea-incendie-2005-isere"
download 67fe87cc7a2b18fab4f58581 "complements/lot5/fourniture-dequipements-pour-la-police-municipale-en-2-lots-mapa-5-2-2025"
download 698e6a32ebf3fdf6036e3905 "complements/lot5/inventaire-des-cours-d-eau-au-sens-de-la-police-de-l-eau-v5-isere"
download 690d38873ca747cdc2a37703 "complements/lot5/contour-des-incendies-forestier-sur-les-communes-de-roybon-et-de-saint-ismier-is"
download 690e88cf867def9d647b9615 "complements/lot5/contour-dun-incendie-de-foret-et-de-vegetation-a-la-mure-isere"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
