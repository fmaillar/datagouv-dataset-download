#!/usr/bin/env bash

set -u
RELEASE_ID="${1:-}"
ACTION="${2:-}"
RPC="${TRANSMISSION_RPC:-localhost:9091}"
UPLOAD_KBPS="${TRANSMISSION_UPLOAD_KBPS:-20000}"
DATASET_ROOT="/mnt/data/datasets"
RELEASE="$DATASET_ROOT/releases/$RELEASE_ID"
TORRENTS="$DATASET_ROOT/torrents/$RELEASE_ID"

if [[ ! "$RELEASE_ID" =~ ^[A-Za-z0-9._+-]+$ ]] || [[ ! -d "$RELEASE/data" ]]; then
    echo "Usage : $0 <release_id> [--execute|--start]" >&2
    exit 2
fi
if [[ "$ACTION" != "" && "$ACTION" != "--execute" && "$ACTION" != "--start" ]]; then
    echo "Action invalide : $ACTION" >&2
    exit 2
fi
if [[ ! "$UPLOAD_KBPS" =~ ^[1-9][0-9]*$ ]]; then
    echo "TRANSMISSION_UPLOAD_KBPS doit être un entier positif" >&2
    exit 2
fi
command -v transmission-remote >/dev/null || { echo "transmission-remote est requis" >&2; exit 2; }
command -v transmission-show >/dev/null || { echo "transmission-show est requis" >&2; exit 2; }
[[ -f "$TORRENTS/SHA256SUMS" ]] || { echo "SHA256SUMS absent" >&2; exit 2; }
(cd "$TORRENTS" && sha256sum -c SHA256SUMS) || exit 1

remote=(transmission-remote "$RPC")
[[ -n "${TR_AUTH:-}" ]] && remote+=(--authenv)
mapfile -t torrent_files < <(find "$TORRENTS" -maxdepth 1 -type f -name '*.torrent' -print | sort)
(( ${#torrent_files[@]} > 0 )) || { echo "Aucun torrent" >&2; exit 2; }

echo "RPC : $RPC"
echo "Répertoire des données : $RELEASE/data"
echo "Torrents : ${#torrent_files[@]}"
echo "Plafond upload au démarrage : $UPLOAD_KBPS kB/s"
if [[ -z "$ACTION" ]]; then
    echo "Simulation : --execute ajoute en pause et vérifie; --start démarre les torrents déjà ajoutés."
    exit 0
fi
"${remote[@]}" --session-info >/dev/null || { echo "Démon Transmission inaccessible" >&2; exit 1; }

if [[ "$ACTION" == "--execute" ]]; then
    "${remote[@]}" --start-paused
    for torrent in "${torrent_files[@]}"; do
        echo "Ajout en pause : $(basename "$torrent")"
        "${remote[@]}" --download-dir "$RELEASE/data" --add "$torrent" || exit 1
        magnet="$(transmission-show --magnet "$torrent")"
        hash="${magnet#*urn:btih:}"
        hash="${hash%%&*}"
        "${remote[@]}" --torrent "$hash" --stop --verify || exit 1
    done
    echo "Ajout terminé. Attendre la fin des vérifications avant --start."
else
    "${remote[@]}" --dht --portmap --utp --uplimit "$UPLOAD_KBPS"
    for torrent in "${torrent_files[@]}"; do
        magnet="$(transmission-show --magnet "$torrent")"
        hash="${magnet#*urn:btih:}"
        hash="${hash%%&*}"
        "${remote[@]}" --torrent "$hash" --no-seedratio --start || exit 1
    done
    echo "Partage démarré avec DHT, port mapping et µTP."
fi
