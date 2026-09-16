import Foundation
import IOBluetooth

@MainActor
public final class BluetoothConnectionMonitor {
    public typealias EventHandler = (DeviceEvent) -> Void

    private let configuration: DeviceArrivalConfiguration
    private let eventHandler: EventHandler
    private var timer: Timer?
    private var tracker = ConnectionStateTracker()
    private var didPerformInitialScan = false

    public init(configuration: DeviceArrivalConfiguration, eventHandler: @escaping EventHandler) {
        self.configuration = configuration
        self.eventHandler = eventHandler
    }

    public func start() {
        guard timer == nil else { return }
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: max(0.2, configuration.pollInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let pairedDevices = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        let connectedNames = pairedDevices.compactMap { device -> String? in
            guard device.isConnected() else { return nil }
            return device.name
        }

        let matched = Dictionary(uniqueKeysWithValues: configuration.devices.compactMap { configured -> (String, (TrackedDevice, String))? in
            guard let bluetoothName = connectedNames.first(where: configured.matches(bluetoothName:)) else { return nil }
            return (configured.id, (configured, bluetoothName))
        })
        let next = ConnectionSnapshot(connectedDeviceIDs: Set(matched.keys))

        if !didPerformInitialScan {
            _ = tracker.ingest(next)
            didPerformInitialScan = true
            if configuration.showConnectedDevicesOnLaunch {
                for (_, pair) in matched.sorted(by: { $0.key < $1.key }) {
                    emit(device: pair.0, bluetoothName: pair.1, event: .connected, isInitial: true)
                }
            }
            return
        }

        guard let delta = tracker.ingest(next) else { return }
        for deviceID in delta.connected.sorted() {
            guard let pair = matched[deviceID] else { continue }
            emit(device: pair.0, bluetoothName: pair.1, event: .connected, isInitial: false)
        }
        for deviceID in delta.disconnected.sorted() {
            guard let configured = configuration.devices.first(where: { $0.id == deviceID }) else { continue }
            emit(device: configured, bluetoothName: configured.displayName, event: .disconnected, isInitial: false)
        }
    }

    private func emit(device: TrackedDevice, bluetoothName: String, event: DeviceEventKind, isInitial: Bool) {
        eventHandler(DeviceEvent(
            deviceID: device.id,
            displayName: device.displayName,
            kind: device.kind,
            event: event,
            batteryPercentage: event == .connected ? BatteryReader.percentage(forDeviceNamed: bluetoothName) : nil,
            isInitialSync: isInitial
        ))
    }
}
