import Foundation
import SwiftUI

/// Ties together Jira tickets and local Copilot sessions, refreshing on a timer.
@MainActor
final class TicketStore: ObservableObject {
    @Published var ticketsByProject: [String: [Ticket]] = [:]
    @Published var sessions: [CopilotSession] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastRefreshed: Date?

    /// JQL scope: tickets assigned to the current user that aren't resolved.
    var jql = "assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC"

    private let jiraService = JiraService()
    private let sessionService = SessionStateService()
    private var refreshTask: Task<Void, Never>?

    func startAutoRefresh(interval: TimeInterval = 300) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        sessions = sessionService.fetchAllSessions()

        do {
            let tickets = try await jiraService.fetchMyTickets(jql: jql)
            ticketsByProject = Dictionary(grouping: tickets, by: \.project)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        lastRefreshed = Date()
    }

    /// Finds a local session whose name references the given ticket key, if any.
    func session(for ticket: Ticket) -> CopilotSession? {
        sessions(for: ticket).first
    }

    /// Finds all local sessions whose names reference the given ticket key.
    func sessions(for ticket: Ticket) -> [CopilotSession] {
        sessions
            .filter { $0.matches(ticketKey: ticket.key) }
            .sorted { lhs, rhs in
                if lhs.isOpen != rhs.isOpen { return lhs.isOpen && !rhs.isOpen }
                return (lhs.updatedAt ?? .distantPast) > (rhs.updatedAt ?? .distantPast)
            }
    }

    /// Active sessions are currently listed in Copilot's open session state.
    func activeSessions(for ticket: Ticket) -> [CopilotSession] {
        sessions(for: ticket).filter(\.isOpen)
    }

    var sortedProjects: [String] {
        ticketsByProject.keys.sorted()
    }
}
