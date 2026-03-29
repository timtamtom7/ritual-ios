import SwiftUI

// MARK: - MacMainView
// Main container view for RitualMac integrating all views

struct MacMainView: View {
    @StateObject private var viewModel = RitualMacViewModel()
    @State private var selectedTab: Int = 0
    @State private var showingDetail: Bool = false
    @State private var selectedRitual: DailyRitual?
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationTitle("Ritual")
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(item: $selectedRitual) { ritual in
            RitualDetailView(
                ritual: ritual,
                completionHistory: viewModel.getCompletionHistory(for: ritual),
                viewModel: viewModel
            )
        }
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            Section {
                NavigationLink(value: 0) {
                    Label("Today", systemImage: "sun.and.stars")
                }
                
                NavigationLink(value: 1) {
                    Label("Daily Flow", systemImage: "clock.arrow.circlepath")
                }
                
                NavigationLink(value: 2) {
                    Label("All Rituals", systemImage: "list.bullet")
                }
                
                NavigationLink(value: 3) {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            }
            
            Section {
                NavigationLink(value: 4) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    // MARK: - Detail Content
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case 0:
            TodayOverviewView(viewModel: viewModel, onRitualTap: { ritual in
                selectedRitual = ritual
            })
            .navigationTitle("Today")
        case 1:
            DailyFlowView(viewModel: viewModel)
                .navigationTitle("Daily Flow")
        case 2:
            RitualListView(viewModel: viewModel)
                .navigationTitle("Rituals")
        case 3:
            StatsView(viewModel: viewModel)
                .navigationTitle("Stats")
        case 4:
            SettingsView(viewModel: viewModel)
                .navigationTitle("Settings")
        default:
            TodayOverviewView(viewModel: viewModel, onRitualTap: { ritual in
                selectedRitual = ritual
            })
            .navigationTitle("Today")
        }
    }
}

// MARK: - TodayOverviewView
// Quick overview for the Today tab with next ritual and quick stats

struct TodayOverviewView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    let onRitualTap: (DailyRitual) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.spacingL) {
                greetingSection
                
                if let nextRitual = viewModel.nextRitual {
                    NextUpCard(ritual: nextRitual, onTap: { onRitualTap(nextRitual) })
                }
                
                progressSection
                
                if !viewModel.morningRituals.isEmpty {
                    todaysRitualsSection
                }
            }
            .padding(MacTheme.spacingL)
        }
        .background(MacTheme.background)
    }
    
    // MARK: - Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingS) {
            Text(greeting)
                .font(MacTheme.displayFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text(dateString)
                .font(MacTheme.bodyFont)
                .foregroundColor(MacTheme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        HStack(spacing: MacTheme.spacingM) {
            ProgressCard(
                title: "Completed",
                value: "\(viewModel.completedCount)",
                total: viewModel.totalRituals,
                icon: "checkmark.circle.fill",
                color: MacTheme.sage
            )
            
            ProgressCard(
                title: "Streak",
                value: "\(viewModel.currentStreak)",
                total: nil,
                icon: "flame.fill",
                color: MacTheme.warmAmber
            )
            
            ProgressCard(
                title: "Progress",
                value: "\(Int(viewModel.dailyProgress * 100))",
                total: nil,
                icon: "percent",
                color: MacTheme.deepBrown
            )
        }
    }
    
    // MARK: - Today's Rituals
    private var todaysRitualsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingM) {
            Text("Today's Rituals")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
            
            VStack(spacing: MacTheme.spacingS) {
                ForEach(viewModel.dailyRituals.prefix(5)) { ritual in
                    Button(action: { onRitualTap(ritual) }) {
                        TodayRitualRow(ritual: ritual, isCompleted: viewModel.isRitualCompleted(ritual))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - NextUpCard
struct NextUpCard: View {
    let ritual: DailyRitual
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MacTheme.spacingM) {
                ZStack {
                    Circle()
                        .fill(MacTheme.warmAmber.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "flame")
                        .font(.system(size: 24))
                        .foregroundColor(MacTheme.warmAmber)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Up")
                        .font(MacTheme.captionFont)
                        .foregroundColor(MacTheme.mutedText)
                    
                    Text(ritual.name)
                        .font(MacTheme.headingFont)
                        .foregroundColor(MacTheme.primaryText)
                        .lineLimit(1)
                    
                    Text(ritual.timeString)
                        .font(MacTheme.captionFont)
                        .foregroundColor(MacTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MacTheme.mutedText)
            }
            .padding(MacTheme.spacingM)
            .background(MacTheme.cardBg)
            .cornerRadius(MacTheme.cardRadius)
            .shadow(color: MacTheme.cardShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ProgressCard
struct ProgressCard: View {
    let title: String
    let value: String
    let total: Int?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MacTheme.spacingS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(MacTheme.primaryText)
                
                if let total = total {
                    Text("/\(total)")
                        .font(.system(size: 14))
                        .foregroundColor(MacTheme.mutedText)
                }
            }
            
            Text(title)
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - TodayRitualRow
struct TodayRitualRow: View {
    let ritual: DailyRitual
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: MacTheme.spacingM) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isCompleted ? MacTheme.sage : MacTheme.mutedText)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ritual.name)
                    .font(MacTheme.bodyFont)
                    .foregroundColor(isCompleted ? MacTheme.mutedText : MacTheme.primaryText)
                    .strikethrough(isCompleted)
                
                Text("\(ritual.timeString) • \(ritual.timeOfDay.name)")
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.mutedText)
            }
            
            Spacer()
            
            if ritual.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(ritual.streak)")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(MacTheme.warmAmber)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(MacTheme.mutedText)
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.buttonRadius)
        .shadow(color: MacTheme.cardShadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.spacingL) {
                Text("Settings coming soon")
                    .font(MacTheme.bodyFont)
                    .foregroundColor(MacTheme.mutedText)
            }
            .padding(MacTheme.spacingL)
        }
        .background(MacTheme.background)
    }
}

// MARK: - Int extension for Identifiable
extension DailyRitual: Equatable {
    static func == (lhs: DailyRitual, rhs: DailyRitual) -> Bool {
        lhs.id == rhs.id
    }
}
