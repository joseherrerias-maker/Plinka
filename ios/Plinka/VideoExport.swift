import SwiftUI
import AVKit
import Photos

private enum VideoShape: String, CaseIterable, Identifiable {
    case vertical = "Vertical", landscape = "Landscape"
    var id: String { rawValue }
    var size: CGSize { self == .vertical ? CGSize(width: 720, height: 1280) : CGSize(width: 1280, height: 720) }
}

private enum SongVideoError: LocalizedError {
    case failed, photosDenied
    var errorDescription: String? {
        switch self {
        case .failed: return "The video could not be created. Check that your device has free space and try again."
        case .photosDenied: return "Allow Pluki to add videos to Photos in iPhone or iPad Settings, then try Save to Photos again."
        }
    }
}

struct SongVideoExportView: View {
    let song: Song
    @StateObject private var model = SongVideoExportModel()
    @State private var shape: VideoShape = .vertical
    @State private var showParentGate = false
    @State private var parentApproved = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(song.title).font(.title2.bold()).multilineTextAlignment(.center)
                    if let player = model.player {
                        VideoPlayer(player: player)
                            .aspectRatio(model.previewRatio, contentMode: .fit)
                            .frame(maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        Button(model.saved ? "Saved to Photos" : "Save to Photos", systemImage: model.saved ? "checkmark.circle.fill" : "square.and.arrow.down") {
                            model.player?.pause()
                            parentApproved = false
                            if PHPhotoLibrary.authorizationStatus(for: .addOnly) == .notDetermined {
                                showParentGate = true
                            } else {
                                model.saveToPhotos()
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(.green)
                        .disabled(model.saving || model.saved)
                        if model.saving { ProgressView("Saving…") }
                        Button("Make another format") { model.clearPreview() }
                            .disabled(model.saving)
                    } else if model.working {
                        ProgressView(value: model.progress)
                        Text(model.progress < 0.85 ? "Creating your music video…" : "Finishing your video…")
                        Text("Keep Pluki open while your video is created.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Cancel", role: .cancel) { model.cancel() }
                    } else {
                        Image(systemName: "music.note.tv.fill")
                            .font(.system(size: 64)).foregroundStyle(.green).padding()
                        Picker("Video format", selection: $shape) {
                            ForEach(VideoShape.allCases) { value in Text(value.rawValue).tag(value) }
                        }.pickerStyle(.segmented)
                        Text("Your animated music sheet and song, together in an HD video. Plays once from beginning to end.")
                            .multilineTextAlignment(.center).foregroundStyle(.secondary)
                        Button("Create video", systemImage: "video.fill") {
                            model.start(song: song, shape: shape)
                        }.buttonStyle(.borderedProminent).tint(.green)
                            .disabled(song.notes.isEmpty)
                    }
                    if let message = model.message {
                        Text(message).font(.callout).multilineTextAlignment(.center)
                            .accessibilityLabel(message)
                    }
                }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(Color(red: 1, green: 0.98, blue: 0.93))
            .navigationTitle("Export video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.disabled(model.saving)
                }
            }
        }
        .sheet(isPresented: $showParentGate, onDismiss: {
            let maySave = parentApproved && scenePhase == .active
            parentApproved = false
            if maySave { model.saveToPhotos(parentApproved: true) }
        }) {
            PlukiParentGate { parentApproved = true }
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--visual-tour") {
                var previewSong = song
                previewSong.notes = Array(song.notes.filter { $0.step < 4 })
                model.start(song: previewSong, shape: .vertical)
                while model.working { try? await Task.sleep(nanoseconds: 100_000_000) }
                if model.player != nil {
                    let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    try? "ready".write(to: folder.appendingPathComponent("visual-preview-ready.txt"), atomically: true, encoding: .utf8)
                }
            }
            #endif
        }
        .interactiveDismissDisabled(model.saving)
        .onDisappear { model.close() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.player?.pause() }
            if phase == .background {
                parentApproved = false
                showParentGate = false
            }
            if phase == .background && model.working {
                model.cancel()
                model.message = "Export paused when Pluki closed. Tap Create video to try again."
            }
        }
    }
}

@MainActor
private final class SongVideoExportModel: ObservableObject {
    @Published var working = false
    @Published var saving = false
    @Published var saved = false
    @Published var progress = 0.0
    @Published var message: String?
    @Published var player: AVPlayer?
    var previewRatio: CGFloat = 9.0 / 16.0
    private var output: URL?
    private var task: Task<Void, Never>?

