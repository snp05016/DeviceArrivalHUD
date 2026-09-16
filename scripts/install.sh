#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

./scripts/build_app.sh
pkill -x DeviceArrivalHUD 2>/dev/null || true
rm -rf /Applications/DeviceArrivalHUD.app
cp -R DeviceArrivalHUD.app /Applications/DeviceArrivalHUD.app
/Applications/DeviceArrivalHUD.app/Contents/MacOS/DeviceArrivalHUD --enable-login
open /Applications/DeviceArrivalHUD.app
echo "DeviceArrivalHUD is installed, running, and registered at login."

