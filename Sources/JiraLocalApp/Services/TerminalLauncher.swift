import Foundation
import AppKit

/// Opens Terminal.app running Copilot CLI, either resuming an existing session
/// or starting a new one named after a ticket so it can be matched later.
enum TerminalLauncher {
    static func resumeSession(id: String) {
        let command = "copilot --resume=\(shellQuote(id))"
        runInTerminal(command)
    }

    /// Starts a brand-new Copilot session named after the ticket (e.g. "RDS-1234: Fix crash")
    /// so SessionStateService can link it back to the ticket on the next refresh.
    static func startSession(forTicket ticket: Ticket, in directory: String, instructions: String) {
        let safeName = "\(ticket.key): \(ticket.summary ?? "")"
        let prompt = """
        \(instructions.trimmingCharacters(in: .whitespacesAndNewlines))

        Jira ticket: \(ticket.key)
        Summary: \(ticket.summary ?? "")
        Jira URL: \(ticket.url)
        """
        let command = "cd \(shellQuote(directory)) && copilot --name=\(shellQuote(safeName)) -i \(shellQuote(prompt))"
        runInTerminal(command)
    }

    static func openTicketInBrowser(_ ticket: Ticket) {
        guard let url = URL(string: ticket.url) else { return }
        NSWorkspace.shared.open(url)
    }

    private static func runInTerminal(_ command: String) {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