    func start(song: Song, shape: VideoShape) {
        guard !working, !saving else { return }
        clearPreview()
        working = true
        progress = 0
        message = nil
        previewRatio = shape.size.width / shape.size.height
        task = Task {
            let idleWasDisabled = UIApplication.shared.isIdleTimerDisabled
            UIApplication.shared.isIdleTimerDisabled = true
            defer {
                UIApplication.shared.isIdleTimerDisabled = idleWasDisabled
                working = false
                task = nil
            }
            do {
                let url = try await SongVideoRenderer.export(song: song, size: shape.size) { self.progress = $0 }
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
                    return
                }
                output = url
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                player = AVPlayer(url: url)
            } catch is CancellationError {
                // Cancellation is intentional; the renderer removes its partial files.
            } catch {
                message = error.localizedDescription
            }
        }
    }

    func cancel() { task?.cancel() }

    func clearPreview() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        if let output { try? FileManager.default.removeItem(at: output.deletingLastPathComponent()) }
        output = nil
        saved = false
        message = nil
    }

    func close() { cancel(); clearPreview() }

    func saveToPhotos(parentApproved: Bool = false) {
        guard let output, !saving, !saved else { return }
        player?.pause()
        saving = true
        message = nil
        Task {
            defer { saving = false }
            var permission = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if permission == .notDetermined {
                guard parentApproved else {
                    message = "Tap Save to Photos again to enable saving with a grown-up."
                    return
                }
                permission = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            }
            if permission == .restricted {
                message = "Photos access is restricted on this device. A grown-up can check Screen Time or device restrictions."
                return
            }
            guard permission == .authorized || permission == .limited else {
                message = SongVideoError.photosDenied.localizedDescription
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: output)
                }
                saved = true
                message = "Your music video is now in Photos."
            } catch {
                message = "Could not save to Photos. Check available storage and try again."
            }
        }
    }
}

/// Render frames from song time, not screen capture or a playback timer.
/// Audio and video begin at zero and share the same tempo calculation.
@MainActor
private enum SongVideoRenderer {
    static func export(song: Song, size: CGSize, progress: (Double) -> Void) async throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Pluki-video-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var succeeded = false
        defer { if !succeeded { try? FileManager.default.removeItem(at: folder) } }
        let soundURL = folder.appendingPathComponent("song.caf")
        let silentURL = folder.appendingPathComponent("frames.mp4")
        let resultURL = folder.appendingPathComponent("Pluki-song.mp4")
        try Task.checkCancellation()
        let duration = try PlinkaAudio().writeExportAudio(song, to: soundURL)
        let writer = try AVAssetWriter(outputURL: silentURL, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 5_000_000]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ])
        guard writer.canAdd(input) else { throw SongVideoError.failed }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? SongVideoError.failed }
        defer { if writer.status == .writing { writer.cancelWriting() } }
        writer.startSession(atSourceTime: .zero)
        let artwork = VideoArtwork(song: song, size: size)
        let frameCount = Int(ceil(duration * 30))
        for frame in 0..<frameCount {
            try Task.checkCancellation()
            let deadline = Date().addingTimeInterval(30)
            while !input.isReadyForMoreMediaData {
                guard writer.status == .writing, Date() < deadline else { throw writer.error ?? SongVideoError.failed }
                try await Task.sleep(nanoseconds: 5_000_000)
            }
            try autoreleasepool {
                guard let pool = adaptor.pixelBufferPool else { throw SongVideoError.failed }
                var buffer: CVPixelBuffer?
                guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
                      let buffer else { throw SongVideoError.failed }
                CVPixelBufferLockBaseAddress(buffer, [])
                defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
                guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                    width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { throw SongVideoError.failed }
                context.translateBy(x: 0, y: size.height)
                context.scaleBy(x: 1, y: -1)
                UIGraphicsPushContext(context)
                artwork.draw(time: Double(frame) / 30, context: context)
                UIGraphicsPopContext()
                guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)) else {
                    throw writer.error ?? SongVideoError.failed
                }
            }
            if frame % 3 == 0 {
                progress(Double(frame + 1) / Double(frameCount) * 0.85)
                try await Task.sleep(nanoseconds: 1_000_000)
            }
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(seconds: duration, preferredTimescale: 44_100))
        await writer.finishWriting()
        try Task.checkCancellation()
        guard writer.status == .completed else { throw writer.error ?? SongVideoError.failed }
        progress(0.88)
        let composition = AVMutableComposition()
        let video = AVURLAsset(url: silentURL)
        let sound = AVURLAsset(url: soundURL)
        guard let videoSource = try await video.loadTracks(withMediaType: .video).first,
              let audioSource = try await sound.loadTracks(withMediaType: .audio).first,
              let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw SongVideoError.failed }
        let range = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 44_100))
        try videoTrack.insertTimeRange(range, of: videoSource, at: .zero)
        try audioTrack.insertTimeRange(range, of: audioSource, at: .zero)
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { throw SongVideoError.failed }
        exporter.outputURL = resultURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        await withTaskCancellationHandler {
            await exporter.export()
        } onCancel: {
            exporter.cancelExport()
        }
        try Task.checkCancellation()
        guard exporter.status == .completed else { throw exporter.error ?? SongVideoError.failed }
        // Validate the final container before allowing Photos to import it.
        let result = AVURLAsset(url: resultURL)
        let finalDuration = try await result.load(.duration).seconds
        let videoTracks = try await result.loadTracks(withMediaType: .video)
        let audioTracks = try await result.loadTracks(withMediaType: .audio)
        guard !videoTracks.isEmpty, !audioTracks.isEmpty, abs(finalDuration - duration) < 0.1 else { throw SongVideoError.failed }
        try? FileManager.default.removeItem(at: silentURL)
        try? FileManager.default.removeItem(at: soundURL)
        progress(1)
        succeeded = true
        return resultURL
    }
}

