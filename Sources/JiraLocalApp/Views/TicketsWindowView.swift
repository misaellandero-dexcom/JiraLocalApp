import SwiftUI

/// Full-size resizable window showing all tickets grouped by project with
/// detailed session progress. Opened via the dashboard button in the
/// compact menu bar dropdown.
struct TicketsWindowView: View {
    @EnvironmentObject var store: TicketStore
    @EnvironmentObject var settings: AppSettingsStore
    @State private var selectedProject: String? = nil

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProject) {
                Label("All", systemImage: "tray.full")
                    .tag(nil as String?)

                ForEach(store.sortedProjects, id: \.self) { project in
                    HStack {
                        Label(project, systemImage: "folder")
                        Spacer()
                        Text("\((store.ticketsByProject[project] ?? []).count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(project as String?)
                }
            }
            .navigationTitle("Projects")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(projectsToShow, id: \.self) { project in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(project)
                                .font(.title3.bold())

                            ForEach(store.ticketsByProject[project] ?? []) { ticket in
                                TicketDetailRow(ticket: ticket, session: store.session(for: ticket))
                                Divider()
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(selectedProject ?? "My Tickets")
            .toolbar {
                ToolbarItem {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(store.isLoading)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .task {
            if store.lastRefreshed == nil {
                await store.refresh()
                store.startAutoRefresh()
            }
        }
    }

    private var projectsToShow: [String] {
        if let selectedProject {
            return [selectedProject]
        }
        return store.sortedProjects
    }
}

private struct TicketDetailRow: View {
    let ticket: Ticket
    let session: CopilotSession?
    @EnvironmentObject var store: TicketStore
    @EnvironmentObject var settings: AppSettingsStore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(session?.working == true ? Color.green : (session != nil ? Color.orange : Color.gray.opacity(0.4)))
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(ticket.key)  \(ticket.summary ?? "")")
                    .font(.system(size: 13, weight: .semibold))

                HStack(spacing: 8) {
                    if let status = ticket.status {
                        Text(status)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    if let type = ticket.issueType {
                        Text(type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let session {
                    if session.todosTotal > 0 {
                        ProgressView(value: Double(session.todosDone), total: Double(session.todosTotal))
                            .frame(maxWidth: 260)
                        Text("\(session.todosDone)/\(session.todosTotal) todos complete\(session.working ? " • working now" : "")")
                            .font(.caption2)
                            .foregroundStyle(session.working ? .green : .secondary)
                    } else if session.working {
                        Text("Working now...")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                if let repoPath = settings.directory(for: ticket) ?? session?.cwd {
                    Text("Repo: \(repoPath)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(spacing: 6) {
                if let session {
                    Button("Resume") {
                        TerminalLauncher.resumeSession(id: session.id)
                    }
                } else {
                    Button("Start") {
                        settings.startSession(for: ticket, existingSession: session)
                    }
                }
                Button("Set Repo...") {
                    _ = settings.promptAndSetDirectory(for: ticket)
                }
                .font(.caption)

                Button("View Ticket") {
                    TerminalLauncher.openTicketInBrowser(ticket)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 6)
    }
}
