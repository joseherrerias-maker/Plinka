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
                tip("Save and open", icon: "folder.fill", detail: "Use the song menu to Save song. Open song lists your saved projects and lets you delete them. Songs are kept on this device; saving under a different name makes a new copy.")
                tip("Try a sample", icon: "music.note.list", detail: "Samples open immediately. Save your current work first if you want to keep it. A saved sample becomes your own editable copy.")
                tip("Make a video", icon: "video.fill", detail: "Choose Export video in the song menu, pick a format and create your video. A grown-up can save it to Photos after a parent check. Keep Pluki open while the video is being made.")
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

/// A fresh, local challenge for one parent action; never persists an unlocked state.
struct PlukiParentGate: View {
    let onApproved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var approval = ParentApproval()
    @State private var answer = ""
    @State private var incorrect = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 48)).foregroundStyle(.green)
                    Text("For a grown-up")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("To save this video to Photos, enter these four numbers in reverse order.")
                    Text(approval.prompt).font(.system(.title3, design: .rounded, weight: .bold))
                    TextField("Four digits", text: $answer)
                        .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Four digits in reverse order")
                        .onChange(of: answer) { _, value in
                            answer = String(value.filter { $0 >= "0" && $0 <= "9" }.prefix(4))
                        }
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
