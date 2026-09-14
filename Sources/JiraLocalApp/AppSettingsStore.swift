import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var jiraToken: String
    @Published var agentInstructions: String
    @Published var projectDirectories: [String: String]
    @Published var statusMessage: String?

    private let service = AppSettingsService()

    init() {
        let settings = service.load()
        jiraToken = settings.jiraToken
        agentInstructions = settings.agentInstructions
        projectDirectories = settings.projectDirectories
    }

    func save() throws {
        try service.save(AppSettings(
            jiraToken: jiraToken,
            agentInstructions: agentInstructions,
            projectDirectories: projectDirectories
        ))
        statusMessage = "Settings saved."
    }

    var hasJiraToken: Bool {
        !jiraToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func directory(for ticket: Ticket) -> String? {
        if let dir = projectDirectories[ticket.project], FileManager.default.fileExists(atPath: dir) {
            return dir
        }
        return nil
    }

    func setDirectory(_ path: String, for project: String) {
        projectDirectories[project] = path
        try? save()
    }

    func removeDirectory(for project: String) {
        projectDirectories.removeValue(forKey: project)
        try? save()
    }

    func promptAndSetDirectory(for ticket: Ticket) -> String? {
        let initialPath = directory(for: ticket)
        if let selected = AppSettingsService.chooseDirectory(
            initialPath: initialPath,
            message: "Select repository folder for project \(ticket.project) (\(ticket.key))"
        ) {
            setDirectory(selected, for: ticket.project)
            return selected
        }
        return nil
    }

    func browseDirectory(for project: String) {
        let initial = projectDirectories[project]
        if let selected = AppSettingsService.chooseDirectory(
            initialPath: initial,
            message: "Select repository folder for project \(project)"
        ) {
            setDirectory(selected, for: project)
        }
    }

    func startSession(for ticket: Ticket, existingSession: CopilotSession? = nil) {
        var dir: String? = existingSession?.cwd

        if let sessionCwd = dir, FileManager.default.fileExists(atPath: sessionCwd) {
            // Use existing session directory
        } else if let savedDir = directory(for: ticket) {
            dir = savedDir
        } else {
            dir = promptAndSetDirectory(for: ticket)
        }

        guard let targetDir = dir, FileManager.default.fileExists(atPath: targetDir) else {
            return
        }

        TerminalLauncher.startSession(forTicket: ticket, in: targetDir, instructions: agentInstructions)
    }
}
