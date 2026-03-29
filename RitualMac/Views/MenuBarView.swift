import SwiftUI

// MARK: - MenuBarView
// Popover content for the menu bar: next ritual countdown, quick complete, streak

struct MenuBarView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
                .padding(.horizontal, MacTheme.spacingM)
            
            if viewModel.dailyRituals.isEmpty {
                emptyState
            } else {
                contentSection
            }
            
            Divider()
                .padding(.horizontal, MacTheme.spacingM)
            
            footerSection
        }
        .frame(width: 280)
        .background(MacTheme.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(MacTheme.headingFont)
                    .foregroundColor(MacTheme.primaryText)
                
                Text(dateString)
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.mutedText)
            }
            
            Spacer()
            
            // Streak indicator
            if viewModel.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MacTheme.warmAmber)
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MacTheme.warmAmber)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(MacTheme.warmAmber.opacity(0.15))
                .cornerRadius(MacTheme.smallRadius)
            }
        }
        .padding(MacTheme.spacingM)
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
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: MacTheme.spacingM) {
            Image(systemName: "flame")
                .font(.system(size: 36))
                .foregroundColor(MacTheme.warmAmber.opacity(0.6))
            
            Text("No rituals today")
                .font(MacTheme.bodyFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text("Open the iOS app to create rituals")
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(MacTheme.spacingL)
    }
    
    // MARK: - Content
    private var contentSection: some View {
        VStack(spacing: MacTheme.spacingS) {
            // Next ritual section
            if let nextRitual = viewModel.nextRitual {
                NextRitualCard(ritual: nextRitual, viewModel: viewModel)
            }
            
            // Today's progress
            TodayProgressCard(viewModel: viewModel)
            
            // Quick actions
            QuickActionsView(viewModel: viewModel)
        }
        .padding(MacTheme.spacingM)
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            Button(action: {
                NSWorkspace.shared.open(URL(string: "ritual://")!)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 12))
                    Text("Open Ritual")
                        .font(MacTheme.captionFont)
                }
                .foregroundColor(MacTheme.warmAmber)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Ritual")
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
        }
        .padding(MacTheme.spacingM)
    }
}

// MARK: - NextRitualCard
struct NextRitualCard: View {
    let ritual: DailyRitual
    @ObservedObject var viewModel: RitualMacViewModel
    
    @State private var timeRemaining: String = ""
    
    var body: some View {
        VStack(spacing: MacTheme.spacingM) {
            HStack {
                Text("Next Ritual")
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                // Countdown
                Text(timeRemaining)
                    .font(MacTheme.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(MacTheme.warmAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MacTheme.warmAmber.opacity(0.15))
                    .cornerRadius(MacTheme.smallRadius)
            }
            
            HStack(spacing: MacTheme.spacingM) {
                // Ritual icon
                ZStack {
                    Circle()
                        .fill(MacTheme.warmAmber.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "flame")
                        .font(.system(size: 20))
                        .foregroundColor(MacTheme.warmAmber)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ritual.name)
                        .font(MacTheme.headingFont)
                        .foregroundColor(MacTheme.primaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(ritual.timeString)
                            .font(MacTheme.captionFont)
                    }
                    .foregroundColor(MacTheme.secondaryText)
                }
                
                Spacer()
                
                // Quick complete button
                Button(action: {
                    viewModel.toggleRitualCompletion(ritual)
                }) {
                    Image(systemName: ritual.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundColor(ritual.isCompleted ? MacTheme.sage : MacTheme.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
        .onAppear {
            updateTimeRemaining()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let scheduled = ritual.scheduledTime
        
        if scheduled < now {
            timeRemaining = "Now"
        } else {
            let diff = Calendar.current.dateComponents([.minute], from: now, to: scheduled).minute ?? 0
            if diff < 60 {
                timeRemaining = "\(diff)m"
            } else {
                let hours = diff / 60
                timeRemaining = "\(hours)h"
            }
        }
    }
}

// MARK: - TodayProgressCard
struct TodayProgressCard: View {
    @ObservedObject var viewModel: RitualMacViewModel
    
    var body: some View {
        VStack(spacing: MacTheme.spacingS) {
            HStack {
                Text("Today's Progress")
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Text("\(viewModel.completedCount)/\(viewModel.totalRituals)")
                    .font(MacTheme.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(MacTheme.sage)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MacTheme.surface)
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(MacTheme.amberGradient)
                        .frame(width: geometry.size.width * viewModel.dailyProgress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.dailyProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - QuickActionsView
struct QuickActionsView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    
    var body: some View {
        HStack(spacing: MacTheme.spacingS) {
            QuickActionButton(
                icon: "list.bullet",
                label: "Rituals",
                action: { viewModel.showRitualList() }
            )
            
            QuickActionButton(
                icon: "chart.bar",
                label: "Stats",
                action: { viewModel.showStats() }
            )
            
            QuickActionButton(
                icon: "clock.arrow.circlepath",
                label: "Flow",
                action: { viewModel.showDailyFlow() }
            )
        }
    }
}

// MARK: - QuickActionButton
struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(MacTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MacTheme.spacingS)
            .background(MacTheme.surface)
            .cornerRadius(MacTheme.buttonRadius)
        }
        .buttonStyle(.plain)
    }
}
