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
        // Samples must load as drafts and never overwrite the previously active save.
        let existing = afterDelete.savedSongs[0]
        precondition(Set(SampleSong.all.map(\.id)).count == SampleSong.all.count)
        for sample in SampleSong.all {
            precondition(!sample.song.notes.isEmpty)
            precondition(sample.song.stepCount > 32 && sample.song.stepCount <= Song.maximumSteps)
            precondition(sample.song.notes.contains { $0.step >= 32 })
            precondition(Set(sample.song.notes.map(\.id)).count == sample.song.notes.count)
            precondition(Set(sample.song.notes.map { "\($0.step):\($0.row)" }).count == sample.song.notes.count)
            precondition(!sample.song.loop)
            let encoded = try JSONEncoder().encode(sample.song)
            let decoded = try JSONDecoder().decode(Song.self, from: encoded)
            precondition(decoded == sample.song)
            precondition(sample.song.notes.allSatisfy {
                (0..<sample.song.stepCount).contains($0.step) && SongStore.pitches.indices.contains($0.row)
            })
            afterDelete.openSample(sample)
            precondition(afterDelete.song == sample.song && afterDelete.hasUnsavedChanges)
            precondition(!afterDelete.canUndo && !afterDelete.canRedo)
            let draft = SongStore(defaults: defaults)
            precondition(draft.song == sample.song && draft.hasUnsavedChanges)
            precondition(draft.saveSong(named: sample.song.title))
            let copyID = draft.savedSongs.first { $0.song.title == sample.song.title }!.id
            draft.song.notes.removeAll()
            precondition(draft.saveSong(named: sample.song.title))
            precondition(draft.savedSongs.first { $0.id == copyID }!.song.notes.isEmpty)
            draft.openSample(sample)
            precondition(draft.song.notes == sample.song.notes)
            precondition(draft.savedSongs.first { $0.id == existing.id }!.song == existing.song)
        }
        // A fresh install starts at Home without a phantom Continue action.
        let freshSuite = "Pluki-FreshChecks-\(UUID().uuidString)"
        let freshDefaults = UserDefaults(suiteName: freshSuite)!
        defer { freshDefaults.removePersistentDomain(forName: freshSuite) }
        let fresh = SongStore(defaults: freshDefaults)
        precondition(!fresh.hasDraft && !fresh.hasUnsavedChanges)
        precondition(!SongStore(defaults: freshDefaults).hasDraft)
        fresh.newSong()
        precondition(fresh.hasDraft && !fresh.hasUnsavedChanges)
        fresh.song.title = "My melody"
        precondition(fresh.hasUnsavedChanges)
        fresh.song.notes = [MusicNote(step: 2, row: 3, instrument: .piano)]
        precondition(fresh.saveSong(named: "My melody"))
        let savedBeforeNew = fresh.savedSongs[0]
        let oldSession = fresh.sessionID
        fresh.newSong()
        precondition(fresh.sessionID != oldSession)
        precondition(fresh.song == Song() && !fresh.canUndo && !fresh.canRedo)
        let continued = SongStore(defaults: freshDefaults)
        precondition(continued.hasDraft && continued.song == Song())
        precondition(continued.savedSongs[0].song == savedBeforeNew.song)
        // Even reusing the old title after New must create a distinct save.
        continued.song.notes = [MusicNote(step: 6, row: 5, instrument: .bells)]
        precondition(continued.saveSong(named: "My melody"))
        precondition(continued.savedSongs.count == 2)
        precondition(continued.savedSongs.first { $0.id == savedBeforeNew.id }!.song == savedBeforeNew.song)
        precondition(SongStore(defaults: freshDefaults).song == continued.song)
        let longSong = SongStore(defaults: freshDefaults)
        longSong.newSong()
        // Adding notes away from the end does not expand the sheet.
        let earlyNote = longSong.tap(step: 0, row: 4)!
        precondition(longSong.song.stepCount == 32)
        let edgeNote = longSong.tap(step: 24, row: 4)!
        precondition(longSong.song.stepCount == 64)
        longSong.undo()
        precondition(longSong.song.stepCount == 32 && longSong.song.notes == [earlyNote])
        longSong.redo()
        precondition(longSong.song.stepCount == 64 && longSong.song.notes.contains(edgeNote))
        // Moving a note into the final measure grows space with the same edit.
        longSong.move(id: edgeNote.id, horizontal: 32, vertical: 0)
        precondition(longSong.song.stepCount == 96 && longSong.song.notes[1].step == 56)
        longSong.undo()
        precondition(longSong.song.stepCount == 64 && longSong.song.notes[1].step == 24)
        longSong.redo()
        precondition(longSong.saveSong(named: "Long song"))
        let longRestored = SongStore(defaults: freshDefaults)
        precondition(longRestored.song == longSong.song)
        longRestored.openSong(longRestored.savedSongs.first { $0.song.title == "Long song" }!)
        precondition(!longRestored.hasUnsavedChanges)
        // Keep composing naturally, including the partial final growth to beat 500.
        while longRestored.song.stepCount < Song.automaticSheetLimit {
            let oldLength = longRestored.song.stepCount
            precondition(longRestored.tap(step: oldLength - 8, row: 3) != nil)
            precondition(longRestored.song.stepCount > oldLength)
        }
        precondition(longRestored.song.stepCount == 1000)
        let finalNote = longRestored.tap(step: 999, row: 4)!
        precondition(longRestored.song.stepCount == 1000)
        precondition(longRestored.tap(step: 1000, row: 4) == nil)
        longRestored.move(id: finalNote.id, horizontal: 10, vertical: 0)
        precondition(longRestored.song.notes.contains { $0.id == finalNote.id && $0.step == 999 })
        precondition(longRestored.saveSong(named: "Final beat"))
        let boundaryRestored = SongStore(defaults: freshDefaults)
        precondition(boundaryRestored.song == longRestored.song)
        boundaryRestored.openSong(boundaryRestored.savedSongs.first { $0.song.title == "Final beat" }!)
        precondition(boundaryRestored.song.notes.contains(finalNote))
        longRestored.remove(id: finalNote.id)
        precondition(longRestored.song.stepCount == 1000) // Deletion must not collapse the viewport.
        precondition(longRestored.saveSong(named: "At the limit"))
        precondition(SongStore(defaults: freshDefaults).song == longRestored.song)
        // Selection, erasing and invalid taps cannot grow a legacy short sheet.
        longRestored.newSong()
        longRestored.song.notes = [MusicNote(step: 31, row: 4, instrument: .piano)]
        _ = longRestored.tap(step: 31, row: 4)
        precondition(longRestored.song.stepCount == 32)
        longRestored.erasing = true
        _ = longRestored.tap(step: 30, row: 4)
        _ = longRestored.tap(step: 31, row: 4)
        precondition(longRestored.song.stepCount == 32 && longRestored.song.notes.isEmpty)
        precondition(longRestored.tap(step: 31, row: 9) == nil)
        // Existing Build 9 saves retain all notes and can continue growing.
        let oldLong = Song(title: "Build 9 long song", notes: [MusicNote(step: 255, row: 4, instrument: .frog)], sheetSteps: 256)
        longRestored.newSong()
        longRestored.song = oldLong
        precondition(longRestored.saveSong(named: oldLong.title))
        let legacyLongRestored = SongStore(defaults: freshDefaults)
        precondition(legacyLongRestored.song == oldLong)
        legacyLongRestored.openSong(legacyLongRestored.savedSongs.first { $0.song.title == oldLong.title }!)
        precondition(legacyLongRestored.song == oldLong && !legacyLongRestored.hasUnsavedChanges)
        precondition(legacyLongRestored.tap(step: 254, row: 3) != nil)
        precondition(legacyLongRestored.song.stepCount == 288)
        precondition(legacyLongRestored.song.notes.contains { $0.step == 255 })
        let broken = Data("not JSON".utf8)
        defaults.set(broken, forKey: "pluki-saved-songs-v1")
        let damaged = SongStore(defaults: defaults)
        precondition(!damaged.deleteSavedSong(id: first.id))
        precondition(!damaged.saveSong(named: "Must not overwrite"))
        precondition(defaults.data(forKey: "pluki-saved-songs-v1") == broken)
        print("Song persistence, samples, new-song isolation, draft continuation and corruption protection passed.")
    }
}
