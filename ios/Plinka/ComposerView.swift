import SwiftUI
import UIKit
import CoreText

private enum PlukiStyle {
    static let ink = Color(red: 0.13, green: 0.22, blue: 0.34)
    static let green = Color(red: 0.20, green: 0.75, blue: 0.43)
    static let blue = Color(red: 0.13, green: 0.69, blue: 0.90)
    static let paper = Color(red: 1, green: 0.98, blue: 0.93)
}

struct ComposerView: View {
    @StateObject private var store = SongStore()
    @StateObject private var audio = PlinkaAudio()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showHome = true
    @State private var confirmNew = false
    @State private var confirmClear = false
    @State private var showSongMenu = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSettings = false
    @State private var showSongs = false
    @State private var showSamples = false
    @State private var showSave = false
    @State private var showRename = false
    @State private var renameTitle = ""
    @FocusState private var renameFocused: Bool
    @State private var showVideoExport = false
    @State private var saveTitle = ""
    @FocusState private var saveNameFocused: Bool
    @State private var pendingSong: SavedSong?
    @State private var confirmOpen = false
    @State private var pendingDelete: SavedSong?
    @State private var confirmDelete = false
    @State private var soundGroup: SoundGroup = .instruments

    #if DEBUG
    @State private var visualStage = "starting"
    #endif

