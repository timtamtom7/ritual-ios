import SwiftUI

struct MacMainView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: 0) {
                    Label("Today", systemImage: "sun.and.stars")
                }

                NavigationLink(value: 1) {
                    Label("Timeline", systemImage: "calendar")
                }

                NavigationLink(value: 2) {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
            }
            .navigationTitle("Ritual")
            .listStyle(.sidebar)
            .frame(minWidth: 200, idealWidth: 240)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case 0:
            MacTodayView()
                .navigationTitle("Today")
        case 1:
            MacTimelineView()
                .navigationTitle("Timeline")
        case 2:
            MacInsightsView()
                .navigationTitle("Insights")
        default:
            MacTodayView()
                .navigationTitle("Today")
        }
    }
}
