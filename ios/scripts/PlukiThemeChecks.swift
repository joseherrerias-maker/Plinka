import Foundation

@main
struct PlukiThemeChecks {
    static func main() {
        let sample = SampleSong.plukiTheme
        let song = sample.song
        precondition(sample.id == "pluki-theme" && song.title == "Pluki Theme")
        precondition((10...12).contains(Double(song.notes.map(\.step).max() ?? 0) * 30 / song.tempo + 0.6))
        precondition(song.notes.count >= 16)
        precondition(song.notes.allSatisfy { [.piano, .bells].contains($0.instrument) })
        precondition(song.notes.allSatisfy { (0..<song.stepCount).contains($0.step) && (0..<9).contains($0.row) })
        precondition(Set(song.notes.map { "\($0.step):\($0.row)" }).count == song.notes.count)
        precondition(SampleSong.all.contains { $0.id == "pluki-theme" })
        print("Pluki Theme: editable, original melody, instrument-only, valid musical staff.")
    }
}