    private var versionLabel: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "PlukiReleaseBuild") as? String ?? "?"
        return "Build \(build)"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Keep the composer mounted so Home/Continue preserves its scroll position.
                composerContent
                    .opacity(showHome ? 0 : 1)
                    .allowsHitTesting(!showHome && !showSongMenu)
                    .accessibilityHidden(showHome || showSongMenu)
                if showHome {
                    homeScreen(size: geometry.size)
                        .accessibilityHidden(showSongMenu)
                }
                if showSongMenu {
                    songMenuOverlay(size: geometry.size)
                        .transition(.opacity)
                }
            }
        }
        .foregroundStyle(PlukiStyle.ink)
        .overlay(alignment: .topLeading) {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--visual-tour") {
                Text(visualStage).font(.system(size: 1)).opacity(0.01)
                    .accessibilityIdentifier("visual-stage")
            }
            #endif
        }
        .task {
            #if DEBUG
            await runVisualTourIfRequested()
            #endif
        }
        .sheet(isPresented: $showRename) { renameSongSheet }
        .sheet(isPresented: $showSettings) { settings }
        .sheet(isPresented: $showSongs) { savedSongsView }
        .sheet(isPresented: $showSamples) { samplesView }
        .sheet(isPresented: $showVideoExport) { SongVideoExportView(song: store.song) }
        .sheet(isPresented: $showSave, onDismiss: { saveNameFocused = false }) { saveSongSheet }
        .alert("Saved songs", isPresented: Binding(get: { store.libraryError != nil }, set: { if !$0 { store.libraryError = nil } })) {
            Button("OK") { store.libraryError = nil }
        } message: { Text(store.libraryError ?? "") }
        .confirmationDialog("Save your current song before starting a new one?", isPresented: $confirmNew, titleVisibility: .visible) {
            Button("Save and start new") {
                if store.saveSong(named: store.song.title) { startNewSong() }
            }
            Button("Start without saving", role: .destructive) { startNewSong() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Clear your entire melody?", isPresented: $confirmClear) {
            Button("Clear all notes", role: .destructive) { audio.stop(); store.clear() }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { audio.pause() }
        }
    }

    private var renameSongSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Song name", text: $renameTitle)
                        .focused($renameFocused)
                        .submitLabel(.done)
                        .onSubmit { finishRenamingSong() }
                        .accessibilityIdentifier("rename-song-name")
                } footer: {
                    Text("Updates the current song title. Use Save song to keep it in your saved projects.")
                }
            }
            .navigationTitle("Rename song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRename = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { finishRenamingSong() }.fontWeight(.semibold)
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                renameFocused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func finishRenamingSong() {
        let title = renameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        store.song.title = title.isEmpty ? "Untitled Song" : String(title.prefix(80))
        renameFocused = false
        showRename = false
    }

    private var saveSongSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Song name", text: $saveTitle)
                        .focused($saveNameFocused)
                        .submitLabel(.done)
                        .onSubmit { finishSavingSong() }
                        .accessibilityIdentifier("save-song-name")
                } footer: {
                    Text("Keep this song on this device. Use a different name to save a new copy.")
                }
            }
            .navigationTitle("Save song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSave = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { finishSavingSong() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                // Focus after the sheet has attached its text field to the window.
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                saveNameFocused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func finishSavingSong() {
        _ = store.saveSong(named: saveTitle)
        saveNameFocused = false
        showSave = false
    }

    private var composerContent: some View {
        GeometryReader { geometry in
            let short = geometry.size.height < 500
            let narrow = geometry.size.width < (short ? 780 : 900)
            let padding: CGFloat = short ? 8 : 16
            let gap: CGFloat = short ? 8 : 12
            let toolbar: CGFloat = narrow ? 108 : (short ? 52 : 72)
            let tray: CGFloat = short ? 94 : 140
            let staffHeight = max(100, geometry.size.height - 2 * padding - 2 * gap - toolbar - tray)
            VStack(spacing: gap) {
                toolbarView(narrow: narrow, short: short, iconOnlyBrand: geometry.size.width < 400)
                    .frame(height: toolbar)
                StaffView(store: store, audio: audio, height: staffHeight, short: short)
                    .id(store.sessionID)
                    .frame(height: staffHeight)
                instrumentTray(short: short)
                    .frame(height: tray)
            }
            .padding(padding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .background {
                Image("studio-room").resizable().scaledToFill()
                    .overlay(.white.opacity(0.12)).ignoresSafeArea()
            }
            .clipped()
        }
    }

    private var homeBrand: some View {
        VStack(spacing: 12) {
            wordmark(small: false)
            Text("Make a little music")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(PlukiStyle.paper.opacity(0.85), in: RoundedRectangle(cornerRadius: 28))
    }

    private func homeScreen(size: CGSize) -> some View {
        ScrollView {
            Group {
                if size.height < 500 && size.width > 600 {
                    HStack(spacing: 28) {
                        homeBrand
                        homeMenu
                    }
                } else {
                    VStack(spacing: 24) {
                        homeBrand
                        homeMenu
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(minHeight: size.height)
        }
        .background {
            Image("studio-room").resizable().scaledToFill()
                .overlay(.white.opacity(0.18)).ignoresSafeArea()
        }
        .clipped()
    }

    private var homeMenu: some View {
        VStack(spacing: 6) {
            navigationActions(inSong: false)
            if store.hasDraft {
                Divider().padding(.horizontal, 12)
                songMenuRow("Continue song", icon: "play.circle.fill", color: PlukiStyle.green) {
                    showHome = false
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(PlukiStyle.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.9), lineWidth: 2))
        .shadow(color: PlukiStyle.ink.opacity(0.15), radius: 14, y: 6)
    }

    private func songMenuOverlay(size: CGSize) -> some View {
        ZStack {
            Color.black.opacity(0.15)
                .contentShape(Rectangle())
                .onTapGesture { dismissSongMenu() }
                .accessibilityHidden(true)
            ScrollView {
                VStack(spacing: 6) {
                    HStack {
                        Text("Song menu").font(.system(.title2, design: .rounded, weight: .bold))
                        Spacer()
                        Button { dismissSongMenu() } label: {
                            Image(systemName: "xmark").font(.headline)
                                .frame(width: 44, height: 44)
                                .background(PlukiStyle.blue.opacity(0.12), in: Circle())
                        }.accessibilityLabel("Close menu")
                    }.padding(.horizontal, 6)
                    Button {
                        renameTitle = store.song.title
                        dismissSongMenu()
                        showRename = true
                    } label: {
                        HStack {
                            Text(store.song.title).lineLimit(2).multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            Image(systemName: "pencil")
                        }
                        .font(.system(.headline, design: .rounded))
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(PlukiStyle.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rename song, \(store.song.title)")
                    .accessibilityIdentifier("rename-song")
                    navigationActions(inSong: true)
                    Divider().padding(.horizontal, 12)
                    songMenuRow("Back to home", icon: "house.fill", color: .orange) {
                        audio.pause()
                        showHome = true
                    }
                }.padding(14)
            }
            .frame(width: min(360, size.width - 24), height: min(470, max(100, size.height - 24)))
            .background(PlukiStyle.paper, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.9), lineWidth: 2))
            .shadow(color: PlukiStyle.ink.opacity(0.18), radius: 16, y: 7)
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { dismissSongMenu() }
        }
    }

    @ViewBuilder
    private func navigationActions(inSong: Bool) -> some View {
        songMenuRow("New song", icon: "plus.circle.fill", color: PlukiStyle.green) {
            if inSong && store.hasUnsavedChanges { confirmNew = true }
            else { startNewSong() }
        }
        songMenuRow("Open song", icon: "folder.fill", color: .orange) {
            audio.stop(); showSongs = true
        }
        if inSong {
            songMenuRow("Save song", icon: "square.and.arrow.down.fill", color: PlukiStyle.green) {
                saveTitle = store.song.title; showSave = true
            }
        }
        if inSong {
            songMenuRow("Export video", icon: "video.fill", color: .pink) {
                audio.stop(); showVideoExport = true
            }
            .disabled(store.song.notes.isEmpty)
        }
        songMenuRow("Samples", icon: "music.note.list", color: .purple) {
            audio.stop(); showSamples = true
        }
        Divider().padding(.horizontal, 12)
        songMenuRow("Settings", icon: "gearshape.fill", color: PlukiStyle.blue) {
            showSettings = true
        }
    }

    private func startNewSong() {
        audio.stop()
        store.newSong()
        soundGroup = .instruments
        showHome = false
    }

    private func toolbarView(narrow: Bool, short: Bool, iconOnlyBrand: Bool) -> some View {
        Group {
            if narrow {
                VStack(spacing: 6) {
                    HStack {
                        if iconOnlyBrand {
                            Image(systemName: "music.note")
                                .font(.system(size: 25, weight: .black))
                                .foregroundStyle(PlukiStyle.green)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                                .accessibilityLabel("Pluki")
                        } else {
                            wordmark(small: true)
                        }
                        Spacer(minLength: 4)
                        editButtons
                    }
                    HStack(spacing: 8) {
                        transport
                        tempo(compact: true)
                    }
                }
            } else {
                HStack(spacing: short ? 8 : 18) {
                    wordmark(small: short)
                    Spacer(minLength: 0)
                    transport
                    tempo(compact: short)
                    editButtons
                }
            }
        }
    }

    private func wordmark(small: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "music.note").foregroundStyle(PlukiStyle.green)
            Text("pluki!").tracking(-1).fixedSize(horizontal: true, vertical: false)
        }
        .font(.system(size: small ? 25 : 35, weight: .black, design: .rounded))
        .padding(.horizontal, small ? 10 : 18)
        .frame(height: small ? 44 : 62)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityLabel("Pluki")
    }

    private var transport: some View {
        HStack(spacing: 6) {
            tool("backward.end.fill", title: "Restart", disabled: store.song.notes.isEmpty) {
                audio.stop(); audio.start(store.song)
            }
            Button { audio.playOrPause(store.song) } label: {
                Image(systemName: audio.isPlaying && !audio.isPaused ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(PlukiStyle.green.gradient, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2))
                    .shadow(color: PlukiStyle.green.opacity(0.3), radius: 4, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(store.song.notes.isEmpty)
            .opacity(store.song.notes.isEmpty ? 0.5 : 1)
            .accessibilityLabel(audio.isPaused ? "Resume" : (audio.isPlaying ? "Pause" : "Play"))
            tool("stop.fill", title: "Stop", disabled: !audio.isPlaying) { audio.stop() }
            tool("repeat", title: "Loop", selected: store.song.loop) {
                store.song.loop.toggle()
                audio.updateLoop(store.song)
            }
            .accessibilityValue(store.song.loop ? "On" : "Off")
        }
    }

    private var editButtons: some View {
        HStack(spacing: 4) {
            tool("arrow.uturn.backward", title: "Undo", disabled: !store.canUndo || audio.isPlaying) { store.undo() }
            tool("arrow.uturn.forward", title: "Redo", disabled: !store.canRedo || audio.isPlaying) { store.redo() }
            tool(store.erasing ? "eraser.fill" : "eraser", title: "Eraser",
                 disabled: audio.isPlaying, selected: store.erasing) {
                store.erasing.toggle()
                store.selectedID = nil
            }
            .accessibilityValue(store.erasing ? "On" : "Off")
            tool("trash", title: "Clear all notes", disabled: audio.isPlaying || store.song.notes.isEmpty) {
                confirmClear = true
            }
            tool("line.3.horizontal", title: "Song menu", selected: showSongMenu) {
                audio.pause()
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { showSongMenu.toggle() }
            }
        }
    }

    private func dismissSongMenu() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { showSongMenu = false }
    }

    private func songMenuRow(_ title: String, icon: String, color: Color,
                             action: @escaping () -> Void) -> some View {
        Button {
            dismissSongMenu()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
                Text(title).font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(PlukiStyle.ink)
                Spacer(minLength: 0)
            }
            .padding(6)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }

    private func openSample(_ sample: SampleSong) {
        audio.stop()
        store.openSample(sample)
        showHome = false
        showSamples = false
    }

    private var samplesView: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(SampleSong.all) { sample in
                        Button {
                            openSample(sample)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(sample.song.title).font(.headline)
                                Text(sample.detail).font(.subheadline).foregroundStyle(.secondary)
                                Text("\(sample.song.stepCount / 8) measures")
                                    .font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                        }
                    }
                } footer: {
                    Text("Open a starter, press Play, and make it yours. Save keeps your own copy; the samples always stay available.")
                }
            }
            .navigationTitle("Samples")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSamples = false } } }
        }
    }

    private func openSavedSong(_ saved: SavedSong) {
        audio.stop()
        store.openSong(saved)
        showHome = false
        showSongs = false
        pendingSong = nil
    }

    private var savedSongsView: some View {
        NavigationStack {
            List {
                if store.savedSongs.isEmpty {
                    ContentUnavailableView("No saved songs yet", systemImage: "music.note.list",
                        description: Text("Choose Save from the song menu to keep your melody."))
                }
                ForEach(store.savedSongs) { saved in
                    HStack {
                    Button {
                        if store.hasUnsavedChanges {
                            pendingSong = saved
                            confirmOpen = true
                        } else { openSavedSong(saved) }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(saved.song.title).font(.headline)
                            Text("\(saved.song.notes.count) notes · \(Int(saved.song.tempo)) BPM")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text(saved.savedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.borderless)
                    Button(role: .destructive) {
                        pendingDelete = saved
                        confirmDelete = true
                    } label: {
                        Image(systemName: "trash").frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Delete \(saved.song.title)")
                    }
                }
            }
            .alert("Delete saved song?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let saved = pendingDelete { store.deleteSavedSong(id: saved.id) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("Remove \"\(pendingDelete?.song.title ?? "this song")\" from saved songs? This cannot be undone. Your current melody will stay open.")
            }
            .navigationTitle("Open song")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSongs = false } } }
            .confirmationDialog("Save your current changes before opening another song?", isPresented: $confirmOpen, titleVisibility: .visible) {
                Button("Save and open") {
                    if store.saveSong(named: store.song.title), let id = pendingSong?.id,
                       let saved = store.savedSongs.first(where: { $0.id == id }) { openSavedSong(saved) }
                }
                Button("Open without saving", role: .destructive) {
                    if let saved = pendingSong { openSavedSong(saved) }
                }
                Button("Cancel", role: .cancel) { pendingSong = nil }
            }
        }
    }

    private func tool(_ icon: String, title: String, disabled: Bool = false, selected: Bool = false,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15)
                    .fill(selected ? PlukiStyle.green.opacity(0.22) : .clear))
                .overlay(RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(selected ? PlukiStyle.green : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func tempo(compact: Bool) -> some View {
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 0) {
                if !compact { Text("Tempo").font(.caption) }
                Text("\(Int(store.song.tempo))").font(.system(size: 13, weight: .bold, design: .rounded)).monospacedDigit()
            }
            Slider(value: $store.song.tempo, in: 65...160, step: 5)
                .tint(PlukiStyle.green).disabled(audio.isPlaying)
                .accessibilityLabel("Tempo").accessibilityValue("\(Int(store.song.tempo)) beats per minute")
        }
        .padding(.horizontal, 8)
        .frame(minWidth: compact ? 82 : 95, maxWidth: compact ? 155 : 240, minHeight: 44)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
    }

    private func instrumentTray(short: Bool) -> some View {
        ScrollViewReader { proxy in
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    ForEach(SoundGroup.allCases) { group in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(group.instruments[0], anchor: .leading)
                            }
                        } label: {
                            Label(group.rawValue, systemImage: group.icon)
                                .font(.system(size: short ? 11 : 12, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: short ? 24 : 28)
                                .background(soundGroup == group ? PlukiStyle.blue.opacity(0.16) : .clear,
                                            in: Capsule())
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(audio.isPlaying)
                        .accessibilityAddTraits(soundGroup == group ? [.isSelected] : [])
                    }
                }.padding(.horizontal, 8).padding(.top, 4)
                GeometryReader { geometry in
                    let cardWidth: CGFloat = max(short ? 72 : 92, (geometry.size.width - 72) / 8)
                    let funWidth = CGFloat(SoundGroup.fun.instruments.count) * (cardWidth + 8) - 8
                    let endPadding = max(0, geometry.size.width - 16 - funWidth)
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(Instrument.allCases) { instrument in
                                Button {
                                    store.choose(instrument)
                                    audio.preview(instrument, row: 5)
                                } label: {
                                    VStack(spacing: 0) {
                                        InstrumentSticker(instrument: instrument)
                                            .frame(height: short ? 41 : 74)
                                        Text(instrument.label)
                                            .font(.system(size: short ? 10 : 12, weight: .bold, design: .rounded))
                                            .lineLimit(1)
                                    }
                                    .frame(width: cardWidth, height: short ? 56 : 98)
                                    .background(store.chosen == instrument && !store.erasing
                                        ? Color(red: 0.86, green: 0.97, blue: 1) : instrument.tint.opacity(0.16),
                                        in: RoundedRectangle(cornerRadius: 15))
                                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(
                                        store.chosen == instrument && !store.erasing ? PlukiStyle.blue : .clear, lineWidth: 2))
                                }
                                .buttonStyle(.plain).disabled(audio.isPlaying)
                                .id(instrument)
                                .background(GeometryReader { card in
                                    Color.clear.preference(key: SoundPositionKey.self, value: [
                                        instrument: card.frame(in: .named("soundTray")).minX
                                    ])
                                })
                                .accessibilityLabel(instrument.label)
                                .accessibilityAddTraits(store.chosen == instrument ? [.isSelected] : [])
                            }
                        }.padding(.horizontal, 8).padding(.vertical, 4)
                            .padding(.trailing, endPadding)
                    }
                    .coordinateSpace(name: "soundTray")
                    .onPreferenceChange(SoundPositionKey.self) { positions in
                        // The category follows the card nearest the leading edge.
                        if let first = positions.min(by: { abs($0.value - 8) < abs($1.value - 8) })?.key {
                            let visibleGroup = SoundGroup.group(for: first)
                            if visibleGroup != soundGroup { soundGroup = visibleGroup }
                        }
                    }
                    .scrollIndicators(.visible)
                }
            }
            .background(PlukiStyle.paper.opacity(0.96), in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var soundCredits: String {
        guard let url = Bundle.main.url(forResource: "CREDITS", withExtension: "txt", subdirectory: "Sounds"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "Sound credits unavailable." }
        return text
    }

    private var settings: some View {
        NavigationStack {
            Form {
                Section("Help") {
                    NavigationLink { PlukiHelpView() } label: {
                        Label("How to play & help", systemImage: "questionmark.circle.fill")
                    }
                }
                if let error = audio.audioError { Section { Text(error).foregroundStyle(.red) } }
                Section("About Pluki") {
                    Text(versionLabel).foregroundStyle(.secondary)
                    NavigationLink { PlukiPrivacyView() } label: {
                        Label("Privacy policy", systemImage: "hand.raised.fill")
                    }
                    NavigationLink("Sound credits") {
                        ScrollView {
                            Text(soundCredits).font(.footnote).textSelection(.enabled).padding()
                        }.navigationTitle("Sound credits")
                    }
                }
            }
            .navigationTitle(showHome ? "Settings" : "Song settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSettings = false } } }
        }
        .presentationDetents([.medium, .large])
    }
}

private enum SoundGroup: String, CaseIterable, Identifiable {
    case instruments = "Instruments", animals = "Animals", fun = "Fun"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .instruments: return "pianokeys"
        case .animals: return "pawprint.fill"
        case .fun: return "star.fill"
        }
    }
    static func group(for instrument: Instrument) -> SoundGroup {
        allCases.first { $0.instruments.contains(instrument) } ?? .instruments
    }
    var instruments: [Instrument] {
        switch self {
        case .instruments: return [.piano, .xylophone, .guitar, .trumpet, .flute, .bells, .synth, .drums]
        case .animals: return [.puppy, .kitten, .chicken, .pig, .cow, .frog]
        case .fun: return [.sparkle, .boing, .bubbles, .whistle, .laser]
        }
    }
}

