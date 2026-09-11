import Foundation

/// A local Copilot CLI session, read from ~/.copilot/session-state/<id>/workspace.yaml
/// plus the live "working" flag from ~/.copilot/open-sessions-state.json.
struct CopilotSession: Identifiable, Hashable {
    let id: String
    let name: String?
    let cwd: String?
    let updatedAt: Date?
    var isOpen: Bool
    var working: Bool
    var todosDone: Int
    var todosTotal: Int

    var activityText: String {
        if working { return "Working" }
        if isOpen { return "Open" }
        return "Saved"
    }

    var progressText: String? {
        guard todosTotal > 0 else { return nil }
        return "\(todosDone)/\(todosTotal) todos"
    }

    /// Whether this session's user-assigned name references the given ticket key,
    /// e.g. session named "RDS-1234: fix crash" matches ticket key "RDS-1234".
    func matches(ticketKey: String) -> Bool {
        guard let name else { return false }
        return name.range(of: ticketKey, options: .caseInsensitive) != nil
    }
}
