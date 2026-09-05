#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/agriculture-alimentation"
LOG="/mnt/data/datasets/logs/agriculture-alimentation-lot5-download.log"

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
download 68cbc430df952493fcc0bcf0 "complements/lot5/paot-2022-2027-actions-prevues-en-bretagne-agriculture-pratiques-perennes"
download 68cbc418df952493fcc0bcae "complements/lot5/paot-2022-2027-actions-prevues-en-bretagne-agriculture-zones-d-erosion"
download 68cbc43cdf952493fcc0bd0e "complements/lot5/paot-2022-2027-actions-prevues-en-bretagne-agriculture-fertilisants-pollution"
download 68cbc433df952493fcc0bcf8 "complements/lot5/paot-2022-2027-actions-prevues-en-bretagne-agriculture-pisciculture"
download 5bfe5a5b8b4c410e486b0bb4 "complements/lot5/donnees-etude-de-lalimentation-totale-infantile"
download 582d7c04a3a7290df5f45b67 "complements/lot5/l-agenda-cultures-en-haute-garonne-open-agenda"
download 692f7ea0d587651515eb69b8 "complements/lot5/concentrations-maximums-en-pesticides-dans-les-cours-d-eau"
download 6853d325ca48a5f38f419f17 "complements/lot5/creation-de-coffrets-et-bornes-dalimentation-electriques-pour-les-forains-sur-le"
download 6a582221f9121211f67fa5d3 "complements/lot5/depassements-de-seuils-reglementaires-en-pesticides-dans-les-cours-d-eau-diagnos"
download 53699ad5a3a729239d2055b2 "complements/lot5/agreste-nombre-d-exploitations-agricoles-aux-recensements-de-l-agriculture-2010-"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
