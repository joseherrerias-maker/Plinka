import SwiftUI

@main
struct PlinkaApp: App {
    var body: some Scene {
        WindowGroup {
            ComposerView()
                .task {
                    #if DEBUG
                    await VideoExportSmokeCheck.runIfRequested()
                    #endif
                }
        }
    }
}
