import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var store: TicketStore
    @EnvironmentObject var settings: AppSettingsStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if store.isLoading && store.ticketsByProject.isEmpty {
                ProgressView("Loading tickets...")
                    .padding()
            } else if let error = store.lastError {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Error", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if store.ticketsByProject.isEmpty {
                Text("No unresolved assigned tickets.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(store.sortedProjects, id: \.self) { project in
                            projectSection(project)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 640)
            }

            Divider()

            windowButtons

            footer
        }
        .frame(width: 380)
        .task {
            if store.lastRefreshed == nil {
                await store.refresh()
                store.startAutoRefresh()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("My Tickets")
                .font(.headline)
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(store.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func projectSection(_ project: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            ForEach(store.ticketsByProject[project] ?? []) { ticket in
                TicketRowView(ticket: ticket, session: store.session(for: ticket))
                    .padding(.horizontal, 12)
            }
        }
    }

    private var windowButtons: some View {
        VStack(spacing: 4) {
            Button {
                openWindow(id: "tickets-window")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open tickets dashboard", systemImage: "rectangle.expand.vertical")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            Button {
                openWindow(id: "agents-window")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("View agent instructions", systemImage: "text.badge.checkmark")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            Button {
                openWindow(id: "settings-window")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var footer: some View {
        HStack {
            if let last = store.lastRefreshed {
                Text("Updated \(last.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
