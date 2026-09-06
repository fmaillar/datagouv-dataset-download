#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/finances-publiques"
LOG="/mnt/data/datasets/logs/finances-publiques-lot2-download.log"

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
download 6984e42c4abb23c7072e5f41 "complements/lot2/montants-des-dotations-de-fonctionnement-aux-communes"
download 69822a6e7d3a18407a36c7b0 "complements/lot2/les-communes-et-les-epci-a-fiscalite-propre-du-departement-de-la-haute-savoie-20"
download 53698ee1a3a729239d2035bc "complements/lot2/tableaux-statistiques-de-la-direction-generale-des-finances-publiques-dgfip"
download 55673898c751df5f9ee5726a "complements/lot2/budget-de-l-etat-exercice-2014"
download 555df4eac751df5c8dc98e0f "complements/lot2/budget-de-l-etat-exercice-2012"
download 555df757c751df5c8dc98e10 "complements/lot2/budget-de-l-etat-exercice-2013"
download 5f68c4edf94340bbc28021e3 "complements/lot2/comptes-des-groupements-a-fiscalite-propre-2018-2025"
download 5ea9515a7f6d609f43319267 "complements/lot2/le-budget-de-letat-en-2019-resultats-et-gestion"
download 53893653a3a7291ffe8c5034 "complements/lot2/execution-du-budget-de-l-etat-2013-en-autorisations-d-engagement-ae-et-des-credi"
download 53699547a3a729239d204694 "complements/lot2/execution-du-budget-de-l-etat-2012-en-credits-de-paiement-cp-suivant-la-nomencla"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
