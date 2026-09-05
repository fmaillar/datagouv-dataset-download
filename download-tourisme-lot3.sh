#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/tourisme"
LOG="/mnt/data/datasets/logs/tourisme-lot3-download.log"

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
download 68195347116615dea69463f1 "complements/lot3/capacites-d-hebergements-touristiques"
download 55882244c751df5f2ca453b9 "complements/lot3/hebergements-touristiques"
download 54881d6dc751df32f8a3fc15 "complements/lot3/campings"
download 6110eaaabbefd3150fec4557 "complements/lot3/sites-d-interet-touristiques"
download 540917e1a3a72959e0628f93 "complements/lot3/frequentation-de-l-office-du-tourisme"
download 637baca3c1db3fc89cdab1b4 "complements/lot3/mairies-et-hotels-de-ville-des-16-communes-de-grand-paris-sud-est-avenir"
download 5b4cdb57a3a729797ae1c35e "complements/lot3/offre-touristique-hebergements-locatifs-meubles-et-chambre-d-hotes-touristiques-"
download 5b4cdb59b595081059d496d4 "complements/lot3/offre-touristique-hebergements-collectifs-touristiques-en-pays-de-la-loire"
download 5b4cdb62a3a729797ae1c360 "complements/lot3/offre-touristique-residences-de-tourisme-en-pays-de-la-loire"
download 58989098c751df12c2ae0a65 "complements/lot3/hebergements-touristiques-de-la-commune-de-plaintel"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
