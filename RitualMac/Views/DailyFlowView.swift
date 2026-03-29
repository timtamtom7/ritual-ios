import SwiftUI

// MARK: - DailyFlowView
// Today's ritual timeline showing Morning → Afternoon → Evening progression

struct DailyFlowView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.spacingL) {
                headerSection
                
                progressIndicator
                
                timelineContent
            }
            .padding(MacTheme.spacingL)
        }
        .background(MacTheme.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: MacTheme.spacingS) {
            Text("Your Day")
                .font(MacTheme.titleFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text(dateString)
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: MacTheme.spacingM) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(MacTheme.surface)
                        .frame(height: 8)
                    
                    // Progress fill
                    Capsule()
                        .fill(MacTheme.amberGradient)
                        .frame(width: geometry.size.width * viewModel.dailyProgress, height: 8)
                }
            }
            .frame(height: 8)
            
            // Stats row
            HStack {
                Label("\(viewModel.completedCount)/\(viewModel.totalRituals)", systemImage: "checkmark.circle.fill")
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.sage)
                
                Spacer()
                
                if let nextRitual = viewModel.nextRitual {
                    Label("Next: \(nextRitual.name) in \(nextRitual.timeString)", systemImage: "clock")
                        .font(MacTheme.captionFont)
                        .foregroundColor(MacTheme.warmAmber)
                }
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Timeline Content
    private var timelineContent: some View {
        VStack(spacing: MacTheme.spacingXL) {
            // Morning
            if !viewModel.morningRituals.isEmpty {
                TimeOfDaySection(
                    timeOfDay: .morning,
                    rituals: viewModel.morningRituals,
                    completedCount: viewModel.morningRituals.filter { viewModel.isRitualCompleted($0) }.count,
                    totalCount: viewModel.morningRituals.count,
                    isPast: currentTimeOfDay != .morning,
                    onToggle: { ritual in viewModel.toggleRitualCompletion(ritual) }
                )
            }
            
            // Afternoon
            if !viewModel.afternoonRituals.isEmpty {
                TimeOfDaySection(
                    timeOfDay: .afternoon,
                    rituals: viewModel.afternoonRituals,
                    completedCount: viewModel.afternoonRituals.filter { viewModel.isRitualCompleted($0) }.count,
                    totalCount: viewModel.afternoonRituals.count,
                    isPast: currentTimeOfDay == .evening,
                    onToggle: { ritual in viewModel.toggleRitualCompletion(ritual) }
                )
            }
            
            // Evening
            if !viewModel.eveningRituals.isEmpty {
                TimeOfDaySection(
                    timeOfDay: .evening,
                    rituals: viewModel.eveningRituals,
                    completedCount: viewModel.eveningRituals.filter { viewModel.isRitualCompleted($0) }.count,
                    totalCount: viewModel.eveningRituals.count,
                    isPast: false,
                    onToggle: { ritual in viewModel.toggleRitualCompletion(ritual) }
                )
            }
        }
    }
    
    private var currentTimeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return .morning
        } else if hour < 17 {
            return .afternoon
        } else {
            return .evening
        }
    }
}

// MARK: - TimeOfDaySection
struct TimeOfDaySection: View {
    let timeOfDay: TimeOfDay
    let rituals: [DailyRitual]
    let completedCount: Int
    let totalCount: Int
    let isPast: Bool
    let onToggle: (DailyRitual) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingM) {
            // Section header
            HStack {
                // Time icon
                Image(systemName: timeOfDay.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isPast ? MacTheme.mutedText : MacTheme.warmAmber)
                
                Text(timeOfDay.name)
                    .font(MacTheme.headingFont)
                    .foregroundColor(isPast ? MacTheme.mutedText : MacTheme.primaryText)
                
                Spacer()
                
                // Progress badge
                Text("\(completedCount)/\(totalCount)")
                    .font(MacTheme.captionFont)
                    .foregroundColor(isPast ? MacTheme.mutedText : MacTheme.sage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isPast ? MacTheme.mutedText : MacTheme.sage).opacity(0.15))
                    .cornerRadius(MacTheme.smallRadius)
            }
            
            // Timeline line
            if isPast {
                // Show completed state
                HStack(spacing: MacTheme.spacingS) {
                    // Checkmark circle
                    ZStack {
                        Circle()
                            .fill(MacTheme.sage)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Rectangle()
                        .fill(MacTheme.sage.opacity(0.5))
                        .frame(height: 2)
                }
            } else {
                // Active timeline
                HStack(spacing: MacTheme.spacingS) {
                    Circle()
                        .fill(MacTheme.warmAmber)
                        .frame(width: 24, height: 24)
                    
                    Rectangle()
                        .fill(MacTheme.warmAmber.opacity(0.3))
                        .frame(height: 2)
                }
            }
            
            // Rituals
            VStack(spacing: MacTheme.spacingS) {
                ForEach(rituals) { ritual in
                    FlowRitualRow(
                        ritual: ritual,
                        isPast: isPast,
                        onToggle: { onToggle(ritual) }
                    )
                }
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
        .opacity(isPast ? 0.7 : 1.0)
    }
}

// MARK: - FlowRitualRow
struct FlowRitualRow: View {
    let ritual: DailyRitual
    let isPast: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: MacTheme.spacingM) {
            // Time
            Text(ritual.timeString)
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
                .frame(width: 50, alignment: .leading)
            
            // Name
            Text(ritual.name)
                .font(MacTheme.bodyFont)
                .foregroundColor(isPast ? MacTheme.mutedText : MacTheme.primaryText)
            
            Spacer()
            
            // Streak
            if ritual.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(MacTheme.warmAmber)
                    Text("\(ritual.streak)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MacTheme.warmAmber)
                }
            }
            
            // Completion indicator
            if isPast {
                Image(systemName: ritual.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(ritual.isCompleted ? MacTheme.sage : MacTheme.mutedText)
            } else {
                Button(action: onToggle) {
                    Image(systemName: ritual.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(ritual.isCompleted ? MacTheme.sage : MacTheme.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MacTheme.spacingS)
        .background(MacTheme.surface)
        .cornerRadius(MacTheme.smallRadius)
    }
}
