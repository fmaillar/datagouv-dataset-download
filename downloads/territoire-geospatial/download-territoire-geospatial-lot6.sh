#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/territoire-geospatial"
LOG="/mnt/data/datasets/logs/territoire-geospatial-lot6-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/developpement-urbain/logement/vacance" \
  "$ROOT/developpement-urbain/logement/loyers" \
  "$ROOT/developpement-urbain/logement/commercialisation" \
  "$ROOT/developpement-urbain/logement/dpe" \
  "$ROOT/developpement-urbain/politique-ville" \
  "$ROOT/developpement-urbain/artificialisation/historique"

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

# ============================================================================
# LOT 6 — LOGEMENT / LOYERS / PERFORMANCE ÉNERGÉTIQUE
# ============================================================================

download 61816c6e23197bb34835228e "developpement-urbain/logement/vacance/parc-prive-2020-2026"
download 56fd8e8788ee387079c352f7 "developpement-urbain/logement/loyers/resultats-nationaux"
download 56fd90e8c751df174ac485cb "developpement-urbain/logement/loyers/par-agglomeration"
download 689c42e194c71a7fbb2b472b "developpement-urbain/logement/commercialisation/zonage-abc"

download 67f7e557cb268460ce66c8d4 "developpement-urbain/logement/dpe/existants-depuis-2021"
download 67f7e5758ffc5d79ab9e8c27 "developpement-urbain/logement/dpe/neufs-depuis-2021"
download 67f7e59231d941e1b216cb37 "developpement-urbain/logement/dpe/tertiaire-depuis-2021"
download 67cad6f31b824c076b3a4b7a "developpement-urbain/logement/dpe/part-residences-principales"

download 5b27839288ee3827eee7079a "developpement-urbain/politique-ville/habitat-ancien-degrade"
download 6405e3f2181d0f673cac60d7 "developpement-urbain/artificialisation/historique/coenaf-2009-2021"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
