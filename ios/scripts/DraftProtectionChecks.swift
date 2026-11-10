import Foundation

@main
struct DraftProtectionChecks {
    @MainActor static func main() throws {
        let suite = "Pluki-Recovery-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SongStore(defaults: defaults)
        precondition(!store.hasMeaningfulDraft)
        precondition(store.newSong() && !store.hasMeaningfulDraft)
        precondition(store.newSong() && store.savedSongs.isEmpty)

        let first = Song(title: "A child's unfinished melody", tempo: 135, loop: true,
                         notes: [MusicNote(step: 1, row: 4, instrument: .piano),
                                 MusicNote(step: 4, row: 3, instrument: .bells)],
                         sheetSteps: 64)
        store.song = first
        precondition(store.hasMeaningfulDraft && store.hasUnsavedChanges)
        precondition(store.openSample(SampleSong.all[0]))
        let copies = store.savedSongs.filter { $0.isRecovery == true }
        precondition(copies.count == 1 && copies[0].song == first)
        precondition(store.song.title == "Pluki Theme")
        precondition(!store.hasUnsavedChanges) // Untouched sample is not a draft edit.
        // Exact restoration, including original note IDs/tempo/loop, after relaunch.
        let relaunched = SongStore(defaults: defaults)
        precondition(relaunched.savedSongs.contains { $0.isRecovery == true && $0.song == first })
        precondition(!relaunched.hasUnsavedChanges)
        let backup = relaunched.savedSongs.first { $0.isRecovery == true && $0.song == first }!
        precondition(relaunched.openSong(backup) && relaunched.song == first)
        precondition(relaunched.song.notes == first.notes)
        precondition(relaunched.hasMeaningfulDraft)
        // Home → New uses exactly the same preservation guard as the editor.
        let beforeNew = relaunched.sessionID
        precondition(relaunched.newSong())
        precondition(relaunched.sessionID != beforeNew)
        precondition(!relaunched.hasMeaningfulDraft && relaunched.song == Song())
        precondition(relaunched.savedSongs.filter { $0.isRecovery == true }.count == 1)
        precondition(relaunched.newSong())
        precondition(relaunched.savedSongs.filter { $0.isRecovery == true }.count == 1)

        // The sample itself must never create copies while merely browsing.
        let initialSavedCount = relaunched.savedSongs.count
        precondition(relaunched.openSample(SampleSong.all[1]))
        precondition(relaunched.openSample(SampleSong.all[2]))
        precondition(relaunched.savedSongs.count == initialSavedCount)
        // Edits to a sample become a recoverable, independent composition.
        var editedSample = relaunched.song
        editedSample.tempo += 5
        relaunched.song = editedSample
        precondition(relaunched.hasUnsavedChanges)
        precondition(relaunched.newSong())
        precondition(relaunched.savedSongs.contains { $0.isRecovery == true && $0.song == editedSample })
        precondition(!relaunched.hasMeaningfulDraft)

        // Saving a song, then editing it, preserves both the saved version
        // and an exact recovery of the unsaved edits when opening another song.
        let savedBase = Song(title: "Saved project", tempo: 105,
                             notes: [MusicNote(step: 3, row: 2, instrument: .xylophone)])
        relaunched.song = savedBase
        precondition(relaunched.saveSong(named: savedBase.title))
        let originalSave = relaunched.savedSongs.first { $0.song == savedBase && $0.isRecovery != true }!
        relaunched.song.tempo = 130
        let changed = relaunched.song
        precondition(relaunched.openSong(originalSave))
        precondition(relaunched.song == savedBase && !relaunched.hasUnsavedChanges)
        precondition(relaunched.savedSongs.contains { $0.id == originalSave.id && $0.song == savedBase })
        precondition(relaunched.savedSongs.contains { $0.isRecovery == true && $0.song == changed })
        // Empty drafts do not spawn recovery copies, even after title edits.
        let count = relaunched.savedSongs.count
        precondition(relaunched.newSong())
        relaunched.song.title = "A title without any notes"
        precondition(!relaunched.hasMeaningfulDraft)
        precondition(relaunched.newSong() && relaunched.savedSongs.count == count)

        // When the stored collection is unreadable, never replace the active
        // melody or its undo/session state. Show a failure reason instead.
        let brokenSuite = "Pluki-Recovery-Broken-\(UUID().uuidString)"
        let broken = UserDefaults(suiteName: brokenSuite)!
        defer { broken.removePersistentDomain(forName: brokenSuite) }
        broken.set(Data("not JSON".utf8), forKey: "pluki-saved-songs-v1")
        broken.set(try JSONEncoder().encode(first), forKey: "plinka-native-song-v1")
        let damaged = SongStore(defaults: broken)
        let initialSession = damaged.sessionID
        precondition(!damaged.newSong())
        precondition(!damaged.openSample(SampleSong.all[0]))
        precondition(damaged.song == first && damaged.sessionID == initialSession)
        precondition(damaged.libraryError != nil)
        precondition(broken.data(forKey: "pluki-saved-songs-v1") == Data("not JSON".utf8))

        // A serialization failure must also keep the in-memory original open.
        let nanSuite = "Pluki-Recovery-Encode-\(UUID().uuidString)"
        let nanDefaults = UserDefaults(suiteName: nanSuite)!
        defer { nanDefaults.removePersistentDomain(forName: nanSuite) }
        let unencodable = SongStore(defaults: nanDefaults)
        unencodable.song.notes = [MusicNote(step: 0, row: 4, instrument: .piano)]
        unencodable.song.tempo = .nan
        let noteIDs = unencodable.song.notes.map(\.id)
        let oldSession = unencodable.sessionID
        precondition(!unencodable.newSong())
        precondition(unencodable.sessionID == oldSession)
        precondition(unencodable.song.tempo.isNaN && unencodable.song.notes.map(\.id) == noteIDs)
        precondition(unencodable.libraryError != nil && unencodable.savedSongs.isEmpty)

        // Existing legacy saved entries lacking the optional recovery marker decode.
        let legacy = try JSONEncoder().encode(SavedSong(song: first))
        let legacyObject = try JSONSerialization.jsonObject(with: legacy) as! [String: Any]
        precondition(legacyObject["isRecovery"] == nil)
        let decodedLegacy = try JSONDecoder().decode(SavedSong.self, from: legacy)
        precondition(decodedLegacy.isRecovery == nil)
        print("PASS: sample/new/open recovery, relaunch, duplicate protection, empty drafts, saved edits, storage failures")
    }
}
