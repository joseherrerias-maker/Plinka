import SwiftUI

struct PlukiHelpView: View {
    var body: some View {
        List {
            Section("Make a little music") {
                tip("Choose a sound", icon: "pianokeys", detail: "Swipe through Instruments, Animals and Fun, or tap a category to jump there.")
                tip("Place and move", icon: "hand.tap.fill", detail: "Tap the sheet to add a sticker. Drag it up or down for pitch, or sideways for timing. The sheet grows as you add notes near its end, up to 500 numbered beats.")
                tip("Press play", icon: "play.fill", detail: "Follow your melody as it plays. Adjust the tempo or turn on Loop to hear it again.")
            }
            Section("Keep your creations") {
                tip("Name your song", icon: "pencil", detail: "Tap the title and pencil at the top of the song menu to rename your current song. Use Save song to keep it in your saved projects.")
                tip("Save and open", icon: "folder.fill", detail: "Use the song menu to Save song. Open song lists your saved projects and lets you delete them. Songs are kept on this device; saving under a different name makes a new copy.")
                tip("Try a sample", icon: "music.note.list", detail: "Samples open immediately. Save your current work first if you want to keep it. A saved sample becomes your own editable copy.")
                tip("Make a video", icon: "video.fill", detail: "Choose Export video in the song menu, pick a format and create your video. A grown-up completes a parent check when first enabling Photos saving. After permission is granted, videos save directly. Keep Pluki open while the video is being made.")
            }
            Section("Troubleshooting") {
                tip("No sound?", icon: "speaker.wave.2.fill", detail: "Turn up media volume and check whether audio is playing through Bluetooth headphones or a speaker. Stop the song and try Play again.")
                tip("Video will not save?", icon: "photo", detail: "Check available device storage. If Photos access was denied, a grown-up can allow Pluki to add to Photos in device Settings, then try again.")
                tip("Where are my songs?", icon: "music.note", detail: "Open song shows projects saved on this device. Continue song returns to the current draft. Deleting the app can remove its songs; a video is not an editable project backup.")
            }
        }
        .navigationTitle("How to play & help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tip(_ title: String, icon: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded)).foregroundStyle(.primary)
            Text(detail).font(.body).foregroundStyle(.secondary)
        }.padding(.vertical, 6)
    }
}

struct PlukiPrivacyView: View {
    private var policy: String {
        guard let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "txt"),
              let value = try? String(contentsOf: url, encoding: .utf8) else {
            return "Privacy information could not be loaded."
        }
        return value
    }
    var body: some View {
        ScrollView {
            Text(policy).frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled).padding(24)
        }
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Outgoing links require a fresh parent check; offline help and privacy stay available.
struct PlukiContactView: View {
    private enum Destination: String, Identifiable {
        case support, privacy, website, email
        var id: String { rawValue }
        var url: URL {
            switch self {
            case .support: return URL(string: "https://pebblesoftapps.com/pluki/support/")!
            case .privacy: return URL(string: "https://pebblesoftapps.com/pluki/privacy/")!
            case .website: return URL(string: "https://pebblesoftapps.com/")!
            case .email: return URL(string: "mailto:support@pebblesoftapps.com")!
            }
        }
        var instruction: String {
            self == .email
                ? "To open your email app, tap these four numbers on the number pad, in the order shown."
                : "To open the website, tap these four numbers on the number pad, in the order shown."
        }
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var pending: Destination?
    @State private var approved: Destination?
    @State private var openFailed = false

    var body: some View {
        List {
            Section {
                Text("A grown-up can contact us for help with pluki! Please do not include children's personal information.")
                Text(verbatim: "support@pebblesoftapps.com")
                    .font(.callout).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section("For grown-ups") {
                destinationButton("Email support", icon: "envelope", destination: .email)
                destinationButton("Support website", icon: "questionmark.circle", destination: .support)
                destinationButton("Privacy policy online", icon: "hand.raised", destination: .privacy)
                destinationButton("Pebblesoft Apps website", icon: "globe", destination: .website)
            }
        }
        .navigationTitle("Contact & website")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pending, onDismiss: openApprovedDestination) { destination in
            PlukiParentGate(instruction: destination.instruction) { approved = destination }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { approved = nil; pending = nil }
        }
        .alert("Could not open link", isPresented: $openFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check that a browser or email app is available. You can also contact support@pebblesoftapps.com.")
        }
    }

    private func destinationButton(_ title: String, icon: String, destination: Destination) -> some View {
        Button {
            approved = nil
            pending = destination
        } label: {
            Label(title, systemImage: icon)
        }
        .accessibilityHint("A parent check is required before leaving the app.")
    }

    private func openApprovedDestination() {
        guard let destination = approved else { return }
        approved = nil
        openURL(destination.url) { accepted in openFailed = !accepted }
    }
}

/// A fresh, local challenge for one parent action; never persists an unlocked state.
struct PlukiParentGate: View {
    var instruction = "To enable saving videos to Photos, tap these four numbers on the number pad, in the order shown."
    let onApproved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var approval = ParentApproval()
    @State private var answer = ""
    @State private var incorrect = false

    // Buttons avoid keyboard focus and text-field updates inside stacked sheets.
    // This is the same input path on iPhone and iPad, including external-keyboard devices.
    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(1...9, id: \.self) { digit in
                digitButton(digit)
            }
            Button { answer = "" } label: {
                Text("Clear").frame(maxWidth: .infinity, minHeight: 48)
            }
            .disabled(answer.isEmpty)
            digitButton(0)
            Button {
                if !answer.isEmpty { answer.removeLast() }
            } label: {
                Image(systemName: "delete.left")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .accessibilityLabel("Delete last digit")
            .disabled(answer.isEmpty)
        }
        .buttonStyle(.bordered)
        .tint(.primary)
    }

    private func digitButton(_ digit: Int) -> some View {
        Button {
            guard answer.count < 4 else { return }
            answer.append(contentsOf: String(digit))
        } label: {
            Text(String(digit))
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .accessibilityLabel(String(digit))
        .disabled(answer.count >= 4)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 48)).foregroundStyle(.green)
                    Text("For a grown-up")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(instruction)
                    Text(approval.prompt).font(.system(.title3, design: .rounded, weight: .bold))
                    Text(answer.isEmpty ? "— — — —" : answer.map(String.init).joined(separator: "  "))
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Entered digits")
                        .accessibilityValue(answer.isEmpty ? "None" : answer.map(String.init).joined(separator: ", "))
                    numberPad
                    if incorrect {
                        Text("Please try the new numbers above.").foregroundStyle(.secondary)
                    }
                    Button("Continue") {
                        guard approval.submit(answer) else {
                            answer = ""; incorrect = true
                            return
                        }
                        if approval.consume() {
                            onApproved()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(.green)
                    .disabled(answer.count != 4)
                }
                .multilineTextAlignment(.center)
                .padding(24).frame(maxWidth: 420).frame(maxWidth: .infinity)
            }
            .background(Color(red: 1, green: 0.98, blue: 0.93))
            .navigationTitle("Parent check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { approval.invalidate(); dismiss() }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { approval.invalidate(); dismiss() }
        }
    }
}
