import Foundation

@main
struct SongImportChecks {
    @MainActor static func main() throws {
        let suite = "Pluki-Import-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let fixture = try Data(contentsOf: URL(fileURLWithPath: "ios/marketing/First-Little-Groove.pluki"))
        let valid = try PlukiSongFile.decode(fixture)
        precondition(valid.notes.count == 16)
        func rejected(_ song: Song) {
            do { _ = try PlukiSongFile.validated(song); preconditionFailure("Invalid song accepted") }
            catch {}
        }
        var bad = valid; bad.tempo = .nan; rejected(bad)
        bad = valid; bad.tempo = 200; rejected(bad)
        bad = valid; bad.sheetSteps = 1001; rejected(bad)
        bad = valid; bad.sheetSteps = nil; rejected(bad)
        bad = valid; bad.title = "\n"; rejected(bad)
        bad = valid; bad.notes[0].row = 9; rejected(bad)
        bad = valid; bad.notes[0].step = -1; rejected(bad)
        bad = valid; bad.notes[0].step = 32; rejected(bad)
        bad = valid; bad.notes.append(bad.notes[0]); rejected(bad)
        bad = valid; bad.notes[1].id = bad.notes[0].id; rejected(bad)
        bad = valid; bad.notes = []; rejected(bad)
        for bytes in [Data("{}".utf8), Data(repeating: 32, count: PlukiSongFile.maximumBytes + 1),
                      Data(String(decoding: fixture, as: UTF8.self).replacingOccurrences(of: "\"version\": 1", with: "\"version\": 2").utf8),
                      Data(String(decoding: fixture, as: UTF8.self).replacingOccurrences(of: "\"piano\"", with: "\"unknown\"").utf8)] {
            do { _ = try PlukiSongFile.decode(bytes); preconditionFailure("Bad file accepted") } catch {}
        }
        let store = SongStore(defaults: defaults)
        store.song = valid
        precondition(store.saveSong(named: valid.title))
        let original = store.savedSongs[0]
        store.song.tempo = 120
        let unsaved = store.song
        precondition(store.importSong(valid))
        precondition(store.savedSongs.count == 3)
        precondition(store.savedSongs.contains { $0.id == original.id && $0.song == original.song })
        precondition(store.savedSongs.contains { $0.song == unsaved })
        precondition(store.song.notes.map(\.id) != valid.notes.map(\.id))
        precondition(!store.hasUnsavedChanges && !store.canUndo && !store.canRedo)
        let restored = SongStore(defaults: defaults)
        precondition(restored.savedSongs.count == 3 && restored.song == store.song)
        precondition(restored.importSong(valid))
        precondition(restored.savedSongs.count == 4) // Clean current song needs no duplicate backup.
        let before = restored.song
        let count = restored.savedSongs.count
        precondition(!restored.importSong(bad))
        precondition(restored.song == before && restored.savedSongs.count == count)
        defaults.set(Data("broken".utf8), forKey: "pluki-saved-songs-v1")
        let broken = SongStore(defaults: defaults)
        precondition(!broken.importSong(valid))
        precondition(defaults.data(forKey: "pluki-saved-songs-v1") == Data("broken".utf8))
        print("PASS: import format, bounds, duplicates, draft preservation, saved-copy independence, reload and corrupt-library protection")
    }
}
