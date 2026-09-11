import Foundation

/// Reads local Copilot CLI session state from ~/.copilot/session-state/ and
/// ~/.copilot/open-sessions-state.json. No network access; everything is local files.
final class SessionStateService {
    private struct OpenSessionState {
        let working: Bool
    }

    private var stateRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".copilot/session-state")
    }

    private var openSessionsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".copilot/open-sessions-state.json")
    }

    func fetchAllSessions() -> [CopilotSession] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: stateRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let openStates = loadOpenSessionStates()

        return entries.compactMap { dir -> CopilotSession? in
            guard fm.fileExists(atPath: dir.appendingPathComponent("workspace.yaml").path) else {
                return nil
            }
            return parseSession(at: dir, openStates: openStates)
        }
    }

    // MARK: - workspace.yaml (minimal flow-style YAML: "key: value" per line)

    private func parseSession(at dir: URL, openStates: [String: OpenSessionState]) -> CopilotSession? {
        let yamlURL = dir.appendingPathComponent("workspace.yaml")
        guard let text = try? String(contentsOf: yamlURL, encoding: .utf8) else { return nil }

        var fields: [String: String] = [:]
        for line in text.split(separator: "\n") {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = line[line.startIndex..<colonIndex].trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            fields[key] = value
        }

        guard let id = fields["id"] else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let updatedAt = fields["updated_at"].flatMap { formatter.date(from: $0) }

        let (done, total) = todoCounts(dbPath: dir.appendingPathComponent("session.db").path)

        return CopilotSession(
            id: id,
            name: fields["name"],
            cwd: fields["cwd"],
            updatedAt: updatedAt,
            isOpen: openStates[id] != nil,
            working: openStates[id]?.working ?? false,
            todosDone: done,
            todosTotal: total
        )
    }

    // MARK: - open-sessions-state.json

    private func loadOpenSessionStates() -> [String: OpenSessionState] {
        guard let data = try? Data(contentsOf: openSessionsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        else {
            return [:]
        }
        var result: [String: OpenSessionState] = [:]
        for (id, entry) in json {
            result[id] = OpenSessionState(working: entry["working"] as? Bool ?? false)
        }
        return result
    }

    // MARK: - session.db todos progress (via sqlite3 CLI, no external dependency)

    private func todoCounts(dbPath: String) -> (done: Int, total: Int) {
        guard FileManager.default.fileExists(atPath: dbPath) else { return (0, 0) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [dbPath, "SELECT status, COUNT(*) FROM todos GROUP BY status;"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (0, 0)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return (0, 0) }

        var done = 0
        var total = 0
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "|")
            guard parts.count == 2, let count = Int(parts[1]) else { continue }
            total += count
            if parts[0] == "done" { done += count }
        }
        return (done, total)
    }
}
