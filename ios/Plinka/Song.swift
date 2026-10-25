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
    // Optional for backward-compatible decoding of existing drafts and saved songs.
    var sheetSteps: Int? = nil
    static let maximumSteps = 256
    var stepCount: Int { max(32, min(Self.maximumSteps, sheetSteps ?? 32)) }
}

// Pluki arrangements of traditional/classical themes and original compositions.
// Times are half-beat steps; all pitches fit the existing nine-row staff.
struct SampleSong: Identifiable {
    let id: String
    let detail: String
    let song: Song

    private static func phrase(_ pitches: [Int], durations: [Int],
                               instrument: Instrument, start: Int = 0) -> [MusicNote] {
        let staff = [77, 76, 74, 72, 71, 69, 67, 65, 64]
        precondition(pitches.count == durations.count && durations.allSatisfy { $0 > 0 })
        var step = start
        return zip(pitches, durations).map { pitch, duration in
            defer { step += duration }
            guard let row = staff.firstIndex(of: pitch) else { preconditionFailure("Sample pitch outside staff") }
            return MusicNote(step: step, row: row, instrument: instrument)
        }
    }

    // Keep each staff cell editable individually; melody takes precedence over decoration.
    private static func decorate(_ melody: [MusicNote], with accents: [MusicNote]) -> [MusicNote] {
        var occupied = Set(melody.map { "\($0.step):\($0.row)" })
        return melody + accents.filter { occupied.insert("\($0.step):\($0.row)").inserted }
    }

    private static var twinkle: Song {
        let a = [67,67,74,74,76,76,74,72,72,71,71,69,69,67]
        let b = [74,74,72,72,71,71,69,74,74,72,72,71,71,69]
        let rhythm = [2,2,2,2,2,2,4,2,2,2,2,2,2,4]
        let notes = phrase(a, durations: rhythm, instrument: .piano)
            + phrase(b, durations: rhythm, instrument: .bells, start: 32)
            + phrase(a, durations: rhythm, instrument: .piano, start: 64)
        let accents = phrase(Array(repeating: 64, count: 6), durations: Array(repeating: 16, count: 6), instrument: .guitar)
        return Song(title: "Twinkle, Twinkle, Little Star", tempo: 100,
                    notes: decorate(notes, with: accents), sheetSteps: 96)
    }

    private static var frereJacques: Song {
        // The low dominant in the final phrase is raised an octave to fit the staff.
        let pitches = [67,69,71,67,67,69,71,67,71,72,74,71,72,74,
                       74,76,74,72,71,67,74,76,74,72,71,67,67,74,67,67,74,67]
        let rhythm = [2,2,2,2,2,2,2,2,2,2,4,2,2,4,
                      1,1,1,1,2,2,1,1,1,1,2,2,2,2,4,2,2,4]
        let notes = phrase(pitches, durations: rhythm, instrument: .flute)
            + phrase(pitches, durations: rhythm, instrument: .xylophone, start: 64)
        let bells = [0,32,64,96].map { MusicNote(step: $0, row: 8, instrument: .bells) }
        return Song(title: "Frère Jacques", tempo: 108,
                    notes: decorate(notes, with: bells), sheetSteps: 128)
    }

    private static var odeToJoy: Song {
        let opening = [71,71,72,74,74,72,71,69,67,67,69,71,71,69,69]
        let answer = [71,71,72,74,74,72,71,69,67,67,69,71,69,67,67]
        let rhythm = [2,2,2,2,2,2,2,2,2,2,2,2,3,1,4]
        let notes = phrase(opening, durations: rhythm, instrument: .piano)
            + phrase(answer, durations: rhythm, instrument: .piano, start: 32)
            + phrase(opening, durations: rhythm, instrument: .flute, start: 64)
            + phrase(answer, durations: rhythm, instrument: .piano, start: 96)
        let accents = [64,80,96,112].map { MusicNote(step: $0, row: 8, instrument: .bells) }
        return Song(title: "Ode to Joy", tempo: 112,
                    notes: decorate(notes, with: accents), sheetSteps: 128)
    }

    private static var oldMacDonald: Song {
        let refrain = [72,72,72,67,69,69,67,76,76,74,74,72]
        let rhythm = [2,2,2,2,2,2,4,2,2,2,2,8]
        var notes: [MusicNote] = []
        for (verse, animal) in [Instrument.cow, .chicken].enumerated() {
            let start = verse * 96
            notes += phrase(refrain, durations: rhythm, instrument: .xylophone, start: start)
            // A spacious call-and-response break between the familiar refrains.
            notes += phrase([67,69,72,69,67,72,74,72],
                            durations: [2,2,4,2,2,4,8,8], instrument: .guitar, start: start + 32)
            notes += [38,46,52,56,60].map { MusicNote(step: start + $0, row: 5, instrument: animal) }
            notes += phrase(refrain, durations: rhythm, instrument: .xylophone, start: start + 64)
        }
        return Song(title: "Old MacDonald", tempo: 110, notes: notes, sheetSteps: 192)
    }

