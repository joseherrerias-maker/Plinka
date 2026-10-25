import AVFoundation
import Foundation
import Combine

/// Offline-first sound engine for the first native prototype.
/// A complete PCM phrase is rendered before playback: notes have sample-accurate
/// timing and playing two instruments on the same beat works naturally.
@MainActor
final class PlinkaAudio: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false
    @Published private(set) var playheadStep: Double?
    @Published var audioError: String?

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: 44_100, channels: 1, interleaved: false)!
    private var activeBuffer: AVAudioPCMBuffer?
    private var ticker: Timer?
    private var pausedStep: Double = 0
    private var phraseDuration: TimeInterval = 0
    private var stepSeconds: TimeInterval = 0
    private var lastStep = 0
    private var looping = false
    private static let recordedInstruments: [Instrument] = [.puppy, .chicken, .pig, .cow, .frog]
    private var recordings: [Instrument: [Float]] = [:]

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.72
        for instrument in Self.recordedInstruments {
            guard let url = Bundle.main.url(forResource: instrument.rawValue,
                                            withExtension: "wav", subdirectory: "Sounds"),
                  let file = try? AVAudioFile(forReading: url),
                  file.processingFormat.sampleRate == 44_100,
                  file.processingFormat.channelCount == 1,
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                 frameCapacity: AVAudioFrameCount(file.length)),
                  (try? file.read(into: buffer)) != nil,
                  let channel = buffer.floatChannelData?[0], buffer.frameLength > 0 else { continue }
            recordings[instrument] = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
        }
    }

    private func prepareAudio() throws {
        guard recordings.count == Self.recordedInstruments.count else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning { try engine.start() }
    }

    func preview(_ instrument: Instrument, row: Int) {
        guard !isPlaying, SongStore.pitches.indices.contains(row) else { return }
        do {
            try prepareAudio()
            let preview = Song(notes: [MusicNote(step: 0, row: row, instrument: instrument)])
            let rendered = render(song: preview, minimumDuration: 0.48)
            player.stop()
            activeBuffer = rendered.buffer
            player.scheduleBuffer(rendered.buffer, at: nil, options: [])
            player.play()
            audioError = nil
        } catch {
            audioError = "Could not play sound. Check your device audio."
        }
    }

    func playOrPause(_ song: Song) {
        if isPlaying {
            if isPaused {
                player.play()
                isPaused = false
                startTicker()
            } else {
                pause()
            }
        } else {
            start(song)
        }
    }

    func start(_ song: Song) {
        guard !song.notes.isEmpty else { return }
        do {
            try prepareAudio()
            player.stop()
            let rendered = render(song: song)
            activeBuffer = rendered.buffer
            phraseDuration = rendered.duration
            stepSeconds = rendered.stepSeconds
            lastStep = rendered.lastStep
            looping = song.loop
            player.scheduleBuffer(rendered.buffer, at: nil,
                                  options: looping ? [.loops] : [])
            player.play()
            pausedStep = 0
            isPlaying = true
            isPaused = false
            playheadStep = 0
            audioError = nil
            startTicker()
        } catch {
            audioError = "Pluki could not start audio on this device."
            stop()
        }
    }

    func stop() {
        stopTicker()
        player.stop()
        activeBuffer = nil
        isPlaying = false
        isPaused = false
        playheadStep = nil
        pausedStep = 0
    }

    func updateLoop(_ song: Song) {
        // A native audio buffer can be looped without timing drift.
        // Changing the toggle while playing restarts the phrase from beat one.
        if isPlaying { start(song) }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        guard isPlaying, !isPaused else { return }
        pausedStep = currentPlaybackStep() ?? 0
        player.pause()
        isPaused = true
        stopTicker()
    }

    // Use the audio player's sample timeline so pauses and render startup do
    // not introduce wall-clock drift into the playhead or scrolling.
    private var elapsedAudioTime: TimeInterval? {
        guard let nodeTime = player.lastRenderTime,
              let time = player.playerTime(forNodeTime: nodeTime), time.sampleRate > 0 else { return nil }
        return max(0, Double(time.sampleTime) / time.sampleRate)
    }

    func currentPlaybackStep() -> Double? {
        guard isPlaying, stepSeconds > 0 else { return nil }
        if isPaused { return pausedStep }
        guard let elapsed = elapsedAudioTime else { return 0 }
        let local = looping ? elapsed.truncatingRemainder(dividingBy: phraseDuration) : elapsed
        return min(Double(lastStep) + 0.8, local / stepSeconds)
    }

    private func tick() {
        guard isPlaying, !isPaused, let elapsed = elapsedAudioTime else { return }
        if !looping && elapsed >= phraseDuration { stop(); return }
        // Only publish beat changes for sticker highlighting. The scroll view
        // reads the continuous sample position independently on each frame.
        if let step = currentPlaybackStep() {
            let beat = floor(step)
            if playheadStep != beat { playheadStep = beat }
        }
    }

    private struct RenderResult {
        let buffer: AVAudioPCMBuffer
        let duration: TimeInterval
        let stepSeconds: TimeInterval
        let lastStep: Int
    }

    private func render(song: Song, minimumDuration: TimeInterval = 0) -> RenderResult {
        let bpm = max(65, min(160, song.tempo))
        let stepSeconds = 30.0 / bpm
        let last = song.notes.map(\.step).max() ?? 0
        // Natural ending after the last note. Repeat at least one measure
        // when looping, so a one-note melody doesn't stutter rapidly.
        let normalEnd = song.notes.map { note -> Double in
            let pitch = SongStore.pitches.indices.contains(note.row) ? SongStore.pitches[note.row] : 69
            let ratio = pow(2.0, Double(pitch - 69) / 12.0)
            let tail = recordings[note.instrument].map { Double($0.count) / format.sampleRate / ratio } ?? 0.60
            return Double(note.step) * stepSeconds + tail + 0.03
        }.max() ?? 0.63
        let duration = max(minimumDuration, song.loop
            ? max(8 * stepSeconds, normalEnd)
            : max(1.4 * stepSeconds, normalEnd))
        let frameCount = AVAudioFrameCount(ceil(duration * format.sampleRate))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) { samples[i] = 0 }

        for note in song.notes {
            guard SongStore.pitches.indices.contains(note.row) else { continue }
            let frequency = 440.0 * pow(2.0,
                Double(SongStore.pitches[note.row] - 69) / 12.0)
            let offset = Int(Double(note.step) * stepSeconds * format.sampleRate)
            let remaining = Int(frameCount) - offset
            if remaining <= 0 { continue }
            let noteDuration = recordings[note.instrument].map {
                Double($0.count) / format.sampleRate / (frequency / 440.0)
            } ?? 0.60
            let sampleCount = min(remaining, Int(ceil(noteDuration * format.sampleRate)))
            addNote(note.instrument, frequency: frequency, into: samples,
                    offset: offset, count: sampleCount)
        }
        for i in 0..<Int(frameCount) {
            // Soft limit stacked notes without harsh clipping.
            samples[i] = Float(tanh(Double(samples[i]) * 0.8))
        }
        return RenderResult(buffer: buffer, duration: Double(frameCount) / format.sampleRate,
                            stepSeconds: stepSeconds, lastStep: last)
    }

    private func addNote(_ instrument: Instrument, frequency f: Double,
                         into output: UnsafeMutablePointer<Float>, offset: Int, count: Int) {
        let rate = format.sampleRate
        if let recording = recordings[instrument] {
            // Pitch follows the staff; sample tails are included in phrase length.
            let ratio = f / 440.0
            for i in 0..<count {
                let position = Double(i) * ratio
                let index = Int(position)
                guard index + 1 < recording.count else { break }
                let fraction = Float(position - Double(index))
                let sample = recording[index] * (1 - fraction) + recording[index + 1] * fraction
                output[offset + i] += sample * 0.28
            }
            return
        }
        let tau = Double.pi * 2
        var seed: UInt32 = UInt32(8_411 + Int(f * 53))
        func random() -> Double {
            seed = 1_664_525 &* seed &+ 1_013_904_223
            return Double(seed) / Double(UInt32.max) * 2 - 1
        }

        // Simple Karplus–Strong string: a plucked guitar behaves differently
        // from a piano oscillator, even before we add recorded samples.
        let period = max(12, Int((rate / f).rounded()))
        var string = [Double](repeating: 0, count: period)
        if instrument == .guitar {
            for j in 0..<period {
                let position = Double(j) / Double(period)
                let pluck = position < 0.23 ? position / 0.23 : (1 - position) / 0.77
                string[j] = (pluck * 2 - 1) * 0.7 + random() * 0.18
            }
        }

        for i in 0..<count {
            let t = Double(i) / rate
            let fundamental = sin(tau * f * t)
            var value: Double
            switch instrument {
            case .piano:
                value = (fundamental * 0.78 + sin(tau * f * 2 * t) * 0.18)
                    * exp(-5.5 * t)
            case .xylophone:
                value = (fundamental * 0.72 + sin(tau * f * 3 * t) * 0.22)
                    * exp(-10.0 * t)
            case .guitar:
                let j = i % period
                let next = (j + 1) % period
                value = (string[j] + string[next]) * 0.5
                string[j] = value * 0.996
                value *= exp(-4.0 * t)
            case .trumpet:
                value = (sin(tau * f * t) * 0.55 +
                         sin(tau * 2 * f * t) * 0.28 +
                         sin(tau * 3 * f * t) * 0.11)
                    * min(1, t * 33) * exp(-2.9 * t)
            case .flute:
                value = (fundamental * 0.90 + sin(tau * 2 * f * t) * 0.07)
                    * min(1, t * 28) * exp(-2.9 * t)
            case .bells:
                value = (fundamental * 0.65 +
                         sin(tau * 2.76 * f * t) * 0.24 +
                         sin(tau * 4.05 * f * t) * 0.12) * exp(-4.3 * t)
            case .synth:
                value = (fundamental * 0.65 +
                         sin(tau * f * 1.01 * t) * 0.35) * exp(-3.8 * t)
            case .puppy, .chicken, .pig, .cow, .frog:
                // Recorded sounds return above. Never substitute a drum oscillator.
                value = 0
            case .kitten:
                // A voiced meow: rising then falling pitch and a nasal overtone.
                let phase = tau * f * (0.85 * t + 0.9 * t * t - t * t * t)
                let envelope = min(1, t * 22) * exp(-5 * t)
                value = (sin(phase) * 0.60 + sin(2 * phase) * 0.28
                    + sin(3 * phase) * 0.12) * envelope
            case .sparkle:
                // Three overlapping bright chimes form a tiny upward flourish.
                value = 0
                for partial in 0..<3 {
                    let local = t - Double(partial) * 0.055
                    if local >= 0 {
                        let pitch = f * pow(1.5, Double(partial))
                        value += sin(tau * pitch * local)
                            * min(1, local * 500) * exp(-12 * local) * 0.48
                    }
                }
            case .boing:
                // Integrating the wobbling pitch keeps the waveform continuous.
                let wobble = (1 - cos(tau * 11 * t)) / (tau * 11)
                let phase = tau * f * (0.65 * t + 0.25 * wobble)
                value = (sin(phase) * 0.78 + sin(2 * phase) * 0.18)
                    * exp(-6 * t)
            case .bubbles:
                value = 0
                for bubble in 0..<3 {
                    let local = t - Double(bubble) * 0.14
                    if local >= 0 && local < 0.11 {
                        let pitch = f * (1.1 + Double(bubble) * 0.3)
                        let phase = tau * pitch * (local + 5 * local * local)
                        value += sin(phase) * sin(Double.pi * local / 0.11) * exp(-18 * local)
                    }
                }
            case .whistle:
                let phase = tau * f * (t + 1.1 * t * t)
                value = sin(phase) * min(1, t * 30) * exp(-3 * t)
            case .laser:
                // Continuous exponential down-glide: a soft cartoon "pew".
                let phase = tau * f * 2.4 * (1 - exp(-9 * t)) / 9
                value = (sin(phase) * 0.8 + sin(phase * 2) * 0.12) * exp(-8 * t)
            case .drums:
                if f < 420 {
                    value = sin(tau * (90 - 58 * min(t, 0.20)) * t) * exp(-18 * t)
                } else {
                    value = random() * exp(-23 * t)
                }
            }
            // A brief anti-click fade, then quick decay appropriate for
            // toy-like musical stickers.
            let attack = min(1.0, t * 500.0)
            let release = min(1.0, Double(count - 1 - i) / (rate * 0.015))
            output[offset + i] += Float(value * attack * release * 0.24)
        }
    }
}
