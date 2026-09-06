#!/usr/bin/env bash

{
  echo "===== limites administratives ====="
  datagouv search "limites administratives" --limit 1000

  echo
  echo "===== communes ====="
  datagouv search "communes" --limit 1000

  echo
  echo "===== départements ====="
  datagouv search "départements" --limit 1000

  echo
  echo "===== régions ====="
  datagouv search "régions" --limit 1000

  echo
  echo "===== EPCI ====="
  datagouv search "EPCI" --limit 1000

  echo
  echo "===== codes géographiques ====="
  datagouv search "code officiel géographique" --limit 1000

  echo
  echo "===== BAN ====="
  datagouv search "Base Adresse Nationale" --limit 1000

  echo
  echo "===== adresses ====="
  datagouv search "adresses" --limit 1000

  echo
  echo "===== cadastre ====="
  datagouv search "cadastre" --limit 1000

  echo
  echo "===== parcelles cadastrales ====="
  datagouv search "parcelles cadastrales" --limit 1000

  echo
  echo "===== bâtiments ====="
  datagouv search "bâtiments" --limit 1000

  echo
  echo "===== BD TOPO ====="
  datagouv search "BD TOPO" --limit 1000

  echo
  echo "===== IGN ====="
  datagouv search "IGN" --limit 1000

  echo
  echo "===== altimétrie ====="
  datagouv search "altimétrie" --limit 1000

  echo
  echo "===== relief ====="
  datagouv search "relief" --limit 1000

  echo
  echo "===== hydrographie ====="
  datagouv search "hydrographie" --limit 1000

  echo
  echo "===== occupation sol ====="
  datagouv search "occupation du sol" --limit 1000

  echo
  echo "===== OCS GE ====="
  datagouv search "OCS GE" --limit 1000
} > ./territoire-geospatial-search.log 2>&1