@MainActor
private struct VideoArtwork {
    let song: Song
    let size: CGSize
    let stickers: [Instrument: UIImage]
    let background: UIImage?
    private let ink = UIColor(red: 0.13, green: 0.22, blue: 0.34, alpha: 1)
    private let blue = UIColor(red: 0.13, green: 0.69, blue: 0.90, alpha: 1)

    init(song: Song, size: CGSize) {
        self.song = song
        self.size = size
        stickers = Dictionary(uniqueKeysWithValues: Instrument.allCases.compactMap { instrument in
            UIImage(named: instrument.rawValue).map { (instrument, $0) }
        })
        background = UIImage(named: "studio-room")
    }

    func draw(time: Double, context: CGContext) {
        let vertical = size.height > size.width
        UIColor(red: 0.70, green: 0.87, blue: 0.89, alpha: 1).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        if let background { drawImage(background, in: CGRect(origin: .zero, size: size), fill: true) }
        UIColor.white.withAlphaComponent(0.30).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        // Keep the sheet dominant while reserving a compact header and two-line footer.
        let paper = CGRect(x: 24, y: vertical ? 170 : 120, width: size.width - 48, height: vertical ? 1010 : 500)
        UIColor(red: 1, green: 0.98, blue: 0.93, alpha: 1).setFill()
        UIBezierPath(roundedRect: paper, cornerRadius: 32).fill()
        let logo = CGRect(x: (size.width - 280) / 2, y: vertical ? 24 : 12, width: 280, height: vertical ? 72 : 60)
        UIColor.white.withAlphaComponent(0.82).setFill()
        UIBezierPath(roundedRect: logo, cornerRadius: 26).fill()
        let green = UIColor(red: 0.20, green: 0.75, blue: 0.43, alpha: 1)
        if let note = UIImage(systemName: "music.note", withConfiguration: UIImage.SymbolConfiguration(pointSize: 46, weight: .black)) {
            drawImage(note.withTintColor(green, renderingMode: .alwaysOriginal),
                      in: CGRect(x: logo.minX + 25, y: logo.midY - 27, width: 43, height: 54))
        }
        text("pluki!", rect: CGRect(x: logo.minX + 79, y: logo.midY - 29, width: 180, height: 60), font: 46, centered: false)
        text(song.title, rect: CGRect(x: 50, y: vertical ? 110 : 80, width: size.width - 100, height: 54), font: vertical ? 30 : 25, centered: true)
        text("Made with Pluki", rect: CGRect(x: 24, y: paper.maxY + 12, width: size.width - 48, height: 36), font: 28.75, centered: true)
        text("Available in the App Store", rect: CGRect(x: 24, y: paper.maxY + 51, width: size.width - 48, height: 30), font: 22, centered: true)
        let gutter: CGFloat = vertical ? 85 : 100
        let left = paper.minX + gutter
        let right = paper.maxX - 20
        let top = paper.minY + 95
        let bottom = paper.maxY - 75
        let rowHeight = (bottom - top) / 8
        let cell: CGFloat = vertical ? 140 : 145
        let step = time / (30 / max(65, min(160, song.tempo)))
        let last = Double(song.notes.map(\.step).max() ?? 0)
        let playStep = min(step, last + 0.6)
        let firstX = left + cell * 0.5
        let visible = right - firstX
        let maxOffset = max(0, CGFloat(last) * cell - visible + cell * 0.5)
        let offset = min(maxOffset, max(0, CGFloat(playStep) * cell - visible * 0.33))
        context.saveGState()
        context.clip(to: CGRect(x: left, y: paper.minY + 15, width: right - left, height: paper.height - 30))
        for beat in 0..<song.stepCount {
            let x = firstX + CGFloat(beat) * cell - offset
            guard x >= left - cell, x <= right + cell else { continue }
            context.setStrokeColor(ink.withAlphaComponent(0.14).cgColor)
            context.setLineWidth(2)
            context.setLineDash(phase: 0, lengths: [8, 10])
            context.move(to: CGPoint(x: x, y: paper.minY + 65))
            context.addLine(to: CGPoint(x: x, y: paper.maxY - 35)); context.strokePath()
            if beat % 2 == 0 {
                text("\(beat / 2 + 1)", rect: CGRect(x: x - 30, y: paper.minY + 24, width: 60, height: 30), font: 22, centered: true)
            }
        }
        context.setLineDash(phase: 0, lengths: [])
        for row in stride(from: 0, through: 8, by: 2) {
            let y = top + CGFloat(row) * rowHeight
            context.setStrokeColor(ink.withAlphaComponent(0.85).cgColor); context.setLineWidth(2.5)
            context.move(to: CGPoint(x: left, y: y)); context.addLine(to: CGPoint(x: right, y: y)); context.strokePath()
        }
        let playX = firstX + CGFloat(playStep) * cell - offset
        context.setStrokeColor(blue.cgColor); context.setLineWidth(4)
        context.move(to: CGPoint(x: playX, y: paper.minY + 65))
        context.addLine(to: CGPoint(x: playX, y: paper.maxY - 35)); context.strokePath()
        for note in song.notes {
            let x = firstX + CGFloat(note.step) * cell - offset
            guard x > left - cell, x < right + cell, let image = stickers[note.instrument] else { continue }
            let age = step - Double(note.step)
            let pulse: CGFloat = age >= 0 && age < 1 ? 1 + 0.12 * CGFloat(sin(age * .pi)) : 1
            let length = min(cell * 0.80, rowHeight * 1.60) * pulse
            let rect = CGRect(x: x - length / 2, y: top + CGFloat(note.row) * rowHeight - length / 2, width: length, height: length)
            if age >= 0 && age < 1 {
                blue.withAlphaComponent(0.18).setFill()
                UIBezierPath(roundedRect: rect.insetBy(dx: -4, dy: -4), cornerRadius: 18).fill()
            }
            drawImage(image, in: rect)
        }
        context.restoreGState()
        drawImage(ClefArtwork.image, in: CGRect(x: paper.minX + 10, y: top + rowHeight * 1.4, width: gutter - 17, height: rowHeight * 5.4))
    }

