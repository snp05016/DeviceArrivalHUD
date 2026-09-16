import Foundation

public enum DeviceKind: String, Codable, CaseIterable, Sendable {
    case airPods
    case headphones
    case keyboard
    case drive
    case display
    case controller
    case unknown

    public var eyebrow: String {
        switch self {
        case .airPods: return "WIRELESS EARBUDS"
        case .headphones: return "OVER-EAR AUDIO"
        case .keyboard: return "INPUT DEVICE"
        case .drive: return "EXTERNAL STORAGE"
        case .display: return "DISPLAY LINK"
        case .controller: return "GAME CONTROLLER"
        case .unknown: return "NEW HARDWARE"
        }
    }
}

public enum DeviceEventKind: String, Codable, Sendable {
    case connected
    case disconnected

    public var label: String { self == .connected ? "CONNECTED" : "DEPARTED" }
    public var verb: String { self == .connected ? "link established" : "link closed" }
}

public struct ConfiguredAction: Codable, Equatable, Sendable {
    public enum ActionKind: String, Codable, Sendable {
        case openURL
        case launchApplication
        case runShortcut
    }

    public var kind: ActionKind
    public var value: String

    public init(kind: ActionKind, value: String) {
        self.kind = kind
        self.value = value
    }
}

public struct TrackedDevice: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var kind: DeviceKind
    public var aliases: [String]
    public var onConnect: [ConfiguredAction]
    public var onDisconnect: [ConfiguredAction]

    public init(
        id: String,
        displayName: String,
        kind: DeviceKind,
        aliases: [String],
        onConnect: [ConfiguredAction] = [],
        onDisconnect: [ConfiguredAction] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.aliases = aliases
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
    }

    public func matches(bluetoothName: String) -> Bool {
        let candidate = Self.normalized(bluetoothName)
        return ([displayName] + aliases).contains { alias in
            let normalizedAlias = Self.normalized(alias)
            return candidate == normalizedAlias || candidate.contains(normalizedAlias) || normalizedAlias.contains(candidate)
        }
    }

    public static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "’", with: "'")
            .uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]+", with: " ", options: .regularExpression)
            .split(separator: " ")
            .joined(separator: " ")
    }
}

public struct DeviceEvent: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let deviceID: String
    public let displayName: String
    public let kind: DeviceKind
    public let event: DeviceEventKind
    public let batteryPercentage: Int?
    public let occurredAt: Date
    public let isInitialSync: Bool

    public init(
        id: UUID = UUID(),
        deviceID: String,
        displayName: String,
        kind: DeviceKind,
        event: DeviceEventKind,
        batteryPercentage: Int? = nil,
        occurredAt: Date = Date(),
        isInitialSync: Bool = false
    ) {
        self.id = id
        self.deviceID = deviceID
        self.displayName = displayName
        self.kind = kind
        self.event = event
        self.batteryPercentage = batteryPercentage
        self.occurredAt = occurredAt
        self.isInitialSync = isInitialSync
    }
}

public struct DeviceArrivalConfiguration: Codable, Equatable, Sendable {
    public var pollInterval: TimeInterval
    public var showConnectedDevicesOnLaunch: Bool
    public var devices: [TrackedDevice]

    public init(
        pollInterval: TimeInterval = 0.35,
        showConnectedDevicesOnLaunch: Bool = true,
        devices: [TrackedDevice] = Self.saumyaDefaults
    ) {
        self.pollInterval = pollInterval
        self.showConnectedDevicesOnLaunch = showConnectedDevicesOnLaunch
        self.devices = devices
    }

    public static let saumyaDefaults: [TrackedDevice] = [
        TrackedDevice(
            id: "saumya-airpods-pro",
            displayName: "Saumya's AirPods Pro",
            kind: .airPods,
            aliases: ["Saumya’s AirPods Pro", "Saumya's AirPods Pro", "AirPods Pro"]
        ),
        TrackedDevice(
            id: "saumya-xm4",
            displayName: "Saumya's XM4",
            kind: .headphones,
            aliases: ["Saumya’s XM4s", "Saumya's XM4s", "Saumya’s XM4", "WH-1000XM4", "XM4s"]
        ),
        TrackedDevice(
            id: "protoarc-k100-a",
            displayName: "ProtoArc K100-A",
            kind: .keyboard,
            aliases: ["ProtoArc K100-A", "K100-A"]
        )
    ]
}
