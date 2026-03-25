import SwiftUI

@main
struct RitualMacApp: App {
    init() {
        Task {
            _ = await CalendarService.shared.requestAccess()
            CalendarService.shared.fetchTodaysEvents()
        }
    }

    var body: some Scene {
        WindowGroup {
            MacMainView()
                .preferredColorScheme(.dark)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
    }
}
