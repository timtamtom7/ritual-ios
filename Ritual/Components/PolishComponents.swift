import Foundation
import SwiftUI
import UIKit

struct DataExportService {
    @MainActor
    static func exportAllData() -> URL? {
        let database = DatabaseService.shared

        let intentions = database.getIntentions()
        let checkIns = database.getAllCheckIns()
        let breathingSessions = database.getBreathingSessions()
        let streakData = database.getStreakData()

        var exportText = "# Ritual Export\n"
        exportText += "# Generated: \(Date().formatted())\n\n"

        // Streak summary
        exportText += "## Streak\n"
        exportText += "- Current Streak: \(streakData.currentStreak) days\n"
        exportText += "- Longest Streak: \(streakData.longestStreak) days\n"
        exportText += "- Streak Freezes: \(streakData.streakFreezes)\n\n"

        // Intentions
        exportText += "## Intentions (\(intentions.count) total)\n"
        exportText += "| Date | Intention | Category | Checked In |\n"
        exportText += "|------|-----------|---------|------------|\n"

        for intention in intentions {
            let checkIn = database.getCheckIns(forIntentionId: intention.id).first
            let dateStr = intention.createdAt.formatted(date: .abbreviated, time: .omitted)
            let text = intention.text ?? ""
            let category = intention.category ?? "General"
            let checkedIn = checkIn?.acted == true ? "✅" : "❌"
            exportText += "| \(dateStr) | \(text) | \(category) | \(checkedIn) |\n"
        }

        exportText += "\n"

        // Breathing Sessions
        exportText += "## Breathing Sessions (\(breathingSessions.count) total)\n"
        exportText += "| Date | Pattern | Duration | Completed |\n"
        exportText += "|------|---------|---------|----------|\n"

        for session in breathingSessions {
            let dateStr = session.createdAt.formatted(date: .abbreviated, time: .shortened)
            let completed = session.completed ? "✅" : "❌"
            exportText += "| \(dateStr) | \(session.pattern.rawValue) | \(session.durationSeconds / 60)m | \(completed) |\n"
        }

        exportText += "\n## Check-ins (\(checkIns.count) total)\n"

        // Write to file
        let fileName = "ritual-export-\(Date().ISO8601Format()).md"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try exportText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}

// MARK: - Loading State Views

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.goldPrimary))
                .scaleEffect(1.2)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.compactRadius)
            .fill(
                LinearGradient(
                    colors: [Theme.surface, Theme.surface.opacity(0.5), Theme.surface],
                    startPoint: isAnimating ? .trailing : .leading,
                    endPoint: isAnimating ? .leading : .trailing
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Empty State Views

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Theme.goldMuted)

            Text(title)
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingL)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "0D0B09"))
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.vertical, Theme.spacingS)
                        .background(Theme.goldPrimary)
                        .cornerRadius(Theme.buttonRadius)
                }
                .padding(.top, Theme.spacingS)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(Theme.warning)

            Text("Something went wrong")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingL)

            if let retry = retryAction {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.goldPrimary)
                }
                .buttonStyle(.bordered)
                .tint(Theme.goldPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingXL)
    }
}

// MARK: - Micro-interactions

struct PulseButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button(action: {
            isPulsing = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPulsing = false
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.goldPrimary)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
        }
        .animation(.spring(response: 0.3), value: isPulsing)
    }
}

// MARK: - Toast / Banner

struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case success, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return Theme.success
            case .error: return Theme.warning
            case .info: return Theme.goldPrimary
            }
        }
    }

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extensions

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                }
            )
            .mask(content)
            .onAppear { phase = 1 }
    }
}


