import AppKit
import SwiftUI

@MainActor
public final class HUDWindowController {
    public static let size = CGSize(width: 620, height: 164)

    private var panel: NSPanel?
    private var queue: [DeviceEvent] = []
    private var isPresenting = false

    public init() {}

    public func enqueue(_ event: DeviceEvent) {
        queue.append(event)
        if !isPresenting { presentNext() }
    }

    public func enqueue(_ events: [DeviceEvent]) {
        queue.append(contentsOf: events)
        if !isPresenting { presentNext() }
    }

    private func presentNext() {
        guard !queue.isEmpty else {
            isPresenting = false
            return
        }
        isPresenting = true
        let event = queue.removeFirst()
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(rootView: ArrivalHUDView(event: event).id(event.id))
        panel.setContentSize(Self.size)
        let targetOrigin = targetOrigin()
        panel.setFrameOrigin(NSPoint(x: targetOrigin.x, y: targetOrigin.y - 150))
        panel.alphaValue = 0.18
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(targetOrigin)
            panel.animator().alphaValue = 1
        }

        // Never delay the first visible frame while the audio engine wakes up.
        DispatchQueue.main.async {
            DeviceFeedbackController.shared.perform(for: event)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTimeline.totalDuration - 0.34) { [weak panel] in
            guard let panel else { return }
            let origin = panel.frame.origin
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.32
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrameOrigin(NSPoint(x: origin.x, y: origin.y - 82))
                panel.animator().alphaValue = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTimeline.totalDuration) { [weak self, weak panel] in
            guard let self, let panel else { return }
            panel.orderOut(nil)
            self.presentNext()
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func targetOrigin() -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
        guard let frame = screen?.visibleFrame else { return .zero }
        return NSPoint(x: round(frame.midX - Self.size.width / 2), y: round(frame.minY + 68))
    }
}
