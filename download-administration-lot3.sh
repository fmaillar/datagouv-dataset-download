#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/administration"
LOG="/mnt/data/datasets/logs/administration-lot3-download.log"

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
download 64c062e06417adf6a69f7201 "complements/lot3/resultats-de-qualite-des-services-publics"
download 66cfba6d347bd9f74b227704 "complements/lot3/annuaire-des-centres-de-controle-technique"
download 63d39bed60f4dd87a77f325b "complements/lot3/enquete-num-enquete-nationale-sur-les-usages-numeriques-des-collectivites-territ"
download 5fa9901c7094eadce61963e8 "complements/lot3/beneficiaires-de-lobligation-demploi-dans-la-fonction-publique-depuis-2006"
download 64c062e0e1545c18019f7201 "complements/lot3/typologies-des-services-publics"
download 5fa9901b66cff095591963e6 "complements/lot3/taux-emploi-de-travailleurs-handicapes-dans-la-fonction-publique-par-departement"
download 666035811a4c33c43140ddcf "complements/lot3/actualites-entreprendre-service-public-gouv-fr"
download 62269cde735b9c18e23e0c46 "complements/lot3/taux-demploi-de-travailleurs-handicapes-dans-la-fonction-publique-selon-les-regi"
download 60e67902484dcf40d255bb07 "complements/lot3/bilan-contentieux-administration-centrale-et-academies"
download 62da21021d3f7025e69ef260 "complements/lot3/depenses-culturelles-des-communes"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
