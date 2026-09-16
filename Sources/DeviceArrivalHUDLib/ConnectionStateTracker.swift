import Foundation

public struct ConnectionSnapshot: Equatable, Sendable {
    public var connectedDeviceIDs: Set<String>

    public init(connectedDeviceIDs: Set<String> = []) {
        self.connectedDeviceIDs = connectedDeviceIDs
    }
}

public struct ConnectionDelta: Equatable, Sendable {
    public let connected: Set<String>
    public let disconnected: Set<String>
}

public struct ConnectionStateTracker: Sendable {
    private var snapshot: ConnectionSnapshot?

    public init() {}

    public mutating func ingest(_ next: ConnectionSnapshot) -> ConnectionDelta? {
        guard let previous = snapshot else {
            snapshot = next
            return nil
        }

        snapshot = next
        return ConnectionDelta(
            connected: next.connectedDeviceIDs.subtracting(previous.connectedDeviceIDs),
            disconnected: previous.connectedDeviceIDs.subtracting(next.connectedDeviceIDs)
        )
    }
}

