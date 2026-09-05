#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/sante"
LOG="/mnt/data/datasets/logs/sante-lot1-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/referentiels/finess" \
  "$ROOT/referentiels/rpps" \
  "$ROOT/etablissements/sae" \
  "$ROOT/etablissements/qualite-securite" \
  "$ROOT/medico-social/evaluations" \
  "$ROOT/offre-soins/accessibilite" \
  "$ROOT/professionnels/demographie" \
  "$ROOT/mortalite/causes-deces"

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
# LOT 1 — RÉFÉRENTIELS / ÉTABLISSEMENTS / OFFRE DE SOINS
# ============================================================================

# FINESS nouvelle génération — structures et activités
download 69fb10fd3d405934d1077e01 "referentiels/finess/structures"
download 69faffb8789b9dc5135058b1 "referentiels/finess/activites"

# Annuaire national des professionnels de santé
download 69025e6c73d1f9b79ca3c365 "referentiels/rpps/annuaire-sante"

# Établissements sanitaires et qualité des soins
download 5369a047a3a729239d206320 "etablissements/sae"
download 614b3fb671e1083ae45effd7 "etablissements/qualite-securite/bqss"

# Établissements et services sociaux et médico-sociaux
download 693822a461b1b759069eba97 "medico-social/evaluations/essms"

# Accessibilité et démographie des professionnels
download 62263314072c63d4d53e0c50 "offre-soins/accessibilite/apl"
download 6888814b4e3edfaa4b226531 "professionnels/demographie/depuis-2012"
download 62ccbac9905df8d44cf49333 "professionnels/demographie/1999-2011"

# Mortalité nationale par cause
download 640924e6090056da2430406a "mortalite/causes-deces"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
