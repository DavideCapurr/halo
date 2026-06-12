#!/usr/bin/env bash
#
# Harness di verifica grafica: builda HaloApp, lo installa sul simulatore e
# cattura uno screenshot di ogni superficie principale usando la DEMO mode
# offline (vedi `DemoMode` in HaloApp/App/AppState.swift).
#
# La demo mode è attivata via env var `HALO_DEMO=1` e NON tocca produzione:
#   - HALO_DEMO=1            → bypassa auth/Supabase, idrata da SeedPeople
#   - HALO_DEMO_TAB=<tab>    → tab iniziale: orbit | pulse | status | profile
#   - HALO_DEMO_SHEET=<x>    → sheet auto-presentata: compose | vibe | easy | space
#
# Uso:
#   ./scripts/demo-screens.sh                 # simulatore booted (o iPhone 17 Pro)
#   ./scripts/demo-screens.sh "iPhone 17 Pro" # device per nome
#   OUT=/tmp/shots ./scripts/demo-screens.sh  # dir di output custom
#
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="HaloApp"
BID="la.halo"
DD="${DD:-/tmp/halo-dd}"
OUT="${OUT:-/tmp/halo-shots}"
DEVICE_NAME="${1:-}"

mkdir -p "$OUT"

# --- risolvi il simulatore: booted > nome passato > iPhone 17 Pro ---
SIM="$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1 || true)"
if [[ -z "$SIM" ]]; then
  NAME="${DEVICE_NAME:-iPhone 17 Pro}"
  SIM="$(xcrun simctl list devices available | grep -F "$NAME (" | grep -Eo '[0-9A-F-]{36}' | head -1 || true)"
  [[ -n "$SIM" ]] || { echo "Nessun simulatore trovato per '$NAME'"; exit 1; }
  xcrun simctl boot "$SIM"
fi
echo "▶ Simulatore: $SIM"

echo "▶ Build…"
xcodebuild -project Halo.xcodeproj -scheme "$SCHEME" -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath "$DD" build >/dev/null
APP="$DD/Build/Products/Debug-iphonesimulator/$SCHEME.app"
xcrun simctl install "$SIM" "$APP" >/dev/null
echo "▶ Installato."

# shoot <slug> <KEY=VAL> [KEY=VAL...]
shoot() {
  local slug="$1"; shift
  xcrun simctl terminate "$SIM" "$BID" >/dev/null 2>&1 || true
  local env=()
  for kv in "$@"; do env+=("SIMCTL_CHILD_$kv"); done
  env "${env[@]}" xcrun simctl launch "$SIM" "$BID" >/dev/null
  sleep 4
  xcrun simctl io "$SIM" screenshot "$OUT/$slug.png" >/dev/null 2>&1
  echo "  ✓ $slug.png"
}

echo "▶ Catturo le superfici → $OUT"
shoot 01-orbit   HALO_DEMO=1 HALO_DEMO_TAB=orbit
shoot 02-pulse   HALO_DEMO=1 HALO_DEMO_TAB=pulse
shoot 03-status  HALO_DEMO=1 HALO_DEMO_TAB=status
shoot 04-profile HALO_DEMO=1 HALO_DEMO_TAB=profile
shoot 05-compose HALO_DEMO=1 HALO_DEMO_SHEET=compose
shoot 06-vibe    HALO_DEMO=1 HALO_DEMO_SHEET=vibe
shoot 07-easy    HALO_DEMO=1 HALO_DEMO_SHEET=easy
shoot 08-space   HALO_DEMO=1 HALO_DEMO_SHEET=space
echo "▶ Fatto."
