import SwiftUI
import SwiftData

@main
struct termaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ProfileStorage.shared.modelContainer)
    }
}
