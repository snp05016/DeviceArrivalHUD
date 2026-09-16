import AppKit
import Foundation

@MainActor
public final class DeviceActionRunner {
    private let configuration: DeviceArrivalConfiguration

    public init(configuration: DeviceArrivalConfiguration) {
        self.configuration = configuration
    }

    public func handle(_ event: DeviceEvent) {
        guard let device = configuration.devices.first(where: { $0.id == event.deviceID }) else { return }
        let actions = event.event == .connected ? device.onConnect : device.onDisconnect
        for action in actions { run(action) }
    }

    private func run(_ action: ConfiguredAction) {
        switch action.kind {
        case .openURL:
            guard let url = URL(string: action.value), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return }
            NSWorkspace.shared.open(url)
        case .launchApplication:
            let url = URL(fileURLWithPath: action.value)
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false
            NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        case .runShortcut:
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["run", action.value]
            try? process.run()
        }
    }
}