    private static var plukiPop: Song {
        let a = [72,76,74,72,71,67,69,76,74,71,72,69,67,69,71,72]
        let b = [76,74,72,69,72,74,71,67,69,71,74,76,74,72,71,67]
        let rhythm = [2,1,3,2,2,1,3,2,2,1,3,2,2,1,3,2]
        var notes: [MusicNote] = []
        for section in 0..<4 {
            let start = section * 32
            notes += phrase(section == 1 ? b : a, durations: rhythm,
                            instrument: section == 2 ? .xylophone : .synth, start: start)
        }
        let drums = stride(from: 0, to: 120, by: 4).map { MusicNote(step: $0, row: 8, instrument: .drums) }
        return Song(title: "Pluki Pop", tempo: 124,
                    notes: decorate(notes, with: drums), sheetSteps: 128)
    }

    private static var animalParade: Song {
        let calls = [[67,71,74,72,69,72,71,67,69,74,72,71],
                     [72,74,76,74,72,69,71,74,72,69,71,67]]
        let rhythm = [2,1,5,2,1,5,2,1,5,2,1,5]
        let animals: [Instrument] = [.puppy, .frog, .chicken, .pig, .cow, .kitten]
        var notes: [MusicNote] = []
        for section in 0..<4 {
            let start = section * 32
            notes += phrase(calls[section % 2], durations: rhythm, instrument: .xylophone, start: start)
            for (index, offset) in [5,13,21,29].enumerated() {
                notes.append(MusicNote(step: start + offset, row: 5,
                                       instrument: animals[(section * 4 + index) % animals.count]))
            }
        }
        notes += phrase([72,71,69,67], durations: [4,4,4,4], instrument: .bells, start: 128)
        return Song(title: "Animal Parade", tempo: 104, notes: notes, sheetSteps: 144)
    }

    static let all: [SampleSong] = [
        SampleSong(id: "frere-jacques", detail: "Traditional · flute and xylophone verses", song: frereJacques),
        SampleSong(id: "ode-to-joy", detail: "Beethoven theme · piano and flute variation", song: odeToJoy),
        SampleSong(id: "animal-parade", detail: "Original · six animal friends and a bell finale", song: animalParade),
        SampleSong(id: "twinkle", detail: "Traditional · complete melody with piano and bells", song: twinkle),
        SampleSong(id: "old-macdonald", detail: "Traditional theme · cow and chicken replies", song: oldMacDonald),
        SampleSong(id: "pluki-pop", detail: "Original · synth melody, contrast and return", song: plukiPop)
    ]
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
    @Published private(set) var sessionID = UUID()
    @Published private(set) var hasDraft = false
    @Published private(set) var savedSongs: [SavedSong] = []
    @Published var libraryError: String?
    private var activeSavedID: UUID?
    private var libraryReadable = true
    private static let libraryKey = "pluki-saved-songs-v1"

    var hasUnsavedChanges: Bool {
        if let saved = savedSongs.first(where: { $0.id == activeSavedID }) {
            return saved.song != song
        }
        return song != Song()
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

    @discardableResult
    func deleteSavedSong(id: UUID) -> Bool {
        guard libraryReadable else {
            libraryError = "Saved songs could not be read. Deletion is paused to protect them."
            return false
        }
        guard savedSongs.contains(where: { $0.id == id }) else { return true }
        let remaining = savedSongs.filter { $0.id != id }
        do {
            let data = try JSONEncoder().encode(remaining)
            defaults.set(data, forKey: Self.libraryKey)
            savedSongs = remaining
            if activeSavedID == id {
                activeSavedID = nil
                defaults.removeObject(forKey: "pluki-active-saved-song")
            }
            // Keep the working melody and its autosave intact.
            return true
        } catch {
            libraryError = "This saved song could not be deleted. Please try again."
            return false
        }
    }

    func openSong(_ saved: SavedSong) {
        sessionID = UUID()
        song = saved.song
        activeSavedID = saved.id
        defaults.set(saved.id.uuidString, forKey: "pluki-active-saved-song")
        selectedID = nil
        erasing = false
        undoHistory.removeAll()
        redoHistory.removeAll()
    }

    func newSong() {
        sessionID = UUID()
        activeSavedID = nil
        defaults.removeObject(forKey: "pluki-active-saved-song")
        song = Song()
        chosen = .piano
        selectedID = nil
        erasing = false
        undoHistory.removeAll()
        redoHistory.removeAll()
    }

    func openSample(_ sample: SampleSong) {
        sessionID = UUID()
        activeSavedID = nil
        defaults.removeObject(forKey: "pluki-active-saved-song")
        song = sample.song
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
            var validated = restored
            validated.notes = restored.notes.filter {
                (0..<validated.stepCount).contains($0.step) && (0..<Self.pitches.count).contains($0.row)
            }
            self.song = validated
            self.hasDraft = true
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
    }

    private func persist() {
        hasDraft = true
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

    func extendSheet() {
        guard song.stepCount < Song.maximumSteps else { return }
        remember()
        song.sheetSteps = min(Song.maximumSteps, song.stepCount + 32)
    }

    func choose(_ instrument: Instrument) {
        chosen = instrument
        selectedID = nil
        erasing = false
    }

    func tap(step: Int, row: Int) -> MusicNote? {
        guard (0..<song.stepCount).contains(step), (0..<Self.pitches.count).contains(row) else { return nil }
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
        let newStep = max(0, min(song.stepCount - 1, old.step + horizontal))
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
