import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct JiraLocalAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TicketStore()
    @StateObject private var settings = AppSettingsStore()

    var body: some Scene {
        MenuBarExtra("Jira", systemImage: "checklist") {
            MenuBarContentView()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .menuBarExtraStyle(.window)

        Window("My Tickets", id: "tickets-window") {
            TicketsWindowView()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .defaultSize(width: 820, height: 560)

        Window("Settings", id: "settings-window") {
            SettingsView()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .defaultSize(width: 560, height: 460)

        Window("Agent Instructions", id: "agents-window") {
            AgentInstructionsView()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .defaultSize(width: 760, height: 560)
    }
}
