import AppKit
import DeviceArrivalHUDLib
import Foundation

private enum LaunchMode {
    case normal
    case demo
    case preview(DeviceKind, DeviceEventKind)
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mode: LaunchMode
    private let configuration = ConfigurationStore.shared.load()
    private let hud = HUDWindowController()
    private var bluetoothMonitor: BluetoothConnectionMonitor?
    private var systemMonitor: SystemDeviceMonitor?
    private var actionRunner: DeviceActionRunner?

    init(mode: LaunchMode) {
        self.mode = mode
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        switch mode {
        case .normal:
            let actions = DeviceActionRunner(configuration: configuration)
            actionRunner = actions
            let handler: (DeviceEvent) -> Void = { [weak self] event in
                self?.hud.enqueue(event)
                self?.actionRunner?.handle(event)
                var payload: [String: Any] = [
                    "id": event.deviceID,
                    "name": event.displayName,
                    "kind": event.kind.rawValue,
                    "connected": event.event == .connected
                ]
                if let battery = event.batteryPercentage { payload["battery"] = battery }
                DistributedNotificationCenter.default().postNotificationName(
                    Notification.Name("com.saumya.DeviceArrivalHUD.event"),
                    object: nil,
                    userInfo: payload,
                    deliverImmediately: true
                )
            }
            let bluetooth = BluetoothConnectionMonitor(configuration: configuration, eventHandler: handler)
            let system = SystemDeviceMonitor(eventHandler: handler)
            bluetoothMonitor = bluetooth
            systemMonitor = system
            bluetooth.start()
            system.start()

        case .demo:
            hud.enqueue(Self.demoEvents)
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTimeline.totalDuration * Double(Self.demoEvents.count) + 0.5) {
                NSApp.terminate(nil)
            }

        case let .preview(kind, event):
            hud.enqueue(Self.previewEvent(kind: kind, event: event))
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTimeline.totalDuration + 0.3) {
                NSApp.terminate(nil)
            }
        }
    }

    nonisolated fileprivate static func previewEvent(kind: DeviceKind, event: DeviceEventKind) -> DeviceEvent {
        let device = DeviceArrivalConfiguration.saumyaDefaults.first(where: { $0.kind == kind })
        return DeviceEvent(
            deviceID: device?.id ?? "preview-\(kind.rawValue)",
            displayName: device?.displayName ?? kind.eyebrow,
            kind: kind,
            event: event,
            batteryPercentage: event == .connected ? 84 : nil
        )
    }

    private static let demoEvents: [DeviceEvent] = [
        previewEvent(kind: .airPods, event: .connected),
        previewEvent(kind: .airPods, event: .disconnected),
        previewEvent(kind: .headphones, event: .connected),
        previewEvent(kind: .headphones, event: .disconnected),
        previewEvent(kind: .keyboard, event: .connected),
        previewEvent(kind: .keyboard, event: .disconnected)
    ]
}

private func parsedDeviceKind(_ value: String) -> DeviceKind? {
    switch value.lowercased() {
    case "airpods", "airpod", "buds": return .airPods
    case "xm4", "headphones": return .headphones
    case "keyboard", "k100", "protoarc": return .keyboard
    case "drive": return .drive
    case "display", "monitor": return .display
    case "controller", "gamepad": return .controller
    default: return nil
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.contains("--enable-login") {
    print(LoginItemManager.shared.enable() ? "enabled" : "failed")
    exit(LoginItemManager.shared.isEnabled ? 0 : 1)
}
if arguments.contains("--disable-login") {
    print(LoginItemManager.shared.disable() ? "disabled" : "failed")
    exit(LoginItemManager.shared.isEnabled ? 1 : 0)
}
if arguments.contains("--status-login") {
    print(LoginItemManager.shared.isEnabled ? "enabled" : "disabled")
    exit(LoginItemManager.shared.isEnabled ? 0 : 1)
}
if arguments.contains("--write-default-config") {
    try ConfigurationStore.shared.save(DeviceArrivalConfiguration())
    print(ConfigurationStore.shared.configurationURL.path)
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

if let renderIndex = arguments.firstIndex(of: "--render-previews") {
    let destination = arguments.indices.contains(renderIndex + 1)
        ? URL(fileURLWithPath: arguments[renderIndex + 1], isDirectory: true)
        : URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    let previews: [(String, DeviceKind, DeviceEventKind)] = [
        ("preview-airpods-connected.png", .airPods, .connected),
        ("preview-airpods-departed.png", .airPods, .disconnected),
        ("preview-xm4-connected.png", .headphones, .connected),
        ("preview-xm4-departed.png", .headphones, .disconnected),
        ("preview-k100-connected.png", .keyboard, .connected),
        ("preview-k100-departed.png", .keyboard, .disconnected)
    ]
    for (filename, kind, event) in previews {
        let model = AppDelegate.previewEvent(kind: kind, event: event)
        let url = destination.appendingPathComponent(filename)
        _ = try MainActor.assumeIsolated {
            try PreviewRenderer.render(event: model, to: url, elapsed: event == .connected ? 1.72 : 0.92)
        }
        print(url.path)
    }
    exit(0)
}

private let mode: LaunchMode
if arguments.contains("--demo") {
    mode = .demo
} else if let previewIndex = arguments.firstIndex(of: "--preview"),
          arguments.indices.contains(previewIndex + 2),
          let kind = parsedDeviceKind(arguments[previewIndex + 1]),
          let event = DeviceEventKind(rawValue: arguments[previewIndex + 2].lowercased()) {
    mode = .preview(kind, event)
} else {
    mode = .normal
}

private let delegate = MainActor.assumeIsolated { AppDelegate(mode: mode) }
app.delegate = delegate
app.run()
