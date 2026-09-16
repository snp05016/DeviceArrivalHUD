import Foundation

public final class ConfigurationStore: @unchecked Sendable {
    public static let shared = ConfigurationStore()
    public static let folderName = "DeviceArrivalHUD"
    public static let fileName = "config.json"

    public init() {}

    public var configurationURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return support.appendingPathComponent(Self.folderName, isDirectory: true).appendingPathComponent(Self.fileName)
    }

    public func load() -> DeviceArrivalConfiguration {
        let url = configurationURL
        if let data = try? Data(contentsOf: url),
           var decoded = try? JSONDecoder().decode(DeviceArrivalConfiguration.self, from: data) {
            // Upgrade early builds that polled too slowly for a convincing arrival animation.
            if decoded.pollInterval > 0.35 {
                decoded.pollInterval = 0.35
                try? save(decoded)
            }
            return decoded
        }
        let configuration = DeviceArrivalConfiguration()
        try? save(configuration)
        return configuration
    }

    public func save(_ configuration: DeviceArrivalConfiguration) throws {
        let url = configurationURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(configuration).write(to: url, options: .atomic)
    }
}
