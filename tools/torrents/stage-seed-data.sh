#!/usr/bin/env bash

set -u
RELEASE_ID="${1:-}"
ACTION="${2:-}"
DATASET_ROOT="/mnt/data/datasets"
SOURCE="$DATASET_ROOT/releases/$RELEASE_ID/data"
TARGET_ROOT="/mnt/data/torrents/datagouv-releases/$RELEASE_ID"
TARGET="$TARGET_ROOT/data"
DAEMON_USER="${TRANSMISSION_USER:-transmission}"
DAEMON_GROUP="${TRANSMISSION_GROUP:-transmission}"

if [[ ! "$RELEASE_ID" =~ ^[A-Za-z0-9._+-]+$ ]] || [[ ! -d "$SOURCE" ]]; then
    echo "Usage : sudo $0 <release_id> [--execute]" >&2
    exit 2
fi
if [[ "$ACTION" != "" && "$ACTION" != "--execute" ]]; then
    echo "Action invalide : $ACTION" >&2
    exit 2
fi
source_bytes="$(du -s --block-size=1 "$SOURCE" | awk '{print $1}')"
available_bytes="$(df -P --block-size=1 /mnt/data/torrents | awk 'NR==2 {print $4}')"
required_bytes=$((source_bytes + source_bytes / 10))
printf 'Source : %s\nDestination : %s\nVolume apparent : %.2f Gio\n' \
    "$SOURCE" "$TARGET" "$(awk -v value="$source_bytes" 'BEGIN {print value / 1024 / 1024 / 1024}')"
if ((available_bytes < required_bytes)); then
    echo "Espace insuffisant avec réserve de 10 %" >&2
    exit 1
fi
if [[ -e "$TARGET_ROOT" ]]; then
    echo "Destination déjà existante, aucun écrasement : $TARGET_ROOT" >&2
    exit 1
fi
if [[ "$ACTION" != "--execute" ]]; then
    echo "Simulation : relancer avec sudo et --execute"
    exit 0
fi
if ((EUID != 0)); then
    echo "Cette opération doit être exécutée avec sudo" >&2
    exit 1
fi
getent passwd "$DAEMON_USER" >/dev/null || { echo "Utilisateur absent : $DAEMON_USER" >&2; exit 1; }
getent group "$DAEMON_GROUP" >/dev/null || { echo "Groupe absent : $DAEMON_GROUP" >&2; exit 1; }

install -d -o "$DAEMON_USER" -g "$DAEMON_GROUP" -m 0750 "$TARGET_ROOT"
cp -a --reflink=auto "$SOURCE" "$TARGET"
chown -R "$DAEMON_USER:$DAEMON_GROUP" "$TARGET"
first_source="$(find "$SOURCE" -type f -print -quit)"
relative="${first_source#"$SOURCE"/}"
if [[ "$(stat -c '%d:%i' "$first_source")" == "$(stat -c '%d:%i' "$TARGET/$relative")" ]]; then
    echo "ERREUR : la copie partage encore les inodes de la release" >&2
    exit 1
fi
echo "Copie de seed indépendante créée : $TARGET"
