#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/agriculture-alimentation"
LOG="/mnt/data/datasets/logs/agriculture-alimentation-lot3-download.log"

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
download 66b61a7f16dfaaad95030fbc "complements/lot3/achats-de-pesticides-par-code-postal-a-troyes-champagne-metropole"
download 66b4d421adbdd5c7e416a17d "complements/lot3/parcelles-en-agriculture-biologique-ab-declarees-a-la-pac-de-troyes-champagne-me"
download 667e99a23842e1affb99dad9 "complements/lot3/qualite-des-cours-d-eau-vis-a-vis-des-pesticides-en-bretagne-impact-sanitaire"
download 6818dd1971517f1a7debf646 "complements/lot3/substances-actives-pesticides-et-leurs-metabolites"
download 667e99996fa1a91d798e010d "complements/lot3/qualite-des-cours-d-eau-vis-a-vis-des-pesticides-en-bretagne-impact-ecologique"
download 6756b860d6f163559eab289a "complements/lot3/dce-bassin-loire-bretagne-etat-chimique-contaminants-chimiques-pesticides"
download 68cbc414df952493fcc0bca2 "complements/lot3/bilan-des-controles-au-titre-de-la-directive-nitrates-dans-les-exploitations-agr"
download 68cbc417df952493fcc0bcaa "complements/lot3/analyse-de-pesticides-dans-les-cours-d-eau-vis-a-vis-des-pnec-dans-les-cours-d-e"
download 684be7647dd2fdcc07ae028b "complements/lot3/donnees-descriptives-des-activites-de-cultures-marines-a-l-echelle-metropolitain"
download 68cbc45adf952493fcc0bd58 "complements/lot3/paot-2022-2027-actions-prevues-en-bretagne-agriculture-fertilisants-apport"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
