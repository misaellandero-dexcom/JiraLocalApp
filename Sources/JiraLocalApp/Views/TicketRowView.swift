import SwiftUI

struct TicketRowView: View {
    let ticket: Ticket
    let session: CopilotSession?
    @EnvironmentObject var store: TicketStore
    @EnvironmentObject var settings: AppSettingsStore

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            statusDot
            VStack(alignment: .leading, spacing: 2) {
                Text("\(ticket.key)  \(ticket.summary ?? "")")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let status = ticket.status {
                        Text(status)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    if let session, let progress = session.progressText {
                        Text("• \(progress)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    if session?.working == true {
                        Text("• working...")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer()
            actionButton
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Set Repository Folder...") {
                _ = settings.promptAndSetDirectory(for: ticket)
            }
            Divider()
            Button("Open in Browser") {
                TerminalLauncher.openTicketInBrowser(ticket)
            }
            Button("Copy Key") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ticket.key, forType: .string)
            }
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        Circle()
            .fill(session?.working == true ? Color.green : (session != nil ? Color.orange : Color.gray.opacity(0.4)))
            .frame(width: 8, height: 8)
            .padding(.top, 4)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let session {
            Button("Resume") {
                TerminalLauncher.resumeSession(id: session.id)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        } else {
            Button("Start") {
                settings.startSession(for: ticket, existingSession: session)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        }
    }
}
