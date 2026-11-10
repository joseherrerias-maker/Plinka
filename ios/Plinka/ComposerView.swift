import SwiftUI
import UIKit
import StoreKit
import CoreText
import UniformTypeIdentifiers

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
    @State private var confirmClear = false
    @State private var showSongMenu = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview
    @State private var parentCheck = false
    @State private var parentApproved = false
    @State private var showSettings = false
    @State private var settingsPath: [SettingsRoute] = []
    @State private var showSongs = false
    @State private var showSamples = false
    @State private var showImport = false
    @State private var openImportAfterSettingsDismiss = false
    @State private var openExportAfterSettingsDismiss = false
    @State private var showProjectExport = false
    @State private var projectExportDocument: PlukiProjectDocument?
    @State private var projectExportFilename = "Pluki Project"
    @State private var projectExportError: String?
    @State private var importedSong: Song?
    @State private var confirmImport = false
    @State private var importError: String?
    @State private var showSave = false
    @State private var showRename = false
    @State private var renameTitle = ""
    @FocusState private var renameFocused: Bool
    @State private var showVideoExport = false
    @State private var saveTitle = ""
    @FocusState private var saveNameFocused: Bool
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
            if scenePhase == .active {
                ReviewMilestone.recordDay()
                if showHome { audio.startHomeTheme() }
            }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--parent-keypad-check") {
                store.openSample(SampleSong.all[0])
                showHome = false
                showVideoExport = true
            }
            if ProcessInfo.processInfo.arguments.contains("--editor-check") {
                store.openSample(SampleSong.all[0])
                showHome = false
            }
            await runVisualTourIfRequested()
            #endif
        }
        .onChange(of: showHome) { _, isHome in
            if isHome && scenePhase == .active {
                audio.startHomeTheme()
            } else {
                audio.stopHomeTheme()
            }
        }
        .fullScreenCover(isPresented: $showRename, onDismiss: { renameFocused = false }) { renameSongSheet }
        .sheet(isPresented: $showSettings, onDismiss: {
            settingsPath = []
            // Present Files after dismissing the parent sheet, never over it.
            if openImportAfterSettingsDismiss {
                openImportAfterSettingsDismiss = false
                if scenePhase == .active { showImport = true }
            } else if openExportAfterSettingsDismiss {
                openExportAfterSettingsDismiss = false
                if scenePhase == .active { showProjectExport = true }
            }
        }) { settings }
        .sheet(isPresented: $showSongs) { savedSongsView }
        .sheet(isPresented: $showSamples) { samplesView }
        .fileExporter(isPresented: $showProjectExport,
                      document: projectExportDocument,
                      contentType: PlukiProjectDocument.contentType,
                      defaultFilename: projectExportFilename) { result in
            if case .failure(let error) = result,
               (error as NSError).code != NSUserCancelledError {
                projectExportError = error.localizedDescription
            }
            projectExportDocument = nil
        }
        .fileImporter(isPresented: $showImport,
                      allowedContentTypes: [UTType(importedAs: "com.pebblesoftapps.pluki.song"), .json],
                      allowsMultipleSelection: false) { result in
            receiveSongFile(result)
        }
        .alert("Import song?", isPresented: $confirmImport) {
            Button("Import and open") {
                if let song = importedSong, store.importSong(song) {
                    audio.stop()
                    showHome = false
                }
                importedSong = nil
            }
            Button("Cancel", role: .cancel) { importedSong = nil }
        } message: {
            Text("Open \(importedSong?.title ?? "this song") as a new saved song? Any unsaved work will be kept as a separate saved copy.")
        }
        .alert("Could not import song", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK") { importError = nil }
        } message: { Text(importError ?? "") }
        .alert("Could not export project", isPresented: Binding(get: { projectExportError != nil },
                                                                 set: { if !$0 { projectExportError = nil } })) {
            Button("OK") { projectExportError = nil }
        } message: { Text(projectExportError ?? "") }

        .sheet(isPresented: $showVideoExport) { SongVideoExportView(song: store.song) }
        .fullScreenCover(isPresented: $showSave, onDismiss: { saveNameFocused = false }) { saveSongSheet }
        .alert("Saved songs", isPresented: Binding(get: { store.libraryError != nil }, set: { if !$0 { store.libraryError = nil } })) {
            Button("OK") { store.libraryError = nil }
        } message: { Text(store.libraryError ?? "") }
        .alert("Clear all notes?", isPresented: $confirmClear) {
            Button("Clear notes", role: .destructive) {
                audio.stop()
                store.clear()
                dismissSongMenu()
            }
            Button("Cancel", role: .cancel) { dismissSongMenu() }
        } message: {
            Text("This will remove every note from the current song.")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                ReviewMilestone.recordDay()
                if showHome { audio.startHomeTheme() }
            } else {
                audio.stopHomeTheme(fade: false)
            }
            if phase == .background {
                audio.pause()
                parentApproved = false
                openImportAfterSettingsDismiss = false
                openExportAfterSettingsDismiss = false
                settingsPath.removeAll()
            }
        }
    }

    private func receiveSongFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            // Read at most the limit plus one byte; do not trust the file's declared size.
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: PlukiSongFile.maximumBytes + 1) ?? Data()
            importedSong = try PlukiSongFile.decode(data)
            confirmImport = true
        } catch {
            importedSong = nil
            if (error as NSError).code != NSUserCancelledError {
                importError = error.localizedDescription
            }
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
                } header: {
                    Text("Song name")
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
        .interactiveDismissDisabled()
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
                } header: {
                    Text("Song name")
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
        .interactiveDismissDisabled()
    }

    private func finishSavingSong() {
        _ = store.saveSong(named: saveTitle)
        saveNameFocused = false
        showSave = false
    }

    private var composerContent: some View {
        GeometryReader { geometry in
            // Medium-width, near-square windows can use the compact controls and
            // beat spacing while giving their extra height to the score.
            let size = geometry.size
            let square = (580..<900).contains(size.width) && size.height >= 500
                && size.height <= size.width * 1.25
            let short = size.height < 500 || square
            let narrow = geometry.size.width < (short ? 780 : 900)
            // Small iPhone landscape has enough width for one toolbar row but
            // not enough height for the old stacked toolbar and nine pitches.
            let compactLandscape = size.height < 500 && size.width >= 540
            let padding: CGFloat = short ? 8 : 16
            let gap: CGFloat = short ? 8 : 12
            let toolbar: CGFloat = compactLandscape ? 52 : (narrow ? 108 : (short ? 52 : 72))
            let tray: CGFloat = short ? 94 : 140
            let staffHeight = max(100, geometry.size.height - 2 * padding - 2 * gap - toolbar - tray)
            VStack(spacing: gap) {
                toolbarView(narrow: narrow, short: short,
                            iconOnlyBrand: geometry.size.width < 400,
                            compactLandscape: compactLandscape)
                    .frame(height: toolbar)
                StaffView(store: store, audio: audio, height: staffHeight, short: short,
                          compactPhone: size.width < 440 && !short)
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
                if size.height < 500 && size.width >= 540 {
                    HStack(alignment: .top, spacing: 14) {
                        homeBrand.frame(maxWidth: 200)
                        homeMenu.frame(maxWidth: 340)
                    }
                } else {
                    VStack(spacing: 24) {
                        homeBrand
                        homeMenu
                    }
                }
            }
            .padding(size.height < 500 ? 12 : 24)
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
            Button {
                if store.hasMeaningfulDraft { showHome = false }
                else { startNewSong() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: store.hasMeaningfulDraft ? "play.fill" : "music.note")
                        .font(.system(size: 26, weight: .bold))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.20), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.hasMeaningfulDraft ? "Continue song" : "Make music")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text(store.hasMeaningfulDraft ? "Pick up your melody" : "Create your own melody")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .opacity(0.9)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.white)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(PlukiStyle.green.gradient, in: RoundedRectangle(cornerRadius: 20))
                .contentShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home-primary-action")
            if store.hasMeaningfulDraft {
                homeSecondaryRow("New song", icon: "plus.circle") { startNewSong() }
            }
            Divider().padding(.horizontal, 8)
            homeSecondaryRow("Open song", icon: "folder") {
                audio.stop(); showSongs = true
            }
            homeSecondaryRow("Samples", icon: "music.note.list") {
                audio.stop(); showSamples = true
            }
            homeSecondaryRow("Help & About", icon: "info.circle") { showSettings = true }
        }
        .padding(12)
        .frame(maxWidth: 340)
        .background(PlukiStyle.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.9), lineWidth: 2))
        .shadow(color: PlukiStyle.ink.opacity(0.15), radius: 14, y: 6)
    }

    private func homeSecondaryRow(_ title: String, icon: String,
                                  action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(PlukiStyle.blue)
                    .frame(width: 44, height: 44)
                Text(title)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(PlukiStyle.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 50)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
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
            startNewSong()
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
            songMenuRow("Restart playback", icon: "backward.end.fill", color: PlukiStyle.blue) {
                audio.stop(); audio.start(store.song)
            }
            .disabled(store.song.notes.isEmpty)
            // Keep the menu mounted while presenting the system confirmation:
            // dismissing the presenting surface first dropped alerts on iPhone SE.
            songMenuRow("Clear all notes", icon: "trash", color: .red, dismissFirst: false) {
                confirmClear = true
            }
            .disabled(audio.isPlaying || store.song.notes.isEmpty)
            songMenuRow("Export video", icon: "video.fill", color: .pink) {
                audio.stop(); showVideoExport = true
            }
            .disabled(store.song.notes.isEmpty)
        }
        songMenuRow("Samples", icon: "music.note.list", color: .purple) {
            audio.stop(); showSamples = true
        }
        Divider().padding(.horizontal, 12)
        songMenuRow("Help & About", icon: "info.circle.fill", color: PlukiStyle.blue) {
            showSettings = true
        }
    }

    private func startNewSong() {
        guard store.newSong() else { return }
        audio.stop()
        soundGroup = .instruments
        showHome = false
    }

    private func toolbarView(narrow: Bool, short: Bool,
                             iconOnlyBrand: Bool, compactLandscape: Bool) -> some View {
        Group {
            if compactLandscape {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(PlukiStyle.green)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                        .accessibilityLabel("Pluki")
                    Spacer(minLength: 0)
                    transport(showRestart: false)
                    editButtons
                    tempo(compact: true).frame(width: 98)
                }
            } else if narrow {
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
                        transport()
                        tempo(compact: true)
                    }
                }
            } else {
                HStack(spacing: short ? 8 : 18) {
                    wordmark(small: short)
                    Spacer(minLength: 0)
                    transport()
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

    private func transport(showRestart: Bool = true) -> some View {
        HStack(spacing: 6) {
            if showRestart {
                tool("backward.end.fill", title: "Restart", disabled: store.song.notes.isEmpty) {
                    audio.stop(); audio.start(store.song)
                }
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
                             dismissFirst: Bool = true,
                             action: @escaping () -> Void) -> some View {
        Button {
            if dismissFirst { dismissSongMenu() }
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
        guard store.openSample(sample) else {
            showSamples = false // Reveal the recovery failure alert without replacing music.
            return
        }
        audio.stop()
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
        guard store.openSong(saved) else {
            showSongs = false // Leave the original song open and surface the error.
            return
        }
        audio.stop()
        showHome = false
        showSongs = false
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
                    Button { openSavedSong(saved) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(saved.song.title).font(.headline)
                            Text("\(saved.song.notes.count) notes · \(Int(saved.song.tempo)) BPM")
                                .font(.subheadline).foregroundStyle(.secondary)
                            if saved.isRecovery == true {
                                Label("Recovered draft", systemImage: "arrow.uturn.backward.circle")
                                    .font(.caption.bold()).foregroundStyle(PlukiStyle.blue)
                            }
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

    private enum SettingsRoute: Hashable { case contact, parents }

    private var settings: some View {
        NavigationStack(path: $settingsPath) {
            Form {
                Section("Help") {
                    NavigationLink { PlukiHelpView() } label: {
                        Label("How to play & help", systemImage: "questionmark.circle.fill")
                    }
                    NavigationLink(value: SettingsRoute.contact) {
                        Label("Contact & website", systemImage: "envelope.fill")
                    }
                }
                if let error = audio.audioError { Section { Text(error).foregroundStyle(.red) } }
                Section {
                    Button { parentApproved = false; parentCheck = true } label: {
                        Label("For parents", systemImage: "person.2.fill")
                    }
                }
                Section("About Pluki") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Developed by").font(.caption).foregroundStyle(.secondary)
                        Image("PebblesoftLogo")
                            .resizable().scaledToFit()
                            .frame(maxWidth: 240, maxHeight: 110)
                            .accessibilityLabel("Pebblesoft Apps")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .contact: PlukiContactView()
                case .parents:
                    List {
                        Text("Songs stay on this device. You can export a song as a video from the song menu.")
                        Section {
                            Button {
                                audio.stop()
                                do {
                                    projectExportDocument = try PlukiProjectDocument(song: store.song)
                                    projectExportFilename = PlukiProjectDocument.filename(for: store.song.title)
                                    openExportAfterSettingsDismiss = true
                                    showSettings = false
                                } catch {
                                    projectExportError = error.localizedDescription
                                }
                            } label: {
                                Label("Export Pluki Project", systemImage: "square.and.arrow.up")
                            }
                            .disabled(store.song.notes.isEmpty)
                            Button {
                                audio.stop()
                                openImportAfterSettingsDismiss = true
                                showSettings = false
                            } label: {
                                Label("Import Pluki Project", systemImage: "square.and.arrow.down")
                            }
                        } header: {
                            Text("Save & Transfer Projects")
                        } footer: {
                            Text("Save an editable .pluki project to Files or share it with another device. To export a saved song, open it first. An import creates a separate saved copy.")
                        }
                        NavigationLink("Privacy policy") { PlukiPrivacyView() }
                    }
                    .navigationTitle("For parents")
                    .task {
                        try? await Task.sleep(for: .seconds(1))
                        guard !Task.isCancelled, scenePhase == .active,
                              settingsPath.last == .parents,
                              ReviewMilestone.takeRequest() else { return }
                        requestReview()
                    }
                }
            }
            .sheet(isPresented: $parentCheck, onDismiss: {
                if parentApproved && scenePhase == .active { settingsPath.append(.parents) }
                parentApproved = false
            }) {
                PlukiParentGate(instruction: "To open the parent area, enter the four numbers in order.") {
                    parentApproved = true
                }
            }
            .navigationTitle("Help & About")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSettings = false } } }
        }
        .presentationDetents([.medium, .large])
    }
}

// One self-contained editable project file, without cloud accounts or backend.
private struct PlukiProjectDocument: FileDocument {
    static let contentType = UTType(exportedAs: "com.pebblesoftapps.pluki.song", conformingTo: .json)
    static var readableContentTypes: [UTType] { [contentType] }
    static var writableContentTypes: [UTType] { [contentType] }
    let data: Data

    init(song: Song) throws {
        data = try PlukiSongFile.encode(song)
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = try PlukiSongFile.encode(PlukiSongFile.decode(contents))
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }

    static func filename(for title: String) -> String {
        let sanitized = title.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String((sanitized.isEmpty ? "Pluki Project" : sanitized).prefix(70))
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

private struct PlayingSticker: View {
    let instrument: Instrument
    let active: Bool
    let reduceMotion: Bool
    @State private var bouncing = false

    var body: some View {
        InstrumentSticker(instrument: instrument)
            .scaleEffect(bouncing ? 1.10 : 1.0)
            .task(id: active && !reduceMotion) {
                guard active, !reduceMotion else { bouncing = false; return }
                withAnimation(.easeOut(duration: 0.08)) { bouncing = true }
                try? await Task.sleep(for: .milliseconds(95))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.11)) { bouncing = false }
            }
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
    let compactPhone: Bool

    var body: some View {
        let metrics = StaffMetrics(height: height, short: short,
                                   steps: store.song.stepCount, compactPhone: compactPhone)
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
    let compactPhone: Bool
    var top: CGFloat { short ? 32 : 60 }
    var bottom: CGFloat { short ? 28 : 48 }
    var row: CGFloat { max(5, (height - top - bottom) / 8) }
    var cell: CGFloat { short ? 60 : 84 }
    var gutter: CGFloat { short ? 60 : (compactPhone ? 64 : 90) }
    var width: CGFloat { gutter + CGFloat(steps) * cell + 16 }
    var sticker: CGFloat { min(short ? 57.6 : 93.6, row * (short ? 4.08 : 3.12)) }
    func x(_ step: Double) -> CGFloat { gutter + (CGFloat(step) + 0.5) * cell }
}

private struct StaffContent: View {
    @ObservedObject var store: SongStore
    @ObservedObject var audio: PlinkaAudio
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                let active = audio.isPlaying && !audio.isPaused && Int(audio.playheadStep ?? -1) == note.step
                PlayingSticker(instrument: note.instrument, active: active, reduceMotion: reduceMotion)
                    .frame(width: metrics.sticker, height: metrics.sticker)
                    .overlay {
                        if store.selectedID == note.id && !audio.isPlaying {
                            RoundedRectangle(cornerRadius: 12).strokeBorder(PlukiStyle.blue, lineWidth: 2).padding(-2)
                        }
                    }
                    // Limit hit targets to their beat cell even when artwork is larger.
                    .frame(width: max(44, metrics.cell - 4), height: max(44, metrics.sticker))
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
        controller.replaceMetrics(metrics)
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

    func replaceMetrics(_ new: StaffMetrics) {
        let old = metrics
        guard new != old else { return }
        let offset = scroll.contentOffset.x
        metrics = new
        guard offset > old.gutter, old.cell != new.cell, !audio.isPlaying else { return }
        let beat = (offset - old.gutter) / old.cell
        scroll.contentSize = CGSize(width: new.width, height: new.height)
        let x = min(new.gutter + beat * new.cell, max(0, new.width - scroll.bounds.width))
        scroll.setContentOffset(CGPoint(x: x, y: 0), animated: false)
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
        // Layout math guard for nine complete playable rows on compact phones.
        // Rendering and actual hit testing still require the device matrix.
        for metrics in [
            StaffMetrics(height: 142, short: true, steps: 32, compactPhone: false),
            StaffMetrics(height: 264, short: false, steps: 32, compactPhone: true),
            StaffMetrics(height: 600, short: false, steps: 32, compactPhone: false)
        ] {
            passed = passed && metrics.cell >= 44
            for pitch in 0...8 {
                let center = metrics.top + CGFloat(pitch) * metrics.row
                passed = passed && center - metrics.sticker / 2 >= 0
                passed = passed && center + metrics.sticker / 2 <= metrics.height
            }
        }
        for short in [false, true] {
            let size = short ? CGSize(width: 820, height: 240) : CGSize(width: 390, height: 600)
            let grid = StaffGridView(metrics: StaffMetrics(height: size.height, short: short, steps: 32, compactPhone: !short))
            grid.frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
            grid.isHidden = true
            grid.frame = CGRect(origin: .zero, size: size)
            grid.isHidden = false
            for steps in [32, 256, Song.maximumSteps] {
                let metrics = StaffMetrics(height: size.height, short: short, steps: steps, compactPhone: !short)
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
                renameTitle = "A very long song name for checking the Rename keyboard"
                showRename = true
                try await capture(prefix + "-03b-rename-keyboard", landscape: landscape)
                showRename = false
                try await pause()
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
                settingsPath = [.contact]
                try await capture(prefix + "-07b-contact", landscape: landscape)
                settingsPath = []
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
            try "PASS: captured 20 screens; human visual review required.".write(to: folder.appendingPathComponent("visual-result.txt"), atomically: true, encoding: .utf8)
        } catch {
            visualStage = "failed"
            try? "FAIL: \(error)".write(to: folder.appendingPathComponent("visual-result.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
