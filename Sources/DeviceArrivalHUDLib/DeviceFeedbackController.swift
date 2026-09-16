import AppKit
import AVFoundation

public enum DeviceChimeSynthesizer {
    public static func samples(kind: DeviceKind, event: DeviceEventKind, sampleRate: Double = 44_100) -> [Float] {
        let connectedNotes: [Double]
        switch kind {
        case .airPods: connectedNotes = [659, 988, 1_318]
        case .headphones: connectedNotes = [220, 330, 440]
        case .keyboard: connectedNotes = [392, 523, 659, 784]
        case .drive: connectedNotes = [262, 392]
        case .display: connectedNotes = [330, 660]
        case .controller: connectedNotes = [294, 440, 587]
        case .unknown: connectedNotes = [330, 494]
        }
        let notes = event == .connected ? connectedNotes : connectedNotes.reversed()
        let samplesPerNote = Int(sampleRate * 0.052)
        return notes.enumerated().flatMap { noteIndex, frequency in
            (0..<samplesPerNote).map { sampleIndex in
                let progress = Double(sampleIndex) / Double(samplesPerNote)
                let absoluteIndex = noteIndex * samplesPerNote + sampleIndex
                let phase = 2 * Double.pi * frequency * Double(absoluteIndex) / sampleRate
                let square = sin(phase) >= 0 ? 1.0 : -1.0
                let envelope = min(1, progress / 0.08) * min(1, (1 - progress) / 0.30)
                return Float(square * envelope * (event == .connected ? 0.045 : 0.032))
            }
        }
    }
}

@MainActor
public final class DeviceFeedbackController {
    public static let shared = DeviceFeedbackController()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
    }

    public func perform(for event: DeviceEvent) {
        NSHapticFeedbackManager.defaultPerformer.perform(
            event.event == .connected ? .alignment : .levelChange,
            performanceTime: .now
        )
        let samples = DeviceChimeSynthesizer.samples(kind: event.kind, event: event.event, sampleRate: format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        for (index, sample) in samples.enumerated() { channel[index] = sample }
        do {
            if !engine.isRunning { try engine.start() }
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            if !player.isPlaying { player.play() }
        } catch {
            // Hardware arrival visuals remain available when the current route cannot play audio.
        }
    }
}

