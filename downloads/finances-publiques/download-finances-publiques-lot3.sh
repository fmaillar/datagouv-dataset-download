#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/finances-publiques"
LOG="/mnt/data/datasets/logs/finances-publiques-lot3-download.log"

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
download 53699546a3a729239d204692 "complements/lot3/execution-du-budget-de-l-etat-2012-en-autorisations-d-engagement-ae-suivant-la-n"
download 53699546a3a729239d204691 "complements/lot3/execution-du-budget-de-l-etat-2012-en-autorisations-d-engagement-ae-et-credits-d"
download 555df20bc751df415ac98e11 "complements/lot3/les-finances-publiques-locales-2014-2009-2013"
download 53699545a3a729239d204690 "complements/lot3/execution-du-budget-de-l-etat-2011-budget-general-en-credits-de-paiement-cp-plr-"
download 53699980a3a729239d20527f "complements/lot3/loi-de-finances-initiale-2011-dotations-par-ministere"
download 53699544a3a729239d20468d "complements/lot3/execution-du-budget-de-l-etat-2011-budget-des-comptes-d-affectation-speciale-en---53699544a3a729239d20468d"
download 53699545a3a729239d20468e "complements/lot3/execution-du-budget-de-l-etat-2011-budget-des-comptes-d-affectation-speciale-en---53699545a3a729239d20468e"
download 53699545a3a729239d20468f "complements/lot3/execution-du-budget-de-l-etat-2011-budget-general-en-autorisations-d-engagement-"
download 53699543a3a729239d20468b "complements/lot3/execution-du-budget-de-l-etat-2011-budget-des-comptes-de-concours-financiers-en-"
download 53699547a3a729239d204695 "complements/lot3/execution-2012-du-budget-de-l-etat-en-cp-suivant-la-nomenclature-mission-program"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
