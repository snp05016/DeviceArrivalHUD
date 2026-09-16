# DeviceArrivalHUD

A persistent, menu-bar-free macOS hardware arrival desk. It watches Bluetooth devices, external drives, displays, and game controllers, then stages a device-specific pixel animation whenever hardware connects or departs.

The three first-class Bluetooth profiles match the real paired-device names on this Mac:

- `Saumya’s AirPods Pro` — opening case, staggered bud launch, radio rings
- `Saumya’s XM4s` — rotating fold-out headphones and signal-lock waves
- `ProtoArc K100-A` — landing squash and animated RGB key wave

## Install and keep it running

```bash
./scripts/install.sh
```

This creates `/Applications/DeviceArrivalHUD.app`, registers it as a Login Item, launches it without a Dock or menu-bar icon, and immediately recognizes already-connected tracked devices. Connection polling defaults to 350 ms, and every HUD shell flies fluidly up from below the Dock before its device-specific choreography starts.

## Preview the animation system

```bash
swift run DeviceArrivalHUD --demo
swift run DeviceArrivalHUD --preview airpods connected
swift run DeviceArrivalHUD --preview xm4 disconnected
swift run DeviceArrivalHUD --preview keyboard connected
swift run DeviceArrivalHUD --render-previews .
```

## Configure actions

The first launch creates:

`~/Library/Application Support/DeviceArrivalHUD/config.json`

Each device supports `onConnect` and `onDisconnect` action arrays. Supported action types deliberately avoid arbitrary shell execution:

```json
"onConnect" : [
  { "kind" : "runShortcut", "value" : "Headphones Connected" },
  { "kind" : "launchApplication", "value" : "/Applications/Music.app" },
  { "kind" : "openURL", "value" : "https://music.apple.com" }
]
```

Changes apply after restarting the app. You can add more paired Bluetooth devices by copying a device entry and supplying its exact Bluetooth name as an alias.

## Development

```bash
swift test
./scripts/build_app.sh
```

The animation choreography is documented in `ANIMATION_DESIGN.md` and implemented by one deterministic `AnimationTimeline`, so snapshot previews and the live HUD cannot drift apart.
