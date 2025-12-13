import Foundation
import SwiftData

@MainActor
final class ProfileStorage {
    static let shared = ProfileStorage()

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    private init() {
        do {
            let schema = Schema([ServerProfile.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    func fetchProfiles() -> [ServerProfile] {
        let descriptor = FetchDescriptor<ServerProfile>(
            sortBy: [SortDescriptor(\.lastConnectedAt, order: .reverse), SortDescriptor(\.name)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch profiles: \(error)")
            return []
        }
    }

    func addProfile(_ profile: ServerProfile) {
        modelContext.insert(profile)
        saveContext()
    }

    func deleteProfile(_ profile: ServerProfile) {
        try? KeychainService.shared.deleteAllCredentials(for: profile)
        modelContext.delete(profile)
        saveContext()
    }

    func updateLastConnected(_ profile: ServerProfile) {
        profile.lastConnectedAt = Date()
        saveContext()
    }

    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
