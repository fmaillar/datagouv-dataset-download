#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/education"
LOG="/mnt/data/datasets/logs/education-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/etablissements" \
  "$ROOT/enseignement-superieur" \
  "$ROOT/examens" \
  "$ROOT/orientation"

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

# LOT 1 — ÉTABLISSEMENTS / SUPÉRIEUR / EXAMENS / ORIENTATION
download 5889d043a3a72974cbf0d5ba "etablissements/education-prioritaire"
download 586dae71a3a7290df5f4be86 "enseignement-superieur/ecoles-doctorales"
download 5b15fd22a3a7290eb6758880 "enseignement-superieur/ecoles-doctorales-historique"
download 5548d994c751df32e0a7b26c "enseignement-superieur/logements-etudiants"
download 53699840a3a729239d204ee5 "enseignement-superieur/filieres-ingenieurs"
download 6667bdd97c40509c4608910e "enseignement-superieur/cpge-effectifs"
download 62846fba5de756c86f902161 "examens/baccalaureat-academie"
download 67ac1cead25c6f09c2c6a495 "examens/baccalaureat-departement"
download 5889d044a3a72974c1f0d60b "examens/baccalaureat-origine-sociale"
download 5f90f5c978b32276bad5f959 "orientation/parcoursup-formations"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
