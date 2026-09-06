#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/emploi-formation-lot3-download.log"

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
download 66e22fbf107665e8dd227719 "complements/lot3/les-salaires-des-professionnelles-du-social-par-profession-au-niveau-national-et"
download 66ba1325a3674318d42cae5c "complements/lot3/structures-proposant-des-formations-aux-logiciels-libres"
download 665fabcc97cb6fb80b9fc8f3 "complements/lot3/indicateurs-de-suivi-de-l-assurance-chomage-total-france"
download 69b989759cbf238599d4757a "complements/lot3/taux-de-chomage-au-sens-du-recensement"
download 66e380b07889d3b365709383 "complements/lot3/bilan-social-d-edf-sa-formation"
download 53699721a3a729239d204bf6 "complements/lot3/insertion-professionnelle-des-diplomes-de-master-en-universites-et-etablissement"
download 54294e8f88ee380327a59161 "complements/lot3/evolution-des-recrutements-de-militaires-sur-24-ans"
download 66685855500cccd9a708910e "complements/lot3/activite-emploi-et-chomage-series-longues"
download 63a4384ab7505d95e39dde9a "complements/lot3/indicateurs-de-suivi-de-l-assurance-chomage-par-departement"
download 584814c3c751df65ebc0bb7e "complements/lot3/insertion-professionnelle-des-diplome-e-s-de-licence-professionnelle-en-universi"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