    private func text(_ value: String, rect: CGRect, font: CGFloat, centered: Bool) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = centered ? .center : .left
        paragraph.lineBreakMode = .byTruncatingTail
        let base = UIFont.systemFont(ofSize: font, weight: .bold)
        let rounded = UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: font)
        (value as NSString).draw(in: rect, withAttributes: [.font: rounded, .foregroundColor: ink, .paragraphStyle: paragraph])
    }

    private func drawImage(_ image: UIImage, in rect: CGRect, fill: Bool = false) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let x = rect.width / image.size.width, y = rect.height / image.size.height
        let scale = fill ? max(x, y) : min(x, y)
        let width = image.size.width * scale, height = image.size.height * scale
        image.draw(in: CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height))
    }
}

#if DEBUG
/// Opt-in media smoke check; never runs in a distributed build or normal launch.
@MainActor
enum VideoExportSmokeCheck {
    static func runIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--check-video-export") else { return }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let notes = [MusicNote(step: 0, row: 4, instrument: .piano),
                         MusicNote(step: 2, row: 2, instrument: .chicken),
                         MusicNote(step: 4, row: 6, instrument: .frog),
                         MusicNote(step: 34, row: 4, instrument: .puppy)]
            let song = Song(title: "Export check", tempo: 160, loop: true, notes: notes, sheetSteps: 64)
            for shape in VideoShape.allCases {
                let url = try await SongVideoRenderer.export(song: song, size: shape.size) { _ in }
                defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
                let asset = AVURLAsset(url: url)
                guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw SongVideoError.failed }
                let dimensions = try await track.load(.naturalSize)
                guard dimensions == shape.size else { throw SongVideoError.failed }
                let destination = documents.appendingPathComponent("\(shape.rawValue).mp4")
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: url, to: destination)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                let (frame, _) = try await generator.image(at: CMTime(seconds: 6, preferredTimescale: 30))
                try UIImage(cgImage: frame).pngData()?.write(to: documents.appendingPathComponent("\(shape.rawValue).png"))
            }
            // Cancel after the first frame and ensure the renderer never returns a partial movie.
            let cancelled = Task { try await SongVideoRenderer.export(song: song, size: VideoShape.vertical.size) { _ in } }
            cancelled.cancel()
            do { _ = try await cancelled.value; throw SongVideoError.failed }
            catch is CancellationError { }
            try "PASS: portrait and landscape movies, audio/video tracks, duration, late note, cancellation".write(to: documents.appendingPathComponent("video-check.txt"), atomically: true, encoding: .utf8)
        } catch {
            try? "FAIL: \(error)".write(to: documents.appendingPathComponent("video-check.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
