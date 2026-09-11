import SwiftUI

struct AgentInstructionsView: View {
    @EnvironmentObject var store: TicketStore
    @EnvironmentObject var settings: AppSettingsStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationSplitView {
            List {
                Section("Instructions") {
                    NavigationLink("Current agent instructions") {
                        instructionsPanel
                    }
                }

                Section("Active Agents by Ticket") {
                    ForEach(ticketsWithActiveAgents) { ticket in
                        NavigationLink {
                            ticketAgentsPanel(ticket)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ticket.key)
                                    .font(.headline)
                                Text(ticket.summary ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Agents")
        } detail: {
            instructionsPanel
        }
        .frame(minWidth: 720, minHeight: 500)
        .task {
            if store.lastRefreshed == nil {
                await store.refresh()
                store.startAutoRefresh()
            }
        }
    }

    private var ticketsWithActiveAgents: [Ticket] {
        store.sortedProjects
            .flatMap { store.ticketsByProject[$0] ?? [] }
            .filter { !store.activeSessions(for: $0).isEmpty }
    }

    private var instructionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Agent Instructions")
                    .font(.title2.bold())
                Spacer()
                Button("Edit in Settings") {
                    openWindow(id: "settings-window")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            ScrollView {
                Text(settings.agentInstructions)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text("These instructions are included in the initial prompt when a new ticket agent starts.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .navigationTitle("Instructions")
    }

    private func ticketAgentsPanel(_ ticket: Ticket) -> some View {
        let sessions = store.activeSessions(for: ticket)

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.key)
                    .font(.title2.bold())
                Text(ticket.summary ?? "")
                    .foregroundStyle(.secondary)
            }

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Active Agents")
                        .font(.headline)
                    Text("No open Copilot sessions are linked to this ticket.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(sessions) { session in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(session.name ?? session.id)
                                .font(.headline)
                            Spacer()
                            Text(session.activityText)
                                .font(.caption.bold())
                                .foregroundStyle(session.working ? .green : .secondary)
                        }

                        if let progress = session.progressText {
                            Text(progress)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let cwd = session.cwd {
                            Text(cwd)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        HStack {
                            if let updatedAt = session.updatedAt {
                                Text("Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Resume") {
                                TerminalLauncher.resumeSession(id: session.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .navigationTitle(ticket.key)
    }
}
