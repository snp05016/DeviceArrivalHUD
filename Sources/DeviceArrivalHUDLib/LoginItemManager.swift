import AppKit
import Foundation
import ServiceManagement

public final class LoginItemManager: @unchecked Sendable {
    public static let shared = LoginItemManager()
    public static let appName = "DeviceArrivalHUD"
    public static let defaultAppBundlePath = "/Applications/DeviceArrivalHUD.app"

    public init() {}

    public var isEnabled: Bool {
        if #available(macOS 13.0, *), Bundle.main.bundleIdentifier == "com.saumya.DeviceArrivalHUD",
           SMAppService.mainApp.status == .enabled { return true }
        return runAppleScriptBoolean("""
        tell application "System Events"
            return exists (login item "\(Self.appName)")
        end tell
        """)
    }

    @discardableResult
    public func enable(appPath: String = defaultAppBundlePath) -> Bool {
        if #available(macOS 13.0, *), Bundle.main.bundleIdentifier == "com.saumya.DeviceArrivalHUD" {
            do {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
                if SMAppService.mainApp.status == .enabled { return true }
            } catch {}
        }
        return runAppleScriptBoolean("""
        tell application "System Events"
            if exists (login item "\(Self.appName)") then delete login item "\(Self.appName)"
            make login item at end with properties {path:"\(appPath)", hidden:true, name:"\(Self.appName)"}
            return exists (login item "\(Self.appName)")
        end tell
        """)
    }

    @discardableResult
    public func disable() -> Bool {
        if #available(macOS 13.0, *), Bundle.main.bundleIdentifier == "com.saumya.DeviceArrivalHUD" {
            try? SMAppService.mainApp.unregister()
        }
        return runAppleScriptBoolean("""
        tell application "System Events"
            if exists (login item "\(Self.appName)") then delete login item "\(Self.appName)"
            return not (exists (login item "\(Self.appName)"))
        end tell
        """)
    }

    private func runAppleScriptBoolean(_ source: String) -> Bool {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        process.standardOutput = output
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            return process.terminationStatus == 0 && String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        } catch { return false }
    }
}

