#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/education"
LOG="/mnt/data/datasets/logs/education-lot3-download.log"

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
download 60b5b0ec04ca1909fd2ee2c7 "complements/lot3/inserjeunes-apprentissage-par-centre-de-formation-d-apprentis-cfa-et-formation-f"
download 5889d043a3a72974cbf0d5bb "complements/lot3/le-budget-missions-interministerielles-enseignement-scolaire-et-recherche-et-ens"
download 6707515c84dfa4012c3ecd45 "complements/lot3/indicateurs-de-valeur-ajoutee-des-lycees-d-enseignement-general-et-technologique--6707515c84dfa4012c3ecd45"
download 5889d042a3a72974c1f0d607 "complements/lot3/indicateurs-de-valeur-ajoutee-des-lycees-d-enseignement-general-et-technologique--5889d042a3a72974c1f0d607"
download 6455d121686917088af10162 "complements/lot3/indicateurs-de-valeur-ajoutee-des-colleges"
download 53699373a3a729239d2041c5 "complements/lot3/effectifs-detudiants-inscrits-dans-les-etablissements-et-les-formations-de-lense--53699373a3a729239d2041c5"
download 53699373a3a729239d2041c4 "complements/lot3/effectifs-detudiants-inscrits-dans-les-etablissements-et-les-formations-de-lense--53699373a3a729239d2041c4"
download 5889d044a3a72974cbf0d5bc "complements/lot3/indicateurs-de-valeur-ajoutee-des-lycees-d-enseignement-professionnel-ancienne-v"
download 5665ff71c751df71e6c664c2 "complements/lot3/publications-statistiques-sur-l-enseignement-superieur-et-la-recherche"
download 5889d041a3a72974cbf0d5b6 "complements/lot3/taille-des-colleges-et-des-lycees"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
