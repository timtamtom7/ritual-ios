import SwiftUI

// MARK: - RitualListView
// List of daily rituals with name, time, completion checkbox, and streak.

struct RitualListView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.spacingM) {
                headerSection
                
                if viewModel.dailyRituals.isEmpty {
                    emptyState
                } else {
                    ritualsList
                }
            }
            .padding(MacTheme.spacingL)
        }
        .background(MacTheme.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingS) {
            Text("Today's Rituals")
                .font(MacTheme.titleFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text(dateString)
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: MacTheme.spacingM) {
            Image(systemName: "flame")
                .font(.system(size: 48))
                .foregroundColor(MacTheme.warmAmber.opacity(0.6))
            
            Text("No rituals yet")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text("Open the iOS app to create your first ritual")
                .font(MacTheme.bodyFont)
                .foregroundColor(MacTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MacTheme.spacingXL)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Rituals List
    private var ritualsList: some View {
        VStack(spacing: MacTheme.spacingS) {
            ForEach(viewModel.dailyRituals) { ritual in
                RitualRowView(
                    ritual: ritual,
                    isCompleted: viewModel.isRitualCompleted(ritual),
                    onToggle: { viewModel.toggleRitualCompletion(ritual) }
                )
            }
        }
    }
}

// MARK: - RitualRowView
struct RitualRowView: View {
    let ritual: DailyRitual
    let isCompleted: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: MacTheme.spacingM) {
            // Completion checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? MacTheme.sage : Color.clear)
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .stroke(isCompleted ? MacTheme.sage : MacTheme.mutedText, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(MacTheme.textPrimary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Ritual info
            VStack(alignment: .leading, spacing: MacTheme.spacingXS) {
                Text(ritual.name)
                    .font(MacTheme.headingFont)
                    .foregroundColor(isCompleted ? MacTheme.mutedText : MacTheme.primaryText)
                    .strikethrough(isCompleted, color: MacTheme.mutedText)
                
                HStack(spacing: MacTheme.spacingS) {
                    // Time
                    Label(ritual.timeString, systemImage: "clock")
                        .font(MacTheme.captionFont)
                        .foregroundColor(MacTheme.secondaryText)
                    
                    // Category
                    if let category = ritual.category {
                        Text("•")
                            .foregroundColor(MacTheme.mutedText)
                        Text(category)
                            .font(MacTheme.captionFont)
                            .foregroundColor(MacTheme.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            // Streak badge
            if ritual.streak > 0 {
                StreakBadge(streak: ritual.streak)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MacTheme.mutedText)
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.buttonRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - StreakBadge
struct StreakBadge: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))
                .foregroundColor(MacTheme.warmAmber)
            
            Text("\(streak)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MacTheme.warmAmber)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(MacTheme.warmAmber.opacity(0.15))
        .cornerRadius(MacTheme.smallRadius)
    }
}

// MARK: - DailyRitual Model
struct DailyRitual: Identifiable {
    let id: String
    let name: String
    let category: String?
    let scheduledTime: Date
    var isCompleted: Bool
    var streak: Int
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }
    
    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: scheduledTime)
        if hour < 12 {
            return .morning
        } else if hour < 17 {
            return .afternoon
        } else {
            return .evening
        }
    }
}

enum TimeOfDay {
    case morning
    case afternoon
    case evening
    
    var name: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }
}
