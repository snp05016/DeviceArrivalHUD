#!/bin/bash
set -euo pipefail

if [ -x /Applications/DeviceArrivalHUD.app/Contents/MacOS/DeviceArrivalHUD ]; then
    /Applications/DeviceArrivalHUD.app/Contents/MacOS/DeviceArrivalHUD --disable-login || true
fi
pkill -x DeviceArrivalHUD 2>/dev/null || true
rm -rf /Applications/DeviceArrivalHUD.app
echo "DeviceArrivalHUD was removed from Applications and Login Items."

