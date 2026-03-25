import SwiftUI

struct MacTodayView: View {
    @State private var todaysIntentions: [Intention] = []
    @State private var currentStreak = StreakData()
    @State private var checkedInCount: Int = 0

    private let database = DatabaseService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                intentionSection

                StreakCardMac(streak: currentStreak)

                breathingSection

                HStack(spacing: 16) {
                    MacStatCard(title: "Intentions", value: "\(todaysIntentions.count)")
                    MacStatCard(title: "Check-ins", value: "\(checkedInCount)")
                    MacStatCard(title: "Streak", value: "\(currentStreak.currentStreak)")
                }
            }
            .padding(24)
        }
        .background(Color(hex: "0D0B09"))
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        todaysIntentions = database.getIntentions().filter {
            calendar.isDate($0.createdAt, inSameDayAs: startOfDay)
        }
        currentStreak = database.getStreakData()
        checkedInCount = todaysIntentions.reduce(0) { count, intention in
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            return count + (checkIns.first?.acted == true ? 1 : 0)
        }
    }

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Intention")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "9C9285"))
                .textCase(.uppercase)
                .tracking(1)

            if todaysIntentions.isEmpty {
                VStack(spacing: 12) {
                    Text("What will you focus on today?")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "F5F0E8"))
                        .multilineTextAlignment(.center)

                    Text("Set an intention to shape your day with purpose.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "9C9285"))
                        .multilineTextAlignment(.center)

                    Text("Open the iOS app to set your intention")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "C9A96E"))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(hex: "1A1714"))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(todaysIntentions) { intention in
                        MacIntentionRow(intention: intention, onCheckIn: {
                            let checkIn = CheckIn(id: UUID().uuidString, intentionId: intention.id, acted: true, reflection: nil, createdAt: Date())
                            try? database.saveCheckIn(checkIn)
                            loadData()
                        })
                    }
                }
            }
        }
    }

    private var breathingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breathing")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "9C9285"))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                ForEach([BreathingPattern.box, .calm, .coherent], id: \.self) { pattern in
                    Button {
                        // Open breathing session
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "wind")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "C9A96E"))
                            Text(pattern.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "F5F0E8"))
                            Text(pattern.description)
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "9C9285"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color(hex: "1A1714"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Mac-specific components

struct StreakCardMac: View {
    let streak: StreakData

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "9C9285"))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 36, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "F5F0E8"))
                    Text("days")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "9C9285"))
                }

                Text(streakStatus)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "C9A96E"))
            }

            Spacer()

            // Streak flame dots
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let isActive = dayIndex < streak.currentStreak % 7 || streak.currentStreak >= 7
                    Circle()
                        .fill(isActive ? Color(hex: "C9A96E") : Color(hex: "1A1714"))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "8B7355").opacity(isActive ? 0 : 0.5), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(Color(hex: "1A1714"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }

    private var streakStatus: String {
        if streak.currentStreak >= 30 {
            return "Incredible consistency!"
        } else if streak.currentStreak >= 14 {
            return "Building real momentum"
        } else if streak.currentStreak >= 7 {
            return "A week of intention"
        } else if streak.currentStreak >= 3 {
            return "The habit is forming"
        } else {
            return "Just getting started"
        }
    }
}

struct MacStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "F5F0E8"))
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "9C9285"))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}

struct MacIntentionRow: View {
    let intention: Intention
    let onCheckIn: () -> Void
    @State private var isCheckedIn: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                isCheckedIn.toggle()
                if isCheckedIn { onCheckIn() }
            } label: {
                Image(systemName: isCheckedIn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isCheckedIn ? Color(hex: "7A9E7A") : Color(hex: "8B7355"))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(intention.text)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(Color(hex: "F5F0E8"))
                    .strikethrough(isCheckedIn)
                    .foregroundColor(isCheckedIn ? Color(hex: "9C9285") : Color(hex: "F5F0E8"))

                Text(intention.category ?? "General")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "9C9285"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}
