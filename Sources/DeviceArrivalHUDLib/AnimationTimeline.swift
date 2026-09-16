import Foundation

public struct AnimationTimeline: Equatable, Sendable {
    public let event: DeviceEventKind
    public let elapsed: TimeInterval

    public static let motionDuration: TimeInterval = 2.15
    public static let totalDuration: TimeInterval = 4.15

    public init(event: DeviceEventKind, elapsed: TimeInterval) {
        self.event = event
        self.elapsed = max(0, elapsed)
    }

    public var overall: Double { Self.clamp(elapsed / Self.motionDuration) }
    public var shellReveal: Double { Self.smoothstep(Self.segment(overall, from: 0.00, to: 0.16)) }
    public var deviceEntrance: Double { Self.backOut(Self.segment(overall, from: 0.05, to: 0.48)) }
    public var mechanism: Double { Self.smoothstep(Self.segment(overall, from: 0.25, to: 0.70)) }
    public var signal: Double { Self.smoothstep(Self.segment(overall, from: 0.50, to: 1.00)) }
    public var copyReveal: Double { Self.smoothstep(Self.segment(overall, from: 0.34, to: 0.72)) }
    public var exitOpacity: Double {
        1 - Self.smoothstep(Self.segment(elapsed, from: Self.totalDuration - 0.38, to: Self.totalDuration))
    }

    public var directedEntrance: Double {
        event == .connected ? deviceEntrance : 1 - Self.smoothstep(Self.segment(overall, from: 0.08, to: 0.82))
    }

    public static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }

    public static func segment(_ value: Double, from: Double, to: Double) -> Double {
        guard to > from else { return value >= to ? 1 : 0 }
        return clamp((value - from) / (to - from))
    }

    public static func smoothstep(_ value: Double) -> Double {
        let x = clamp(value)
        return x * x * (3 - 2 * x)
    }

    public static func backOut(_ value: Double) -> Double {
        let x = clamp(value) - 1
        let overshoot = 1.70158
        return 1 + (overshoot + 1) * x * x * x + overshoot * x * x
    }
}

