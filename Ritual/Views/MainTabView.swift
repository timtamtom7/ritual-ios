import SwiftUI

struct AdaptiveMainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: sidebar navigation
                iPadNavigationView
            } else {
                // iPhone: tab bar navigation
                MainTabView()
            }
        }
    }

    // MARK: - iPad Navigation

    private var iPadNavigationView: some View {
        NavigationSplitView {
            List {
                Button {
                    withAnimation { selectedTab = 0 }
                } label: {
                    Label("Today", systemImage: "sun.and.stars")
                        .foregroundColor(selectedTab == 0 ? Theme.goldPrimary : Theme.textPrimary)
                }
                .listRowBackground(selectedTab == 0 ? Theme.goldPrimary.opacity(0.1) : Color.clear)

                Button {
                    withAnimation { selectedTab = 1 }
                } label: {
                    Label("Timeline", systemImage: "calendar")
                        .foregroundColor(selectedTab == 1 ? Theme.goldPrimary : Theme.textPrimary)
                }
                .listRowBackground(selectedTab == 1 ? Theme.goldPrimary.opacity(0.1) : Color.clear)

                Button {
                    withAnimation { selectedTab = 2 }
                } label: {
                    Label("Templates", systemImage: "square.grid.2x2")
                        .foregroundColor(selectedTab == 2 ? Theme.goldPrimary : Theme.textPrimary)
                }
                .listRowBackground(selectedTab == 2 ? Theme.goldPrimary.opacity(0.1) : Color.clear)

                Button {
                    withAnimation { selectedTab = 3 }
                } label: {
                    Label("Community", systemImage: "person.3.fill")
                        .foregroundColor(selectedTab == 3 ? Theme.goldPrimary : Theme.textPrimary)
                }
                .listRowBackground(selectedTab == 3 ? Theme.goldPrimary.opacity(0.1) : Color.clear)

                Button {
                    withAnimation { selectedTab = 4 }
                } label: {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                        .foregroundColor(selectedTab == 4 ? Theme.goldPrimary : Theme.textPrimary)
                }
                .listRowBackground(selectedTab == 4 ? Theme.goldPrimary.opacity(0.1) : Color.clear)
            }
            .listStyle(.sidebar)
            .navigationTitle("Ritual")
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case 0:
            TodayView()
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.large)
        case 1:
            TimelineView()
                .navigationTitle("Timeline")
                .navigationBarTitleDisplayMode(.large)
        case 2:
            CommunityTemplatesView()
                .navigationTitle("Templates")
                .navigationBarTitleDisplayMode(.large)
        case 3:
            GroupRitualView()
                .navigationTitle("Community")
                .navigationBarTitleDisplayMode(.large)
        case 4:
            InsightsView()
                .navigationTitle("Insights")
                .navigationBarTitleDisplayMode(.large)
        default:
            TodayView()
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.and.stars")
                }
                .tag(0)

            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(1)

            CommunityTemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "square.grid.2x2")
                }
                .tag(2)

            GroupRitualView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .tag(3)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(4)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
        }
        .tint(Theme.goldPrimary)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.textMuted)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.goldPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.goldPrimary)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
