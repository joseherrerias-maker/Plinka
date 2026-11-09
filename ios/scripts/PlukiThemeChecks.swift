import Foundation

@main
struct PlukiThemeChecks {
    static func main() {
        let sample = SampleSong.plukiTheme
        let song = sample.song
        precondition(sample.id == "pluki-theme" && song.title == "Pluki Theme")
        precondition(song.tempo == 132 && song.sheetSteps == 48)
        precondition((10...12).contains(Double(song.sheetSteps ?? 0) * 30 / song.tempo))
        precondition(song.notes.count == 36)
        let melody = song.notes.filter { $0.instrument == .piano }
        let rhythm = song.notes.filter { $0.instrument == .xylophone }
        precondition(melody.count == 30 && rhythm.count == 6)
        precondition(melody.sorted { $0.step < $1.step }.last?.row == 3) // C5 resolution
        let onsets = melody.map(\.step).sorted()
        precondition(onsets.first == 0 && onsets.last == 46)
        precondition(zip(onsets, onsets.dropFirst()).allSatisfy { $1 - $0 <= 2 })
        precondition(song.notes.allSatisfy { [.piano, .xylophone].contains($0.instrument) })
        precondition(song.notes.allSatisfy { (0..<song.stepCount).contains($0.step) && (0..<9).contains($0.row) })
        precondition(Set(song.notes.map { "\($0.step):\($0.row)" }).count == song.notes.count)
        precondition(SampleSong.all.contains { $0.id == "pluki-theme" })
        print("Pluki Theme: upbeat C-major cadence, 132 BPM, no long gaps, 48-step seamless loop.")
    }
}
