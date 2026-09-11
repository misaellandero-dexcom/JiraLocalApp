import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var jiraToken: String
    @Published var agentInstructions: String
    @Published var statusMessage: String?

    private let service = AppSettingsService()

    init() {
        let settings = service.load()
        jiraToken = settings.jiraToken
        agentInstructions = settings.agentInstructions
    }

    func save() throws {
        try service.save(AppSettings(jiraToken: jiraToken, agentInstructions: agentInstructions))
        statusMessage = "Settings saved."
    }

    var hasJiraToken: Bool {
        !jiraToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
