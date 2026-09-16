import SwiftUI

public struct ArrivalHUDView: View {
    public let event: DeviceEvent
    public let startedAt: Date
    public let fixedElapsed: TimeInterval?

    public init(event: DeviceEvent, startedAt: Date = Date(), fixedElapsed: TimeInterval? = nil) {
        self.event = event
        self.startedAt = startedAt
        self.fixedElapsed = fixedElapsed
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: fixedElapsed != nil)) { context in
            let elapsed = fixedElapsed ?? context.date.timeIntervalSince(startedAt)
            let timeline = AnimationTimeline(event: event.event, elapsed: elapsed)
            content(timeline: timeline)
                .opacity(timeline.exitOpacity)
        }
        .frame(width: 620, height: 164)
    }

    @ViewBuilder
    private func content(timeline: AnimationTimeline) -> some View {
        ZStack {
            HUDPalette.ink.opacity(0.96)
            scanlines

            HStack(spacing: 0) {
                ZStack {
                    Rectangle().fill(HUDPalette.panel)
                    PixelDeviceArt(kind: event.kind, timeline: timeline)
                        .padding(8)
                }
                .frame(width: 180)
                .clipped()

                Rectangle().fill(HUDPalette.blue.opacity(0.65)).frame(width: 2)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text("NINE-NINE DEVICE DESK")
                            .foregroundStyle(HUDPalette.cyan)
                        Text("//")
                            .foregroundStyle(HUDPalette.muted)
                        Text(event.kind.eyebrow)
                            .foregroundStyle(HUDPalette.gold)
                        Spacer(minLength: 8)
                        SignalBars(progress: timeline.signal, connected: event.event == .connected)
                    }
                    .font(.system(size: 10, weight: .black, design: .monospaced))

                    Text(event.displayName.uppercased())
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(HUDPalette.paper)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .offset(x: (1 - timeline.copyReveal) * 24)
                        .opacity(timeline.copyReveal)

                    HStack(spacing: 10) {
                        Text(event.event.label)
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundStyle(event.event == .connected ? HUDPalette.ink : HUDPalette.paper)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(event.event == .connected ? HUDPalette.cyan : HUDPalette.danger)

                        Text(statusCopy)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(HUDPalette.muted)
                            .lineLimit(1)
                    }
                    .opacity(timeline.copyReveal)

                    HStack(spacing: 12) {
                        PixelProgressRail(progress: timeline.signal, connected: event.event == .connected)
                        if let battery = event.batteryPercentage {
                            PixelBatteryGauge(percentage: battery)
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.leading, 20)
                .padding(.trailing, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(HUDPalette.cyan).frame(height: 3) }
        .overlay(alignment: .bottom) { Rectangle().fill(HUDPalette.blue).frame(height: 3) }
        .overlay { Rectangle().stroke(HUDPalette.blue.opacity(0.85), lineWidth: 2) }
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .shadow(color: HUDPalette.cyan.opacity(0.25 * timeline.shellReveal), radius: 24, y: 7)
        .scaleEffect(x: 0.94 + timeline.shellReveal * 0.06, y: 0.80 + timeline.shellReveal * 0.20)
    }

    private var statusCopy: String {
        switch (event.kind, event.event) {
        case (.airPods, .connected): return "AUDIO CHANNEL OPEN"
        case (.airPods, .disconnected): return "BUDS SECURED"
        case (.headphones, .connected): return "NOISE CONTROL LOCKED"
        case (.headphones, .disconnected): return "SIGNAL STOOD DOWN"
        case (.keyboard, .connected): return "READY FOR DUTY"
        case (.keyboard, .disconnected): return "KEYBOARD OFF SHIFT"
        case (_, .connected): return "\(event.event.verb.uppercased())"
        case (_, .disconnected): return "\(event.event.verb.uppercased())"
        }
    }

    private var scanlines: some View {
        Canvas { context, size in
            var y: CGFloat = 1
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.white.opacity(0.025)))
                y += 4
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SignalBars: View {
    let progress: Double
    let connected: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                let active = progress > Double(index) / 4
                Rectangle()
                    .fill(active ? (connected ? HUDPalette.cyan : HUDPalette.danger) : HUDPalette.navy)
                    .frame(width: 3, height: CGFloat(3 + index * 3))
            }
        }
        .frame(height: 13, alignment: .bottom)
    }
}

private struct PixelProgressRail: View {
    let progress: Double
    let connected: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<16, id: \.self) { index in
                let isActive = progress >= Double(index + 1) / 16
                Rectangle()
                    .fill(isActive ? (connected ? HUDPalette.cyan : HUDPalette.danger) : HUDPalette.navy)
                    .frame(height: 7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PixelBatteryGauge: View {
    let percentage: Int

    var color: Color {
        if percentage <= 15 { return HUDPalette.danger }
        if percentage <= 35 { return HUDPalette.gold }
        return HUDPalette.cyan
    }

    var body: some View {
        HStack(spacing: 5) {
            ZStack(alignment: .leading) {
                Rectangle().stroke(HUDPalette.muted, lineWidth: 1).frame(width: 28, height: 10)
                Rectangle().fill(color).frame(width: CGFloat(max(1, min(24, percentage * 24 / 100))), height: 6).padding(.leading, 2)
            }
            Text("\(percentage)%")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

