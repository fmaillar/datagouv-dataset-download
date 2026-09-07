#!/usr/bin/env bash

set -u
RELEASE_ID="${1:-}"
ACTION="${2:-}"
RPC="${TRANSMISSION_RPC:-localhost:9091}"
DATASET_ROOT="/mnt/data/datasets"
TORRENTS="$DATASET_ROOT/torrents/$RELEASE_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACKER_FILE="$SCRIPT_DIR/public-trackers.txt"

if [[ ! "$RELEASE_ID" =~ ^[A-Za-z0-9._+-]+$ ]] || [[ ! -d "$TORRENTS" ]]; then
    echo "Usage : $0 <release_id> [--files-only|--execute]" >&2
    exit 2
fi
if [[ "$ACTION" != "" && "$ACTION" != "--execute" && "$ACTION" != "--files-only" ]]; then
    echo "Action invalide : $ACTION" >&2
    exit 2
fi
for command in transmission-edit transmission-show; do
    command -v "$command" >/dev/null || { echo "$command est requis" >&2; exit 2; }
done
mapfile -t trackers < <(sed '/^[[:space:]]*\($\|#\)/d' "$TRACKER_FILE")
mapfile -t torrent_files < <(find "$TORRENTS" -maxdepth 1 -type f -name '*.torrent' -print | sort)
(( ${#trackers[@]} > 0 && ${#torrent_files[@]} > 0 )) || { echo "Entrées absentes" >&2; exit 2; }

echo "Torrents : ${#torrent_files[@]}"
echo "Trackers : ${#trackers[@]}"
if [[ -z "$ACTION" ]]; then
    printf '  %s\n' "${trackers[@]}"
    echo "Simulation : --files-only modifie les fichiers; --execute met aussi Transmission à jour."
    exit 0
fi

remote=(transmission-remote "$RPC")
[[ -n "${TR_AUTH:-}" ]] && remote+=(--authenv)
if [[ "$ACTION" == "--execute" ]]; then
    command -v transmission-remote >/dev/null || { echo "transmission-remote est requis" >&2; exit 2; }
    "${remote[@]}" --session-info >/dev/null || { echo "Démon Transmission inaccessible" >&2; exit 1; }
fi
failed=0
for torrent in "${torrent_files[@]}"; do
    name="$(basename "$torrent")"
    magnet="$(transmission-show --magnet "$torrent")"
    hash="${magnet#*urn:btih:}"
    hash="${hash%%&*}"
    for tracker in "${trackers[@]}"; do
        if ! transmission-show "$torrent" | grep -Fq "$tracker"; then
            transmission-edit --add "$tracker" "$torrent" || failed=$((failed + 1))
        fi
        if [[ "$ACTION" == "--execute" ]] && \
                ! "${remote[@]}" --torrent "$hash" --info-trackers | grep -Fq "$tracker"; then
            "${remote[@]}" --torrent "$hash" --tracker-add "$tracker" || failed=$((failed + 1))
        fi
    done
    updated="$(transmission-show --magnet "$torrent")"
    updated_hash="${updated#*urn:btih:}"
    updated_hash="${updated_hash%%&*}"
    if [[ "$hash" != "$updated_hash" ]]; then
        echo "ERREUR : infohash modifié pour $name" >&2
        failed=$((failed + 1))
    else
        if [[ "$ACTION" == "--execute" ]]; then
            "${remote[@]}" --torrent "$hash" --reannounce >/dev/null || failed=$((failed + 1))
        fi
        echo "OK : $name — $hash"
    fi
done
((failed == 0)) || exit 1
"$SCRIPT_DIR/build-index.sh" "$RELEASE_ID"
if [[ "$ACTION" == "--execute" ]]; then
    echo "Trackers ajoutés aux fichiers et à Transmission; index régénéré."
else
    echo "Trackers ajoutés aux fichiers; index régénéré."
fi
