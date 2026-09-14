import Foundation
import AppKit

struct AppSettings {
    var jiraToken: String
    var agentInstructions: String
    var projectDirectories: [String: String]
}

enum AppSettingsError: Error, LocalizedError {
    case invalidToken

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Enter a Jira token before saving."
        }
    }
}

final class AppSettingsService {
    static let defaultAgentInstructions = """
    Work on the Jira ticket end to end. Read the ticket context, identify the acceptance criteria, make focused code changes, validate them with the smallest relevant checks, and report the outcome clearly in English.
    """

    private let agentInstructionsKey = "agentInstructions"
    private let projectDirectoriesKey = "projectDirectories"

    private var jiraEnvURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/jira/.env")
    }

    func load() -> AppSettings {
        let savedDirs = UserDefaults.standard.dictionary(forKey: projectDirectoriesKey) as? [String: String] ?? [:]
        return AppSettings(
            jiraToken: loadJiraToken() ?? "",
            agentInstructions: UserDefaults.standard.string(forKey: agentInstructionsKey) ?? Self.defaultAgentInstructions,
            projectDirectories: savedDirs
        )
    }

    func save(_ settings: AppSettings) throws {
        try saveJiraToken(settings.jiraToken)
        UserDefaults.standard.set(settings.agentInstructions, forKey: agentInstructionsKey)
        UserDefaults.standard.set(settings.projectDirectories, forKey: projectDirectoriesKey)
    }

    static func chooseDirectory(initialPath: String? = nil, message: String = "Select repository directory") -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.message = message

        if let initialPath, FileManager.default.fileExists(atPath: initialPath) {
            panel.directoryURL = URL(fileURLWithPath: initialPath)
        } else {
            panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/GitHub")
        }

        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            return url.path
        }
        return nil
    }

    private func loadJiraToken() -> String? {
        guard let text = try? String(contentsOf: jiraEnvURL, encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("JIRA_PAT=") else { continue }
            return unquote(String(trimmed.dropFirst("JIRA_PAT=".count)))
        }
        return nil
    }

    private func saveJiraToken(_ token: String) throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else { throw AppSettingsError.invalidToken }

        let fm = FileManager.default
        try fm.createDirectory(at: jiraEnvURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        var lines: [String] = []
        if let existing = try? String(contentsOf: jiraEnvURL, encoding: .utf8) {
            lines = existing.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        }

        let newLine = "JIRA_PAT=\(quote(trimmedToken))"
        if let index = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("JIRA_PAT=") }) {
            lines[index] = newLine
        } else {
            lines.append(newLine)
        }

        try lines.joined(separator: "\n").write(to: jiraEnvURL, atomically: true, encoding: .utf8)
    }

    private func quote(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private func unquote(_ value: String) -> String {
        var result = value.trimmingCharacters(in: .whitespaces)
        if result.hasPrefix("\""), result.hasSuffix("\""), result.count >= 2 {
            result = String(result.dropFirst().dropLast())
            result = result.replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
        }
        return result
    }
}
