#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG="/mnt/data/datasets/logs/download-all.log"

mkdir -p "$(dirname "$LOG")"

scripts=(
  "download-administration-lot1.sh"
  "download-agriculture-alimentation-lot1.sh"
  "download-climat-environnement.sh"
  "download-culture-patrimoine-lot1.sh"
  "download-education-lot1.sh"
  "download-emploi-formation-lot1.sh"
  "download-energie-lot1.sh"
  "download-entreprises-economie-lot1.sh"
  "download-finances-publiques-lot1.sh"
  "download-justice-securite-lot1.sh"
  "download-socio-economie-lot1.sh"
  "download-socio-economie-lot2.sh"
  "download-socio-economie-lot3.sh"
  "download-socio-economie-lot4.sh"
  "download-socio-economie-lot5.sh"
  "download-socio-economie-lot6.sh"
  "download-territoire-geospatial-lot1.sh"
  "download-territoire-geospatial-lot2.sh"
  "download-territoire-geospatial-lot3.sh"
  "download-territoire-geospatial-lot4.sh"
  "download-territoire-geospatial-lot5.sh"
  "download-territoire-geospatial-lot6.sh"
  "download-transport-lot1.sh"
  "download-transport-lot2.sh"
  "download-technologie-numerique-lot1.sh"
  "download-technologie-numerique-lot2.sh"
  "download-tourisme-lot1.sh"
  "download-sante-lot1.sh"
  "download-sante-lot2.sh"
  "download-sante-lot3.sh"
  "download-education-lot2.sh"
  "download-education-lot3.sh"
  "download-education-lot4.sh"
  "download-education-lot5.sh"
  "download-administration-lot2.sh"
  "download-administration-lot3.sh"
  "download-administration-lot4.sh"
  "download-administration-lot5.sh"
  "download-emploi-formation-lot2.sh"
  "download-emploi-formation-lot3.sh"
  "download-emploi-formation-lot4.sh"
  "download-emploi-formation-lot5.sh"
  "download-energie-lot2.sh"
  "download-energie-lot3.sh"
  "download-energie-lot4.sh"
  "download-energie-lot5.sh"
  "download-agriculture-alimentation-lot2.sh"
  "download-agriculture-alimentation-lot3.sh"
  "download-agriculture-alimentation-lot4.sh"
  "download-agriculture-alimentation-lot5.sh"
  "download-entreprises-economie-lot2.sh"
  "download-entreprises-economie-lot3.sh"
  "download-entreprises-economie-lot4.sh"
  "download-entreprises-economie-lot5.sh"
  "download-justice-securite-lot2.sh"
  "download-justice-securite-lot3.sh"
  "download-justice-securite-lot4.sh"
  "download-justice-securite-lot5.sh"
  "download-culture-patrimoine-lot2.sh"
  "download-culture-patrimoine-lot3.sh"
  "download-culture-patrimoine-lot4.sh"
  "download-culture-patrimoine-lot5.sh"
  "download-finances-publiques-lot2.sh"
  "download-finances-publiques-lot3.sh"
  "download-finances-publiques-lot4.sh"
  "download-finances-publiques-lot5.sh"
  "download-tourisme-lot2.sh"
  "download-tourisme-lot3.sh"
  "download-tourisme-lot4.sh"
  "download-tourisme-lot5.sh"
)

succeeded=()
failed=()

echo "Début global : $(date --iso-8601=seconds)" >"$LOG"
echo "Scripts prévus : ${#scripts[@]}" | tee -a "$LOG"

for script in "${scripts[@]}"; do
    script_path="$SCRIPT_DIR/$script"

    echo | tee -a "$LOG"
    echo "================================================================" | tee -a "$LOG"
    echo "DÉBUT SCRIPT : $script" | tee -a "$LOG"
    echo "================================================================" | tee -a "$LOG"

    if [[ ! -f "$script_path" ]]; then
        echo "ABSENT : $script_path" | tee -a "$LOG" >&2
        failed+=("$script")
        continue
    fi

    bash "$script_path" 2>&1 | tee -a "$LOG"
    script_status=${PIPESTATUS[0]}

    if ((script_status == 0)); then
        echo "SCRIPT OK : $script" | tee -a "$LOG"
        succeeded+=("$script")
    else
        echo "SCRIPT ECHEC : $script" | tee -a "$LOG" >&2
        failed+=("$script")
    fi
done

echo | tee -a "$LOG"
echo "Fin globale : $(date --iso-8601=seconds)" | tee -a "$LOG"
echo "Scripts réussis : ${#succeeded[@]}" | tee -a "$LOG"
if ((${#succeeded[@]} > 0)); then
    printf '  OK: %s\n' "${succeeded[@]}" | tee -a "$LOG"
fi

echo "Scripts en échec : ${#failed[@]}" | tee -a "$LOG"
if ((${#failed[@]} > 0)); then
    printf '  ECHEC: %s\n' "${failed[@]}" | tee -a "$LOG" >&2
    exit 1
fi

exit 0
