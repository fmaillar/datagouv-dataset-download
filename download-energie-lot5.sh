#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot5-download.log"

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
download 6092189f52089a65549bacce "complements/lot5/indicateur-mensuel-gaz-renouvelable-des-territoires-par-region"
download 6092189c8c7f3ca7049bacce "complements/lot5/indicateur-mensuel-gaz-renouvelable-des-territoires-par-departement"
download 60c431acf0bf638bcd2fcb3b "complements/lot5/bilan-d-emissions-de-gaz-a-effet-de-serre-par-scope-et-operateur"
download 63587afb1cc488641390f68e "complements/lot5/centrales-de-production-thermique-a-flamme-d-edf-sa-fioul-gaz-charbon"
download 617a213b6169cf65304a1318 "complements/lot5/projets-de-production-de-gaz-renouvelable-et-bas-carbone-par-pyrogazeification-p"
download 5ce8c11e06e3e715bcd57eba "complements/lot5/repartition-des-potentiels-de-gaz-verts-a-horizon-2050-par-departement"
download 5fbb95cd90aa3901aef2a418 "complements/lot5/distribution-du-gaz-a-antibes"
download 674547cc5cc63ed8987733ca "complements/lot5/energies-energie-totale-consommee-a-paris"
download 619c677ba67b35c0e95506cd "complements/lot5/indicateur-prospectif-de-gaz-renouvelable-dynamique-engagee-a-la-maille-epci"
download 6128640090a161c05046ea4e "complements/lot5/indicateur-annualise-gaz-renouvelable-des-territoires-perimetre-national"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