private struct SoundPositionKey: PreferenceKey {
    static let defaultValue: [Instrument: CGFloat] = [:]
    static func reduce(value: inout [Instrument: CGFloat], nextValue: () -> [Instrument: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct InstrumentSticker: View {
    let instrument: Instrument
    var body: some View {
        Image(instrument.rawValue).resizable().scaledToFit()
            .shadow(color: instrument.tint.opacity(0.12), radius: 1, y: 1)
    }
}

@MainActor
enum ClefArtwork {
    // Use the actual glyph's ink bounds, including font fallback and overhang.
    // A fixed transparent image can then fit inside the gutter at every height.
    static let image: UIImage = {
        let text = NSAttributedString(string: "𝄞", attributes: [
            .font: UIFont.systemFont(ofSize: 240),
            .foregroundColor: UIColor(red: 0.13, green: 0.22, blue: 0.34, alpha: 1)
        ])
        let line = CTLineCreateWithAttributedString(text as CFAttributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds).integral
        guard !bounds.isNull, !bounds.isInfinite, !bounds.isEmpty else { return UIImage() }
        let size = CGSize(width: max(1, bounds.width + 8), height: max(1, bounds.height + 8))
        return UIGraphicsImageRenderer(size: size).image { renderer in
            let context = renderer.cgContext
            context.translateBy(x: 4 - bounds.minX, y: 4 + bounds.maxY)
            context.scaleBy(x: 1, y: -1)
            context.textPosition = .zero
            CTLineDraw(line, context)
        }
    }()
}

private struct StaffView: View {
    @ObservedObject var store: SongStore
    @ObservedObject var audio: PlinkaAudio
    let height: CGFloat
    let short: Bool

    var body: some View {
        let metrics = StaffMetrics(height: height, short: short, steps: store.song.stepCount)
        FollowScrollView(audio: audio, metrics: metrics) {
            StaffContent(store: store, audio: audio, metrics: metrics)
        }
        .background(PlukiStyle.paper, in: RoundedRectangle(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.8), lineWidth: 2))
        .overlay(alignment: .topTrailing) {
            if store.erasing {
                Text("Eraser on").font(.caption.bold())
                    .padding(8)
                    .background(PlukiStyle.paper, in: Capsule())
                    .padding(6)
            }
        }
    }
}

private struct StaffMetrics: Equatable {
    let height: CGFloat
    let short: Bool
    let steps: Int
    var top: CGFloat { short ? 32 : 60 }
    var bottom: CGFloat { short ? 28 : 48 }
    var row: CGFloat { max(5, (height - top - bottom) / 8) }
    var cell: CGFloat { short ? 60 : 84 }
    var gutter: CGFloat { short ? 60 : 90 }
    var width: CGFloat { gutter + CGFloat(steps) * cell + 16 }
    var sticker: CGFloat { min(short ? 48 : 78, row * (short ? 3.4 : 2.6)) }
    func x(_ step: Double) -> CGFloat { gutter + (CGFloat(step) + 0.5) * cell }
}

private struct StaffContent: View {
    @ObservedObject var store: SongStore
    @ObservedObject var audio: PlinkaAudio
    let metrics: StaffMetrics

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(.clear).contentShape(Rectangle())
                .frame(width: metrics.width, height: metrics.height)
                .onTapGesture { location in
                    guard !audio.isPlaying, location.x >= metrics.gutter else { return }
                    let row = Int(((location.y - metrics.top) / metrics.row).rounded())
                    let step = Int(floor((location.x - metrics.gutter) / metrics.cell))
                    if let note = store.tap(step: step, row: row) { audio.preview(note.instrument, row: note.row) }
                }
            Image(uiImage: ClefArtwork.image).resizable().scaledToFit()
                .frame(width: metrics.gutter - 24, height: metrics.row * 7)
                .position(x: metrics.gutter * 0.5, y: metrics.top + metrics.row * 4)
                .allowsHitTesting(false)
            ForEach(0..<metrics.steps, id: \.self) { step in
                Text(step.isMultiple(of: 2) ? "\(step / 2 + 1)" : "·")
                    .font(.system(size: metrics.short ? 11 : 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PlukiStyle.ink.opacity(0.4))
                    .position(x: metrics.x(Double(step)), y: 16)
                    .allowsHitTesting(false)
            }
            ForEach(store.song.notes) { note in
                let active = audio.isPlaying && Int(audio.playheadStep ?? -1) == note.step
                InstrumentSticker(instrument: note.instrument)
                    .frame(width: metrics.sticker, height: metrics.sticker)
                    .background {
                        if active { Circle().fill(PlukiStyle.blue.opacity(0.18)).padding(-3) }
                    }
                    .overlay {
                        if store.selectedID == note.id && !audio.isPlaying {
                            RoundedRectangle(cornerRadius: 12).strokeBorder(PlukiStyle.blue, lineWidth: 2).padding(-2)
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .position(x: metrics.x(Double(note.step)), y: metrics.top + CGFloat(note.row) * metrics.row)
                    .onTapGesture {
                        guard !audio.isPlaying else { return }
                        if store.erasing { store.remove(id: note.id) }
                        else { store.selectedID = note.id; audio.preview(note.instrument, row: note.row) }
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 12).onEnded { drag in
                        guard !audio.isPlaying else { return }
                        store.move(id: note.id,
                                   horizontal: Int((drag.translation.width / metrics.cell).rounded()),
                                   vertical: Int((drag.translation.height / metrics.row).rounded()))
                    })
                    .accessibilityLabel("\(note.instrument.label), pitch position \(note.row + 1), step \(note.step + 1)")
            }
        }
        .frame(width: metrics.width, height: metrics.height)
    }
}

/// The lines use a viewport-sized backing surface even for a 500-beat song.
/// Keeping this separate from the wide SwiftUI note content avoids oversized
/// Canvas textures and lets scrolling, rotation and returning Home redraw it.
@MainActor
private final class StaffGridView: UIView {
    private var metrics: StaffMetrics
    private var offset = CGPoint.zero

    init(metrics: StaffMetrics) {
        self.metrics = metrics
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        contentMode = .redraw
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(metrics: StaffMetrics, offset: CGPoint) {
        guard self.metrics != metrics || self.offset != offset else { return }
        self.metrics = metrics
        self.offset = offset
        setNeedsDisplay()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), bounds.width > 0 else { return }
        let ink = UIColor(red: 0.13, green: 0.22, blue: 0.34, alpha: 1)
        let left = max(0, metrics.gutter - 12 - offset.x)
        let right = min(bounds.width, metrics.width - offset.x)
        guard right > left else { return }
        context.setStrokeColor(ink.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(1.6)
        for row in stride(from: 0, through: 8, by: 2) {
            let y = metrics.top + CGFloat(row) * metrics.row - offset.y
            context.move(to: CGPoint(x: left, y: y))
            context.addLine(to: CGPoint(x: right, y: y))
        }
        context.strokePath()
        // Include one column outside either edge for fractional scroll positions.
        let first = max(0, Int(floor((offset.x - metrics.gutter) / metrics.cell)) - 1)
        let last = min(metrics.steps - 1, Int(ceil((offset.x + bounds.width - metrics.gutter) / metrics.cell)) + 1)
        guard first <= last else { return }
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [5, 6])
        for step in first...last {
            let x = metrics.x(Double(step)) - offset.x
            context.setStrokeColor(ink.withAlphaComponent(step.isMultiple(of: 2) ? 0.12 : 0.05).cgColor)
            context.move(to: CGPoint(x: x, y: 28 - offset.y))
            context.addLine(to: CGPoint(x: x, y: metrics.height - 15 - offset.y))
            context.strokePath()
        }
    }
}

/// The staff is hosted in a real scroll view. A display link moves only the
/// lightweight playhead and scroll offset; SwiftUI doesn't rebuild at 60 Hz.
private struct FollowScrollView<Content: View>: UIViewControllerRepresentable {
    let audio: PlinkaAudio
    let metrics: StaffMetrics
    @ViewBuilder let content: () -> Content

    func makeUIViewController(context: Context) -> FollowController<Content> {
        FollowController(audio: audio, metrics: metrics, content: content())
    }
    func updateUIViewController(_ controller: FollowController<Content>, context: Context) {
        controller.metrics = metrics
        controller.host.rootView = content()
        controller.view.setNeedsLayout()
    }
    static func dismantleUIViewController(_ controller: FollowController<Content>, coordinator: ()) {
        controller.invalidate()
    }
}

@MainActor
private final class FrameTarget: NSObject {
    var callback: (() -> Void)?
    @objc func frame() { callback?() }
}

@MainActor
private final class FollowController<Content: View>: UIViewController, UIScrollViewDelegate {
    let audio: PlinkaAudio
    var metrics: StaffMetrics
    let host: UIHostingController<Content>
    private let scroll = UIScrollView()
    private let grid: StaffGridView
    private let playhead = UIView()
    private let marker = UIView()
    private let target = FrameTarget()
    private var link: CADisplayLink?
    private var wasPlaying = false

    init(audio: PlinkaAudio, metrics: StaffMetrics, content: Content) {
        self.audio = audio; self.metrics = metrics
        grid = StaffGridView(metrics: metrics)
        host = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(grid)
        scroll.delegate = self
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.showsHorizontalScrollIndicator = true
        scroll.alwaysBounceVertical = false
        scroll.isDirectionalLockEnabled = true
        scroll.delaysContentTouches = false
        view.addSubview(scroll)
        addChild(host)
        host.view.backgroundColor = .clear
        // This is a wide music canvas, not a screen-sized child safe area.
        host.safeAreaRegions = []
        scroll.addSubview(host.view)
        host.didMove(toParent: self)
        for item in [playhead, marker] {
            item.backgroundColor = UIColor(red: 0.13, green: 0.69, blue: 0.90, alpha: 1)
            item.isUserInteractionEnabled = false
            item.layer.cornerRadius = 2
            scroll.addSubview(item)
        }
        target.callback = { [weak self] in self?.advanceFrame() }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        grid.setNeedsDisplay()
        if link == nil {
            let display = CADisplayLink(target: target, selector: #selector(FrameTarget.frame))
            display.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            display.add(to: .main, forMode: .common)
            link = display
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        invalidate()
    }
    func invalidate() { link?.invalidate(); link = nil }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        grid.frame = view.bounds
        scroll.frame = view.bounds
        host.view.frame = CGRect(x: 0, y: 0, width: metrics.width, height: metrics.height)
        scroll.contentSize = host.view.frame.size
        grid.update(metrics: metrics, offset: scroll.contentOffset)
        advanceFrame()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        grid.update(metrics: metrics, offset: scrollView.contentOffset)
    }

    private func advanceFrame() {
        let playing = audio.isPlaying
        scroll.isScrollEnabled = !playing || audio.isPaused
        playhead.isHidden = !playing
        marker.isHidden = !playing
        guard playing else {
            if wasPlaying { scroll.setContentOffset(.zero, animated: false) }
            wasPlaying = false
            return
        }
        wasPlaying = true
        guard let step = audio.currentPlaybackStep() else { return }
        let x = metrics.x(step)
        playhead.frame = CGRect(x: x - 1.5, y: 25, width: 3, height: max(1, metrics.height - 38))
        marker.frame = CGRect(x: x - 5, y: 22, width: 10, height: 8)
        guard !audio.isPaused else { return }
        // Continuous movement begins when the playhead reaches 38% of the
        // viewport. Clamp at both ends; a loop resets directly to its first beat.
        let desired = max(0, min(metrics.width - scroll.bounds.width, x - scroll.bounds.width * 0.38))
        scroll.setContentOffset(CGPoint(x: desired, y: 0), animated: false)
    }
}

#if DEBUG
/// Opt-in drawing regression: render short and long sheets at multiple scroll
/// positions using the actual grid view, including a hide/show and resize.
@MainActor
enum StaffGridSmokeCheck {
    static func runIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--check-staff-grid") else { return }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var passed = true
        for short in [false, true] {
            let size = short ? CGSize(width: 820, height: 240) : CGSize(width: 390, height: 600)
            let grid = StaffGridView(metrics: StaffMetrics(height: size.height, short: short, steps: 32))
            grid.frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
            grid.isHidden = true
            grid.frame = CGRect(origin: .zero, size: size)
            grid.isHidden = false
            for steps in [32, 256, Song.maximumSteps] {
                let metrics = StaffMetrics(height: size.height, short: short, steps: steps)
                for fraction: CGFloat in [0, 0.5, 1] {
                    let offset = max(0, metrics.width - size.width) * fraction
                    grid.update(metrics: metrics, offset: CGPoint(x: offset, y: 0))
                    grid.layer.displayIfNeeded()
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1
                    let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
                        grid.layer.render(in: renderer.cgContext)
                    }
                    // Missing-grid regression: every staff line must leave visible ink.
                    for row in stride(from: 0, through: 8, by: 2) {
                        let point = CGPoint(x: size.width / 2, y: metrics.top + CGFloat(row) * metrics.row)
                        passed = passed && pixelAlpha(image, at: point) > 100
                    }
                    // The dashed timing guide must also render away from staff lines.
                    let step = max(0, Int(ceil((offset + 10 - metrics.gutter) / metrics.cell)))
                    let point = CGPoint(x: metrics.x(Double(step)) - offset, y: 30)
                    passed = passed && pixelAlpha(image, at: point) > 2
                    if steps == Song.maximumSteps {
                        let name = "grid-\(short ? "landscape" : "portrait")-\(Int(fraction * 100)).png"
                        try? image.pngData()?.write(to: directory.appendingPathComponent(name))
                    }
                }
            }
        }
        let result = passed ? "PASS: grid visible for 32/256/1000 positions, start/middle/end, portrait/landscape, hide/show and resize" : "FAIL: missing grid pixels"
        try? result.write(to: directory.appendingPathComponent("grid-check.txt"), atomically: true, encoding: .utf8)
    }

    private static func pixelAlpha(_ image: UIImage, at point: CGPoint) -> UInt8 {
        guard let pixel = image.cgImage?.cropping(to: CGRect(x: floor(point.x), y: floor(point.y), width: 1, height: 1)) else { return 0 }
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8,
                                    bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return bytes[3]
    }
}
#endif

#if DEBUG
// Only runs in a disposable simulator when explicitly launched by the visual workflow.
// Drive existing views through their normal state; do not maintain duplicate mock layouts.
extension ComposerView {
    @MainActor private func runVisualTourIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--visual-tour") else { return }
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        func pause(_ seconds: Double = 1.5) async throws {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
        func capture(_ name: String, landscape: Bool) async throws {
            try await pause()
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  scene.interfaceOrientation.isLandscape == landscape else {
                throw NSError(domain: "VisualTourOrientation", code: 1)
            }
            let request = folder.appendingPathComponent("visual-ready.txt")
            let ack = folder.appendingPathComponent("visual-ack.txt")
            try? FileManager.default.removeItem(at: ack)
            try name.write(to: request, atomically: true, encoding: .utf8)
            for _ in 0..<180 {
                if (try? String(contentsOf: ack, encoding: .utf8)) == name {
                    try? FileManager.default.removeItem(at: request)
                    return
                }
                try await pause(0.5)
            }
            throw NSError(domain: "VisualTourCaptureTimeout", code: 2)
        }
        do {
            try await pause(2)
            store.openSample(SampleSong.all.first { $0.song.title == "Pluki Pop" }!)
            _ = store.saveSong(named: "A very long song name for checking saved project rows and the Save keyboard")
            store.openSample(SampleSong.all.first { $0.song.title == "Ode to Joy" }!)
            _ = store.saveSong(named: "Ode to Joy")
            store.openSample(SampleSong.all.first { $0.song.title == "Pluki Pop" }!)
            for landscape in [false, true] {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    throw NSError(domain: "VisualTourScene", code: 3)
                }
                visualStage = landscape ? "rotate-landscape" : "rotate-portrait"
                // XCTest rotates the simulated hardware, including iPad multitasking scenes.
                for _ in 0..<120 {
                    if scene.interfaceOrientation.isLandscape == landscape { break }
                    try await pause(0.5)
                }
                try await pause(2)
                let prefix = landscape ? "landscape" : "portrait"
                showHome = true
                try await capture(prefix + "-01-home", landscape: landscape)
                showHome = false
                try await capture(prefix + "-02-composer", landscape: landscape)
                showSongMenu = true
                try await capture(prefix + "-03-menu", landscape: landscape)
                showSongMenu = false
                showSongs = true
                try await capture(prefix + "-04-open", landscape: landscape)
                showSongs = false
                try await pause()
                saveTitle = "A very long song name for checking the Save keyboard"
                showSave = true
                try await capture(prefix + "-05-save-keyboard", landscape: landscape)
                showSave = false
                try await pause()
                showSamples = true
                try await capture(prefix + "-06-samples", landscape: landscape)
                showSamples = false
                try await pause()
                showSettings = true
                try await capture(prefix + "-07-settings", landscape: landscape)
                showSettings = false
                try await pause()
                showVideoExport = true
                // The export screen prepares a short real preview in visual-tour mode.
                for _ in 0..<120 {
                    if FileManager.default.fileExists(atPath: folder.appendingPathComponent("visual-preview-ready.txt").path) { break }
                    try await pause(0.5)
                }
                guard FileManager.default.fileExists(atPath: folder.appendingPathComponent("visual-preview-ready.txt").path) else {
                    throw NSError(domain: "VisualTourPreviewTimeout", code: 4)
                }
                try await capture(prefix + "-08-video-preview", landscape: landscape)
                showVideoExport = false
                try await pause()
                try? FileManager.default.removeItem(at: folder.appendingPathComponent("visual-preview-ready.txt"))
            }
            visualStage = "finished"
            try "PASS: captured 16 screens; human visual review required.".write(to: folder.appendingPathComponent("visual-result.txt"), atomically: true, encoding: .utf8)
        } catch {
            visualStage = "failed"
            try? "FAIL: \(error)".write(to: folder.appendingPathComponent("visual-result.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
