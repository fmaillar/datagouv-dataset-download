#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/agriculture-alimentation"
LOG="/mnt/data/datasets/logs/agriculture-alimentation-lot4-download.log"

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
download 684be69c7dd2fdcc07ae0149 "complements/lot4/donnees-descriptives-de-l-activite-de-cultures-marines-sur-le-secteur-estuaire-d"
download 684a50e9bd2710cecf52b638 "complements/lot4/alimentation-en-metropole-enquete"
download 684be6a57dd2fdcc07ae0157 "complements/lot4/donnees-descriptives-carroyage-1-x-1-des-activites-de-cultures-marines-a-l-echel"
download 68cbc444df952493fcc0bd21 "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-agriculture-algues-vertes"
download 68cbc45bdf952493fcc0bd5a "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-agriculture-etude-globale-et-schema-d"
download 68cbc411df952493fcc0bc9b "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-agriculture-intrants-et-erosion"
download 68cbc419df952493fcc0bcb1 "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-agriculture-pesticides-apport"
download 684be6f67dd2fdcc07ae01e7 "complements/lot4/donnees-descriptives-de-l-activite-de-cultures-marines-sur-le-secteur-baie-de-se"
download 68cbc435df952493fcc0bcfe "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-agriculture-pesticides-pollution"
download 68cbc423df952493fcc0bccf "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-agriculture-aires-d-alimentation-de-c"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
