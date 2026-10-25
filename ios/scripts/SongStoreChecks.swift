import Foundation

@main
struct SongStoreChecks {
    @MainActor static func main() throws {
        let suite = "Pluki-SongChecks-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = Song(title: "Existing draft", tempo: 125, loop: true,
                          notes: [MusicNote(step: 3, row: 4, instrument: .frog)])
        defaults.set(try JSONEncoder().encode(legacy), forKey: "plinka-native-song-v1")
        let store = SongStore(defaults: defaults)
        precondition(store.song == legacy && store.hasUnsavedChanges)
        precondition(store.saveSong(named: "First"))
        let first = store.savedSongs[0]
        store.song.tempo = 140
        precondition(store.hasUnsavedChanges)
        precondition(store.saveSong(named: "First"))
        precondition(store.savedSongs.count == 1 && store.savedSongs[0].id == first.id)
        precondition(store.saveSong(named: "Second"))
        precondition(store.savedSongs.count == 2)
        let restored = SongStore(defaults: defaults)
        precondition(restored.savedSongs.count == 2 && restored.song.title == "Second")
        precondition(!restored.hasUnsavedChanges)
        restored.openSong(restored.savedSongs.first { $0.id == first.id }!)
        precondition(restored.song.title == "First" && restored.song.tempo == 140)
        precondition(restored.song.loop && restored.song.notes == legacy.notes)
        precondition(!restored.canUndo && !restored.canRedo)
        let working = restored.song
        let otherID = restored.savedSongs.first { $0.id != first.id }!.id
        precondition(restored.deleteSavedSong(id: otherID))
        precondition(restored.song == working && restored.savedSongs.count == 1)
        precondition(!restored.hasUnsavedChanges)
        precondition(SongStore(defaults: defaults).savedSongs.count == 1)
        precondition(restored.deleteSavedSong(id: first.id))
        let afterDelete = SongStore(defaults: defaults)
        precondition(afterDelete.savedSongs.isEmpty && afterDelete.song == working)
        precondition(afterDelete.hasUnsavedChanges)
        precondition(afterDelete.saveSong(named: working.title))
        precondition(afterDelete.savedSongs[0].id != first.id)
        let broken = Data("not JSON".utf8)
        defaults.set(broken, forKey: "pluki-saved-songs-v1")
        let damaged = SongStore(defaults: defaults)
        precondition(!damaged.deleteSavedSong(id: first.id))
        precondition(!damaged.saveSong(named: "Must not overwrite"))
        precondition(defaults.data(forKey: "pluki-saved-songs-v1") == broken)
        print("Song persistence, migration, updates, copies, reopening and corruption protection passed.")
    }
}
