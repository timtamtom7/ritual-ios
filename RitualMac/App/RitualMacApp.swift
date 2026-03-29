import SwiftUI

@main
struct RitualMacApp: App {
    @StateObject private var viewModel = RitualMacViewModel()
    
    var body: some Scene {
        WindowGroup {
            MacMainView()
                .environmentObject(viewModel)
                .preferredColorScheme(.light)
                .frame(minWidth: 700, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Ritual") {
                Button("Show Window") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("1")
                
                Divider()
                
                Button("Quit Ritual") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}
