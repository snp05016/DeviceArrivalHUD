import SwiftUI

enum HUDPalette {
    static let ink = Color(red: 0.025, green: 0.045, blue: 0.075)
    static let panel = Color(red: 0.045, green: 0.075, blue: 0.115)
    static let navy = Color(red: 0.06, green: 0.15, blue: 0.28)
    static let blue = Color(red: 0.10, green: 0.43, blue: 0.82)
    static let cyan = Color(red: 0.18, green: 0.89, blue: 0.95)
    static let violet = Color(red: 0.55, green: 0.37, blue: 0.96)
    static let gold = Color(red: 1.00, green: 0.73, blue: 0.16)
    static let paper = Color(red: 0.92, green: 0.96, blue: 1.00)
    static let muted = Color(red: 0.39, green: 0.48, blue: 0.59)
    static let danger = Color(red: 1.00, green: 0.29, blue: 0.27)
}

private struct PixelPainter {
    var context: GraphicsContext
    let unit: CGFloat
    let origin: CGPoint

    mutating func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ color: Color, opacity: Double = 1) {
        let rect = CGRect(
            x: origin.x + CGFloat(x) * unit,
            y: origin.y + CGFloat(y) * unit,
            width: CGFloat(width) * unit,
            height: CGFloat(height) * unit
        ).integral
        context.fill(Path(rect), with: .color(color.opacity(opacity)))
    }
}

public struct PixelDeviceArt: View {
    public let kind: DeviceKind
    public let timeline: AnimationTimeline

    public init(kind: DeviceKind, timeline: AnimationTimeline) {
        self.kind = kind
        self.timeline = timeline
    }

