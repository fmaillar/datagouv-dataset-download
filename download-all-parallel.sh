#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKERS="${1:-4}"
LOG_DIR="/mnt/data/datasets/logs/parallel"
MASTER_LOG="/mnt/data/datasets/logs/download-all-parallel.log"

if [[ ! "$WORKERS" =~ ^[1-9][0-9]*$ ]] || ((WORKERS > 16)); then
    echo "Usage : $0 [nombre-workers entre 1 et 16]" >&2
    exit 2
fi

mkdir -p "$LOG_DIR"

mapfile -t scripts < <(
    find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'download-*.sh' \
      ! -name 'download-all.sh' \
      ! -name 'download-all-parallel.sh' \
      -printf '%f\n' | sort
)

if ((${#scripts[@]} == 0)); then
    echo "Aucun script de téléchargement trouvé." >&2
    exit 1
fi

declare -A pid_to_script=()
succeeded=()
failed=()
running=0

# shellcheck disable=SC2317  # Fonction appelée indirectement par trap.
stop_children() {
    local pid

    trap - INT TERM
    echo "Interruption : arrêt des téléchargements en cours..." | tee -a "$MASTER_LOG" >&2
    for pid in "${!pid_to_script[@]}"; do
        pkill -TERM -P "$pid" 2>/dev/null || true
        kill -TERM "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null || true
    echo "Arrêt global : $(date --iso-8601=seconds)" | tee -a "$MASTER_LOG" >&2
    exit 130
}

trap stop_children INT TERM

echo "Début global : $(date --iso-8601=seconds)" >"$MASTER_LOG"
echo "Workers : $WORKERS" | tee -a "$MASTER_LOG"
echo "Scripts prévus : ${#scripts[@]}" | tee -a "$MASTER_LOG"

launch_script() {
    local script="$1"
    local console_log="$LOG_DIR/${script%.sh}.log"

    echo "DÉBUT : $script — $(date --iso-8601=seconds)" | tee -a "$MASTER_LOG"
    bash "$SCRIPT_DIR/$script" >"$console_log" 2>&1 &
    pid_to_script[$!]="$script"
    running=$((running + 1))
}

reap_script() {
    local finished_pid
    local status
    local script

    wait -n -p finished_pid
    status=$?
    script="${pid_to_script[$finished_pid]}"
    unset 'pid_to_script[$finished_pid]'
    running=$((running - 1))

    if ((status == 0)); then
        succeeded+=("$script")
        echo "OK : $script — $(date --iso-8601=seconds)" | tee -a "$MASTER_LOG"
    else
        failed+=("$script")
        echo "ECHEC : $script — code $status — $(date --iso-8601=seconds)" \
          | tee -a "$MASTER_LOG" >&2
    fi
}

for script in "${scripts[@]}"; do
    while ((running >= WORKERS)); do
        reap_script
    done
    launch_script "$script"
done

while ((running > 0)); do
    reap_script
done

echo "Fin globale : $(date --iso-8601=seconds)" | tee -a "$MASTER_LOG"
echo "Scripts réussis : ${#succeeded[@]}" | tee -a "$MASTER_LOG"
echo "Scripts en échec : ${#failed[@]}" | tee -a "$MASTER_LOG"

if ((${#failed[@]} > 0)); then
    printf '  ECHEC: %s\n' "${failed[@]}" | tee -a "$MASTER_LOG" >&2
    exit 1
fi

exit 0
