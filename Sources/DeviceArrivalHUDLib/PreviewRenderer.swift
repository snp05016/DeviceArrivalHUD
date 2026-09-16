import AppKit
import SwiftUI

@MainActor
public enum PreviewRenderer {
    @discardableResult
    public static func render(event: DeviceEvent, to url: URL, elapsed: TimeInterval = 1.72) throws -> URL {
        let view = NSHostingView(rootView: ArrivalHUDView(event: event, fixedElapsed: elapsed))
        view.frame = NSRect(origin: .zero, size: HUDWindowController.size)
        view.appearance = NSAppearance(named: .darkAqua)
        view.layoutSubtreeIfNeeded()

        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            throw CocoaError(.fileWriteUnknown)
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}