    public var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            let unit = floor(min(size.width / 34, size.height / 26))
            var painter = PixelPainter(
                context: context,
                unit: unit,
                origin: CGPoint(x: (size.width - unit * 34) / 2, y: (size.height - unit * 26) / 2)
            )
            switch kind {
            case .airPods:
                Self.drawAirPods(with: &painter, timeline: timeline)
            case .headphones:
                Self.drawHeadphones(with: &painter, timeline: timeline)
            case .keyboard:
                Self.drawKeyboard(with: &painter, timeline: timeline)
            case .drive:
                Self.drawDrive(with: &painter, timeline: timeline)
            case .display:
                Self.drawDisplay(with: &painter, timeline: timeline)
            case .controller:
                Self.drawController(with: &painter, timeline: timeline)
            case .unknown:
                Self.drawUnknown(with: &painter, timeline: timeline)
            }
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(x: scaleX, y: scaleY, anchor: .center)
        .offset(y: verticalOffset)
    }

    private var rotation: Double {
        guard kind == .headphones else { return 0 }
        if timeline.event == .connected { return (1 - timeline.deviceEntrance) * -300 }
        return timeline.overall * 230
    }

    private var scaleX: Double {
        if kind == .keyboard {
            return 1 + sin(timeline.deviceEntrance * .pi) * 0.05
        }
        return 0.70 + timeline.directedEntrance * 0.30
    }

    private var scaleY: Double {
        if kind == .keyboard {
            let squash = sin(timeline.deviceEntrance * .pi) * 0.10
            return max(0.78, timeline.directedEntrance - squash + 0.08)
        }
        return 0.70 + timeline.directedEntrance * 0.30
    }

    private var verticalOffset: Double {
        let distance = kind == .keyboard ? 58.0 : 34.0
        return (1 - timeline.directedEntrance) * distance
    }

    private static func directed(_ value: Double, _ timeline: AnimationTimeline) -> Double {
        timeline.event == .connected ? value : 1 - value
    }

    private static func drawAirPods(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        let mechanism = directed(t.mechanism, t)
        let signal = directed(t.signal, t)

        // Blocky radio rings arrive last and collapse first.
        for index in 0..<3 {
            let reveal = AnimationTimeline.clamp(signal * 3 - Double(index))
            let inset = Double(index) * 2
            p.rect(2 - inset, 8 - inset, 2, 4 + inset * 2, HUDPalette.cyan, opacity: reveal * (0.9 - Double(index) * 0.18))
            p.rect(30 + inset, 8 - inset, 2, 4 + inset * 2, HUDPalette.cyan, opacity: reveal * (0.9 - Double(index) * 0.18))
        }

        // Charging case.
        p.rect(9, 14, 16, 8, HUDPalette.paper)
        p.rect(7, 16, 2, 4, HUDPalette.paper)
        p.rect(25, 16, 2, 4, HUDPalette.paper)
        p.rect(10, 20, 14, 3, HUDPalette.muted)
        p.rect(11, 17, 12, 4, Color.white)
        p.rect(16, 18, 2, 1, HUDPalette.gold)

        // Lid opens upward instead of becoming a generic fade.
        let lidRise = mechanism * 5
        p.rect(9, 13 - lidRise, 16, 2, HUDPalette.paper)
        p.rect(11, 12 - lidRise, 12, 1, Color.white)
        p.rect(10, 15 - lidRise * 0.35, 14, 1, HUDPalette.navy, opacity: 0.5)

        // Staggered buds.
        let left = AnimationTimeline.smoothstep(AnimationTimeline.segment(mechanism, from: 0.08, to: 0.68))
        let right = AnimationTimeline.smoothstep(AnimationTimeline.segment(mechanism, from: 0.25, to: 0.86))
        drawEarbud(with: &p, x: 11 - left * 3, y: 14 - left * 10, flipped: false)
        drawEarbud(with: &p, x: 20 + right * 3, y: 14 - right * 9, flipped: true)
        p.rect(15, 4, 4, 1, HUDPalette.gold, opacity: signal)
    }

    private static func drawEarbud(with p: inout PixelPainter, x: Double, y: Double, flipped: Bool) {
        let stemX = flipped ? x : x + 2
        p.rect(x, y, 3, 4, Color.white)
        p.rect(flipped ? x + 2 : x - 1, y + 1, 2, 2, HUDPalette.muted)
        p.rect(stemX, y + 3, 1, 6, Color.white)
        p.rect(stemX, y + 8, 2, 1, HUDPalette.muted)
        p.rect(flipped ? x : x + 2, y + 1, 1, 1, HUDPalette.ink)
    }

    private static func drawHeadphones(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        let mechanism = directed(t.mechanism, t)
        let signal = directed(t.signal, t)
        let expansion = mechanism * 3

        // Signal lock waves.
        for index in 0..<3 {
            let reveal = AnimationTimeline.clamp(signal * 2.4 - Double(index) * 0.7)
            let x = 2 - Double(index) * 2
            p.rect(x, 10 - Double(index), 2, 6 + Double(index) * 2, index == 1 ? HUDPalette.violet : HUDPalette.cyan, opacity: reveal * 0.75)
            p.rect(30 - x, 10 - Double(index), 2, 6 + Double(index) * 2, index == 1 ? HUDPalette.violet : HUDPalette.cyan, opacity: reveal * 0.75)
        }

        // Headband, with expanding sides.
        p.rect(11 - expansion, 3, 12 + expansion * 2, 2, HUDPalette.paper)
        p.rect(8 - expansion, 5, 3, 3, HUDPalette.paper)
        p.rect(23 + expansion, 5, 3, 3, HUDPalette.paper)
        p.rect(6 - expansion, 7, 3, 11, HUDPalette.blue)
        p.rect(25 + expansion, 7, 3, 11, HUDPalette.blue)
        p.rect(4 - expansion, 11, 4, 8, HUDPalette.ink)
        p.rect(26 + expansion, 11, 4, 8, HUDPalette.ink)
        p.rect(5 - expansion, 12, 2, 6, HUDPalette.violet)
        p.rect(27 + expansion, 12, 2, 6, HUDPalette.violet)
        p.rect(9, 3, 16, 1, HUDPalette.cyan, opacity: signal)
        p.rect(15, 21, 4, 2, HUDPalette.gold, opacity: signal)
    }

    private static func drawKeyboard(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        let mechanism = directed(t.mechanism, t)
        let columns = 11

        // Chassis and landing shadow.
        p.rect(3, 8, 28, 14, HUDPalette.ink)
        p.rect(4, 7, 26, 2, HUDPalette.muted)
        p.rect(5, 20, 24, 3, HUDPalette.navy)
        p.rect(8, 24, 18, 1, HUDPalette.blue, opacity: 0.4 + mechanism * 0.5)

        for row in 0..<4 {
            for column in 0..<columns {
                let wave = AnimationTimeline.clamp(mechanism * 1.65 - Double(column) / Double(columns) * 0.65)
                let off = HUDPalette.navy
                let lit: Color
                switch (column + row) % 4 {
                case 0: lit = HUDPalette.cyan
                case 1: lit = HUDPalette.blue
                case 2: lit = HUDPalette.violet
                default: lit = HUDPalette.gold
                }
                let keyColor = wave > 0.55 ? lit : off
                let pop = wave > 0.72 && ((column == 2 && row == 1) || (column == 6 && row == 2) || (column == 9 && row == 0))
                p.rect(6 + Double(column) * 2, 10 + Double(row) * 2 - (pop ? sin(mechanism * .pi * 3) * 1.5 : 0), 1, 1, keyColor)
            }
        }
        p.rect(12, 18, 12, 1, mechanism > 0.72 ? HUDPalette.paper : HUDPalette.navy)
    }

    private static func drawDrive(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        let signal = directed(t.signal, t)
        p.rect(7, 5, 20, 17, HUDPalette.muted)
        p.rect(9, 7, 16, 11, HUDPalette.ink)
        p.rect(11, 9, 12, 5, HUDPalette.navy)
        p.rect(22, 19, 2, 2, HUDPalette.cyan, opacity: signal)
        p.rect(9, 23, 16, 1, HUDPalette.blue, opacity: signal)
    }

    private static func drawDisplay(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        let signal = directed(t.signal, t)
        p.rect(3, 3, 28, 18, HUDPalette.paper)
        p.rect(5, 5, 24, 14, HUDPalette.ink)
        p.rect(7, 7, 20 * signal, 2, HUDPalette.cyan)
        p.rect(15, 21, 4, 3, HUDPalette.muted)
        p.rect(11, 24, 12, 1, HUDPalette.paper)
    }

    private static func drawController(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        let signal = directed(t.signal, t)
        p.rect(6, 8, 22, 10, HUDPalette.paper)
        p.rect(4, 13, 7, 8, HUDPalette.paper)
        p.rect(23, 13, 7, 8, HUDPalette.paper)
        p.rect(10, 11, 2, 6, HUDPalette.ink)
        p.rect(8, 13, 6, 2, HUDPalette.ink)
        p.rect(23, 12, 2, 2, HUDPalette.cyan, opacity: signal)
        p.rect(26, 15, 2, 2, HUDPalette.gold, opacity: signal)
    }

    private static func drawUnknown(with p: inout PixelPainter, timeline t: AnimationTimeline) {
        p.rect(7, 4, 20, 18, HUDPalette.navy)
        p.rect(9, 6, 16, 14, HUDPalette.ink)
        p.rect(15, 9, 4, 7, HUDPalette.cyan, opacity: directed(t.signal, t))
        p.rect(15, 18, 4, 2, HUDPalette.gold)
    }
}
