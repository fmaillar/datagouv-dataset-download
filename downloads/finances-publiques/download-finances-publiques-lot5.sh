#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/finances-publiques"
LOG="/mnt/data/datasets/logs/finances-publiques-lot5-download.log"

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
download 5f68c4edc9ed7984245b654a "complements/lot5/comptes-consolides-des-groupements-a-fiscalite-propre-2018-2025"
download 53698e76a3a729239d203485 "complements/lot5/adhesion-des-communes-a-un-etablissement-public-de-cooperation-intercommunale-ep"
download 5cdd26748b4c413b076fb9cf "complements/lot5/le-budget-de-letat-en-2018-resultats-et-gestion"
download 5d1b7aa36f444175f0d04005 "complements/lot5/les-finances-publiques-locales-2019-fascicule-1"
download 5d8a13f16f44414a5997604c "complements/lot5/les-finances-publiques-locales-2019"
download 5bc49bb28b4c417a3c76e450 "complements/lot5/projet-de-loi-de-finances-pour-2019-plf-2019-annexe-budget-des-operateurs-de-l-e"
download 5369928ea3a729239d203f64 "complements/lot5/depenses-des-administrations-publiques-par-fonction-de-depense"
download 53699541a3a729239d204686 "complements/lot5/execution-du-budget-de-l-etat-2010-budget-des-comptes-de-concours-financiers-en-"
download 5d1b7c576f44417a5d88e05e "complements/lot5/la-situation-et-les-perspectives-des-finances-publiques"
download 5f043d38a55f5b362f611148 "complements/lot5/les-finances-publiques-locales-2020-fascicule-1"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
