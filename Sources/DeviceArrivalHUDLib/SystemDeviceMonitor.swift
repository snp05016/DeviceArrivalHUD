import AppKit
import CoreGraphics
import GameController

@MainActor
public final class SystemDeviceMonitor {
    public typealias EventHandler = (DeviceEvent) -> Void

    private let eventHandler: EventHandler
    private var observers: [NSObjectProtocol] = []
    private var knownScreens: [CGDirectDisplayID: String] = [:]

    public init(eventHandler: @escaping EventHandler) {
        self.eventHandler = eventHandler
    }

    public func start() {
        guard observers.isEmpty else { return }
        knownScreens = Self.screenMap()
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { [weak self] note in
            Task { @MainActor in self?.handleVolume(note, event: .connected) }
        })
        observers.append(center.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main) { [weak self] note in
            Task { @MainActor in self?.handleVolume(note, event: .disconnected) }
        })
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleScreenChange() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] note in
            Task { @MainActor in self?.handleController(note, event: .connected) }
        })
        observers.append(NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] note in
            Task { @MainActor in self?.handleController(note, event: .disconnected) }
        })
    }

    public func stop() {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    private func handleVolume(_ notification: Notification, event: DeviceEventKind) {
        guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        let values = try? url.resourceValues(forKeys: [.volumeIsInternalKey, .volumeNameKey])
        guard values?.volumeIsInternal != true else { return }
        let name = values?.volumeName ?? url.lastPathComponent
        eventHandler(DeviceEvent(deviceID: "drive-\(name)", displayName: name, kind: .drive, event: event))
    }

    private func handleScreenChange() {
        let next = Self.screenMap()
        for (id, name) in next where knownScreens[id] == nil {
            eventHandler(DeviceEvent(deviceID: "display-\(id)", displayName: name, kind: .display, event: .connected))
        }
        for (id, name) in knownScreens where next[id] == nil {
            eventHandler(DeviceEvent(deviceID: "display-\(id)", displayName: name, kind: .display, event: .disconnected))
        }
        knownScreens = next
    }

    private func handleController(_ notification: Notification, event: DeviceEventKind) {
        guard let controller = notification.object as? GCController else { return }
        let name = controller.vendorName ?? "Game Controller"
        eventHandler(DeviceEvent(deviceID: "controller-\(name)", displayName: name, kind: .controller, event: event))
    }

    private static func screenMap() -> [CGDirectDisplayID: String] {
        Dictionary(uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
            return (CGDirectDisplayID(number.uint32Value), screen.localizedName)
        })
    }
}

