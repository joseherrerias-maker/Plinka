import SwiftUI
import Foundation

enum Instrument: String, Codable, CaseIterable, Identifiable {
    case piano, xylophone, guitar, trumpet, flute, bells, synth, drums, puppy, kitten, sparkle, boing

    var id: String { rawValue }
    var label: String {
        switch self {
        case .piano: return "Piano"
        case .xylophone: return "Xylophone"
        case .guitar: return "Guitar"
        case .trumpet: return "Trumpet"
        case .flute: return "Flute"
        case .bells: return "Bells"
        case .synth: return "Synth"
        case .drums: return "Drums"
        case .puppy: return "Puppy"
        case .kitten: return "Kitten"
        case .sparkle: return "Sparkle"
        case .boing: return "Boing"
        }
    }
    var emoji: String {
        switch self {
        case .piano: return "🎹"
        case .xylophone: return "🎼"
        case .guitar: return "🎸"
        case .trumpet: return "🎺"
        case .flute: return "🪈"
        case .bells: return "🔔"
        case .synth: return "⚡️"
        case .drums: return "🥁"
        case .puppy: return "🐶"
        case .kitten: return "🐱"
        case .sparkle: return "⭐️"
        case .boing: return "🌈"
        }
    }
    var tint: Color {
        switch self {
        case .piano: return Color(red: 0.59, green: 0.49, blue: 0.88)
        case .xylophone: return Color(red: 1.00, green: 0.78, blue: 0.36)
        case .guitar: return Color(red: 1.00, green: 0.60, blue: 0.50)
        case .trumpet: return Color(red: 1.00, green: 0.72, blue: 0.38)
        case .flute: return Color(red: 0.43, green: 0.82, blue: 0.80)
        case .bells: return Color(red: 1.00, green: 0.83, blue: 0.54)
        case .synth: return Color(red: 0.54, green: 0.76, blue: 1.00)
        case .puppy: return Color.orange
        case .kitten: return Color.purple
        case .sparkle: return Color.yellow
        case .boing: return Color.pink
        case .drums: return Color(red: 0.77, green: 0.60, blue: 0.93)
        }
    }
}

struct MusicNote: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var step: Int
    var row: Int
    var instrument: Instrument
}

struct Song: Codable {
    var title: String = "My First Song"
    var tempo: Double = 110
    var loop: Bool = false
    var notes: [MusicNote] = []
}

@MainActor
final class SongStore: ObservableObject {
    static let steps = 32
    static let pitches = [77, 76, 74, 72, 71, 69, 67, 65, 64] // F5 to E4
    private static let saveKey = "plinka-native-song-v1"

    @Published var song: Song {
        didSet { persist() }
    }
    @Published var chosen: Instrument = .piano
    @Published var erasing = false
    @Published var selectedID: UUID?
    private var undoHistory: [Song] = []
    private var redoHistory: [Song] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey),
           let restored = try? JSONDecoder().decode(Song.self, from: data) {
            self.song = restored
        } else {
            self.song = Song()
        }
        self.song.notes = self.song.notes.filter {
            (0..<Self.steps).contains($0.step) && (0..<Self.pitches.count).contains($0.row)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(song) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    private func remember() {
        undoHistory.append(song)
        redoHistory.removeAll()
        if undoHistory.count > 40 { undoHistory.removeFirst() }
    }

    var canUndo: Bool { !undoHistory.isEmpty }
    var canRedo: Bool { !redoHistory.isEmpty }

    func choose(_ instrument: Instrument) {
        chosen = instrument
        selectedID = nil
        erasing = false
    }

    func tap(step: Int, row: Int) -> MusicNote? {
        guard (0..<Self.steps).contains(step), (0..<Self.pitches.count).contains(row) else { return nil }
        if let existing = song.notes.first(where: { $0.step == step && $0.row == row }) {
            if erasing {
                remember()
                song.notes.removeAll { $0.id == existing.id }
                selectedID = nil
            } else {
                selectedID = existing.id
            }
            return erasing ? nil : existing
        }
        if erasing { return nil }
        remember()
        let added = MusicNote(step: step, row: row, instrument: chosen)
        song.notes.append(added)
        selectedID = added.id
        return added
    }

    func move(id: UUID, horizontal: Int, vertical: Int) {
        guard let index = song.notes.firstIndex(where: { $0.id == id }) else { return }
        let old = song.notes[index]
        let newStep = max(0, min(Self.steps - 1, old.step + horizontal))
        let newRow = max(0, min(Self.pitches.count - 1, old.row + vertical))
        guard newStep != old.step || newRow != old.row else { return }
        guard !song.notes.contains(where: { $0.id != id && $0.step == newStep && $0.row == newRow }) else { return }
        remember()
        song.notes[index].step = newStep
        song.notes[index].row = newRow
        selectedID = id
    }

    func remove(id: UUID) {
        guard song.notes.contains(where: { $0.id == id }) else { return }
        remember()
        song.notes.removeAll { $0.id == id }
        selectedID = nil
    }

    func undo() {
        guard let prior = undoHistory.popLast() else { return }
        redoHistory.append(song)
        song = prior
        selectedID = nil
    }

    func redo() {
        guard let next = redoHistory.popLast() else { return }
        undoHistory.append(song)
        song = next
        selectedID = nil
    }

    func clear() {
        guard !song.notes.isEmpty else { return }
        remember()
        song.notes.removeAll()
        selectedID = nil
    }

    func demo() {
        remember()
        let rows = [6,6,5,6,4,4,5,6,7,7,6,5,6,5,6,8]
        let sounds: [Instrument] = [.piano,.piano,.xylophone,.piano,.bells,.xylophone,
            .piano,.piano,.guitar,.guitar,.flute,.xylophone,.trumpet,.xylophone,.piano,.bells]
        song.notes = zip(rows, sounds).enumerated().map {
            MusicNote(step: $0.offset * 2, row: $0.element.0, instrument: $0.element.1)
        }
        selectedID = nil
    }
}
