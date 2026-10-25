import SwiftUI
import Foundation

enum Instrument: String, Codable, CaseIterable, Identifiable {
    case piano, xylophone, guitar, trumpet, flute, bells, synth, drums, puppy, kitten, chicken, pig, cow, frog, sparkle, boing, bubbles, whistle, laser

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
        case .chicken: return "Chicken"
        case .pig: return "Pig"
        case .cow: return "Cow"
        case .frog: return "Frog"
        case .bubbles: return "Bubbles"
        case .whistle: return "Whistle"
        case .laser: return "Laser"
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
        case .chicken: return "🐔"
        case .pig: return "🐷"
        case .cow: return "🐮"
        case .frog: return "🐸"
        case .bubbles: return "🫧"
        case .whistle: return "🎵"
        case .laser: return "🚀"
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
        case .chicken: return Color.orange
        case .pig: return Color.pink
        case .cow: return Color.brown
        case .frog: return Color.green
        case .bubbles: return Color.cyan
        case .whistle: return Color.mint
        case .laser: return Color.blue
        }
    }
}

struct MusicNote: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var step: Int
    var row: Int
    var instrument: Instrument
}

struct Song: Codable, Equatable {
    var title: String = "My First Song"
    var tempo: Double = 110
    var loop: Bool = false
    var notes: [MusicNote] = []
}

struct SavedSong: Codable, Identifiable {
    var id: UUID = UUID()
    var song: Song
    var savedAt: Date = Date()
}

@MainActor
final class SongStore: ObservableObject {
    static let steps = 32
    static let pitches = [77, 76, 74, 72, 71, 69, 67, 65, 64] // F5 to E4
    private static let saveKey = "plinka-native-song-v1"

    @Published var song: Song {
        didSet { persist() }
    }
    @Published private(set) var savedSongs: [SavedSong] = []
    @Published var libraryError: String?
    private var activeSavedID: UUID?
    private var libraryReadable = true
    private static let libraryKey = "pluki-saved-songs-v1"

    var hasUnsavedChanges: Bool {
        if let saved = savedSongs.first(where: { $0.id == activeSavedID }) {
            return saved.song != song
        }
        return !song.notes.isEmpty
    }

    @discardableResult
    func saveSong(named name: String) -> Bool {
        guard libraryReadable else { libraryError = "Saved songs could not be read. Saving is paused to protect them."; return false }
        var snapshot = song
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        snapshot.title = title.isEmpty ? "Untitled Song" : String(title.prefix(80))
        var entries = savedSongs
        let id: UUID
        if let index = entries.firstIndex(where: { $0.id == activeSavedID && $0.song.title == snapshot.title }) {
            id = entries[index].id
            entries[index].song = snapshot
            entries[index].savedAt = Date()
        } else {
            let entry = SavedSong(song: snapshot)
            id = entry.id
            entries.append(entry)
        }
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: Self.libraryKey)
            savedSongs = entries.sorted { $0.savedAt > $1.savedAt }
            activeSavedID = id
            defaults.set(id.uuidString, forKey: "pluki-active-saved-song")
            song = snapshot
            return true
        } catch {
            libraryError = "Your song could not be saved. Please try again."
            return false
        }
    }

    func openSong(_ saved: SavedSong) {
        song = saved.song
        activeSavedID = saved.id
        defaults.set(saved.id.uuidString, forKey: "pluki-active-saved-song")
        selectedID = nil
        erasing = false
        undoHistory.removeAll()
        redoHistory.removeAll()
    }

    @Published var chosen: Instrument = .piano
    @Published var erasing = false
    @Published var selectedID: UUID?
    private var undoHistory: [Song] = []
    private var redoHistory: [Song] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.saveKey),
           let restored = try? JSONDecoder().decode(Song.self, from: data) {
            self.song = restored
        } else {
            self.song = Song()
        }
        if let data = defaults.data(forKey: Self.libraryKey) {
            do {
                savedSongs = try JSONDecoder().decode([SavedSong].self, from: data)
                    .sorted { $0.savedAt > $1.savedAt }
            } catch {
                libraryReadable = false
                libraryError = "Saved songs could not be read. Your current melody is safe; the saved collection has not been changed."
            }
        }
        activeSavedID = defaults.string(forKey: "pluki-active-saved-song").flatMap(UUID.init(uuidString:))
        self.song.notes = self.song.notes.filter {
            (0..<Self.steps).contains($0.step) && (0..<Self.pitches.count).contains($0.row)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(song) {
            defaults.set(data, forKey: Self.saveKey)
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
