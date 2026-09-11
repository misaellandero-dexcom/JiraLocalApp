import Foundation

/// Runs the global read-only `jira` CLI (~/.local/bin/jira) and parses its JSON output.
/// The CLI loads JIRA_PAT from ~/.config/jira/.env.
enum JiraServiceError: Error, LocalizedError {
    case cliNotFound
    case processFailed(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "The 'jira' CLI was not found at ~/.local/bin/jira. Check the Jira skill installation."
        case .processFailed(let message):
            return "jira CLI failed: \(message)"
        case .decodingFailed(let error):
            return "Could not parse the jira response: \(error.localizedDescription)"
        }
    }
}

final class JiraService {
    /// Resolve the CLI path directly rather than relying on PATH, since GUI apps
    /// launched from Finder/LaunchAgent don't inherit the user's shell PATH.
    private var cliURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/jira")
    }

    func fetchMyTickets(jql: String, maxResults: Int = 50) async throws -> [Ticket] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: cliURL.path) else {
            throw JiraServiceError.cliNotFound
        }

        let process = Process()
        process.executableURL = cliURL
        process.arguments = ["search", jql, "--max", String(maxResults)]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let message = String(data: errData, encoding: .utf8) ?? "unknown error"
            throw JiraServiceError.processFailed(message)
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(SearchResponse.self, from: outData)
            return response.issues
        } catch {
            throw JiraServiceError.decodingFailed(error)
        }
    }
}
