#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/territoire-geospatial"
LOG="/mnt/data/datasets/logs/territoire-geospatial-lot2-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/cadastre/pci" \
  "$ROOT/cadastre/parcelles" \
  "$ROOT/cadastre/batiments" \
  "$ROOT/cadastre/historique"

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

# ============================================================================
# LOT 2 — CADASTRE / PARCELLES / BÂTIMENTS
# ============================================================================

download 66c2ff1a4ea0a9d2ba6a62a9 "cadastre/pci/vecteur"
download 5bd837f2634f41112d338d46 "cadastre/pci/adresses-extraites"

download 5e6ad06d06e3e742367168cc "cadastre/parcelles/strasbourg"
download 6836523418d64a73d1708380 "cadastre/parcelles/ara-2022"
download 6a4b7f2c1d7ecb5a4eb55a9a "cadastre/parcelles/occitanie-localisants"
download 5a6c7e7b88ee383fabaa4823 "cadastre/parcelles/historique-filiation"
download 5a6c78f188ee3831716746b8 "cadastre/parcelles/documents-filiation"

download 61dc7157488f8cdb4283e3c3 "cadastre/batiments/base-donnees-nationale"
download 64f8681944e2fc006a93e65b "cadastre/batiments/imope"
download 676b759548fd95b8f0133b7e "cadastre/batiments/rennes"
download 612da9f23e803252b4ef6a5a "cadastre/batiments/grand-poitiers"

download 60274f0db3d17ed49f7ce5a7 "cadastre/historique/napoleonien-hauts-de-seine"
download 60274f0cbb06f7e1577ce5a7 "cadastre/historique/renove-hauts-de-seine"
download 684004152f9592aab088e146 "cadastre/historique/napoleonien-bretagne"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
