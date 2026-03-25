import SwiftUI
import WatchKit

@main
struct RitualWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    @State private var selectedPattern: BreathingPattern = .calm
    @State private var isBreathing = false
    @State private var currentPhase: BreathingPhase = .idle
    @State private var timeRemaining: Int = 3
    @State private var sessionComplete = false
    @State private var showIntentionSheet = false
    @State private var showCheckInSheet = false
    @State private var currentIntentionText: String = ""

    private let userDefaults = UserDefaults.standard
    private let intentionKey = "watch_intention_text"
    private let intentionDateKey = "watch_intention_date"
    private let checkInKey = "watch_checkin_done"

    var body: some View {
        NavigationStack {
            if isBreathing {
                BreathingWatchView(
                    selectedPattern: $selectedPattern,
                    isBreathing: $isBreathing,
                    currentPhase: $currentPhase,
                    timeRemaining: $timeRemaining,
                    sessionComplete: $sessionComplete
                )
            } else if sessionComplete {
                SessionCompleteView(onDismiss: {
                    sessionComplete = false
                    WKInterfaceDevice.current().play(.success)
                })
            } else {
                homeView
            }
        }
        .onAppear {
            loadSavedIntention()
        }
        .sheet(isPresented: $showIntentionSheet) {
            WatchIntentionSheet(intentionText: $currentIntentionText) {
                saveIntention()
                showIntentionSheet = false
            }
        }
        .sheet(isPresented: $showCheckInSheet) {
            WatchCheckInSheet(intentionText: currentIntentionText) { acted in
                saveCheckIn(acted: acted)
                showCheckInSheet = false
            }
        }
    }

    private var homeView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Intention card
                intentionCard

                // Quick actions
                actionButtons

                Text("Choose Your Breath")
                    .font(.headline)
                    .foregroundColor(.gold)

                ForEach(BreathingPattern.allCases.filter { $0 != .custom }, id: \.self) { pattern in
                    Button {
                        selectedPattern = pattern
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.rawValue)
                                    .font(.system(.callout, design: .rounded))
                                    .fontWeight(.medium)
                                Text(pattern.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedPattern == pattern {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.gold)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedPattern == pattern ? .gold : .secondary)
                }

                Button {
                    startSession()
                } label: {
                    Label("Begin Session", systemImage: "wind")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gold)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Ritual")
    }

    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            if currentIntentionText.isEmpty {
                Button {
                    showIntentionSheet = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set Today's Intention")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Tap to set an intention")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(.gold.opacity(0.6))
            } else if hasCheckedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(currentIntentionText)
                        .font(.caption)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button {
                    showCheckInSheet = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Intention")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(currentIntentionText)
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.medium)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(.gold)
            }
        }
        .padding(8)
        .background(Color.gold.opacity(0.1))
        .cornerRadius(8)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if !currentIntentionText.isEmpty && !hasCheckedIn {
                Button {
                    showCheckInSheet = true
                } label: {
                    Label("Check In", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }

            Button {
                showIntentionSheet = true
            } label: {
                Label("Intention", systemImage: "text.bubble")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.gold.opacity(0.8))
        }
    }

    private var hasCheckedIn: Bool {
        guard let dateString = userDefaults.string(forKey: intentionDateKey),
              let date = ISO8601DateFormatter().date(from: dateString),
              Calendar.current.isDateInToday(date) else {
            return userDefaults.bool(forKey: checkInKey)
        }
        return Calendar.current.isDateInToday(date) && userDefaults.bool(forKey: checkInKey)
    }

    private func loadSavedIntention() {
        if let text = userDefaults.string(forKey: intentionKey) {
            currentIntentionText = text
        }
    }

    private func saveIntention() {
        userDefaults.set(currentIntentionText, forKey: intentionKey)
        userDefaults.set(ISO8601DateFormatter().string(from: Date()), forKey: intentionDateKey)
        userDefaults.set(false, forKey: checkInKey)
        WKInterfaceDevice.current().play(.notification)
    }

    private func saveCheckIn(acted: Bool) {
        userDefaults.set(true, forKey: checkInKey)
        WKInterfaceDevice.current().play(acted ? .success : .retry)
    }

    private func startSession() {
        isBreathing = true
        currentPhase = .idle
        WKInterfaceDevice.current().play(.start)
    }
}

// MARK: - Watch Intention Sheet

struct WatchIntentionSheet: View {
    @Binding var intentionText: String
    let onSave: () -> Void
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Today's Intention")
                    .font(.headline)
                    .foregroundColor(.gold)

                TextField("I intend to...", text: $text)
                    .font(.system(.body, design: .rounded))
                    .focused($isFocused)
                    .onAppear { isFocused = true }

                Button("Save") {
                    intentionText = text
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .tint(.gold)
                .disabled(text.isEmpty)

                Button("Cancel", role: .cancel) {
                    onSave()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onChange(of: text) { _, newValue in
            intentionText = newValue
        }
    }
}

// MARK: - Watch Check-In Sheet

struct WatchCheckInSheet: View {
    let intentionText: String
    let onCheckIn: (Bool) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Check In")
                    .font(.headline)
                    .foregroundColor(.gold)

                Text("Did you act on your intention?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("\"\(intentionText)\"")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button {
                    onCheckIn(true)
                } label: {
                    Label("Yes, I did", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    onCheckIn(false)
                } label: {
                    Label("Not today", systemImage: "xmark.circle")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button("Skip", role: .cancel) {
                    onCheckIn(false)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
