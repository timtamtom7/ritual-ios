import SwiftUI

// MARK: - RitualDetailView
// Detailed view of a single ritual: name, description, time, duration, notes, completion history.

struct RitualDetailView: View {
    let ritual: DailyRitual
    let completionHistory: [CompletionRecord]
    @ObservedObject var viewModel: RitualMacViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.spacingL) {
                headerSection
                
                ritualInfoSection
                
                if !completionHistory.isEmpty {
                    historySection
                }
                
                notesSection
            }
            .padding(MacTheme.spacingL)
        }
        .background(MacTheme.background)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MacTheme.mutedText)
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: MacTheme.spacingM) {
            // Icon
            ZStack {
                Circle()
                    .fill(MacTheme.warmAmber.opacity(0.15))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "flame")
                    .font(.system(size: 32))
                    .foregroundColor(MacTheme.warmAmber)
            }
            
            Text(ritual.name)
                .font(MacTheme.displayFont)
                .foregroundColor(MacTheme.primaryText)
                .multilineTextAlignment(.center)
            
            // Category badge
            if let category = ritual.category {
                Text(category)
                    .font(MacTheme.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(MacTheme.warmAmber)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(MacTheme.warmAmber.opacity(0.15))
                    .cornerRadius(MacTheme.smallRadius)
            }
        }
    }
    
    // MARK: - Ritual Info
    private var ritualInfoSection: some View {
        VStack(spacing: MacTheme.spacingS) {
            InfoRow(icon: "clock", title: "Scheduled Time", value: ritual.timeString)
            InfoRow(icon: ritual.timeOfDay.icon, title: "Time of Day", value: ritual.timeOfDay.name)
            
            if ritual.streak > 0 {
                InfoRow(icon: "flame.fill", title: "Current Streak", value: "\(ritual.streak) days")
            }
            
            InfoRow(icon: "chart.bar.fill", title: "Total Completions", value: "\(completionHistory.count)")
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingM) {
            Text("Recent History")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
            
            VStack(spacing: MacTheme.spacingS) {
                ForEach(completionHistory.prefix(7)) { record in
                    HistoryRow(record: record)
                }
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingM) {
            Text("Notes")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text("Add personal notes about this ritual...")
                .font(MacTheme.bodyFont)
                .foregroundColor(MacTheme.mutedText)
                .padding(MacTheme.spacingM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 100)
                .background(MacTheme.surface)
                .cornerRadius(MacTheme.buttonRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: MacTheme.buttonRadius)
                        .stroke(MacTheme.mutedText.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MacTheme.warmAmber)
                .frame(width: 24)
            
            Text(title)
                .font(MacTheme.bodyFont)
                .foregroundColor(MacTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(MacTheme.bodyFont)
                .fontWeight(.medium)
                .foregroundColor(MacTheme.primaryText)
        }
        .padding(.vertical, MacTheme.spacingXS)
    }
}

// MARK: - HistoryRow
struct HistoryRow: View {
    let record: CompletionRecord
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: record.date)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: record.date)
    }
    
    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayString)
                    .font(.system(size: 11))
                    .foregroundColor(MacTheme.mutedText)
                Text(dateString)
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.primaryText)
            }
            .frame(width: 50, alignment: .leading)
            
            // Status
            HStack(spacing: 6) {
                Image(systemName: record.completed ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(record.completed ? MacTheme.sage : MacTheme.mutedText)
                
                Text(record.completed ? "Completed" : "Missed")
                    .font(MacTheme.captionFont)
                    .foregroundColor(record.completed ? MacTheme.sage : MacTheme.mutedText)
            }
            
            Spacer()
            
            // Reflection indicator
            if let reflection = record.reflection, !reflection.isEmpty {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundColor(MacTheme.warmAmber)
            }
        }
        .padding(.vertical, MacTheme.spacingXS)
    }
}

// MARK: - CompletionRecord
struct CompletionRecord: Identifiable {
    let id: String
    let date: Date
    let completed: Bool
    let reflection: String?
}
