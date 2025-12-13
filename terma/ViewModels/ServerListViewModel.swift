import Foundation
import SwiftUI

@Observable
@MainActor
final class ServerListViewModel {
    var profiles: [ServerProfile] = []
    var selectedProfile: ServerProfile?
    var showingAddSheet = false
    var showingEditSheet = false
    var profileToEdit: ServerProfile?
    var showingTerminal = false
    var activeSession: TerminalSession?

    private let storage = ProfileStorage.shared

    func loadProfiles() {
        profiles = storage.fetchProfiles()
    }

    func deleteProfile(_ profile: ServerProfile) {
        storage.deleteProfile(profile)
        loadProfiles()
    }

    func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            storage.deleteProfile(profiles[index])
        }
        loadProfiles()
    }

    func connectToProfile(_ profile: ServerProfile) {
        storage.updateLastConnected(profile)
        activeSession = TerminalSession(profile: profile)
        showingTerminal = true
        loadProfiles()
    }

    func editProfile(_ profile: ServerProfile) {
        profileToEdit = profile
        showingEditSheet = true
    }

    func addNewProfile() {
        profileToEdit = nil
        showingAddSheet = true
    }

    func onProfileSaved() {
        loadProfiles()
    }
}
