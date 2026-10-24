import SwiftUI

private enum PlinkaStyle {
    static let ink = Color(red: 0.15, green: 0.21, blue: 0.34)
    static let teal = Color(red: 0.13, green: 0.76, blue: 0.67)
    static let muted = Color(red: 0.45, green: 0.55, blue: 0.66)
}

struct ComposerView: View {
    @StateObject private var store = SongStore()
    @StateObject private var audio = PlinkaAudio()
    @State private var confirmClear = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 650
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: compact ? 12 : 19) {
                    header(compact: compact)
                    VStack(alignment: .leading, spacing: compact ? 10 : 17) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Your melody ✨")
                                    .font(.system(size: compact ? 21 : 27, weight: .heavy, design: .rounded))
                                    .foregroundStyle(PlinkaStyle.ink)
                                Text(store.song.notes.isEmpty
                                     ? "Tap the music lines to add a sound"
                                     : "\(store.song.notes.count) little notes")
                                    .font(.system(size: compact ? 12 : 14, weight: .medium))
                                    .foregroundStyle(PlinkaStyle.muted)
                            }
                            Spacer()
                            if !compact {
                                TextField("Song name", text: $store.song.title)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 210)
                            }
                        }
                        playbackControls(compact: compact)
                        StaffView(store: store, audio: audio, compact: compact)
                            .padding(.vertical, 3)
                        HStack {
                            Label("Higher is higher-pitched", systemImage: "music.note")
                            Spacer()
                            if !compact { Text("Scroll sideways to make more music →") }
                        }
                        .font(.system(size: compact ? 10 : 12, weight: .semibold))
                        .foregroundStyle(PlinkaStyle.muted)
                        instrumentTray
                        if let error = audio.audioError {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(compact ? 13 : 22)
                    .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: compact ? 22 : 34))
                    .shadow(color: .blue.opacity(0.07), radius: 26, y: 10)
                    if !compact {
                        HStack(spacing: 24) {
                            Text("① Pick a sound")
                            Text("② Tap to add a note")
                            Text("③ Press play!")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlinkaStyle.muted)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(compact ? 12 : 24)
                .frame(maxWidth: 1430)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(colors: [
                    Color(red: 0.79, green: 0.98, blue: 0.92),
                    Color(red: 0.93, green: 0.96, blue: 1.00),
                    Color(red: 0.89, green: 0.87, blue: 1.00)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
        }
        .confirmationDialog("Clear your entire melody?", isPresented: $confirmClear) {
            Button("Clear all notes", role: .destructive) {
                audio.stop()
                store.clear()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Text("♫")
                .font(.system(size: compact ? 29 : 38, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: compact ? 44 : 58, height: compact ? 44 : 58)
                .background(PlinkaStyle.teal.gradient, in: RoundedRectangle(cornerRadius: 16))
                .rotationEffect(.degrees(-5))
            VStack(alignment: .leading, spacing: 0) {
                Text("pluki!")
                    .font(.system(size: compact ? 31 : 40, weight: .black, design: .rounded))
                    .tracking(-2)
                    .foregroundStyle(PlinkaStyle.ink)
                if !compact {
                    Text("MAKE A LITTLE MUSIC")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(PlinkaStyle.muted)
                }
            }
            Spacer(minLength: 4)
            headerButton("arrow.uturn.backward", title: "Undo", disabled: !store.canUndo || audio.isPlaying) { store.undo() }
            headerButton(store.erasing ? "eraser.fill" : "eraser", title: "Erase", disabled: audio.isPlaying) {
                store.erasing.toggle()
                store.selectedID = nil
            }
            headerButton("trash", title: "Clear", disabled: audio.isPlaying || store.song.notes.isEmpty) {
                confirmClear = true
            }
        }
    }

    private func headerButton(_ icon: String, title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PlinkaStyle.ink)
                .frame(width: 43, height: 43)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(title)
    }

    private func playbackControls(compact: Bool) -> some View {
        Group {
            if compact {
                VStack(spacing: 8) {
                    tempoPicker
                    playbackButtons
                }
            } else {
                HStack(spacing: 14) {
                    tempoPicker
                    Spacer(minLength: 10)
                    playbackButtons
                }
            }
        }
    }

    private var tempoPicker: some View {
        HStack(spacing: 9) {
            Text("TEMPO")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(PlinkaStyle.muted)
            Slider(value: $store.song.tempo, in: 65...160, step: 5)
                .tint(PlinkaStyle.teal)
                .frame(minWidth: 82, maxWidth: 160)
                .disabled(audio.isPlaying)
            Text("\(Int(store.song.tempo)) BPM")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(PlinkaStyle.ink)
        }
        .padding(.horizontal, 11).padding(.vertical, 9)
        .background(Color(red: 0.95, green: 0.97, blue: 0.99), in: RoundedRectangle(cornerRadius: 14))
    }

    private var playbackButtons: some View {
        HStack(spacing: 8) {
            Button {
                audio.playOrPause(store.song)
            } label: {
                Label(audio.isPaused ? "Resume" : (audio.isPlaying ? "Pause" : "Play"),
                      systemImage: audio.isPlaying && !audio.isPaused ? "pause.fill" : "play.fill")
            }
            .buttonStyle(PlinkaPill(color: PlinkaStyle.teal, foreground: .white))
            Button { audio.stop() } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(PlinkaPill(color: Color(red: 1, green: 0.93, blue: 0.89),
                                    foreground: Color(red: 0.84, green: 0.37, blue: 0.32)))
            Button {
                store.song.loop.toggle()
                audio.updateLoop(store.song)
            } label: {
                Label("Loop", systemImage: "repeat")
            }
            .buttonStyle(PlinkaPill(
                color: store.song.loop
                    ? Color(red: 0.73, green: 0.97, blue: 0.90)
                    : Color(red: 0.91, green: 0.94, blue: 1.0),
                foreground: store.song.loop ? Color(red: 0.05, green: 0.49, blue: 0.42)
                                            : PlinkaStyle.ink))
            .accessibilityAddTraits(store.song.loop ? [.isSelected] : [])
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded))
    }

    private var instrumentTray: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🎨 Pick a sound")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(PlinkaStyle.ink)
            ScrollView(.horizontal) {
                HStack(spacing: 11) {
                    ForEach(Instrument.allCases) { instrument in
                        Button {
                            guard !audio.isPlaying else { return }
                            store.choose(instrument)
                            audio.preview(instrument, row: 5)
                        } label: {
                            VStack(spacing: 6) {
                                Text(instrument.emoji)
                                    .font(.system(size: 34))
                                    .frame(width: 61, height: 49)
                                    .background(instrument.tint.opacity(0.28),
                                                in: RoundedRectangle(cornerRadius: 13))
                                Text(instrument.label)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundStyle(PlinkaStyle.ink)
                            }
                            .frame(width: 91, height: 91)
                            .background(store.chosen == instrument
                                ? Color(red: 0.91, green: 1.0, blue: 0.97) : .white,
                                in: RoundedRectangle(cornerRadius: 18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(store.chosen == instrument
                                        ? PlinkaStyle.teal : .gray.opacity(0.13), lineWidth: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(audio.isPlaying)
                        .accessibilityLabel(instrument.label)
                    }
                }
                .padding(3)
            }
            .scrollIndicators(.hidden)
        }
        .padding(13)
        .background(Color(red: 0.95, green: 0.97, blue: 0.985),
                    in: RoundedRectangle(cornerRadius: 21))
    }
}

private struct PlinkaPill: ButtonStyle {
    let color: Color
    let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .frame(minHeight: 45)
            .foregroundStyle(foreground)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct StaffView: View {
    @ObservedObject var store: SongStore
    @ObservedObject var audio: PlinkaAudio
    let compact: Bool

    private var cellWidth: CGFloat { compact ? 54 : 72 }
    private var rowHeight: CGFloat { compact ? 31 : 43 }
    private var gutter: CGFloat { compact ? 55 : 82 }
    private var top: CGFloat { compact ? 65 : 80 }
    private var trackHeight: CGFloat { top + rowHeight * 8 + 45 }
    private var trackWidth: CGFloat { gutter + CGFloat(SongStore.steps) * cellWidth }

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal) {
                ZStack(alignment: .topLeading) {
                    Canvas { context, size in
                        for row in stride(from: 0, through: 8, by: 2) {
                            let y = top + CGFloat(row) * rowHeight
                            var p = Path()
                            p.move(to: CGPoint(x: gutter, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(p, with: .color(Color(red: 0.59, green: 0.68, blue: 0.79)),
                                           lineWidth: 2)
                        }
                        for step in 0...SongStore.steps {
                            let x = gutter + CGFloat(step) * cellWidth
                            var p = Path()
                            p.move(to: CGPoint(x: x, y: top - 25))
                            p.addLine(to: CGPoint(x: x, y: top + rowHeight * 8 + 20))
                            context.stroke(p, with: .color(Color(red: 0.81, green: 0.87, blue: 0.93)
                                .opacity(step.isMultiple(of: 8) ? 0.88 : 0.33)),
                                lineWidth: step.isMultiple(of: 8) ? 2 : 1)
                        }
                    }
                    .frame(width: trackWidth, height: trackHeight)

                    // The tappable music surface is behind placed stickers.
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .frame(width: trackWidth - gutter, height: trackHeight)
                        .offset(x: gutter)
                        .onTapGesture { location in
                            guard !audio.isPlaying else { return }
                            let rawY = location.y - top
                            guard rawY >= -rowHeight * 0.55,
                                  rawY <= rowHeight * 8.55 else { return }
                            let step = Int(floor(location.x / cellWidth))
                            let row = Int(round(rawY / rowHeight))
                            if let note = store.tap(step: step, row: row) {
                                audio.preview(note.instrument, row: note.row)
                            }
                        }

                    Text("𝄞")
                        .font(.system(size: compact ? 74 : 103))
                        .foregroundStyle(Color(red: 0.37, green: 0.43, blue: 0.56))
                        .position(x: gutter * 0.50, y: top + rowHeight * 3.65)

                    ForEach(0..<4, id: \.self) { measure in
                        Text("MEASURE \(measure + 1)")
                            .font(.system(size: compact ? 10 : 12, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.61, green: 0.68, blue: 0.76))
                            .position(x: gutter + CGFloat(measure * 8) * cellWidth + 70, y: 23)
                    }

                    ForEach(store.song.notes) { note in
                        Text(note.instrument.emoji)
                            .font(.system(size: compact ? 23 : 29))
                            .frame(width: compact ? 41 : 54, height: compact ? 39 : 49)
                            .background(note.instrument.tint,
                                        in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(.white.opacity(0.82), lineWidth: 2)
                            }
                            .shadow(color: note.instrument.tint.opacity(0.40), radius: 3, y: 4)
                            .overlay {
                                if store.selectedID == note.id {
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(PlinkaStyle.teal, lineWidth: 3)
                                        .padding(-3)
                                }
                            }
                            .position(x: gutter + (CGFloat(note.step) + 0.5) * cellWidth,
                                      y: top + CGFloat(note.row) * rowHeight)
                            .onTapGesture {
                                guard !audio.isPlaying else { return }
                                if store.erasing {
                                    store.remove(id: note.id)
                                } else {
                                    store.selectedID = note.id
                                    audio.preview(note.instrument, row: note.row)
                                }
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 12)
                                    .onEnded { drag in
                                        guard !audio.isPlaying else { return }
                                        let dx = Int((drag.translation.width / cellWidth).rounded())
                                        let dy = Int((drag.translation.height / rowHeight).rounded())
                                        store.move(id: note.id, horizontal: dx, vertical: dy)
                                    }
                            )
                            .accessibilityLabel("\(note.instrument.label), note position \(note.row + 1), step \(note.step + 1)")
                    }
                    if let step = audio.playheadStep {
                        Capsule().fill(PlinkaStyle.teal)
                            .frame(width: 3, height: rowHeight * 8 + 37)
                            .shadow(color: PlinkaStyle.teal.opacity(0.55), radius: 5)
                            .position(x: gutter + (CGFloat(step) + 0.5) * cellWidth,
                                      y: top + rowHeight * 4)
                    }
                    // Minimal scroll anchors used to follow the playhead.
                    ForEach(0..<SongStore.steps, id: \.self) { step in
                        Color.clear.frame(width: 1, height: 1)
                            .position(x: gutter + CGFloat(step) * cellWidth, y: 2)
                            .id(step)
                    }
                }
                .frame(width: trackWidth, height: trackHeight)
                .background(.white)
            }
            .scrollIndicators(.visible, axes: .horizontal)
            .onChange(of: Int(audio.playheadStep ?? 0)) { _, newStep in
                if audio.isPlaying && newStep > 4 && newStep.isMultiple(of: 4) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        scroller.scrollTo(min(31, newStep + 4), anchor: .center)
                    }
                }
            }
        }
        .frame(height: trackHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color(red: 0.86, green: 0.91, blue: 0.95), lineWidth: 2)
        }
    }
}
