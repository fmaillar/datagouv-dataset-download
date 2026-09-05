#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/administration"
LOG="/mnt/data/datasets/logs/administration-lot4-download.log"

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
download 5fa9901be0b96c51b61963e6 "complements/lot4/taux-demploi-de-travailleurs-handicapes-dans-la-fonction-publique-depuis-2006"
download 53698f1aa3a729239d203653 "complements/lot4/associations-reconnues-d-utilite-publique"
download 5bc5df57634f417a900a5ed0 "complements/lot4/annuaire-des-diagnostiqueurs-immobiliers"
download 68e51e04c4258097a201a3cc "complements/lot4/annuaire-sante-ameli"
download 5c3538da9ce2e7459c6d765a "complements/lot4/les-bibliotheques-des-collectivites-territoriales-adresses-et-donnees-dactivite"
download 61a10d03a62eb966568b1b06 "complements/lot4/liste-des-delegations-de-service-public-delivrees-pour-l-exploitation-des-casino"
download 6902546dfc27585fa038d104 "complements/lot4/annuaire-sante-extraction-des-bal-mssante"
download 5bbf2bf28b4c4175c716d3b1 "complements/lot4/donnees-du-suivi-du-service-public-de-la-donnee"
download 61c9fdfa3f81d47b9db36bd9 "complements/lot4/liste-des-simulateurs-developpes-par-la-dila-service-public-fr"
download 57db148888ee383cd95ff490 "complements/lot4/budget-de-recherche-et-de-transfert-de-technologie-r-t-des-collectivites-territo"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
